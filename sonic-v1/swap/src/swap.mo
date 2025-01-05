import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Prelude "mo:base/Prelude";
import Buffer "mo:base/Buffer";
import Utils "./utils";
import Tokens "./tokens";
import Types "./types";
import Cap "./cap/Cap";
import CapV2 "./cap/CapV2";
import IC "./cap/IC";
import Root "./cap/Root";
import Cycles = "mo:base/ExperimentalCycles";
import Nat32 "mo:base/Nat32";
import Blob "mo:base/Blob";
import Hex "./Hex";
import Bool "mo:base/Bool";
import Error "mo:base/Error";
import Account "./Account";

shared(msg) actor class Swap(owner_: Principal, swap_id: Principal,commit_id : Text) = this {   
    type Errors = {
        #InsufficientBalance;
        #InsufficientAllowance;
        #LedgerTrap;
        #AmountTooSmall;
        #BlockUsed;
        #ErrorOperationStyle;
        #ErrorTo;
        #Other:Text;
    };
    type ICRCTransferError = {
        #BadFee : { expected_fee : Nat };
        #BadBurn : { min_burn_amount : Nat };
        #InsufficientFunds : { balance : Nat };
        #InsufficientAllowance : { allowance : Nat };
        #TooOld;
        #CreatedInFuture : { ledger_time : Nat64 };
        #Duplicate : { duplicate_of : Nat };
        #TemporarilyUnavailable;
        #GenericError : { message : Text; error_code : Nat };
        #Expired; //only for approve
        #CustomError:Text; // custom error for sonic logic
    };
    type TokenTxReceipt = {
        #Ok: Nat;
        #Err: Errors;
    };
    type YCTokenTxReceipt = {
        #Ok: Text;
        #Err: Errors;
    };
    type ICRCTokenTxReceipt = {
        #Ok: Nat;
        #Err: ICRCTransferError;
    }; 
    type Metadata = {
        logo : Text;
        name : Text;
        symbol : Text;
        decimals : Nat8;
        totalSupply : Nat;
        owner : Principal;
        fee : Nat;
    };
    type CapDetails={
        CapV1RootBucketId:?Text;
        CapV1Status:Bool;
        CapV2RootBucketId:?Text;
        CapV2Status:Bool
    };
    public type TokenActor = actor {
        allowance: shared (owner: Principal, spender: Principal) -> async Nat;
        approve: shared (spender: Principal, value: Nat) -> async TokenTxReceipt;
        balanceOf: (owner: Principal) -> async Nat;
        decimals: () -> async Nat8;
        name: () -> async Text;
        symbol: () -> async Text;
        getMetadata: () -> async Metadata;
        totalSupply: () -> async Nat;
        transfer: shared (to: Principal, value: Nat) -> async TokenTxReceipt;
        transferFrom: shared (from: Principal, to: Principal, value: Nat) -> async TokenTxReceipt;
    };
    public type YCTokenActor = actor {
        allowance: shared (owner: Principal, spender: Principal) -> async Nat;
        approve: shared (spender: Principal, value: Nat) -> async YCTokenTxReceipt;
        balanceOf: (owner: Principal) -> async Nat;
        decimals: () -> async Nat8;
        name: () -> async Text;
        symbol: () -> async Text;
        getMetadata: () -> async Metadata;
        totalSupply: () -> async Nat;
        transfer: shared (to: Principal, value: Nat) -> async YCTokenTxReceipt;
        transferFrom: shared (from: Principal, to: Principal, value: Nat) -> async YCTokenTxReceipt;
    };
    type ICRCMetaDataValue = { #Nat8 : Nat8;#Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text };
    type Subaccount = Blob;
    type ICRCAccount =  {
        owner : Principal;
        subaccount : ?Subaccount;
    };
    type ICRCTransferArg = {
        from_subaccount :?Subaccount;
        to : ICRCAccount;
        amount : Nat;
    };     
    type ICRC2TransferArg = {
        from :ICRCAccount;
        to : ICRCAccount;
        amount : Nat;
    };    
    public type ICRC1TokenActor = actor {       
        icrc1_balance_of: (account: ICRCAccount) -> async Nat;
        icrc1_decimals: () -> async Nat8;
        icrc1_name: () -> async Text;
        icrc1_symbol: () -> async Text;
        icrc1_metadata: () -> async [(Text, ICRCMetaDataValue)];
        icrc1_total_supply: () -> async Nat;
        icrc1_transfer: shared (ICRCTransferArg) -> async ICRCTokenTxReceipt;
    };
    public type ICRC2TokenActor = actor {
        icrc2_approve: shared (from_subaccount :?Subaccount, spender: Principal, amount : Nat) -> async ICRCTokenTxReceipt;
        icrc2_allowance: shared (account  :Subaccount, spender: Principal) -> async (allowance: Nat, expires_at: ?Nat64);
        icrc1_balance_of: (account: ICRCAccount) -> async Nat;
        icrc1_decimals: () -> async Nat8;
        icrc1_name: () -> async Text;
        icrc1_symbol: () -> async Text;
        icrc1_metadata: () -> async [(Text, ICRCMetaDataValue)];
        icrc1_total_supply: () -> async Nat;
        icrc2_transfer_from : shared (ICRC2TransferArg) -> async ICRCTokenTxReceipt;
        icrc1_transfer: shared (ICRCTransferArg) -> async ICRCTokenTxReceipt;
    };
    type TokenActorVariable = {      
        #DIPtokenActor:TokenActor;
        #YCTokenActor:YCTokenActor;
        #ICRC1TokenActor:ICRC1TokenActor;
        #ICRC2TokenActor:ICRC2TokenActor;
        #Err: Errors;
    };

    public type TxReceipt = Result.Result<Nat, Text>;
    public type ICRC1SubAccountBalance = Result.Result<Nat, Text>;
    public type TransferReceipt = { 
        #Ok: Nat;
        #Err: Errors;
        #ICRCTransferError: ICRCTransferError;
    };
    public type ICRCTxReceipt = { 
        #Ok: [Nat8];
        #Err: Text;
    };

    // id = token0 # : # token1
    public type PairInfo = {
        id: Text;
        token0: Text; //Principal;
        token1: Text; //Principal;
        creator: Principal;
        var reserve0: Nat;
        var reserve1: Nat;
        var price0CumulativeLast: Nat; // time weighted price oracle: https://uniswap.org/blog/uniswap-v2/#price-oracles
        var price1CumulativeLast: Nat;
        var kLast: Nat; // last reserve0 * reserve1
        var blockTimestampLast: Int;
        var totalSupply: Nat; // lp totalsupply
        lptoken: Text;
    };

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

    type Operation = Types.Operation;
    type TxRecord = Types.TxRecord;

    type UserInfo = {
        balances: [(Text, Nat)];
        lpBalances: [(Text, Nat)];
    };

    type UserInfoPage = {
        balances: ([(Text, Nat)], Nat);
        lpBalances: ([(Text, Nat)], Nat);
    };

    type SwapInfo = {
        owner : Principal;
        feeOn : Bool;
        feeTo : Principal;
        cycles : Nat;
        tokens: [TokenInfoExt];
        pairs: [PairInfoExt];
        commitId:Text;
    };

    type SwapInfoExt = {
        depositCounter : Nat;
        txcounter : Nat;
        owner : Principal;
        feeOn : Bool;
        feeTo : Principal;
    };

    type MonitorMetrics = {
        cycles : Nat;
        canisterStatus : IC.CanisterStatus;
        tokenCount : Nat;
        pairsCount : Nat;
        blocklistedUsersCount : Nat;
        lpTokenBalancesSize : Nat;
        lpTokenAllowanceSize : Nat;
        tokenBalancesSize : Nat;
        tokenAllowanceSize : Nat;
        lptokensSize : Nat;
        rewardPairsSize : Nat; 
        rewardTokensSize : Nat;
        rewardInfo : Nat;
        depositTransactionSize : Nat;
    };

    type DepositSubAccounts={
        transactionOwner : Principal;
        depositAId:Text;
        subaccount : Blob;
        created_at:Time.Time;
    };

    type RecoveryDetails = {
        tokenId : Principal;
        amount : Nat;
    };

    type RewardInfo = {
        tokenId: Text;
        amount: Nat;
    };

    type RewardTokens={
        token0 : Text;
        amount0 : Nat;
        token1 : Text;
        amount1 : Nat
    };

    type WithdrawState={
        tokenId:Text;
        userPId:Principal;
        value:Nat;
        refundStatus:Bool
    };

    type WithdrawRefundReceipt = {
        #Ok: Bool;
        #Err: Text;
    };

    type SwapLastTransaction = {
        #SwapOutAmount: Nat;
        #RemoveLiquidityOutAmount: (Nat, Nat);
        #NotFound:Bool;
    };

    type ValidateFunctionReturnType = { 
        #Ok: Text; 
        #Err: Text; 
    };
    
    public type TokenBlockType = Tokens.TokenBlockType;
    public type TokenInfo = Tokens.TokenInfo;
    public type TokenInfoExt = Tokens.TokenInfoExt;
    public type TokenInfoWithType = Tokens.TokenInfoWithType; 
    public type TokenAnalyticsInfo = Tokens.TokenAnalyticsInfo;
    private stable var depositCounter : Nat = 0;
    private stable var txcounter: Nat = 0;
    private stable var capV1Enabled:Bool=true;
    private stable var capV2Enabled:Bool=false;
    private stable var capV2CanisterId:Text="";
    private var cap: Cap.Cap = Cap.Cap(swap_id, 1_000_000_000_000);
    private var capV2: CapV2.Cap = CapV2.Cap(swap_id, capV2CanisterId, 1_000_000_000_000);

    private var lppattern : Text.Pattern = #text ":";
    private stable var maxTokens: Nat = 100; // max number of tokens supported
    private stable var feeOn: Bool = false; // 1/6 of transaction fee(0.3%) goes to feeTo
    private stable var tokenFee: Nat = 10000; // 0.0001 if decimal == 8
    private stable var feeTo: Principal = owner_;
    private stable var owner: Principal = owner_;
    private stable let blackhole: Principal = Principal.fromText("aaaaa-aa");
    private stable let minimum_liquidity: Nat = 10**3;
    private stable let depositCounterV2 : Nat = 10000;
    
    // ic management canister
    let ic: IC.ICActor = actor("aaaaa-aa");

    private var depositTransactions= HashMap.HashMap<Principal, DepositSubAccounts>(1, Principal.equal, Principal.hash);
    private var userFundRecoveries = HashMap.HashMap<Principal, RecoveryDetails>(1, Principal.equal, Principal.hash);
    private var tokenTypes = HashMap.HashMap<Text, Text>(1, Text.equal, Text.hash);
    private var pairs = HashMap.HashMap<Text, PairInfo>(1, Text.equal, Text.hash);
    private var lptokens: Tokens.Tokens = Tokens.Tokens(feeTo, []);
    private var tokens: Tokens.Tokens = Tokens.Tokens(feeTo, []);
    private var rewardPairs = HashMap.HashMap<Text, PairInfo>(1, Text.equal, Text.hash);
    private var rewardTokens=HashMap.HashMap<Text, RewardTokens>(1, Text.equal, Text.hash);
    private var rewardInfo = HashMap.HashMap<Principal, [RewardInfo]>(1, Principal.equal, Principal.hash);
    private var blocklistedUsers = HashMap.HashMap<Principal, Bool>(1, Principal.equal, Principal.hash);   
    private var faileWithdraws = HashMap.HashMap<Text, WithdrawState>(1, Text.equal, Text.hash);   
    private var swapLastTransaction = HashMap.HashMap<Principal, SwapLastTransaction>(1, Principal.equal, Principal.hash);    
    private var tokenBlocklist = HashMap.HashMap<Principal, TokenBlockType>(1, Principal.equal, Principal.hash);
    private var natLabsToken = HashMap.HashMap<Text, Bool>(1, Text.equal, Text.hash);//created this to handle the natlab issue
    private var commitId:Text="";
    private var wicp_xtc_migrationEnabled=false;
    let wicp = "utozz-siaaa-aaaam-qaaxq-cai"; //prod
    let icp = "ryjl3-tyaaa-aaaaa-aaaba-cai";  //prod

    // admins
    private var auths = HashMap.HashMap<Principal, Bool>(1, Principal.equal, Principal.hash);
    auths.put(owner, true);

    private stable var depositTransactionsEntries : [(Principal,DepositSubAccounts)] = [];
    private stable var userFundRecoveriesEntries : [(Principal,RecoveryDetails)] = [];
    private stable var tokenTypeEntries : [(Text,Text)] = [];
    private stable var pairsEntries: [(Text, PairInfo)] = [];
    private stable var lptokensEntries: [(Text, TokenInfoExt, [(Principal, Nat)], [(Principal, [(Principal, Nat)])])] = []; 
    private stable var tokensEntries: [(Text, TokenInfoExt, [(Principal, Nat)], [(Principal, [(Principal, Nat)])])] = []; 
    private stable var authsEntries: [(Principal, Bool)] = [];
    private stable var rewardPairsEntries: [(Text, PairInfo)] = [];
    private stable var rewardTokenEntries : [(Text,RewardTokens)] = [];
    private stable var rewardInfoEntries : [(Principal,[RewardInfo])] = [];
    private stable var blocklistedUserEntries: [(Principal, Bool)] = [];
    private stable var faileWithdrawEntries: [(Text, WithdrawState)] = [];
    private stable var tokenBlocklistEntries: [(Principal, TokenBlockType)] = [];
    private stable var natLabsTokenEntries:[(Text,Bool)] = [];

    // variables not used : added for future use
    private stable var daoCanisterIdForLiquidity : Text = "";
    private stable var permissionless: Bool = false;

    private func updateCommitId(commit_Id:Text){
        commitId:=commit_Id;
    };
    updateCommitId(commit_id);

    private func addRecord(
        caller: Principal, 
        op: Text, 
        details: [(Text, Root.DetailValue)]
        ): async () {
        let record: Root.IndefiniteEvent = {
            operation = op;
            details = details;
            caller = caller;
        };
        // don't wait for result, faster
        if(capV1Enabled){ 
            ignore cap.insert(record);
        };
        // if(capV2Enabled){ 
        //     ignore capV2.insert(record);
        // }
    };

    private func addRecord_without_ignore(
        caller: Principal, 
        op: Text, 
        details: [(Text, Root.DetailValue)]
        ): async ()  {
        let record: Root.IndefiniteEvent = {
            operation = op;
            details = details;
            caller = caller;
        };
        // don't wait for result, faster
        if(capV1Enabled){ 
            var data=await cap.insert(record);
        };
        // if(capV2Enabled){ 
        //     var data2=await capV2.insert(record);
        // }
    };

    /*
    * constants management functions
    */
    private func _checkAuth(id: Principal): Bool {
        switch(auths.get(id)) {
            case(?v) { return v; };
            case(_) { return false; };
        };
    };

    private func _checkBlocklist(id: Principal): Bool {
        switch(blocklistedUsers.get(id)) {
            case(?v) { return v; };
            case(_) { return false; };
        };
    };

    private func u64(i: Nat): Nat64 {
        Nat64.fromNat(i)
    };
    private func u64ToText(value :Nat) : Text{
        return Nat.toText(value);
    };
    //--------token actor------------
    private func _getTokenActorWithType(tokenId: Text, tokenType: Text): TokenActorVariable{
        switch(tokenType){
            case("DIP20"){
                var tokenCanister : TokenActor = actor(tokenId);
                return #DIPtokenActor(tokenCanister);
            };
            case("YC"){
                var tokenCanister : YCTokenActor = actor(tokenId);                          
                return #YCTokenActor(tokenCanister);
            };
            case("ICRC1"){
                var tokenCanister : ICRC1TokenActor = actor(tokenId);                          
                return #ICRC1TokenActor(tokenCanister);
            };
            case("ICRC2"){
                var tokenCanister : ICRC2TokenActor = actor(tokenId);                          
                return #ICRC2TokenActor(tokenCanister);
            };
            case(_){
                Prelude.unreachable();
            };
        };
    };
    private func _getTokenActor(tokenId: Text): TokenActorVariable{
        switch(tokenTypes.get(tokenId)) {
            case(?tokenType) {
                switch(tokenType){
                    case("DIP20"){
                        var tokenCanister : TokenActor = actor(tokenId);
                        return #DIPtokenActor(tokenCanister);
                    };
                    case("YC"){
                        var tokenCanister : YCTokenActor = actor(tokenId);                          
                        return #YCTokenActor(tokenCanister);
                    };
                    case("ICRC1"){
                        var tokenCanister : ICRC1TokenActor = actor(tokenId);                          
                        return #ICRC1TokenActor(tokenCanister);
                    };
                    case("ICRC2"){
                        var tokenCanister : ICRC2TokenActor = actor(tokenId);                          
                        return #ICRC2TokenActor(tokenCanister);
                    };
                    case(_){
                        Prelude.unreachable()
                    };
                };
            };
            case(_) { //by default type is DIP20 
                var tokenCanister : TokenActor = actor(tokenId);
                return #DIPtokenActor(tokenCanister);
            };
        };
    };
    private func _transferFrom(tid: Text, tokenCanister: TokenActorVariable, caller:Principal, value: Nat, fee: Nat) :async TransferReceipt{               
        switch(tokenCanister){
            case(#DIPtokenActor(dipTokenActor)){                
                var txid = await dipTokenActor.transferFrom(caller, Principal.fromActor(this), value);
                switch (txid){
                    case(#Ok(id)) { return #Ok(id); };
                    case(#Err(e)) { return #Err(e); };
                }
            };
            case(#YCTokenActor(ycTokenActor)){
                var txid = await ycTokenActor.transferFrom(caller, Principal.fromActor(this), value); 
                switch (txid){
                    case(#Ok(id)) { return #Ok(textToNat(id)); };
                    case(#Err(e)) { return #Err(e); };
                }
            };
            case(#ICRC1TokenActor(icrc1TokenActor)){

                let subaccount = getICRC1SubAccount(caller);
                var depositSubAccount:ICRCAccount={owner=Principal.fromActor(this); subaccount=?subaccount};
                var balance=await icrc1TokenActor.icrc1_balance_of(depositSubAccount);
                var depositBalance: Nat=switch(natLabsToken.get(tid)){
                    case(?data){ value + fee };
                    case(_){ value }
                };
                if(balance>=value+fee)
                {
                    var defaultSubaccount:Blob=Utils.defaultSubAccount();
                    var transferArg:ICRCTransferArg=
                    {
                        from_subaccount=?subaccount;
                        to={ owner=Principal.fromActor(this); subaccount=?defaultSubaccount };
                        amount=depositBalance;
                    };
                    var txid = await icrc1TokenActor.icrc1_transfer(transferArg);
                    switch (txid){
                        case(#Ok(id)){ return #Ok(id); };                 
                        case(#Err(e)){ return #ICRCTransferError(e); };
                    }
                }
                else{
                    return #ICRCTransferError(#CustomError("transaction amount not matched"));
                };
            };
            case(#ICRC2TokenActor(icrc2TokenActor)){
               var transferArg=
                {
                    from={ owner=caller; subaccount=null}; 
                    to={ owner=Principal.fromActor(this); subaccount=null};
                    amount=value;
                };
                var txid = await icrc2TokenActor.icrc2_transfer_from(transferArg); 
                switch (txid){
                    case(#Ok(id)){ return #Ok(id); };                 
                    case(#Err(e)){ return #ICRCTransferError(e); };
                }                           
            };
            case(_){
                Prelude.unreachable()
            };
        }
    };
    private func _transfer(tokenCanister: TokenActorVariable, caller:Principal, value: Nat) :async TransferReceipt{
        switch(tokenCanister){
            case(#DIPtokenActor(dipTokenActor)){
                var txid = await dipTokenActor.transfer(caller, value);
                switch (txid){
                    case(#Ok(id)) { return #Ok(id); };
                    case(#Err(e)) { return #Err(e); };
                }
            };
            case(#YCTokenActor(ycTokenActor)){
                var txid = await ycTokenActor.transfer(caller, value); 
                switch (txid){
                    case(#Ok(id)) { return #Ok(textToNat(id)); };
                    case(#Err(e)) { return #Err(e); };
                }
            };
            case(#ICRC1TokenActor(icrc1TokenActor)){
                var defaultSubaccount:Blob=Utils.defaultSubAccount();
                var transferArg:ICRCTransferArg=
                {
                    from_subaccount=?defaultSubaccount;
                    to={ owner=caller; subaccount=?defaultSubaccount};
                    amount=value;
                };
                var txid = await icrc1TokenActor.icrc1_transfer(transferArg); 
                switch (txid){
                    case(#Ok(id)) { return #Ok(id); };
                    case(#Err(e)) { return #ICRCTransferError(e); };
                }
            };
            case(#ICRC2TokenActor(icrc2TokenActor)){
                var defaultSubaccount:Blob=Utils.defaultSubAccount();
                var transferArg:ICRCTransferArg=
                {
                    from_subaccount=?defaultSubaccount;
                    to={ owner=caller; subaccount=?defaultSubaccount};
                    amount=value;
                };
                var txid = await icrc2TokenActor.icrc1_transfer(transferArg); 
                switch (txid){
                    case(#Ok(id)) { return #Ok(id); };
                    case(#Err(e)) { return #ICRCTransferError(e); };
                }
            };
            case(_){
                Prelude.unreachable()
            };
        }
    };
    private func _balanceOf(tokenCanister: TokenActorVariable, caller:Principal) :async Nat{               
        switch(tokenCanister){
            case(#DIPtokenActor(dipTokenActor)){                
                return await dipTokenActor.balanceOf(caller);
            };
            case(#YCTokenActor(ycTokenActor)){
                return await ycTokenActor.balanceOf(caller); 
            };
            case(#ICRC1TokenActor(icrc1TokenActor)){
                let subaccount = getICRC1SubAccount(caller);
                var depositSubAccount:ICRCAccount={owner=Principal.fromActor(this); subaccount=?subaccount};
                return await icrc1TokenActor.icrc1_balance_of(depositSubAccount);
            };
            case(_){
                Prelude.unreachable()
            };
        }
    };  
    private func textToNat( txt : Text) : Nat {
        let lash=Text.hash(txt);
        return Nat32.toNat(lash);
    };
    private func _getMetadata(tokenCanister: TokenActorVariable, tokenId: Principal) :async Metadata{
        switch(tokenCanister){
            case(#DIPtokenActor(dipTokenActor)){
                var metadata = await dipTokenActor.getMetadata();
                return metadata;
            };
            case(#YCTokenActor(ycTokenActor)){
                var metadata = await ycTokenActor.getMetadata();
                return metadata;
            };
            case(#ICRC1TokenActor(icrc1TokenActor)){
                var icrc1_metadata = await icrc1TokenActor.icrc1_metadata(); 
                var totalSupply = await icrc1TokenActor.icrc1_total_supply();                            
                var metadata=_extractICRCMetadata(tokenId, icrc1_metadata, totalSupply);
                return metadata;
            };
            case(#ICRC2TokenActor(icrc2TokenActor)){
                var icrc2_metadata = await icrc2TokenActor.icrc1_metadata();
                var totalSupply = await icrc2TokenActor.icrc1_total_supply();                             
                var metadata=_extractICRCMetadata(tokenId, icrc2_metadata, totalSupply);
                return metadata;
            };
            case(_){
                Prelude.unreachable()
            };
        }
    };
    private func _extractICRCMetadata(tokenId: Principal, metadatas :[(Text, ICRCMetaDataValue)], totalSupply:Nat ): Metadata{
        var name:Text="";
        var symbol:Text="";
        var fee:Nat=0;
        var decimals:Nat=0;        
        for(metadata in metadatas.vals())
        {
            switch(metadata.0){
                case("icrc1:name"){
                    switch(metadata.1){
                        case(#Text(data)){
                            name:=data;
                        };
                        case(_){};
                    };                          
                };
                case("icrc1:symbol"){
                    switch(metadata.1){
                        case(#Text(data)){
                            symbol:=data;
                        };
                        case(_){};
                    };                          
                };
                case("icrc1:decimals"){
                    switch(metadata.1){
                        case(#Nat(data)){
                            decimals:=data;
                        };
                        case(_){};
                    };                          
                };
                case("icrc1:fee"){
                    switch(metadata.1){
                        case(#Nat(data)){
                            fee:=data;
                        };
                        case(_){};
                    };                          
                };               
                case(_){};
            };
        };         
        var resultMeta:Metadata={
            logo="";
            name=name;
            symbol=symbol;
            decimals=Nat8.fromNat(decimals);
            totalSupply=totalSupply;
            owner=tokenId;
            fee=fee;
        };
        return resultMeta;
    };
    private func _getSymbol(tokenCanister: TokenActorVariable) :async Text{
        switch(tokenCanister){
            case(#DIPtokenActor(dipTokenActor)){
                var symbol = await dipTokenActor.symbol();
                return symbol;
            };
            case(#YCTokenActor(ycTokenActor)){
                var symbol = await ycTokenActor.symbol();
                return symbol;
            };
            case(#ICRC1TokenActor(icrc1TokenActor)){
                var symbol = await icrc1TokenActor.icrc1_symbol();
                return symbol;
            };
            case(#ICRC2TokenActor(icrc2TokenActor)){
                var symbol = await icrc2TokenActor.icrc1_symbol();
                return symbol;
            };
            case(_){
                Prelude.unreachable()
            };
        }
    };
    //-------------------------------

    public shared(msg) func addNatLabsToken(tokenId : Text) : async Bool{
        assert(_checkAuth(msg.caller));
        natLabsToken.put(tokenId,true);
        return true;
    };

    public shared(msg) func removeNatLabsToken(tokenId : Text) : async Bool{
        assert(_checkAuth(msg.caller));
        natLabsToken.delete(tokenId);
        return true;
    };

    public shared(msg) func getNatLabsToken():async [(Text,Bool)]{
        return Iter.toArray(natLabsToken.entries());
    };

    public shared(msg) func getBlockedTokens(): async [(Principal,TokenBlockType)] {
        return Iter.toArray(tokenBlocklist.entries());
    };

    public shared(msg) func addTokenToBlocklistValidate(tokenId: Principal, blockType:TokenBlockType) : async ValidateFunctionReturnType {        
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #Ok("token not exist");
        switch(blockType){
            case(#Full(d)){};
            case(#Partial(d)){};
            case(_){
                return #Err("invaild block type");
            };
        };        
        return #Ok("addTokenToBlocklist Validated");
    };
    
    public shared(msg) func addTokenToBlocklist(tokenId: Principal, blockType:TokenBlockType): async Bool {
        assert(_checkAuth(msg.caller));
        tokenBlocklist.put(tokenId, blockType);
        return true;
    };

    public shared(msg) func removeTokenFromBlocklistValidate(tokenId: Principal) : async ValidateFunctionReturnType {        
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #Ok("token not exist");
        return #Ok("removeTokenFromBlocklist Validated");
    };

    public shared(msg) func removeTokenFromBlocklist(tokenId: Principal): async Bool {
        assert(_checkAuth(msg.caller));
        tokenBlocklist.delete(tokenId);
        return true;
    };

    public shared(msg) func getBlocklistedUsers(): async [(Principal,Bool)] {
        assert(_checkAuth(msg.caller));
        return Iter.toArray(blocklistedUsers.entries());
    };
    
    public shared(msg) func addUserToBlocklist(user: Principal): async Bool {
        assert(_checkAuth(msg.caller));
        blocklistedUsers.put(user, true);
        return true;
    };

    public shared(msg) func removeUserFromBlocklist(user: Principal): async Bool {
        assert(_checkAuth(msg.caller));
        blocklistedUsers.delete(user);
        return true;
    };

    public query func getCapDetails(): async CapDetails {
        return ({
            CapV1RootBucketId=cap.getRootBucketId();
            CapV1Status=capV1Enabled;
            CapV2RootBucketId=capV2.getRootBucketId();
            CapV2Status=capV2Enabled;
        });
    };

    public shared(msg) func setCapV2CanisterId(canisterId: Text): async Bool {
        assert(msg.caller == owner);
        capV2CanisterId:=canisterId;
        return capV2.setRouterId(canisterId);
    };

    public shared(msg) func setCapV1EnableStatus(status: Bool): async Bool {
        assert(msg.caller == owner);
        capV1Enabled:=status;
        return true;
    };

    public shared(msg) func setCapV2EnableStatus(status: Bool): async  Result.Result<Bool, Text> {
        assert(msg.caller == owner);
        if(capV2.getRouterId()!=""){
            capV2Enabled:=status;
            return #ok(true);
        }
        else{
            return #err("capV2CanisterId is empty")
        }
    };
    
    public shared(msg) func addAuth(id: Principal): async Bool {
        assert(msg.caller == owner);
        auths.put(id, true);
        return true;
    };

    public shared(msg) func removeAuth(id: Principal): async Bool {
        assert(msg.caller == owner);
        auths.delete(id);
        return true;
    };

    public shared(msg) func setOwner(newOwner: Principal): async Bool {
        assert(msg.caller == owner);
        owner := newOwner;
        return true;
    };

    public shared(msg) func setMaxTokenValidate(newValue: Nat): async ValidateFunctionReturnType {
        if(newValue <= 1000){
            return #Ok("MaxToken updated to :"#Nat.toText(newValue));
        };
        return #Err("invaild maxtoken range");        
    };

    public shared(msg) func setMaxTokens(newValue: Nat): async Bool {
        assert(msg.caller == owner);
        maxTokens := newValue;
        return true;
    };

    public shared(msg) func setFeeOn(newValue: Bool): async Bool {
        assert(msg.caller == owner);
        feeOn := newValue;
        return true;
    };

    public shared(msg) func setFeeTo(newTo: Principal): async Bool {
        assert(msg.caller == owner);
        feeTo := newTo;
        return true;
    };

    public shared(msg) func setGlobalTokenFee(newFee: Nat): async Bool {
        assert(msg.caller == owner);
        tokenFee := newFee;
        return true;
    };

    public shared(msg) func setFeeForToken(tokenId: Text, newFee: Nat): async Bool {
        assert(msg.caller == owner);
        if(Text.contains(tokenId, lppattern)) {
            return lptokens.setFee(tokenId, newFee);
        } else {
            return tokens.setFee(tokenId, newFee);
        };
    };

    public shared(msg) func updateTokenMetadata(tokenId: Text): async Bool {
        assert(msg.caller == owner);
        if (tokens.hasToken(tokenId) == false) {
            return false;
        };
        let tokenCanister = _getTokenActor(tokenId);
        let metadata = await _getMetadata(tokenCanister, Principal.fromText(tokenId));
        tokens.setMetadata(tokenId, metadata.name, metadata.symbol, metadata.decimals, metadata.fee)
    };

    public shared(msg) func updateAllTokenMetadata(): async Bool {
        assert(msg.caller == owner);
        for((tokenId, info) in Iter.fromArray(tokens.getTokenInfoList())) {
            let tokenCanister = _getTokenActor(tokenId);
            let metadata = await _getMetadata(tokenCanister, Principal.fromText(tokenId));
            ignore tokens.setMetadata(tokenId, metadata.name, metadata.symbol, metadata.decimals, metadata.fee);
        };
        return true;
    };

    // update token transfer fees, 
    // e.g. tokenA's transfer fee is 1 when added to sonic, in sonic's record the fee is 1,
    // later tokenA's transfer fee is changed to 2, if sonic is not up to date, will cause
    // sonic to lose money when users withdraw tokenA from sonic
    public shared(msg) func updateTokenFees(): async Bool {
        assert(msg.caller == owner);
        for((tokenId, info) in Iter.fromArray(tokens.getTokenInfoList())) {
            let t = _getTokenActor(tokenId);
            let metadata = await _getMetadata(t, Principal.fromText(tokenId));
            ignore tokens.setFee(tokenId, metadata.fee);
        };
        return true;
    };

    // FOR TEST ONLY, DO NOT REMOVE TOKEN IN PRODUCTION AS THIS WILL RESULT IN FUND LOSS
    // public shared(msg) func removeToken(tokenId: Text): async Bool {
    //     assert(_checkAuth(msg.caller));
    //     tokens.removeToken(tokenId)
    // };

    /*
    * private helper functions
    */
    private func _getlpTokenId(token0: Text, token1: Text) : Text {
        let (t0, t1) = Utils.sortTokens(token0, token1);
        let pair_str = t0 # ":" # t1;
        return pair_str;
    };

    private func _getPair(token0: Text, token1: Text) : ?PairInfo {
        let tid = _getlpTokenId(token0, token1);
        return pairs.get(tid);
    };

    private func _getRewardPair(token0: Text, token1: Text) : ?PairInfo {
        let tid = _getlpTokenId(token0, token1);
        return rewardPairs.get(tid);
    };

    private func _getlpToken(token0: Text, token1: Text): ?TokenInfo {
        let tid = _getlpTokenId(token0, token1);
        lptokens.getTokenInfo(tid)
    };

    private func _pairToExternal(p: PairInfo) : PairInfoExt {
        let temp : PairInfoExt = {
            id = p.id;
            token0 = p.token0;
            token1 = p.token1;
            creator = p.creator;
            reserve0 = p.reserve0;
            reserve1 = p.reserve1;
            price0CumulativeLast = p.price0CumulativeLast;
            price1CumulativeLast = p.price1CumulativeLast;
            kLast = p.kLast;
            blockTimestampLast = p.blockTimestampLast;
            totalSupply = p.totalSupply;
            lptoken = p.lptoken;
        };
        temp
    };
    
    // create/update pair
    private func _putPair(token0: Text, token1: Text, info: PairInfo) : Bool {
        let tid = _getlpTokenId(token0, token1);
        pairs.put(tid, info);
        return true;
    };

    /*
    * token related functions: addToken
    */
    private func createTokenType(tokenId: Principal, tokenType: Text) {
        let tid : Text = Principal.toText(tokenId);
        if (Option.isNull(tokenTypes.get(tid)) == true) {
            tokenTypes.put(tid, tokenType);
        };
    };

    /*
    * checks for users' ICRC1 Tokens deposited in temporary addresses
    * Useful for platform admins to verify balance
    */
    public shared(msg) func getICRC1SubAccountBalance(user:Principal, tid: Text) : async ICRC1SubAccountBalance{
       assert(_checkAuth(msg.caller));
       let tokenCanister = _getTokenActor(tid);
       switch(tokenCanister)
       {            
            case(#ICRC1TokenActor(icrc1TokenActor))
            {
                let subaccount = getICRC1SubAccount(user);
                var depositSubAccount:ICRCAccount={owner=Principal.fromActor(this); subaccount=?subaccount};
                let balance = await icrc1TokenActor.icrc1_balance_of(depositSubAccount);
                return #ok(balance);
            };            
            case(_){
                return #err("tid/tokenid passed is not a supported ICRC1 canister");
            };
        };
    };

    public shared(msg) func addTokenValidate(tokenId: Principal, tokenType: Text) : async ValidateFunctionReturnType {        
        if ((msg.caller == owner) == false) {
            return #Err("unauthorized");
        };
        switch(tokenType){
            case("DIP20"){};
            case("YC"){};
            case("ICRC1"){};
            case("ICRC2"){};
            case(_){
                return #Err("invaild token type");
            };
        };        
        return #Ok("tokenId :"#Principal.toText(tokenId)#" \r\n tokenType:"#tokenType);
    };

    public shared(msg) func addToken(tokenId: Principal, tokenType: Text) : async TxReceipt {
        if ((msg.caller == owner) == false) {
            return #err("unauthorized");
        };
        if (tokens.getNumTokens() == maxTokens)
            return #err("max number of tokens reached");
        if (tokens.hasToken(Principal.toText(tokenId)))
            return #err("token exists");

        let tokenCanister = _getTokenActorWithType(Principal.toText(tokenId),tokenType);
        let metadata = await _getMetadata(tokenCanister, tokenId);
        
        let token : TokenInfo = {
            id = Principal.toText(tokenId);
            var name = metadata.name;
            var symbol = metadata.symbol;
            var decimals = metadata.decimals;
            var fee = metadata.fee;
            var totalSupply = 0;
            balances = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
            allowances = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>(1, Principal.equal, Principal.hash);
        };
        assert(tokens.createToken(Principal.toText(tokenId), token));
        createTokenType(tokenId, tokenType);
        ignore addRecord(
            msg.caller, "addToken", [("tokenId", #Text(Principal.toText(tokenId)))]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func updateTokenTypeValidate(tokenId: Principal, tokenType: Text) : async ValidateFunctionReturnType {        
        if ((msg.caller == owner) == false) {
            return #Err("unauthorized");
        };
        switch(tokenType){
            case("DIP20"){};
            case("YC"){};
            case("ICRC1"){};
            case("ICRC2"){};
            case(_){
                return #Err("invaild token type");
            };
        };        
        return #Ok("tokenId :"#Principal.toText(tokenId)#" \r\n tokenType:"#tokenType);
    };

    public shared(msg) func updateTokenType(tokenId: Principal, tokenType: Text) : async Bool{
        if ((msg.caller == owner) == false) {
            return false;
        };
        let tid : Text = Principal.toText(tokenId);
        switch(tokenType){
            case("DIP20"){};
            case("ICRC1"){};
            case("ICRC2"){};
            case(_){
                return false;
            };
        };
        if (Option.isNull(tokenTypes.get(tid)) == false) {
            tokenTypes.put(tid, tokenType);
            return true;
        };
        return false;
    };

    private func effectiveDepositAmount(tokenId : Text, value : Nat) : Nat {
        switch(tokenTypes.get(tokenId)) {
            case(?tokenType) {
                switch(tokenType){
                    case("YC"){
                        return ((value * 89000)/100000); // 11% tax cut
                    };
                    case(_){};
                };
            };
            case(_){};
        };
        return value;
    };

    private func getICRC1SubAccount(caller: Principal): Blob {
        switch(depositTransactions.get(caller))
        {
            case(?deposit){                
                return deposit.subaccount;
            };
            case(_){
                let subaccount = Utils.generateSubaccount({
                    caller = caller;
                    id = depositCounterV2;
                });
                return subaccount;
            };
        };
    };

    public shared(msg) func initiateICRC1Transfer() : async [Nat8] {
        return Blob.toArray(getICRC1SubAccount(msg.caller));
    };

    public shared(msg) func initiateICRC1TransferForUser(userPId: Principal) : async ICRCTxReceipt{
        if (_checkAuth(msg.caller) == false) {
                return #Err("unauthorized");
        };
        return #Ok(Blob.toArray(getICRC1SubAccount(userPId)));
    };   

    public shared(msg) func deposit(tokenId: Principal, value: Nat) : async TxReceipt {
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");

        ignore addRecord(
            msg.caller, "deposit-init", 
            [
                ("tokenId", #Text(tid)),
                ("from", #Principal(msg.caller)),
                ("to", #Principal(msg.caller)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        switch(getTokenBlockStatus(tokenId)){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(tokenId));     
            }
        };

        let tokenCanister = _getTokenActor(tid);
        let result = await _transferFrom(tid, tokenCanister, msg.caller, value, tokens.getFee(tid));
        let txid = switch (result) {
            case(#Ok(id)) { id; };
            case(#Err(e)) { return #err("token transfer failed:" # tid); };
            case(#ICRCTransferError(e)) { return #err("token transfer failed:" # tid); };
        };
        if (value < tokens.getFee(tid))
            return #err("value less than token transfer fee");
        ignore tokens.mint(tid, msg.caller, effectiveDepositAmount(tid, value));
        ignore addRecord(
            msg.caller, "deposit", 
            [
                ("tokenId", #Text(tid)),
                ("tokenTxid", #Text(u64ToText(txid))),
                ("from", #Principal(msg.caller)),
                ("to", #Principal(msg.caller)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(0))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func depositTo(tokenId: Principal, to: Principal, value: Nat) : async TxReceipt {
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");

        ignore addRecord(
            msg.caller, "depositTo-init", 
            [
                ("tokenId", #Text(tid)),
                ("from", #Principal(msg.caller)),
                ("to", #Principal(to)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, to)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        switch(getTokenBlockStatus(tokenId)){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(tokenId));     
            }
        };

        let tokenCanister = _getTokenActor(tid);
        let txid = switch(await _transferFrom(tid, tokenCanister, msg.caller, value, tokens.getFee(tid))) {
            case(#Ok(id)) { id };
            case(#Err(e)) { return #err("token transfer failed:" # tid); };
            case(#ICRCTransferError(e)) { return #err("token transfer failed:" # tid); };
        };
        if (value < tokens.getFee(tid))
            return #err("value less than token transfer fee");
        ignore tokens.mint(tid, to, effectiveDepositAmount(tid, value));
        ignore addRecord(
            msg.caller, "deposit", 
            [
                ("tokenId", #Text(tid)),
                ("tokenTxid", #Text(u64ToText(txid))),
                ("from", #Principal(msg.caller)),
                ("to", #Principal(to)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(0))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, to)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func retryDeposit(tokenId: Principal) : async TxReceipt {        
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");

        var tokenActor : ICRC1TokenActor = actor(tid);                          
        var tokenCanister : TokenActorVariable = #ICRC1TokenActor(tokenActor);  
        var balance = await _balanceOf(tokenCanister, msg.caller);
        let tokenFee = tokens.getFee(tid);
        var value : Nat = if(Nat.greater(balance,tokenFee)){
            balance - tokenFee;
        } else{
            balance;
        };
        ignore addRecord(
            msg.caller, "retrydeposit-init", 
            [
                ("tokenId", #Text(tid)),
                ("from", #Principal(msg.caller)),
                ("to", #Principal(msg.caller)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        switch(getTokenBlockStatus(tokenId)){            
            case(#None(id)) { };
            case(#Partial(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(tokenId));     
            }
        };

        if(Nat.equal(value,0)){
            return #err("no pending deposit found");
        };
        if (value < tokens.getFee(tid)) {
            return #err("value less than token transfer fee");
        };
        let txid = switch(await _transferFrom(tid, tokenCanister, msg.caller, value, tokens.getFee(tid))) {
            case(#Ok(id)) { id };
            case(#Err(e)) { return #err("token transfer failed:" # tid); };
            case(#ICRCTransferError(e)) { return #err("token transfer failed:" # tid); };
        };
        ignore tokens.mint(tid, msg.caller, effectiveDepositAmount(tid, value));
        ignore addRecord(
            msg.caller, "deposit", 
            [
                ("tokenId", #Text(tid)),
                ("tokenTxid", #Text(u64ToText(txid))),
                ("from", #Principal(msg.caller)),
                ("to", #Principal(msg.caller)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(0))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func retryDepositTo(tokenId: Principal, to: Principal, value: Nat) : async TxReceipt {
        if (_checkAuth(msg.caller) == false) {
          return #err("unauthorized");
        };
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");
        
        switch(getTokenBlockStatus(tokenId)){            
            case(#None(id)) { };
            case(#Partial(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(tokenId));     
            }
        };

        var tokenActor : ICRC1TokenActor = actor(tid);                          
        var tokenCanister : TokenActorVariable = #ICRC1TokenActor(tokenActor);
        let txid = switch(await _transferFrom(tid, tokenCanister, to, value, tokens.getFee(tid))) {
            case(#Ok(id)) { id };
            case(#Err(e)) { return #err("token transfer failed:" # tid); };
            case(#ICRCTransferError(e)) { return #err("token transfer failed:" # tid); };
        };
        ignore addRecord(
            msg.caller, "retrydepositTo-init", 
            [
                ("tokenId", #Text(tid)),
                ("from", #Principal(to)),
                ("to", #Principal(to)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, to)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        if (value < tokens.getFee(tid))
            return #err("value less than token transfer fee");
        ignore tokens.mint(tid, to, effectiveDepositAmount(tid, value));
        ignore addRecord(
            to, "deposit", 
            [
                ("tokenId", #Text(tid)),
                ("tokenTxid", #Text(u64ToText(txid))),
                ("from", #Principal(to)),
                ("to", #Principal(to)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(0))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, to)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    private func depositForUser(userPId:Principal, tokenId: Principal) : async TxReceipt {
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");

        switch(getTokenBlockStatus(tokenId)){            
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(tokenId));     
            }
        };

        let tokenCanister = _getTokenActor(tid);
        let balance = await _balanceOf(tokenCanister, userPId);
        let tokenFee = tokens.getFee(tid);
        let result = await _transferFrom(tid, tokenCanister, userPId, (balance - tokenFee), tokenFee);
        let txid = switch (result) {
            case(#Ok(id)) { id; };
            case(#Err(e)) { return #err("token transfer failed:" # tid); };
            case(#ICRCTransferError(e)) { return #err("token transfer failed:" # tid); };
        };
        if (balance < tokens.getFee(tid))
            return #err("value less than token transfer fee");
        ignore tokens.mint(tid, userPId, effectiveDepositAmount(tid, balance));
        ignore addRecord(
            userPId, "deposit", 
            [
                ("tokenId", #Text(tid)),
                ("tokenTxid", #Text(u64ToText(txid))),
                ("from", #Principal(userPId)),
                ("to", #Principal(userPId)),
                ("amount", #Text(u64ToText(balance))),
                ("fee", #Text(u64ToText(0))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, userPId)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func withdraw(tokenId: Principal, value: Nat) : async TxReceipt {
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");
        ignore addRecord(
            msg.caller, "withdraw-init", 
            [
                ("tokenId", #Text(tid)),
                ("from", #Principal(msg.caller)),
                ("to", #Principal(msg.caller)),
                ("amount", #Text(u64ToText(value))),
                ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        switch(getTokenBlockStatus(tokenId)){            
            case(#None(id)) { };
            case(#Partial(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(tokenId));     
            }
        };
        
        if (tokens.burn(tid, msg.caller, value)) {
            let tokenCanister = _getTokenActor(tid);
            let fee = tokens.getFee(tid);
            var txid: Nat = 0;
            try {
                var withdrawBalance: Nat=switch(natLabsToken.get(tid)) {
                    case(?data){ value };
                    case(_){ value - fee }
                };
                switch(await _transfer(tokenCanister, msg.caller, withdrawBalance)) {
                    case(#Ok(id)) { txid := id; };
                    case(#Err(e)) {
                        // ignore tokens.mint(tid, msg.caller, value);
                        var ledger_error = switch(e) {
                            case(#Other(errMsg)){
                                if(tid == "utozz-siaaa-aaaam-qaaxq-cai" 
                                    or tid == "lzvjb-wyaaa-aaaam-qarua-cai" 
                                    or tid == "djjfs-tyaaa-aaaak-qagtq-cai" )
                                {
                                    true
                                } else {
                                    false
                                };
                            };
                            case(_){false};
                        };
                        if(not ledger_error){
                            ignore tokens.mint(tid, msg.caller, value);
                        } else {
                            addFailedWithdraws(tid, msg.caller, value);
                            ignore addRecord(
                                msg.caller, "withdraw-failed", 
                                [
                                    ("tokenId", #Text(tid)),
                                    ("from", #Principal(msg.caller)),
                                    ("to", #Principal(msg.caller)),
                                    ("amount", #Text(u64ToText(value))),
                                    ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                                    ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                                    ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid)))),
                                    ("Error", #Text(debug_show(e))),
                                ]
                            );
                        };
                        return #err("token transfer failed:" # tid);
                    };
                    case(#ICRCTransferError(e)) {
                        ignore tokens.mint(tid, msg.caller, value);
                        return #err("token transfer failed:" # tid);
                    };
                };
            } catch (e) {
                // ignore tokens.mint(tid, msg.caller, value);
                addFailedWithdraws(tid, msg.caller, value);
                ignore addRecord(
                    msg.caller, "withdraw-failed", 
                    [
                        ("tokenId", #Text(tid)),
                        ("from", #Principal(msg.caller)),
                        ("to", #Principal(msg.caller)),
                        ("amount", #Text(u64ToText(value))),
                        ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                        ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                        ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid)))),
                        ("Error", #Text(Error.message(e))),
                    ]
                );
                return #err("token transfer failed:" # tid);
            };
            ignore addRecord(
                msg.caller, "withdraw", 
                [
                    ("tokenId", #Text(tid)),
                    ("tokenTxid", #Text(u64ToText(txid))),
                    ("from", #Principal(msg.caller)),
                    ("to", #Principal(msg.caller)),
                    ("amount", #Text(u64ToText(value))),
                    ("fee", #Text(u64ToText(fee))),
                    ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                    ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
                ]
            );
            txcounter += 1;
            return #ok(txcounter - 1);
        } else {
            return #err("burn token failed:" # tid);
        };
    };
    private func addFailedWithdraws(tokenId:Text, userPId:Principal, value:Nat){
        faileWithdraws.put(Int.toText(Time.now()),{
            tokenId=tokenId; 
            userPId=userPId; 
            value=value; 
            refundStatus=false
        });
    };
    
    public shared(msg) func withdrawTo(tokenId: Principal, from: Principal) : async TxReceipt {
        // assert(_checkAuth(msg.caller));
        let tid: Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");
        ignore addRecord(
            from, "withdrawTo-init", 
            [
                ("tokenId", #Text(tid)),
                ("from", #Principal(from)),
                ("to", #Principal(msg.caller)),
                ("fee", #Text(u64ToText(tokens.getFee(tid)))),
                ("balance", #Text(u64ToText(tokens.balanceOf(tid,from)))),
                ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
            ]
        );
        let token_amount=tokens.allowance(Principal.toText(tokenId), from, msg.caller);
        let burnTokenId= getWIPCfromICP(tid);
        if (token_amount== 0)
            return #err("token allowance not found");
        if (tokens.burn(burnTokenId, from, token_amount)) {
            let tokenCanister = _getTokenActor(tid);
            let fee = tokens.getFee(tid);
            var txid: Nat = 0;
            try {
                switch(await _transfer(tokenCanister, msg.caller, token_amount - fee)) {
                    case(#Ok(id)) { 
                        txid := id; 
                        var _removeStatus=tokens.removeAllowances(Principal.toText(tokenId), from, msg.caller, token_amount);
                    };
                    case(#Err(e)) {
                        ignore tokens.mint(tid, from, token_amount);
                        return #err("token transfer failed:" # tid);
                    };
                    case(#ICRCTransferError(e)) {
                        ignore tokens.mint(tid, from, token_amount);
                        return #err("token transfer failed:" # tid);
                    };
                }
            } catch (e) {
                ignore tokens.mint(tid, from, token_amount);
                return #err("token transfer failed:" # tid);
            };
            ignore addRecord(
                from, "withdrawTo", 
                [
                    ("tokenId", #Text(tid)),
                    ("tokenTxid", #Text(u64ToText(txid))),
                    ("from", #Principal(from)),
                    ("to", #Principal(msg.caller)),
                    ("amount", #Text(u64ToText(token_amount))),
                    ("fee", #Text(u64ToText(fee))),
                    ("balance", #Text(u64ToText(tokens.balanceOf(tid, msg.caller)))),
                    ("totalSupply", #Text(u64ToText(tokens.totalSupply(tid))))
                ]
            );
            return #ok(token_amount - fee);
        } else {
            return #err("burn token failed:" # tid);
        };
    };
    
    public shared(msg) func failedWithdrawRefund(transactionId: Text) : async WithdrawRefundReceipt {        
        if (_checkAuth(msg.caller) == false) {
          return #Err("unauthorized");
        };        

        switch(faileWithdraws.get(transactionId)){
            case(?trans){
                if(trans.refundStatus){
                   return #Err("The refund has already been processed.");     
                };
                var tid:Text=trans.tokenId;
                var userPId:Principal=trans.userPId;
                var value:Nat=trans.value;
                ignore tokens.mint(tid, userPId, value);
                faileWithdraws.put(transactionId,{
                    tokenId=tid; 
                    userPId=userPId; 
                    value=value; 
                    refundStatus=true;
                });
                #Ok(true);
            };
            case(_){
                return #Err("transaction not found");
            };
        };
    };

    /*
    *   swap related functions: createPair/addLiquidity/removeLiquidity/swap
    */
    public shared(msg) func createPair(token0: Principal, token1: Principal): async TxReceipt {
        let tid0: Text = Principal.toText(token0);
        let tid1: Text = Principal.toText(token1);
        if(tid0 == tid1 or token0 == blackhole or token1 == blackhole)
            return #err("identical addresses or blackhole address");
        if(tokens.hasToken(tid0) == false or tokens.hasToken(tid1) == false)
            return #err("token not exist");

        let (t0, t1) = Utils.sortTokens(tid0, tid1);
        let pair_str = t0 # ":" # t1;
        if (Option.isSome(pairs.get(pair_str)) or lptokens.hasToken(pair_str))
            return #err("pair exists");

        let token0Actor = _getTokenActor(t0);
        let token1Actor = _getTokenActor(t1);
        let name0 = await _getSymbol(token0Actor);
        let name1 = await _getSymbol(token1Actor);
        let lpName = name0 # "-" # name1;

        let lp : TokenInfo = {
            id = pair_str;
            var name = lpName # "-LP";
            var symbol = lpName # "-LP";
            var decimals = 8;
            var fee = tokenFee; // 0.0001 fee for transfer/approve
            var totalSupply = 0;
            balances = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
            allowances = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>(1, Principal.equal, Principal.hash);
        };
        
        let pairinfo: PairInfo = {
            id = pair_str;
            token0 = t0;
            token1 = t1;
            creator = msg.caller;
            var reserve0 = 0;
            var reserve1 = 0;
            var price0CumulativeLast = 0;
            var price1CumulativeLast = 0;
            var kLast = 0;
            var blockTimestampLast = 0;
            var totalSupply = 0;
            lptoken = pair_str;
        };
        pairs.put(pair_str, pairinfo);
        ignore lptokens.createToken(pair_str, lp);
        ignore addRecord(
            msg.caller, "createPair", 
            [
                ("pairId", #Text(pair_str)),
                ("token0", #Text(t0)),
                ("token1", #Text(t1))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    // update price accumulators on the first call of each block
    // TWAP = (priceCum_2 - priceCum_1) / (timestamp_2 - timestamp_1)
    // query output amount: amountIn * TWAP / 10**30
    private func _update(pair: PairInfo): PairInfo {
        let blockTimestamp: Int = Time.now();
        let timeElapsed: Nat = Int.abs(blockTimestamp - pair.blockTimestampLast);
        // TODO: check numeric precision
        // mul 10**30 for precision
        if(timeElapsed > 0 and pair.reserve0 > 0 and pair.reserve1 > 0) {
            pair.price0CumulativeLast := pair.reserve1 * 10**30 / pair.reserve0 * timeElapsed;
            pair.price1CumulativeLast := pair.reserve0 * 10**30 / pair.reserve1 * timeElapsed;
        };
        pair.blockTimestampLast := blockTimestamp;
        return pair;
    };

    // mint dev fee
    private func _mintFee(pair: PairInfo): Nat {
        if(feeOn == false) {
            pair.kLast := 0;
            return 0;
        };
        if(pair.kLast == 0) {
            return 0;
        };
        if(pair.totalSupply == 0 or pair.reserve0 == 0 or pair.reserve1 == 0) {
            return 0;
        };
        var rootK: Nat = Utils.sqrt(pair.reserve0 * pair.reserve1);
        var rootKLast: Nat = Utils.sqrt(pair.kLast);
        var liquidity: Nat = 0;
        if(rootK > rootKLast) {
            var numerator: Nat = pair.totalSupply * (rootK - rootKLast);
            var denominator: Nat = rootK * 5 + rootKLast;
            liquidity := numerator / denominator;
            // if(liquidity > 0) {
                // let _ = lptokens.mint(pair.id, feeTo, liquidity);
                // pair.totalSupply += liquidity;
            // };
        };
        return liquidity;
    };

    private func getTokenBlockStatus(tokenId: Principal): TokenBlockType{
        switch(tokenBlocklist.get(tokenId)){
            case(?d){
                d;
            };
            case(_){
                #None(true);
            }
        }
    };

    /**
    *   1. calculate amount0/amount1
    *   2. transfer token0/token1 from user to this canister (user has to approve first)
    *   3. mint lp token for msg.caller
    *   4. update reserve0/reserve1 info of pair
    */
    public shared(msg) func addLiquidity(
        token0: Principal, 
        token1: Principal, 
        amount0Desired: Nat, 
        amount1Desired: Nat, 
        amount0Min: Nat, 
        amount1Min: Nat,
        deadline: Int
        ): async TxReceipt {
        if (Time.now() > deadline)
            return #err("tx expired");
        if (amount0Desired == 0 or amount1Desired == 0)
            return #err("desired amount should not be zero");
        
        switch(getTokenBlockStatus(token0)){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(token0));     
            }
        };
        switch(getTokenBlockStatus(token1)){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(token1));     
            }
        };

        let tid0: Text = Principal.toText(token0);
        let tid1: Text = Principal.toText(token1);

        var pair = switch(_getPair(tid0, tid1)) {
            case(?p) { p; };
            case(_) {
                return #err("pair not exist")
            };
        };
        var lptoken = switch(_getlpToken(tid0, tid1)) {
            case(?t) { t; };
            case(_) { return #err("lptokens or lptoken pair doesnot exists"); };
        };

        var amount0 = 0;
        var amount1 = 0;
        var amount0D = amount0Desired;
        var amount1D = amount1Desired;
        var amount0M = amount0Min;
        var amount1M = amount1Min;
        var reserve0 = pair.reserve0;
        var reserve1 = pair.reserve1;
        if(tid0 == pair.token1) {
            amount0D := amount1Desired;
            amount1D := amount0Desired;
            amount0M := amount1Min;
            amount1M := amount0Min;
        };

        if(reserve0 == 0 and reserve1 == 0) {
            amount0 := amount0D;
            amount1 := amount1D;
        } else {
            let amount1Optimal = Utils.quote(amount0D, reserve0, reserve1);
            if(amount1Optimal <= amount1D) {
                assert(amount1Optimal >= amount1M);
                amount0 := amount0D;
                amount1 := amount1Optimal;
            } else {
                let amount0Optimal = Utils.quote(amount1D, reserve1, reserve0);
                assert(amount0Optimal <= amount0D);
                assert(amount0Optimal >= amount0M);
                amount0 := amount0Optimal;
                amount1 := amount1D;
            };
        };

        if(amount0 > tokens.balanceOf(pair.token0, msg.caller)){
            return #err("insufficient balance: " # pair.token0);
        };
        if(amount1 > tokens.balanceOf(pair.token1, msg.caller)){
            return #err("insufficient balance: " # pair.token1);
        };
        if(tokens.zeroFeeTransfer(pair.token0, msg.caller, Principal.fromActor(this), amount0) == false)
            return #err("insufficient balance: " # pair.token0);
        if(tokens.zeroFeeTransfer(pair.token1, msg.caller, Principal.fromActor(this), amount1) == false)
            return #err("insufficient balance: " # pair.token1);

        // mint fee
        var feeLP: Nat = _mintFee(pair);
        if(feeLP > 0) {
            let _ = lptokens.mint(pair.id, feeTo, feeLP);
            pair.totalSupply += feeLP;
        };

        var totalSupply_ = pair.totalSupply;
        // mint LP token
        var lpAmount = 0;
        if(totalSupply_ == 0) {
            lpAmount := Utils.sqrt(amount0 * amount1) - minimum_liquidity;
            ignore lptokens.mint(pair.id, blackhole, minimum_liquidity);
        } else {
            lpAmount := Nat.min(amount0 * totalSupply_ / reserve0, amount1 * totalSupply_ / reserve1);
        };
        
        assert(lpAmount > 0);
        assert(lptokens.mint(pair.id, msg.caller, lpAmount));
        pair := _update(pair);
        // update reserves
        pair.reserve0 += amount0;
        pair.reserve1 += amount1;
        if(feeOn) {
            pair.kLast := pair.reserve0 * pair.reserve1;
        };
        pair.totalSupply += lpAmount;
        pairs.put(pair.id, pair);
        ignore addRecord(
            msg.caller, "addLiquidity", 
            [
                ("pairId", #Text(pair.id)),
                ("token0", #Text(pair.token0)),
                ("token1", #Text(pair.token1)),
                ("amount0", #Text(u64ToText(amount0))),
                ("amount1", #Text(u64ToText(amount1))),
                ("lpAmount", #Text(u64ToText(lpAmount))),
                ("reserve0", #Text(u64ToText(pair.reserve0))),
                ("reserve1", #Text(u64ToText(pair.reserve1)))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    /**
    *   1. calculate amount0/amount1
    *   2. transfer token0/token1 from user to this canister (user has to approve first)
    *   3. mint lp token for msg.caller
    *   4. update reserve0/reserve1 info of pair
    */
    public shared(msg) func addLiquidityForUser(
        userPId:Principal,
        token0: Principal, 
        token1: Principal, 
        amount0Desired: Nat, 
        amount1Desired: Nat,
        useSubAcount : Bool
        ): async TxReceipt {

        if (_checkAuth(msg.caller) == false) {
            return #err("unauthorized");
        };

        switch(getTokenBlockStatus(token0)){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(token0));     
            }
        };
        switch(getTokenBlockStatus(token1)){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(token1));     
            }
        };

        if(useSubAcount) {
            var depositToken1Result=await depositForUser(userPId, token0);
            var depositToken2Result=await depositForUser(userPId, token1);
            switch(depositToken1Result){
                case(#ok(id)) { };
                case(_) {
                    return #err("token1 deposit error");
                };
            };

            switch(depositToken2Result){
                case(#ok(id)) { };
                case(_) {
                    return #err("token2 deposit error");
                };
            };
        };
        if (amount0Desired == 0 or amount1Desired == 0)
            return #err("desired amount should not be zero");

        let tid0: Text = Principal.toText(token0);
        let tid1: Text = Principal.toText(token1);

        var pair = switch(_getPair(tid0, tid1)) {
            case(?p) { p; };
            case(_) {
                return #err("pair not exist")
            };
        };
        var lptoken = switch(_getlpToken(tid0, tid1)) {
            case(?t) { t; };
            case(_) { return #err("lptokens or lptoken pair doesnot exists"); };
        };

        var amount0 = 0;
        var amount1 = 0;
        var amount0D = amount0Desired;
        var amount1D = amount1Desired;
        // var amount0M = amount0Min;
        // var amount1M = amount1Min;
        var reserve0 = pair.reserve0;
        var reserve1 = pair.reserve1;
        if(tid0 == pair.token1) {
            amount0D := amount1Desired;
            amount1D := amount0Desired;
            // amount0M := amount1Min;
            // amount1M := amount0Min;
        };

        if(reserve0 == 0 and reserve1 == 0) {
            amount0 := amount0D;
            amount1 := amount1D;
        } else {
            let amount1Optimal = Utils.quote(amount0D, reserve0, reserve1);
            if(amount1Optimal <= amount1D) {
                // assert(amount1Optimal >= amount1M);
                amount0 := amount0D;
                amount1 := amount1Optimal;
            } else {
                let amount0Optimal = Utils.quote(amount1D, reserve1, reserve0);
                assert(amount0Optimal <= amount0D);
                // assert(amount0Optimal >= amount0M);
                amount0 := amount0Optimal;
                amount1 := amount1D;
            };
        };

        if(amount0 > tokens.balanceOf(pair.token0, userPId)){
            return #err("insufficient balance: " # pair.token0);
        };
        if(amount1 > tokens.balanceOf(pair.token1, userPId)){
            return #err("insufficient balance: " # pair.token1);
        };
        if(tokens.zeroFeeTransfer(pair.token0, userPId, Principal.fromActor(this), amount0) == false)
            return #err("insufficient balance: " # pair.token0);
        if(tokens.zeroFeeTransfer(pair.token1, userPId, Principal.fromActor(this), amount1) == false)
            return #err("insufficient balance: " # pair.token1);

        // mint fee
        var feeLP: Nat = _mintFee(pair);
        if(feeLP > 0) {
            let _ = lptokens.mint(pair.id, feeTo, feeLP);
            pair.totalSupply += feeLP;
        };

        var totalSupply_ = pair.totalSupply;
        // mint LP token
        var lpAmount = 0;
        if(totalSupply_ == 0) {
            lpAmount := Utils.sqrt(amount0 * amount1) - minimum_liquidity;
            ignore lptokens.mint(pair.id, blackhole, minimum_liquidity);
        } else {
            lpAmount := Nat.min(amount0 * totalSupply_ / reserve0, amount1 * totalSupply_ / reserve1);
        };

        assert(lpAmount > 0);
        assert(lptokens.mint(pair.id, userPId, lpAmount));
        pair := _update(pair);
        // update reserves
        pair.reserve0 += amount0;
        pair.reserve1 += amount1;
        if(feeOn) {
            pair.kLast := pair.reserve0 * pair.reserve1;
        };
        pair.totalSupply += lpAmount;
        pairs.put(pair.id, pair);
        ignore addRecord(
            userPId, "addLiquidity", 
            [
                ("pairId", #Text(pair.id)),
                ("token0", #Text(pair.token0)),
                ("token1", #Text(pair.token1)),
                ("amount0", #Text(u64ToText(amount0))),
                ("amount1", #Text(u64ToText(amount1))),
                ("lpAmount", #Text(u64ToText(lpAmount))),
                ("reserve0", #Text(u64ToText(pair.reserve0))),
                ("reserve1", #Text(u64ToText(pair.reserve1)))
            ]
        );
        txcounter += 1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func registerFundRecoveryForUser(user : Principal, tokenId : Principal, amount : Nat) : async TxReceipt {
        // TODO: this function can be moved in control of the DAO
        assert(_checkAuth(msg.caller));
        let tid : Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");
        switch(userFundRecoveries.get(user)){
            case(?r){
                return #err("pending funding recovery");
            };
            case(_){};
        };
        userFundRecoveries.put(user, {
            tokenId = tokenId;
            amount = amount;
        });
        ignore addRecord(
            msg.caller, "registerFundRecoveryForUser",
            [
                ("user", #Principal(user)),
                ("token", #Principal(tokenId)),
                ("amount", #Text(u64ToText(amount)))
            ]
        );
        txcounter +=1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func validateRegisterFundRecoveryForUser(user : Principal, tokenId : Principal, amount : Nat) : async ValidateFunctionReturnType {
        let tid : Text = Principal.toText(tokenId);
        if (tokens.hasToken(tid) == false)
            return #Err("token does not exists");
        switch(userFundRecoveries.get(user)){
            case(?r){
                return #Err("pending funding recovery");
            };
            case(_){};
        };
        return #Ok("valid inputs");
    };

    public shared(msg) func executeFundRecoveryForUser(user: Principal) : async TxReceipt{
        // TODO: this function can be moved in control of DAO
        assert(_checkAuth(msg.caller));
        let recoveryDetails : RecoveryDetails = switch(userFundRecoveries.get(user)){
            case(?r){r};
            case(_){
                return #err("no fund recovery registered for user");
            };
        };
        let tid : Text = Principal.toText(recoveryDetails.tokenId);
        if (tokens.hasToken(tid) == false)
            return #err("token not exist");
        userFundRecoveries.delete(user);
        ignore tokens.mint(tid, user, effectiveDepositAmount(tid, recoveryDetails.amount));
        ignore addRecord(
            msg.caller, "executeFundRecoveryForUser",
            [
                ("user", #Principal(user)),
                ("token", #Principal(recoveryDetails.tokenId)),
                ("amount", #Text(u64ToText(recoveryDetails.amount)))
            ]
        );
        txcounter +=1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func validateExecuteFundRecoveryForUser(user: Principal) : async ValidateFunctionReturnType{
        let recoveryDetails : RecoveryDetails = switch(userFundRecoveries.get(user)){
            case(?r){r};
            case(_){
                return #Err("no fund recovery registered for user");
            };
        };
        let tid : Text = Principal.toText(recoveryDetails.tokenId);
        if (tokens.hasToken(tid) == false)
            return #Err("token does not exists");
        return #Ok("valid inputs");
    };

    public shared(msg) func addLiquidityForUserTest(
        userPId:Principal,
        token0: Principal, 
        token1: Principal, 
        amount0Desired: Nat, 
        amount1Desired: Nat
        ): async Text {          
        assert(_checkAuth(msg.caller));

        if (amount0Desired == 0 or amount1Desired == 0)
            return "desired amount should not be zero";

        let tid0: Text = Principal.toText(token0);
        let tid1: Text = Principal.toText(token1);

        var pair = switch(_getPair(tid0, tid1)) {
            case(?p) { p; };
            case(_) {
                return "pair not exist";
            };
        };
        var lptoken = switch(_getlpToken(tid0, tid1)) {
            case(?t) { t; };
            case(_) { return "lptokens or lptoken pair doesnot exists"; };
        };

        var amount0 = 0;
        var amount1 = 0;
        var amount0D = amount0Desired;
        var amount1D = amount1Desired;

        var reserve0 = pair.reserve0;
        var reserve1 = pair.reserve1;
        if(tid0 == pair.token1) {
            amount0D := amount1Desired;
            amount1D := amount0Desired;
        };

        if(reserve0 == 0 and reserve1 == 0) {
            amount0 := amount0D;
            amount1 := amount1D;
        } else {
            let amount1Optimal = Utils.quote(amount0D, reserve0, reserve1);
            if(amount1Optimal <= amount1D) {
                amount0 := amount0D;
                amount1 := amount1Optimal;
            } else {
                let amount0Optimal = Utils.quote(amount1D, reserve1, reserve0);
                assert(amount0Optimal <= amount0D);
                amount0 := amount0Optimal;
                amount1 := amount1D;
            };
        };

        return debug_show({
            token0 = token0;
            token1 = token1;
            amount0 = amount0;
            amount1 = amount1;
        });
    };

    /**
    *   1. transfer lp token from user to this canister (user has to approve first)
    *   2. burn lp token
    *   3. calculate token0/token1 amount
    *   4. transfer token0/token1 to user
    *   5. update reserve0/reserve1 info of pair
    */
    public shared(msg) func removeLiquidity(
        token0: Principal,
        token1: Principal, 
        lpAmount: Nat,
        amount0Min: Nat,
        amount1Min: Nat,
        to: Principal,
        deadline: Int
        ): async TxReceipt {
        if (Time.now() > deadline)
            return #err("tx expired");

        switch(getTokenBlockStatus(token0)){
            case(#Partial(id)) { };
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(token0));     
            }
        };
        switch(getTokenBlockStatus(token1)){
            case(#Partial(id)) { };
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#Principal.toText(token1));     
            }
        };

        let tid0: Text = Principal.toText(token0);
        let tid1: Text = Principal.toText(token1);
        var pair = switch(_getPair(tid0, tid1)) {
            case(?p) { p; };
            case(_) { return #err("pair not exist"); };
        };
        var lptoken = switch(_getlpToken(tid0, tid1)) {
            case(?t) { t; };
            case(_) { return #err("pair not exist");  };
        };


        // mint fee
        var feeLP: Nat = _mintFee(pair);

        var totalSupply = pair.totalSupply + feeLP;
        var amount0 : Nat = lpAmount * pair.reserve0 / totalSupply;
        var amount1 : Nat = lpAmount * pair.reserve1 / totalSupply;
        var amount0M = 0;
        var amount1M = 0;

        Debug.print(debug_show((amount0, amount1)));
        if (amount0 == 0 or amount1 == 0)
            return #err("insufficient LP tokens");

        // make sure that amount0 <-> pair.token0
        if (tid0 == pair.token0) {
            amount0M := amount0Min;
            amount1M := amount1Min;
        } else {
            amount0M := amount1Min;
            amount1M := amount0Min;
        };        

        if(Nat.greater(feeLP,0)){
            var amount0Part0:Nat=amount0M;
            var amount0Part1:Nat=lpAmount * pair.reserve0 / feeLP;
            var amount0calculated=(amount0Part0*amount0Part1)/(amount0Part0+amount0Part1);

            var amount1Part0:Nat=amount1M;
            var amount1Part1:Nat=lpAmount * pair.reserve1 / feeLP;
            var amount1calculated=(amount1Part0*amount1Part1)/(amount1Part0+amount1Part1);

            if (amount0 < amount0calculated or amount1 < amount1calculated)
                return #err("insufficient output amount : " # debug_show({
                    amount0 = amount0;
                    amount1 = amount1;
                    amount0Part0 = amount0Part0;
                    amount0Part1 = amount0Part1;
                    amount1Part0 = amount1Part0;
                    amount1Part1 = amount1Part1;
                    amount0calculated = amount0calculated;
                    amount1calculated = amount1calculated;
                }));    
        }
        else{
            if (amount0 < amount0M or amount1 < amount1M)
               return #err("insufficient output : " # debug_show({
                 amount0 = amount0;
                 amount1 = amount1;
                 amount0M = amount0M;
                 amount1M = amount1M;
               }));            
        };
        
        // burn user lp
        if (lptokens.burn(pair.id, msg.caller, lpAmount) == false)
            return #err("insufficient LP balance or lpAmount too small");
        // transfer tokens to user
        assert(tokens.zeroFeeTransfer(pair.token0, Principal.fromActor(this), to, amount0));
        assert(tokens.zeroFeeTransfer(pair.token1, Principal.fromActor(this), to, amount1));

        // mint fee
        if(feeLP > 0) {
            let _ = lptokens.mint(pair.id, feeTo, feeLP);
            pair.totalSupply += feeLP;
        };

        pair := _update(pair);
        // update reserves
        pair.reserve0 -= amount0;
        pair.reserve1 -= amount1;
        if(feeOn) {
            pair.kLast := pair.reserve0 * pair.reserve1;
        };
        pair.totalSupply -= lpAmount;
        pairs.put(pair.id, pair);
        swapLastTransaction.put(msg.caller,#RemoveLiquidityOutAmount(amount0,amount1));
        ignore addRecord(
            msg.caller, "removeLiquidity", 
            [
                ("pairId", #Text(pair.id)),
                ("token0", #Text(pair.token0)),
                ("token1", #Text(pair.token1)),
                ("lpAmount", #Text(u64ToText(lpAmount))),
                ("amount0", #Text(u64ToText(amount0))),
                ("amount1", #Text(u64ToText(amount1))),
                ("reserve0", #Text(u64ToText(pair.reserve0))),
                ("reserve1", #Text(u64ToText(pair.reserve1)))
            ]
        );
        txcounter +=1;
        return #ok(txcounter - 1);
    };

    public shared(msg) func migrateLiquidity(
        liquidityProvider:Principal,
        token0: Principal,
        token1: Principal, 
        v3PoolId: Principal
        ): async TxReceipt {
        assert(_checkAuth(msg.caller));

        let tid0: Text = Principal.toText(token0);
        let tid1: Text = Principal.toText(token1);
        var pair = switch(_getPair(tid0, tid1)) {
            case(?p) { p; };
            case(_) { return #err("pair not exist"); };
        };
        var _lptoken = switch(_getlpToken(tid0, tid1)) {
            case(?t) { t; };
            case(_) { return #err("pair not exist");  };
        };

        let lpAmount: Nat=lptokens.getTokenBalances(pair.id ,liquidityProvider);
        if (lpAmount == 0)
            return #err("insufficient lpAmount");

        // mint fee
        var feeLP: Nat = _mintFee(pair);

        var totalSupply = pair.totalSupply + feeLP;
        var amount0 : Nat = lpAmount * pair.reserve0 / totalSupply;
        var amount1 : Nat = lpAmount * pair.reserve1 / totalSupply;

        Debug.print(debug_show((amount0, amount1)));
        if (amount0 == 0 or amount1 == 0)
            return #err("insufficient LP tokens");

        // burn user lp
        if (lptokens.burn(pair.id, liquidityProvider, lpAmount) == false)
            return #err("insufficient LP balance or lpAmount too small");
        // transfer tokens to user
        assert(tokens.zeroFeeTransfer(pair.token0, Principal.fromActor(this), liquidityProvider, amount0));
        assert(tokens.zeroFeeTransfer(pair.token1, Principal.fromActor(this), liquidityProvider, amount1));

        // mint fee
        if(feeLP > 0) {
            let _ = lptokens.mint(pair.id, feeTo, feeLP);
            pair.totalSupply += feeLP;
        };

        pair := _update(pair);
        // update reserves
        pair.reserve0 -= amount0;
        pair.reserve1 -= amount1;
        if(feeOn) {
            pair.kLast := pair.reserve0 * pair.reserve1;
        };
        pair.totalSupply -= lpAmount;
        pairs.put(pair.id, pair);
        ignore addRecord(
            liquidityProvider, "migrateLiquidity", 
            [
                ("pairId", #Text(pair.id)),
                ("token0", #Text(pair.token0)),
                ("token1", #Text(pair.token1)),
                ("lpAmount", #Text(u64ToText(lpAmount))),
                ("amount0", #Text(u64ToText(amount0))),
                ("amount1", #Text(u64ToText(amount1))),
                ("reserve0", #Text(u64ToText(pair.reserve0))),
                ("reserve1", #Text(u64ToText(pair.reserve1))),
                ("v3PoolId", #Text(Principal.toText(v3PoolId))),
            ]
        );
        ignore addRecord(
            msg.caller, "removeLiquidity", 
            [
                ("pairId", #Text(pair.id)),
                ("token0", #Text(pair.token0)),
                ("token1", #Text(pair.token1)),
                ("lpAmount", #Text(u64ToText(lpAmount))),
                ("amount0", #Text(u64ToText(amount0))),
                ("amount1", #Text(u64ToText(amount1))),
                ("reserve0", #Text(u64ToText(pair.reserve0))),
                ("reserve1", #Text(u64ToText(pair.reserve1)))
            ]
        );

        if(approve_for_migration(liquidityProvider, Principal.toText(token0), v3PoolId, amount0))
        {
            ignore addRecord(
                liquidityProvider, "migrateToken0Approve", 
                [
                    ("tokenId", #Text(Principal.toText(token0))),
                    ("from", #Principal(liquidityProvider)),
                    ("to", #Principal(v3PoolId)),
                    ("amount", #Text(u64ToText(amount0))),
                    ("allowance", #Text(u64ToText(tokens.allowance(Principal.toText(token0), liquidityProvider, v3PoolId))))
                ]
            );
        };
        if(approve_for_migration(liquidityProvider, Principal.toText(token1), v3PoolId, amount1))
        {
            ignore addRecord(
                liquidityProvider, "migrateToken1Approve", 
                [
                    ("tokenId", #Text(Principal.toText(token1))),
                    ("from", #Principal(liquidityProvider)),
                    ("to", #Principal(v3PoolId)),
                    ("amount", #Text(u64ToText(amount1))),
                    ("allowance", #Text(u64ToText(tokens.allowance(Principal.toText(token1), liquidityProvider, v3PoolId))))
                ]
            );
        };
        txcounter +=1;
        return #ok(txcounter - 1);
    };

    private func _getReserves(t0: Text, t1: Text): (Nat, Nat) {
        switch(_getPair(t0, t1)) {
            case(?p) { 
                if(p.token0 == t0) {
                    return (p.reserve0, p.reserve1);
                } else {
                    return (p.reserve1, p.reserve0);
                };
            };
            case(_) { assert(false); return (0, 0); };
        };
    };

    private func _getAmountsOut(amountIn: Nat, path: [Text]): ([var Nat],Nat) {
        assert(path.size() >= 2);
        var amounts: [var Nat] = Array.init<Nat>(path.size(), amountIn);
        var rewardAmount=0;
        var i: Nat = 0;
        while(i < Int.abs(path.size() - 1)) {
            let ret: (Nat, Nat) = _getReserves(path[i], path[i+1]);
            let reserveIn = ret.0;
            let reserveOut = ret.1;
            let data=Utils.getAmountOut(amounts[i], reserveIn, reserveOut);
            amounts[i+1] := data.0;
            rewardAmount := data.1;
            i += 1;
        };
        return (amounts,rewardAmount);
    };

    private func _getAmountsIn(amountOut: Nat, path: [Text]): [var Nat] {
        assert(path.size() >= 2);
        var amounts: [var Nat] = Array.init<Nat>(path.size(), amountOut);
        var i: Nat = Int.abs(path.size()) - 1;
        while(i > 0) {
            let ret = _getReserves(path[i-1], path[i]);
            let reserveIn = ret.0;
            let reserveOut = ret.1;
            amounts[i-1] := Utils.getAmountIn(amounts[i], reserveIn, reserveOut);
            i -= 1;
        };
        return amounts;
    };

    private func _swap(amounts: [var Nat], path: [Text], to: Principal,txid: Nat): [[(Text, Root.DetailValue)]] {
        var ops = Buffer.Buffer<[(Text, Root.DetailValue)]>(path.size()-1);
        // Iter.range(x, y) = [x, y], we need [0, path.size() - 1)
        for(i in Iter.range(0, path.size() - 2)) {
            // input = path[i], output = path[i+1]
            // amountIn = amounts[i], amountOut = amounts[i+1]
            var pair: PairInfo = switch(_getPair(path[i], path[i+1])) {
                case(?p) { p; };
                case(_) { 
                    Prelude.unreachable()
                };
            };
            if(pair.token0 == path[i]) {
                pair.reserve0 += amounts[i];
                pair.reserve1 -= amounts[i+1];
            } else {
                pair.reserve1 += amounts[i];
                pair.reserve0 -= amounts[i+1];
            };
            pair := _update(pair);
            // update reserves
            ignore _putPair(path[i], path[i+1], pair);
            var detailRecord=[
                    ("pairId", #Text(pair.id)),
                    ("toAccount", #Principal(to)),
                    ("from", #Text(path[i])),
                    ("to", #Text(path[i+1])),
                    ("tokenTxid", #Text(u64ToText(txid))),
                    ("amountIn", #Text(u64ToText(amounts[i]))),
                    ("amountOut", #Text(u64ToText(amounts[i+1]))),
                    ("reserve0", #Text(u64ToText(pair.reserve0))),
                    ("reserve1", #Text(u64ToText(pair.reserve1))),
                    ("fee", #Text(u64ToText(amounts[i] * 3 / 1000)))
            ];
            if(feeOn){
               detailRecord:=Array.append(detailRecord, [("LPfee", #Text(u64ToText(amounts[i] * 25 / 10000)))]); 
            };
            ops.add(detailRecord);
            if(i == Int.abs(path.size() - 2)) {
                assert(tokens.zeroFeeTransfer(path[i+1], Principal.fromActor(this), to, amounts[i+1]));
            };
        };
        return ops.toArray();
    };

    public shared(msg) func swapExactTokensForTokens(
        amountIn: Nat,
        amountOutMin: Nat,
        path: [Text],
        to: Principal,
        deadline: Int
        ): async TxReceipt {
        if (Time.now() > deadline)
            return #err("tx expired");
        
        switch(getTokenBlockStatus(Principal.fromText(path[0]))){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#path[0]);     
            }
        };
        switch(getTokenBlockStatus(Principal.fromText(path[1]))){
            case(#None(id)) { };
            case(_){
                return #err("token is blocked "#path[1]);     
            }
        };

        var amountdatas = _getAmountsOut(amountIn, path);
        var amounts = amountdatas.0;
        var rewardAmount = amountdatas.1;
        if (amounts[amounts.size() - 1] < amountOutMin) // slippage check
            return #err("slippage: insufficient output amount");
        if(amounts[0] > tokens.balanceOf(path[0], msg.caller)) {
            return #err("insufficient balance: " # path[0]);
        };
        if (tokens.zeroFeeTransfer(path[0], msg.caller, Principal.fromActor(this), amounts[0]) == false)
            return #err("insufficient balance: " # path[0]);
        let ops = _swap(amounts, path, to,txcounter);
        for(o in Iter.fromArray(ops)) {
            ignore addRecord(msg.caller, "swap", o);
            txcounter += 1;
        };
        swapLastTransaction.put(msg.caller,#SwapOutAmount(amounts[1]));
        return #ok(amounts[1]);
    };

    public shared(msg) func log_test_ignore() : async TxReceipt {
        try {
            assert(_checkAuth(msg.caller));
            ignore addRecord(
                msg.caller, "logtest_ignore", 
                [
                    ("tokenId", #Text("tokenId")),
                    ("from", #Principal(msg.caller)),
                    ("to", #Principal(msg.caller)),
                    ("amount", #Text("amount")),
                    ("fee", #Text("fee")),
                    ("balance", #Text("balance")),
                    ("totalSupply", #Text("totalSupply")),
                ]);
            } catch (e) {
                return #err("logtest failed:" # Error.message(e));
            };

        return #ok(1);
    };

    public shared(msg) func log_test() : async TxReceipt {
        try {
            assert(_checkAuth(msg.caller));
            await addRecord_without_ignore(
                msg.caller, "logtest", 
                [
                    ("tokenId", #Text("tokenId")),
                    ("from", #Principal(msg.caller)),
                    ("to", #Principal(msg.caller)),
                    ("amount", #Text("amount")),
                    ("fee", #Text("fee")),
                    ("balance", #Text("balance")),
                    ("totalSupply", #Text("totalSupply")),
                ]);
            } catch (e) {
                return #err("logtest failed:" # Error.message(e));
            };

        return #ok(1);
    };

    public shared(msg) func setWICPMigration(wicp_xtc_migration:Bool) : async Bool {
        assert(_checkAuth(msg.caller));
        wicp_xtc_migrationEnabled:=wicp_xtc_migration;
        return true;
    };

    /*
    * public info query functions
    */
    public query func getWICPMigration(): async Bool {
        return wicp_xtc_migrationEnabled;
    };

    public shared query(msg) func getLastTransactionOutAmount(): async SwapLastTransaction {
        switch(swapLastTransaction.get(msg.caller)){
            case(?trans){
                return trans;
            };
            case(_){
                return #NotFound(true);
            }
        }
    };

    public query func historySize(): async Nat {
        return txcounter;
    };

    public query func getLPTokenId(token0: Principal, token1: Principal) : async Text {
        _getlpTokenId(Principal.toText(token0), Principal.toText(token1));
    };

    public query func getAllPairs(): async [PairInfoExt] {
        var pairList = Buffer.Buffer<PairInfoExt>(pairs.size());
		for((tid, pair) in pairs.entries()) {
            pairList.add(_pairToExternal(pair));
		};
		pairList.toArray()
    };

    public query func getAllRewardPairs(): async [PairInfoExt] {
        var pairList = Buffer.Buffer<PairInfoExt>(rewardPairs.size());
		for((tid, pair) in rewardPairs.entries()) {
            pairList.add(_pairToExternal(pair));
		};
		pairList.toArray()
    };


    public query func getPairs(start: Nat, num: Nat) : async ([PairInfoExt], Nat) {
        var pairList = Buffer.Buffer<PairInfoExt>(pairs.size());
        for((tid, pair) in pairs.entries()) {
            pairList.add(_pairToExternal(pair));
        };
        let limit: Nat = if(start + num > pairList.size()) {
            pairList.size() - start
        } else {
            num
        };
        let res = Array.init<PairInfoExt>(limit, pairList.get(0));
        for (i in Iter.range(0, limit-1)) {
            res[i] := pairList.get(i+start);
        };
        return (Array.freeze(res), pairList.size());                
    };

    public query func getNumPairs(): async Nat {
        return pairs.size();
    };

    public query func getTokenMetadata(tokenId: Text): async TokenAnalyticsInfo {
        return tokens.getMetadata(tokenId);
    };

    public query func getSupportedTokenList(): async [TokenInfoWithType] {
        return tokens.tokenListWithType(tokenTypes, tokenBlocklist);
    };

    public query func getSupportedTokenListSome(start: Nat, num: Nat) : async ([TokenInfoExt], Nat) {
        let temp = tokens.tokenList();
        let limit: Nat = if(start + num > temp.size()) {
            temp.size() - start
        } else {
            num
        };
        let res = Array.init<TokenInfoExt>(limit, temp[0]);
        for (i in Iter.range(0, limit-1)) {
            res[i] := temp[i+start];
        };
        return (Array.freeze(res), temp.size());
    };

    public query func getSupportedTokenListByName(t: Text, start: Nat, num: Nat) : async ([TokenInfoExt], Nat) {
        var temp = tokens.tokenListByName(t);
        let limit: Nat = if(start + num > temp.size()) {
            temp.size() - start
        } else {
            num
        };
        let res = Array.init<TokenInfoExt>(limit, temp[0]);
        for (i in Iter.range(0, limit-1)) {
            res[i] := temp[start+i];
        };
        return (Array.freeze(res), temp.size());
    };

    public shared func getUserICRC1SubAccount(userPId: Principal) : async Text{
        let subaccount = getICRC1SubAccount(userPId);
        return Hex.encode(Blob.toArray(Account.accountIdentifier(
          Principal.fromActor(this), subaccount
        )));
    };

    public query func getUserBalances(user: Principal): async [(Text, Nat)] {
        return tokens.getBalances(user);
    };

    public query func getUserLPBalances(user: Principal): async [(Text, Nat)] {
        return lptokens.getBalances(user);
    };


    public query func getUserLPBalancesAbove(user: Principal, above: Nat): async [(Text, Nat)] {
        return lptokens.getBalancesAbove(user, above);
    };

    public query func getUserInfo(user: Principal): async UserInfo {
        {
            balances = tokens.getBalances(user);
            lpBalances = lptokens.getBalances(user);
        }
    };

    public query func getUserInfoAbove(user: Principal, tokenAbove: Nat, lpAbove: Nat): async UserInfo {
        {
            balances = tokens.getBalancesAbove(user, tokenAbove);
            lpBalances = lptokens.getBalancesAbove(user, lpAbove);
        }
    };

    public query func getUserInfoByNamePageAbove(user: Principal, tokenAbove: Int, tokenName: Text, tokenStart: Nat, tokenNum: Nat, lpAbove: Int, lpName: Text, lpStart: Nat, lpNum: Nat) : async UserInfoPage {
        {
            balances = tokens.getBalancesByNamePageAbove(user, tokenAbove, tokenName, tokenStart, tokenNum);
            lpBalances = tokens.getBalancesByNamePageAbove(user, lpAbove, lpName, lpStart, lpNum);
        }
    };

    public query func getSwapInfo(): async SwapInfo {
        var pairList = Buffer.Buffer<PairInfoExt>(pairs.size());
		for((tid, pair) in pairs.entries()) {
            pairList.add(_pairToExternal(pair));
		};
        return {
            owner = owner;
            feeOn = feeOn;
            feeTo = feeTo;
            cycles = Cycles.balance();
            tokens = tokens.tokenList();
            pairs = pairList.toArray();
            commitId=commitId;
        };
    };

    public query func getHolders(tokenId: Text): async Nat {
        if(Text.contains(tokenId, lppattern)) {
            switch(lptokens.getTokenInfo(tokenId)) {
                case(?t) { t.balances.size() };
                case(_) { 0 };
            }
        } else {
            switch(tokens.getTokenInfo(tokenId)) {
                case(?t) { t.balances.size() };
                case(_) { 0 };
            }
        }
    };

    public query func getHolderInfo(tokenId: Text): async [(Principal, Nat)] {
        if(Text.contains(tokenId, lppattern)) {
            switch(lptokens.getTokenInfo(tokenId)) {
                case(?t) { Iter.toArray(t.balances.entries()) };
                case(_) { [] };
            }
        } else {
            switch(tokens.getTokenInfo(tokenId)) {
                case(?t) { Iter.toArray(t.balances.entries()) };
                case(_) { [] };
            }
        }
    };

    public query func getPair(token0: Principal, token1: Principal) : async ?PairInfoExt {
        let temp = switch(_getPair(Principal.toText(token0), Principal.toText(token1))) {
            case (?pair) {
                pair;
            };
            case(_) {
                return null;
            };
        };
        ?(_pairToExternal(temp))
    };

    public shared query(msg) func getUserReward(userPId: Principal,tid0 :Text, tid1 :Text): async Result.Result<(Nat,Nat), (Text)> {        
        var pair = switch(_getPair(tid0, tid1)) {
            case(?p) { p; };
            case(_) {
                return #ok(0, 0);
            };
        };
        var rewardPair = switch(_getRewardPair(tid0, tid1)) {
            case(?p) { p; };
            case(_) {
                return #ok(0, 0);
            };
        };
        var settledReward= switch(rewardInfo.get(userPId)) {
            case(?reward) { 
                var amount0=switch(Array.find<RewardInfo>(reward, func x = x.tokenId ==tid0)){
                   case(?p) { p.amount };
                   case(_) { 0 };
                };
                var amount1=switch(Array.find<RewardInfo>(reward, func x = x.tokenId ==tid1)){
                   case(?p) { p.amount };
                   case(_) { 0 };
                };
                (amount0, amount1);
             };
            case(_) { (0, 0) };
        };
        
        let (t0, t1) = Utils.sortTokens(tid0, tid1);
        let pair_str = t0 # ":" # t1;
        var processingReward=switch(lptokens.getTokenInfo(pair_str)) {
            case(?t) {
                var lpBalance = t.balances.get(userPId);
                var userLpBalance:Nat = switch lpBalance
                {
                    case (?int) int;
                    case null 0;
                };
                if(Nat.greater(userLpBalance,0) and (Nat.greater(rewardPair.reserve0,0) or Nat.greater(rewardPair.reserve1,0)))
                {
                    var amount0 : Nat = userLpBalance * rewardPair.reserve0 / pair.totalSupply;
                    var amount1 : Nat = userLpBalance * rewardPair.reserve1 / pair.totalSupply; 
                    (amount0, amount1);
                }
                else{
                    (0, 0);
                }
            };
            case(_) { (0, 0) };
        };
        var amount0 = settledReward.0 + processingReward.0;
        var amount1 = settledReward.1 + processingReward.1;
        return #ok((amount0,amount1));
    };

    /*
    *   lptoken & token related functions
    */
    
    public shared(msg) func burn(tokenId: Text, value: Nat) : async Bool {
        if(Text.contains(tokenId, lppattern)) {
            if(lptokens.burn(tokenId, msg.caller, value) == true) {
                switch(pairs.get(tokenId)) {
                    case (?pair) {
                        pair.totalSupply -= value;
                    };
                    case (_) { };
                };
                ignore addRecord(
                    msg.caller, "lpBurn", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(msg.caller)),
                        ("amount", #Text(u64ToText(value))),
                        ("from_balance", #Text(u64ToText(lptokens.balanceOf(tokenId, msg.caller)))),
                    ]
                );
                txcounter += 1;
                return true;
            };
            return false;
        } else {
            if(tokens.burn(tokenId, msg.caller, value)) {
                ignore addRecord(
                    msg.caller, "tokenBurn", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(msg.caller)),
                        ("amount", #Text(u64ToText(value))),
                        ("from_balance", #Text(u64ToText(tokens.balanceOf(tokenId, msg.caller))))
                    ]
                );
                txcounter += 1;
            };
            return false;
        };
    };

    /*
    public shared(msg) func transfer(tokenId: Text, to: Principal, value: Nat) : async Bool {
        if(Text.contains(tokenId, lppattern)) {
            if(lptokens.transfer(tokenId, msg.caller, to, value) == true) {
                let fee = lptokens.getFee(tokenId);
                ignore addRecord(
                    msg.caller, "lpTransfer", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(msg.caller)),
                        ("to", #Principal(to)),
                        ("amount", #Text(u64ToText(value))),
                        ("fee", #Text(u64ToText(fee))),
                        ("from_balance", #Text(u64ToText(lptokens.balanceOf(tokenId, msg.caller)))),
                        ("to_balance", #Text(u64ToText(lptokens.balanceOf(tokenId, to))))
                    ]
                );
                txcounter += 1;
                return true;
            };
            return false;
        } else {
            if(tokens.transfer(tokenId, msg.caller, to, value)) {
                let fee = tokens.getFee(tokenId);
                ignore addRecord(
                    msg.caller, "tokenTransfer", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(msg.caller)),
                        ("to", #Principal(to)),
                        ("amount", #Text(u64ToText(value))),
                        ("fee", #Text(u64ToText(fee))),
                        ("from_balance", #Text(u64ToText(tokens.balanceOf(tokenId, msg.caller)))),
                        ("to_balance", #Text(u64ToText(tokens.balanceOf(tokenId, to))))
                    ]
                );
                txcounter += 1;
            };
            return false;
        };
    };
    */
    public shared(msg) func transferFrom(tokenId: Text, from: Principal, to: Principal, value: Nat) : async Bool {
        if(Text.contains(tokenId, lppattern)) {
            if(lptokens.transferFrom(tokenId, msg.caller, from, to, value) == true) {
                let fee = lptokens.getFee(tokenId);
                ignore addRecord(
                    msg.caller, "lpTransferFrom", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(from)),
                        ("to", #Principal(to)),
                        ("amount", #Text(u64ToText(value))),
                        ("fee", #Text(u64ToText(fee))),
                        ("from_balance", #Text(u64ToText(lptokens.balanceOf(tokenId, msg.caller)))),
                        ("to_balance", #Text(u64ToText(lptokens.balanceOf(tokenId, to))))
                    ]
                );
                txcounter += 1;
                return true;
            };
            return false;
        } else {
            if(tokens.transferFrom(tokenId, msg.caller, from, to, value)) {
                let fee = tokens.getFee(tokenId);
                ignore addRecord(
                    msg.caller, "tokenTransferFrom", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(from)),
                        ("to", #Principal(to)),
                        ("amount", #Text(u64ToText(value))),
                        ("fee", #Text(u64ToText(fee))),
                        ("from_balance", #Text(u64ToText(tokens.balanceOf(tokenId, msg.caller)))),
                        ("to_balance", #Text(u64ToText(tokens.balanceOf(tokenId, to))))
                    ]
                );
                txcounter += 1;
            };
            return false;
        };
    };

    public shared(msg) func approve(tokenId: Text, spender: Principal, value: Nat) : async Bool {
        if(Text.contains(tokenId, lppattern)) {
            if(lptokens.approve(tokenId, msg.caller, spender, value) == true) {
                let fee = lptokens.getFee(tokenId);
                ignore addRecord(
                    msg.caller, "lpApprove", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(msg.caller)),
                        ("to", #Principal(spender)),
                        ("amount", #Text(u64ToText(value))),
                        ("fee", #Text(u64ToText(fee))),
                        ("allowance", #Text(u64ToText(lptokens.allowance(tokenId, msg.caller, spender))))
                    ]
                );
                txcounter += 1;
                return true;
            };
            return false;
        } else {
            if(tokens.approve(tokenId, msg.caller, spender, value)) {
                let fee = tokens.getFee(tokenId);
                ignore addRecord(
                    msg.caller, "tokenApprove", 
                    [
                        ("tokenId", #Text(tokenId)),
                        ("from", #Principal(msg.caller)),
                        ("to", #Principal(spender)),
                        ("amount", #Text(u64ToText(value))),
                        ("fee", #Text(u64ToText(fee))),
                        ("allowance", #Text(u64ToText(tokens.allowance(tokenId, msg.caller, spender))))
                    ]
                );
                txcounter += 1;
                return true;
            };
            return false;
        };
    };

    private func approve_for_migration(liquidityProvider:Principal, token_cansiter_id: Text, spender: Principal, value: Nat) : Bool {
        let tokenId = getWIPCfromICP(token_cansiter_id);
        let skipBalanceValidation=(wicp_xtc_migrationEnabled and tokenId==icp);
        if(tokens.zeroFeeApprove(tokenId, liquidityProvider, spender, value, skipBalanceValidation) == true) {
            return true;
        };
        return false;
    };

    private func getWIPCfromICP(token_cansiter_id: Text) : Text{
        if(wicp_xtc_migrationEnabled) {
            let tokenId = if (token_cansiter_id == wicp) { icp } else if (token_cansiter_id == icp) { wicp } else { token_cansiter_id };
            return tokenId;
        }
        else {
            return token_cansiter_id;
        }
    };

    public query func balanceOf(tokenId: Text, who: Principal) : async Nat {
        if(Text.contains(tokenId, lppattern)) {
            return lptokens.balanceOf(tokenId, who);
        } else {
            return tokens.balanceOf(tokenId, who);
        };
    };

    public query func allowance(tokenId: Text, owner: Principal, spender: Principal) : async Nat {
        if(Text.contains(tokenId, lppattern)) {
            return lptokens.allowance(tokenId, owner, spender);
        } else {
            return tokens.allowance(tokenId, owner, spender);
        };
    };

    public query func totalSupply(tokenId: Text) : async Nat {
        if(Text.contains(tokenId, lppattern)) {
            return lptokens.totalSupply(tokenId);
        } else {
            return tokens.totalSupply(tokenId);
        };
    };

    public query func name(tokenId: Text) : async Text {
        if(Text.contains(tokenId, lppattern)) {
            return lptokens.name(tokenId);
        } else {
            return tokens.name(tokenId);
        };
    };

    public query func decimals(tokenId: Text) : async Nat8 {
        if(Text.contains(tokenId, lppattern)) {
            return lptokens.decimals(tokenId);
        } else {
            return tokens.decimals(tokenId);
        };
    };

    public query func symbol(tokenId: Text) : async Text {
        if(Text.contains(tokenId, lppattern)) {
            return lptokens.symbol(tokenId);
        } else {
            return tokens.symbol(tokenId);
        };
    };

    public query func getAuthList() : async [(Principal, Bool)] {
        return Iter.toArray(auths.entries())
    };

    /*
     * expose metrics to monitoring identities
    */


    public shared(msg) func monitorMetrics(): async MonitorMetrics {

        assert(_checkAuth(msg.caller));

        let canisterStatus : IC.CanisterStatus = await ic.canister_status({
            canister_id = Principal.fromActor(this);
        });

        let lpTokenList = lptokens.getTokenInfoList();
        let tokenList = tokens.getTokenInfoList();

        var lpTokenBalancesSize = 0;
        var lpTokenAllowanceSize = 0;
        var tokenBalancesSize = 0;
        var tokenAllowanceSize = 0;

        for((k,v) in lpTokenList.vals()) {
            lpTokenBalancesSize += v.balances.size();
            lpTokenAllowanceSize += v.allowances.size();
        };

        for((k,v) in tokenList.vals()) {
            tokenBalancesSize += v.balances.size();
            tokenAllowanceSize += v.allowances.size();
        };

        return {
            cycles = Cycles.balance();
            canisterStatus = canisterStatus;
            tokenCount = tokens.getNumTokens();
            pairsCount = pairs.size();
            lptokensSize = lptokens.getNumTokens();
            blocklistedUsersCount = blocklistedUsers.size();
            rewardPairsSize = rewardPairs.size(); 
            rewardTokensSize = rewardTokens.size();
            rewardInfo = rewardInfo.size();
            depositTransactionSize = depositTransactions.size();
            lpTokenBalancesSize = lpTokenBalancesSize;
            lpTokenAllowanceSize = lpTokenAllowanceSize;
            tokenBalancesSize = tokenBalancesSize;
            tokenAllowanceSize = tokenAllowanceSize;
        };
    };

    /*
    * state export
    */
    public shared query(msg) func exportFaileWithdraws() : async [(Text,WithdrawState)] {
        assert(_checkAuth(msg.caller));
        return Iter.toArray(faileWithdraws.entries())
    };

    public shared query(msg) func exportSwapInfo() : async SwapInfoExt{
        assert(_checkAuth(msg.caller));        
        return 
        {
            depositCounter = depositCounter;
            txcounter = txcounter;
            owner = owner;
            feeOn = feeOn;
            feeTo = feeTo;
        };
    };

    public shared query(msg) func exportSubAccounts() : async [(Principal,DepositSubAccounts)] {
        assert(_checkAuth(msg.caller));
        var temp=HashMap.HashMap<Principal, DepositSubAccounts>(1, Principal.equal, Principal.hash);
        for(data in depositTransactions.vals()){
            var trans={
                transactionOwner = data.transactionOwner;
                depositAId=Hex.encode(Blob.toArray(Account.accountIdentifier(
                    Principal.fromActor(this), 
                    data.subaccount
                )));
                subaccount = data.subaccount;
                created_at = data.created_at;
            };
            temp.put(data.transactionOwner,trans);
        };
        return Iter.toArray(temp.entries())
    };

    public shared query(msg) func exportBalances(tokenId: Text): async ?[(Principal, Nat)] {
        assert(_checkAuth(msg.caller));
        if(Text.contains(tokenId, lppattern)) {
            let list = lptokens.getTokenInfoList();
            for((k, v) in list.vals()) {
                if(k == tokenId) {
                    return ?Iter.toArray(v.balances.entries());
                };
            };
            return null;
        } else {
            let list = tokens.getTokenInfoList();
            for((k, v) in list.vals()) {
                if(k == tokenId) {
                    return ?Iter.toArray(v.balances.entries());
                };
            };
            return null;
        };
    };

    public query(msg) func exportTokenTypes(): async [(Text, Text)] {
        assert(_checkAuth(msg.caller));
        return Iter.toArray(tokenTypes.entries());
    };

    public query(msg) func exportTokens(): async [TokenInfoExt] {
        assert(_checkAuth(msg.caller));
        tokens.tokenList()
    };

    public query(msg) func exportLPTokens(): async [TokenInfoExt] {
        assert(_checkAuth(msg.caller));
        lptokens.tokenList()
    };

    public query(msg) func exportPairs(): async [PairInfoExt] {
        assert(_checkAuth(msg.caller));
        Array.map(Iter.toArray(pairs.vals()), _pairToExternal)
    };

    public query(msg) func exportRewardPairs(): async [PairInfoExt]{
        assert(_checkAuth(msg.caller));
        Array.map(Iter.toArray(rewardPairs.vals()), _pairToExternal)
    };

    public shared query(msg) func exportRewardInfo(): async [(Principal,[RewardInfo])]{
        assert(_checkAuth(msg.caller));
        return Iter.toArray(rewardInfo.entries());
    };

    /*
    *   canister upgrade related functions
    */
    private func mapToArray(x: [(Text, TokenInfo)]) : [(Text, TokenInfoExt, [(Principal, Nat)], [(Principal, [(Principal, Nat)])])] {
        var size: Nat = x.size();
        var token: TokenInfoExt = {
            id = "";
            name = "";
            symbol = "";
            decimals = 0;
            fee = 0;
            totalSupply = 0;
        };
        var res_temp: [var (Text, TokenInfoExt, [(Principal, Nat)], [(Principal, [(Principal, Nat)])])] = Array.init<(Text, TokenInfoExt, [(Principal, Nat)], [(Principal, [(Principal, Nat)])])>(size, ("", token, [],[]));
        size := 0;
        for ((k, v) in x.vals()) {
            let _token: TokenInfoExt = {
                id = v.id;
                name = v.name;
                symbol = v.symbol;
                decimals = v.decimals;
                fee = v.fee;
                totalSupply = v.totalSupply;
            };
            var allowances_size: Nat = v.allowances.size();
            var allowances_temp: [var (Principal, [(Principal, Nat)])] = Array.init<(Principal, [(Principal, Nat)])>(allowances_size, (owner, []));
            allowances_size := 0;
            for ((i,j) in v.allowances.entries()) {
                allowances_temp[allowances_size] := (i, Iter.toArray(j.entries()));
                allowances_size += 1;
            };
            let allowances_temp_ = Array.freeze(allowances_temp);
            res_temp[size] := (k, _token, Iter.toArray(v.balances.entries()), allowances_temp_);
            size += 1;
        };
        return Array.freeze(res_temp);
    };

    private func arrayToMap(x: [(Text, TokenInfoExt, [(Principal, Nat)], [(Principal, [(Principal, Nat)])])]) : [(Text, TokenInfo)] {
        var _token: TokenInfo = {
            id = "";
            var name = "";
            var symbol = "";
            var decimals = 0;
            var fee = 0;
            var totalSupply = 0;
            balances = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
            allowances = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>(1, Principal.equal, Principal.hash);
        };
        var size = x.size();
        var res_temp: [var (Text, TokenInfo)] = Array.init<(Text, TokenInfo)>(size, ("", _token));
        size := 0;
        for ((a, b, c, d) in x.vals()) {
            var map2_temp = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>(1, Principal.equal, Principal.hash);
            for ((k, v) in d.vals()) {
                let allowed_temp = HashMap.fromIter<Principal, Nat>(v.vals(), 1, Principal.equal, Principal.hash);
                map2_temp.put(k, allowed_temp);
            };
            let token: TokenInfo = {
                id = b.id;
                var name = b.name;
                var symbol = b.symbol;
                var decimals = b.decimals;
                var fee = b.fee;
                var totalSupply = b.totalSupply;
                balances = HashMap.fromIter<Principal, Nat>(c.vals(), 1, Principal.equal, Principal.hash);
                allowances = map2_temp;
            };
            res_temp[size] := (a, token);
            size += 1;
        };
        return Array.freeze(res_temp);
    };

    system func inspect({ caller : Principal; arg : Blob; 
       msg :
        {
            #addAuth : () -> Principal;
            #getAuthList : () -> ();
            #addLiquidity : () -> (Principal, Principal, Nat, Nat, Nat, Nat, Int);
            #addLiquidityForUser : () -> (Principal, Principal, Principal, Nat, Nat, Bool);
            #registerFundRecoveryForUser : () -> (Principal, Principal, Nat);
            #validateRegisterFundRecoveryForUser : () -> (Principal, Principal, Nat);
            #executeFundRecoveryForUser : () -> Principal;
            #validateExecuteFundRecoveryForUser : () -> Principal;
            #addLiquidityForUserTest : () -> (Principal, Principal, Principal, Nat, Nat);
            #addTokenValidate : () -> (Principal, Text);
            #addToken : () -> (Principal, Text);
            #updateTokenTypeValidate : () -> (Principal, Text);
            #updateTokenType : () -> (Principal, Text);
            #allowance : () -> (Text, Principal, Principal);
            #approve : () -> (Text, Principal, Nat);
            #balanceOf : () -> (Text, Principal);
            #burn : () -> (Text, Nat);
            #createPair : () -> (Principal, Principal);
            #decimals : () -> Text;
            #deposit : () -> (Principal, Nat);
            #depositTo : () -> (Principal, Principal, Nat);
            #exportBalances : () -> Text;
            #exportLPTokens : () -> ();
            #exportPairs : () -> ();
            #exportRewardInfo : () -> ();
            #exportRewardPairs : () -> ();
            #exportSubAccounts : () -> ();
            #exportSwapInfo : () -> ();
            #exportTokenTypes : () -> ();
            #exportTokens : () -> ();
            #getAllPairs : () -> ();
            #getAllRewardPairs : () -> ();
            #getICRC1SubAccountBalance : () -> (Principal, Text);
            #getHolders : () -> Text;
            #getHolderInfo : () -> Text;
            #getLPTokenId : () -> (Principal, Principal);
            #getNumPairs : () -> ();
            #getPair : () -> (Principal, Principal);
            #getPairs : () -> (Nat, Nat);
            #getSupportedTokenList : () -> ();
            #getSupportedTokenListByName : () -> (Text, Nat, Nat);
            #getSupportedTokenListSome : () -> (Nat, Nat);
            #getSwapInfo : () -> ();
            #getTokenMetadata : () -> Text;
            #getUserICRC1SubAccount : ()-> Principal;
            #getUserBalances : () -> Principal;
            #getUserInfo : () -> Principal;
            #getUserInfoAbove : () -> (Principal, Nat, Nat);
            #getUserInfoByNamePageAbove : () -> (Principal, Int, Text, Nat, Nat, Int, Text, Nat, Nat);
            #getUserLPBalances : () -> Principal;
            #getUserLPBalancesAbove : () -> (Principal, Nat);
            #getUserReward : () -> (Principal, Text, Text);
            #historySize : () -> ();
            #initiateICRC1Transfer : () -> ();
            #initiateICRC1TransferForUser : () -> Principal;
            #monitorMetrics : () -> ();
            #name : () -> Text;
            #removeAuth : () -> Principal;
            #removeLiquidity : () -> (Principal, Principal, Nat, Nat, Nat, Principal, Int);
            #migrateLiquidity : () -> (Principal, Principal, Principal, Principal); 
            #retryDeposit : () -> Principal;
            #retryDepositTo : () -> (Principal, Principal, Nat);
            #setFeeForToken : () -> (Text, Nat);
            #setFeeOn : () -> Bool;
            #setFeeTo : () -> Principal;
            #setGlobalTokenFee : () -> Nat;
            #setMaxTokenValidate : () -> Nat;
            #setMaxTokens : () -> Nat;
            #setOwner : () -> Principal;
            #swapExactTokensForTokens : () -> (Nat, Nat, [Text], Principal, Int);
            #symbol : () -> Text;
            #totalSupply : () -> Text;
            // #transfer : () -> (Text, Principal, Nat);
            #transferFrom : () -> (Text, Principal, Principal, Nat);
            #updateAllTokenMetadata : () -> ();
            #updateTokenFees : () -> ();
            #updateTokenMetadata : () -> Text;
            #withdraw : () -> (Principal, Nat);
            #withdrawTo : () -> (Principal, Principal);
            #getBlocklistedUsers : () -> ();
            #addUserToBlocklist : () -> Principal;
            #removeUserFromBlocklist : () -> Principal;
            #getBlockedTokens : () -> ();
            #addTokenToBlocklist : () -> (Principal, TokenBlockType);
            #addTokenToBlocklistValidate : () -> (Principal, TokenBlockType);
            #removeTokenFromBlocklist : () -> Principal;
            #removeTokenFromBlocklistValidate : () -> Principal;
            #setCapV2CanisterId : () -> Text;
            #getCapDetails : () -> ();
            #setCapV1EnableStatus : () -> Bool;
            #setCapV2EnableStatus : () -> Bool;
            #exportFaileWithdraws : () ->();
            #failedWithdrawRefund : () -> Text;
            #getLastTransactionOutAmount : () -> ();
            #addNatLabsToken:()->Text;
            #removeNatLabsToken:()->Text;
            #getNatLabsToken:()->();
            #log_test : () -> ();
            #log_test_ignore : () -> ();
            #setWICPMigration : () -> Bool;
            #getWICPMigration : () -> ();
        }}) : Bool 
        {
            if(_checkBlocklist(caller)){
                return false;
            };
            switch (msg) {                    

                //admin with (msg.caller == owner)
                case (#addAuth _) { (caller == owner) };
                case (#removeAuth _) { (caller == owner) };
                case (#setOwner _) { (caller == owner) };
                case (#setCapV2CanisterId _) { (caller == owner) };
                case (#setCapV1EnableStatus _) { (caller == owner) };
                case (#setCapV2EnableStatus _) { (caller == owner) };
                case (#setMaxTokenValidate _) { (caller == owner) };
                case (#setMaxTokens _) { (caller == owner) };
                case (#setFeeOn _) { (caller == owner) };
                case (#setFeeTo _) { (caller == owner) };
                case (#setGlobalTokenFee _) { (caller == owner) };
                case (#setFeeForToken _) { (caller == owner) };
                case (#updateTokenMetadata _) { (caller == owner) };
                case (#updateAllTokenMetadata _) { (caller == owner) };
                case (#updateTokenFees _) { (caller == owner) };   
                case (#addTokenValidate _) { (caller == owner) };
                case (#addToken _) { (caller == owner) };
                case (#updateTokenTypeValidate _) { (caller == owner) };
                case (#updateTokenType _) { (caller == owner) };
                // TODO : should use sns governance canister check
                case (#validateExecuteFundRecoveryForUser _) { true };
                case (#validateRegisterFundRecoveryForUser _) { true };                
                //admin with _checkAuth(msg.caller)
                case (#getICRC1SubAccountBalance _) { _checkAuth(caller) };
                case (#initiateICRC1TransferForUser _) { _checkAuth(caller) };
                case (#retryDepositTo _) { _checkAuth(caller) };
                case (#addLiquidityForUser _) { _checkAuth(caller) };
                case (#registerFundRecoveryForUser _) { _checkAuth(caller) };
                case (#executeFundRecoveryForUser _) { _checkAuth(caller) };
                case (#addLiquidityForUserTest _) { _checkAuth(caller) };
                case (#monitorMetrics _) { _checkAuth(caller) };  
                case (#getBlocklistedUsers _) { _checkAuth(caller) };
                case (#addUserToBlocklist _) { _checkAuth(caller) };
                case (#removeUserFromBlocklist _) { _checkAuth(caller) };
                case (#getBlockedTokens _) { _checkAuth(caller) };
                case (#addTokenToBlocklist _) { _checkAuth(caller) };
                case (#addTokenToBlocklistValidate _) { _checkAuth(caller) };
                case (#removeTokenFromBlocklist _) { _checkAuth(caller) };
                case (#removeTokenFromBlocklistValidate _) { _checkAuth(caller) };
                case (#failedWithdrawRefund _) { _checkAuth(caller) };           
                case (#addNatLabsToken _) { _checkAuth(caller) };
                case (#removeNatLabsToken _) { _checkAuth(caller) };
                case (#getNatLabsToken _){true;};        
                case (#log_test _) { _checkAuth(caller) };
                case (#log_test_ignore _) { _checkAuth(caller) };      

                //non-admin functions                
                case (#initiateICRC1Transfer _) { 
                    if(Principal.isAnonymous(caller)){
                        false
                    }
                    else{
                        true
                    };                 
                };
                case (#deposit d) { 
                    var tid: Text=Principal.toText(d().0);      
                    var value: Nat=d().1;
                    var fee: Nat=tokens.getFee(tid);    
                    if (tokens.hasToken(tid) == false or Principal.isAnonymous(caller) or Nat.less(value,fee)){
                        return false;
                    }   
                    else{
                        return true;
                    };
                };
                case (#depositTo d) { 
                    var tid: Text=Principal.toText(d().0);               
                    var to: Principal=d().1;
                    var value: Nat=d().2;
                    var fee: Nat=tokens.getFee(tid);
                    if (tokens.hasToken(tid) == false or Principal.isAnonymous(to) or Nat.less(value,fee) or Principal.isAnonymous(caller)){
                        return false;
                    }   
                    else{
                        return true;
                    };
                };
                case (#retryDeposit d) { 
                    var tid: Text=Principal.toText(d());               
                    if (tokens.hasToken(tid) == false or Principal.isAnonymous(caller)){
                        return false;
                    }   
                    else{
                        return true;
                    };
                };
                case (#withdraw d) { 
                    var tid: Text=Principal.toText(d().0);
                    var value: Nat=d().1;
                    var fee: Nat=tokens.getFee(tid);
                    if (tokens.hasToken(tid) == false or Principal.isAnonymous(caller) or Nat.less(value,fee)){
                        return false;
                    }   
                    else{
                        return true;
                    };
                };
                case (#withdrawTo d) { 
                    var tid: Text=Principal.toText(d().0);
                    if (tokens.hasToken(tid) == false){
                        return false;
                    }   
                    else{
                        return true;
                    };
                };
                case (#createPair d) { 
                    var token0: Principal=d().0;
                    var token1: Principal=d().1;
                    var tid0: Text=Principal.toText(token0);
                    var tid1: Text=Principal.toText(token1);
                    if(Principal.isAnonymous(caller)){
                        return false;
                    };
                    if(tid0 == tid1 or token0 == blackhole or token1 == blackhole){
                        return false;
                    };
                    if(tokens.hasToken(tid0) == false or tokens.hasToken(tid1) == false){
                        return false;
                    };
                    let (t0, t1) = Utils.sortTokens(tid0, tid1);
                    let pair_str = t0 # ":" # t1;
                    if (Option.isSome(pairs.get(pair_str)) or lptokens.hasToken(pair_str)){
                        return false;
                    }
                    else{
                        return true;
                    }
                };
                case (#addLiquidity d) {
                    var token0: Principal=d().0;
                    var token1: Principal=d().1;
                    var amount0Desired: Nat=d().2;
                    var amount1Desired: Nat=d().3;
                    var amount0Min: Nat=d().4;
                    var amount1Min: Nat=d().5;
                    var deadline: Int=d().6;

                    if(Principal.isAnonymous(caller)){
                        return false;
                    };
                    
                    if (amount0Desired == 0 or amount1Desired == 0)
                        return false;

                    let tid0: Text = Principal.toText(token0);
                    let tid1: Text = Principal.toText(token1);
                    switch(_getPair(tid0, tid1)) {
                        case(?p) { };
                        case(_) {
                            return false;
                        };
                    };
                    switch(_getlpToken(tid0, tid1)) {
                        case(?p) { };
                        case(_) { return false; };
                    };
                    return true;
                };
                case (#removeLiquidity d) {
                    var token0: Principal=d().0;
                    var token1: Principal=d().1;
                    var lpAmount: Nat=d().2;
                    var amount0Min: Nat=d().3;
                    var amount1Min: Nat=d().4;
                    var to: Principal=d().5;
                    var deadline: Int=d().6;

                    if(Principal.isAnonymous(caller) or lpAmount<=0){
                        return false;
                    };

                    let tid0: Text = Principal.toText(token0);
                    let tid1: Text = Principal.toText(token1);
                    switch(_getPair(tid0, tid1)) {
                        case(?p) { };
                        case(_) { return false; };
                    };
                    switch(_getlpToken(tid0, tid1)) {
                        case(?t) { };
                        case(_) { return false;  };
                    };
                    return true;
                };
                case (#swapExactTokensForTokens d) {
                    var amountIn: Nat=d().0;
                    var amountOutMin: Nat=d().1;
                    var path: [Text]=d().2;
                    var to: Principal=d().3;
                    var deadline: Int=d().4;

                    if(Principal.isAnonymous(caller) or amountIn<=0){
                        return false;
                    };
                    
                    return true;
                };
                case (#burn _) { 
                    if(Principal.isAnonymous(caller)){
                        false
                    }
                    else{
                        true
                    };                 
                };
                case (#migrateLiquidity d) {
                    var token0: Principal=d().1;
                    var token1: Principal=d().2;

                    if(_checkAuth(caller)==false){
                        return false;
                    };

                    let tid0: Text = Principal.toText(token0);
                    let tid1: Text = Principal.toText(token1);
                    switch(_getPair(tid0, tid1)) {
                        case(?p) { };
                        case(_) { return false; };
                    };
                    switch(_getlpToken(tid0, tid1)) {
                        case(?t) { };
                        case(_) { return false;  };
                    };
                    return true;
                };
                /*
                case (#transfer _) { 
                    if(Principal.isAnonymous(caller)){
                        false
                    }
                    else{
                        true
                    };                 
                };
                */
                case (#transferFrom _) { 
                    if(Principal.isAnonymous(caller)){
                        false
                    }
                    else{
                        true
                    };                 
                };
                case (#approve _) { 
                    if(Principal.isAnonymous(caller)){
                        false
                    }
                    else{
                        true
                    };                 
                };

                case (#setWICPMigration _)  { true };
                case (#getWICPMigration _)  { true };
                //query
                case (#getAuthList  _) { true };
                case (#getLPTokenId  _) { true };
                case (#getAllPairs _) { true };
                case (#getAllRewardPairs _) { true };
                case (#getPairs _) { true };
                case (#getNumPairs _) { true };
                case (#getTokenMetadata _) { true };
                case (#getSupportedTokenList _) { true };
                case (#getSupportedTokenListSome _) { true };
                case (#getSupportedTokenListByName _) { true };
                case (#getUserICRC1SubAccount _) { true };
                case (#getUserBalances _) { true };
                case (#getUserLPBalances _) { true };
                case (#getUserLPBalancesAbove _) { true };
                case (#getUserInfo _) { true };
                case (#getUserInfoAbove _) { true };
                case (#getUserInfoByNamePageAbove _) { true };
                case (#getSwapInfo _) { true };
                case (#getHolders _) { true };
                case (#getHolderInfo _) { true };
                case (#getPair _) { true };
                case (#getUserReward _) { true };
                case (#balanceOf _) { true };
                case (#allowance _) { true };
                case (#totalSupply _) { true };
                case (#name _) { true };
                case (#decimals _) { true };
                case (#symbol _) { true };
                case (#exportSwapInfo _) { true };
                case (#exportSubAccounts _) { true };
                case (#exportBalances _) { true };                
                case (#exportTokenTypes _) { true };
                case (#exportTokens _) { true };
                case (#exportLPTokens _) { true };
                case (#exportPairs _) { true };
                case (#exportRewardPairs _) { true };
                case (#exportRewardInfo _) { true };
                case (#getCapDetails _) { true };
                case (#historySize _) { true };
                case (#exportFaileWithdraws _) { true };
                case (#getLastTransactionOutAmount _) { true };
            }
        };

    system func preupgrade() {
        depositTransactionsEntries := Iter.toArray(depositTransactions.entries());
        userFundRecoveriesEntries := Iter.toArray(userFundRecoveries.entries());
        tokenTypeEntries := Iter.toArray(tokenTypes.entries());
        pairsEntries := Iter.toArray(pairs.entries());
        lptokensEntries := mapToArray(lptokens.getTokenInfoList());
        tokensEntries := mapToArray(tokens.getTokenInfoList());
        authsEntries := Iter.toArray(auths.entries());
        rewardPairsEntries := Iter.toArray(rewardPairs.entries());
        rewardTokenEntries := Iter.toArray(rewardTokens.entries());
        rewardInfoEntries := Iter.toArray(rewardInfo.entries());
        blocklistedUserEntries := Iter.toArray(blocklistedUsers.entries());
        faileWithdrawEntries := Iter.toArray(faileWithdraws.entries());
        tokenBlocklistEntries := Iter.toArray(tokenBlocklist.entries());
        natLabsTokenEntries := Iter.toArray(natLabsToken.entries());
    };

    system func postupgrade() {
        depositTransactions:= HashMap.fromIter<Principal, DepositSubAccounts>(depositTransactionsEntries.vals(), 1, Principal.equal, Principal.hash);
        userFundRecoveries := HashMap.fromIter<Principal, RecoveryDetails>(userFundRecoveriesEntries.vals(), 1, Principal.equal, Principal.hash);
        tokenTypes:= HashMap.fromIter<Text,Text>(tokenTypeEntries.vals(), 1, Text.equal, Text.hash);  
        pairs := HashMap.fromIter<Text, PairInfo>(pairsEntries.vals(), 1, Text.equal, Text.hash);
        lptokens := Tokens.Tokens(feeTo, arrayToMap(lptokensEntries));
        tokens := Tokens.Tokens(feeTo, arrayToMap(tokensEntries));
        auths := HashMap.fromIter<Principal, Bool>(authsEntries.vals(), 1, Principal.equal, Principal.hash);
        rewardPairs := HashMap.fromIter<Text, PairInfo>(rewardPairsEntries.vals(), 1, Text.equal, Text.hash);
        rewardTokens:= HashMap.fromIter<Text,RewardTokens>(rewardTokenEntries.vals(), 1, Text.equal, Text.hash);
        rewardInfo := HashMap.fromIter<Principal, [RewardInfo]>(rewardInfoEntries.vals(), 1, Principal.equal, Principal.hash);
        blocklistedUsers := HashMap.fromIter<Principal, Bool>(blocklistedUserEntries.vals(), 1, Principal.equal, Principal.hash);
        faileWithdraws := HashMap.fromIter<Text, WithdrawState>(faileWithdrawEntries.vals(), 1, Text.equal, Text.hash);
        tokenBlocklist := HashMap.fromIter<Principal, TokenBlockType>(tokenBlocklistEntries.vals(), 1, Principal.equal, Principal.hash);
        natLabsToken := HashMap.fromIter<Text, Bool>(natLabsTokenEntries.vals(), 1, Text.equal, Text.hash);
        lppattern := #text ":";
        depositTransactionsEntries := [];
        rewardPairsEntries := [];
        rewardTokenEntries := [];
        rewardInfoEntries := [];
        pairsEntries := [];
        lptokensEntries := [];
        tokensEntries := [];
        authsEntries := [];
        blocklistedUserEntries := [];
        faileWithdrawEntries := [];
        tokenBlocklistEntries := [];
        natLabsTokenEntries := [];
    };
};