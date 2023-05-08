use std::collections::HashMap;
use std::convert::TryInto;
use cap_sdk::Event;
use diesel::SqliteConnection;
use ic_kit::Principal;
use crate::{BigDecimal, BigUint};
use crate::model::{AddLiquidity, Bundle, DB, Pair, RemoveLiquidity, Swap, Token, TokenMetadata, TokenTx};
use crate::sync::daily_update::{update_pair_day_data, update_pair_hour_data, update_sonic_day_data, update_token_day_data};
use crate::sync::helpers::{convert_token_to_decimal, create_liquidity_position, create_liquidity_position_snapshots, create_pair, create_sonic, create_token, create_user, exponent_to_big_uint};
use crate::sync::pricing::{find_icp_per_token, get_tracked_liquidity_usd, get_tracked_volume_usd};

/// create token and add token count
pub fn handle_add_token(token_id: String, token_meta: TokenMetadata, conn: &SqliteConnection) {
    create_token(token_id, token_meta, conn);
    let mut sonic = create_sonic(conn);
    sonic.token_count += 1;
    sonic.update(conn);
}

/// insert token transaction and update total deposited of token
pub fn handle_deposit_withdraw(tx_id: i64, event: &Event, conn: &SqliteConnection) {
    let mut token = handle_tokens(tx_id, event, conn);

    let details: HashMap<_, _> = event.details.to_owned().into_iter().collect();
    let total_deposited: u64 = details.get("totalSupply").unwrap().to_owned().try_into().unwrap();
    token.total_deposited = BigUint::from(total_deposited);
    token.update(conn);
}

// create pair and update pair count
pub fn handle_create_pair(event: &Event, conn: &SqliteConnection) {
    let timestamp = event.time;
    let details: HashMap<_, _> = event.details.to_owned().into_iter().collect();
    let token0_id: String = details.get("token0").unwrap().to_owned().try_into().unwrap();
    let token1_id: String = details.get("token1").unwrap().to_owned().try_into().unwrap();
    create_pair(token0_id, token1_id, timestamp, conn);
    let mut sonic = create_sonic(conn);
    sonic.pair_count += 1;
    sonic.update(conn);
}

pub fn handle_add_liquidity(tx_id: i64, event: &Event, conn: &SqliteConnection) {
    // addLiquidity
    // ("pairId", #Text(pair.id)),
    // ("token0", #Text(pair.token0)),
    // ("token1", #Text(pair.token1)),
    // ("amount0", #U64(u64(amount0))),
    // ("amount1", #U64(u64(amount1))),
    // ("lpAmount", #U64(u64(lpAmount))),
    // ("reserve0", #U64(u64(pair.reserve0))),
    // ("reserve1", #U64(u64(pair.reserve1)))
    let details: HashMap<_, _> = event.details.to_owned().into_iter().collect();

    let pair_id: String = details.get("pairId").unwrap().to_owned().try_into().unwrap();
    let token0_id: String = details.get("token0").unwrap().to_owned().try_into().unwrap();
    let token1_id: String = details.get("token1").unwrap().to_owned().try_into().unwrap();
    let amount0: u64 = details.get("amount0").unwrap().to_owned().try_into().unwrap();
    let amount1: u64 = details.get("amount1").unwrap().to_owned().try_into().unwrap();
    let lp_amount: u64 = details.get("lpAmount").unwrap().to_owned().try_into().unwrap();
    let reserve0 = details.get("reserve0").unwrap().to_owned().try_into().unwrap();
    let reserve1 = details.get("reserve1").unwrap().to_owned().try_into().unwrap();

    handle_reserve(pair_id.clone(), reserve0, reserve1, conn);

    let mut sonic = create_sonic(conn);
    let mut pair = Pair::load(pair_id.clone(), conn).unwrap();
    let mut token0 = Token::load(token0_id, conn).unwrap();
    let mut token1 = Token::load(token1_id, conn).unwrap();

    let token0_amount = convert_token_to_decimal(amount0.into(), token0.decimals);
    let token1_amount = convert_token_to_decimal(amount1.into(), token1.decimals);

    token0.tx_count += 1;
    token1.tx_count += 1;

    let bundle = Bundle::load(1, conn).unwrap();
    let amount_total_icp = token1.derived_icp.clone() * token1_amount.clone() + token0.derived_icp.clone() * token0_amount.clone();
    let amount_total_usd = amount_total_icp.clone() * bundle.icp_price;

    let lp_value = convert_token_to_decimal(lp_amount.into(), 8);
    pair.tx_count += 1;
    pair.total_supply += lp_value.clone();
    sonic.tx_count += 1;

    token0.update(conn);
    token1.update(conn);
    pair.update(conn);
    sonic.update(conn);

    let add_liquidity = AddLiquidity {
        id: tx_id.try_into().expect("tx id overflow"),
        timestamp: event.time.into(),
        pair: pair_id.clone(),
        liquidity_provider: event.caller.to_string(),
        liquidity: lp_value.clone(),
        amount0: token0_amount,
        amount1: token1_amount,
        amount_icp: amount_total_icp,
        amount_usd: amount_total_usd,
        fee_to: None,
        fee_liquidity: None
    };
    add_liquidity.insert(conn);

    let mut liquidity_position = create_liquidity_position(pair_id, event.caller, conn);
    liquidity_position.liquidity_token_balance += lp_value;
    liquidity_position.update(conn);
    create_liquidity_position_snapshots(&liquidity_position, event.time.into(), conn);

    update_pair_day_data(&pair, event.time, conn);
    update_pair_hour_data(&pair, event.time, conn);
    update_sonic_day_data(&sonic, event.time, conn);
    update_token_day_data(&token0, event.time, conn);
    update_token_day_data(&token1, event.time, conn);
}

