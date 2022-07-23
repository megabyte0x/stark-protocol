import styles from "../styles/Home.module.css";
import { useMoralis } from "react-moralis";
import AvailableBorrowTable from "../components/AvailableBorrowTable";
import BorrowsTable from "../components/BorrowsTable";
<<<<<<< HEAD
import { useEffect, useState } from "react";
import contractAddresses from "../constants/networkMapping.json";
import erc20Abi from "../constants/Weth.json";
import { ethers } from "ethers";
=======
import { useEffect, useMemo, useState } from "react";
import contractAddresses from "../constants/networkMapping.json";
import erc20Abi from "../constants/Weth.json";
import { ethers } from "ethers";
import creditAbi from "../constants/CreditLogic.json";
import { Button } from "web3uikit";
import Link from "next/link";
import PendingGurantees from "../components/PendingGuarantees";
>>>>>>> 074c85e (frontend ready)

export default function NoCollateral() {
    const { isWeb3Enabled, chainId, account } = useMoralis();
    const [tokenBalances, setTokenBalances] = useState({});
    const [isFetching, setIsFetching] = useState(true);
<<<<<<< HEAD
    const tokenAddresses = [];
    const tokenNames = ["WBTC", "WETH", "DAI", "USDC", "ST"];

=======
    const [requests, setRequests] = useState([]);
    const tokenAddresses = [];
    const tokenNames = ["WBTC", "WETH", "DAI", "USDC", "ST"];

    async function fetchRequests() {
        try {
            console.log("fetching requests......");
            const { ethereum } = window;
            const provider = await new ethers.providers.Web3Provider(ethereum);
            const signer = await provider.getSigner();
            const contractAddress = await contractAddresses["CreditLogic"][parseInt(chainId)][0];
            const contract = await new ethers.Contract(contractAddress, creditAbi, signer);
            const borrowers = await contract.getBorrowers();
            const req = [];
            if (borrowers.length === 0) return;
            borrowers?.slice().map(async (borrower) => {
                const request = await contract.getGuarantyRequest(account, borrower);
                if (request && request.lender.toLowerCase() == account) {
                    console.log("request", request);
                    req.push(request);
                }
            });
            setRequests(req);
        } catch (e) {
            console.log("This error is comming from fetchRequests");
            console.log(e);
        }
    }

>>>>>>> 074c85e (frontend ready)
    async function getTokenAddreses() {
        for (let token of tokenNames) {
            tokenAddresses.push(contractAddresses[token][parseInt(chainId)][0]);
        }
    }

    async function fetchBalances() {
<<<<<<< HEAD
=======
        console.log("fetching balances......");
>>>>>>> 074c85e (frontend ready)
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

<<<<<<< HEAD
=======
    // const requestMemo = useMemo(() => {
    //     if (!isFetching) fetchRequests();
    // }, [isWeb3Enabled]);

    useEffect(() => {
        fetchRequests();
    }, [isWeb3Enabled]);

>>>>>>> 074c85e (frontend ready)
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
<<<<<<< HEAD
                                <div className=""></div>

                                <div className="h-40"></div>
=======
                                <div>
                                    <PendingGurantees />
                                </div>
                                <div className="h-80">
                                    <Link href="/chat">
                                        <Button
                                            text="Request Guaranty"
                                            theme="primary"
                                            size="large"
                                        />
                                    </Link>
                                </div>
>>>>>>> 074c85e (frontend ready)
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
