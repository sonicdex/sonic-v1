#!/bin/bash
cd $(dirname $BASH_SOURCE)/../../ || exit 1

dfx deploy --no-wallet test-coin \
  --argument="(
			\"data:image/png;base64,$(base64 assets/test-coin.png)\",
			\"Test Coin\",
			\"COIN\",
			8:nat8,
			0:nat,
			principal \"$(dfx identity get-principal)\",
			0,
			principal \"$(dfx identity get-principal)\",
			principal \"$(dfx canister id cap-router)\"
	  )"