# ERC1155 Exchange

## Dev

	npx nodemon --watch contracts --ext sol --exec npm run compile

	npx nodemon --exec npm run deploy

	npx nodemon --watch contracts --watch test --ext sol,js --exec npm run test

	node src/sripts.js

### Ressources

Queue FIFO:
https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

https://medium.com/coinmonks/ethereum-solidity-memory-vs-storage-which-to-use-in-local-functions-72b593c3703a

## TODO

 - https://docs.soliditylang.org/en/v0.8.0/security-considerations.html#restrict-the-amount-of-ether
 - fix withdraw pattern, use OZ payment API
