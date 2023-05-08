use juniper::FieldResult;
use crate::BigUint;
use crate::BigDecimal;
use crate::db::Sqlite;
use crate::model::DB;
use crate::schema::liquidity::{LiquidityPosition, LiquidityPositionSnapshot};
use crate::schema::statistic::{PairDayData, PairHourData};
use crate::schema::token::Token;
use crate::schema::transaction::{AddLiquidity, RemoveLiquidity, Swap};

pub struct Pair {
    id: juniper::ID,

    token0: juniper::ID, // index to token0 id
    token1: juniper::ID, // index to token1 id
    reserve0: BigDecimal,
    reserve1: BigDecimal,
    total_supply: BigDecimal,

    reserve_icp: BigDecimal,
    reserve_usd: BigDecimal,
    tracked_reserved_icp: BigDecimal,

    token0_price: BigDecimal,
    token1_price: BigDecimal,

    volume_token0: BigDecimal,
    volume_token1: BigDecimal,
    volume_icp: BigDecimal,
    volume_usd: BigDecimal,
    untracked_volume_icp: BigDecimal,
    untracked_volume_usd: BigDecimal,
    tx_count: BigUint,

    crated_timestamp: BigUint,

    liquidity_provider_count: i32,
}

impl From<crate::model::Pair> for Pair {
    fn from(p: crate::model::Pair) -> Self {
        Self {
            id: p.id.into(),
            token0: p.token0.into(),
            token1: p.token1.into(),
            reserve0: p.reserve0,
            reserve1: p.reserve1,
            total_supply: p.total_supply,
            reserve_icp: p.reserve_icp,
            reserve_usd: p.reserve_usd,
            tracked_reserved_icp: p.tracked_reserved_icp,
            token0_price: p.token0_price,
            token1_price: p.token1_price,
            volume_token0: p.volume_token0,
            volume_token1: p.volume_token1,
            volume_icp: p.volume_icp,
            volume_usd: p.volume_usd,
            untracked_volume_icp: p.untracked_volume_icp,
            untracked_volume_usd: p.untracked_volume_usd,
            tx_count: p.tx_count,
            crated_timestamp: p.crated_timestamp,
            liquidity_provider_count: p.liquidity_provider_count
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl Pair {

    #[graphql(description = "ID of the Pair")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "Base token id of the pair")]
    fn token0(&self, context: &Sqlite) -> FieldResult<Token> {
        let conn = context.pool.get().unwrap();
        Ok(
            Token::from(crate::model::Token::load(self.token0.to_string(), &conn)?)
        )
    }

    #[graphql(description = "Quote token id of the pair")]
    fn token1(&self, context: &Sqlite) -> FieldResult<Token> {
        let conn = context.pool.get().unwrap();
        Ok(
            Token::from(crate::model::Token::load(self.token1.to_string(), &conn)?)
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

    #[graphql(description = "Total supply of the lp token", name = "totalSupply")]
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

    #[graphql(description = "Tracked reserve amount in ICP, computed by whitelist token", name = "trackedReserveICP")]
    fn tracked_reserved_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.tracked_reserved_icp.to_owned())
    }

    #[graphql(description = "Base token's price in quote token", name = "token0Price")]
    fn token0_price(&self) -> FieldResult<BigDecimal> {
        Ok(self.token0_price.to_owned())
    }

    #[graphql(description = "Quote token's price in base token", name = "token1Price")]
    fn token1_price(&self) -> FieldResult<BigDecimal> {
        Ok(self.token1_price.to_owned())
    }

    #[graphql(description = "Base token's trade volume", name = "volumeToken0")]
    fn volume_token0(&self) -> FieldResult<BigDecimal> {
        Ok(self.volume_token0.to_owned())
    }

    #[graphql(description = "Quote token's trade volume", name = "volumeToken1")]
    fn volume_token1(&self) -> FieldResult<BigDecimal> {
        Ok(self.volume_token1.to_owned())
    }

    #[graphql(description = "Trade volume in ICP", name = "volumeICP")]
    fn volume_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.volume_icp.to_owned())
    }

    #[graphql(description = "Trade volume in USD", name = "volumeUSD")]
    fn volume_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.volume_usd.to_owned())
    }

    #[graphql(description = "Untracked trade volume in ICP", name = "untrackedVolumeICP")]
    fn untracked_volume_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.untracked_volume_icp.to_owned())
    }

    #[graphql(description = "Untracked trade volume in USD", name = "untrackedVolumeUSD")]
    fn untracked_volume_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.untracked_volume_usd.to_owned())
    }

    #[graphql(description = "Transaction count of the pair", name = "txCount")]
    fn tx_count(&self) -> FieldResult<BigUint> {
        Ok(self.tx_count.to_owned())
    }

    #[graphql(description = "Pair created timestamp", name = "createdTimestamp")]
    fn created_timestamp(&self) -> FieldResult<BigUint> {
        Ok(self.crated_timestamp.to_owned())
    }

    #[graphql(description = "Number of liquidity provider", name = "liquidityProviderCount")]
    fn liquidity_provider_count(&self) -> FieldResult<i32> {
        Ok(self.liquidity_provider_count)
    }

    #[graphql(description = "Get pair's hour statistic data. Hour from and to is unix time stamp of an hour start", name = "pairHourData")]
    fn pair_hour_data(&self, context: &Sqlite, hour_from: i32, hour_to: i32) -> FieldResult<Vec<PairHourData>> {
        Ok(
            context.get_pair_hour_data(self.id.to_string(), hour_from, hour_to)?
                .into_iter()
                .map(|p| {
                    PairHourData::from(p)
                })
                .collect()
        )
    }

    #[graphql(description = "Get pair's day statistic data. Date from and to is unix timestamp", name = "pairDayData")]
    fn pair_day_data(&self, context: &Sqlite, date_from: i32, date_to: i32) -> FieldResult<Vec<PairDayData>> {
        Ok(
            context.get_pair_day_data(self.id.to_string(), date_from, date_to)?
                .into_iter()
                .map(|p| {
                    PairDayData::from(p)
                })
                .collect()
        )
    }

    #[graphql(description = "Get liquidity positions of the pair, with offset and limit", name = "liquidityPositions")]
    fn liquidity_positions(&self, context: &Sqlite, offset: i32, limit: i32) -> FieldResult<Vec<LiquidityPosition>> {
        Ok(
            context.get_liquidity_positions_by_pair(self.id.to_string(), offset as i64, limit as i64)?
                .into_iter()
                .map(|l| {
                    LiquidityPosition::from(l)
                })
                .collect()
        )
    }

    #[graphql(description = "Get liquidity positions snapshots of the pair", name = "liquidityPositionSnapshots")]
    fn liquidity_position_snapshots(&self, context: &Sqlite) -> FieldResult<Vec<LiquidityPositionSnapshot>> {
        Ok(
            context.get_liquidity_position_snapshots_by_pair(self.id.to_string())?
                .into_iter()
                .map(|l| {
                    LiquidityPositionSnapshot::from(l)
                })
                .collect()
        )
    }

    #[graphql(description = "Get add liquidity tx of the pair, with offset and limit", name = "addLiquidity",
        arguments(
            offset(
                default = 0,
                description = "offset"
            ),
            limit(
                default = 50,
                description = "limit"
        )
    ))]
    fn add_liquidity(&self, context: &Sqlite, offset: i32, limit: i32) -> FieldResult<Vec<AddLiquidity>> {
        Ok(
            context.get_add_liquidity_by_pair(self.id.to_string(), offset as i64, limit as i64)?
                .into_iter()
                .map(|a| {
                    AddLiquidity::from(a)
                })
                .collect()
        )
    }

    #[graphql(description = "Get remove liquidity tx of the pair, with offset and limit", name = "removeLiquidity",
        arguments(
            offset(
                default = 0,
                description = "offset"
            ),
            limit(
                default = 50,
                description = "limit"
            )
    ))]
    fn remove_liquidity(&self, context: &Sqlite, offset: i32, limit: i32) -> FieldResult<Vec<RemoveLiquidity>> {
        Ok(
            context.get_remove_liquidity_by_pair(self.id.to_string(), offset as i64, limit as i64)?
                .into_iter()
                .map(|r| {
                    RemoveLiquidity::from(r)
                })
                .collect()
        )
    }

    #[graphql(description = "Get swap tx of the pair, with offset and limit",
        arguments(
            offset(
                default = 0,
                description = "offset"
            ),
            limit(
                default = 50,
                description = "limit"
            )
    ))]
    fn swaps(&self, context: &Sqlite, offset: i32, limit: i32) -> FieldResult<Vec<Swap>> {
        Ok(
            context.get_swap_by_pair(self.id.to_string(), offset as i64, limit as i64)?
                .into_iter()
                .map(|s| {
                    Swap::from(s)
                })
                .collect()
        )
    }
}