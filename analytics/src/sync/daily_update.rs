use diesel::SqliteConnection;
use crate::model::{Bundle, DB, Pair, PairDayData, PairHourData, Sonic, SonicDayData, Token, TokenDayData};

pub fn update_sonic_day_data(sonic: &Sonic, timestamp: u64, conn: &SqliteConnection) -> SonicDayData {
    // timestamp is unix epoch in millisecond
    let day_id = timestamp / 86_400_000;
    // unix epoch in second
    let day_start_timestamp = day_id * 86400;
    let mut sonic_day_data = SonicDayData::load(day_id as i32, conn)
        .unwrap_or_else(|_| {
           let mut data = SonicDayData::default();
            data.id = day_id as i32;
            data.date = day_start_timestamp as i32;
            data.insert(conn);
            data
        });
    sonic_day_data.total_liquidity_icp = sonic.total_liquidity_icp.to_owned();
    sonic_day_data.total_liquidity_usd = sonic.total_liquidity_usd.to_owned();
    sonic_day_data.total_volume_icp = sonic.total_volume_icp.to_owned();
    sonic_day_data.total_volume_usd = sonic.total_volume_usd.to_owned();
    sonic_day_data.tx_count = sonic.tx_count.to_owned();
    sonic_day_data.update(conn);

    sonic_day_data
}

pub fn update_pair_day_data(pair: &Pair, timestamp: u64, conn: &SqliteConnection) -> PairDayData {
    // timestamp is unix epoch in millisecond
    let day_id = timestamp / 86_400_000;
    // unix epoch in second
    let day_start_timestamp = day_id * 86400;
    let day_pair_id = format!("{}:{}", pair.id, day_id);
    let mut pair_day_data = PairDayData::load(day_pair_id.clone(), conn)
        .unwrap_or_else(|_| {
            let mut data = PairDayData::default();
            data.id = day_pair_id;
            data.date = day_start_timestamp as i32;
            data.pair = pair.id.to_owned();
            data.insert(conn);
            data
        });
    pair_day_data.total_supply = pair.total_supply.to_owned();
    pair_day_data.reserve0 = pair.reserve0.to_owned();
    pair_day_data.reserve1 = pair.reserve1.to_owned();
    pair_day_data.reserve_icp = pair.reserve_icp.to_owned();
    pair_day_data.reserve_usd = pair.reserve_usd.to_owned();
    pair_day_data.daily_txs += 1;
    pair_day_data.update(conn);

    pair_day_data
}

pub fn update_pair_hour_data(pair: &Pair, timestamp: u64, conn: &SqliteConnection) -> PairHourData {
    let hour_id = timestamp / 3_600_000;
    let hour_start_unix = hour_id * 3600;
    let hour_pair_id = format!("{}:{}", pair.id, hour_id);
    let mut pair_hour_data = PairHourData::load(hour_pair_id.clone(), conn)
        .unwrap_or_else(|_| {
            let mut data = PairHourData::default();
            data.id = hour_pair_id;
            data.hour_start_unix = hour_start_unix as i32;
            data.pair = pair.id.to_owned();
            data.insert(conn);
            data
        });
    pair_hour_data.total_supply = pair.total_supply.to_owned();
    pair_hour_data.reserve0 = pair.reserve0.to_owned();
    pair_hour_data.reserve1 = pair.reserve1.to_owned();
    pair_hour_data.reserve_icp = pair.reserve_icp.to_owned();
    pair_hour_data.reserve_usd = pair.reserve_usd.to_owned();
    pair_hour_data.hourly_txs += 1;
    pair_hour_data.update(conn);

    pair_hour_data
}

pub fn update_token_day_data(token: &Token, timestamp: u64, conn: &SqliteConnection) -> TokenDayData {
    let bundle = Bundle::load(1, conn).expect("Error in loading bundle");
    // timestamp is unix epoch in millisecond
    let day_id = timestamp / 86_400_000;
    // unix epoch in second
    let day_start_timestamp = day_id * 86400;
    let day_token_id = format!("{}:{}", token.id, day_id);

    let mut token_day_data = TokenDayData::load(day_token_id.clone(), conn)
        .unwrap_or_else(|_| {
            let mut data = TokenDayData::default();
            data.id = day_token_id;
            data.date = day_start_timestamp as i32;
            data.token = token.id.to_owned();
            data.price_usd = token.derived_icp.to_owned() * bundle.icp_price.clone();
            data.insert(conn);
            data
        });
    token_day_data.price_usd = token.derived_icp.to_owned() * bundle.icp_price.clone();
    token_day_data.total_liquidity_token = token.total_liquidity.to_owned();
    token_day_data.total_liquidity_icp = token.total_liquidity.to_owned() * token.derived_icp.to_owned();
    token_day_data.total_liquidity_usd = token_day_data.total_liquidity_icp.clone() * bundle.icp_price;
    token_day_data.daily_txs += 1;
    token_day_data.update(conn);

    token_day_data
}

