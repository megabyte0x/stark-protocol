import styles from "../styles/Home.module.css";
import { useMoralis } from "react-moralis";
import AvailableBorrowTable from "../components/AvailableBorrowTable";
import BorrowsTable from "../components/BorrowsTable";
import { useEffect, useState } from "react";
import contractAddresses from "../constants/networkMapping.json";
import erc20Abi from "../constants/Weth.json";
import { ethers } from "ethers";

export default function NoCollateral() {
    const { isWeb3Enabled, chainId, account } = useMoralis();
    const [tokenBalances, setTokenBalances] = useState({});
    const [isFetching, setIsFetching] = useState(true);
    const tokenAddresses = [];
    const tokenNames = ["WBTC", "WETH", "DAI", "USDC", "ST"];

    async function getTokenAddreses() {
        for (let token of tokenNames) {
            tokenAddresses.push(contractAddresses[token][parseInt(chainId)][0]);
        }
    }

    async function fetchBalances() {
        const balances = [];
        try {
            const { ethereum } = window;
            const provider = await new ethers.providers.Web3Provider(ethereum);
            const signer = await provider.getSigner();
            for (let tokenAddress of tokenAddresses) {
                const contract = await new ethers.Contract(tokenAddress, erc20Abi, signer);
                const tokenBalance = await contract.balanceOf(account);
                balances.push(ethers.utils.formatEther(tokenBalance));
            }

            const allBalances = new Object();

            tokenNames.forEach((token, i) => {
                allBalances[token] = balances[i];
            });

            setTokenBalances(allBalances);
            setIsFetching(false);
        } catch (e) {
            console.log(e);
            console.log("Error is coming from fetchBalances");
        }
    }

    async function updateUI() {
        await getTokenAddreses();
        await fetchBalances();
    }

    useEffect(() => {
        if (isWeb3Enabled && chainId == 80001) {
            updateUI();
        }
    }, [isWeb3Enabled, tokenBalances]);

    return (
        <div>
            {isWeb3Enabled ? (
                <div>
                    {chainId == 80001 ? (
                        !isFetching ? (
                            <div className="p-4 grid grid-cols-2 gap-4 h-48">
                                <div className=""></div>

                                <div className="h-40"></div>
                                <div>
                                    <AvailableBorrowTable
                                        tokenBalances={tokenBalances}
                                        tokenAddresses={tokenAddresses}
                                        tokenNames={tokenNames}
                                        isFetching={isFetching}
                                    />
                                </div>
                                <div className="">
                                    <BorrowsTable
                                        tokenBalances={tokenBalances}
                                        tokenAddresses={tokenAddresses}
                                        tokenNames={tokenNames}
                                        isFetching={isFetching}
                                    />
                                </div>
                            </div>
                        ) : (
                            <div>Loading....</div>
                        )
                    ) : (
                        <div>Plz Connect to Polygon Mumbai testnet</div>
                    )}
                </div>
            ) : (
                <div>Please Connect Your Wallet</div>
            )}
        </div>
    );
}
