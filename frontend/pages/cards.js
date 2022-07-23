import Head from "next/head";
import Image from "next/image";
import styles from "../styles/Home.module.css";
import { useMoralis } from "react-moralis";
import { useEffect, useState } from "react";
import contractAddresses from "../constants/networkMapping.json";
import erc20Abi from "../constants/Weth.json";
import { ethers } from "ethers";
import { Card, Illustration } from "web3uikit";

export default function NoCollteral() {
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
                            <div
                                className="pt-12 pl-12 grid grid-cols-2 gap-4 place-content-center h-100"
                                style={{
                                    width: "600px",
                                    height: "600px"
                                }}
                            >
                                <Card
                                    description="Borrow from a lender directly"
                                    onClick={() => {}}
                                    title="P2P"
                                    tooltipText="Borrow from a lender directly"
                                >
                                    <div>
                                        <Illustration height="180px" logo="token" width="100%" />
                                    </div>
                                </Card>

                                <Card
                                    description="Take Guaranty from your friend so you can borrow"
                                    onClick={() => {}}
                                    title="Borrow with Guaranty"
                                    tooltipText="Take Guranty from your friend so you can borrow"
                                >
                                    <div>
                                        <Illustration
                                            height="180px"
                                            logo="confirmed"
                                            width="100%"
                                        />
                                    </div>
                                </Card>
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
