use juniper::FieldResult;
use crate::{BigDecimal, BigUint};
use crate::db::Sqlite;
use crate::schema::liquidity::{LiquidityPosition, LiquidityPositionSnapshot};
use crate::schema::pair::Pair;
use crate::schema::statistic::{PositionMetrics, ReturnMetrics};
use crate::schema::token::Token;
use crate::schema::transaction::{AddLiquidity, RemoveLiquidity, Swap};

#[derive(Debug)]
pub struct User {
    id: juniper::ID,
    icp_swapped: BigDecimal,
    usd_swapped: BigDecimal,
}

impl From<crate::model::User> for User {
    fn from(u: crate::model::User) -> Self {
        Self {
            id: u.id.into(),
            icp_swapped: u.icp_swapped,
            usd_swapped: u.usd_swapped
        }
    }
}

#[graphql_object(Context = Sqlite)]
impl User {
    #[graphql(description = "User's principal as ID")]
    fn id(&self, context: &Sqlite) -> FieldResult<juniper::ID> {
        Ok(self.id.to_owned())
    }

    #[graphql(name = "ICPSwapped", description = "User's swapped volume in ICP")]
    fn icp_swapped(&self, context: &Sqlite) -> FieldResult<BigDecimal> {
        Ok(self.icp_swapped.to_owned())
    }

    #[graphql(name = "USDSwapped", description = "User's swapped volume in USD")]
    fn usd_swapped(&self, context: &Sqlite) -> FieldResult<BigDecimal> {
        Ok(self.usd_swapped.to_owned())
    }

    #[graphql(description = "User's liquidity position")]
    fn liquidity_positions(&self, context: &Sqlite) -> FieldResult<Vec<LiquidityPosition>> {
        let positions = context.get_liquidity_positions_by_user(self.id.to_string())?;
        Ok(
            positions.into_iter()
                .map(|p| {
                    LiquidityPosition::from(p)
                })
                .collect()
        )
    }

    #[graphql(description = "Get liquidity position snapshots of the user, with offset and limit", name = "liquidityPositionSnapshots")]
    fn liquidity_position_snapshots(&self, context: &Sqlite) -> FieldResult<Vec<LiquidityPositionSnapshot>> {
        Ok(
            context.get_liquidity_position_snapshots_by_user(self.id.to_string())?
                .into_iter()
                .map(|l| {
                    LiquidityPositionSnapshot::from(l)
                })
                .collect()
        )
    }

    #[graphql(description = "Get add liquidity tx of the user, with offset and limit", name = "addLiquidity",
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
            context.get_add_liquidity_by_user(self.id.to_string(), offset as i64, limit as i64)?
                .into_iter()
                .map(|a| {
                    AddLiquidity::from(a)
                })
                .collect()
        )
    }

    #[graphql(description = "Get remove liquidity tx of the user, with offset and limit", name = "removeLiquidity",
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
            context.get_remove_liquidity_by_user(self.id.to_string(), offset as i64, limit as i64)?
                .into_iter()
                .map(|r| {
                    RemoveLiquidity::from(r)
                })
                .collect()
        )
    }

    #[graphql(description = "Get swap tx of the user, with offset and limit",
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
            context.get_swap_by_user(self.id.to_string(), offset as i64, limit as i64)?
                .into_iter()
                .map(|s| {
                    Swap::from(s)
                })
                .collect()
        )
    }

    #[graphql(description = "User fee earned approximately",
        arguments(
            pair_id(
                description = "Return metrics on the pair. None means among all pairs"
            )
    ))]
    fn return_metrics(&self, context: &Sqlite, pair_id: Option<String>) -> FieldResult<ReturnMetrics> {
        let icp_price = context.get_bundle(1)?.icp_price;
        let return_metric = match pair_id {
            None => {
                // get all pairs position snapshots
                let mut res: Vec<ReturnMetrics> = vec![];
                let positions = context.get_liquidity_positions_by_user(self.id.to_string())?;
                for position in positions {
                    let snapshots = context.get_liquidity_position_snapshots_by_user_and_pair(
                        position.pair.clone(),
                        self.id.to_string()
                    )?;
                    let p = context.get_pair_by_id(position.pair.clone())?;
                    let token0_icp = context.get_token_by_id(p.token0.to_string())?.derived_icp;
                    let token1_icp = context.get_token_by_id(p.token1.to_string())?.derived_icp;
                    res.push(get_lp_returns_on_pair(self.id.to_string(), p, token0_icp, token1_icp, icp_price.clone(), snapshots));
                }
                res.into_iter().reduce(|mut accum, item| {
                    accum.sonic_return += item.sonic_return;
                    accum.net_return += item.net_return;
                    accum.hodl_return += item.hodl_return;
                    accum.imp_loss += item.imp_loss;
                    accum.fees += item.fees;
                    accum
                }).unwrap_or(
                    ReturnMetrics::default()
                )
            }
            Some(pair) => {
                let snapshots = context.get_liquidity_position_snapshots_by_user_and_pair(pair.clone(),self.id.to_string())?;
                let p = context.get_pair_by_id(pair)?;
                let token0_icp = context.get_token_by_id(p.token0.to_string())?.derived_icp;
                let token1_icp = context.get_token_by_id(p.token1.to_string())?.derived_icp;
                get_lp_returns_on_pair(self.id.to_string(), p, token0_icp, token1_icp, icp_price, snapshots)
            }
        };
        Ok(ReturnMetrics{
            hodl_return: return_metric.hodl_return.with_scale(18),
            net_return: return_metric.net_return.with_scale(18),
            sonic_return: return_metric.sonic_return.with_scale(18),
            imp_loss: return_metric.imp_loss.with_scale(18),
            fees: return_metric.fees.with_scale(18)
        })
    }

    #[graphql(description = "User fee earned approximately on specific position currently",
        arguments(
            pair_id(
                description = "Fees earned metrics on the pair."
            )
    ))]
    fn position_metrics(&self, context: &Sqlite, pair_id: String) -> FieldResult<PositionMetrics> {
        let icp_price = context.get_bundle(1)?.icp_price;

        let snapshots = context.get_liquidity_position_snapshots_by_user_and_pair(pair_id.clone(),self.id.to_string())?;
        let p = context.get_pair_by_id(pair_id)?;
        let token0_icp = context.get_token_by_id(p.token0.to_string())?.derived_icp;
        let token1_icp = context.get_token_by_id(p.token1.to_string())?.derived_icp;
        let position_metrics = get_position_fees_on_pair(self.id.to_string(), p, token0_icp, token1_icp, icp_price, snapshots);

        Ok(PositionMetrics{
            imp_loss: position_metrics.imp_loss.with_scale(18),
            fees: position_metrics.fees.with_scale(18)
        })
    }
}

