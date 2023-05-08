mod user;
mod liquidity;
mod pair;
mod token;
mod sonic;
mod transaction;
mod statistic;

use std::str::FromStr;
use juniper::{EmptyMutation, EmptySubscription, FieldResult};
use juniper::RootNode;
use crate::schema::user::User;

use crate::sync::helpers::SONIC_ADDRESS;
use crate::db::Sqlite;
use crate::{BigUint};
use crate::model::DB;
use crate::schema::liquidity::{LiquidityPosition, LiquidityPositionSnapshot};
use crate::schema::pair::Pair;
use crate::schema::sonic::Sonic;
use crate::schema::statistic::{PairDayData, PairHourData, SonicDayData, SyncTime, TokenDayData, Bundle};
use crate::schema::token::Token;
use crate::schema::transaction::{AddLiquidity, RawTx, RemoveLiquidity, Swap};

pub struct Query;

#[graphql_object(Context = Sqlite)]
impl Query {
    // #[graphql(description = "test")]
    // fn raw_txs(context: &Sqlite, id: juniper::ID) -> FieldResult<RawTx> {
    //     let tx = context.get_raw_tx(id.parse().unwrap())?;
    //     Ok(RawTx{
    //         id: juniper::ID::new(tx.id.to_string()),
    //         timestamp: BigUint(num_bigint::BigUint::from_str(tx.time.as_str()).unwrap()),
    //         caller: tx.caller,
    //         operation: tx.operation,
    //         details: tx.details,
    //     })
    // }

    #[graphql(description = "get sonic statistic")]
    fn sonic(context: &Sqlite) -> FieldResult<Sonic> {
        let conn = context.pool.get().unwrap();
        Ok(Sonic::from(crate::model::Sonic::load(SONIC_ADDRESS.to_string(), &conn)?))
    }

    #[graphql(description = "get user by id, which is user's principal")]
    fn user(context: &Sqlite, id: juniper::ID) -> FieldResult<User> {
        Ok(
            context.get_user_by_id(id.to_string())?
                .into()
        )
    }