pub fn handle_remove_liquidity(tx_id: i64, event: &Event, conn: &SqliteConnection) {
    // removeLiquidity
    // ("pairId", #Text(pair.id)),
    // ("token0", #Text(pair.token0)),
    // ("token1", #Text(pair.token1)),
    // ("lpAmount", #U64(u64(lpAmount))),
    // ("amount0", #U64(u64(amount0))),
    // ("amount1", #U64(u64(amount1))),
    // ("reserve0", #U64(u64(pair.reserve0))),
    // ("reserve1", #U64(u64(pair.reserve1)))
    let details: HashMap<_, _> = event.details.to_owned().into_iter().collect();

    let pair_id: String = details.get("pairId").unwrap().to_owned().try_into().unwrap();
    let token0_id: String = details.get("token0").unwrap().to_owned().try_into().unwrap();
    let token1_id: String = details.get("token1").unwrap().to_owned().try_into().unwrap();
    let amount0: u64 = details.get("amount0").unwrap().to_owned().try_into().unwrap();
    let amount1: u64 = details.get("amount1").unwrap().to_owned().try_into().unwrap();
    let lp_amount:u64 = details.get("lpAmount").unwrap().to_owned().try_into().unwrap();
    let reserve0 = details.get("reserve0").unwrap().to_owned().try_into().unwrap();
    let reserve1 = details.get("reserve1").unwrap().to_owned().try_into().unwrap();

    handle_reserve(pair_id.clone(), reserve0, reserve1, conn);

    let mut sonic = create_sonic(conn);
    let mut pair = Pair::load(pair_id.clone(), conn).unwrap();
    let mut token0 = Token::load(token0_id, conn).unwrap();
    let mut token1 = Token::load(token1_id, conn).unwrap();

    let token0_amount = convert_token_to_decimal(amount0.into(), token0.decimals);
    let token1_amount = convert_token_to_decimal(amount1.into(), token1.decimals);

    token0.tx_count += 1;
    token1.tx_count += 1;

    let bundle = Bundle::load(1, conn).unwrap();
    let amount_total_icp = token1.derived_icp.clone() * token1_amount.clone() + token0.derived_icp.clone() * token0_amount.clone();
    let amount_total_usd = amount_total_icp.clone() * bundle.icp_price;

    let lp_value = convert_token_to_decimal(lp_amount.into(), 8);
    pair.tx_count += 1;
    pair.total_supply -= lp_value.clone();
    sonic.tx_count += 1;

    token0.update(conn);
    token1.update(conn);
    pair.update(conn);
    sonic.update(conn);

    let remove_liquidity = RemoveLiquidity {
        id: tx_id.try_into().expect("tx id overflow"),
        timestamp: event.time.into(),
        pair: pair_id.clone(),
        liquidity_provider: event.caller.to_string(),
        liquidity: lp_value.clone(),
        amount0: token0_amount,
        amount1: token1_amount,
        amount_icp: amount_total_icp,
        amount_usd: amount_total_usd,
        fee_to: None,
        fee_liquidity: None
    };
    remove_liquidity.insert(conn);

    let mut liquidity_position = create_liquidity_position(pair_id, event.caller, conn);
    liquidity_position.liquidity_token_balance -= lp_value;
    liquidity_position.update(conn);
    create_liquidity_position_snapshots(&liquidity_position, event.time.into(), conn);

    update_pair_day_data(&pair, event.time, conn);
    update_pair_hour_data(&pair, event.time, conn);
    update_sonic_day_data(&sonic, event.time, conn);
    update_token_day_data(&token0, event.time, conn);
    update_token_day_data(&token1, event.time, conn);
}