/// calculate returns within one time window
fn get_metrics_for_position_window(position0: crate::model::LiquidityPositionSnapshot, position1: crate::model::LiquidityPositionSnapshot) -> ReturnMetrics {
    let t0_ownership = if position0.liquidity_token_total_supply.clone() == BigDecimal::default() {
        BigDecimal::from(1)
    } else {
        position0.liquidity_token_balance.clone() / position0.liquidity_token_total_supply
    };
    let t1_ownership = if position1.liquidity_token_total_supply.clone() == BigDecimal::default() {
        BigDecimal::from(1)
    } else {
        position0.liquidity_token_balance / position1.liquidity_token_total_supply
    };

    // get starting amounts of token0 and token1 deposited by LP
    let token0_amount_t0 = t0_ownership.clone() * position0.reserve0;
    let token1_amount_t0 = t0_ownership.clone() * position0.reserve1;

    // get current token values
    let token0_amount_t1 = t1_ownership.clone() * position1.reserve0;
    let token1_amount_t1 = t1_ownership.clone() * position1.reserve1;

    // calculate squares to find imp loss and fee differences
    let sqrt_k_t0 = (token0_amount_t0.clone() * token1_amount_t0.clone()).sqrt().unwrap();
    let price_ratio_t1 = if position1.token0_price_usd.clone() == BigDecimal::default() {
        BigDecimal::default()
    } else {
        position1.token1_price_usd.clone() / position1.token0_price_usd.clone()
    };

    let token0_amount_no_fees = sqrt_k_t0.clone() * price_ratio_t1.sqrt().unwrap();
    let token1_amount_no_fees = if price_ratio_t1 == BigDecimal::default() {
        BigDecimal::default()
    } else {
        sqrt_k_t0 / price_ratio_t1.sqrt().unwrap()
    };
    let no_fees_usd = token0_amount_no_fees.clone() * position1.token0_price_usd.clone() + token1_amount_no_fees.clone() * position1.token1_price_usd.clone();

    let difference_fees_token0 = token0_amount_t1.clone() - token0_amount_no_fees;
    let difference_fees_token1 = token1_amount_t1.clone() - token1_amount_no_fees;
    let difference_fees_usd = difference_fees_token0 * position1.token0_price_usd.clone() + difference_fees_token1 * position1.token1_price_usd.clone();

    // calculate USD value at t0 and t1 using initial token deposit amounts for asset return
    let asset_value_t0 = token0_amount_t0.clone() * position0.token0_price_usd + token1_amount_t0.clone() * position0.token1_price_usd;
    let asset_value_t1 = token0_amount_t0.clone() * position1.token0_price_usd + token1_amount_t0.clone() * position1.token1_price_usd;

    let imp_loss_usd = no_fees_usd - asset_value_t1.clone();
    let sonic_return = difference_fees_usd.clone() + imp_loss_usd.clone();

    let net_value_t0 = t0_ownership * position0.reserve_usd;
    let net_value_t1 = t1_ownership * position1.reserve_usd;

    return ReturnMetrics {
        hodl_return: asset_value_t1 - asset_value_t0,
        net_return: net_value_t1 - net_value_t0,
        sonic_return,
        imp_loss: imp_loss_usd,
        fees: difference_fees_usd
    }
}

