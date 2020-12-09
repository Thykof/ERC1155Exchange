'use strict'
const HDWalletProvider = require('@truffle/hdwallet-provider');
const BigNumber = require('bignumber.js');
const process = require('process');
const Web3 = require('web3');

const API_QUOTE_URL = 'https://api.0x.org/swap/v1/quote';
const { MNEMONIC, RPC_URL } = process.env;

const GAS_LIMIT = new BigNumber(6721975);

function createQueryString(params) {
    return Object.entries(params).map(([k, v]) => `${k}=${v}`).join('&');
}

// Wait for a web3 tx `send()` call to be mined and return the receipt.
function waitForTxSuccess(tx) {
    return new Promise((accept, reject) => {
        try {
            tx.on('error', err => reject(err));
            tx.on('receipt', receipt => accept(receipt));
        } catch (err) {
            reject(err);
        }
    });
}

function createProvider() {
    const provider = /^ws?:\/\//.test(RPC_URL)
        ? new Web3.providers.WebsocketProvider(RPC_URL)
        : new Web3.providers.HttpProvider(RPC_URL);
    if (!MNEMONIC) {
        return provider;
    }
    return new HDWalletProvider({ mnemonic: MNEMONIC, providerOrUrl: provider });
}

function createWeb3() {
    return new Web3(createProvider());
}

function etherToWei(etherAmount) {
    return new BigNumber(etherAmount)
        .times('1e18')
        .integerValue()
        .toString(10);
}

function weiToEther(weiAmount) {
    return new BigNumber(weiAmount)
        .div('1e18')
        .toString(10);
}

function send(tx, from) {
    return tx.estimateGas({
        from
    }).then(gasAmount => {
        // gasAmount = gasAmount * new BigNumber(1.1) <= GAS_LIMIT
        //     ? gasAmount * new BigNumber(1.1)
        //     : GAS_LIMIT;
        // gasAmount = new BigNumber(gasAmount);
        // gasAmount = gasAmount.integerValue().toNumber();
        console.log(gasAmount);
        // gas = gas < 100000 ? 100000 : gas
        let result = tx.send({ from, gas: gasAmount })
        return result;
    })
}

module.exports = {
    etherToWei,
    weiToEther,
    createWeb3,
    createQueryString,
    waitForTxSuccess,
    createProvider,
    send
};
