import { useEffect, useState } from "react";
import { useMoralis } from "react-moralis";
import Auth from "../components/Auth";

export default function Chat() {
    const [isLoading, setIsLoading] = useState(false);
    const { isWeb3Enabled, account, chainId } = useMoralis();

    return (
        <div>
            {isWeb3Enabled ? (
                <div>
                    {chainId == 80001 ? (
                        !isLoading ? (
                            <div>
                            <Auth/>
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
