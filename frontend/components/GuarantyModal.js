import { useEffect, useState } from "react";
import { Modal, Icon, useNotification, Input } from "web3uikit";
import starkAbi from "../constants/Stark.json";
import contractAddresses from "../constants/networkMapping.json";
import { useMoralis } from "react-moralis";
import { ethers } from "ethers";
import creditAbi from "../constants/CreditLogic.json";

export default function GuarantyModal({ isVisible, onClose, address }) {
    const [borrowAmount, setBorrowAmount] = useState("0");
    const { isWeb3Enabled, account, chainId } = useMoralis();
    const [isOkDisabled, setIsOkDisabled] = useState(false);
    const [availableTokens, setAvailableTokens] = useState("0");
    const [amount, setAmount] = useState("");
    const [rentedUntil, setRentedUntil] = useState("");
    const dispatch = useNotification();

    async function raiseGuaranty() {
        try {
            if (+availableTokens < +borrowAmount) {
                alert("You can only borrow 80% of your collateral!");
                return;
            }
            setIsOkDisabled(true);
            const { ethereum } = window;
            const provider = await new ethers.providers.Web3Provider(ethereum);
            const signer = await provider.getSigner();
            const contractAddress = await contractAddresses["CreditLogic"][parseInt(chainId)][0];
            const wethAddress = await contractAddresses["WETH"][parseInt(chainId)][0];
            const contract = await new ethers.Contract(contractAddress, creditAbi, signer);
            console.log("Raising...");
            const tx = await contract.guarantyRaiseRequest(
                address,
                wethAddress,
                ethers.utils.parseEther(amount),
                rentedUntil
            );
            const txReceipt = await tx.wait(1);
            if (txReceipt.status === 1) {
                console.log("Raised!");
                setIsOkDisabled(false);
                handleRaisedSuccess();
            } else {
                alert("Transaction Failed for some reason. Please try again!");
                setIsOkDisabled(false);
            }
        } catch (e) {
            console.log(e);
            console.log("This error is coming from `GuarantyModal` raiseGuaranty function");
            setIsOkDisabled(false);
        }
    }

    const handleRaisedSuccess = async function () {
        onClose && onClose();
        dispatch({
            type: "success",
            title: "Request raised!",
            message: "Request raised",
            position: "topR",
        });
    };

    // useEffect(() => {
    // updateUI();
    // }, [isWeb3Enabled]);

    return (
        <div className="pt-2">
            <Modal
                isVisible={isVisible}
                onCancel={onClose}
                onCloseButtonPressed={onClose}
                onClose={onClose}
                onOk={raiseGuaranty}
                title="Raise Guaranty Request"
                width="450px"
                isCentered={true}
                isOkDisabled={isOkDisabled}
            >
                <div
                    style={{
                        alignItems: "center",
                        display: "flex",
                        flexDirection: "column",
                        justifyContent: "center",
                    }}
                    className="p-4"
                >
                    <div className="p-4">
                        <Input
                            label="Amount (in ETH)"
                            name="Amount"
                            type="text"
                            onChange={(event) => {
                                setAmount(event.target.value);
                            }}
                        />
                    </div>
                    <div className="p-4">
                        <Input
                            label="Rented Until (in months)"
                            name="Rented Until"
                            type="text"
                            onChange={(event) => {
                                setRentedUntil(event.target.value);
                            }}
                        />
                    </div>
                </div>
            </Modal>
        </div>
    );
}
