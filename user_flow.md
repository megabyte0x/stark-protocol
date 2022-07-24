# User Flow

The User will be in the **[STARK PROTOCOL]()** which will be same as the AAVE.
But in this PROTOCOL it will have the ability to request for the assets in the following  manners :-

## For P2P Request

1. Borrower enters the address of the lender, and then get into a chat with the lender.

2. Borrower and lender agree on the amount of the loan, interest rate, instalment amount and the number of instalments. (*all this in the chat*)

3. Borrower made request to the lender to borrow money, by entering the amount, interest rate and number of instalments.

4. Lender approves the request, and the borrower gets the money.

5. Borrower then start paying the lender back, amount will be equal to the instalment amount or full amount.

### *1st condition* 
When borrower request to increase the number of instalments, and ***if the lender accepts it*** there will be additional interest to be paid by the borrower in each payment.
The interest amount will be divided between the lender and the protocol.

### *2nd condition*
When borrower request to increase the number of instalments, and ***if the lender rejects it*** then..... ?

Two workaround for this:-
* We could use soulbound tokens to give a level of debt credibility to borrowers to give different risk tolerances to lenders. This would also mean different interest ranges based upon risk. If the user does not give the money back then the lender has accepted the risk & knows to lower his risk exposure.

* We could just make an ERC721 token that a user has to accept before being sent & then once received they can't transfer it. We will have the tokenURI pointing at **IPNS** instead of IPFS & we could dynamically update the contents of the metadata to reflect the outcome of the lending & calculate the lending fee out from the metadata 🙂

---
---

## For GURANTEE Request

1. Borrower enters the address of the lender, and then get into a chat with the lender.

2. They agree on the Amount of the assets Lender will back for the borrower and the amount of the time.(*all this in the chat*)

3. Borrower will make the Gurantee Request, mentioning the Lender's address, the amount of the assets, and the period time. 

4. Lender accepts the Request and his collateral will be locked in the protocol till the borrower complete the payment.

### *1st Condition*
When the borrower make the payments in time, his credit score will increase and the Lender collateral will not affected.

### *2nd Condition*
When the borrower repay the amount he borrowed after the time period ends his credit score will decrease, and the lenders collateral will be decreased with some percentage.

### *3rd Condition*
When the borrower fails to repay the Loan in any amount of time, his credit score will deplet and the collateral of the borrower will be used to cover the loss of the Protocol.

***
* Chat functionality will be handled by [XMTP](https://xmtp.com/).
* Notification Functionality will be handled by [EPNS](https://epns.io/).
***
