import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import logo from "./logo.png";

import AllContractData from './components/AllContractData'
import CacheCallExample from './components/CacheCallExample'
import ERC1155Token from "./build/contracts/ERC1155Token.json";

const { AccountData } = newContextComponents;

export default ({ drizzle, drizzleState }) => {
  // destructure drizzle and drizzleState from props
  return (
    <div className="App">
      <div>
        <img src={logo} alt="drizzle-logo" />
        <h1>Drizzle Examples</h1>
        <p>
          Examples of how to get started with Drizzle in various situations.
        </p>
      </div>

      <div className="section">
        <h2>Active Account</h2>
        <CacheCallExample
          drizzle={drizzle}
          drizzleState={drizzleState}
          accountIndex={0}
          units="ether"
          precision={3}
        />
      </div>
      <AllContractData
        drizzle={drizzle}
        drizzleState={drizzleState}
        contractName="ERC1155Token"
        abi={ERC1155Token.abi}
      />
    </div>
  );
};
