import styles from "../styles/Home.module.css";
import { useMoralis } from "react-moralis";
import AvailableBorrowTable from "../components/AvailableBorrowTable";
import BorrowsTable from "../components/BorrowsTable";
import { useEffect, useMemo, useState } from "react";
import contractAddresses from "../constants/networkMapping.json";
import erc20Abi from "../constants/Weth.json";
import { ethers } from "ethers";
import creditAbi from "../constants/CreditLogic.json";
import { Button } from "web3uikit";
import Link from "next/link";

export default function PendingGurantees() {
    const { isWeb3Enabled, chainId, account } = useMoralis();
    const [requests, setRequests] = useState([]);
    const [isFetching, setIsFetching] = useState(true);
    const [index, setIndex] = useState(0);
    const [buttonDisabled, setButtonDisabled] = useState(false);

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
            let prevBorrower = "";
            borrowers?.slice().map(async (borrower) => {
                console.log(prevBorrower != borrower);
                console.log("prevBorrower", prevBorrower);
                console.log("borrower", borrower);
                const request = await contract.getGuarantyRequest(account, borrower);
                if (
                    request &&
                    request.lender.toLowerCase() == account &&
                    !request.requestAccepted &&
                    prevBorrower != borrower
                ) {
                    console.log("request", request);
                    req.push(request);
                    prevBorrower = borrower;
                }
            });
            setRequests(req);
            setIsFetching(false);
        } catch (e) {
            console.log("This error is comming from fetchRequests");
            console.log(e);
        }
    }

    async function acceptGuaranty() {
        try {
            setButtonDisabled(true);
            console.log("accepting request......");
            const { ethereum } = window;
            const provider = await new ethers.providers.Web3Provider(ethereum);
            const signer = await provider.getSigner();
            const contractAddress = await contractAddresses["CreditLogic"][parseInt(chainId)][0];
            const contract = await new ethers.Contract(contractAddress, creditAbi, signer);
            const req = requests[index];
            console.log("accepting...");
            const tx = await contract.guarantyAcceptRequest(req.borrower);
            const txReceipt = await tx.wait(1);
            if (txReceipt.status == 1) {
                console.log("Accepted!");
                handleAcceptedSuccess();
            }
            setButtonDisabled(false);
        } catch (e) {
            console.log("This error is comming from acceptGuaranty");
            console.log(e);
            setButtonDisabled(false);
        }
    }

    const handleAcceptedSuccess = async function () {
        dispatch({
            type: "success",
            title: "Requested!",
            message: "Guaranty given to your fren",
            position: "topR",
        });
    };

    useEffect(() => {
        fetchRequests();
    }, [isWeb3Enabled]);

    return (
        <div>
            <div className="pl-4 font-semibold text-2xl text-gray-500">Pending requests</div>
            {requests.length != 0 && !isFetching ? (
                requests.map((req, i) => {
                    if (i < requests.length - 2) return;
                    return (
                        <div className="p-4">
                            <div>Request from: {req.borrower}</div>
                            <div>Amount: {ethers.utils.formatEther(req.totalAmount)} ETH</div>
                            <div>Rented Until: {parseInt(req.timeRentedUntil)} months</div>
                            <div>
                                <Button
                                    text="Accept"
                                    theme="primary"
                                    size="small"
                                    disabled={buttonDisabled}
                                    onClick={() => {
                                        setIndex(i);
                                        acceptGuaranty();
                                    }}
                                />
                            </div>
                        </div>
                    );
                })
            ) : (
                <div className="p-4">
                    <div>No requests :/</div>
                </div>
            )}
        </div>
    );
}
