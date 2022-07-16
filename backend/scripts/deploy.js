async function main() {
    const [deployerAcc] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployerAcc.address);

    // console.log("Account balance:", (await deployerAcc.getBalance()).toString());

    const Deployer = await ethers.getContractFactory("deployer_contract");
    const deployer = await Deployer.deploy();

    console.log("Deployer address:", deployer.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });