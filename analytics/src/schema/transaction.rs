use juniper::FieldResult;
use crate::BigUint;
use crate::BigDecimal;
use crate::db::Sqlite;
use crate::schema::pair::Pair;

#[derive(GraphQLObject)]
pub struct RawTx {
    pub(crate) id: juniper::ID,
    pub(crate) timestamp: BigUint,
    pub(crate) caller: String,
    pub(crate) operation: String,
    pub(crate) details: String,
}

pub struct AddLiquidity {
    id: juniper::ID,
    timestamp: BigUint,
    pair: juniper::ID, // index to pair id

    liquidity_provider: String,
    liquidity: BigDecimal,
    amount0: BigDecimal,
    amount1: BigDecimal,
    amount_icp: BigDecimal,
    amount_usd: BigDecimal,

    fee_to: String,
    fee_liquidity: BigDecimal,
}

impl From<crate::model::AddLiquidity> for AddLiquidity {
    fn from(a: crate::model::AddLiquidity) -> Self {
        Self {
            id: juniper::ID::new(a.id.to_string()),
            timestamp: a.timestamp,
            pair: a.pair.into(),
            liquidity_provider: a.liquidity_provider,
            liquidity: a.liquidity,
            amount0: a.amount0,
            amount1: a.amount1,
            amount_icp: a.amount_icp,
            amount_usd: a.amount_usd,
            fee_to: a.fee_to.unwrap_or("".to_string()),
            fee_liquidity: a.fee_liquidity.unwrap_or(BigDecimal::default())
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl AddLiquidity {
    #[graphql(description = "Transaction ID of add liquidity")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "Transaction unix timestamp in millisecond")]
    fn timestamp(&self) -> FieldResult<BigUint> {
        Ok(self.timestamp.to_owned())
    }

    #[graphql(description = "Pair to add liquidity")]
    fn pair(&self, context: &Sqlite) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(self.pair.to_string())?)
        )
    }

    #[graphql(description = "Liquidity provider")]
    fn liquidity_provider(&self) -> FieldResult<String> {
        Ok(self.liquidity_provider.to_owned())
    }

    #[graphql(description = "Liquidity to add(lp token amount)")]
    fn liquidity(&self) -> FieldResult<BigDecimal> {
        Ok(self.liquidity.to_owned())
    }
    #[graphql(description = "Amount of base token")]
    fn amount0(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount0.to_owned())
    }
    #[graphql(description = "Amount of quote token")]
    fn amount1(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount1.to_owned())
    }
    #[graphql(description = "Amount in ICP", name = "amountICP")]
    fn amount_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount_icp.to_owned())
    }
    #[graphql(description = "Amount in USD", name = "amountUSD")]
    fn amount_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount_usd.to_owned())
    }

    fn fee_to(&self) -> FieldResult<String> {
        Ok(self.fee_to.to_owned())
    }
    fn fee_liquidity(&self) -> FieldResult<BigDecimal> {
        Ok(self.fee_liquidity.to_owned())
    }
}

pub struct Swap {
    id: juniper::ID,
    timestamp: BigUint,
    pair: juniper::ID, // index to pair id

    caller: String,

    amount0_in: BigDecimal,
    amount1_in: BigDecimal,
    amount0_out: BigDecimal,
    amount1_out: BigDecimal,
    fee: BigDecimal,

    amount_icp: BigDecimal,
    amount_usd: BigDecimal,
}

impl From<crate::model::Swap> for Swap {
    fn from(s: crate::model::Swap) -> Self {
        Self {
            id: juniper::ID::new(s.id.to_string()),
            timestamp: s.timestamp,
            pair: s.pair.into(),
            caller: s.caller,
            amount0_in: s.amount0_in,
            amount1_in: s.amount1_in,
            amount0_out: s.amount0_out,
            amount1_out: s.amount1_out,
            fee: s.fee,
            amount_icp: s.amount_icp,
            amount_usd: s.amount_usd
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl Swap {
    #[graphql(description = "Transaction ID of swap")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "Transaction unix timestamp in millisecond")]
    fn timestamp(&self) -> FieldResult<BigUint> {
        Ok(self.timestamp.to_owned())
    }

    #[graphql(description = "Pair to swap")]
    fn pair(&self, context: &Sqlite) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(self.pair.to_string())?)
        )
    }

