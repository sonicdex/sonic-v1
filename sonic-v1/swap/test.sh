#!/bin/bash

set -e

# clear
dfx stop
rm -rf .dfx

dfx start --background
dfx canister create --all
dfx build

dfx canister install sonic      --argument="(\"logo\", \"SONIC\", \"SONIC\", 8, 10000000000000000, principal \"$(dfx identity get-principal)\", 10)"
dfx canister install wicp       --argument="(\"logo\", \"WICP\", \"WICP\", 8, 10000000000000000, principal \"$(dfx identity get-principal)\", 10)"
dfx canister install usdt       --argument="(\"logo\", \"USDT\", \"USDT\", 8, 10000000000000000, principal \"$(dfx identity get-principal)\", 10)"
dfx canister install storage    --argument="(principal \"$(dfx canister id dswap)\", principal \"$(dfx identity get-principal)\")"
dfx canister install dswap      --argument="(principal \"$(dfx identity get-principal)\", principal \"$(dfx canister id sonic)\", principal \"$(dfx canister id storage)\")"
dfx canister install testDswap  --argument="(principal \"$(dfx canister id dswap)\", principal \"$(dfx canister id sonic)\", principal \"$(dfx canister id wicp)\", principal \"$(dfx canister id usdt)\")"

TEST_ID=$(dfx canister id testDswap)
TEST_ID="principal \"$TEST_ID\""
echo testDswap principal: $TEST_ID

echo authorize
dfx canister call dswap addAuth "($TEST_ID)"

echo mint to test_canister
dfx canister call sonic transfer "($TEST_ID, 10000_00000000)"
dfx canister call wicp  transfer "($TEST_ID, 10000_00000000)"
dfx canister call usdt  transfer "($TEST_ID, 100000_00000000)"

echo Testing begin!
dfx canister call testDswap tests

dfx stop
