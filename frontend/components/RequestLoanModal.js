import { useEffect, useState } from "react";
import { Modal, Icon, useNotification, Card, Illustration } from "web3uikit";
import starkAbi from "../constants/Stark.json";
import contractAddresses from "../constants/networkMapping.json";
import { useMoralis } from "react-moralis";
import { ethers } from "ethers";

export default function RequestLoanModal({ isVisible, onClose }) {
    const [borrowAmount, setBorrowAmount] = useState("0");
    const { isWeb3Enabled, account, chainId } = useMoralis();
    const [isOkDisabled, setIsOkDisabled] = useState(false);
    const [availableTokens, setAvailableTokens] = useState("0");
    const dispatch = useNotification();

    async function updateUI() {
        const { ethereum } = window;
        const provider = await new ethers.providers.Web3Provider(ethereum);
        const signer = await provider.getSigner();
        const contractAddress = await contractAddresses["Stark"][parseInt(chainId)][0];
        const contract = await new ethers.Contract(contractAddress, starkAbi, signer);
        const availableTokens = await contract.getMaxTokenBorrow(
            tokenAddresses[borrowIndex],
            account
        );
        setAvailableTokens(ethers.utils.formatEther(availableTokens));
    }

    // useEffect(() => {
    //     updateUI();
    // }, [isWeb3Enabled, borrowAmount, tokenBalances]);

    return (
        <div className="pt-2">
            <Modal
                isVisible={isVisible}
                onCancel={onClose}
                onCloseButtonPressed={onClose}
                title="Request Loan"
                width="750px"
                isCentered={true}
                hasFooter={false}
            >
                <div className="p-6 pb-12 grid grid-cols-2 gap-1 place-content-stretch h-35">
                    <div
                        style={{
                            width: "250px",
                        }}
                    >
                        <Card
                            description="Borrow from a lender directly"
                            onClick={function noRefCheck() {}}
                            setIsSelected={function noRefCheck() {}}
                            title="P2P"
                            tooltipText="Borrow from a lender directly"
                        >
                            <div>
                                <Illustration height="180px" logo="token" width="100%" />
                            </div>
                        </Card>
                    </div>

                    <div
                        style={{
                            width: "250px",
                        }}
                    >
                        <Card
                            description="Borrow with Guaranty"
                            onClick={function noRefCheck() {}}
                            setIsSelected={function noRefCheck() {}}
                            title="Guaranty"
                            tooltipText="Take Guranty from your freind so you can borrow"
                        >
                            <div>
                                <Illustration height="180px" logo="confirmed" width="100%" />
                            </div>
                        </Card>
                    </div>
                </div>
            </Modal>
        </div>
    );
}
