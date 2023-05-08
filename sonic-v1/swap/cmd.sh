dfx canister install dfc --argument="(\"logo\", \"DFC\", \"DFC\", 8, 10000000000000000, principal \"$(dfx identity get-principal)\", 0)"

dfx canister install wicp --argument="(\"logo\", \"WICP\", \"WICP\", 8, 10000000000000000, principal \"$(dfx identity get-principal)\", 0)"

dfx canister install usdt --argument="(\"logo\", \"USDT\", \"USDT\", 8, 10000000000000000, principal \"$(dfx identity get-principal)\", 0)"


dfx canister install storage --argument="(principal \"$(dfx canister id dswap)\", principal \"$(dfx identity get-principal)\")"

dfx canister install dswap --argument="(principal \"$(dfx identity get-principal)\", principal \"$(dfx canister id dfc)\", principal \"$(dfx canister id storage)\")"


dfx canister call dswap addToken "(principal \"$(dfx canister id dfc)\")"
dfx canister call dswap addToken "(principal \"$(dfx canister id wicp)\")"
dfx canister call dswap addToken "(principal \"$(dfx canister id usdt)\")"

dfx canister call dswap balanceOf "(\"$(dfx canister id wicp)\", principal \"$(dfx identity get-principal)\")"
dfx canister call dswap getUserInfo "(principal \"$(dfx identity get-principal)\")"

dfx canister call wicp approve "(principal \"$(dfx canister id dswap)\", 100000000_00000000:nat)"
dfx canister call dfc approve "(principal \"$(dfx canister id dswap)\", 100000000_00000000:nat)"

dfx canister call dswap deposit "(principal \"$(dfx canister id wicp)\", 1000000_00000000:nat)"
dfx canister call dswap withdraw "(principal \"$(dfx canister id wicp)\", 100000_00000000:nat)"
dfx canister call dswap deposit "(principal \"$(dfx canister id dfc)\", 1000000_00000000:nat)"


dfx canister call dswap createPair "(principal \"$(dfx canister id wicp)\", principal \"$(dfx canister id dfc)\")"

dfx canister call dswap addLiquidity "(principal \"$(dfx canister id wicp)\", principal \"$(dfx canister id dfc)\", 100000_00000000:nat, 100000_00000000:nat, 0:nat, 0:nat)"

LPtoken=$(dfx canister call dswap getLPTokenId "(principal \"$(dfx canister id wicp)\", principal \"$(dfx canister id dfc)\")")
LPtoken=${LPtoken:2:55}
dfx canister call dswap balanceOf "(\"$LPtoken\", principal \"$(dfx identity get-principal)\")"

dfx canister call dswap swapExactTokensForTokens "(10000_00000000:nat, 0:nat, vec{\"$(dfx canister id wicp)\";\"$(dfx canister id dfc)\"}, principal \"$(dfx identity get-principal)\")"


dfx canister call dswap balanceOf "(\"$(dfx canister id wicp)\", principal \"$(dfx identity get-principal)\")"
dfx canister call dswap balanceOf "(\"$(dfx canister id dfc)\", principal \"$(dfx identity get-principal)\")"

dfx canister call storage getStatus
dfx canister call storage getTransactions "(0,7)"
dfx canister call dswap removeLiquidity "(principal \"$(dfx canister id wicp)\", principal \"$(dfx canister id dfc)\", 9_999_999_999_000:nat)"
