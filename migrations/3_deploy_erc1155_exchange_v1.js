const ERC1155ExchangeImplementationV1 = artifacts.require(
  "ERC1155ExchangeImplementationV1"
);

module.exports = function(deployer) {
  deployer.deploy(ERC1155ExchangeImplementationV1); // gas used: 3502763, ~~ $400
};
