use std::collections::HashSet;
use serde::Deserialize;
use diesel::{RunQueryDsl, SqliteConnection};
use reqwest::Error;
use crate::BigDecimal;
use crate::db::Pool;
use crate::model::{Bundle, DB, Pair, Token};

lazy_static! {
    static ref WICP_ADDRESS: &'static str = "utozz-siaaa-aaaam-qaaxq-cai";

    static ref WHITE_LIST: Vec<&'static str> = Vec::from(
        [
            "utozz-siaaa-aaaam-qaaxq-cai", // WICP
            "aanaa-xaaaa-aaaah-aaeiq-cai" // XTC
        ]
    );

    // todo set parameter
    // minimum liquidity required to count towards tracked volume for pairs with small number of Lps
    static ref MINIMUM_USD_THRESHOLD_NEW_PAIRS: BigDecimal = BigDecimal(bigdecimal::BigDecimal::from(4000));
    // minimum liquidity for price to get tracked
    static ref MINIMUM_LIQUIDITY_THRESHOLD_ICP: BigDecimal = BigDecimal(bigdecimal::BigDecimal::from(300));
}

// todo implement get_icp_price_in_usd when stable coin added

pub fn find_icp_per_token(token: Token, conn: &SqliteConnection) -> BigDecimal {
    if token.id == *WICP_ADDRESS {
        return BigDecimal::from(1);
    }
    // loop through whitelist and check if paired with any
    for addr in WHITE_LIST.iter() {
        let pair_id = if (*addr).to_string() < token.id {
            format!("{}:{}", *addr, token.id)
        } else {
            format!("{}:{}", token.id, *addr)
        };
        let pair = Pair::load(pair_id, conn);
        match pair {
            Ok(p) => {
                if p.token0 == token.id && p.reserve_icp > *MINIMUM_LIQUIDITY_THRESHOLD_ICP {
                    let token1 = Token::load(p.token1, conn).unwrap();
                    return p.token1_price * token1.derived_icp;
                }

                if p.token1 == token.id && p.reserve_icp > *MINIMUM_LIQUIDITY_THRESHOLD_ICP {
                    let token0 = Token::load(p.token0, conn).unwrap();
                    return p.token0_price * token0.derived_icp;
                }
            }
            Err(_) => {
                continue;
            }
        }
    }

    // no pair found, return 0
    BigDecimal::default()
}

/// Accepts tokens and amounts, return tracked amount based on token whitelist
/// If one token on whitelist, return amount in that token converted to USD
/// If both are, return average of two amount
/// If neither is, return 0
pub fn get_tracked_volume_usd(
    token0_amount: BigDecimal,
    token0: Token,
    token1_amount: BigDecimal,
    token1: Token,
    pair: Pair,
    conn: &SqliteConnection,
) -> BigDecimal {
    let bundle = Bundle::load(1, conn).expect("Error in getting price bundle");
    let price_0 = token0.derived_icp * bundle.icp_price.clone();
    let price_1 = token1.derived_icp * bundle.icp_price.clone();

    // if # of liquidity providers is less than 5
    if pair.liquidity_provider_count < 5 {
        let reserve0_usd = pair.reserve0 * price_0;
        let reserve1_usd = pair.reserve1 * price_1;
        if WHITE_LIST.contains(&token0.id.as_str()) && WHITE_LIST.contains(&token1.id.as_str()) {
            if reserve0_usd.clone() + reserve1_usd.clone() < *MINIMUM_USD_THRESHOLD_NEW_PAIRS {
                return BigDecimal::default();
            }
        }

        if WHITE_LIST.contains(&token0.id.as_str()) && !WHITE_LIST.contains(&token1.id.as_str()) {
            if reserve0_usd.clone() * 2 < *MINIMUM_USD_THRESHOLD_NEW_PAIRS {
                return BigDecimal::default();
            }
        }

        if !WHITE_LIST.contains(&token0.id.as_str()) && WHITE_LIST.contains(&token1.id.as_str()) {
            if reserve1_usd.clone() * 2 < *MINIMUM_USD_THRESHOLD_NEW_PAIRS {
                return BigDecimal::default();
            }
        }
    } else {
        // both are in whitelist
        if WHITE_LIST.contains(&token0.id.as_str()) && WHITE_LIST.contains(&token1.id.as_str()) {
            return (token0_amount * price_0 + token1_amount * price_1) / 2;
        }

        // take full value of the whitelist token amount
        if WHITE_LIST.contains(&token0.id.as_str()) && !WHITE_LIST.contains(&token1.id.as_str()) {
            return token0_amount * price_0;
        }

        // take full value of the whitelisted token amount
        if !WHITE_LIST.contains(&token0.id.as_str()) && WHITE_LIST.contains(&token1.id.as_str()) {
            return token1_amount * price_1;
        }
    }

    // neither token is on whitelist, return 0
    BigDecimal::default()
}

/// Accepts tokens and amounts, return tracked amount based on token whitelist
//  If one token on whitelist, return amount in that token converted to USD.
//  If both are, return average of two amounts
//  If neither is, return 0
pub fn get_tracked_liquidity_usd(
    token0_amount: BigDecimal,
    token0: Token,
    token1_amount: BigDecimal,
    token1: Token,
    conn: &SqliteConnection,
) -> BigDecimal {
    let bundle = Bundle::load(1, conn).expect("Error in getting price bundle");
    let price_0 = token0.derived_icp * bundle.icp_price.clone();
    let price_1 = token1.derived_icp * bundle.icp_price.clone();

    // both are in whitelist
    if WHITE_LIST.contains(&token0.id.as_str()) && WHITE_LIST.contains(&token1.id.as_str()) {
        return token0_amount * price_0 + token1_amount * price_1;
    }

    // take full value of the whitelist token amount
    if WHITE_LIST.contains(&token0.id.as_str()) && !WHITE_LIST.contains(&token1.id.as_str()) {
        return token0_amount * price_0 * 2;
    }

    // take full value of the whitelisted token amount
    if !WHITE_LIST.contains(&token0.id.as_str()) && WHITE_LIST.contains(&token1.id.as_str()) {
        return token1_amount * price_1 * 2;
    }

    // neither token is on whitelist, return 0
    BigDecimal::default()
}

#[derive(Deserialize)]
struct Price {
    pub mins: i32,
    pub price: String,
}

pub async fn get_icp_price_from_binance() -> Result<String, Error> {
    let result = reqwest::get("https://api.binance.com/api/v3/avgPrice?symbol=ICPUSDT").await;
    match result {
        Ok(res) => {
            Ok(res.json::<Price>()
                .await
                ?.price
            )
        }
        Err(e) => {
            Err(e)
        }
    }
}