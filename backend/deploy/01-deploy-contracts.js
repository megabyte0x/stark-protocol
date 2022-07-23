const { network, ethers } = require("hardhat");
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

    const creditLogic = await deploy("CreditLogic", {
        from: deployer,
        log: true,
        args: [],
        waitConfirmations: waitConfirmations,
<<<<<<< HEAD
    })

    await stark.addAllowContracts(creditLogic.address);
    await creditLogic.setStarkAddress(stark.address);

    log("-------------------------");
    if (!developmentChains.includes(network.name)) {
        await verify(stark.address, args);
        await verify(creditLogic.address, []);

=======
    });

    log("-------------------------------------------------");

    const starkContract = await ethers.getContractAt("Stark", stark.address);
    const creditLogicContract = await ethers.getContractAt("CreditLogic", creditLogic.address);

    log("-------------------------------------------------");

    await starkContract.addAllowContracts(creditLogic.address);
    await creditLogicContract.setStarkAddress(stark.address);

    log("-------------------------------------------------");
    if (!developmentChains.includes(network.name)) {
        await verify(stark.address, args);
        await verify(creditLogic.address, []);
>>>>>>> 074c85e (frontend ready)
    }
};

module.exports.tags = ["all", "main"];
