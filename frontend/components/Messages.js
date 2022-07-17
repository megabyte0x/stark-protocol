import { useEffect, useState } from "react";
import { useMoralis } from "react-moralis";
import { PlanCard, Button, Widget } from "web3uikit";

export default function Messages({ address, conversation }) {
    const [messages, setMessages] = useState([]);
    const { isWeb3Enabled, account } = useMoralis();
    const [isLoading, setIsLoading] = useState(true);

    async function updateUI() {
        const _messages = await conversation.messages();
        setMessages(_messages);
        console.log("mesagess", _messages);
        for (const message of messages) {
            console.log(message.content);
        }
        setIsLoading(false);
    }

    useEffect(() => {
        updateUI();
    }, [isWeb3Enabled, conversation]);

    return (
        <div>
            Your Conversation with {address}
            <div>
                {messages.slice().map((msg, i) => {
                    if (i > 12) return;
                    console.log("message", msg);
                    if (address == msg.recipientAddress)
                        return (
                            <div className="p-1" style={{ width: "" }}>
                                <div className="absolute right-2 border-2 rounded-full p-1 pr-4">
                                    {msg.content}
                                </div>
                            </div>
                        );
                    return (
                        <div className="p-1" style={{ width: "" }}>
                            <div className="border-2 rounded-full p-1 pl-4">{msg.content}</div>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
