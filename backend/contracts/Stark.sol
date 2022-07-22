// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Stark__NeedMoreThanZero(uint256 amount);
error Stark__NotSupplied();
error Stark__CannotWithdrawMoreThanSupplied(uint256 amount);
error Stark__CouldNotBorrowMoreThan80PercentOfCollateral();
error Stark__ThisTokenIsNotAvailable(address tokenAddress);
error Stark__NotAllowedBeforeRepayingExistingLoan(uint256 amount);
error Stark__TransactionFailed();
error Stark__SorryWeCurrentlyDoNotHaveThisToken(address tokenAddress);
error Stark__UpKeepNotNeeded();

contract Stark is ReentrancyGuard, KeeperCompatibleInterface, Ownable {
    address private deployer;
    address[] private s_allowedTokens; // * Array of allowed tokens
    address[] private s_suppliers; // * Array of all suppliers
    address[] private s_borrowers; // * Array of all borrowers
    address[] private s_allowedContracts;
    uint256 private immutable i_interval; // * Chainlink keepers Interval
    uint256 private s_lastTimeStamp; // * Time stamp for chainlink keepers

    //////////////////
    //// Events /////
    ////////////////

    event TokenSupplied(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenWithdrawn(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenBorrowed(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event TokenRepaid(
        address indexed tokenAddress,
        address indexed userAddress,
        uint256 indexed amount
    );
    event Guaranteed(
        address indexed userAddress,
        address indexed friendAddress,
        bool indexed reponse
    );

    //////////////////////
    /////  mappings  /////
    /////////////////////

    // token address -> total supply of that token
    mapping(address => uint256) private s_totalSupply;

    // tokenAddress & user address -> their supplied balances
    mapping(address => mapping(address => uint256)) private s_supplyBalances;

    // tokenAddress & user adddress -> their borrowed balance
    mapping(address => mapping(address => uint256)) private s_borrowedBalances;

    // tokenAddress & user adddress -> their locked balance
    mapping(address => mapping(address => uint256)) private s_lockedBalances;

    // token address -> price feeds
    mapping(address => AggregatorV3Interface) private s_priceFeeds;

    // userAddress -> all of his unique supplied tokens
    mapping(address => address[]) private s_supplierUniqueTokens;

    // userAddress -> all of his unique borrowed tokens
    mapping(address => address[]) private s_borrowerUniqueTokens;

    // userAddress & friend address => their guaranties
    mapping(address => mapping(address => bool)) private s_guarantys;

    // contractAddress -> permission to modify the data in this contract
    // mapping(address => bool) private s_allowedContracts;

    /////////////////////
    ///   Modifiers   ///
    /////////////////////

    // * MODIFIER: check if user have supplied token or not
    modifier hasSupplied() {
        bool success;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            if (s_supplyBalances[s_allowedTokens[i]][msg.sender] > 0) {
                success = true;
            }
        }

        if (!success) {
            revert Stark__NotSupplied();
        }
        _;
    }

    // * MODIFIER: check value is more then 0
    modifier notZero(uint256 amount) {
        if (amount <= 0) {
            revert Stark__NeedMoreThanZero(amount);
        }
        _;
    }

    // * MODIFIER: check is token allowed or not
    modifier isTokenAllowed(address tokenAddress) {
        bool execute;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            if (s_allowedTokens[i] == tokenAddress) {
                execute = true;
            }
        }

        if (!execute) {
            revert Stark__ThisTokenIsNotAvailable(tokenAddress);
        }
        _;
    }

    // * MODIFIER: Check whether the contract address is allowed to modify values.
    modifier onlyAllowedContracts(address _contractAddress) {
        bool execute;
        for (uint256 i = 0; i < s_allowedContracts.length; i++) {
            if (s_allowedContracts[i] == _contractAddress) {
                execute = true;
            }
        }
        require(execute, "not onlyAllowedContracts");
        _;
    }

    //////////////////////////
    ///  Main  Functions   ///
    /////////////////////////

    constructor(
        address[] memory allowedTokens,
        address[] memory priceFeeds,
        uint256 updateInterval
    ) {
        s_allowedTokens = allowedTokens;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            s_priceFeeds[allowedTokens[i]] = AggregatorV3Interface(priceFeeds[i]);
        }
        i_interval = updateInterval;
        s_lastTimeStamp = block.timestamp;
        s_allowedContracts.push(msg.sender);
    }

    // * FUNCTION: Users can supply tokens
    function supply(address tokenAddress, uint256 amount)
        external
        payable
        isTokenAllowed(tokenAddress)
        notZero(amount)
        nonReentrant
    {
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert Stark__TransactionFailed();
        }
        s_totalSupply[tokenAddress] += amount;
        s_supplyBalances[tokenAddress][msg.sender] += amount;
        addSupplier(msg.sender); // adds supplier in s_suppliers array
        addUniqueToken(s_supplierUniqueTokens[msg.sender], tokenAddress); // adding token address to their unique tokens array (check this function in helper functions sections)
        // s_supplierUniqueTokens[msg.sender] -> mapping
        emit TokenSupplied(tokenAddress, msg.sender, amount);
    }

    // * FUNCTION: Users can withdraw their supplied tokens
    function withdraw(address tokenAddress, uint256 amount)
        external
        payable
        hasSupplied
        notZero(amount)
        nonReentrant
    {
        if (amount > s_supplyBalances[tokenAddress][msg.sender]) {
            revert Stark__CannotWithdrawMoreThanSupplied(amount);
        }

        revertIfHighBorrowing(tokenAddress, msg.sender, amount); // not allows to withdraw if borrowing is already high
        s_supplyBalances[tokenAddress][msg.sender] -= amount;
        s_totalSupply[tokenAddress] -= amount;
        removeSupplierAndUniqueToken(tokenAddress, msg.sender); // removes supplier and his unique token
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    // * FUNCTION: Users can borrow based on their supplies
    function borrow(address tokenAddress, uint256 amount)
        external
        payable
        isTokenAllowed(tokenAddress)
        hasSupplied
        notZero(amount)
        nonReentrant
    {
        if (s_totalSupply[tokenAddress] <= 0) {
            // reverts if we don't have supply of that token
            revert Stark__SorryWeCurrentlyDoNotHaveThisToken(tokenAddress);
        }

        notMoreThanMaxBorrow(tokenAddress, msg.sender, amount); // not allows to borrow if asking more than their max borrow
        addBorrower(msg.sender); // adds borrower in s_borrowers array
        addUniqueToken(s_borrowerUniqueTokens[msg.sender], tokenAddress);
        s_borrowedBalances[tokenAddress][msg.sender] += amount;
        s_totalSupply[tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenBorrowed(tokenAddress, msg.sender, amount);
    }

    // * FUNCTION: To repay the loan
    function repay(address tokenAddress, uint256 amount)
        external
        payable
        notZero(amount)
        nonReentrant
    {
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert Stark__TransactionFailed();
        }

        s_borrowedBalances[tokenAddress][msg.sender] -= amount;
        s_totalSupply[tokenAddress] += amount;
        removeBorrowerAndUniqueToken(tokenAddress, msg.sender); // removes borrower and his unique token from array
        emit TokenRepaid(tokenAddress, msg.sender, amount);
    }

    // * FUNCTION: For liquidation
    function liquidation() external onlyOwner {
        for (uint256 i = 0; i < s_borrowers.length; i++) {
            if (getTotalBorrowValue(s_borrowers[i]) >= getTotalSupplyValue(s_borrowers[i])) {
                // * Checking if total borrow value is equal or greater than total supply value in USD
                for (uint256 index = 0; index < s_allowedTokens.length; index++) {
                    s_supplyBalances[s_allowedTokens[index]][s_borrowers[i]] = 0;
                    s_borrowedBalances[s_allowedTokens[index]][s_borrowers[i]] = 0; // reducing their borrowed balance & supply balance to 0
                }
            }
        }
    }

    // * FUNCTION: To allow guaranty requests to be sent
    function allowGuaranty(address friendAddress) external {
        s_guarantys[msg.sender][friendAddress] = true;
        emit Guaranteed(msg.sender, friendAddress, true);
    }

    // * FUNCTION: To disallow guaranty requests to be sent
    function disAllowGuaranty(address friendAddress) external {
        s_guarantys[msg.sender][friendAddress] = false;
        emit Guaranteed(msg.sender, friendAddress, false);
    }

    // PS: change the name guaranty to something else if you don't like

    // function noCollateralBorrow(address friendAddress) external {
    //     // use table land to store data of all users who have guaranty
    //     // then use query to read data to find if this msg.sender have guantees or if have then
    //     // take allower address and borrower address from table and update their balance accordingly
    //     hasGuaranty();
    // }

    // function hasGuaranty() public {
    //     // read from database and check if allowed
    // }

    // * FUNCTION: TO charge APY on borrowings
    function chargeAPY() private {
        for (uint256 i = 0; i < s_borrowers.length; i++) {
            // looping borrowers array
            for (
                uint256 index = 0;
                index < s_borrowerUniqueTokens[s_borrowers[i]].length; // using borrower unique tokens to loop, so we don't need to loop every token
                // s_borrowers[i] => current borrower
                // s_borrowerUniqueTokens[s_borrowers[i]] => his all unique tokens
                index++
            ) {
                s_borrowedBalances[s_borrowerUniqueTokens[s_borrowers[i]][index]][ // s_borrowedBalances[tokenAddress][userAddress] => thier borrowed balance
                    s_borrowers[i]
                    // s_borrowerUniqueTokens[s_borrowers[i]] => borrower's all unique tokens
                    // s_borrowerUniqueTokens[s_borrowers[i]][index] => tokenAddress (from unique tokens)
                ] += (
                    (s_borrowedBalances[s_borrowerUniqueTokens[s_borrowers[i]][index]][
                        s_borrowers[i]
                    ] / uint256(50)) // adding 2 % to their borrowed balance (in s_borrowedBalances)
                );
            }
        }
    }

    // * FUNCTION: TO reward APY on suppliers
    function rewardAPY() private {
        for (uint256 i = 0; i < s_suppliers.length; i++) {
            // looping suppleirs array
            for (
                uint256 index = 0;
                index < s_supplierUniqueTokens[s_suppliers[i]].length; // using supplier unique tokens to loop, so we don't need to loop every token
                // s_suppliers[i] => current supplier
                // s_supplierUniqueTokens[s_suppliers[i]] => his all unique tokens
                index++
            ) {
                s_supplyBalances[s_supplierUniqueTokens[s_suppliers[i]][index]][
                    s_suppliers[i]
                    // s_supplierUniqueTokens[s_suppliers[i]] => supplier's all unique tokens
                    // s_supplierUniqueTokens[s_suppliers[i]][index] => tokenAddress (from unique tokens)
                ] += (s_supplyBalances[s_supplierUniqueTokens[s_suppliers[i]][index]][
                    s_suppliers[i]
                ] / uint256(100)); // adding 2 % to their borrowed balance (in s_borrowedBalances)
            }
        }
    }

    // * FUNCTION: checkUpkeep function from chainlink keepers
    /* returns true if
     * have atleast 1 borrower/supplier
     * time has passed
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool hasUsers = (s_borrowers.length > 0) || (s_suppliers.length > 0);
        bool isTimePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        upkeepNeeded = (hasUsers && isTimePassed);
        return (upkeepNeeded, "0x0");
    }

    // * FUNCTION: performUpkeep function from chainlink keepers
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Stark__UpKeepNotNeeded();
        }

        if (s_borrowers.length > 0) {
            chargeAPY();
        }

        if (s_suppliers.length > 0) {
            rewardAPY();
        }

        s_lastTimeStamp = block.timestamp;
    }

    // * FUNCTION: so people can also take some test tokens
    function faucet(address tokenAddress) external {
        IERC20(tokenAddress).transfer(msg.sender, 10000 * 10**18);
    }

    ////////////////////////
    // Helper functions ////
    ///////////////////////

    // * FUNCTION: To not allow to withdraw if borrowing is already high
    function revertIfHighBorrowing(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) private view {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            (((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80)) +
                getTotalLockedValue(userAddress));

        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        uint256 askedAmountValue = amount * (price / 10**decimals);

        if (askedAmountValue > availableAmountValue) {
            revert Stark__NotAllowedBeforeRepayingExistingLoan(amount);
        }
    }

    // * FUNCTION: To not allow to borrow if asking more than their max borrow
    function notMoreThanMaxBorrow(
        address tokenAddress,
        address userAddress,
        uint256 amount
    ) private view {
        uint256 maxBorrow = getMaxBorrow(userAddress); // max borrow in usd
        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        uint256 askedAmountValue = amount * (price / 10**decimals);

        if (askedAmountValue > maxBorrow) {
            revert Stark__CouldNotBorrowMoreThan80PercentOfCollateral();
        }
    }

    // * FUNCTION: To add tokenAddress in their unique token array
    // * in its first arg it takes a array so it can be used for borrower & supplier unique token
    function addUniqueToken(address[] storage uniqueTokenArray, address tokenAddress) private {
        if (uniqueTokenArray.length == 0) {
            uniqueTokenArray.push(tokenAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < uniqueTokenArray.length; i++) {
                if (uniqueTokenArray[i] == tokenAddress) {
                    add = false;
                }
            }
            if (add) {
                uniqueTokenArray.push(tokenAddress);
            }
        }
    }

    // * FUNCTION: To add supplier in s_suppliers array
    function addSupplier(address userAddress) private {
        if (s_suppliers.length == 0) {
            s_suppliers.push(userAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < s_suppliers.length; i++) {
                if (s_suppliers[i] == userAddress) {
                    add = false;
                }
            }
            if (add) {
                s_suppliers.push(userAddress);
            }
        }
    }

    // * FUNCTION: To add supplier in s_suppliers array
    function addBorrower(address userAddress) private {
        if (s_borrowers.length == 0) {
            s_borrowers.push(userAddress);
        } else {
            bool add = true;
            for (uint256 i = 0; i < s_borrowers.length; i++) {
                if (s_borrowers[i] == userAddress) {
                    add = false;
                }
            }
            if (add) {
                s_borrowers.push(userAddress);
            }
        }
    }

    // * FUNCTION: To remove supplier and his unique token
    function removeSupplierAndUniqueToken(address tokenAddress, address userAddress) private {
        if (s_supplyBalances[tokenAddress][userAddress] <= 0) {
            remove(s_supplierUniqueTokens[userAddress], tokenAddress);
        }

        if (s_supplierUniqueTokens[userAddress].length == 0) {
            remove(s_suppliers, userAddress);
        }
    }

    // * FUNCTION: To remove borrower and his unique token from array
    function removeBorrowerAndUniqueToken(address tokenAddress, address userAddress) private {
        if (s_borrowedBalances[tokenAddress][userAddress] <= 0) {
            remove(s_borrowerUniqueTokens[userAddress], tokenAddress);
        }
        if (s_borrowerUniqueTokens[userAddress].length == 0) {
            remove(s_borrowers, userAddress);
        }
    }

    // * FUNCTION: small algorithm for removing element from an array
    function remove(address[] storage array, address removingAddress) private {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == removingAddress) {
                array[i] = array[array.length - 1];
                array.pop();
            }
        }
    }

    ////////////////////////////
    ///   getter functions   ///
    ////////////////////////////

    function getTokenTotalSupply(address tokenAddress) external view returns (uint256) {
        return s_totalSupply[tokenAddress];
    }

    function getAllTokenSupplyInUsd() external view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(s_allowedTokens[i]);

            totalValue += ((price / 10**decimals) * s_totalSupply[s_allowedTokens[i]]);
        }
        return totalValue;
    }

    function getSupplyBalance(address tokenAddress, address userAddress)
        public
        view
        returns (uint256)
    {
        return s_supplyBalances[tokenAddress][userAddress];
    }

    function getLockedBalance(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        return s_lockedBalances[tokenAddress][userAddress];
    }

    function getBorrowedBalance(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        return s_borrowedBalances[tokenAddress][userAddress];
    }

    function getLatestPrice(address tokenAddress) public view returns (uint256, uint256) {
        (, int256 price, , , ) = s_priceFeeds[tokenAddress].latestRoundData();
        uint256 decimals = uint256(s_priceFeeds[tokenAddress].decimals());
        return (uint256(price), decimals);
    }

    // * FUNCTION: returns max borrow allowed to a user
    function getMaxBorrow(address userAddress) public view returns (uint256) {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            (((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80)) +
                getTotalLockedValue(userAddress));

        return (availableAmountValue * uint256(80)) / uint256(100);
    }

    function getMaxWithdraw(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        uint256 availableAmount = s_supplyBalances[tokenAddress][userAddress] -
            (((uint256(100) * s_borrowedBalances[tokenAddress][userAddress]) / uint256(80)) +
                s_lockedBalances[tokenAddress][userAddress]);

        return availableAmount;
    }

    function getMaxTokenBorrow(address tokenAddress, address userAddress)
        external
        view
        returns (uint256)
    {
        uint256 availableAmountValue = getTotalSupplyValue(userAddress) -
            (((uint256(100) * getTotalBorrowValue(userAddress)) / uint256(80)) +
                getTotalLockedValue(userAddress));

        (uint256 price, uint256 decimals) = getLatestPrice(tokenAddress);
        return ((availableAmountValue / (price / 10**decimals)) * uint256(80)) / uint256(100);
    }

    function getTotalSupplyValue(address userAddress) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(s_allowedTokens[i]);

            totalValue += ((price / 10**decimals) *
                s_supplyBalances[s_allowedTokens[i]][userAddress]);
        }
        return totalValue;
    }

    function getTotalLockedValue(address userAddress) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(s_allowedTokens[i]);

            totalValue += ((price / 10**decimals) *
                s_lockedBalances[s_allowedTokens[i]][userAddress]);
        }
        return totalValue;
    }

    function getTotalBorrowValue(address userAddress) public view returns (uint256) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < s_allowedTokens.length; i++) {
            (uint256 price, uint256 decimals) = getLatestPrice(s_allowedTokens[i]);
            totalValue += ((price / 10**decimals) *
                s_borrowedBalances[s_allowedTokens[i]][userAddress]);
        }
        return totalValue;
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return s_allowedTokens;
    }

    function getSuppliers() external view returns (address[] memory) {
        return s_suppliers;
    }

    function getBorrowers() external view returns (address[] memory) {
        return s_borrowers;
    }

    function getUniqueSupplierTokens(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return s_supplierUniqueTokens[userAddress];
    }

    function getUniqueBorrowerTokens(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return s_borrowerUniqueTokens[userAddress];
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    /////////////////////////////
    ///   Interface Functions ///
    /////////////////////////////

    // function setCreditLogicContract(address _starkProtocolAddress) external onlyOwner {
    //     starkContract = Istark_protocol(_starkProtocolAddress);
    //     starkProtocolAddress = _starkProtocolAddress;
    // }

    // * FUNCTION: To Lock the Balance of the lender
    function lockBalanceChanges(
        address _tokenAddress,
        address _lender,
        address _borrower,
        uint256 _tokenAmount
    ) public onlyAllowedContracts(msg.sender) {
        s_lockedBalances[_tokenAddress][_lender] += _tokenAmount;
        s_supplyBalances[_tokenAddress][_borrower] += _tokenAmount;

        // emit Event to Lender that his funds are locked

        // requestChange_LendBalance(_tokenAddress, _borrower, _tokenAmount);
    }

    // * FUNCTION: To transfer the funds to the Borrower Balance
    // function requestChange_LendBalance(
    //     address _tokenAddress,
    //     address _borrower,
    //     uint256 _tokenAmount
    // ) internal {
    //     s_supplyBalances[_tokenAddress][_borrower] += _tokenAmount;

    //     s_totalSupply[_tokenAddress] -= _tokenAmount;

    //     // emit Event to Borrower that he received the funds
    // }

    // * FUNCTION: Deployer will add the guaranty contract in the List.
    function addAllowContracts(address _contractAddress)
        external
        onlyAllowedContracts(msg.sender)
    {
        s_allowedContracts.push(_contractAddress);
        // emit Event (optional)
    }

    // * FUNCTION: Guaranty Contracts will change the balances after repayment.
    function repayChanges(
        address _tokenAddress,
        address _lender,
        address _borrower,
        uint256 _tokenAmount
    ) external onlyAllowedContracts(msg.sender) {
        s_borrowedBalances[_tokenAddress][_borrower] -= _tokenAmount;
        s_totalSupply[_tokenAddress] += _tokenAmount;
        s_lockedBalances[_tokenAddress][_lender] -= _tokenAmount;
    }
}
