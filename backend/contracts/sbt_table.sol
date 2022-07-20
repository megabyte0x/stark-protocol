// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract sbt_table is Context, ERC721URIStorage, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    ITablelandTables private _tableland;
    string private _metadataTable;
    uint256 private _metadataTableId;
    string private _tablePrefix = "sbt";

    address private deployer;

    // Our will be pulled from the network
    string private _baseURIString = "https://testnet.tableland.network/query?s=";

    // Called only when the smart contract is created
    // registry = 0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68
    constructor(address registry) ERC721("Pixel", "ITM") {
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
    function safeMint(address to) public returns (uint256) {
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
        _safeMint(to, newItemId, "");
        _tokenIds.increment();
        return newItemId;
    }

    /*
     * @dev makeMove is an example of how to encode gameplay into both the
     * smart contract and the metadata. Whenever a token owner calls
     * make move, they can supply a new x,y coordinate and update
     * their token metadata.
     */
    function changeCredit(
        uint256 tokenId,
        uint256 _score
    ) public {
        // Check token ownership
        require(this.ownerOf(tokenId) == msg.sender, "Invalid owner");
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

    /*
     * @dev tokenURI is an example of how to turn a row in your table back into
     * erc721 compliant metadata JSON. Here, we do a simple SELECT statement
     * with function that converts the result into json.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory base = _baseURI();

        /* We will give token viewers a way to get at our table metadata */
        return;
    }

    function metadataURI() public view returns (string memory) {
        string memory base = _baseURI();
        return string.concat(base, "SELECT%20*%20FROM%20", _metadataTable);
    }
}
