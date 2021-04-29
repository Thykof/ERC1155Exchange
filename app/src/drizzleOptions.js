import Web3 from "web3";
import ERC1155Token from "./build/contracts/ERC1155Token.json";

const options = {
  web3: {
    block: false,
    customProvider: new Web3("ws://localhost:8545"),
  },
  contracts: [ERC1155Token],
  events: {
    ERC1155Token: ["ApprovalForAll"],
  },
};

export default options;
