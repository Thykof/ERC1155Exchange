const ERC1155Tokens = artifacts.require("ERC1155Tokens");

module.exports = function(deployer) {
  deployer.deploy(ERC1155Tokens);
};
