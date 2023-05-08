mod core;
mod daily_update;
pub mod helpers;
mod pricing;

use candid::{Decode, Encode};
use ic_agent::{ic_types::Principal, Agent};
use std::{thread, time::Duration};
use std::convert::TryInto;
use std::sync::RwLock;
use std::time::SystemTime;
use diesel::sqlite::SqliteConnection;
use diesel::ExpressionMethods;
use cap_sdk::{Event, DetailValue};
use cap_sdk_core::did::*;
use diesel::{QueryDsl, RunQueryDsl};
use diesel::dsl::{max};
use crate::model::*;
use diesel::prelude::*;
use reqwest::Error;
use tokio_retry::Retry;
use tokio_retry::strategy::FixedInterval;
use crate::BigUint;
use crate::db::Pool;
use crate::sync::core::*;
use crate::sync::helpers::create_user;
use crate::sync::pricing::get_icp_price_from_binance;

const PAGE_CAPACITY: i64 = 64;

const DEFAULT_IC_GATEWAY: &str = "https://boundary.ic0.app";
const INTERVAL: u64 = 30; // 30s

pub fn raw_tx_from_event(id: i64, e: &Event) -> RawTx {
    RawTx {
        id: id as i32,
        time: e.time.to_string(),
        caller: e.caller.to_string(),
        operation: e.operation.clone(),
        details: serde_json::to_string(&e.details).unwrap(),
    }
}

fn save_raw_tx_to_db(tx: &RawTx, conn: &SqliteConnection) {
    use crate::model::schema::raw_txs;

    diesel::insert_into(raw_txs::table)
        .values(tx)
        .execute(conn)
        .expect("Error saving raw transaction");
}

fn handle_event(tx_id: i64, event: &Event, token_meta: Option<(String, TokenMetadata)>, conn: &SqliteConnection) {
    let operation = event.operation.as_str();
    info!("handle {}", operation);
    create_user(event.caller, conn);
    match operation {
        "addToken" => {
            let (token_id, meta) = token_meta.expect("token meta data must exist");
            handle_add_token(token_id.to_owned(), meta, conn);
        }
        "deposit" | "withdraw" => {
            handle_deposit_withdraw(tx_id, event, conn);
        }
        "createPair" => {
            handle_create_pair(event, conn);
        }
        "addLiquidity" => {
            handle_add_liquidity(tx_id, event, conn);
        }
        "removeLiquidity" => {
            handle_remove_liquidity(tx_id, event, conn);
        }
        "swap" => {
            handle_swap(tx_id, event, conn);
        }
        // token related event
        "tokenTransfer" | "lpTransfer" | "tokenTransferFrom" | "lpTransferFrom" | "tokenApprove" | "lpApprove" => {
            handle_tokens(tx_id, event, conn);
        }
        // other unsupported event
        op => {
            warn!("Unsupported operation: {}", op)
        }
    }
}

pub async fn sync_cap(canister_id: String, conn: SqliteConnection) {
    let agent = Agent::builder()
        .with_url(DEFAULT_IC_GATEWAY)
        .with_identity(create_identity())
        .build()
        .expect("Failed to build the Agent");

    let mut current_index = get_current_index(&conn) + 1;
    loop {
        let mut current_page = current_index / PAGE_CAPACITY;
        let history_size: i64 = get_history_size(&agent, canister_id.clone()).await.try_into().expect("history size overflow");
        let total_pages = history_size / PAGE_CAPACITY;
        info!("history size: {:?}, total pages: {:?}", history_size, total_pages);
        info!("current index: {:?}, current page: {:?}", current_index, current_page);

        if current_index >= history_size {
            update_sync_time(
                SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_secs(),
                history_size - 1,
                &conn
            );
            info!("sync completed");
            tokio::time::sleep(Duration::from_secs(INTERVAL)).await;
            continue;
        }

        info!("start index: {:?}, end index: {:?}", current_index, history_size - 1);
        info!("start fetching pages: start page: {:?}, end page: {:?}", current_page, total_pages);
        while current_page <= total_pages {
            let events = get_transactions(
                &agent,
                canister_id.clone(),
                current_page as u32,
            ).await;
            let idx_in_page = (current_index % PAGE_CAPACITY) as usize;
            for i in idx_in_page..events.len() {
                let e = &events[i];
                let metadata = if e.operation.clone() == "addToken" {
                    let canister_id = match &e.details[0].1 {
                        DetailValue::Text(s) => { s }
                        _ => { panic!("not a text") }
                    };
                    let meta = get_token_info(&agent, canister_id.to_owned()).await;
                    Some((canister_id.to_owned(), meta))
                } else {
                    None
                };
                handle_event(current_index, &e, metadata, &conn);
                let tx = raw_tx_from_event(current_index, &e);
                save_raw_tx_to_db(&tx, &conn);
                current_index += 1;
            }
            info!("page: {:?}, current index: {:?}", current_page, current_index);
            current_page += 1;
        }
    }
}

