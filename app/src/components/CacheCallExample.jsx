import React from 'react';

class CacheCallExample extends React.Component {
 state = { dataKey: null };

 componentDidMount() {
   const { drizzle } = this.props;
   const contract = drizzle.contracts.ERC1155Token;
   let dataKey = contract.methods["name"].cacheCall(); // declare this call to be cached and synchronized
   this.setState({ dataKey });
 }

 render() {
   const { ERC1155Token } = this.props.drizzleState.contracts;
   const displayData = ERC1155Token.name[this.state.dataKey]; // if displayData (an object) exists, then we can display the value below
   return (
     <p>Hi from Truffle! Here is your storedData: {displayData && displayData.value}</p>
   )
 }
}

export default CacheCallExample