    #[graphql(description = "Swap caller")]
    fn caller(&self) -> FieldResult<String> {
        Ok(self.caller.to_owned())
    }

    #[graphql(description = "Base token input in swap")]
    fn amount0_in(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount0_in.to_owned())
    }

    #[graphql(description = "Quote token input in swap")]
    fn amount1_in(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount1_in.to_owned())
    }

    #[graphql(description = "Base token output in swap")]
    fn amount0_out(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount0_out.to_owned())
    }

    #[graphql(description = "Quote token output in swap")]
    fn amount1_out(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount1_out.to_owned())
    }

    #[graphql(description = "Swap fee")]
    fn fee(&self) -> FieldResult<BigDecimal> {
        Ok(self.fee.to_owned())
    }

    #[graphql(description = "Swap amount in ICP", name = "amountICP")]
    fn amount_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount_icp.to_owned())
    }

    #[graphql(description = "Swap amount in USD", name = "amountUSD")]
    fn amount_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount_usd.to_owned())
    }
}

pub struct RemoveLiquidity{
    id: juniper::ID,
    timestamp: BigUint,
    pair: juniper::ID, // index to pair id

    liquidity_provider: String,
    liquidity: BigDecimal,

    amount0: BigDecimal,
    amount1: BigDecimal,
    amount_icp: BigDecimal,
    amount_usd: BigDecimal,

    fee_to: String,
    fee_liquidity: BigDecimal,
}

impl From<crate::model::RemoveLiquidity> for RemoveLiquidity {
    fn from(r: crate::model::RemoveLiquidity) -> Self {
        Self {
            id: juniper::ID::new(r.id.to_string()),
            timestamp: r.timestamp,
            pair: r.pair.into(),
            liquidity_provider: r.liquidity_provider,
            liquidity: r.liquidity,
            amount0: r.amount0,
            amount1: r.amount1,
            amount_icp: r.amount_icp,
            amount_usd: r.amount_usd,
            fee_to: r.fee_to.unwrap_or("".to_string()),
            fee_liquidity: r.fee_liquidity.unwrap_or(BigDecimal::default())
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl RemoveLiquidity {
    #[graphql(description = "Transaction ID of remove liquidity")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "Transaction unix timestamp in millisecond")]
    fn timestamp(&self) -> FieldResult<BigUint> {
        Ok(self.timestamp.to_owned())
    }

    #[graphql(description = "Pair to remove liquidity")]
    fn pair(&self, context: &Sqlite) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(self.pair.to_string())?)
        )
    }

    #[graphql(description = "Liquidity provider")]
    fn liquidity_provider(&self) -> FieldResult<String> {
        Ok(self.liquidity_provider.to_owned())
    }

    #[graphql(description = "Liquidity to remove(lp token amount)")]
    fn liquidity(&self) -> FieldResult<BigDecimal> {
        Ok(self.liquidity.to_owned())
    }
    #[graphql(description = "Amount of base token")]
    fn amount0(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount0.to_owned())
    }
    #[graphql(description = "Amount of quote token")]
    fn amount1(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount1.to_owned())
    }
    #[graphql(description = "Amount in ICP", name = "amountICP")]
    fn amount_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount_icp.to_owned())
    }
    #[graphql(description = "Amount in USD", name = "amountUSD")]
    fn amount_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.amount_usd.to_owned())
    }

    fn fee_to(&self) -> FieldResult<String> {
        Ok(self.fee_to.to_owned())
    }
    fn fee_liquidity(&self) -> FieldResult<BigDecimal> {
        Ok(self.fee_liquidity.to_owned())
    }
}