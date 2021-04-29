const Web3 = require('web3');
const truffleContract = require("@truffle/contract");

const { sendWithEstimateGas } = require('./utils');

const uri = "http://localhost:8545";
const web3 = new Web3(uri);
const provider = new Web3.providers.HttpProvider(uri);
const ADR1 = '0x6E35e016c521f7370C1fF6A398ac228137dd16D9'
const ADR2 = '0x6815C945E0F1525EA778a0bECCFc6e7ccc5BE91d'

const dataToken = require("../app/src/build/contracts/ERC1155Token.json");
const dataProxy = require("../app/src/build/contracts/ProxyAndStorageForERC1155Exchange.json");
const dataExchange = require("../app/src/build/contracts/ERC1155ExchangeImplementationV1.json");

async function prepareContract() {
    console.log("gasLimit: " + (await web3.eth.getBlock('latest')).gasLimit);

    var contract = truffleContract(dataToken);
    contract.setProvider(provider);

    const address = (await contract.deployed()).address
    const instance = new web3.eth.Contract(
        dataToken.abi,
        address
    );
    instance.address = address
    return instance
}

async function demoUsage() {
    instance = await prepareContract()

    let r;
    r = await sendWithEstimateGas(instance.methods.setApprovalForAll(ADR2, true), ADR1);
    console.log(`gasUsed: ${r.gasUsed}`);

    r = await instance.methods.isApprovedForAll(ADR1, ADR2).call();
    console.log(`isApprovedForAll: ${r}`);
}

demoUsage()

async function createExchange(tokenId, feeRate) {
    erc1155 = await prepareContract()
    const exchange = truffleContract(dataExchange);
    exchange.setProvider(provider);
    const exchangeAddress = (await exchange.deployed()).address

    const proxyExchange = truffleContract(dataProxy);
    proxyExchange.setProvider(provider);

    abiInitialize = dataExchange.abi.find(elt => {
        return elt.name === 'initialize'
    })

    // truffleContract instance
    const proxyInstance = await proxyExchange.new(
        exchangeAddress,
        web3.eth.abi.encodeFunctionCall(
            abiInitialize,
            [
                erc1155.address,
                tokenId,
                feeRate,
                ADR2 // operator allowed to change fee fee rate
            ]
        ),
        { from: ADR1 }
    )

    return [proxyInstance, exchangeAddress]
}

async function demoExchange(proxyInstance, exchangeAddress) {
    const proxyAddress = proxyInstance.address

    const exchangeImpl = truffleContract(dataExchange);
    exchangeImpl.setProvider(provider);
    const exchange = await exchangeImpl.at(proxyAddress)

    await exchange.setFeeRate(6, { from: ADR2 })
    const feeRate = await exchange.feeRate({ from: ADR2 })
    console.log(feeRate.toNumber());
}

async function demo() {
    let proxyInstance
    let exchangeAddress
    [proxyInstance, exchangeAddress] = await createExchange(13, 3)
    await demoExchange(proxyInstance, exchangeAddress)
    console.log('done');
}


demo()
