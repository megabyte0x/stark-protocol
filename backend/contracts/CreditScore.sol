// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./CreditLogic.sol";

contract CreditScore is Context, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 private score = 100;
    string private color = "#fdff00";
    uint256 private lastTimeStamp;
    uint256[] private allTokenIds;
    CreditLogic public creditLogic;
    address private sbtOwner;

    string private constant STARTING_SVG =
        '<svg id="eChK4yXtexE1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" width="450" height="300" style="background-color:';
    // in b/w color credit score will come
    // red -> #FF0000
    // yellow -> #fdff00
    // green -> #00FF00
    string private constant MIDDLE_SVG =
        '"><text dx="0" dy="0" font-family="&quot;Roboto&quot;" font-size="15" font-weight="400" transform="matrix(4.917124 0 0 5.062497 87.876901 175.927052)" stroke-width="0"><tspan y="0" font-weight="400" stroke-width="0">';
    // in b/w credit score will come
    string private constant ENDING_SVG = "</tspan></text></svg>";

    modifier notMinted() {
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            address _owner = this.ownerOf(allTokenIds[i]);
            require(_owner != msg.sender, "Already minted!");
        }
        _;
    }

    constructor(address _address) ERC721("Stark Credit Score", "SCS") {
        creditLogic = CreditLogic(_address);
        lastTimeStamp = block.timestamp;
    }

    function safeMint() public notMinted returns (uint256) {
        uint256 newItemId = _tokenIds.current();

        string memory _image = string.concat(
            STARTING_SVG,
            color,
            MIDDLE_SVG,
            Strings.toString(score),
            ENDING_SVG
        );

        string memory finalTokenUri = string.concat(
            '{"name": "Credit Score", "description": "A Credit Score SBT provided by Stark", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(_image)),
            '"}'
        );

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, finalTokenUri);
        sbtOwner = msg.sender;
        allTokenIds.push(newItemId);
        _tokenIds.increment();
        return newItemId;
    }

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
        upkeepNeeded = (block.timestamp - lastTimeStamp) > 2628002;
        return (upkeepNeeded, "0x0");
    }

    // * FUNCTION: performUpkeep function from chainlink keepers
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        require(upkeepNeeded, "Upkeep not needed!");

        address[] memory lenders = creditLogic.getLenders();

        for (uint256 i = 0; i < lenders.length; i++) {
            CreditLogic.GuarantyRequest memory request = creditLogic.getGuarantyRequest(
                lenders[i],
                sbtOwner
            );

            if (request.totalAmount > 0 && request.timeRentedSince > request.timeRentedUntil) {
                score -= 10;
            } else {
                score += 10;
            }
        }

        if (score < 100) {
            color = "#FF0000";
        } else if (score > 300) {
            color = "#00FF00";
        } else {
            color = "#fdff00";
        }

        lastTimeStamp = block.timestamp;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(from == address(0), "Err: token transfer is BLOCKED");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isAlreadyMinted() external view returns (bool) {
        bool minted;

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            address _owner = this.ownerOf(allTokenIds[i]);
            if (_owner == msg.sender) {
                minted = true;
            }
        }
        return minted;
    }
}
