
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";

actor class TestSwap(
    dswap_id : Principal,
    sonic_id : Principal,
    wicp_id  : Principal,
    usdt_id  : Principal
    ) = this {

    let blackhole: Principal = Principal.fromText("aaaaa-aa");

    type TxReceipt = Result.Result<Nat, Text>;
    type TxReceiptToken = Result.Result<Nat, {
        #InsufficientBalance;
        #InsufficientAllowance;}>;

    type UserInfo = {
        balances: [(Text, Nat)];
        lpBalances: [(Text, Nat)];
    };

    public type DswapActor = actor {
        checkTxCounter: shared () -> async Bool;
        getNumPairs: () -> async Nat;
        getLPTokenId: (token0: Principal, token1: Principal) -> async Text;
        balanceOf: (tokenId: Text, who: Principal) -> async Nat;
        getUserBalances: (user: Principal) -> async [(Text, Nat)];
        getUserLPBalances: (user: Principal) -> async [(Text, Nat)];
        getUserInfo: (user: Principal) -> async UserInfo;

        addToken: shared (tokenId: Principal) -> async Result.Result<Bool, Text>;
        deposit: shared (tokenId: Principal, value: Nat) -> async TxReceipt;
        depositTo: shared (tokenId: Principal, to: Principal, value: Nat) -> async TxReceipt;
        withdraw: shared (tokenId: Principal, value: Nat) -> async TxReceipt;
        withdrawTo: shared (tokenId: Principal, to: Principal, value: Nat) -> async TxReceipt;

        createPair: shared (token0: Principal, token1: Principal) -> async TxReceipt;
        addLiquidity: shared (  token0: Principal, 
                                token1: Principal, 
                                amount0Desired: Nat, 
                                amount1Desired: Nat, 
                                amount0Min: Nat, 
                                amount1Min: Nat,
                                deadline: Int) -> async TxReceipt;

        removeLiquidity: shared (   token0: Principal,
                                    token1: Principal, 
                                    lpAmount: Nat,
                                    amount0Min: Nat,
                                    amount1Min: Nat,
                                    to: Principal,
                                    deadline: Int) -> async TxReceipt;

        swapExactTokensForTokens: shared (  amountIn: Nat,
                                            amountOutMin: Nat,
                                            path: [Text],
                                            to: Principal,
                                            deadline: Int) -> async TxReceipt;

        swapTokensForExactTokens: shared (  amountOut: Nat, 
                                            amountInMax: Nat, 
                                            path: [Text],
                                            to: Principal,
                                            deadline: Int) -> async TxReceipt;
        lazySwap: shared (  amountIn: Nat,
                            amountOutMin: Nat,
                            path: [Text],
                            to: Principal) -> async TxReceipt;
    };
    public type TokenActor = actor {
        approve: shared (spender: Principal, value: Nat) -> async TxReceiptToken;
        balanceOf: shared (who: Principal) -> async Nat;
    };

    let dswapCanister : DswapActor = actor(Principal.toText(dswap_id));
    let sonicCanister : TokenActor = actor(Principal.toText(sonic_id));
    let wicpCanister  : TokenActor = actor(Principal.toText(wicp_id) );
    let usdtCanister  : TokenActor = actor(Principal.toText(usdt_id) );

    func log_info (message: Text) {
        Debug.print(message);
    };

    public func testAddToken(tokenId: Principal): async Bool {
        switch(await dswapCanister.addToken(tokenId)){
            case(#ok(_)){
                log_info("[ok]: add token successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testDeposit(tokenId: Principal, value: Nat): async Bool {
        switch(await dswapCanister.deposit(tokenId, value)){
            case(#ok(_)){
                log_info("[ok]: deposit successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testDepositTo(tokenId: Principal, to: Principal, value: Nat): async Bool {
        switch(await dswapCanister.deposit(tokenId, value)){
            case(#ok(_)){
                log_info("[ok]: depositTo successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testWithdraw(tokenId: Principal, value: Nat): async Bool {
        switch(await dswapCanister.withdraw(tokenId, value)){
            case(#ok(_)){
                log_info("[ok]: withdraw successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testWithdrawTo(tokenId: Principal, to: Principal, value: Nat): async Bool {
        switch(await dswapCanister.withdrawTo(tokenId, to, value)){
            case(#ok(_)){
                log_info("[ok]: withdrawTo successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testCreatePair(token0: Principal, token1: Principal): async Bool {
        switch(await dswapCanister.createPair(token0, token1)){
            case(#ok(_)){
                log_info("[ok]: createPair successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testAddLiquidity(
        token0: Principal, 
        token1: Principal, 
        amount0Desired: Nat, 
        amount1Desired: Nat, 
        amount0Min: Nat, 
        amount1Min: Nat,
        deadline: Int
        ): async Bool {
        switch(await dswapCanister.addLiquidity(
            token0,
            token1,
            amount0Desired,
            amount1Desired,
            amount0Min,
            amount1Min,
            deadline
            )){
            case(#ok(_)){
                log_info("[ok]: addLiquidity successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testRemoveLiquidity (
        token0: Principal,
        token1: Principal, 
        lpAmount: Nat,
        amount0Min: Nat,
        amount1Min: Nat,
        to: Principal,
        deadline: Int
        ): async Bool {
        switch(await dswapCanister.removeLiquidity(
            token0,
            token1, 
            lpAmount,
            amount0Min,
            amount1Min,
            to,
            deadline
            )){
            case(#ok(_)){
                log_info("[ok]: removeLiquidity successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testSwapExactTokensForTokens(
        amountIn: Nat,
        amountOutMin: Nat,
        path: [Text],
        to: Principal,
        deadline: Int
        ): async Bool {
        switch(await dswapCanister.swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline)){
            case(#ok(_)){
                log_info("[ok]: swapExactTokensForTokens successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testSwapTokensForExactTokens(
        amountOut: Nat, 
        amountInMax: Nat, 
        path: [Text],
        to: Principal,
        deadline: Int
        ): async Bool {
        switch(await dswapCanister.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline)){
            case(#ok(_)){
                log_info("[ok]: swapTokensForExactTokens successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func testLazySwap(
        amountIn: Nat,
        amountOutMin: Nat,
        path: [Text],
        to: Principal
        ): async Bool {
        switch(await dswapCanister.lazySwap(amountIn, amountOutMin, path, to)){
            case(#ok(_)){
                log_info("[ok]: lazySwap successed");
                return true;
            };
            case(#err(err)){
                log_info("[error]: " # err);
                return false;
            };
        };
    };

    public func tests(): async Text {
        var total_count: Nat = 0;
        var pass_count : Nat = 0;
        var fail_count : Nat = 0;
        var skip_count : Nat = 0;

        log_info("******  Testing beginning! ******");
        log_info("====================================");
        log_info("1. %%%%% Testing addToken %%%%%");
        log_info("a): add token usdt");
        var result: Bool = await testAddToken(usdt_id);
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): add existed token usdt");
        result := await testAddToken(usdt_id);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        log_info("********************************** ");
        log_info("2. %%%%%% Testing deposit %%%%%");
        log_info("a): deposit wicp (not exist currently)");
        result := await testDeposit(wicp_id, 5000_00000000);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): add wicp token");
        ignore await testAddToken(wicp_id);
        skip_count += 1;
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c): get balance");
        var this_wicp_balance : Nat = await wicpCanister.balanceOf(Principal.fromActor(this));
        var dswap_wicp_balance: Nat = await wicpCanister.balanceOf(Principal.fromActor(dswapCanister));
        var this_usdt_balance : Nat = await usdtCanister.balanceOf(Principal.fromActor(this));
        var dswap_usdt_balance: Nat = await usdtCanister.balanceOf(Principal.fromActor(dswapCanister));
        log_info("testDswap canister wicp balance: " # Nat.toText(this_wicp_balance));
        log_info("testDswap canister usdt balance: " # Nat.toText(this_usdt_balance));
        log_info("dswap canister wicp balance: " # Nat.toText(dswap_wicp_balance));
        log_info("dswap canister usdt balance: " # Nat.toText(dswap_usdt_balance));
        skip_count += 1;
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("d): deposit 50000_00000000 wicp (exceeded balance)");
        result := await testDeposit(wicp_id, 50000_00000000);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("e): deposit 5000_00000000 wicp (allowance insufficient)");
        result := await testDeposit(wicp_id, 5000_00000000);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("f): deposit 5_00000000 wicp (fee insufficient)");
        result := await testDeposit(wicp_id, 5_00000000);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("g): deposit 1000_00000000 wicp and 50000_00000000 usdt");
        ignore await wicpCanister.approve(Principal.fromActor(dswapCanister), 1000_00000000);
        ignore await usdtCanister.approve(Principal.fromActor(dswapCanister), 50000_00000000);
        var result1 = await testDeposit(wicp_id, 1000_00000000);
        var result2 = await testDeposit(usdt_id, 50000_00000000);
        if (result1 and result2) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("h): get balance again");
        this_wicp_balance  := await wicpCanister.balanceOf(Principal.fromActor(this));
        dswap_wicp_balance := await wicpCanister.balanceOf(Principal.fromActor(dswapCanister));
        this_usdt_balance  := await usdtCanister.balanceOf(Principal.fromActor(this));
        dswap_usdt_balance := await usdtCanister.balanceOf(Principal.fromActor(dswapCanister));
        log_info("testDswap canister wicp balance: " # Nat.toText(this_wicp_balance));
        log_info("testDswap canister usdt balance: " # Nat.toText(this_usdt_balance));
        log_info("dswap canister wicp balance: " # Nat.toText(dswap_wicp_balance));
        log_info("dswap canister usdt balance: " # Nat.toText(dswap_usdt_balance));
        skip_count += 1;
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        Debug.print("fail_count:" # Nat.toText(fail_count));
        log_info("********************************** ");
        log_info("3. %%%%%% Testing createPair %%%%%");
        log_info("a): create new pair (wicp wicp)");
        result := await testCreatePair(wicp_id, wicp_id);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): create new pair (wicp blackhole) ");
        result := await testCreatePair(wicp_id, blackhole);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c) create new pair (wicp sonic)");
        result := await testCreatePair(wicp_id, sonic_id);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("d) create new pair (wicp usdt) ");
        result := await testCreatePair(wicp_id, usdt_id);
        var pair_num = await dswapCanister.getNumPairs();
        log_info("pairs count: " # Nat.toText(pair_num));
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("e) create exist pair (wicp usdt) ");
        result := await testCreatePair(wicp_id, usdt_id);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        log_info("********************************** ");
        log_info("4. %%%%%% Testing addLiquidity %%%%%");
        log_info("a): addLiquidity limited time");
        result := await testAddLiquidity(wicp_id, usdt_id, 1000_00000000, 50000_00000000, 0, 0, Time.now());
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): addLiquidity zero token amount ");
        result := await testAddLiquidity(wicp_id, usdt_id, 0, 0, 0, 0, Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c) addLiquidity to nonexitent pair(wicp sonic)");
        result := await testAddLiquidity(wicp_id, sonic_id, 1000_00000000, 50000_00000000, 0, 0, Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("d) addLiquidity to pair(wicp usdt) beyond balance");
        result := await testAddLiquidity(wicp_id, usdt_id, 2000_00000000, 100000_00000000, 0, 0, Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("e) not reach minumum liquidity (wicp usdt) ");
        try {
            result := await testAddLiquidity(wicp_id, usdt_id, 1, 50, 0, 0, Time.now()*2);
            if (result) {pass_count += 1;}
            else {
                log_info("! ! ! test fail");
                fail_count += 1;};
            total_count += 1;
        } catch(e) {
            pass_count += 1;
            total_count += 1;
        };

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("f) add 600_00000000 wicp , 30000_00000000 usdt to pair (wicp usdt) ");
        result := await testAddLiquidity(wicp_id, usdt_id, 600_00000000, 30000_00000000, 598_00000000, 29900_00000000, Time.now()*2);
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("g) get  balance ");
        var pair_str: Text = await dswapCanister.getLPTokenId(wicp_id, usdt_id);
        var lp_balance: Nat = await dswapCanister.balanceOf(pair_str, Principal.fromActor(this));
        var wicp_balance: Nat = await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        var usdt_balance: Nat = await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        log_info("testDswap lp balance:" # Nat.toText(lp_balance));
        log_info("testDswap wicp balance:" # Nat.toText(wicp_balance));
        log_info("testDswap usdt balance:" # Nat.toText(usdt_balance));
        skip_count += 1;
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("h) add 15000_00000000 usdt , 300_00000000 wicp to pair (usdt wicp) ");
        result := await testAddLiquidity(usdt_id, wicp_id, 15000_00000000, 300_00000000, 10000_00000000, 250_00000000, Time.now()*2);
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("i) get lp balance again");
        pair_str     := await dswapCanister.getLPTokenId(wicp_id, usdt_id);
        lp_balance   := await dswapCanister.balanceOf(pair_str, Principal.fromActor(this));
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        log_info("testDswap lp balance:" # Nat.toText(lp_balance));
        log_info("testDswap wicp balance:" # Nat.toText(wicp_balance));
        log_info("testDswap usdt balance:" # Nat.toText(usdt_balance));
        skip_count += 1;
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("j) Impermanence loss test");
        log_info("test: removeLiquidity not reach desired amount");
        result := await testRemoveLiquidity(wicp_id, usdt_id, lp_balance, 900_00000000, 45000_00000000, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("********************************** ");
        log_info("5. %%%%%% Testing swapExactTokensForTokens %%%%%");
        log_info("a): swap limited time");
        var path: [Text] = [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapExactTokensForTokens(1_00000000, 40_00000000, path, Principal.fromActor(this), Time.now());
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): swap no slippage");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapExactTokensForTokens(1_0000000, 50_00000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c): swap 200 wicp to usdt (exceed balance)");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapExactTokensForTokens(200_00000000, 5000_00000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("d): swap 1 wicp to usdt");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapExactTokensForTokens(1_00000000, 40_00000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("e) get  balance ");
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        log_info("testDswap wicp balance:" # Nat.toText(wicp_balance));
        log_info("testDswap usdt balance:" # Nat.toText(usdt_balance));
        skip_count += 1;
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("f): swap 50 usdt to wicp");
        path := [Principal.toText(usdt_id), Principal.toText(wicp_id)];
        result := await testSwapExactTokensForTokens(50_00000000, 80000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("g) get balance again");
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        log_info("testDswap wicp balance:" # Nat.toText(wicp_balance));
        log_info("testDswap usdt balance:" # Nat.toText(usdt_balance));
        skip_count += 1;
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        log_info("********************************** ");
        log_info("6. %%%%%% Testing swapTokensForExactTokens %%%%%");
        log_info("a): swap limited time");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapTokensForExactTokens(50_00000000, 1_20000000, path, Principal.fromActor(this), Time.now());
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): swap no slippage");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapTokensForExactTokens(50_00000000, 1_00000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c): swap 200 wicp to usdt (exceed balance)");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapTokensForExactTokens(10000_00000000, 100_00000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("d): swap 50 usdt with wicp");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapTokensForExactTokens(50_00000000, 1_20000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("e) get  balance ");
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        log_info("testDswap wicp balance:" # Nat.toText(wicp_balance));
        log_info("testDswap usdt balance:" # Nat.toText(usdt_balance));
        skip_count += 1;
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("f): swap 1 wicp with usdt");
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testSwapTokensForExactTokens(1_00000000, 60_00000000, path, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("g) get balance again");
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        log_info("testDswap wicp balance:" # Nat.toText(wicp_balance));
        log_info("testDswap usdt balance:" # Nat.toText(usdt_balance));
        skip_count += 1;
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        log_info("********************************** ");
        log_info("7. %%%%%% Testing lazyswap %%%%%");
        log_info("a) get  balance ");
        this_wicp_balance  := await wicpCanister.balanceOf(Principal.fromActor(this));
        this_usdt_balance  := await usdtCanister.balanceOf(Principal.fromActor(this));
        log_info("testDswap canister wicp balance: " # Nat.toText(this_wicp_balance));
        log_info("testDswap canister usdt balance: " # Nat.toText(this_usdt_balance));
        skip_count += 1;
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): lazyswap, swap 2 wicp to usdt");
        ignore await wicpCanister.approve(Principal.fromActor(dswapCanister), 2_00000000);
        path := [Principal.toText(wicp_id), Principal.toText(usdt_id)];
        result := await testLazySwap(2_00000000, 90_00000000, path, Principal.fromActor(this));
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c) get  balance again");
        this_wicp_balance  := await wicpCanister.balanceOf(Principal.fromActor(this));
        this_usdt_balance  := await usdtCanister.balanceOf(Principal.fromActor(this));
        log_info("testDswap canister wicp balance: " # Nat.toText(this_wicp_balance));
        log_info("testDswap canister usdt balance: " # Nat.toText(this_usdt_balance));
        skip_count += 1;
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        log_info("********************************** ");
        log_info("8. %%%%%% Testing removeLiquidity %%%%%");
        log_info("a): removeLiquidity limited time");
        result := await testRemoveLiquidity(wicp_id, usdt_id, lp_balance, 0, 0, Principal.fromActor(this), Time.now());
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): removeLiquidity with nonexitent pair(wicp, sonic) ");
        result := await testRemoveLiquidity(wicp_id, sonic_id, lp_balance, 0, 0, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c): removeLiquidity not reach desired amount");
        var wicp_amountout = 900_00000000 + 3_0000 * 25;
        var usdt_amountout = 45000_00000000 + 50_0000 * 25;
        result := await testRemoveLiquidity(wicp_id, usdt_id, lp_balance, wicp_amountout, usdt_amountout, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("d): removeLiquidity zero lpamount");
        result := await testRemoveLiquidity(wicp_id, usdt_id, 0, 0, 0, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("e): removeLiquidity too little lpamount");
        result := await testRemoveLiquidity(wicp_id, usdt_id, 1, 0, 0, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("f): removeLiquidity too large lpamount");
        result := await testRemoveLiquidity(wicp_id, usdt_id, lp_balance * 2, 0, 0, Principal.fromActor(this), Time.now()*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("g): removeLiquidity");
        result := await testRemoveLiquidity(wicp_id, usdt_id, lp_balance, 0, 0, Principal.fromActor(this), Time.now()*2);
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("h): get balance");
        pair_str     := await dswapCanister.getLPTokenId(wicp_id, usdt_id);
        lp_balance   := await dswapCanister.balanceOf(pair_str, Principal.fromActor(this));
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        log_info("testDswap lp balance:" # Nat.toText(lp_balance));
        log_info("testDswap wicp balance:" # Nat.toText(wicp_balance));
        log_info("testDswap usdt balance:" # Nat.toText(usdt_balance));
        skip_count += 1;
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        log_info("********************************** ");
        log_info("9. %%%%%% Testing withdraw %%%%%");
        log_info("a): withdraw sonic (not exist currently)");
        result := await testWithdraw(sonic_id, 1000_00000000);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("b): withdraw too little token ");
        result := await testWithdraw(sonic_id, 1);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("c): withdraw too large token ");
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        result := await testWithdraw(wicp_id, wicp_balance*2);
        if (result) {
            log_info("! ! ! test fail");
            fail_count += 1;}
        else {pass_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("d): withdraw all wicp token and usdt token");
        wicp_balance := await dswapCanister.balanceOf(Principal.toText(wicp_id), Principal.fromActor(this));
        usdt_balance := await dswapCanister.balanceOf(Principal.toText(usdt_id), Principal.fromActor(this));
        result := await testWithdraw(wicp_id, wicp_balance);
        result := await testWithdraw(usdt_id, usdt_balance);
        if (result) {pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;

        log_info("- - - - - - - - - - - - - - - - - - ");
        log_info("e): get balance");
        this_wicp_balance  := await wicpCanister.balanceOf(Principal.fromActor(this));
        dswap_wicp_balance := await wicpCanister.balanceOf(Principal.fromActor(dswapCanister));
        this_usdt_balance  := await usdtCanister.balanceOf(Principal.fromActor(this));
        dswap_usdt_balance := await usdtCanister.balanceOf(Principal.fromActor(dswapCanister));
        log_info("testDswap canister wicp balance: " # Nat.toText(this_wicp_balance));
        log_info("testDswap canister usdt balance: " # Nat.toText(this_usdt_balance));
        log_info("dswap canister wicp balance: " # Nat.toText(dswap_wicp_balance));
        log_info("dswap canister usdt balance: " # Nat.toText(dswap_usdt_balance));
        skip_count += 1;
        total_count += 1;
        log_info("- - - - - - - - - - - - - - - - - - ");

        log_info("********************************** ");
        log_info("10. %%%%%% Testing check TxReceipt %%%%%");
        log_info("a): TxReceipt is equal txcounter?");
        result := await dswapCanister.checkTxReceipt();
        if (result) {
            log_info("yes!");
            pass_count += 1;}
        else {
            log_info("! ! ! test fail");
            fail_count += 1;};
        total_count += 1;
        
        log_info("====================================");
        log_info("******  Testing end! ******");
        log_info("******  Test results showed below! ******");
        log_info("Total: " # Nat.toText(total_count) # "  Pass: " # Nat.toText(pass_count) # "  Fail: " # Nat.toText(fail_count) # "  Skip: " # Nat.toText(skip_count));

        return "test finished!"

    };

}
