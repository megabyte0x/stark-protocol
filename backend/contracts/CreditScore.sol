// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "base64-sol/base64.sol";

contract CreditScore is Context, ERC721URIStorage, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    ITablelandTables private _tableland;
    string private _metadataTable;
    uint256 private _metadataTableId;
    string private _tablePrefix = "sbt";

    address private deployer;

    // Our will be pulled from the network
    string private _baseURIString = "https://testnet.tableland.network/query?s=";

    string private constant STARTING_SVG='<svg id="eChK4yXtexE1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" width="450" height="300" style="background-color:';
    // in b/w color credit score will come
    // red -> #FF0000
    // yellow -> #fdff00
    // green -> #00FF00
    string private constant MIDDLE_SVG='"><text dx="0" dy="0" font-family="&quot;Roboto&quot;" font-size="15" font-weight="400" transform="matrix(4.917124 0 0 5.062497 87.876901 175.927052)" stroke-width="0"><tspan y="0" font-weight="400" stroke-width="0">';
    // in b/w credit score will come
    string private constant ENDING_SVG='</tspan></text></svg>';

    modifier notMinted() {
        address owner = this.ownerOf(_tokenIds.current());
        require(owner != msg.sender, "Already minted!");
        _;
    }

    // Called only when the smart contract is created
    // registry = 0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68
    constructor(address registry) ERC721("Stark Credit Score", "SCS") {
        /*
         * The Tableland address on your current chain
         */
        _tableland = ITablelandTables(registry);

        /*
         * Stores the unique ID for the newly created table.
         */
        _metadataTableId = _tableland.createTable(
            address(this),
            string.concat(
                "CREATE TABLE ",
                _tablePrefix,
                Strings.toString(block.chainid),
                " (id int, wallet_address address ,external_link text, score int);"
            )
        );

        /*
         * Stores the full tablename for the new table.
         * {prefix}_{chainid}_{tableid}
         */
        _metadataTable = string.concat(
            _tablePrefix,
            "_",
            Strings.toString(block.chainid),
            "_",
            Strings.toString(_metadataTableId)
        );
        deployer = msg.sender;
    }

    /*
     * @dev safeMint allows anyone to mint a token in this project.
     * Any time a token is minted, a new row of metadata will be
     * dynamically inserted into the metadata table.
     */
    function safeMint(address to) public notMinted returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _tableland.runSQL(
            address(this),
            _metadataTableId,
            string.concat(
                "INSERT INTO ",
                _metadataTable,
                " (id, wallet_address, external_link, score) VALUES (",
                Strings.toString(newItemId),
                Strings.toHexString(uint256(uint160(msg.sender)), 20),
                ", 'not.implemented.xyz', 100)"
            )
        );

        string memory color = "#fdff00";
        string memory score = 100;

        if(score > 200) {
            color = "#00FF00"; // green
        } else if (score < 50) {
            color = "#FF0000"; // red
        }

        string memory _image = string.concat(STARTING_SVG, color, MIDDLE_SVG, Strings.toString(score), ENDING_SVG);

        string memory finalTokenUri = string.concat(
            '{"name": "Credit Score", "description": "A Credit Score SBT provided by Stark", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(_image)),
            '"}'
        );

        _safeMint(to, newItemId);
        _setTokenURI(newItemId, finalTokenUri);
        _tokenIds.increment();
        return newItemId;
    }

    function changeCredit(
        uint256 tokenId,
        uint256 _score
    ) public {
        // Check token ownership
        require(this.ownerOf(tokenId) == deployer, "Invalid owner");
        // Simple on-chain gameplay enforcement
        // Update the row in tableland
        _tableland.runSQL(
            address(this),
            _metadataTableId,
            string.concat(
                "UPDATE ",
                _metadataTable,
                " SET score = ",
                Strings.toString(_score),
                " WHERE id = ",
                Strings.toString(tokenId),
                ";"
            )
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIString;
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    ) internal override virtual {
        require(from == address(0), "Err: token transfer is BLOCKED");   
        super._beforeTokenTransfer(from, to, tokenId);  
    }

    function metadataURI() public view returns (string memory) {
        string memory base = _baseURI();
        return string.concat(base, "SELECT%20*%20FROM%20", _metadataTable);
    }
}
