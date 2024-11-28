import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Bool "mo:base/Bool";

module {
    public type TokenInfo = {
        id: Text;
        var name: Text;
        var symbol: Text;
        var decimals: Nat8;
        var fee: Nat;
        var totalSupply: Nat;
        balances: HashMap.HashMap<Principal, Nat>;
        allowances: HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>;
    };

    public type TokenInfoExt = {
        id: Text;
        name: Text;
        symbol: Text;
        decimals: Nat8;
        fee: Nat;
        totalSupply: Nat;
    };

    public type TokenInfoWithType = {
        id: Text;
        name: Text;
        symbol: Text;
        decimals: Nat8;
        fee: Nat;
        totalSupply: Nat;
        tokenType:Text;
        blockStatus:Text
    };

    public type TokenAnalyticsInfo = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        fee: Nat;
        totalSupply: Nat;
    };

    public type TokenBlockType = {
        #Partial: Bool;
        #Full: Bool;
        #None:Bool
    };

    // type TxReceipt = Result.Result<Nat, {
    //     #TokenNotFound;
    //     #InsufficientBalance;
    //     #InsufficientAllowance;
    // }>;

    public class Tokens(feeTo_: Principal, tokenInfoList: [(Text, TokenInfo)]) {
        private var feeTo: Principal = feeTo_;
        private var tokens = HashMap.fromIter<Text, TokenInfo>(tokenInfoList.vals(), 1, Text.equal, Text.hash);

        // create a new token
        public func createToken(tokenId: Text, token: TokenInfo) : Bool {
            if (Option.isNull(tokens.get(tokenId)) == false) {
                return false;
            };
            tokens.put(tokenId, token);
            return true;
        };

        public func removeToken(tokenId: Text) : Bool {
            switch(tokens.get(tokenId)) {
                case(?token) {
                    tokens.delete(tokenId);
                    return true;
                };
                case(_) { return false; };
            };
        };

        public func setFee(tokenId: Text, newFee: Nat): Bool {
            switch(tokens.get(tokenId)) {
                case(?token) {
                    token.fee := newFee;
                    tokens.put(tokenId, token);
                    return true;
                };
                case(_) { return false; };
            };
        };

        public func setMetadata(tokenId: Text, name: Text, symbol: Text, decimals: Nat8, fee: Nat): Bool {
            switch(tokens.get(tokenId)) {
                case(?token) {
                    token.name := name;
                    token.symbol := symbol;
                    token.decimals := decimals;
                    token.fee := fee;
                    tokens.put(tokenId, token);
                    return true;
                };
                case(_) { return false; };
            };
        };

        public func getMetadata(tokenId: Text): TokenAnalyticsInfo {
            switch(tokens.get(tokenId)) {
                case(?token) {
                    return _toTokeAnalyticsInfo(token);
                };
                case(_) { return _toTokeAnalyticsInfoEmpty(tokenId); };
            };
        };

        public func getFee(tokenId: Text): Nat {
            switch(tokens.get(tokenId)) {
                case(?token) {
                    token.fee
                };
                case(_) { 0 };
            }
        };

        public func getNumTokens(): Nat {
            return tokens.size();
        };

        // public func getToken(tokenId: Text): TokenInfoExt {
            
        // };

        // public func getTokens(start: Nat, limit: Nat): [TokenInfoExt] {
        //     // sort by total supply first
        // };

        public func getTokenInfoList(): [(Text, TokenInfo)] {
            return Iter.toArray(tokens.entries());
        };

        private func _toTokenInfoExt(info: TokenInfo): TokenInfoExt {
            {
                id = info.id;
                name = info.name;
                symbol = info.symbol;
                decimals = info.decimals;
                fee = info.fee;
                totalSupply = info.totalSupply;
            }
        };

        private func _toTokeAnalyticsInfo(info: TokenInfo): TokenAnalyticsInfo {
            {
                name = info.name;
                symbol = info.symbol;
                decimals = info.decimals;
                fee = info.fee;
                totalSupply = info.totalSupply;
            }
        };

        private func _toTokeAnalyticsInfoEmpty(tokenId: Text): TokenAnalyticsInfo {
            {
                name = tokenId;
                symbol = "";
                decimals = 0;
                fee = 0;
                totalSupply = 0;
            }
        };

        private func _toTokenInfoWithType(info: TokenInfo, tokenType:?Text, tokenBlocklist:HashMap.HashMap<Principal, TokenBlockType>): TokenInfoWithType {
            {
                id = info.id;
                name = info.name;
                symbol = info.symbol;
                decimals = info.decimals;
                fee = info.fee;
                totalSupply = info.totalSupply;
                tokenType=if(Option.isNull(tokenType)==true){"DIP20"}else{Option.unwrap(tokenType)};
                blockStatus=isTokenBlocked(Principal.fromText(info.id), tokenBlocklist);
            }
        };

        public func tokenListWithType(tokenTypes: HashMap.HashMap<Text, Text>, tokenBlocklist :HashMap.HashMap<Principal, TokenBlockType>) : [TokenInfoWithType] {
            var ret: [TokenInfoWithType] = [];
            for((k, v) in tokens.entries()) {               
                ret := Array.append(ret, [_toTokenInfoWithType(v,tokenTypes.get(k), tokenBlocklist)]);
            };
            return ret;
        };

        private func isTokenBlocked(tokenId: Principal, tokenBlocklist:HashMap.HashMap<Principal, TokenBlockType>): Text{
            switch(tokenBlocklist.get(tokenId)){
                case(?blockType){
                    switch(blockType)
                    {
                        case(#Full(d)){
                            return "Full";
                        };
                        case(#Partial(d)){
                            return "Partial";
                        };
                        case(_){
                            return "None";
                        };
                    };   
                };
                case(_){
                    return "None";
                }
            }
        };

        public func tokenList() : [TokenInfoExt] {
            var ret: [TokenInfoExt] = [];
            for((k, v) in tokens.entries()) {
                ret := Array.append(ret, [_toTokenInfoExt(v)]);
            };
            return ret;
        };

        public func tokenListByName(t: Text) : [TokenInfoExt] {
            var ret: [TokenInfoExt] = [];
            let p = #text t;
            for ((k, v) in tokens.entries()) {
                if (Text.contains(v.name, p) or Text.contains(v.symbol, p)) {
                    ret := Array.append(ret, [_toTokenInfoExt(v)]);
                };
            };
            return ret;
        };

        public func hasToken(tokenId: Text): Bool {
            return Option.isSome(tokens.get(tokenId));
        };

        public func getBalances(user: Principal): [(Text, Nat)] {
            var ret: [(Text, Nat)] = [];
            for((k, v) in tokens.entries()) {
                let bal: Nat = switch (v.balances.get(user)) {
                    case (?balance) {
                        balance
                    };
                    case (_) {
                        0
                    };
                };
                ret := Array.append(ret, [(k, bal)]);
            };
            return ret;
        };

        public func getTokenBalances(tokenId:Text, user: Principal): Nat {
            return _balanceOf(tokenId, user);
        };

        public func getBalancesAbove(user: Principal, above: Nat): [(Text, Nat)] {
            var ret: [(Text, Nat)] = [];
            label l for((k, v) in tokens.entries()) {
                switch (v.balances.get(user)) {
                    case (?balance) {
                        if (balance > above) { ret := Array.append(ret, [(k, balance)]); }
                    };
                    case (_) {
                        continue l;
                    };
                };                
            };
            return ret;
        };

        public func getBalancesByNamePageAbove(user: Principal, above: Int, t: Text, start: Nat, num: Nat): ([(Text, Nat)], Nat) {
            var temp: [(Text, Nat)] = [];
            let p : Text.Pattern = #text t;
            for ((k, v) in tokens.entries()) {
                switch (v.balances.get(user)) {
                    case (?balance) {
                        if ((Text.contains(v.name, p) or Text.contains(v.symbol, p)) and bigger(balance, above)) {
                            temp := Array.append(temp, [(k, balance)]);
                        };
                    };
                    case (_) {
                        if ((above < 0) and (Text.contains(v.name, p) or Text.contains(v.symbol, p))) {
                            temp := Array.append(temp, [(k, 0)]);
                        };
                    };
                };                
            };
            var ret: [(Text, Nat)] = [];
            let limit: Nat = if(start + num > temp.size()) {
                temp.size() - start
            } else {
                num
            };
            for (i in Iter.range(0, limit-1)) {
                ret := Array.append<(Text, Nat)>(ret, [temp[start+i]]);
            };
            (ret, temp.size())
        };

        public func bigger(a: Nat, b: Int) : Bool {
            if (b < 0) {
                return true;
            } else {
                let c = Int.abs(b);
                return a > c;
            };
        };

        private func _chargeFee(tokenId: Text, from: Principal, fee: Nat) {
            if(fee > 0) {
                ignore _transfer(tokenId, from, feeTo, fee);
            };
        };

        public func getTokenInfo(tokenId: Text): ?TokenInfo {
            return tokens.get(tokenId);
        };

        private func _transfer(tokenId: Text, from: Principal, to: Principal, value: Nat): Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            let from_balance = _balanceOf(tokenId, from);
            let from_balance_new: Nat = from_balance - value;
            if(from_balance_new != 0) {
                token.balances.put(from, from_balance_new);
            } else {
                token.balances.delete(from);
            };
            let to_balance = _balanceOf(tokenId, to);
            let to_balance_new: Nat = to_balance + value;
            if(to_balance_new != 0) {
                token.balances.put(to, to_balance_new);
            };
            tokens.put(tokenId, token);
            return true;
        };

        private func _balanceOf(tokenId: Text, who: Principal) : Nat {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return 0; };
            };
            switch (token.balances.get(who)) {
                case (?balance) { return balance; };
                case (_) { return 0; };
            }
        };

        private func _allowance(tokenId: Text, owner: Principal, spender: Principal) : Nat {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return 0; };
            };
            switch(token.allowances.get(owner)) {
                case (?allowance_owner) {
                    switch(allowance_owner.get(spender)) {
                        case (?allowance) { return allowance; };
                        case (_) { return 0; };
                    }
                };
                case (_) { return 0; };
            }
        };

        public func mint(tokenId: Text, caller: Principal, value: Nat) : Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            if(value < token.fee) { return false; };
            let bal = _balanceOf(tokenId, caller);
            let bal_new: Nat = bal + value;
            assert(bal_new >= bal);
            token.balances.put(caller, bal_new);
            token.totalSupply += value;
            tokens.put(tokenId, token);
            return true;
        };

        public func burn(tokenId: Text, caller: Principal, value: Nat) : Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            let bal = _balanceOf(tokenId, caller);
            if(bal < value or bal < token.fee or value < token.fee) { return false; };
            let bal_new: Nat = bal - value;
            assert(bal_new <= bal);
            token.balances.put(caller, bal_new);
            token.totalSupply -= value;
            tokens.put(tokenId, token);
            return true;
        };

        public func transfer(tokenId: Text, caller: Principal, to: Principal, value: Nat) : Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            let from_balance = _balanceOf(tokenId, caller);
            if(from_balance < token.fee + value) {
                return false;
            };
            _chargeFee(tokenId, caller, token.fee);
            return _transfer(tokenId, caller, to, value);
        };

        public func zeroFeeTransfer(tokenId: Text, caller: Principal, to: Principal, value: Nat) : Bool {
            return _transfer(tokenId, caller, to, value);
        };

        public func transferFrom(tokenId: Text, caller: Principal, from: Principal, to: Principal, value: Nat) : Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            let from_balance = _balanceOf(tokenId, from);
            let allowance_ = _allowance(tokenId, from, caller);
            if(from_balance < value + token.fee or allowance_ < value or value < token.fee) {
                return false;
            };
            _chargeFee(tokenId, from, token.fee);
            ignore _transfer(tokenId, from, to, value);
            switch(token.allowances.get(from)) {
                case(?allowance_from) {
                    switch(allowance_from.get(caller)) {
                        case(?allowance) {
                            allowance_from.put(caller, allowance - value);
                            token.allowances.put(from, allowance_from);
                            tokens.put(tokenId, token);
                            return true;
                        };
                        case(_) { return false; };
                    };
                };
                case(_) { return false; }
            };
        };

        public func approve(tokenId: Text, caller: Principal, spender: Principal, value: Nat) : Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            var bal = _balanceOf(tokenId, caller);
            if(bal < token.fee) {
                return false;
            };
            _chargeFee(tokenId, caller, token.fee);
            switch(token.allowances.get(caller)) {
                case (?allowances_caller) {
                    allowances_caller.put(spender, value);
                    token.allowances.put(caller, allowances_caller);
                    tokens.put(tokenId, token);
                    return true;
                };
                case (_) {
                    var temp = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
                    temp.put(spender, value);
                    token.allowances.put(caller, temp);
                    tokens.put(tokenId, token);
                    return true;
                };
            }
        };

        public func zeroFeeApprove(tokenId: Text, caller: Principal, spender: Principal, value: Nat) : Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            var bal = _balanceOf(tokenId, caller);
            if(bal < token.fee) {
                return false;
            };
            switch(token.allowances.get(caller)) {
                case (?allowances_caller) {
                    allowances_caller.put(spender, value);
                    token.allowances.put(caller, allowances_caller);
                    tokens.put(tokenId, token);
                    return true;
                };
                case (_) {
                    var temp = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
                    temp.put(spender, value);
                    token.allowances.put(caller, temp);
                    tokens.put(tokenId, token);
                    return true;
                };
            }
        };

        public func removeAllowances(tokenId: Text, caller: Principal, spender: Principal, value: Nat) : Bool {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return false; };
            };
            switch(token.allowances.get(caller)) {
                case (?allowances_caller) {
                    allowances_caller.put(spender, value);
                    token.allowances.put(caller, allowances_caller);
                    tokens.put(tokenId, token);
                    return true;
                };
                case (_) {
                    return false;
                };
            }
        };

        public func balanceOf(tokenId: Text, who: Principal) : Nat {
            return _balanceOf(tokenId, who);
        };

        public func allowance(tokenId: Text, owner: Principal, spender: Principal) : Nat {
            return _allowance(tokenId, owner, spender);
        };

        public func totalSupply(tokenId: Text) : Nat {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return 0; };
            };
            return token.totalSupply;
        };    

        public func name(tokenId: Text) : Text {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return ""; };
            };
            return token.name;
        };

        public func decimals(tokenId: Text) : Nat8 {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return 0; };
            };
            return token.decimals;
        };

        public func symbol(tokenId: Text) : Text {
            var token = switch (tokens.get(tokenId)) {
                case (?_token) { _token; };
                case (_) { return ""; };
            };
            return token.symbol;
        };    
    };    
};