fn get_current_index(conn: &SqliteConnection) -> i64 {
    use crate::model::schema::raw_txs::dsl::*;
    use crate::model::schema::raw_txs::columns::*;

    let index: Option<i32> = raw_txs.select(max(id))
        .first(conn)
        .expect("query table error");
    index.unwrap_or(-1) as i64
}

async fn get_history_size(agent: &Agent, canister_id: String) -> u64 {
    let empty_arg = 0;
    let response =
        Retry::spawn(FixedInterval::from_millis(1000), || async {
            agent
                .query(
                    &Principal::from_text(canister_id.clone()).expect(
                        format!(
                            "Failed to convert this canister_id to principal: {}",
                            canister_id
                        )
                            .as_str(),
                    ),
                    "size",
                )
                .with_arg(&Encode!(&empty_arg).unwrap())
                .call()
                .await
        })
            .await
            .expect("Failed to call canister on size.");

    let history_size: u64 =
        Decode!(response.as_slice(), u64).expect("failed to decode size result");

    history_size
}

async fn get_transactions(agent: &Agent, canister_id: String, page: u32) -> Vec<Event> {
    let arg = GetTransactionsArg {
        page: Some(page),
        witness: false,
    };
    let response =
        Retry::spawn(FixedInterval::from_millis(1000), || async {
            agent
                .query(
                    &Principal::from_text(canister_id.clone()).expect(
                        format!(
                            "Failed to convert this canister_id to principal: {}",
                            canister_id
                        )
                            .as_str(),
                    ),
                    "get_transactions",
                )
                .with_arg(&Encode!(&arg).unwrap())
                .call()
                .await
        })
            .await
            .expect("Failed to call canister on get_transactions");

    let result = Decode!(response.as_slice(), GetTransactionsResponse)
        .expect("Failed to decode the get_transactions response data.");

    result.data
}

async fn get_transaction(agent: &Agent, canister_id: String, id: u64) -> Event {
    let arg = WithIdArg {
        id,
        witness: false,
    };

    // fetch cap would fail, retry max 5 times
    let response =
        Retry::spawn(FixedInterval::from_millis(1000), || async {
            agent
                .query(
                    &Principal::from_text(canister_id.clone()).expect(
                        format!(
                            "Failed to convert this canister_id to principal: {}",
                            canister_id
                        )
                            .as_str(),
                    ),
                    "get_transaction",
                )
                .with_arg(&Encode!(&arg).unwrap())
                .call()
                .await
        })
            .await
            .expect("Failed to call canister on get_transaction");

    let result = Decode!(response.as_slice(), GetTransactionResponse)
        .expect("Failed to decode the get_transactions response data.");

    match result {
        GetTransactionResponse::Found(e, w) => e.unwrap(),
        _ => panic!("transaction not found"),
    }
}

async fn get_token_info(agent: &Agent, canister_id: String) -> TokenMetadata {
    let arg = 0;
    let response =
        agent
            .query(
                &Principal::from_text("3xwpq-ziaaa-aaaah-qcn4a-cai").expect(
                    format!(
                        "Failed to convert this canister_id to principal: {}",
                        canister_id
                    )
                        .as_str(),
                ),
                "getTokenMetadata",
            )
            .with_arg(&Encode!(&canister_id).unwrap())
            .call()
            .await
            .expect("Failed to call canister on getMetadata")
        ;

    let result = Decode!(response.as_slice(), TokenMetadata)
        .expect("Failed to decode the get_transactions response data.");

    result
}

fn create_identity() -> impl ic_agent::Identity {
    let rng = ring::rand::SystemRandom::new();
    let key_pair = ring::signature::Ed25519KeyPair::generate_pkcs8(&rng)
        .expect("Could not generate a key pair.");

    ic_agent::identity::BasicIdentity::from_key_pair(
        ring::signature::Ed25519KeyPair::from_pkcs8(key_pair.as_ref())
            .expect("Could not read the key pair."),
    )
}

pub async fn sync_price(conn: SqliteConnection) {
    loop {
        let result = get_icp_price_from_binance().await;
        match result {
            Ok(price) => {
                info!("get icp price: {}", price.clone());
                let bundle = Bundle {
                    id: 1,
                    icp_price: price.into(),
                    timestamp: Some(BigUint::from(SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_secs()))
                };
                diesel::replace_into(crate::model::schema::bundle::dsl::bundle)
                    .values(bundle.clone())
                    .execute(&conn)
                    .expect("Error updating bundle price");
            }
            Err(e) => {
                warn!("get icp error: {}", e);
            }
        }
        // poll icp price  every 5 seconds
        tokio::time::sleep(Duration::from_secs(5)).await;
    }
}

pub fn update_sync_time(sync_time: u64, tx_id: i64, conn: &SqliteConnection) {
    use crate::model::schema::sync_time::dsl;

    // sync time is unix timestamp in second
    let sync_time = SyncTime {
        id: 1,
        time: BigUint::from(sync_time),
        tx_id: tx_id as i32
    };
    diesel::replace_into(dsl::sync_time)
        .values(sync_time)
        .execute(conn)
        .expect("Error updating sync time");
}