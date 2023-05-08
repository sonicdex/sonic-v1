use juniper::FieldResult;
use crate::BigUint;
use crate::BigDecimal;
use crate::db::Sqlite;
use crate::schema::pair::Pair;
use crate::schema::user::User;

pub struct LiquidityPosition {
    pub id: juniper::ID,
    pub user: juniper::ID, // index to user id
    pub pair: juniper::ID, // index to pair id
    pub liquidity_token_balance: BigDecimal,
}

impl From<crate::model::LiquidityPosition> for LiquidityPosition {
    fn from(lp: crate::model::LiquidityPosition) -> Self {
        Self {
            id: lp.id.into(),
            user: lp.user.into(),
            pair: lp.pair.into(),
            liquidity_token_balance: lp.liquidity_token_balance
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl LiquidityPosition {

    #[graphql(description = "ID of liquidity position, combined with pair id and user id")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "User of the liquidity position")]
    fn user(&self, context: &Sqlite) -> FieldResult<User> {
        Ok(
            User::from(context.get_user_by_id(self.id.to_string())?)
        )
    }

    #[graphql(description = "Pair of the liquidity position")]
    fn pair(&self, context: &Sqlite) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(self.pair.to_string())?)
        )
    }

    #[graphql(description = "Liquidity token balance of the position")]
    fn liquidity_token_balance(&self) -> FieldResult<BigDecimal> {
        Ok(self.liquidity_token_balance.to_owned())
    }
}

pub struct LiquidityPositionSnapshot {
    id: juniper::ID,
    liquidity_position: juniper::ID, // index to liquidity position id
    timestamp: BigUint,
    user: juniper::ID, // index to user id
    pair: juniper::ID, // index to pair id
    token0_price_icp: BigDecimal,
    token0_price_usd: BigDecimal,
    token1_price_icp: BigDecimal,
    token1_price_usd: BigDecimal,
    reserve0: BigDecimal,
    reserve1: BigDecimal,
    reserve_icp: BigDecimal,
    reserve_usd: BigDecimal,
    liquidity_token_total_supply: BigDecimal,
    liquidity_token_balance: BigDecimal,
}

impl From<crate::model::LiquidityPositionSnapshot> for LiquidityPositionSnapshot {
    fn from(lps: crate::model::LiquidityPositionSnapshot) -> Self {
        Self {
            id: lps.id.into(),
            liquidity_position: lps.liquidity_position.into(),
            timestamp: lps.timestamp,
            user: lps.user.into(),
            pair: lps.pair.into(),
            token0_price_icp: lps.token0_price_icp,
            token0_price_usd: lps.token0_price_usd,
            token1_price_icp: lps.token1_price_icp,
            token1_price_usd: lps.token1_price_usd,
            reserve0: lps.reserve0,
            reserve1: lps.reserve1,
            reserve_icp: lps.reserve_icp,
            reserve_usd: lps.reserve_usd,
            liquidity_token_total_supply: lps.liquidity_token_total_supply,
            liquidity_token_balance: lps.liquidity_token_balance
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl LiquidityPositionSnapshot {

    #[graphql(description = "ID of liquidity position snapshot, combined with liquidity position and timestamp")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "Corresponding liquidity position")]
    fn liquidity_position(&self, context: &Sqlite) -> FieldResult<LiquidityPosition> {
        Ok(
            LiquidityPosition::from(context.get_liquidity_position_by_id(self.liquidity_position.to_string())?)
        )
    }

    #[graphql(description = "Snapshot timestamp, unix timestamp in millisecond")]
    fn timestamp(&self) -> FieldResult<BigUint> {
        Ok(self.timestamp.to_owned())
    }

    #[graphql(description = "Corresponding user")]
    fn user(&self, context: &Sqlite) -> FieldResult<User> {
        Ok(
            User::from(context.get_user_by_id(self.user.to_string())?)
        )
    }

    #[graphql(description = "Corresponding pair")]
    fn pair(&self, context: &Sqlite) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(self.pair.to_string())?)
        )
    }

    #[graphql(description = "Base token price in ICP", name = "token0PriceICP")]
    fn token0_price_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.token0_price_icp.to_owned())
    }

    #[graphql(description = "Base token price in USD", name = "token0PriceUSD")]
    fn token0_price_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.token0_price_usd.to_owned())
    }

    #[graphql(description = "Quote token price in ICP", name = "token1PriceICP")]
    fn token1_price_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.token1_price_icp.to_owned())
    }

    #[graphql(description = "Quote token price in USD", name = "token1PriceUSD")]
    fn token1_price_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.token1_price_usd.to_owned())
    }

    #[graphql(description = "Reserve amount of base token")]
    fn reserve0(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve0.to_owned())
    }

    #[graphql(description = "Reserve amount of quote token")]
    fn reserve1(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve1.to_owned())
    }

    #[graphql(description = "Reserve amount in ICP", name = "reserveICP")]
    fn reserve_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve_icp.to_owned())
    }

    #[graphql(description = "Reserve amount in USD", name = "reserveUSD")]
    fn reserve_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.reserve_usd.to_owned())
    }

    #[graphql(description = "Liquidity token total supply")]
    fn liquidity_token_total_supply(&self) -> FieldResult<BigDecimal> {
        Ok(self.liquidity_token_total_supply.to_owned())
    }

    #[graphql(description = "Liquidity token balance of user")]
    fn liquidity_token_balance(&self) -> FieldResult<BigDecimal> {
        Ok(self.liquidity_token_balance.to_owned())
    }
}