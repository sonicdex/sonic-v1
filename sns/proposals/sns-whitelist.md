This proposal offers the Sonic Platform to the NNS to be turned into a decentralized service by creation of an SNS to govern the Sonic Dapp canisters.  

### Who sent this proposal ?  

This proposal is sent by the Sonic development team. Sonic is a [fully on-chain ](https://app.sonic.ooo) and [open source](https://github.com/sonicdex) Defi platform running end-to-end on the Internet Computer. The project is presented in [this whitepaper](https://sonicdex.gitbook.io/sonic-whitepaper/).

### What is the purpose of this proposal?  

The Sonic development team offers the Sonic app to the NNS to be turned into a decentralized service by creation of a [Service Nervous System (SNS) DAO](https://internetcomputer.org/sns) to govern Sonic. The Sonic platform consists of 3 dapp canisters and 2 asset canisters. The following Sonic canisters would be directly controlled by the SNS: 

sonic swap canister `3xwpq-ziaaa-aaaah-qcn4a-cai`   
sonic swap FE asset canister `eukbz-7iaaa-aaaah-ac5tq-cai`  
sonic analytics FE asset canister `fxgi7-lqaaa-aaaah-ac5va-cai`  
wicp canister `utozz-siaaa-aaaam-qaaxq-cai`  
xtc canister `aanaa-xaaaa-aaaah-aaeiq-cai`  


All of the other canisters are in turn controlled by one of the above listed canisters and would thus also be indirectly controlled by the SNS.  

If this proposal is approved, the NNS mandates that the necessary steps to create a [Service Nervous System (SNS) DAO](https://internetcomputer.org/sns) to govern Sonic are taken.   

### What is the technical effect of this proposal?  

By adopting the proposal, Sonic will be required to install the necessary SNS canisters on the SNS subnet. These canisters will initially be in a pre-decentralization-sale mode, limiting their capabilities and preventing token movement until the decentralization sale is finalized. Essentially, the proposal grants the cycles wallet, with principal ID `tu57s-7iaaa-aaaal-achra-cai` and controlled by Sonic, the ability to make a call to the SNS wasm modules canister (SNS-W) for the purpose of installing SNS canisters. This privilege is a one-time occurrence, as it will be revoked after the call is made.    

### What is this proposal not about / what will be decided in a second, future proposal?  

This proposal does not address specific aspects such as parameter choices for the Sonic SNS. Those details will be covered in a separate future proposal. The upcoming proposal will focus on initiating the Sonic decentralization sale and establishing the SNS DAO. It will encompass decisions related to parameter choices, conditions for the decentralization sale, and other pertinent matters. 
