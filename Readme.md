#### **My homeworks for Etherium Solidity course from Sigma Software Academy**

1) Send 1 ETH to mentors wallet on Rinkeby network

2) There is a contract "Home" where we have a list of type "string", ATM there is only my name in the list, you should make your names also to appear there. For this purpose you should call function registerAsStudent in "Home" contract, which will take 100 Home tokens from your wallet under the hood. To get tokens there is a separate contract "Home Token Faucet". ABI of function is attached.
   Home token (has default ABI) -  https://rinkeby.etherscan.io/address/0xA8BFa2DEf58e0fce3c4293411249504C3AD9EbB4#code ,
   Home Token Faucet - part of ABI - [{"inputs": [],"name": "getTokens","outputs": [],"stateMutability": "nonpayable", "type": "function"}] - https://rinkeby.etherscan.io/address/0x3f586f62f4baeb081cc4861e82c7b27d51a8904d#code
   Home - part of ABI - [{ "inputs": [ { "internalType": "string", "name": "name", "type": "string" } ], "name": "registerAsStudent", "outputs": [], "stateMutability": "nonpayable", "type": "function" } ] - https://rinkeby.etherscan.io/address/0x0e822c71e628b20a35f8bcabe8c11f274246e64d
   
   HINT: if you are not familiar with ERC20 - look at approve/transferFrom
   
   + if you have free time left please  create a contract which will display the status of studentsList from this task, "red" if students < 10 etc.
   
3) Create your own ERC20 token in any way, the primeray goal is it should be ERC20 compatible. Write contract for selling it, so I would be able to buy your token for ETH. And also make so if there are not enough tokens ATM at the contract, the ETH should be returned to sender with a message "Sorry, there is not enough tokens to buy". The price of your token should be (current price)ETH/USD / registeredStudentsLength (from homework2). this is how you can get the price of ETH/USD  https://docs.chain.link/docs/get-the-latest-price/ 
4) No practical task.
5) +Add ability to bui your tokens not only with ETH but also for other tokens(for example stablecoin like this on rinkeby -  https://ethereum.stackexchange.com/questions/72388/does-rinkeby-have-a-faucet-where-i-can-fill-a-wallet-with-dai/80204 or any other, just tell where and how to get it), lets make a price of your token configurable, lets say it to be 1$;

   +Cover your exchange contract with unit tests, every function, so the coverage is 100%;
   
   +For the token you sell, create a pair on Uniswap v2 and add some liquidity(Token/ETH), so I will be able to sell your token for ETH
6) No practical task.
7) Add a restriction to your contract so only the owner of some NFT token can buy your tokens
8) Make your contract upgradeable
9) No practical task.
10) When user buys your token add getting of random number(Chainlink VRF) and use it as a multiplier when sending tokens to user. Multiplier could be from 0.5 to 3.0. Use this multiplier to multiply an amount of tokens to transfer to a user. The price of your token should be received not from priceFeed as before, but from any trusted API using chainlink oracles.
  