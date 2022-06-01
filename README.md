# Dead-Mans-Switch

**Objective**

A smart contract solution in the event that you lose access to the private keys of a wallet. Modular to adapt based on needs...but what does that exactly mean?

I had a couple of main motivations for making this project. My first was of course to make an unguided project as part of my portfolio so I can apply for jobs in the Web3 space. The other was a thought I had in regards to what happens to a person's funds on a wallet if something were to happen and they couldn't access it...

With that in mind, I thought of a smart contract vault. It would be able to receive the native currency on a chain as well as ERC-20 tokens. To fully accomplish the robustness of this system, it will take more than Solidity code and the Typescript front end I'm aiming for. I'll most likely have to code a bot/script in JS to trigger the ping() function in this contract as the ping() function would have to be called as there's no way to automate it strictly on the blockchain.

The end goal of this smart contract would be to become a smart contract vault that can receive ether or the native balance of the chain as well as ERC-20 compatible tokens. I'm also looking to implement functions that would deposit/withdraw funds from/to Curve Finance/Yearn Finance. The 'ideal' end game of the smart contract would be to accept native currency/ERC-20 tokens, deposit/withdraw to Curve/Yearn, have a script/bot coded in JS externally that could call the ping() function, and that ping() function would ultimately be able to:

1. Send all native currency/ERC-20 to the designated address
2. If need be, withdraw all funds in Curve/Yearn back to the smart contract to be forwarded to the designated address
3. Iterate over an array/data structure of all current tokens in the smart contract and a for-loop would send each token until the contract is empty; to guard against random airdrops, the function would have restrictions so each instance wouldn't become a honeypot


**Current Functions:**

- `depositEthers` - As stated, this function receives a uint256 which is the ether amount the user tries to deposit, the vaultBalance is incremented and a Deposit event is emitted

- `depositTokens` - As with the above function, this accepts tokens. The token address is passed into the function along with an amount. This function can approve the tokens by calling the IERC20 implementation, transfer the tokens from the user's wallet, and then decreases the 'allowance' the user approved the contract. `safeDecreaseAllowance` would benefit the end user. Emits a `DepositTokens` event. 

- `withdrawEthers` - Checks if requested withdraw amount is valid, subtracts the requested amount from the balance, and forwards the ethers to the designated `distAddress`. A Withdrawn event is emitted.

- `withdrawTokens` - Checks the balanceOf the specific token address that is passed to the function. If valid, the function will `safeTransfer` all of the token to the `distAddress`

- `Ping` - This function needs to be called to keep the `timePeriod` variable from expiring. When/if that variable expires, the contract ethers balance will be forwarded to the `distAddress`. If the `timePeriod` is still valid, the `pingActive` bool will remain true and the timePeriod will be refreshed with `block.timestamp + 12 weeks` in which the latter time can be customizable based on needs.

- `getBalance` and `getTokenBalance` are pretty self-explanatory. One returns the ethers/native currency balance and the other returns the balanceOf of a specific token contract

**What's In Progress:**
