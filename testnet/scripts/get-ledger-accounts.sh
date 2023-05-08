#!/bin/bash
cd $(dirname $BASH_SOURCE)/../ || exit 1

dfx identity use minter >/dev/null 2>&1
_mint_account=$(dfx ledger account-id)

dfx identity use default >/dev/null 2>&1
_ledger_account=$(dfx ledger account-id)
_ledger_controller=$(dfx identity get-principal)

echo -e "mint account: \"$_mint_account\"\nledger account: \"$_ledger_account\"\nledger controller: \"$_ledger_controller\""