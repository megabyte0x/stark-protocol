import { Client } from "@xmtp/xmtp-js";
import { ethers } from "ethers";
import { useEffect, useState } from "react";
import { useMoralis } from "react-moralis";
import { Button, Input } from "web3uikit";

export default function Conversation() {
    const { account, isWeb3Enabled } = useMoralis();
    const [xmtp, setXmtp] = useState();
    const [signed, setSigned] = useState(false);
    const [buttonDisabled, setButtonDisabled] = useState(false);

    async function auth() {
        setButtonDisabled(true);
        const { ethereum } = window;
        const provider = await new ethers.providers.Web3Provider(ethereum);
        const signer = await provider.getSigner();
        const xmtp = await Client.create(signer);
        setXmtp(xmtp);
        setSigned(true);
        setButtonDisabled(false);
    }

    async function chat() {
        try {
            if (!signed) return;
            const conversation = await xmtp.conversations.newConversation(
                "0x7f6311AdEb83cB825250B2222656D26223D7EcB4"
            );
            const messages = await conversation.messages();
            console.log(messages[0].content);
            // await conversation.send("testing");
            for (const message of messages) {
                console.log(message.content);
            }
        } catch (e) {
            console.log("This error is coming from chat");
            console.log(e);
        }
    }

    async function updateUI() {
        await chat();
    }

    useEffect(() => {
        updateUI();
    }, [isWeb3Enabled, signed]);

    return (
        <div>
            {!signed ? (
                <div>
                    <div className="absolute bottom-8 right-40">
                        <Input
                            label="Enter your message"
                            name="message"
                            width="1000px"
                            prefixIcon="mail"
                            onBlur={function noRefCheck() {}}
                            onChange={function noRefCheck() {}} // don't forget to replace
                        />
                    </div>
                    <div className="absolute bottom-8 right-12">
                        <Button
                            id="test-button-primary"
                            onClick={chat}
                            text="Send"
                            theme="primary"
                            type="button"
                            size="large"
                            disabled={buttonDisabled}
                            isLoading={buttonDisabled}
                        />
                    </div>
                </div>
            ) : (
                <div className="flex justify-center p-12">
                    <Button
                        id="test-button-primary"
                        onClick={auth}
                        text="Start!"
                        theme="primary"
                        type="button"
                        size="large"
                        disabled={buttonDisabled}
                        isLoading={buttonDisabled}
                    />
                </div>
            )}
        </div>
    );
}
