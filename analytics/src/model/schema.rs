table! {
    add_liquidity (id) {
        id -> Integer,
        timestamp -> Text,
        pair -> Text,
        liquidity_provider -> Text,
        liquidity -> Text,
        amount0 -> Text,
        amount1 -> Text,
        amount_icp -> Text,
        amount_usd -> Text,
        fee_to -> Nullable<Text>,
        fee_liquidity -> Nullable<Text>,
    }
}

table! {
    bundle (id) {
        id -> Integer,
        icp_price -> Text,
        timestamp -> Nullable<Text>,
    }
}

table! {
    liquidity_position_snapshots (id) {
        id -> Text,
        liquidity_position -> Text,
        timestamp -> Text,
        user -> Text,
        pair -> Text,
        token0_price_icp -> Text,
        token0_price_usd -> Text,
        token1_price_icp -> Text,
        token1_price_usd -> Text,
        reserve0 -> Text,
        reserve1 -> Text,
        reserve_icp -> Text,
        reserve_usd -> Text,
        liquidity_token_total_supply -> Text,
        liquidity_token_balance -> Text,
    }
}

table! {
    liquidity_positions (id) {
        id -> Text,
        user -> Text,
        pair -> Text,
        liquidity_token_balance -> Text,
    }
}

table! {
    pair_day_data (id) {
        id -> Text,
        date -> Integer,
        pair -> Text,
        reserve0 -> Text,
        reserve1 -> Text,
        total_supply -> Text,
        reserve_icp -> Text,
        reserve_usd -> Text,
        daily_volume_token0 -> Text,
        daily_volume_token1 -> Text,
        daily_volume_icp -> Text,
        daily_volume_usd -> Text,
        daily_txs -> Text,
    }
}

table! {
    pair_hour_data (id) {
        id -> Text,
        hour_start_unix -> Integer,
        pair -> Text,
        reserve0 -> Text,
        reserve1 -> Text,
        total_supply -> Text,
        reserve_icp -> Text,
        reserve_usd -> Text,
        hourly_volume_token0 -> Text,
        hourly_volume_token1 -> Text,
        hourly_volume_icp -> Text,
        hourly_volume_usd -> Text,
        hourly_txs -> Text,
    }
}

table! {
    pairs (id) {
        id -> Text,
        token0 -> Text,
        token1 -> Text,
        reserve0 -> Text,
        reserve1 -> Text,
        total_supply -> Text,
        reserve_icp -> Text,
        reserve_usd -> Text,
        tracked_reserved_icp -> Text,
        token0_price -> Text,
        token1_price -> Text,
        volume_token0 -> Text,
        volume_token1 -> Text,
        volume_icp -> Text,
        volume_usd -> Text,
        untracked_volume_icp -> Text,
        untracked_volume_usd -> Text,
        tx_count -> Text,
        crated_timestamp -> Text,
        liquidity_provider_count -> Integer,
    }
}

table! {
    raw_txs (id) {
        id -> Integer,
        time -> Text,
        caller -> Text,
        operation -> Text,
        details -> Text,
    }
}

table! {
    remove_liquidity (id) {
        id -> Integer,
        timestamp -> Text,
        pair -> Text,
        liquidity_provider -> Text,
        liquidity -> Text,
        amount0 -> Text,
        amount1 -> Text,
        amount_icp -> Text,
        amount_usd -> Text,
        fee_to -> Nullable<Text>,
        fee_liquidity -> Nullable<Text>,
    }
}

table! {
    sonic (id) {
        id -> Text,
        token_count -> Integer,
        pair_count -> Integer,
        total_volume_icp -> Text,
        total_volume_usd -> Text,
        untracked_volume_icp -> Text,
        untracked_volume_usd -> Text,
        total_liquidity_icp -> Text,
        total_liquidity_usd -> Text,
        tx_count -> Text,
    }
}

table! {
    sonic_day_data (id) {
        id -> Integer,
        date -> Integer,
        daily_volume_icp -> Text,
        daily_volume_usd -> Text,
        daily_volume_untracked -> Text,
        total_volume_icp -> Text,
        total_liquidity_icp -> Text,
        total_volume_usd -> Text,
        total_liquidity_usd -> Text,
        tx_count -> Text,
    }
}

table! {
    swaps (id) {
        id -> Integer,
        timestamp -> Text,
        pair -> Text,
        caller -> Text,
        amount0_in -> Text,
        amount1_in -> Text,
        amount0_out -> Text,
        amount1_out -> Text,
        fee -> Text,
        amount_icp -> Text,
        amount_usd -> Text,
    }
}

table! {
    sync_time (id) {
        id -> Integer,
        time -> Text,
        tx_id -> Integer,
    }
}

table! {
    token_day_data (id) {
        id -> Text,
        date -> Integer,
        token -> Text,
        daily_volume_token -> Text,
        daily_volume_icp -> Text,
        daily_volume_usd -> Text,
        daily_txs -> Text,
        total_liquidity_token -> Text,
        total_liquidity_icp -> Text,
        total_liquidity_usd -> Text,
        price_usd -> Text,
    }
}

table! {
    token_txs (id) {
        id -> Integer,
        token_txid -> Integer,
        timestamp -> Text,
        caller -> Text,
        operation -> Text,
        token -> Text,
        from -> Text,
        to -> Text,
        amount -> Text,
        fee -> Text,
    }
}

table! {
    tokens (id) {
        id -> Text,
        name -> Text,
        symbol -> Text,
        decimals -> Integer,
        total_supply -> Text,
        fee -> Text,
        total_deposited -> Text,
        trade_volume -> Text,
        trade_volume_icp -> Text,
        trade_volume_usd -> Text,
        untracked_volume_icp -> Text,
        untracked_volume_usd -> Text,
        tx_count -> Text,
        total_liquidity -> Text,
        derived_icp -> Text,
    }
}

table! {
    users (id) {
        id -> Text,
        icp_swapped -> Text,
        usd_swapped -> Text,
    }
}

allow_tables_to_appear_in_same_query!(
    add_liquidity,
    bundle,
    liquidity_position_snapshots,
    liquidity_positions,
    pair_day_data,
    pair_hour_data,
    pairs,
    raw_txs,
    remove_liquidity,
    sonic,
    sonic_day_data,
    swaps,
    sync_time,
    token_day_data,
    token_txs,
    tokens,
    users,
);
