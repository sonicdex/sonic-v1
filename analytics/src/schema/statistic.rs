use juniper::FieldResult;
use crate::BigUint;
use crate::BigDecimal;
use crate::db::Sqlite;
use crate::schema::token::Token;
use crate::schema::pair::Pair;

#[derive(GraphQLObject)]
pub struct Bundle {
    #[graphql(description = "Price id, always 1 in USD")]
    id: juniper::ID,
    #[graphql(description = "ICP price")]
    icp_price: BigDecimal,
    #[graphql(description = "Synchronized timestamp")]
    timestamp: BigUint,
}

impl From<crate::model::Bundle> for Bundle {
    fn from(b: crate::model::Bundle) -> Self {
        Self {
            id: juniper::ID::new(b.id.to_string()),
            icp_price: b.icp_price,
            timestamp: b.timestamp.unwrap_or(0u64.into())
        }
    }
}

#[derive(GraphQLObject)]
pub struct SonicDayData {
    #[graphql(description = "Day ID, unix timestamp in day")]
    id: juniper::ID,
    #[graphql(description = "Unix timestamp in second")]
    date: i32,

    #[graphql(description = "Daily trade volume in ICP", name = "dailyVolumeICP")]
    daily_volume_icp: BigDecimal,
    #[graphql(description = "Daily trade volume in USD", name = "dailyVolumeUSD")]
    daily_volume_usd: BigDecimal,
    #[graphql(description = "Daily untracked trade volume in USD")]
    daily_volume_untracked: BigDecimal,

    #[graphql(description = "Total trade volume in ICP", name = "totalVolumeICP")]
    total_volume_icp: BigDecimal,
    #[graphql(description = "Total liquidity in ICP", name = "totalLiquidityICP")]
    total_liquidity_icp: BigDecimal,
    #[graphql(description = "Total trade volume in USD", name = "totalVolumeUSD")]
    total_volume_usd: BigDecimal,
    #[graphql(description = "Total liquidity in USD", name = "totalLiquidityUSD")]
    total_liquidity_usd: BigDecimal,

    #[graphql(description = "Daily transaction count")]
    tx_count: BigUint,
}

impl From<crate::model::SonicDayData> for SonicDayData {
    fn from(s: crate::model::SonicDayData) -> Self {
        Self {
            id: juniper::ID::new(s.id.to_string()),
            date: s.date,
            daily_volume_icp: s.daily_volume_icp,
            daily_volume_usd: s.daily_volume_usd,
            daily_volume_untracked: s.daily_volume_untracked,
            total_volume_icp: s.total_volume_icp,
            total_liquidity_icp: s.total_liquidity_icp,
            total_volume_usd: s.total_volume_usd,
            total_liquidity_usd: s.total_liquidity_usd,
            tx_count: s.tx_count
        }
    }
}

pub struct PairHourData {
    id: juniper::ID,
    hour_start_unix: i32,
    pair: juniper::ID, // index to pair id

    reserve0: BigDecimal,
    reserve1: BigDecimal,

    total_supply: BigDecimal,

    reserve_icp: BigDecimal,
    reserve_usd: BigDecimal,

    hourly_volume_token0: BigDecimal,
    hourly_volume_token1: BigDecimal,
    hourly_volume_icp: BigDecimal,
    hourly_volume_usd: BigDecimal,
    hourly_txs: BigUint,
}

impl From<crate::model::PairHourData> for PairHourData {
    fn from(p: crate::model::PairHourData) -> Self {
        Self {
            id: juniper::ID::new(p.id.to_string()),
            hour_start_unix: p.hour_start_unix,
            pair: p.pair.into(),
            reserve0: p.reserve0,
            reserve1: p.reserve1,
            total_supply: p.total_supply,
            reserve_icp: p.reserve_icp,
            reserve_usd: p.reserve_usd,
            hourly_volume_token0: p.hourly_volume_token0,
            hourly_volume_token1: p.hourly_volume_token1,
            hourly_volume_icp: p.hourly_volume_icp,
            hourly_volume_usd: p.hourly_volume_usd,
            hourly_txs: p.hourly_txs
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl PairHourData {
    #[graphql(description = "ID of pair hour data, combined with pair id and start hour")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "Start hour in unix timestamp in second")]
    fn hour_start_unix(&self) -> FieldResult<i32> {
        Ok(self.hour_start_unix.to_owned())
    }

    #[graphql(description = "Corresponding pair")]
    fn pair(&self, context: &Sqlite) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(self.pair.to_string())?)
        )
    }

