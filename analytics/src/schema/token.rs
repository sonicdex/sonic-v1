use juniper::FieldResult;
use crate::BigUint;
use crate::BigDecimal;
use crate::db::Sqlite;
use crate::schema::pair::Pair;
use crate::schema::statistic::TokenDayData;

pub struct Token {
    id: juniper::ID,

    symbol: String,
    name: String,
    decimals: i32,
    total_supply: BigUint,
    fee: BigUint,
    total_deposited: BigUint,

    trade_volume: BigDecimal,
    trade_volume_icp: BigDecimal,
    trade_volume_usd: BigDecimal,
    untracked_volume_icp: BigDecimal,
    untracked_volume_usd: BigDecimal,

    tx_count: BigUint,

    total_liquidity: BigDecimal,

    derived_icp: BigDecimal,
}

impl From<crate::model::Token> for Token {
    fn from(t: crate::model::Token) -> Self {
        Self {
            id: t.id.into(),
            symbol: t.symbol,
            name: t.name,
            decimals: t.decimals,
            total_supply: t.total_supply,
            fee: t.fee,
            total_deposited: t.total_deposited,
            trade_volume: t.trade_volume,
            trade_volume_icp: t.trade_volume_icp,
            trade_volume_usd: t.trade_volume_usd,
            untracked_volume_icp: t.untracked_volume_icp,
            untracked_volume_usd: t.untracked_volume_usd,
            tx_count: t.tx_count,
            total_liquidity: t.total_liquidity,
            derived_icp: t.derived_icp,
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl Token {
    #[graphql(description = "Token's principal as ID")]
    fn id(&self) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(description = "Token symbol")]
    fn symbol(&self) -> FieldResult<String> {
        Ok(self.symbol.to_owned())
    }

    #[graphql(description = "Token name")]
    fn name(&self) -> FieldResult<String> {
        Ok(self.name.to_owned())
    }

    #[graphql(description = "Token decimals")]
    fn decimals(&self) -> FieldResult<i32> {
        Ok(self.decimals)
    }

    #[graphql(description = "Token total supply", name = "totalSupply")]
    fn total_supply(&self) -> FieldResult<BigUint> {
        Ok(self.total_supply.to_owned())
    }

    #[graphql(description = "Token fee")]
    fn fee(&self) -> FieldResult<BigUint> {
        Ok(self.fee.to_owned())
    }

    #[graphql(description = "Token amount deposited into sonic", name = "totalDeposited")]
    fn total_deposited(&self) -> FieldResult<BigUint> {
        Ok(self.total_deposited.to_owned())
    }

    #[graphql(description = "Total trade volume of the token", name = "tradeVolume")]
    fn trade_volume(&self) -> FieldResult<BigDecimal> {
        Ok(self.trade_volume.to_owned())
    }

    #[graphql(description = "Total trade volume of the token in ICP, computed by whitelist token", name = "tradeVolumeICP")]
    fn trade_volume_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.trade_volume_icp.to_owned())
    }

    #[graphql(description = "Total trade volume of the token in USD, computed by whitelist token", name = "tradeVolumeUSD")]
    fn trade_volume_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.trade_volume_usd.to_owned())
    }

    #[graphql(description = "Total untracked volume of the token in ICP, derived from ICP.", name = "untrackedVolumeICP")]
    fn untracked_volume_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.untracked_volume_icp.to_owned())
    }

    #[graphql(description = "Total untracked volume of the token in USD, derived from ICP.", name = "untrackedVolumeUSD")]
    fn untracked_volume_usd(&self) -> FieldResult<BigDecimal> {
        Ok(self.untracked_volume_usd.to_owned())
    }

    #[graphql(description = "Total transaction counts of this token.", name = "txCount")]
    fn tx_count(&self) -> FieldResult<BigUint> {
        Ok(self.tx_count.to_owned())
    }

    #[graphql(description = "Total liquidity of this token.", name = "totalLiquidity")]
    fn total_liquidity(&self) -> FieldResult<BigDecimal> {
        Ok(self.total_liquidity.to_owned())
    }

    #[graphql(description = "Derived ICP price", name = "derivedPrice")]
    fn derived_icp(&self) -> FieldResult<BigDecimal> {
        Ok(self.derived_icp.to_owned())
    }

    #[graphql(description = "Get the day data of token between from and to date.", name = "tokenDayData")]
    fn token_day_data(&self, context: &Sqlite, from_date: i32, to_date: i32) -> FieldResult<Vec<TokenDayData>> {
        Ok(
            context.get_token_day_data(self.id.to_string(), from_date, to_date)?
                .into_iter()
                .map(|t| {
                    TokenDayData::from(t)
                })
                .collect()
        )
    }

    #[graphql(description = "Get the pair whose base token(token0) is this token", name = "pairBase")]
    fn pair_base(&self, context: &Sqlite) -> FieldResult<Vec<Pair>> {
        Ok(
            context.get_pair_base(self.id.to_string())?
                .into_iter()
                .map(|p| {
                    Pair::from(p)
                })
                .collect()
        )
    }

    #[graphql(description = "Get the pair whose quote token(token1) is this token.", name = "pairQuote")]
    fn pair_quote(&self, context: &Sqlite) -> FieldResult<Vec<Pair>> {
        Ok(
            context.get_pair_quote(self.id.to_string())?
                .into_iter()
                .map(|p| {
                    Pair::from(p)
                })
                .collect()
        )
    }
}