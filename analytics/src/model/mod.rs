pub(crate) mod schema;

use std::default::Default;
use diesel::prelude::*;
use schema::*;
use ic_kit::candid::{types::number::Nat, CandidType, Deserialize};
use cap_sdk::insert;
use diesel::{insert_into, replace_into, update};
use ic_agent::{ic_types::Principal};
use crate::{BigDecimal, BigUint};

pub trait DB<PK, CONN>
    where
        Self: Sized,
        CONN: Connection
{
    fn load(id: PK, conn: &CONN) -> QueryResult<Self> {
        unreachable!()
    }
    fn insert(&self, conn: &CONN) {
        unreachable!()
    }
    fn update(&self, conn: &CONN) {
        unreachable!()
    }
}

#[derive(Queryable, Insertable)]
#[table_name = "raw_txs"]
pub struct RawTx {
    pub id: i32,
    pub time: String,
    pub caller: String,
    pub operation: String,
    pub details: String,
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "sonic"]
pub struct Sonic {
    pub id: String,

    pub token_count: i32,
    pub pair_count: i32,

    pub total_volume_icp: BigDecimal,
    pub total_volume_usd: BigDecimal,

    pub untracked_volume_icp: BigDecimal,
    pub untracked_volume_usd: BigDecimal,

    pub total_liquidity_icp: BigDecimal,
    pub total_liquidity_usd: BigDecimal,

    pub tx_count: BigUint,
}

impl DB<String, SqliteConnection> for Sonic {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::sonic::dsl::sonic;
        sonic.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::sonic::dsl::sonic;
        insert_into(sonic)
            .values(self)
            .execute(conn)
            .expect("Error in inserting sonic");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating sonic");
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "users"]
pub struct User {
    pub id: String,
    pub icp_swapped: BigDecimal,
    pub usd_swapped: BigDecimal,
}

impl DB<String, SqliteConnection> for User {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::users::dsl::users;
        users.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::users::dsl::users;
        insert_into(users)
            .values(self)
            .execute(conn)
            .expect("Error in inserting user");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating user");
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default, Clone)]
#[table_name = "tokens"]
pub struct Token {
    pub id: String,
    pub name: String,
    pub symbol: String,
    pub decimals: i32,
    pub total_supply: BigUint,
    pub fee: BigUint,
    pub total_deposited: BigUint,

    pub trade_volume: BigDecimal,
    pub trade_volume_icp: BigDecimal,
    pub trade_volume_usd: BigDecimal,
    pub untracked_volume_icp: BigDecimal,
    pub untracked_volume_usd: BigDecimal,

    pub tx_count: BigUint,

    pub total_liquidity: BigDecimal,

    pub derived_icp: BigDecimal,
}

impl DB<String, SqliteConnection> for Token {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::tokens::dsl::tokens;
        tokens.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::tokens::dsl::tokens;
        insert_into(tokens)
            .values(self)
            .execute(conn)
            .expect("Error in inserting tokens");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating tokens");
    }
}

#[allow(non_snake_case)]
#[derive(Deserialize, CandidType, Clone, Debug)]
pub struct TokenMetadata {
    // pub logo: String,
    pub name: String,
    pub symbol: String,
    pub decimals: u8,
    pub totalSupply: Nat,
    // pub owner: Principal,
    pub fee: Nat,
}

impl Token {
    pub fn from_metadata(canister_id: String, m: TokenMetadata) -> Self {
        Token {
            id: canister_id,
            name: m.name,
            symbol: m.symbol,
            decimals: m.decimals as i32,
            total_supply: BigUint(m.totalSupply.0),
            fee: BigUint(m.fee.0),
            total_deposited: Default::default(),
            trade_volume: Default::default(),
            trade_volume_icp: Default::default(),
            trade_volume_usd: Default::default(),
            untracked_volume_icp: Default::default(),
            untracked_volume_usd: Default::default(),
            total_liquidity: Default::default(),
            tx_count: Default::default(),
            derived_icp: Default::default(),
        }
    }
}

// swap related txs: addLiquidity, removeLiquidity, swap
#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "swaps"]
pub struct Swap {
    pub id: i32,
    pub timestamp: BigUint,
    pub pair: String,
    pub caller: String,

    pub amount0_in: BigDecimal,
    pub amount1_in: BigDecimal,
    pub amount0_out: BigDecimal,
    pub amount1_out: BigDecimal,
    pub fee: BigDecimal,

    pub amount_icp: BigDecimal,
    pub amount_usd: BigDecimal,
}

impl DB<i32, SqliteConnection> for Swap {
    fn load(id: i32, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::swaps::dsl::swaps;
        swaps.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::swaps::dsl::swaps;
        replace_into(swaps)
            .values(self)
            .execute(conn)
            .expect("Error in inserting swaps");
    }
}

