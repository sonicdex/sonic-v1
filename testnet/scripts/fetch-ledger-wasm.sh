#!/bin/bash
cd $(dirname $BASH_SOURCE)/../dependencies/ledger || exit 1

echo "Fetching ledger-wasm"
export IC_VERSION=dd3a710b03bd3ae10368a91b255571d012d1ec2f

if [ -f ledger.wasm ]; then
  echo "ledger.wasm already fetched"
else
  curl -o ledger.wasm.gz https://download.dfinity.systems/ic/${IC_VERSION}/canisters/ledger-canister_notify-method.wasm.gz
  gunzip ledger.wasm.gz
fi

if [ -f ledger.private.did ]; then
  echo "ledger.private.did already fetched"
else
  curl -o ledger.private.did https://raw.githubusercontent.com/dfinity/ic/${IC_VERSION}/rs/rosetta-api/ledger.did
fi

if [ -f ledger.public.did ]; then
  echo "ledger.public.did already fetched"
else
  curl -o ledger.public.did https://raw.githubusercontent.com/dfinity/ic/${IC_VERSION}/rs/rosetta-api/ledger_canister/ledger.did
fi


