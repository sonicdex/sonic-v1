#!/bin/bash

set -e

# clear
dfx stop
rm -rf .dfx

ALICE_HOME=$(mktemp -d -t alice-temp)
BOB_HOME=$(mktemp -d -t bob-temp)
HOME=$ALICE_HOME

ALICE_PUBLIC_KEY="principal \"$( \
    HOME=$ALICE_HOME dfx identity get-principal
)\""
BOB_PUBLIC_KEY="principal \"$( \
    HOME=$BOB_HOME dfx identity get-principal
)\""

dfx start --background
dfx canister create --all
dfx build

echo Testing Dtoken
echo ================================================================
echo == install token0
eval dfx canister install --argument="'(\"Test Token0\", \"TT0\", 8, 10000_00000000, $ALICE_PUBLIC_KEY)'" token0

echo == install token1
eval dfx canister install --argument="'(\"Test Token1\", \"TT1\", 8, 10000_00000000, $ALICE_PUBLIC_KEY)'" token1

TOKEN0_ID=$(dfx canister id token0)
TOKEN0_ID="principal \"$TOKEN0_ID\""
echo token0 principal: $TOKEN0_ID
TOKEN1_ID=$(dfx canister id token1)
TOKEN1_ID="principal \"$TOKEN1_ID\""
echo token1 principal: $TOKEN1_ID

echo == install dswap
eval dfx canister install dswap

DSWAP_ID=$(dfx canister id dswap)
DSWAP_ID="principal \"$DSWAP_ID\""
echo dswap principal: $DSWAP_ID


echo == transfer 1000 token0 to Bob
eval dfx canister call token0 transfer "'($BOB_PUBLIC_KEY, 1000_00000000)'"

echo == Create token0 and token1 Dtoken of Dswap
eval dfx canister call dswap creatDtoken "'($TOKEN0_ID)'"
eval dfx canister call dswap creatDtoken "'($TOKEN1_ID)'"

echo == Alice approve dswap to spend 5000 token0 and 5000 token1          
eval dfx canister call token0 approve "'($DSWAP_ID, 5000_00000000)'"
eval dfx canister call token1 approve "'($DSWAP_ID, 5000_00000000)'"

echo == Alice deposit 5000 token0 and 5000 token1
eval dfx canister call dswap deposit "'($TOKEN0_ID, 5000_00000000)'"
eval dfx canister call dswap deposit "'($TOKEN1_ID, 5000_00000000)'"

echo == Alice Token0 token1 balance
eval dfx canister call token0 balanceOf "'($ALICE_PUBLIC_KEY)'"
eval dfx canister call token1 balanceOf "'($ALICE_PUBLIC_KEY)'"
echo == Bob Token0 token1 balance
eval dfx canister call token0 balanceOf "'($BOB_PUBLIC_KEY)'"
eval dfx canister call token1 balanceOf "'($BOB_PUBLIC_KEY)'"
echo == Dswap token0 token1 balance
eval dfx canister call token0 balanceOf "'($DSWAP_ID)'"
eval dfx canister call token1 balanceOf "'($DSWAP_ID)'"

echo == Alice Transfer 500 dtoken0 and dtoken1 to Bob
eval dfx canister call dswap transfer "'($TOKEN0_ID, $BOB_PUBLIC_KEY, 500_00000000)'"
eval dfx canister call dswap transfer "'($TOKEN1_ID, $BOB_PUBLIC_KEY, 500_00000000)'"

echo == Alice approve bob 1000 dtoken0 and 1000 dtoken1
eval dfx canister call dswap approve "'($TOKEN0_ID, $BOB_PUBLIC_KEY, 1000_00000000)'"
eval dfx canister call dswap approve "'($TOKEN1_ID, $BOB_PUBLIC_KEY, 1000_00000000)'"

echo == Bob transferFrom Alice 500 dtoken0 and dtoken1 to himself
eval HOME=$BOB_HOME dfx canister call dswap transferFrom "'($TOKEN0_ID, $ALICE_PUBLIC_KEY, $BOB_PUBLIC_KEY, 500_00000000)'"
eval HOME=$BOB_HOME dfx canister call dswap transferFrom "'($TOKEN1_ID, $ALICE_PUBLIC_KEY, $BOB_PUBLIC_KEY, 500_00000000)'"


echo == Get dtoken0 info IN dswap
eval dfx canister call dswap symbol "'($TOKEN0_ID)'"
eval dfx canister call dswap decimals "'($TOKEN0_ID)'"
eval dfx canister call dswap name "'($TOKEN0_ID)'"
eval dfx canister call dswap totalSupply "'($TOKEN0_ID)'"
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $ALICE_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $BOB_PUBLIC_KEY)'"
eval dfx canister call dswap allowance "'($TOKEN0_ID, $ALICE_PUBLIC_KEY, $BOB_PUBLIC_KEY)'"

echo == Get dtoken1 info IN dswap
eval dfx canister call dswap symbol "'($TOKEN1_ID)'"
eval dfx canister call dswap decimals "'($TOKEN1_ID)'"
eval dfx canister call dswap name "'($TOKEN1_ID)'"
eval dfx canister call dswap totalSupply "'($TOKEN1_ID)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $ALICE_PUBLIC_KEY)'"
eval dfx canister call dswap allowance "'($TOKEN0_ID, $ALICE_PUBLIC_KEY, $BOB_PUBLIC_KEY)'"