pub fn handle_swap(tx_id: i64, event: &Event, conn: &SqliteConnection) {
    // swap
    // ("pairId", #Text(pair.id)),
    // ("from", #Text(path[i])),
    // ("to", #Text(path[i+1])),
    // ("amountIn", #U64(u64(amounts[i]))),
    // ("amountOut", #U64(u64(amounts[i+1]))),
    // ("reserve0", #U64(u64(pair.reserve0))),
    // ("reserve1", #U64(u64(pair.reserve1))),
    // ("fee", #U64(u64(amounts[i] * 3 / 1000)))
    // let details: HashMap<_, _> = event.details.to_owned().into_iter().collect();
    let details: HashMap<_, _> = event.details.to_owned().into_iter().collect();

    let pair_id: String = details.get("pairId").unwrap().to_owned().try_into().unwrap();
    let from: String = details.get("from").unwrap().to_owned().try_into().unwrap();
    let to: String = details.get("to").unwrap().to_owned().try_into().unwrap();
    let amount_in: u64 = details.get("amountIn").unwrap().to_owned().try_into().unwrap();
    let amount_out: u64 = details.get("amountOut").unwrap().to_owned().try_into().unwrap();
    let fee:u64 = details.get("fee").unwrap().to_owned().try_into().unwrap();
    let reserve0 = details.get("reserve0").unwrap().to_owned().try_into().unwrap();
    let reserve1 = details.get("reserve1").unwrap().to_owned().try_into().unwrap();

    handle_reserve(pair_id.clone(), reserve0, reserve1, conn);

    let tokens_id: Vec<_>  = pair_id.split(':').collect();
    let token0_id = tokens_id.get(0).unwrap().to_owned();
    let token1_id = tokens_id.get(1).unwrap().to_owned();

    let mut pair = Pair::load(pair_id.clone(), conn).unwrap();
    let mut token0 = Token::load(token0_id.to_string(), conn).unwrap();
    let mut token1 = Token::load(token1_id.to_string(), conn).unwrap();

    let (amount0_in, amount1_in) = if token0_id == from {
        (convert_token_to_decimal(amount_in.into(), token0.decimals), BigDecimal::default())
    } else {
        (BigDecimal::default(), convert_token_to_decimal(amount_in.into(), token1.decimals))
    };
    let (amount0_out, amount1_out) = if token0_id == to {
        (convert_token_to_decimal(amount_out.into(), token0.decimals), BigDecimal::default())
    } else {
        (BigDecimal::default(), convert_token_to_decimal(amount_out.into(), token1.decimals))
    };
    let amount0_total = amount0_in.clone() + amount0_out.clone();
    let amount1_total = amount1_in.clone() + amount1_out.clone();

    let bundle = Bundle::load(1, conn).expect("Error in loading bundle");
    let derived_amount_icp =
        (
            token0.derived_icp.clone() * amount0_total.clone()
                + token1.derived_icp.clone() * amount1_total.clone()
        ) / 2;
    let derived_amount_usd = derived_amount_icp.clone() * bundle.icp_price.clone();

    let tracked_amount_usd = get_tracked_volume_usd(
        amount0_total.clone(),
        token0.clone(),
        amount1_total.clone(),
        token1.clone(),
        pair.clone(),
        conn
    );

    let tracked_amount_icp = if tracked_amount_usd == BigDecimal::default() {
        BigDecimal::default()
    } else {
        tracked_amount_usd.clone() / bundle.icp_price.clone()
    };

    token0.trade_volume += amount0_in.clone() + amount0_out.clone();
    token0.trade_volume_icp += tracked_amount_icp.clone();
    token0.trade_volume_usd += tracked_amount_usd.clone();
    token0.untracked_volume_icp += derived_amount_icp.clone();
    token0.untracked_volume_usd += derived_amount_usd.clone();
    token0.tx_count += 1;

    token1.trade_volume += amount1_in.clone() + amount1_out.clone();
    token1.trade_volume_icp += tracked_amount_icp.clone();
    token1.trade_volume_usd += tracked_amount_usd.clone();
    token1.untracked_volume_icp += derived_amount_icp.clone();
    token1.untracked_volume_usd += derived_amount_usd.clone();
    token1.tx_count += 1;

    pair.volume_icp += tracked_amount_icp.clone();
    pair.volume_usd += tracked_amount_usd.clone();
    pair.volume_token0 += amount0_total.clone();
    pair.volume_token1 += amount1_total.clone();
    pair.untracked_volume_usd += derived_amount_usd.clone();
    pair.untracked_volume_icp += derived_amount_icp.clone();
    pair.tx_count += 1;

    let mut sonic = create_sonic(conn);
    sonic.total_volume_icp += tracked_amount_icp.clone();
    sonic.total_volume_usd += tracked_amount_usd.clone();
    sonic.untracked_volume_usd += derived_amount_usd.clone();
    sonic.untracked_volume_icp += derived_amount_icp.clone();
    sonic.tx_count += 1;

    let mut user = create_user(event.caller, conn);
    user.icp_swapped += if tracked_amount_icp == BigDecimal::default() {
        derived_amount_icp.clone()
    } else {
        tracked_amount_icp.clone()
    };
    user.usd_swapped += if tracked_amount_usd == BigDecimal::default() {
        derived_amount_usd.clone()
    } else {
        tracked_amount_usd.clone()
    };

    user.update(conn);
    pair.update(conn);
    token0.update(conn);
    token1.update(conn);
    sonic.update(conn);

    let fee_decimals = if token0_id == &from {
        token0.decimals
    } else {
        token1.decimals
    };
    // add swap record
    let swap = Swap {
        id: tx_id.try_into().expect("tx id overflow"),
        timestamp: event.time.into(),
        pair: pair_id.clone(),
        caller: event.caller.to_string(),
        amount0_in: amount0_in.clone(),
        amount1_in: amount1_in.clone(),
        amount0_out: amount0_out.clone(),
        amount1_out: amount1_out.clone(),
        fee: convert_token_to_decimal(fee.into(), fee_decimals),
        amount_icp: if tracked_amount_icp.clone() == BigDecimal::default() {
            derived_amount_icp.clone()
        } else {
            tracked_amount_icp.clone()
        },
        amount_usd: if tracked_amount_usd.clone() == BigDecimal::default() {
            derived_amount_usd.clone()
        } else {
            tracked_amount_usd.clone()
        }
    };

    swap.insert(conn);

    // update day data
    let mut pair_day_data = update_pair_day_data(&pair, event.time, conn);
    let mut pair_hour_data = update_pair_hour_data(&pair, event.time, conn);
    let mut sonic_day_data = update_sonic_day_data(&sonic, event.time, conn);
    let mut token0_day_data = update_token_day_data(&token0, event.time, conn);
    let mut token1_day_data = update_token_day_data(&token1, event.time, conn);

    sonic_day_data.daily_volume_usd += tracked_amount_usd.clone();
    sonic_day_data.daily_volume_icp += tracked_amount_icp.clone();
    sonic_day_data.daily_volume_untracked += derived_amount_usd.clone();
    sonic_day_data.update(conn);

    pair_day_data.daily_volume_icp += tracked_amount_icp.clone();
    pair_day_data.daily_volume_usd += tracked_amount_usd.clone();
    pair_day_data.daily_volume_token0 += amount0_total.clone();
    pair_day_data.daily_volume_token1 += amount1_total.clone();
    pair_day_data.update(conn);

    pair_hour_data.hourly_volume_icp += tracked_amount_icp.clone();
    pair_hour_data.hourly_volume_usd += tracked_amount_usd.clone();
    pair_hour_data.hourly_volume_token0 += amount0_total.clone();
    pair_hour_data.hourly_volume_token1 += amount1_total.clone();
    pair_hour_data.update(conn);

    token0_day_data.daily_volume_icp += amount0_total.clone() * token0.derived_icp.clone();
    token0_day_data.daily_volume_usd += amount0_total.clone() * token0.derived_icp.clone() * bundle.icp_price.clone();
    token0_day_data.daily_volume_token += amount0_total.clone();
    token0.update(conn);

    token1_day_data.daily_volume_icp += amount1_total.clone() * token1.derived_icp.clone();
    token1_day_data.daily_volume_usd += amount1_total.clone() * token1.derived_icp.clone() * bundle.icp_price.clone();
    token1_day_data.daily_volume_token += amount1_total.clone();
    token1.update(conn);
}

