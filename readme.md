# ERC1155 Exchange

## Dev

	npx nodemon --watch contracts --ext sol --exec npm run compile

	npx nodemon --exec npm run deploy

	npx nodemon --watch contracts --watch test --ext sol,js --exec npm run test

	node src/sripts.js

	# run tests and say result
	./test/run_test.sh

	# run test coverage and say result
	./test/run_test.sh cov
	./test/run_test.sh test ./test/test_ether_manager.js

### Ressources

Queue FIFO:
https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

https://medium.com/coinmonks/ethereum-solidity-memory-vs-storage-which-to-use-in-local-functions-72b593c3703a

## Features

 - limit orders
 - fees paid by taker and 1/3 fees bonus earn by maker
 - deposit and withdraw fee credits (ether)
 - withdraw bonus fee credits (ether)
 - withdraw ether

## TODO

- (abandoned) restrict the amount of ether (https://docs.soliditylang.org/en/v0.8.0/security-considerations.html#restrict-the-amount-of-ether)
- (abandoned) withdraw pattern, use OZ payment API
- (abandoned) pause mode: disable trading and withdrawals
- (abandoned) cancel order
