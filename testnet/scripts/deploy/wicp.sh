#!/bin/bash
cd $(dirname $BASH_SOURCE)/../../ || exit 1

dfx deploy --no-wallet wicp \
  --argument="(
			\"data:image/png;base64,$(base64 dependencies/wicp/WICP-logo.png)\",
			\"Wrapped ICP\",
			\"WICP\",
			8:nat8,
			18446744073709551615:nat,
			principal \"$(dfx identity get-principal)\",
			0,
			principal \"$(dfx identity get-principal)\",
			principal \"$(dfx canister id cap-router)\",
			opt principal \"$(dfx canister id ledger)\"
	  )"