// in-canister token related txs
#[derive(Queryable, Insertable, Identifiable, Default)]
#[table_name = "token_txs"]
pub struct TokenTx {
    pub id: i32,
    // transaction id in global tx history
    pub token_txid: i32,
    // corresponding txid in token tx history
    pub timestamp: BigUint,
    pub caller: String,
    pub operation: String,
    pub token: String,
    pub from: String,
    pub to: String,
    pub amount: BigDecimal,
    pub fee: BigDecimal,
}

impl DB<i32, SqliteConnection> for TokenTx {
    fn load(id: i32, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::token_txs::dsl::token_txs;
        token_txs.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::token_txs::dsl::token_txs;
        replace_into(token_txs)
            .values(self)
            .execute(conn)
            .expect("Error in inserting token_txs");
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default, Clone)]
#[table_name = "pairs"]
pub struct Pair {
    pub id: String,
    pub token0: String,
    pub token1: String,
    pub reserve0: BigDecimal,
    pub reserve1: BigDecimal,
    pub total_supply: BigDecimal,

    pub reserve_icp: BigDecimal,
    pub reserve_usd: BigDecimal,
    pub tracked_reserved_icp: BigDecimal,

    pub token0_price: BigDecimal,
    pub token1_price: BigDecimal,

    pub volume_token0: BigDecimal,
    pub volume_token1: BigDecimal,
    pub volume_icp: BigDecimal,
    pub volume_usd: BigDecimal,
    pub untracked_volume_icp: BigDecimal,
    pub untracked_volume_usd: BigDecimal,
    pub tx_count: BigUint,

    pub crated_timestamp: BigUint,

    pub liquidity_provider_count: i32,
}

impl DB<String, SqliteConnection> for Pair {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::pairs::dsl::pairs;
        pairs.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::pairs::dsl::pairs;
        replace_into(pairs)
            .values(self)
            .execute(conn)
            .expect("Error in inserting pairs");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating pairs");
    }
}

// LP positions, delete when remove liquidity
#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "liquidity_positions"]
pub struct LiquidityPosition {
    pub id: String,
    pub user: String,
    // index to user id
    pub pair: String,
    // index to pair id
    pub liquidity_token_balance: BigDecimal,
}

impl DB<String, SqliteConnection> for LiquidityPosition {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::liquidity_positions::dsl::liquidity_positions;
        liquidity_positions.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::liquidity_positions::dsl::liquidity_positions;
        replace_into(liquidity_positions)
            .values(self)
            .execute(conn)
            .expect("Error in inserting liquidity positions");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating liquidity positions");
    }
}


#[derive(Queryable, Insertable, Identifiable, Clone)]
#[table_name = "liquidity_position_snapshots"]
pub struct
LiquidityPositionSnapshot {
    pub id: String,
    pub liquidity_position: String, // index to liquidity position id
    pub timestamp: BigUint,
    pub user: String, // index to user id
    pub pair: String, // index to pair id
    pub token0_price_icp: BigDecimal,
    pub token0_price_usd: BigDecimal,
    pub token1_price_icp: BigDecimal,
    pub token1_price_usd: BigDecimal,
    pub reserve0: BigDecimal,
    pub reserve1: BigDecimal,
    pub reserve_icp: BigDecimal,
    pub reserve_usd: BigDecimal,
    pub liquidity_token_total_supply: BigDecimal,
    pub liquidity_token_balance: BigDecimal,
}

impl DB<String, SqliteConnection> for LiquidityPositionSnapshot {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::liquidity_position_snapshots::dsl::liquidity_position_snapshots;
        liquidity_position_snapshots.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::liquidity_position_snapshots::dsl::liquidity_position_snapshots;
        replace_into(liquidity_position_snapshots)
            .values(self)
            .execute(conn)
            .expect("Error in inserting liquidity position snapshots");
    }
}

#[derive(Queryable, Insertable, Identifiable)]
#[table_name = "add_liquidity"]
pub struct AddLiquidity {
    pub id: i32,
    pub timestamp: BigUint,
    pub pair: String, // index to pair id

    pub liquidity_provider: String,
    pub liquidity: BigDecimal,
    pub amount0: BigDecimal,
    pub amount1: BigDecimal,
    pub amount_icp: BigDecimal,
    pub amount_usd: BigDecimal,

    pub fee_to: Option<String>,
    pub fee_liquidity: Option<BigDecimal>,
}

impl DB<i32, SqliteConnection> for AddLiquidity {
    fn load(id: i32, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::add_liquidity::dsl::add_liquidity;
        add_liquidity.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::add_liquidity::dsl::add_liquidity;
        replace_into(add_liquidity)
            .values(self)
            .execute(conn)
            .expect("Error in inserting add liquidity");
    }
}

#[derive(Queryable, Insertable, Identifiable)]
#[table_name = "remove_liquidity"]
pub struct RemoveLiquidity {
    pub id: i32,
    pub timestamp: BigUint,
    pub pair: String, // index to pair id

    pub liquidity_provider: String,
    pub liquidity: BigDecimal,
    pub amount0: BigDecimal,
    pub amount1: BigDecimal,
    pub amount_icp: BigDecimal,
    pub amount_usd: BigDecimal,

