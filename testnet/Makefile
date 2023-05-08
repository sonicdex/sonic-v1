.PHONY: replica-start replica-stop replica-reset cap wicp xtc swap-v2 launchpad-registry canister-ids full-deploy add-user cloud cloud-remote swap-v1 ledger-accounts

PRINCIPALS = $(shell dfx identity get-principal)
CAP_ID ?= $(shell dfx canister id cap-router)
WICP_ID ?= $(shell dfx canister id wicp)
XTC_ID ?= $(shell dfx canister id xtc)
SWAP_V2_FACTORY ?= $(shell dfx canister id swap-v2-factory)
SWAP_V1 ?= $(shell dfx canister id swap-v1)
LAUNCHPAD_REGISTRY ?= $(shell dfx canister id launchpad-registry)
TEST_COIN ?= $(shell dfx canister id test-coin)
LEDGER_ID ?= $(shell dfx canister id ledger)

# --- Prestart ---
init:
	git submodule update --init
	@./scripts/fetch-ledger-wasm.sh
# ------

# --- Run ---
cloud:
	cd scripts && ./start-cloud.sh local

cloud-remote:
	cd scripts && ./start-cloud.sh remote

replica-stop:
	dfx stop

replica-start: replica-stop
	dfx start --host 0.0.0.0:8000 --background

replica-reset: replica-stop
	rm -rf .dfx
# ------

# --- Deploy ---
ledger:
	@# $(shell [ -z "$(LEDGER_ID)" ] && scripts/deploy/ledger.sh)
	@echo "ledger canister id: $(LEDGER_ID)"

cap:
	@# $(shell [ -z "$(CAP_ID)" ] && dfx deploy cap-router)
	@echo "cap canister id: $(CAP_ID)"

wicp: cap
	@# $(shell [ -z "$(WICP_ID)" ] && scripts/deploy/wicp.sh)
	@echo "wicp canister id: $(WICP_ID)"

test-coin: cap
	@# $(shell [ -z "$(TEST_COIN)" ] && scripts/deploy/test-coin.sh)
	@echo "test-coin canister id: $(TEST_COIN)"

xtc:
	@# $(shell [ -z "$(XTC_ID)" ] && scripts/deploy/xtc.sh)
	@echo "xtc canister id: $(XTC_ID)"

swap-v1: cap wicp xtc test-coin
	@# $(shell [ -z "$(SWAP_V1)" ] && scripts/deploy/swap-v1.sh)
	@echo "swap-v1 canister id: $(SWAP_V1)"

swap-v2: cap xtc
	@# $(shell [ -z "$(SWAP_V2_FACTORY)" ] && scripts/deploy/swap-v2.sh)
	@echo "swap-v2 canister id: $(SWAP_V2_FACTORY)"

launchpad-registry: xtc
	@# $(shell [ -z "$(LAUNCHPAD_REGISTRY)" ] && scripts/deploy/launchpad-registry.sh)
	@echo "launchpad-registry canister id: $(LAUNCHPAD_REGISTRY)"

full-deploy: init replica-reset replica-start ledger cap wicp test-coin xtc swap-v1 swap-v2 launchpad-registry canister-ids
# ------

# --- Utils ---
add-user:
	scripts/add-user.sh $(PRINCIPAL)

canister-ids:
	@echo "LEDGER: $(LEDGER_ID)\nCAP_ID: $(CAP_ID)\nWICP_ID: $(WICP_ID)\nXTC_ID: $(XTC_ID)\nSWAP_V1: $(SWAP_V1)\nSWAP_V2_FACTORY: $(SWAP_V2_FACTORY)\nLAUNCHPAD_REGISTRY: $(LAUNCHPAD_REGISTRY)\nTEST_COIN: $(TEST_COIN)"

root-buckets:
	@scripts/get-root-buckets.sh

ledger-accounts:
	@scripts/get-ledger-accounts.sh
# ------