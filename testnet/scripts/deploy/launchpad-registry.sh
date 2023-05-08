#!/bin/bash
cd $(dirname $BASH_SOURCE)/../../ || exit 1

dfx deploy --no-wallet launchpad-registry --argument="(principal \"$(dfx identity get-principal)\", principal\"$(dfx canister id xtc)\", 2_000_000_000_000:nat)"