fn get_lp_returns_on_pair(
    user_id: String,
    pair: crate::model::Pair,
    token0_icp: BigDecimal,
    token1_icp: BigDecimal,
    icp_price: BigDecimal,
    mut snapshots: Vec<crate::model::LiquidityPositionSnapshot>
) -> ReturnMetrics {
    let mut hodl_return = BigDecimal::default();
    let mut net_return = BigDecimal::default();
    let mut sonic_return = BigDecimal::default();
    let mut fees = BigDecimal::default();
    let mut imp_loss = BigDecimal::default();

    let current_position = crate::model::LiquidityPositionSnapshot {
        id: "temp".into(),
        liquidity_position: "temp".into(),
        timestamp: BigUint::default(),
        user: user_id.into(),
        pair: pair.id,
        token0_price_icp: token0_icp.clone(),
        token0_price_usd: token0_icp * icp_price.clone(),
        token1_price_icp: token1_icp.clone(),
        token1_price_usd: token1_icp * icp_price.clone(),
        reserve0: pair.reserve0,
        reserve1: pair.reserve1,
        reserve_icp: pair.reserve_icp,
        reserve_usd: pair.reserve_usd,
        liquidity_token_total_supply: pair.total_supply,
        liquidity_token_balance: snapshots.last().map(|x| x.liquidity_token_balance.to_owned()).unwrap_or(BigDecimal::default())
    };

    snapshots.push(current_position);

    for i in 0..snapshots.len()-1 {
        let position0 = snapshots[i].to_owned();
        let position1 = snapshots[i+1].to_owned();

        let res = get_metrics_for_position_window(position0, position1);
        hodl_return += res.hodl_return;
        net_return += res.net_return;
        sonic_return += res.sonic_return;
        fees += res.fees;
        imp_loss += res.imp_loss;
    }

    return ReturnMetrics {
        hodl_return,
        net_return,
        sonic_return,
        imp_loss,
        fees
    }
}

fn get_position_fees_on_pair(
    user_id: String,
    pair: crate::model::Pair,
    token0_icp: BigDecimal,
    token1_icp: BigDecimal,
    icp_price: BigDecimal,
    mut snapshots: Vec<crate::model::LiquidityPositionSnapshot>
) -> PositionMetrics {
    let mut fees = BigDecimal::default();
    let mut imp_loss = BigDecimal::default();

    let current_position = crate::model::LiquidityPositionSnapshot {
        id: "temp".into(),
        liquidity_position: "temp".into(),
        timestamp: BigUint::default(),
        user: user_id.into(),
        pair: pair.id,
        token0_price_icp: token0_icp.clone(),
        token0_price_usd: token0_icp * icp_price.clone(),
        token1_price_icp: token1_icp.clone(),
        token1_price_usd: token1_icp * icp_price.clone(),
        reserve0: pair.reserve0,
        reserve1: pair.reserve1,
        reserve_icp: pair.reserve_icp,
        reserve_usd: pair.reserve_usd,
        liquidity_token_total_supply: pair.total_supply,
        liquidity_token_balance: snapshots.last().map(|x| x.liquidity_token_balance.to_owned()).unwrap_or(BigDecimal::default())
    };

    snapshots.push(current_position);

    for i in 0..snapshots.len()-1 {
        let position0 = &snapshots[i];
        let position1 = &snapshots[i+1];

        if position1.liquidity_token_balance == BigDecimal::default() {
            fees = BigDecimal::default();
            imp_loss = BigDecimal::default();
            continue;
        }

        let res = get_metrics_for_position_window(position0.to_owned(), position1.to_owned());
        fees += res.fees;
        imp_loss += res.imp_loss;
        let ratio = if position1.liquidity_token_balance < position0.liquidity_token_balance {
            // remove liquidity, subtract the fees proportionally
            position1.liquidity_token_balance.to_owned() / position0.liquidity_token_balance.to_owned() // position0 balance must not be 0
        } else {
            BigDecimal::from(1)
        };
        fees *= ratio.clone();
        imp_loss *= ratio;
    }

    return PositionMetrics {
        imp_loss,
        fees
    }
}