echo Testing Dswap
echo ================================================================
echo == Create Pair 
eval dfx canister call dswap createPair "'($TOKEN0_ID, $TOKEN1_ID)'"

echo == Get all Pair
eval dfx canister call dswap getAllPairs 

echo == Alice addLiquidity 4000 token0 and 1000 token1
eval dfx canister call dswap addLiquidity "'($TOKEN0_ID, $TOKEN1_ID,  4000_00000000, 1000_00000000, 0, 0)'"
echo == Get all Pair
eval dfx canister call dswap getAllPairs 

TOKENLP_ID=$(dfx canister call dswap getTokenId "($TOKEN0_ID, $TOKEN1_ID)")
echo $TOKENLP_ID
TOKENLP_ID=${TOKENLP_ID:2:54}
TOKENLP_ID=\"$TOKENLP_ID\"
echo $TOKENLP_ID

echo == Get Alice LP token balance
eval dfx canister call dswap lpBalanceOf "'($TOKENLP_ID, $ALICE_PUBLIC_KEY)'"

echo == Get Alice dtoken0 and dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $ALICE_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $ALICE_PUBLIC_KEY)'"
echo == Get Bob dtoken0 and dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $BOB_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $BOB_PUBLIC_KEY)'"
echo == Get dswap dtoken0 and dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $DSWAP_ID)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $DSWAP_ID)'"


echo == Bob swap 400 token0 to get token1
eval HOME=$BOB_HOME dfx canister call dswap swap "'($TOKEN0_ID, $TOKEN1_ID, 400_00000000, 0)'"

echo == Get all Pair
eval dfx canister call dswap getAllPairs 

echo == Alice dtoken0 dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $ALICE_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $ALICE_PUBLIC_KEY)'"
echo == Bob dtoken0 token1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $BOB_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $BOB_PUBLIC_KEY)'"
echo == Get dswap dtoken0 and dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $DSWAP_ID)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $DSWAP_ID)'"


echo == Alice remove liquidity
eval dfx canister call dswap removeLiquidity "'($TOKEN0_ID, $TOKEN1_ID, 199_999_999_000)'"

echo == Get all Pair
eval dfx canister call dswap getAllPairs 
echo == Alice dtoken0 dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $ALICE_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $ALICE_PUBLIC_KEY)'"
echo == Bob dtoken0 token1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $BOB_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $BOB_PUBLIC_KEY)'"
echo == Get dswap dtoken0 and dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $DSWAP_ID)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $DSWAP_ID)'"


echo == Get Alice balance
eval dfx canister call token0 balanceOf "'($ALICE_PUBLIC_KEY)'"
eval dfx canister call token1 balanceOf "'($ALICE_PUBLIC_KEY)'"
echo == Get dswap token0 and token1 balance
eval dfx canister call token0 balanceOf "'($DSWAP_ID)'"
eval dfx canister call token1 balanceOf "'($DSWAP_ID)'"
echo == Get Bob token0  and token1 balance
eval dfx canister call token0 balanceOf "'($BOB_PUBLIC_KEY)'"
eval dfx canister call token1 balanceOf "'($BOB_PUBLIC_KEY)'"

echo == Alice withdraw dtoken0 dtoken1 balance
eval dfx canister call dswap withdraw "'($TOKEN0_ID, 440_000_000_000)'"
eval dfx canister call dswap withdraw "'($TOKEN1_ID, 390_933_891_062)'"
echo == Bob withdraw dtoken0 dtoken1 balance
eval HOME=$BOB_HOME dfx canister call dswap withdraw "'($TOKEN0_ID, 60_000_000_000)'"
eval HOME=$BOB_HOME dfx canister call dswap withdraw "'($TOKEN1_ID, 109_066_108_938)'"


echo == Alice dtoken0 dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $ALICE_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $ALICE_PUBLIC_KEY)'"
echo == Bob dtoken0 token1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $BOB_PUBLIC_KEY)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $BOB_PUBLIC_KEY)'"
echo == Get dswap dtoken0 and dtoken1 balance
eval dfx canister call dswap balanceOf "'($TOKEN0_ID, $DSWAP_ID)'"
eval dfx canister call dswap balanceOf "'($TOKEN1_ID, $DSWAP_ID)'"

echo == Get Alice token0 and token1 balance
eval dfx canister call token0 balanceOf "'($ALICE_PUBLIC_KEY)'"
eval dfx canister call token1 balanceOf "'($ALICE_PUBLIC_KEY)'"
echo == Get dswap token0 and token1 balance
eval dfx canister call token0 balanceOf "'($DSWAP_ID)'"
eval dfx canister call token1 balanceOf "'($DSWAP_ID)'"
echo == Get Bob token0  and token1 balance
eval dfx canister call token0 balanceOf "'($BOB_PUBLIC_KEY)'"
eval dfx canister call token1 balanceOf "'($BOB_PUBLIC_KEY)'"

eval dfx stop