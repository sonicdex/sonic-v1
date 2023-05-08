<h1 align="center">Sonic Testnet</h1>

<h3 align="center">Development scripts for Sonic testnet</h3>

## Installation

For clean environments without the necessary dev tools, it will be necessary to install:

-   DFX (0.9.3)
-   Rust (1.61.0)
    -   ic-cdk-optimizer
    -   target add wasm32-unknown-unknown
-   Node (16.x)
    -   yarn
    -   serve

For debian based environments you can run the script:

```
sudo scripts/install-tools.sh
```

## Cloud

The `cloud` folder holds two projects for helping with all replica canisters deploying and controlling:

### Dashboard

The `cloud/dashboard` is the frontend project that allows to easily control the replica development replica and its canisters.

### Service

The `cloud/service` project is a HTTP and Websocket worker to serve as an API for dashboard to interact with the development replica and run predefined scripts.

When live, the Service serves connection listeners for `http` and `websocket` that can used through `http://{host}` and `ws://{host}`.

### Running the Cloud

You can run the cloud to deploy all your services locally by running:

```
make cloud
```

The `service` and `dashboard` will be both running on `localhost:3232` and `localhost:3233` respectively. You can also setup your settings on `cloud/settings.json`.

## Scripts

### Dependencies Fetching

```
make init
```

### IC Replica Control

```
make start-replica
```

```
make stop-replica
```

```
make reset-replica
```

### Date Retrieve

```
make canister-ids
```

```
make root-buckets
```

### Services Deploy

```
make cap
```

```
make wicp
```

```
make xtc
```

```
make test-coin
```

```
make swap-v1
```

```
make swap-v2
```

```
make launchpad-registry
```

```
make add-user PRINCIPAL=lkqmh-5vihe-t5x5j-smuot-vitei-tgfyx-losfh-bbud4-fp2rq-353dj-yqe
```
