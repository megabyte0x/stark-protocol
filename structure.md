# Contracts

There are two contracts as of now=>

- ## `Lend.sol`
**This is the main contract handling all the transactions functionality.**
- ### Functions
    * `getBorrower()` => To get the address of the Borrower.
    * `getLender()` => To get the address of the Lender.
    * `getInstalmentAmount()` => To get the instalment amount.
    * `getNoOfInstalments()` => To get the number of instalments.
    * `getTotalAmountOwed()` => To get the amount owed by the  borrower.
    * `getInterestRate()` => To get the interest rate.
    * `payAtOnce()` => To pay the amount remaining at once.
    * `payInInstalment()` => Tp pay the instalment, where we calulate the interest and additional interest(if any).
    * `requestNoOfInstalment()` => To request additional number of instalments.
    * `acceptRequestOfInstalment()` => To accept the request for additional number of instalments.
- ### Variables
    * `deployer` => The address of the Protocol
    * `borrower` => The address of the Borrower
    * `lender` => The address of the lender
    * `deal` => The instance of the struct `DealDetails`
- ### Structs
    * `DealDetails` => Contains all the details about the deal.
        * 