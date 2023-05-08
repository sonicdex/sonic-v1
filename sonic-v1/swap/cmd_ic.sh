dfx canister --network ic install dswap --argument="(principal \"$(dfx identity get-principal)\", principal \"$(dfx canister --network ic id storage)\")"

dfx canister --network ic install storage --argument="(principal \"$(dfx identity get-principal)\")"

 dfx canister --network ic call storage setDSwapCanisterId "(principal \"$(dfx canister --network ic id dswap)\")"

dfx canister --network ic call dswap createDtoken "(principal \"lf23w-ciaaa-aaaah-qaeya-cai\")"
dfx canister --network ic call dswap createDtoken "(principal \"lx4mp-oyaaa-aaaah-qae3a-cai\")"

dfx canister --network ic call lf23w-ciaaa-aaaah-qaeya-cai approve "(principal \"$(dfx canister --network ic id dswap)\", 100000000_00000000:nat)"
dfx canister --network ic call lx4mp-oyaaa-aaaah-qae3a-cai approve "(principal \"$(dfx canister --network ic id dswap)\", 100000000_00000000:nat)"

dfx canister --network ic call dswap createPair "(principal \"lx4mp-oyaaa-aaaah-qae3a-cai\", principal \"lf23w-ciaaa-aaaah-qaeya-cai\")"


dfx canister --network ic call dswap deposit "(principal \"lf23w-ciaaa-aaaah-qaeya-cai\", 1000000_00000000:nat)"
dfx canister --network ic call dswap deposit "(principal \"lx4mp-oyaaa-aaaah-qae3a-cai\", 1000000_00000000:nat)"

dfx canister --network ic call dswap addLiquidity "(principal \"lx4mp-oyaaa-aaaah-qae3a-cai\", principal \"lf23w-ciaaa-aaaah-qaeya-cai\", 500000_00000000:nat, 500000_00000000:nat, 0:nat, 0:nat)"

dfx canister --network ic call dswap swap "(principal \"lx4mp-oyaaa-aaaah-qae3a-cai\", principal \"lf23w-ciaaa-aaaah-qaeya-cai\", 1000_00000000:nat, 800_00000000:nat)"

dfx canister --network ic call dswap removeLiquidity "(principal \"lx4mp-oyaaa-aaaah-qae3a-cai\", principal \"lf23w-ciaaa-aaaah-qaeya-cai\", 900:nat)"
