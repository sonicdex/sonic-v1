use crate::BigUint;
use crate::BigDecimal;

#[derive(GraphQLObject)]
pub struct Sonic {
    #[graphql(description = "Canister ID of Sonic")]
    id: juniper::ID,

    #[graphql(description = "Total transaction count")]
    token_count: i32,
    #[graphql(description = "Total pair count")]
    pair_count: i32,

    #[graphql(description = "Total trade volume in ICP", name = "totalVolumeICP")]
    total_volume_icp: BigDecimal,
    #[graphql(description = "Total trade volume in USD", name = "totalVolumeUSD")]
    total_volume_usd: BigDecimal,

    #[graphql(description = "Total untracked trade volume in ICP", name = "untrackedVolumeICP")]
    untracked_volume_icp: BigDecimal,
    #[graphql(description = "Total untracked trade volume in USD", name = "untrackedVolumeUSD")]
    untracked_volume_usd: BigDecimal,

    #[graphql(description = "Total liquidity in ICP", name = "totalLiquidityICP")]
    total_liquidity_icp: BigDecimal,
    #[graphql(description = "Total liquidity in USD", name = "totalLiquidityUSD")]
    total_liquidity_usd: BigDecimal,

    #[graphql(description = "Total transaction count")]
    tx_count: BigUint,
}

impl From<crate::model::Sonic> for Sonic {
    fn from(s: crate::model::Sonic) -> Self {
        Self {
            id: s.id.into(),
            token_count: s.token_count,
            pair_count: s.pair_count,
            total_volume_icp: s.total_volume_icp,
            total_volume_usd: s.total_volume_usd,
            untracked_volume_icp: s.untracked_volume_icp,
            untracked_volume_usd: s.untracked_volume_usd,
            total_liquidity_icp: s.total_liquidity_icp,
            total_liquidity_usd: s.total_liquidity_usd,
            tx_count: s.tx_count
        }
    }
}