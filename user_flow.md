# User Flow

1. Borrower enters the address of the lender, and then get into a chat with the lender.
We will be using [XMTP](https://xmtp.com/) for this.

2. Borrower and lender agree on the amount of the loan, interest rate, instalment amount and the number of instalments. (*all this in the chat*)

3. Borrower made request to the lender to borrow money, by entering the amount, interest rate and number of instalments.
We will be using [EPNS](https://epns.io/) for notification to the users.

4. Lender approves the request, and the borrower gets the money.

5. Borrower then start paying the lender back, amount will be equal to the instalment amount or full amount.

----
### *1st condition* 
When borrower request to increase the number of instalments, and ***if the lender accepts it*** there will be additional interest to be paid by the borrower in each payment.
The interest amount will be divided between the lender and the protocol.

----
### *2nd condition*
When borrower request to increase the number of instalments, and ***if the lender rejects it*** then..... ?

Two workaround for this:-
* We could use soulbound tokens to give a level of debt credibility to borrowers to give different risk tolerances to lenders. This would also mean different interest ranges based upon risk. If the user does not give the money back then the lender has accepted the risk & knows to lower his risk exposure.

* We could just make an ERC721 token that a user has to accept before being sent & then once received they can't transfer it. We will have the tokenURI pointing at **IPNS** instead of IPFS & we could dynamically update the contents of the metadata to reflect the outcome of the lending & calculate the lending fee out from the metadata 🙂