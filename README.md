# Dead-Mans-Switch

**Objective**

A smart contract solution that functions as a vault with extras. The core part of the project is the smart contract as it handles all of the logic for the vault. Initialization handles assigning `msg.sender` to the `owner` variable. The `onlyOwner()` modifier secures nearly all functions on this contract except the `depositEthers()` function. As of this moment, the smart contract portion of this project FULLY WORKS and has been extensively tested in Remix for any vulnerabilities. 


**Current Functions:**

- `depositEthers` - As stated, this function receives a uint256 which is the ether amount the user tries to deposit, the vaultBalance is incremented and a Deposit event is emitted. This is the only function that doesn't have the `onlyOwner()` modifier as there can't be malicious code programmed into the deposited ethers.

- `depositTokens` - As with the above function, this accepts ERC-20 tokens. The token address is passed into the function along with an amount. The approval method exists in the front end of this dApp the contract will keep track of which tokens are stored in the contract using `tokenArray` and the `tokenWallet` mapping stores the token address and it's respective value. This also has an `onlyOwner()` modifier since ERC-20 tokens can be coded with malicious intent which is a major vulnerability of this project. By limiting deposits to the owner, each token deposited on the contract will be something that was deliberately done by a safe party.

*IMPORTANT: If the depositTokens function isn't used in the front end, it will not count the tokens correctly per the 'tokenWallet' which will later affect the Ping function should funds need to be extracted.*

- `withdrawEthers` - Checks if requested withdraw amount is valid, subtracts the requested amount from the balance, and forwards the ethers to the designated `distAddress`. A Withdrawn event is emitted.

- `withdrawTokens` - Checks the balanceOf the specific token address that is passed to the function. If valid, the function will `safeTransfer` all of the token to the `distAddress`

- `Ping` - This function REQUIRES for the `distAddress` as well as the `timePeriod` to work properly. You set the distAddress to wherever you'd want the funds to be sent and the timePeriod is customizable for your needs (it goes by seconds, 60 = 1 min, 3600 = 1 hour, etc). The default `timePeriod` would begin as `block.timestamp + 12 weeks` but the arbitrary waiting period can be changed modified before the contract is deployed.  When the `else` condition of this function is met, all ERC-20 tokens and ether will be sent. The `tokenWallet` mapping and `tokenArray` will be cleared as well.

- `getBalance` and `getTokenBalance` are pretty self-explanatory. One returns the ethers/native currency balance and the other returns the balanceOf of a specific token contract

- `getTokenAddresses` returns an array of the ERC-20 token addresses currently stored on the smart contract.

- `getTimeperiod` returns the UNIX timestamp for when the contract is set to expire.

**What's In Progress:**

- Implement the external bot/script in JS that could be set to call the `ping()` function after a programmable amount of time has passed and the bot/script hasn't been "refreshed"
