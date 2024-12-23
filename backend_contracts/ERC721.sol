// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface IERC721 {
    
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transfer(address to, uint256 tokenId) external returns(bool);
    function approve(address to, uint256 tokenId) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

}

contract ERC721 is IERC721 {

    string public name;
    string public symbol;
    uint256 public currentTokenId;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owner;
    mapping(address => mapping(address => uint256)) private _allowance;
    mapping(uint256 => bool) private _tokenExists;


    constructor(string memory _name, string memory _symbol) {

        name = _name;
        symbol = _symbol;
        currentTokenId = 0;

    }

    function balanceOf(address owner) public view override returns(uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 token_id) public view override returns(address) {
        
        require(_tokenExists[token_id], "The token doesn't exit.");
        return _owner[token_id];
    }

    function transfer(address to, uint256 tokenId) public returns(bool) {

        require(_tokenExists[tokenId], "The token is not exits.");
        require(_owner[tokenId] == msg.sender, "The owner is different");
        require(to != address(0) && to != msg.sender , "The receiver address is invalid");

        _balances[msg.sender] -= 1;
        _balances[to] += 1;
        
        _owner[tokenId] = to;
        emit Transfer(msg.sender, to, tokenId);

        return true;

    }

    function approve(address to, uint256 tokenId) public returns(bool) {

        require(_tokenExists[tokenId], "The token is not exits.");
        require(_owner[tokenId] == msg.sender, "The owner is different");
        require(to != address(0) && to != msg.sender , "The receiver address is invalid");

        _allowance[msg.sender][to] = tokenId;
        emit Approval(msg.sender, to, tokenId);
        
        return true;

    }

    function mint(address to, uint256 tokenId) public returns(bool) {

        require(to != address(0), "The address doesn't valid.");
        require(!_tokenExists[tokenId], "The token is already exits.");

        _tokenExists[tokenId] = true;
        _balances[to] += 1;
        _owner[tokenId] = to;

        return true; 

    }

    function incrementTokenID() public returns(uint256) {
        
        currentTokenId += 1;
        return currentTokenId;

    }

}