    #[graphql(description = "Reserve amount of base token")]
    fn reserve0(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve0.to_owned())
    }

    #[graphql(description = "Reserve amount of quote token")]
    fn reserve1(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve1.to_owned())
    }

    #[graphql(description = "Total supply of lp token in the pair")]
    fn total_supply(&self) -> FieldResult<BigDecimal> {
        Ok(self.total_supply.to_owned())
    }

    #[graphql(description = "Reserve amount in ICP", name = "reserveICP")]
    fn reserve_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve_icp.to_owned())
    }

    #[graphql(description = "Reserve amount in USD", name = "reserveUSD")]
    fn reserve_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve_usd.to_owned())
    }

    #[graphql(description = "Base token's hourly trade volume")]
    fn hourly_volume_token0(&self) -> FieldResult<BigDecimal> {
        Ok(self.hourly_volume_token0.to_owned())
    }

    #[graphql(description = "Quote token's hourly trade volume")]
    fn hourly_volume_token1(&self) -> FieldResult<BigDecimal> {
        Ok(self.hourly_volume_token1.to_owned())
    }

    #[graphql(description = "Hourly trade volume in ICP", name = "hourlyVolumeICP")]
    fn hourly_volume_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.hourly_volume_icp.to_owned())
    }

    #[graphql(description = "Hourly trade volume in USD", name = "hourlyVolumeUSD")]
    fn hourly_volume_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.hourly_volume_usd.to_owned())
    }

    #[graphql(description = "Hourly transaction count")]
    fn hourly_txs(&self) -> FieldResult<BigUint> {
        Ok(self.hourly_txs.to_owned())
    }
}

pub struct PairDayData {

    id: juniper::ID,

    date: i32,

    pair: juniper::ID, // index to pair id

    total_supply: BigDecimal,

    reserve_icp: BigDecimal,

    reserve_usd: BigDecimal,


    daily_volume_token0: BigDecimal,

    daily_volume_token1: BigDecimal,

    daily_volume_icp: BigDecimal,

    daily_volume_usd: BigDecimal,

    daily_txs: BigUint,
}

impl From<crate::model::PairDayData> for PairDayData {
    fn from(p: crate::model::PairDayData) -> Self {
        Self {
            id: juniper::ID::new(p.id.to_string()),
            date: p.date,
            pair: p.pair.into(),
            total_supply: p.total_supply,
            reserve_icp: p.reserve_icp,
            reserve_usd: p.reserve_usd,
            daily_volume_token0: p.daily_volume_token0,
            daily_volume_token1: p.daily_volume_token1,
            daily_volume_icp: p.daily_volume_icp,
            daily_volume_usd: p.daily_volume_usd,
            daily_txs: p.daily_txs
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl PairDayData {
    #[graphql(description = "ID of pair")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }
    #[graphql(description = "Date start time in unix timestamp")]
    fn date(&self) -> FieldResult<i32> {
        Ok(self.date.to_owned())
    }
    #[graphql(description = "Corresponding pair")]
    fn pair(&self, context: &Sqlite) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(self.pair.to_string())?)
        )
    }
    #[graphql(description = "Total supply of lp token in the pair")]
    fn total_supply(&self) -> FieldResult<BigDecimal> {
        Ok(self.total_supply.to_owned())
    }
    #[graphql(description = "Reserve amount in ICP", name = "reserveICP")]
    fn reserve_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve_icp.to_owned())
    }
    #[graphql(description = "Reserve amount in USD", name = "reserveUSD")]
    fn reserve_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve_usd.to_owned())
    }
    #[graphql(description = "Base token's daily trade volume")]
    fn daily_volume_token0(&self) -> FieldResult<BigDecimal> {
        Ok(self.daily_volume_token0.to_owned())
    }
    #[graphql(description = "Quote token's daily trade volume")]
    fn daily_volume_token1(&self) -> FieldResult<BigDecimal> {
        Ok(self.daily_volume_token1.to_owned())
    }
    #[graphql(description = "Daily trade volume in ICP", name = "dailyVolumeICP")]
    fn daily_volume_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.daily_volume_icp.to_owned())
    }
    #[graphql(description = "Daily trade volume in USD", name = "dailyVolumeUSD")]
    fn daily_volume_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.daily_volume_usd.to_owned())
    }
    #[graphql(description = "Daily transaction count")]
    fn daily_txs(&self) -> FieldResult<BigUint> {
        Ok(self.daily_txs.to_owned())
    }
}

