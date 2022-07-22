// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/URITemplate.sol";

abstract contract CreditScore is ERC721URIStorage, Ownable, URITemplate {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    ITablelandTables private _tableland;
    string private _metadataTable;
    uint256 private _metadataTableId;
    string private _tablePrefix = "sbt";
    string private uriTemplate;

    address private deployer;

    // Our will be pulled from the network
    string private _baseURIString = "https://testnet.tableland.network/query?mode=list&s=";

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
                " (id int, wallet_address address , score int, image text, description text, name text);"
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

        uriTemplate = getUriTemplate(_metadataTable);
        string memory base = _baseURI();
        string memory finalTemplate = string.concat(base, uriTemplate);
        _setURITemplate(finalTemplate);

        deployer = msg.sender;
    }

    function getUriTemplate(string memory _metadataTableName)
        internal
        pure
        returns (string memory)
    {
        string memory _uriTemplate = string.concat(
            "SELECT+json_object%28%27id%27%2C+id%2C+%27name%27%2C+name%2C+%27wallet_address%27%2C+wallet_address%2C+%27score%27%2C+score%2C+%27image%27%2C+image%2C+%27description%27%2C+description+%29+FROM+",
            _metadataTableName,
            "+WHERE+id%3D{id}"
        );
        return _uriTemplate;
    }

    // method to set our uriTemplate
    // function setURITemplate(string memory uriTemplate) internal override {
    //     string memory base = _baseURI();
    //     string memory finalTemplate = string.concat(base, uriTemplate);
    //     _setURITemplate(finalTemplate);
    // }

    /*
     * @dev safeMint allows anyone to mint a token in this project.
     * Any time a token is minted, a new row of metadata will be
     * dynamically inserted into the metadata table.
     */
    function safeMint(address to) public notMinted returns (uint256) {
        uint256 newItemId = _tokenIds.current();

        string memory _image = string.concat(
            STARTING_SVG,
            "#fdff00",
            MIDDLE_SVG,
            "100",
            ENDING_SVG
        );

        string memory finalImage = string.concat(
            "data:image/svg+xml;base64",
            Base64.encode(bytes(_image))
        );

        _tableland.runSQL(
            address(this),
            _metadataTableId,
            string.concat(
                "INSERT INTO ",
                _metadataTable,
                " (id, wallet_address, score, image, description, name) VALUES (",
                Strings.toString(newItemId),
                Strings.toHexString(uint256(uint160(msg.sender)), 20),
                ", '100'",
                finalImage,
                ", 'A Credit Score SBT provided by Stark', 'Credit Score' )"
            )
        );

        _safeMint(to, newItemId);
        _tokenURI(newItemId);
        _tokenIds.increment();
        return newItemId;
    }

    function changeCredit(uint256 tokenId, uint256 _score) public {
        // Check token ownership
        require(this.ownerOf(tokenId) == deployer, "Invalid owner");
        // Simple on-chain gameplay enforcement

        string memory color = "#fdff00";
        uint256 score = 100;

        if (score > 150) {
            color = "#00FF00"; // green
        } else if (score < 50) {
            color = "#FF0000"; // red
        }

        string memory _image = string.concat(
            STARTING_SVG,
            color,
            MIDDLE_SVG,
            Strings.toString(score),
            ENDING_SVG
        );

        string memory finalImage = string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(_image))
        );

        // Update the row in tableland
        _tableland.runSQL(
            address(this),
            _metadataTableId,
            string.concat(
                "UPDATE ",
                _metadataTable,
                " SET score = ",
                Strings.toString(_score),
                " AND image = ",
                finalImage,
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
    ) internal virtual override {
        require(from == address(0), "Err: token transfer is BLOCKED");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function metadataURI() public view returns (string memory) {
        string memory base = _baseURI();
        return string.concat(base, "SELECT%20*%20FROM%20", _metadataTable);
    }

    /*
     * @dev tokenURI is an example of how to turn a row in your table back into
     * erc721 compliant metadata JSON. Here, we do a simple SELECT statement
     * with function that converts the result into json.
     */
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    //     string memory base = _baseURI();

    //     /* We will give token viewers a way to get at our table metadata */
    //     return finalTokenUri;
    // }

    // public method to read the tokenURI
    function _tokenURI(uint256 tokenId) internal {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory finalTokenURI = _getTokenURI(Strings.toString(tokenId));
        _setTokenURI(tokenId, finalTokenURI);
    }
}
