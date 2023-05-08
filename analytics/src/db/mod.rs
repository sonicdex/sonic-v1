use std::time::Duration;
use diesel::r2d2::{self, ConnectionManager};
use diesel::{BoolExpressionMethods, ExpressionMethods, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
use diesel::connection::SimpleConnection;
use crate::BigUint;
use crate::model::{User, LiquidityPosition, RawTx, TokenDayData, Token, PairDayData, Pair, PairHourData, LiquidityPositionSnapshot, SonicDayData, AddLiquidity, RemoveLiquidity, Swap, Bundle, SyncTime};

pub type Pool = r2d2::Pool<ConnectionManager<SqliteConnection>>;

#[derive(Debug)]
pub struct ConnectionOptions {
    pub enable_wal: bool,
    pub enable_foreign_keys: bool,
    pub busy_timeout: Option<Duration>,
}

impl diesel::r2d2::CustomizeConnection<SqliteConnection, diesel::r2d2::Error> for ConnectionOptions {
    fn on_acquire(&self, conn: &mut SqliteConnection) -> Result<(), diesel::r2d2::Error> {
        (|| {
            if self.enable_wal {
                conn.batch_execute("PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;")?;
            }
            if let Some(d) = self.busy_timeout {
                conn.batch_execute(&format!("PRAGMA busy_timeout = {};", d.as_millis()))?;
            }
            Ok(())
        })()
            .map_err(diesel::r2d2::Error::QueryError)
    }
}

pub fn get_db_pool() -> Pool {
    let db_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    r2d2::Pool::builder()
        .max_size(16)
        .connection_customizer(Box::new(ConnectionOptions {
            enable_wal: true,
            enable_foreign_keys: false,
            busy_timeout: Some(Duration::from_secs(30))
        }))
        .build(ConnectionManager::<SqliteConnection>::new(db_url))
        .expect("Failed to create pool")
}

#[derive(Clone)]
pub struct Sqlite {
    pub pool: Pool,
}

impl juniper::Context for Sqlite {}

impl Sqlite {
    pub fn get_raw_tx(&self, idx: i32) -> QueryResult<RawTx> {
        use crate::model::schema::raw_txs::dsl::*;

        let conn = self.pool.get().unwrap();
        raw_txs.find(idx).first(&conn)
    }

    pub fn get_user_by_id(&self, id: String) -> QueryResult<User>{
        use crate::model::schema::users::dsl;
        let conn = self.pool.get().expect("unable to get a db connection");
        dsl::users.find(id).first(&conn)
    }

    pub fn get_users_pagination(&self, offset: i64, limit: i64) -> QueryResult<Vec<User>> {
        use crate::model::schema::users::dsl;
        use crate::model::schema::users::all_columns;
        let conn = self.pool.get().expect("unable to get a db connection");
        dsl::users.select(all_columns)
            .offset(offset)
            .limit(limit)
            .get_results(&conn)
    }

    pub fn get_pair_by_id(&self, id: String) -> QueryResult<Pair> {
        use crate::model::schema::pairs::dsl;
        let conn = self.pool.get().unwrap();
        dsl::pairs.find(id).first(&conn)
    }

    pub fn get_liquidity_position_by_id(&self, id: String) -> QueryResult<LiquidityPosition> {
        use crate::model::schema::liquidity_positions::dsl;

        let conn = self.pool.get().unwrap();
        dsl::liquidity_positions
            .find(id)
            .first(&conn)
    }

    pub fn get_liquidity_positions_by_user(&self, user_id: String) -> QueryResult<Vec<LiquidityPosition>> {
        use crate::model::schema::liquidity_positions::dsl;

        let conn = self.pool.get().unwrap();
        dsl::liquidity_positions
            .filter(dsl::user.eq(user_id))
            .load::<LiquidityPosition>(&conn)
    }

    pub fn get_liquidity_positions_by_pair(&self, pair_id: String, offset: i64, limit: i64) -> QueryResult<Vec<LiquidityPosition>> {
        use crate::model::schema::liquidity_positions::dsl;

        let conn = self.pool.get().unwrap();
        dsl::liquidity_positions
            .filter(dsl::pair.eq(pair_id))
            .offset(offset)
            .limit(limit)
            .load(&conn)
    }

    pub fn get_liquidity_position_snapshots_by_id(&self, id: String) -> QueryResult<LiquidityPositionSnapshot> {
        use crate::model::schema::liquidity_position_snapshots::dsl;

        let conn = self.pool.get().unwrap();
        dsl::liquidity_position_snapshots
            .find(id)
            .first(&conn)
    }

    pub fn get_liquidity_position_snapshots_by_pair(&self, pair_id: String) -> QueryResult<Vec<LiquidityPositionSnapshot>> {
        use crate::model::schema::liquidity_position_snapshots::dsl;

        let conn = self.pool.get().unwrap();
        dsl::liquidity_position_snapshots
            .filter(dsl::pair.eq(pair_id))
            .load(&conn)
    }

    pub fn get_liquidity_position_snapshots_by_user(&self, user_id: String) -> QueryResult<Vec<LiquidityPositionSnapshot>> {
        use crate::model::schema::liquidity_position_snapshots::dsl;

        let conn = self.pool.get().unwrap();
        dsl::liquidity_position_snapshots
            .filter(dsl::user.eq(user_id))
            .load(&conn)
    }

    pub fn get_liquidity_position_snapshots_by_user_and_pair(&self, pair_id: String, user_id: String) -> QueryResult<Vec<LiquidityPositionSnapshot>> {
        use crate::model::schema::liquidity_position_snapshots::dsl;

        let conn = self.pool.get().unwrap();
        dsl::liquidity_position_snapshots
            .filter(dsl::user.eq(user_id).and(dsl::pair.eq(pair_id)))
            .load(&conn)
    }

    pub fn get_token_by_id(&self, id: String) -> QueryResult<Token> {
        use crate::model::schema::tokens::dsl;

        let conn = self.pool.get().unwrap();
        dsl::tokens
            .find(id)
            .first(&conn)
    }

    pub fn get_tokens(&self, offset: i64, limit: i64) -> QueryResult<Vec<Token>> {
        use crate::model::schema::tokens::dsl;
        use crate::model::schema::tokens::all_columns;

        let conn = self.pool.get().unwrap();
        dsl::tokens.select(all_columns)
            .offset(offset)
            .limit(limit)
            .get_results(&conn)
    }

    pub fn get_token_day_data_by_date(&self, date: i32) -> QueryResult<TokenDayData> {
        use crate::model::schema::token_day_data::dsl;

        let conn = self.pool.get().unwrap();
        dsl::token_day_data
            .filter(dsl::date.eq(date))
            .get_result(&conn)
    }

    pub fn get_token_day_data(&self, token_id: String, date_from: i32, date_to: i32) -> QueryResult<Vec<TokenDayData>> {
        use crate::model::schema::token_day_data::dsl;

        let conn = self.pool.get().unwrap();
        dsl::token_day_data
            .filter(dsl::token.eq(token_id))
            .filter(dsl::date.ge(date_from).and(dsl::date.le(date_to)))
            .load::<TokenDayData>(&conn)
    }

    pub fn get_pairs(&self, offset: i64, limit: i64) -> QueryResult<Vec<Pair>> {
        use crate::model::schema::pairs::dsl;
        use crate::model::schema::pairs::all_columns;

        let conn = self.pool.get().unwrap();
        dsl::pairs
            .select(all_columns)
            .offset(offset)
            .limit(limit)
            .load::<Pair>(&conn)
    }

    pub fn get_pair_base(&self, token_base: String) -> QueryResult<Vec<Pair>> {
        use crate::model::schema::pairs::dsl;

        let conn = self.pool.get().unwrap();
        dsl::pairs
            .filter(dsl::token0.eq(token_base))
            .load::<Pair>(&conn)
    }

    pub fn get_pair_quote(&self, token_quote: String) -> QueryResult<Vec<Pair>> {
        use crate::model::schema::pairs::dsl;

        let conn = self.pool.get().unwrap();
        dsl::pairs
            .filter(dsl::token1.eq(token_quote))
            .load(&conn)
    }

    pub fn get_pair_hour_data(&self, pair_id: String, hour_from: i32, hour_to: i32) -> QueryResult<Vec<PairHourData>> {
        use crate::model::schema::pair_hour_data::dsl;

        let conn = self.pool.get().unwrap();
        dsl::pair_hour_data
            .filter(dsl::pair.eq(pair_id))
            .filter(dsl::hour_start_unix.ge(hour_from).and(dsl::hour_start_unix.le(hour_to)))
            .load::<PairHourData>(&conn)
    }

    pub fn get_pair_day_data(&self, pair_id: String, date_from: i32, date_to: i32) -> QueryResult<Vec<PairDayData>> {
        use crate::model::schema::pair_day_data::dsl;

        let conn = self.pool.get().unwrap();
        dsl::pair_day_data
            .filter(dsl::pair.eq(pair_id))
            .filter(dsl::date.ge(date_from).and(dsl::date.le(date_to)))
            .load::<PairDayData>(&conn)
    }

    pub fn get_sonic_day_data(&self, date_from: i32, date_to: i32) -> QueryResult<Vec<SonicDayData>> {
        use crate::model::schema::sonic_day_data::dsl;

        let conn = self.pool.get().unwrap();
        dsl::sonic_day_data
            .filter(dsl::date.ge(date_from).and(dsl::date.le(date_to)))
            .load::<SonicDayData>(&conn)
    }

    pub fn get_add_liquidity_by_id(&self, id: i32) -> QueryResult<AddLiquidity> {
        use crate::model::schema::add_liquidity::dsl;

        let conn = self.pool.get().unwrap();
        dsl::add_liquidity.find(id).first(&conn)
    }

    pub fn get_add_liquidity_by_pair(&self, pair_id: String, offset: i64, limit: i64) -> QueryResult<Vec<AddLiquidity>> {
        use crate::model::schema::add_liquidity::dsl;

        let conn = self.pool.get().unwrap();
        dsl::add_liquidity
            .filter(dsl::pair.eq(pair_id))
            .offset(offset)
            .limit(limit)
            .load::<AddLiquidity>(&conn)
    }

    pub fn get_add_liquidity_by_user(&self, user_id: String, offset: i64, limit: i64) -> QueryResult<Vec<AddLiquidity>> {
        use crate::model::schema::add_liquidity::dsl;

        let conn = self.pool.get().unwrap();
        dsl::add_liquidity
            .filter(dsl::liquidity_provider.eq(user_id))
            .offset(offset)
            .limit(limit)
            .load::<AddLiquidity>(&conn)
    }

    pub fn get_remove_liquidity_by_id(&self, id: i32) -> QueryResult<RemoveLiquidity> {
        use crate::model::schema::remove_liquidity::dsl;

        let conn = self.pool.get().unwrap();
        dsl::remove_liquidity.find(id).first(&conn)
    }

    pub fn get_remove_liquidity_by_pair(&self, pair_id: String, offset: i64, limit: i64) -> QueryResult<Vec<RemoveLiquidity>> {
        use crate::model::schema::remove_liquidity::dsl;

        let conn = self.pool.get().unwrap();
        dsl::remove_liquidity
            .filter(dsl::pair.eq(pair_id))
            .offset(offset)
            .limit(limit)
            .load::<RemoveLiquidity>(&conn)
    }

    pub fn get_remove_liquidity_by_user(&self, user_id: String, offset: i64, limit: i64) -> QueryResult<Vec<RemoveLiquidity>> {
        use crate::model::schema::remove_liquidity::dsl;

        let conn = self.pool.get().unwrap();
        dsl::remove_liquidity
            .filter(dsl::liquidity_provider.eq(user_id))
            .offset(offset)
            .limit(limit)
            .load::<RemoveLiquidity>(&conn)
    }

    pub fn get_swap_by_id(&self, id: i32) -> QueryResult<Swap> {
        use crate::model::schema::swaps::dsl;

        let conn = self.pool.get().unwrap();
        dsl::swaps.find(id).first(&conn)
    }

    pub fn get_swap_by_pair(&self, pair_id: String, offset: i64, limit: i64) -> QueryResult<Vec<Swap>> {
        use crate::model::schema::swaps::dsl;

        let conn = self.pool.get().unwrap();
        dsl::swaps
            .filter(dsl::pair.eq(pair_id))
            .offset(offset)
            .limit(limit)
            .load::<Swap>(&conn)
    }

    pub fn get_swap_by_user(&self, user_id: String, offset: i64, limit: i64) -> QueryResult<Vec<Swap>> {
        use crate::model::schema::swaps::dsl;

        let conn = self.pool.get().unwrap();
        dsl::swaps
            .filter(dsl::caller.eq(user_id))
            .offset(offset)
            .limit(limit)
            .load::<Swap>(&conn)
    }

    pub fn get_bundle(&self, id: i32) -> QueryResult<Bundle> {
        use crate::model::schema::bundle::dsl;

        let conn = self.pool.get().unwrap();
        dsl::bundle
            .find(id)
            .first(&conn)
    }

    pub fn get_sync_time(&self) -> QueryResult<SyncTime> {
        use crate::model::schema::sync_time::dsl;

        let conn = self.pool.get().unwrap();
        dsl::sync_time
            .find(1)
            .first(&conn)
    }
}
