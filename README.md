# Dead-Mans-Switch
A smart contract solution in the event that you lose access to the private keys of a wallet. Modular to adapt based on needs...but what does that exactly mean?

I had a couple of main motivations for making this project. My first was of course to make an unguided project as part of my portfolio so I can apply for jobs in the Web3 space. The other was a thought I had in regards to what happens to a person's funds on a wallet if something were to happen and they couldn't access it...

With that in mind, I thought of a smart contract vault. It would be able to receive the native currency on a chain as well as ERC-20 tokens. To fully accomplish the robustness of this system, it will take more than Solidity code and the Typescript front end I'm aiming for. I'll most likely have to code a bot/script in JS to trigger the ping() function in this contract as the ping() function would have to be called as there's no way to automate it strictly on the blockchain.

The end goal of this smart contract would be to become a smart contract vault that can receive ether or the native balance of the chain as well as ERC-20 compatible tokens. I'm also looking to implement functions that would deposit/withdraw funds from/to Curve Finance/Yearn Finance. The 'ideal' end game of the smart contract would be to accept native currency/ERC-20 tokens, deposit/withdraw to Curve/Yearn, have a script/bot coded in JS externally that could call the ping() function, and that ping() function would ultimately be able to:

1. Send all native currency/ERC-20 to the designated address
2. If need be, withdraw all funds in Curve/Yearn back to the smart contract to be forwarded to the designated address
3. Iterate over an array/data structure of all current tokens in the smart contract and a for-loop would send each token until the contract is empty; to guard against random airdrops, the function would have restrictions so each instance wouldn't become a honeypot


Current Functions:


What's In Progress:
