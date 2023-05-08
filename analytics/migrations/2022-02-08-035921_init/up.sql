-- Your SQL goes here

create table if not exists raw_txs
(
    id        int primary key not null,
    time      text            not null,
    caller    text            not null,
    operation text            not null,
    details   text            not null
);

create table if not exists sonic
(
    id                   text primary key not null,

    token_count          integer          not null,
    pair_count           integer          not null,

    total_volume_icp     text             not null,
    total_volume_usd     text             not null,

    untracked_volume_icp text             not null,
    untracked_volume_usd text             not null,

    total_liquidity_icp  text             not null,
    total_liquidity_usd  text             not null,

    tx_count             text             not null
);

create table if not exists users
(
    id          text primary key not null,
    icp_swapped text             not null,
    usd_swapped text             not null
);

create table if not exists tokens
(
    id                   text primary key not null,
    name                 text             not null,
    symbol               text             not null,
    decimals             integer          not null,

    total_supply         text             not null,
    fee                  text             not null,
    total_deposited      text             not null,

    trade_volume         text             not null,
    trade_volume_icp     text             not null,
    trade_volume_usd     text             not null,
    untracked_volume_icp text             not null,
    untracked_volume_usd text             not null,

    tx_count             text             not null,
    total_liquidity      text             not null,
    derived_icp          text             not null
);

create table if not exists swaps
(
    id          integer primary key not null,
    timestamp   text                not null,
    pair        text                not null,
    caller      text                not null,

    amount0_in  text                not null,
    amount1_in  text                not null,
    amount0_out text                not null,
    amount1_out text                not null,
    fee         text                not null,

    amount_icp  text                not null,
    amount_usd  text                not null
);

CREATE INDEX index_swaps_pair on swaps (pair);
CREATE INDEX index_swaps_caller on swaps (caller);

create table if not exists token_txs
(
    id         integer primary key not null,
    token_txid integer             not null,
    timestamp  text                not null,
    caller     text                not null,
    operation  text                not null,
    token      text                not null,
    'from'     text                not null,
    'to'       text                not null,
    amount     text                not null,
    fee        text                not null
);

CREATE INDEX index_tokentx_caller on token_txs (caller);

create table if not exists pairs
(
    id                       text primary key not null,
    token0                   text             not null,
    token1                   text             not null,
    reserve0                 text             not null,
    reserve1                 text             not null,
    total_supply             text             not null,

    reserve_icp              text             not null,
    reserve_usd              text             not null,
    tracked_reserved_icp     text             not null,

    token0_price             text             not null,
    token1_price             text             not null,

    volume_token0            text             not null,
    volume_token1            text             not null,
    volume_icp               text             not null,
    volume_usd               text             not null,
    untracked_volume_icp     text             not null,
    untracked_volume_usd     text             not null,
    tx_count                 text             not null,

    crated_timestamp         text             not null,

    liquidity_provider_count integer          not null
);

CREATE INDEX index_token_token0 on pairs (token0);
CREATE INDEX index_token_token1 on pairs (token1);

create table if not exists liquidity_positions
(
    id                      text primary key not null,
    user                    text             not null,
    pair                    text             not null,
    liquidity_token_balance text             not null
);

CREATE INDEX index_lp_user on liquidity_positions(user);
CREATE INDEX index_lp_pair on liquidity_positions(pair);

create table if not exists liquidity_position_snapshots
(
    id                           text primary key not null,
    liquidity_position           text             not null,
    timestamp                    text             not null,
    user                         text             not null,
    pair                         text             not null,
    token0_price_icp             text             not null,
    token0_price_usd             text             not null,
    token1_price_icp             text             not null,
    token1_price_usd             text             not null,
    reserve0                     text             not null,
    reserve1                     text             not null,
    reserve_icp                  text             not null,
    reserve_usd                  text             not null,
    liquidity_token_total_supply text             not null,
    liquidity_token_balance      text             not null
);

CREATE INDEX index_lps_timestamp on liquidity_position_snapshots(timestamp);
CREATE INDEX index_lps_user on liquidity_position_snapshots(user);
CREATE INDEX index_lps_pair on liquidity_position_snapshots(pair);

create table if not exists add_liquidity
(
    id                 integer primary key not null,
    timestamp          text                not null,
    pair               text                not null,

    liquidity_provider text                not null,
    liquidity          text                not null,
    amount0            text                not null,
    amount1            text                not null,
    amount_icp         text                not null,
    amount_usd         text                not null,

    fee_to             text,
    fee_liquidity      text
);

CREATE INDEX index_al_pair on add_liquidity(pair);
CREATE INDEX index_al_lp on add_liquidity(liquidity_provider);

create table if not exists remove_liquidity
(
    id                 integer primary key not null,
    timestamp          text                not null,
    pair               text                not null,

    liquidity_provider text                not null,
    liquidity          text                not null,
    amount0            text                not null,
    amount1            text                not null,
    amount_icp         text                not null,
    amount_usd         text                not null,

    fee_to             text,
    fee_liquidity      text
);

CREATE INDEX index_rl_pair on remove_liquidity(pair);
CREATE INDEX index_rl_lp on remove_liquidity(liquidity_provider);

create table if not exists bundle
(
    id        integer primary key not null,
    icp_price text                not null
);

create table if not exists sonic_day_data
(
    id                     integer primary key not null,
    date                   integer             not null,

    daily_volume_icp       text                not null,
    daily_volume_usd       text                not null,
    daily_volume_untracked text                not null,

    total_volume_icp       text                not null,
    total_liquidity_icp    text                not null,
    total_volume_usd       text                not null,
    total_liquidity_usd    text                not null,

    tx_count               text                not null
);

CREATE INDEX index_sonic_date on sonic_day_data(date);

create table if not exists pair_hour_data
(
    id                   text primary key not null,
    hour_start_unix      integer          not null,
    pair                 text             not null,

    reserve0             text             not null,
    reserve1             text             not null,

    total_supply         text             not null,

    reserve_icp          text             not null,
    reserve_usd          text             not null,

    hourly_volume_token0 text             not null,
    hourly_volume_token1 text             not null,
    hourly_volume_icp    text             not null,
    hourly_volume_usd    text             not null,
    hourly_txs           text             not null
);

CREATE INDEX index_ph_hour on pair_hour_data(hour_start_unix);
CREATE INDEX index_ph_pair on pair_hour_data(pair);

create table if not exists pair_day_data
(
    id                  text primary key not null,
    date                integer          not null,
    pair                text             not null,

    reserve0            text             not null,
    reserve1            text             not null,

    total_supply        text             not null,

    reserve_icp         text             not null,
    reserve_usd         text             not null,

    daily_volume_token0 text             not null,
    daily_volume_token1 text             not null,
    daily_volume_icp    text             not null,
    daily_volume_usd    text             not null,
    daily_txs           text             not null
);

CREATE INDEX index_pd_date on pair_day_data(date);
CREATE INDEX index_pd_pair on pair_day_data(pair);

create table if not exists token_day_data
(
    id                    text primary key not null,
    date                  integer          not null,
    token                 text             not null,

    daily_volume_token    text             not null,
    daily_volume_icp      text             not null,
    daily_volume_usd      text             not null,
    daily_txs             text             not null,

    total_liquidity_token text             not null,
    total_liquidity_icp   text             not null,
    total_liquidity_usd   text             not null,

    price_usd             text             not null
);

CREATE INDEX index_td_date on token_day_data(date);
CREATE INDEX index_td_token on token_day_data(token);