pub fn handle_tokens(tx_id: i64, event: &Event, conn: &SqliteConnection) -> Token {
    let details: HashMap<_, _> = event.details.to_owned().into_iter().collect();
    let token_id: String = details.get("tokenId").unwrap().to_owned().try_into().expect("tokenId not exist");
    let token = Token::load(token_id.clone(), conn).expect(format!("token {} not exist", token_id).as_str());
    let decimals = token.decimals;
    let exponent = exponent_to_big_uint(decimals);
    let amount_:u64 = details.get("amount").unwrap().to_owned().try_into().unwrap();
    let amount: BigDecimal = BigUint::from(amount_) / exponent.clone();
    let fee_:u64 = details.get("fee").unwrap().to_owned().try_into().unwrap();
    let fee: BigDecimal = BigUint::from(fee_) / exponent;
    let from_: Principal = details.get("from").unwrap().to_owned().try_into().unwrap();
    let to_: Principal = details.get("to").unwrap().to_owned().try_into().unwrap();
    let token_tx = TokenTx {
        id: tx_id as i32,
        token_txid: details.get("token_txid")
            .map_or(0, |v| {
                let tx: u64 = v.to_owned().try_into().unwrap();
                tx.try_into().expect("token_txid overflow i32")
            }),
        timestamp: event.time.into(),
        caller: event.caller.to_string(),
        operation: event.operation.to_owned(),
        token: token_id,
        from: from_.to_string(),
        to: to_.to_string(),
        amount,
        fee,
    };
    token_tx.insert(conn);

    token
}