    pub fee_to: Option<String>,
    pub fee_liquidity: Option<BigDecimal>,
}

impl DB<i32, SqliteConnection> for RemoveLiquidity {
    fn load(id: i32, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::remove_liquidity::dsl::remove_liquidity;
        remove_liquidity.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::remove_liquidity::dsl::remove_liquidity;
        replace_into(remove_liquidity)
            .values(self)
            .execute(conn)
            .expect("Error in inserting remove liquidity");
    }
}

#[derive(Queryable, Insertable, Identifiable, Clone)]
#[table_name = "bundle"]
pub struct Bundle {
    pub id: i32,
    pub icp_price: BigDecimal,
    pub timestamp: Option<BigUint>,
}

impl DB<i32, SqliteConnection> for Bundle {
    fn load(id: i32, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::bundle::dsl::bundle;
        bundle.find(id).first(conn)
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "sonic_day_data"]
pub struct SonicDayData {
    pub id: i32,
    pub date: i32,

    pub daily_volume_icp: BigDecimal,
    pub daily_volume_usd: BigDecimal,
    pub daily_volume_untracked: BigDecimal,

    pub total_volume_icp: BigDecimal,
    pub total_liquidity_icp: BigDecimal,
    pub total_volume_usd: BigDecimal,
    pub total_liquidity_usd: BigDecimal,

    pub tx_count: BigUint,
}

impl DB<i32, SqliteConnection> for SonicDayData {
    fn load(id: i32, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::sonic_day_data::dsl::sonic_day_data;
        sonic_day_data.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::sonic_day_data::dsl::sonic_day_data;
        replace_into(sonic_day_data)
            .values(self)
            .execute(conn)
            .expect("Error in inserting sonic day data");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating sonic day data");
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "pair_hour_data"]
pub struct PairHourData {
    pub id: String,
    pub hour_start_unix: i32,
    pub pair: String, // index to pair id

    pub reserve0: BigDecimal,
    pub reserve1: BigDecimal,

    pub total_supply: BigDecimal,

    pub reserve_icp: BigDecimal,
    pub reserve_usd: BigDecimal,

    pub hourly_volume_token0: BigDecimal,
    pub hourly_volume_token1: BigDecimal,
    pub hourly_volume_icp: BigDecimal,
    pub hourly_volume_usd: BigDecimal,
    pub hourly_txs: BigUint,
}

impl DB<String, SqliteConnection> for PairHourData {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::pair_hour_data::dsl::pair_hour_data;
        pair_hour_data.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::pair_hour_data::dsl::pair_hour_data;
        replace_into(pair_hour_data)
            .values(self)
            .execute(conn)
            .expect("Error in inserting pair hour data");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating pair hour data");
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "pair_day_data"]
pub struct PairDayData {
    pub id: String,
    pub date: i32,
    pub pair: String, // index to pair id

    pub reserve0: BigDecimal,
    pub reserve1: BigDecimal,

    pub total_supply: BigDecimal,

    pub reserve_icp: BigDecimal,
    pub reserve_usd: BigDecimal,

    pub daily_volume_token0: BigDecimal,
    pub daily_volume_token1: BigDecimal,
    pub daily_volume_icp: BigDecimal,
    pub daily_volume_usd: BigDecimal,
    pub daily_txs: BigUint,
}

impl DB<String, SqliteConnection> for PairDayData {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::pair_day_data::dsl::pair_day_data;
        pair_day_data.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::pair_day_data::dsl::pair_day_data;
        replace_into(pair_day_data)
            .values(self)
            .execute(conn)
            .expect("Error in inserting pair hour data");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating pair day data");
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "token_day_data"]
pub struct TokenDayData {
    pub id: String,
    pub date: i32,
    pub token: String, // index to token id

    pub daily_volume_token: BigDecimal,
    pub daily_volume_icp: BigDecimal,
    pub daily_volume_usd: BigDecimal,
    pub daily_txs: BigUint,

    pub total_liquidity_token: BigDecimal,
    pub total_liquidity_icp: BigDecimal,
    pub total_liquidity_usd: BigDecimal,

    pub price_usd: BigDecimal,
}

impl DB<String, SqliteConnection> for TokenDayData {
    fn load(id: String, conn: &SqliteConnection) -> QueryResult<Self> {
        use schema::token_day_data::dsl::token_day_data;
        token_day_data.find(id).first(conn)
    }

    fn insert(&self, conn: &SqliteConnection) {
        use schema::token_day_data::dsl::token_day_data;
        replace_into(token_day_data)
            .values(self)
            .execute(conn)
            .expect("Error in inserting pair hour data");
    }

    fn update(&self, conn: &SqliteConnection) {
        update(self)
            .set(self)
            .execute(conn)
            .expect("Error in updating token day data");
    }
}

#[derive(Queryable, Insertable, Identifiable, AsChangeset, Default)]
#[table_name = "sync_time"]
pub struct SyncTime {
    pub id: i32,
    pub time: BigUint,
    pub tx_id: i32,
}