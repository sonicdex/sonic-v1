#!/bin/bash
cd $(dirname $BASH_SOURCE)/../../ || exit 1

dfx canister create swap-v1
dfx deploy --no-wallet swap-v1 --argument="(principal \"$(dfx identity get-principal)\", principal \"$(dfx canister id swap-v1)\", principal \"$(dfx canister id cap-router)\")"

dfx canister call swap-v1 addToken "(principal \"$(dfx canister id wicp)\")"
dfx canister call swap-v1 addToken "(principal \"$(dfx canister id xtc)\")"
dfx canister call swap-v1 addToken "(principal \"$(dfx canister id test-coin)\")"