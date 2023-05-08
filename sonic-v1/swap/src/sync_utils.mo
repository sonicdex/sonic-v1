import Tokens "./tokens";

module {

        public type TokenInfoExt = Tokens.TokenInfoExt;
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
        public type SwapActor = actor {
            exportTokens : () -> async [TokenInfoExt];
            exportLPTokens : () -> async [TokenInfoExt];
            exportPairs : () -> async [PairInfoExt];
            exportBalances : () -> async [PairInfoExt];
        };
};