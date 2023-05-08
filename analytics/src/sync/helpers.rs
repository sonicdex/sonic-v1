use diesel::{SqliteConnection};
use ic_kit::Principal;
use crate::{BigDecimal, BigUint};
use crate::model::{Bundle, DB, LiquidityPosition, LiquidityPositionSnapshot, Pair, Sonic, Token, TokenMetadata, User};

pub const SONIC_ADDRESS: &'static str = "3xwpq-ziaaa-aaaah-qcn4a-cai";

pub fn create_sonic(conn: &SqliteConnection) -> Sonic {
    Sonic::load(SONIC_ADDRESS.to_string(), conn)
        .unwrap_or_else(|_| {
            let mut sonic = Sonic::default();
            sonic.id = SONIC_ADDRESS.to_string();
            sonic.insert(conn);
            sonic
        })
}

pub fn create_user(user_id: Principal, conn: &SqliteConnection) -> User {
    User::load(user_id.to_string(), conn)
        .unwrap_or_else(|_| {
            let mut user = User::default();
            user.id = user_id.to_string();
            user.insert(conn);
            user
        })
}

pub fn create_token(token_id: String, token_meta: TokenMetadata, conn: &SqliteConnection) -> Token {
    Token::load(token_id.clone(), conn)
        .unwrap_or_else(|_| {
            let token = Token::from_metadata(token_id, token_meta);
            token.insert(conn);
            token
        })
}

pub fn create_pair(token0: String, token1: String, timestamp: u64, conn: &SqliteConnection) -> Pair {
    let pair_id = format!("{}:{}", token0, token1);
    Pair::load(pair_id.clone(), conn)
        .unwrap_or_else(|_| {
            let mut pair = Pair::default();
            pair.id = pair_id;
            pair.token0 = token0;
            pair.token1 = token1;
            pair.crated_timestamp = BigUint(num_bigint::BigUint::from(timestamp));
            pair.insert(conn);
            pair
        })
}

pub fn create_liquidity_position(pair_id: String, user: Principal, conn: &SqliteConnection) -> LiquidityPosition {
    let id = format!("{}:{}", pair_id.clone(), user);
    LiquidityPosition::load(id.clone(), conn)
        .unwrap_or_else(|_| {
            let mut pair = Pair::load(pair_id.clone(), conn).expect(format!("Pair {} must exist", pair_id.clone()).as_str());
            pair.liquidity_provider_count += 1;
            let mut liquidity_position = LiquidityPosition::default();
            liquidity_position.id = id;
            liquidity_position.user = user.to_string();
            liquidity_position.pair = pair_id;
            liquidity_position.insert(conn);
            pair.update(conn);
            liquidity_position
        })
}

pub fn create_liquidity_position_snapshots(position: &LiquidityPosition, timestamp: BigUint, conn: &SqliteConnection) {
    let bundle = Bundle::load(1, conn).unwrap();
    let pair = Pair::load(position.pair.to_owned(), conn).expect(format!("Pair {} must exist", position.pair.to_owned()).as_str());
    let token0 = Token::load(pair.token0.to_owned(), conn).expect(format!("Token {} must exist", pair.token0.as_str()).as_str());
    let token1 = Token::load(pair.token1.to_owned(), conn).expect(format!("Token {} must exist", pair.token1.as_str()).as_str());

    let snapshot = LiquidityPositionSnapshot {
        id: format!("{}:{}", position.id.to_owned(), timestamp.0),
        liquidity_position: position.id.to_owned(),
        timestamp,
        user: position.user.to_owned(),
        pair: position.pair.to_owned(),
        token0_price_icp: token0.derived_icp.clone(),
        token0_price_usd: token0.derived_icp * bundle.icp_price.clone(),
        token1_price_icp: token1.derived_icp.clone(),
        token1_price_usd: token1.derived_icp * bundle.icp_price,
        reserve0: pair.reserve0,
        reserve1: pair.reserve1,
        reserve_icp: pair.reserve_icp,
        reserve_usd: pair.reserve_usd,
        liquidity_token_total_supply: pair.total_supply,
        liquidity_token_balance: position.liquidity_token_balance.to_owned()
    };
    snapshot.insert(conn);
}

pub fn exponent_to_big_uint(decimal: i32) -> BigUint {
    let mut bd = BigUint::from(1u32);
    for _ in 0..decimal {
        bd = bd * BigUint::from(10u32);
    }
    bd
}

pub fn convert_icp_decimal(icp: BigUint) -> BigDecimal {
    icp / exponent_to_big_uint(8)
}

pub fn convert_token_to_decimal(token_amount: BigUint, decimal: i32) -> BigDecimal {
    if decimal == 0 {
        BigDecimal::default()
    }
    else {
        token_amount / exponent_to_big_uint(decimal)
    }
}