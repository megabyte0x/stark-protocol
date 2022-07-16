const { network } = require("hardhat");
const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deployer } = await getNamedAccounts();
    const { deploy, log } = deployments;
    const chainId = network.config.chainId;
    const waitConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS;

    const args = [
        networkConfig[chainId]["tokenAddresses"],
        [
            networkConfig[chainId]["btcUsdPriceFeed"],
            networkConfig[chainId]["ethUsdPriceFeed"],
            networkConfig[chainId]["daiUsdPriceFeed"],
            networkConfig[chainId]["usdcUsdPriceFeed"],
            networkConfig[chainId]["starkTokenUsdPriceFeed"],
        ],
        networkConfig[chainId]["keepersUpdateInterval"],
    ];

    const stark = await deploy("Stark", {
        from: deployer,
        log: true,
        args: args,
        waitConfirmations: waitConfirmations,
    });

    log("-------------------------");
    if (!developmentChains.includes(network.name)) {
        await verify(stark.address, args);
    }
};

module.exports.tags = ["all", "main"];