pub struct TokenDayData {
    id: juniper::ID,
    date: i32,
    token: juniper::ID, // index to token id

    daily_volume_token: BigDecimal,
    daily_volume_icp: BigDecimal,
    daily_volume_usd: BigDecimal,
    daily_txs: BigUint,

    total_liquidity_token: BigDecimal,
    total_liquidity_icp: BigDecimal,
    total_liquidity_usd: BigDecimal,

    price_usd: BigDecimal,
}

impl From<crate::model::TokenDayData> for TokenDayData {
    fn from(t: crate::model::TokenDayData) -> Self {
        Self {
            id: t.id.into(),
            date: t.date,
            token: t.token.into(),
            daily_volume_token: t.daily_volume_token,
            daily_volume_icp: t.daily_volume_icp,
            daily_volume_usd: t.daily_volume_usd,
            daily_txs: t.daily_txs,
            total_liquidity_token: t.total_liquidity_token,
            total_liquidity_icp: t.total_liquidity_icp,
            total_liquidity_usd: t.total_liquidity_usd,
            price_usd: t.price_usd
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl TokenDayData {

    #[graphql(description = "ID of token")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }
    #[graphql(description = "Date start time in unix timestamp")]
    fn date(&self) -> FieldResult<i32> {
        Ok(self.date)
    }
    #[graphql(description = "Corresponding token")]
    fn token(&self, context: &Sqlite) -> FieldResult<Token> {
        Ok(
            Token::from(context.get_token_by_id(self.token.to_string())?)
        )
    }
    #[graphql(description = "Daily trade volume")]
    fn daily_volume_token(&self) -> FieldResult<BigDecimal> {
        Ok(self.daily_volume_token.to_owned())
    }
    #[graphql(description = "Daily trade volume in ICP", name = "dailyVolumeICP")]
    fn daily_volume_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.daily_volume_icp.to_owned())
    }
    #[graphql(description = "Daily trade volume in USD", name = "dailyVolumeUSD")]
    fn daily_volume_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.daily_volume_usd.to_owned())
    }
    #[graphql(description = "Daily transaction count")]
    fn daily_txs(&self) -> FieldResult<BigUint> {
        Ok(self.daily_txs.to_owned())
    }
    #[graphql(description = "Total liquidity of token")]
    fn total_liquidity_token(&self) -> FieldResult<BigDecimal> {
        Ok(self.total_liquidity_token.to_owned())
    }
    #[graphql(description = "Total liquidity in ICP", name = "totalLiquidityICP")]
    fn total_liquidity_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.total_liquidity_icp.to_owned())
    }
    #[graphql(description = "Total liquidity in USD", name = "totalLiquidityUSD")]
    fn total_liquidity_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.total_liquidity_usd.to_owned())
    }
    #[graphql(description = "Token price in USD", name = "priceUSD")]
    fn price_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.price_usd.to_owned())
    }
}

#[derive(GraphQLObject)]
pub struct SyncTime {
    #[graphql(description = "ID, always 1")]
    id: juniper::ID,
    #[graphql(description = "Transaction synchronized time, unix timestamp in second ")]
    time: BigUint,
    #[graphql(description = "Transaction synchronized id so far")]
    tx_id: i32
}

impl From<crate::model::SyncTime> for SyncTime {
    fn from(s: crate::model::SyncTime) -> Self {
        Self {
            id: juniper::ID::new(s.id.to_string()),
            time: s.time,
            tx_id: s.tx_id
        }
    }
}

#[derive(GraphQLObject, Default)]
pub struct ReturnMetrics {
    #[graphql(description = "Return value if hodl the asset")]
    pub hodl_return: BigDecimal,
    #[graphql(description = "Net return")]
    pub net_return: BigDecimal,
    #[graphql(description = "Net return - hodl return")]
    pub sonic_return: BigDecimal,
    #[graphql(description = "Impermanent loss")]
    pub imp_loss: BigDecimal,
    #[graphql(description = "Fees earned")]
    pub fees: BigDecimal
}

#[derive(GraphQLObject, Default)]
pub struct PositionMetrics {
    #[graphql(description = "Impermanent loss")]
    pub imp_loss: BigDecimal,
    #[graphql(description = "Fees earned")]
    pub fees: BigDecimal
}