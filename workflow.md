# WORKFLOW

The default will be same as the AAVE, where there will Lending/Borrowing of the Assets.
Which will be handled with the help of [this](https://github.com/Megabyte-143/stark-protocol/blob/main/backend/contracts/Stark.sol)

When the users will agree on the terms using the chat functionality on the platform which is done by using [this](https://xmtp.com/)
There will be two ways for the Borrower to make the Request:-

## P2P Request 
When the borrower raise the request, a [Deal Contract](https://github.com/Megabyte-143/stark-protocol/blob/main/backend/contracts/Deal.sol) will be deployed, which will handle the transactions between the Borrower and the Lender.

## Gurantee Request
When the borrower raise the request, a []() will be deployed, which will handle the transactions between the Borrower and the Protocol, and also lock the assets of the Lender in the protocol.



Failure of repaying the Loans, will decrease the credit score of the user which will be managed using [this](https://tableland.xyz/).

Notification Functionality will be handled by [EPNS](https://epns.io/).
