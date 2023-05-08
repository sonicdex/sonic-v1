# SonicSwap

Two canisters:

* swap: main canister holding user assets, swap main logic （goeik-taaaa-aaaah-qcduq-cai）
* storage: using CAP for history transaction storage



### Data Structures

1. TokenInfo

   ```
   public type TokenInfoExt = {
           id: Text;
           name: Text;
           symbol: Text;
           decimals: Nat8;
           fee: Nat; // fee for internal transfer/approve
           totalSupply: Nat;
       };
   ```

2. PairInfo

   ```
   public type PairInfoExt = {
           id: Text;
           token0: Text; //Principal;
           token1: Text; //Principal;
           creator: Principal;
           reserve0: Nat;
           reserve1: Nat;
           price0CumulativeLast: Nat;
           price1CumulativeLast: Nat;
           kLast: Nat;
           blockTimestampLast: Int;
           totalSupply: Nat;
           lptoken: Text;
       };
   ```

3. UserInfo

   ```
   type UserInfo = {
           balances: [(Principal, Nat)]; // user token balances [(token id, balance)...]
           lpBalances: [(Text, Nat)]; // user lp token balances [(lp token id, balance)...]; lp token decimal = 8
       };
   ```

4. SwapInfo

   ```
   type SwapInfo = {
           owner : Principal; // dswap canister creator
           cycles : Nat; // dswap canister cycles balance
           tokens: [TokenInfoExt]; // supported tokens info
           pairs: [PairInfoExt]; // supported pairs info
       };
   ```
   
5. TxReceipt, if success, returns the index of the tx record, otherwise return an error message.

   ```
   public type TxReceipt = Result.Result<Nat, Text>;
   ```
   
6. TxRecord, refer to [CAP sdk](https://github.com/Psychedelic/cap/tree/motoko-sdk/sdk/motoko) on record structure and how to retrive tx record.

   ```
   TxRecord = {
   	caller: Principal;
   	operation: Text;
   	details: [(Text, Root.DetailValue)];
   	time: Nat64;
   };
   // operation can be: addToken/createPair/addLiquidity/removeLiquidity/swap           //  tokenApprove/lpApprove/tokenTransfer/lpTransfer/tokenTransferFrom/lpTransferFrom
   ```

   

## APIs



### 1. Swap canister

#### 1.1. query calls

```
1. getPair(token0: Principal, token1: Principal) : async ?PairInfoExt // get pair info
2. getAllPairs(): async [PairInfoExt] // get all pairs info
3. getNumPairs(): async Nat // get number of pairs
4. getSupportedTokenList(): async [TokenInfoExt] // get supported tokens/assets
5. getUserLPBalances(user: Principal): async [(Text, Nat)] // (lptoken id, balance)
6. getUserInfo(user: Principal): async UserInfo // get user info
7. getDSwapInfo(): async DSwapInfo // get dswap info
```

#### 

#### 1.2. update calls

```
0. addToken(tokenId: Principal) : async TxReceipt // add an asset to dswap
1. createPair(token0: Principal, token1: Principal): async TxReceipt // create pair
2. addLiquidity(token0: Principal, token1: Principal, amount0Desired: Nat, amount1Desired: Nat, amount0Min: Nat, amount1Min: Nat, deadline: Int): async TxReceipt // add liquidity
3. removeLiquidity(token0: Principal, token1: Principal, lpAmount: Nat, to: Principal, deadline: Int): async TxReceipt // remove liquidity
4. deposit(tokenId: Principal, value: Nat) : async TxReceipt // deposit token into swap
5. depositTo(tokenId: Principal, to: Principal, value: Nat) : async TxReceipt // deposit token into swap, balance are added to user `to`
6. withdraw(tokenId: Principal, value: Nat) : async TxReceipt // withdraw token from swap
7. withdrawTo(tokenId: Principal, to: Principal, value: Nat) : async TxReceipt // withdraw token from swap to user `to`
8. swapExactTokensForTokens(amountIn: Nat, amountOutMin: Nat, path: [Text], to: Principal, deadline: Int): async TxReceipt
9. swapTokensForExactTokens(amountOut: Nat, amountInMax: Nat, path: [Text], to: Principal, deadline: Int): async TxReceipt
10. lazySwap(amountIn: Nat, amountOutMin: Nat, path[Text], to: Principal): async TxReceipt // aggregate deposit, swap & withdraw in one function

// lp token & token related
1. transfer(tokenId: Text, to: Principal, value: Nat) : async TxReceipt
2. transferFrom(tokenId: Text, from: Principal, to: Principal, value: Nat) : async TxReceipt
3. approve(tokenId: Text, spender: Principal, value: Nat) : async TxReceipt
4. balanceOf(tokenId: Text, who: Principal) : async Nat
5. allowance(tokenId: Text, owner: Principal, spender: Principal) : async Nat
6. totalSupply(tokenId: Text) : async Nat
7. name(tokenId: Text) : async Text
8. decimals(tokenId: Text) : async Nat
9. symbol(tokenId: Text) : async Text
```