fn handle_reserve(pair_id: String, reserve0: u64, reserve1: u64, conn: &SqliteConnection) {
    let mut pair = Pair::load(pair_id.clone(), conn).expect(format!("Pair {} not exist", pair_id).as_str());
    let mut token0 = Token::load(pair.token0.clone(), conn).unwrap();
    let mut token1 = Token::load(pair.token1.clone(), conn).unwrap();
    let mut sonic = create_sonic(conn);

    sonic.total_liquidity_icp -= pair.tracked_reserved_icp.clone();

    token0.total_liquidity -= pair.reserve0.clone();
    token1.total_liquidity -= pair.reserve1.clone();

    pair.reserve0 = convert_token_to_decimal(reserve0.into(), token0.decimals);
    pair.reserve1 = convert_token_to_decimal(reserve1.into(), token1.decimals);

    pair.token0_price = if pair.reserve0.clone() == BigDecimal::default() {
        BigDecimal::default()
    } else {
        pair.reserve0.clone() / pair.reserve1.clone()
    };
    pair.token1_price = if pair.reserve1.clone() == BigDecimal::default() {
        BigDecimal::default()
    } else {
        pair.reserve1.clone() / pair.reserve0.clone()
    };

    pair.update(conn);

    token0.derived_icp = find_icp_per_token(token0.clone(), conn);
    token1.derived_icp = find_icp_per_token(token1.clone(), conn);

    token0.update(conn);
    token1.update(conn);

    let bundle = Bundle::load(1, conn).unwrap();
    let tracked_liquidity_icp = if bundle.icp_price.clone() == BigDecimal::default() {
        BigDecimal::default()
    } else {
        get_tracked_liquidity_usd(pair.reserve0.clone(), token0.clone(), pair.reserve1.clone(), token1.clone(), conn) / bundle.icp_price.clone()
    };

    pair.tracked_reserved_icp = tracked_liquidity_icp.clone();
    pair.reserve_icp = pair.reserve0.clone() * token0.derived_icp.clone() + pair.reserve1.clone() * token1.derived_icp.clone();
    pair.reserve_usd = pair.reserve_icp.clone() * bundle.icp_price.clone();

    sonic.total_liquidity_icp += tracked_liquidity_icp.clone();
    sonic.total_liquidity_usd = sonic.total_liquidity_icp.clone() * bundle.icp_price.clone();

    token0.total_liquidity += pair.reserve0.clone();
    token1.total_liquidity += pair.reserve1.clone();

    pair.update(conn);
    sonic.update(conn);
    token0.update(conn);
    token1.update(conn);
}
