import A          "./Account";
import CRC32      "./CRC32";
import Hex        "./Hex";
import SHA224     "./SHA224";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat32      "mo:base/Nat32";
import Buffer     "mo:base/Buffer";
import Blob       "mo:base/Blob";
import Array      "mo:base/Array";
module {
    /// Get the min value of two input nature.
    public func min(x: Nat, y: Nat): Nat {
        if(x < y) {
            x
        } else {
            y
        }
    };

    public func sqrt(y: Nat): Nat {
        var z = 0;
        if (y > 3) {
            z := y;
            var x: Nat = y / 2 + 1;
            while (x < z) {
                z := x;
                x := (y / x + x) / 2;
            }
        } else if (y != 0) {
            z := 1;
        };
        z
    };

    public func sortTokens(tokenA: Text, tokenB: Text): (Text, Text) {
        if(Text.less(tokenA, tokenB)) {
            (tokenA, tokenB)
        } else {
            (tokenB, tokenA)
        }
    };

    public func quote(amount0: Nat, r0: Nat, r1: Nat): Nat {
        assert(amount0 > 0);
        assert(r0 > 0 and r1 > 0);
        return amount0 * r1 / r0;
    };

    public func getAmountOut(amountIn: Nat, reserveIn: Nat, reserveOut: Nat): Nat {
        var amountInWithFee = amountIn * 997;
        var numerator = amountInWithFee * reserveOut;
        var denominator = reserveIn * 1000 + amountInWithFee;
        numerator / denominator
    };

    public func getAmountIn(amountOut: Nat, reserveIn: Nat, reserveOut: Nat): Nat {
        var numerator: Nat = reserveIn * amountOut * 1000;
        var denominator: Nat = (reserveOut - amountOut) * 997;
        numerator / denominator + 1
    };

    public type GenerateSubaccountArgs = {
        caller : Principal;
        id : Nat;
    };

    public func generateSubaccount (args : GenerateSubaccountArgs) : Blob {
        let idHash = SHA224.Digest();
        // Length of domain separator
        idHash.write([0x0A]);
        // Domain separator
        idHash.write(Blob.toArray(Text.encodeUtf8("invoice-id")));
        // Counter as Nonce
        let idBytes = A.beBytes(Nat32.fromNat(args.id));
        idHash.write(idBytes);
        // Principal of caller
        idHash.write(Blob.toArray(Principal.toBlob(args.caller)));
        let hashSum = idHash.sum();
        let crc32Bytes = A.beBytes(CRC32.ofArray(hashSum));
        let buf = Buffer.Buffer<Nat8>(32);
        Blob.fromArray(Array.append(crc32Bytes, hashSum));
    };

    public func defaultSubAccount() : Blob { 
        var index : Nat8=0;  
        return Blob.fromArray([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,index]);
    };
};