    #[graphql(
        description = "get users by offset and limit",
        arguments(
            offset(
                default = 0,
                description = "offset"
            ),
            limit(
                default = 50,
                description = "limit"
            )
        )
    )]
    fn users(context: &Sqlite, offset: i32, limit: i32) -> FieldResult<Vec<User>> {
        Ok(
            context.get_users_pagination(offset as i64, limit as i64)?
                .into_iter()
                .map(|u| {
                    User::from(u)
                })
                .collect()
        )
    }

    #[graphql(description = "get token by id, which is token's canister id")]
    fn token(context: &Sqlite, id: juniper::ID) -> FieldResult<Token> {
        Ok(
            context.get_token_by_id(id.to_string())
                .map(|t| {
                    Token::from(t)
                })?
        )
    }

    #[graphql(
        description = "get tokens by offset and limit",
        arguments(
            offset(
                default = 0,
                description = "offset"
            ),
            limit(
                default = 50,
                description = "limit"
            )
        )
    )]
    fn tokens(context: &Sqlite, offset: i32, limit: i32) -> FieldResult<Vec<Token>> {
        Ok(
            context.get_tokens(offset as i64, limit as i64)?
                .into_iter()
                .map(|t| {
                    Token::from(t)
                })
                .collect()
        )
    }

    #[graphql(description = "get pair by id")]
    fn pair(context: &Sqlite, id: juniper::ID) -> FieldResult<Pair> {
        Ok(
            Pair::from(context.get_pair_by_id(id.to_string())?)
        )
    }

    #[graphql(description = "get pairs by offset and limit",
        arguments(
            offset(
                default = 0,
                description = "offset"
            ),
            limit(
                default = 50,
                description = "limit"
            )
        )
    )]
    fn pairs(context: &Sqlite, offset: i32, limit: i32) -> FieldResult<Vec<Pair>> {
        Ok(
            context.get_pairs(offset as i64, limit as i64)?
                .into_iter()
                .map(|p| {
                    Pair::from(p)
                })
                .collect()
        )
    }

    #[graphql(description = "get token day data",
        arguments(
            id(
                description = "token's id"
            ),
            dateFrom(
                description = "from date, unix timestamp in second"
            ),
            dateTo(
                description = "from date, unix timestamp in second"
            )
        )
    )]
    fn token_day_data(context: &Sqlite, id: juniper::ID, date_from: i32, date_to: i32) -> FieldResult<Vec<TokenDayData>> {
        Ok (
            context.get_token_day_data(id.to_string(), date_from, date_to)?
                .into_iter()
                .map(|t| {
                    TokenDayData::from(t)
                })
                .collect()
        )
    }

    #[graphql(description = "get pair hour data",
        arguments(
            id(
                description = "pair id"
            ),
            hourFrom(
                description = "from hour, unix timestamp in second"
            ),
            hourTo(
                description = "to hour, unix timestamp in second"
            )
        )
    )]
    fn pair_hour_data(context: &Sqlite, id: juniper::ID, hour_from: i32, hour_to: i32) -> FieldResult<Vec<PairHourData>> {
        Ok(
            context.get_pair_hour_data(id.to_string(), hour_from,hour_to)?
                .into_iter()
                .map(|p| {
                    PairHourData::from(p)
                })
                .collect()
        )
    }

    #[graphql(description = "get pair day data",
        arguments(
            id(
                description = "pair id"
            ),
            dateFrom(
                description = "from date, unix timestamp in second"
            ),
            dateTo(
                description = "to date, unix timestamp in second"
            )
        )
    )]
    fn pair_day_data(context: &Sqlite, id: juniper::ID, date_from: i32, date_to: i32) -> FieldResult<Vec<PairDayData>> {
        Ok(
            context.get_pair_day_data(id.to_string(), date_from, date_to)?
                .into_iter()
                .map(|p| {
                    PairDayData::from(p)
                })
                .collect()
        )
    }

    #[graphql(description = "get sonic day data",
        arguments(
            dateFrom(
                description = "from date, unix timestamp in second"
            ),
            dateTo(
                description = "to date, unix timestamp in second"
            )
        )
    )]
    fn sonic_day_data(context: &Sqlite, date_from: i32, date_to: i32) -> FieldResult<Vec<SonicDayData>> {
        Ok(
            context.get_sonic_day_data(date_from, date_to)?
                .into_iter()
                .map(|s| {
                    SonicDayData::from(s)
                })
                .collect()
        )
    }


    #[graphql(description = "get liquidity position by id, which is combined with pair id and user id")]
    fn liquidity_position(context: &Sqlite, id: juniper::ID) -> FieldResult<LiquidityPosition> {
        Ok(
            LiquidityPosition::from(context.get_liquidity_position_by_id(id.to_string())?)
        )
    }

    #[graphql(description = "get liquidity positions by id, which is combined with liquidity position id and timestamp")]
    fn liquidity_position_snapshot(context: &Sqlite, id: juniper::ID) -> FieldResult<LiquidityPositionSnapshot> {
        Ok(
            LiquidityPositionSnapshot::from(context.get_liquidity_position_snapshots_by_id(id.to_string())?)
        )
    }

    #[graphql(description = "get liquidity positions by user and pair")]
    fn liquidity_position_snapshots(context: &Sqlite, user_id: String, pair_id: String) -> FieldResult<Vec<LiquidityPositionSnapshot>> {
        Ok(
            context.get_liquidity_position_snapshots_by_user_and_pair(pair_id, user_id)?
                .into_iter()
                .map(|l| {
                    LiquidityPositionSnapshot::from(l)
                })
                .collect()
        )
    }

    #[graphql(description = "get add liquidity transaction by transaction id")]
    fn add_liquidity(context: &Sqlite, id: juniper::ID) -> FieldResult<AddLiquidity> {
        Ok(
            AddLiquidity::from(context.get_add_liquidity_by_id(id.parse().expect("ID is not i32"))?)
        )
    }

    #[graphql(description = "get remove liquidity transaction by transaction id")]
    fn remove_liquidity(context: &Sqlite, id: juniper::ID) -> FieldResult<RemoveLiquidity> {
        Ok(
            RemoveLiquidity::from(context.get_remove_liquidity_by_id(id.parse().expect("ID is not i32"))?)
        )
    }

    #[graphql(description = "get swap transaction by transaction id")]
    fn swap(context: &Sqlite, id: juniper::ID) -> FieldResult<Swap> {
        Ok(
            Swap::from(context.get_swap_by_id(id.parse().expect("ID is not i32"))?)
        )
    }

    #[graphql(description = "Price bundle",
        arguments(id(default = 1, description = "price id, 1 is usd")))]
    fn bundle(context: &Sqlite, id: i32) -> FieldResult<Bundle> {
        Ok(
            Bundle::from(context.get_bundle(id)?)
        )
    }

    #[graphql(description = "get transaction synchronized time, unix timestamp in second")]
    fn sync_time(context: &Sqlite) -> FieldResult<SyncTime> {
        Ok(
            SyncTime::from(context.get_sync_time()?)
        )
    }
}

pub type Schema = RootNode<'static, Query, EmptyMutation<Sqlite>, EmptySubscription<Sqlite>>;

pub fn create_schema() -> Schema {
    Schema::new(Query, EmptyMutation::new(), EmptySubscription::new())
}
