const Web3 = require('web3');
const truffleContract = require("@truffle/contract");

const { send } = require('./utils');

const uri = "http://localhost:8545";
const web3 = new Web3(uri);
const provider = new Web3.providers.HttpProvider(uri);
const ADR = '0x376d75F6C0D9E693D1b3817241bfEd7e84a484Cc'

async function test() {
    const data = require("../build/contracts/Test.json");

    console.log("gasLimit: " + (await web3.eth.getBlock('latest')).gasLimit);

    var contract = truffleContract(data);
    contract.setProvider(provider);

    const instance = new web3.eth.Contract(
        data.abi,
        (await contract.deployed()).address
    );

    let r = await instance.methods.getFirst().call()
    console.log(r);

    // await send(instance.methods.insertTree(2), ADR)
    await send(instance.methods.batch(41), ADR) // fail at 42, Exceeds block gas limit 

}

test()
