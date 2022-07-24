import { useEffect, useState } from "react";
import { useMoralis } from "react-moralis";
import { getChainById } from "web3uikit";
import GuarantyModal from "./GuarantyModal";

export default function Messages({ address, conversation }) {
    const [messages, setMessages] = useState([]);
    const { isWeb3Enabled, account } = useMoralis();
    const [isLoading, setIsLoading] = useState(true);

    async function updateUI() {
        const _messages = await conversation.messages();
        setMessages(_messages);
        for (const message of messages) {
            console.log(message.content);
        }
        setIsLoading(false);
    }

    function getSmallString(addr) {
        const string = addr.slice(0, 6) + "...." + addr.slice(-5, -1);
        return string;
    }

    useEffect(() => {
        updateUI();
    }, [isWeb3Enabled, conversation]);

    return (
        <div>
            <div className="flex flex-wrap whitespace-nowrap border-b-2 pb-1">TO: {address}</div>
            <div>
                {messages.slice().map((msg, i, arr) => {
                    if (i < arr.length - 10) return;
                    return (
                        <div className="p-1" style={{ width: "" }}>
                            <div className="justify-self-start">
                                <div className="flex flex-wrap text-xs whitespace-nowrap border-2 rounded-full bg-gray-100 text-blue-500 w-24 h-5">
                                    {getSmallString(msg.senderAddress)}
                                </div>
                            </div>
                            <div className="flex flex-wrap p-1 whitespace-nowrap">
                                {msg.content}
                            </div>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
