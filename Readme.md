#### **My homeworks for Etherium Solidity course from Sigma Software Academy**

1) Send 1 ETH to mentors wallet on Rinkeby network

2) There is a contract "Home" where we have a list of type "string", ATM there is only my name in the list, you should make your names also to appear there. For this purpose you should call function registerAsStudent in "Home" contract, which will take 100 Home tokens from your wallet under the hood. To get tokens there is a separate contract "Home Token Faucet". ABI of function is attached.
   Home token (has default ABI) -  https://rinkeby.etherscan.io/address/0xA8BFa2DEf58e0fce3c4293411249504C3AD9EbB4#code ,
   Home Token Faucet - part of ABI - [{"inputs": [],"name": "getTokens","outputs": [],"stateMutability": "nonpayable", "type": "function"}] - https://rinkeby.etherscan.io/address/0x3f586f62f4baeb081cc4861e82c7b27d51a8904d#code
   Home - part of ABI - [{ "inputs": [ { "internalType": "string", "name": "name", "type": "string" } ], "name": "registerAsStudent", "outputs": [], "stateMutability": "nonpayable", "type": "function" } ] - https://rinkeby.etherscan.io/address/0x0e822c71e628b20a35f8bcabe8c11f274246e64d
   
   HINT: if you are not familiar with ERC20 - look at approve/transferFrom
   
   + if you have free time left please  create a contract which will display the status of studentsList from this task, "red" if students < 10 etc.
   
3) Create your own ERC20 token in any way, the primeray goal is it should be ERC20 compatible. Write contract for selling it, so I would be able to buy your token for ETH. And also make so if there are not enough tokens ATM at the contract, the ETH should be returned to sender with a message "Sorry, there is not enough tokens to buy". The price of your token should be (current price)ETH/USD / registeredStudentsLength (from homework2). this is how you can get the price of ETH/USD  https://docs.chain.link/docs/get-the-latest-price/ 