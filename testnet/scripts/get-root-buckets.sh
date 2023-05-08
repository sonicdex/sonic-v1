#!/bin/bash
cd $(dirname $BASH_SOURCE)/../ || exit 1

_services=("swap-v1" "wicp" "test-coin")
_full_result=""

for _service in "${_services[@]}"; do
  _result=$(dfx canister call cap-router get_token_contract_root_bucket "(record { canister = principal \"$(dfx canister id $_service)\"; witness = false })")
  _parsed=$(echo $_result | awk -F '"' '{print $2}')
  _full_result="${_full_result}${_service}: \"${_parsed}\"\n"
done

echo -e $_full_result