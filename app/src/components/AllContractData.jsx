import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData } = newContextComponents;

export default class AllContractData extends React.Component {
  updateState = () => {
    this.setState({
      viewFunctions: this.props.abi.filter(elt => {
        return (
          elt.type === 'function' &&
          elt.stateMutability === 'view'
        )
      })
    })
  }
  componentDidMount() {
    this.updateState()
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.abi !== prevProps.abi) {
      this.updateState()
    }
  }

  renderContractData = (func, idx) => { // or () => ?
    if (func.inputs.length === 0) {
      console.log(func);
      return (
        <li key={idx}>
          <ContractData
            drizzle={this.props.drizzle}
            drizzleState={this.props.drizzleState}
            contract={this.props.contractName}
            method={func.name}
          />
        </li>
      )
    } else {
      return (<p key={idx}>rien</p>)
    }
  }

  render() {
    if (!this.state || !this.state.viewFunctions) {
      return null
    }

    console.log(this.state.viewFunctions);

    return (
      <div className="App">
        <h2>Contract data</h2>
        <div className="section">
          <ul>
            {
              this.state.viewFunctions.map((func, idx) => {
                return this.renderContractData(func, idx)
              })
            }
          </ul>
        </div>
      </div>
    );
  }
}
