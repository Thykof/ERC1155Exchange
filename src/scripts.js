const Web3 = require('web3');
const truffleContract = require("@truffle/contract");

const { sendWithEstimateGas } = require('./utils');

const uri = "http://localhost:8545";
const web3 = new Web3(uri);
const provider = new Web3.providers.HttpProvider(uri);
const ADR1 = '0x376d75F6C0D9E693D1b3817241bfEd7e84a484Cc'
const ADR2 = '0x9EC8D1e50645F9Fe257D04b9F93C30358F725905'

async function test() {
    const data = require("../build/contracts/Test.json");

    console.log("gasLimit: " + (await web3.eth.getBlock('latest')).gasLimit);

    var contract = truffleContract(data);
    contract.setProvider(provider);

    const instance = new web3.eth.Contract(
        data.abi,
        (await contract.deployed()).address
    );


    // let tx = await send(instance.methods.newOrder(110, 5, ADR2), ADR1);
    // console.log(tx.events);
    for (let i = 0; i < 5; i++) {
        let r = await sendWithEstimateGas(instance.methods.newOrder(115, 10+i, ADR2), ADR1);
        console.log(`${r.gasUsed}`);
    }
    for (let i = 0; i < 5; i++) {
        let r = await sendWithEstimateGas(instance.methods.newOrder(150+i, 10, ADR2), ADR1);
        console.log(`${r.gasUsed}`);
    }

    let r = await instance.methods.getBestOrder().call();
    // let r = await instance.methods.getBestOrder().send({ from: ADR1 });
    console.log(r);
}

test()
