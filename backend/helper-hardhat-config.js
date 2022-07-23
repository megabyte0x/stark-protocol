const networkConfig = {
    default: {
        name: "hardhat",
        keepersUpdateInterval: "30",
        tokenAddresses: [
            "0x8455471D6d4B2B260c5f31ec461A167Aa7CD1319",
            "0x231F96A75e9769eF0724BdCb2e65B4E5DF778da3",
            "0x96F0541be50739C24C7B163e49ad20661dbfA17b",
            "0xf3b0BF046a4CF537f8BCFD385ea6ec21d8Da02Fa",
            "0x2bd8A9Bd0eA5e7893E5B09692F5a6d499D4E4319",
        ],
        btcUsdPriceFeed: "0x007A22900a3B98143368Bd5906f8E17e9867581b",
        ethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
        daiUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        usdcUsdPriceFeed: "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0",
        starkTokenUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        keepersUpdateInterval: "30",
    },
    1337: {
        name: "localhost",
        tokenAddresses: [
            "0x049856981Fc63219c426fcFA88d214Bf21b67a0E",
            "0xd4ac619a9A98e25eB6c049a48f3e279dA06eC913",
            "0xceD3C86fC2EAeaDc8062197B651e757e10af43D5",
            "0xcF28B34984E0AAB55443a11fc0dF095C4492c69E",
            "0x5B183d403fB41208C5E90eb33903361a78641C7C",
        ],
        btcUsdPriceFeed: "0x007A22900a3B98143368Bd5906f8E17e9867581b",
        ethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
        daiUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        usdcUsdPriceFeed: "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0",
        starkTokenUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        keepersUpdateInterval: "30",
    },
    31337: {
        name: "localhost",
        tokenAddresses: [
            "0x049856981Fc63219c426fcFA88d214Bf21b67a0E",
            "0xd4ac619a9A98e25eB6c049a48f3e279dA06eC913",
            "0xceD3C86fC2EAeaDc8062197B651e757e10af43D5",
            "0xcF28B34984E0AAB55443a11fc0dF095C4492c69E",
            "0x5B183d403fB41208C5E90eb33903361a78641C7C",
        ],
        btcUsdPriceFeed: "0x007A22900a3B98143368Bd5906f8E17e9867581b",
        ethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
        daiUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        usdcUsdPriceFeed: "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0",
        starkTokenUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        keepersUpdateInterval: "30",
    },
    4: {
        name: "rinkeby",
        gasPrice: "10000000007",
        gasLimit: "50000000000",
        tokenAddresses: [
            "0xe7741e436d63d8CAF5AAAF2AEe6F789fc69bFbEe",
            "0x623a957272c015Fe4A3646874cCe78864945EAe2",
            "0x39C0b0ec96e7710D752f54f1fc309BC5Fec4F3d3",
            "0x4CaF57805DceB66BbB34f9aB44A6C5A906B03eE4",
            "0x53D9d56efBfD33B4Cecc3AcA7A70842864FC3a8A",
        ],
        btcUsdPriceFeed: "0xECe365B379E1dD183B20fc5f022230C044d51404",
        ethUsdPriceFeed: "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e",
        daiUsdPriceFeed: "0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
        usdcUsdPriceFeed: "0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
        starkTokenUsdPriceFeed: "0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
        keepersUpdateInterval: "30",
    },
    80001: {
        name: "mumbai",
        gasPrice: "10000000007",
        gasLimit: "50000000000",
        tokenAddresses: [
            "0xe83b16E5EDEd23f7e8276930D26D376d0b05b915",
            "0xc113cb45987F301081edc7A4ce0376525F573Aab",
            "0x6FFD350f9C705d58586Da02be32623D040f8976E",
            "0x74758d04BCE3Aee82e88335BB3212010Eb0B91A3",
            "0xD41D929D5eAa0aF3e89679950640bA6abB8e589b",
        ],
        btcUsdPriceFeed: "0x007A22900a3B98143368Bd5906f8E17e9867581b",
        ethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
        daiUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        usdcUsdPriceFeed: "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0",
        starkTokenUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        keepersUpdateInterval: "30",
    },
    3: {
        name: "ropsten",
        gasPrice: "10000000007",
        gasLimit: "50000000000",
        tokenAddresses: [
            "0xBF1006a495cdDc4386ef7C527D32D280aC700Bc9",
            "0x21C9303F872540f6A62FdAa5BCCCD7e093726aBD",
            "0xCa6547068B5C4A5eB2b7032ecf86bC51C2b2c8B6",
            "0xAfbC4baBe6f0179042cAbd82343eD118bc48EFeE",
            "0x93731772F93d3641437C3E6182fc91bcbd12AbC5",
        ],
        btcUsdPriceFeed: "0x007A22900a3B98143368Bd5906f8E17e9867581b",
        ethUsdPriceFeed: "0x0715A7794a1dc8e42615F059dD6e406A6594651A",
        daiUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        usdcUsdPriceFeed: "0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0",
        starkTokenUsdPriceFeed: "0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046",
        keepersUpdateInterval: "30",
    },
    1: {
        name: "mainnet",
        keepersUpdateInterval: "30",
    },
};

const developmentChains = ["hardhat", "localhost"];
const VERIFICATION_BLOCK_CONFIRMATIONS = 6;
const iWethContractAddress = "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619";

module.exports = {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
    iWethContractAddress,
};
