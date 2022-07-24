const { ethers, network } = require("hardhat");
const fs = require("fs");

const frontEndContractsFile = "../frontend/constants/networkMapping.json";
const frontEndAbiLocation = "../frontend/constants/";

module.exports = async function () {
    if (process.env.UPDATE_FRONT_END) {
        await updateAbi();
        await updateContractAddresses();
        console.log("Updated Frontend!!");
    }
};

async function updateAbi() {
    const stark = await ethers.getContract("Stark");
    const weth = await ethers.getContract("WETH");
    const contracts = [stark, weth];
    const strings = ["Stark.json", "Weth.json"];

    for (let i = 0; i < contracts.length; i++) {
        fs.writeFileSync(
            frontEndAbiLocation + strings[i],
            contracts[i].interface.format(ethers.utils.FormatTypes.json)
        );
    }
}

async function updateContractAddresses() {
    const stark = await ethers.getContract("Stark");
    const weth = await ethers.getContract("WETH");
    const wbtc = await ethers.getContract("WBTC");
    const dai = await ethers.getContract("DAI");
    const usdc = await ethers.getContract("USDC");
    const st = await ethers.getContract("ST");
    const chainId = network.config.chainId;
    const contractAddress = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"));

    const addresses = [
        stark.address,
        wbtc.address,
        weth.address,
        dai.address,
        usdc.address,
        st.address,
    ];
    const strings = ["Stark", "WBTC", "WETH", "DAI", "USDC", "ST"];

    for (let i = 0; i < addresses.length; i++) {
        contractAddress[strings[i]] = { [chainId]: [addresses[i]] };
    }

    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddress));
}

module.exports.tags = ["all", "frontend"];
