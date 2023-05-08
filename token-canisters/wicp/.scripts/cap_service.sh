#!/bin/bash
# CAP local Service setup

printf "🙏 Verifying the Cap Service status, please wait...\n\n"
if [ -z $CAP_ID ]; then 
    if [[ $NETWORK == "ic" ]]; then
        CAP_ID=lj532-6iaaa-aaaah-qcc7a-cai
    else 
        CAP_ID=$(cd ./cap && dfx canister id ic-history-router)
        if [ -z $CAP_ID ]; then
            # The extra space is intentional, used for alignment
           printf "⚠️  Warning: The Cap Service is required.\n\n"
           read -r -p "🤖 Enter the local Cap container ID (or nothing to continue to CAP setup): " CAP_ID
            if [ -z $CAP_ID ]; then
                read -r -p "🤖 Do you want to deploy the CAP canister on the local network? [Y/n]? " CONT

                if [ "$CONT" = "Y" ]; then
                    npm run cap:init
                    npm run cap:start
                    CAP_ID=$(cd ./cap && dfx canister id ic-history-router)
                fi
            fi
        fi
        
    fi
fi

# the cap id should be set by now, throw an error if not
if [ -z $CAP_ID ]; then
    printf "Error: The CAP canister is required!\n\n"
    exit 1
fi