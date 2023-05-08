#!/bin/bash
cd $(dirname $BASH_SOURCE)/../ || exit 1

_user=$1

if [ -z "$_user" ]; then
  echo "Principal Id not provided: $0"
  exit 98
fi

echo "Adding user $_user..."

echo "Minting ICP"
dfx --identity minter ledger transfer $(python3 scripts/utils/account2principal.py $_user) --ledger-canister-id $(dfx canister id ledger) --memo 12345 --icp 100 --fee 0

echo "Sending WICP"
dfx canister call wicp transfer "(principal \"$_user\", 100_000_000_000_000:nat)"

echo "Minting COIN"
dfx canister call test-coin mint "(principal \"$_user\", 100_000_000_000_000:nat)"

echo "Minting XTC"
xtc_mint() 
{
  rm -rf .dfx/local/wallets.json
  errormessage=$(dfx canister --wallet "$(dfx identity get-wallet)" call --with-cycles 100000000000000 xtc mint "(principal \"$_user\", 0:nat)" 2>&1)
  rm -rf .dfx/local/wallets.json
  if [[ $errormessage == *"nat is not a subtype of nat64"* ]]
  then
    echo "XTC mint is fine!"
  else
    echo $errormessage
    exit 99
  fi
}
xtc_mint



echo "Adding to Launchpad whitelist"
dfx canister call launchpad-registry addWhitelist "(principal \"$_user\")"