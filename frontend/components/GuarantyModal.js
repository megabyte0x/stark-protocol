import { useEffect, useState } from "react";
import { Modal, Icon, useNotification, Input } from "web3uikit";
import starkAbi from "../constants/Stark.json";
import contractAddresses from "../constants/networkMapping.json";
import { useMoralis } from "react-moralis";
import { ethers } from "ethers";
<<<<<<< HEAD

export default function GuarantyModal({isVisible, onClose}) {
=======
import creditAbi from "../constants/CreditLogic.json";

export default function GuarantyModal({ isVisible, onClose, address }) {
>>>>>>> 074c85e (frontend ready)
    const [borrowAmount, setBorrowAmount] = useState("0");
    const { isWeb3Enabled, account, chainId } = useMoralis();
    const [isOkDisabled, setIsOkDisabled] = useState(false);
    const [availableTokens, setAvailableTokens] = useState("0");
<<<<<<< HEAD
    const dispatch = useNotification();

    async function updateUI() {
        const { ethereum } = window;
        const provider = await new ethers.providers.Web3Provider(ethereum);
        const signer = await provider.getSigner();
        const contractAddress = await contractAddresses["Stark"][parseInt(chainId)][0];
        const contract = await new ethers.Contract(contractAddress, starkAbi, signer);
    }

    async function borrow() {
=======
    const [amount, setAmount] = useState("");
    const [rentedUntil, setRentedUntil] = useState("");
    const dispatch = useNotification();

    async function raiseGuaranty() {
>>>>>>> 074c85e (frontend ready)
        try {
            if (+availableTokens < +borrowAmount) {
                alert("You can only borrow 80% of your collateral!");
                return;
            }
<<<<<<< HEAD
            // setIsOkDisabled(true);
            const { ethereum } = window;
            const provider = await new ethers.providers.Web3Provider(ethereum);
            const signer = await provider.getSigner();
            const contractAddress = await contractAddresses["Stark"][parseInt(chainId)][0];
            const contract = await new ethers.Contract(contractAddress, starkAbi, signer);
            // console.log("Borrowing...");
            // const tx = await contract.borrow(
            //     tokenAddresses[borrowIndex],
            //     ethers.utils.parseEther(borrowAmount)
            // );
            // const txReceipt = await tx.wait(1);
            // if (txReceipt.status === 1) {
            //     console.log("Borrowed!");
            // setIsOkDisabled(false);
            //     handleBorrowSuccess();
            // } else {
            //     alert("Transaction Failed for some reason. Please try again!");
            //     setIsOkDisabled(false);
            // }
        } catch (e) {
            console.log(e);
            console.log("This error is coming from `BorrowModal` borrow function");
=======
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
>>>>>>> 074c85e (frontend ready)
            setIsOkDisabled(false);
        }
    }

<<<<<<< HEAD
    const handleBorrowSuccess = async function () {
        onClose && onClose();
        dispatch({
            type: "success",
            title: "Asset Borrowed!",
            message: "Asset Borrowed - Please Refresh",
=======
    const handleRaisedSuccess = async function () {
        onClose && onClose();
        dispatch({
            type: "success",
            title: "Request raised!",
            message: "Request raised",
>>>>>>> 074c85e (frontend ready)
            position: "topR",
        });
    };

<<<<<<< HEAD
    useEffect(() => {
        updateUI();
    }, [isWeb3Enabled]);
=======
    // useEffect(() => {
    // updateUI();
    // }, [isWeb3Enabled]);
>>>>>>> 074c85e (frontend ready)

    return (
        <div className="pt-2">
            <Modal
                isVisible={isVisible}
                onCancel={onClose}
                onCloseButtonPressed={onClose}
                onClose={onClose}
<<<<<<< HEAD
                // onOk={borrow}
                title="Raise Guaranty Request"
                width="450px"
                isCentered={true}
                isOkDisabled={false}
=======
                onOk={raiseGuaranty}
                title="Raise Guaranty Request"
                width="450px"
                isCentered={true}
                isOkDisabled={isOkDisabled}
>>>>>>> 074c85e (frontend ready)
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
                            label="Amount"
                            name="Amount"
                            type="text"
                            onChange={(event) => {
<<<<<<< HEAD
                                setBorrowAmount(event.target.value);
=======
                                setAmount(event.target.value);
>>>>>>> 074c85e (frontend ready)
                            }}
                        />
                    </div>
                    <div className="p-4">
                        <Input
<<<<<<< HEAD
                            label="Rented Until (in years)"
                            name="Rented Until"
                            type="text"
                            onChange={(event) => {
                                setBorrowAmount(event.target.value);
=======
                            label="Rented Until (in months)"
                            name="Rented Until"
                            type="text"
                            onChange={(event) => {
                                setRentedUntil(event.target.value);
>>>>>>> 074c85e (frontend ready)
                            }}
                        />
                    </div>
                </div>
            </Modal>
        </div>
    );
}
