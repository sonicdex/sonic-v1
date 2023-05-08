/**
 * Module     : types.mo
 * Copyright  : 2021 Psychedelic
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : Soinc Team
 * Stability  : Experimental
 */

import Time "mo:base/Time";

module {
    /// Update call operations
    public type Operation = {
        #deposit;
        #withdraw;
        #tokenTransfer;
        #tokenTransferFrom;
        #tokenApprove;

        #lpTransfer;
        #lpTransferFrom;
        #lpApprove;

        #createPair;
        #swap;
        #addLiquidity;
        #removeLiquidity;
    };
    /// Update call operation record fields
    public type TxRecord = {
        caller: Principal;
        op: Operation;
        index: Nat;
        tokenId: Text; // used for lp/token operations
        from: Principal;
        to: Principal;
        amount: Nat;  // == lpAmount when addLiq/removeLiq, 0 when swap
        amount0: Nat; // used for swap/addLiq/removeLiq
        amount1: Nat; // used for swap/addLiq/removeLiq
        /* (reserve0, reserve1): 
        * if op = swap/addLiq/removeLiq, (pair.reserve0, pair.reserve1);
        * if op = deposit/withdraw, (user balance, total token balance in canister);
        * if op = transfer/transferFrom, (from user balance, to user balance)
        */
        reserve0: Nat; 
        reserve1: Nat;
        fee: Nat; // fee for transfer/approve/swap
        timestamp: Time.Time;
    };
};    
