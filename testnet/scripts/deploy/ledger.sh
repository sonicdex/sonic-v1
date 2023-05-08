#!/bin/bash
cd $(dirname $BASH_SOURCE)/../../ || exit 1

echo "Setting ledger private did file"
jq '.canisters.ledger.candid = "dependencies/ledger/ledger.private.did"' dfx.json > dfx.json.tmp && mv dfx.json.tmp dfx.json

dfx identity new minter
dfx identity use minter
export MINT_ACC=$(dfx ledger account-id)

dfx identity use default
export LEDGER_ACC=$(dfx ledger account-id)
export ARCHIVE_CONTROLLER=$(dfx identity get-principal)

dfx deploy ledger --argument '(record {
  minting_account = "'${MINT_ACC}'"; 
  initial_values = vec { record { "'${LEDGER_ACC}'"; record { e8s=17_446_744_073_709_551_615 } }; }; 
  max_message_size_bytes = null;
  transaction_window = null;
  archive_options = opt record { trigger_threshold = 2000; num_blocks_to_archive = 1000; controller_id = principal "'${ARCHIVE_CONTROLLER}'" };
  send_whitelist = vec {}; 
  transfer_fee = null;
  token_symbol = null;
  token_name = null;
},)'

echo "Setting ledger public did file"
jq '.canisters.ledger.candid = "dependencies/ledger/ledger.public.did"' dfx.json > dfx.json.tmp && mv dfx.json.tmp dfx.json

echo "Checking ledger account balance:"
dfx canister call ledger account_balance '(record { account = '$(python3 -c 'print("vec{" + ";".join([str(b) for b in bytes.fromhex("'$LEDGER_ACC'")]) + "}")')' })'