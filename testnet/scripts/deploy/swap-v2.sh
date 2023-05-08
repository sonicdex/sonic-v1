#!/bin/bash
cd $(dirname $BASH_SOURCE)/../../ || exit 1

dfx deploy --no-wallet swap-v2-factory --argument="(principal \"$(dfx identity get-principal)\", principal \"$(dfx canister id xtc)\", principal \"$(dfx canister id cap-router)\")"