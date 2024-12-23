// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {

    string public name; // token name
    string public symbol; // token symbol
    uint8 public decimals = 18;
    uint256 public _totalSupply; 

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowance;


    constructor(string memory _name, string memory _symbol, uint256 initalSupply) {

        name = _name;
        symbol = _symbol;
        _totalSupply = initalSupply * (10 ** decimals);
        mint(msg.sender, _totalSupply);
        
    }

    function totalSupply() public view override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns(bool) {

        require(recipient != address(0), "Please give valid address");
        require( amount >= 0 , "Please give amount positive");
        require(_balances[msg.sender] >= amount , "There is no enough balance in account");

        uint256 converted_amount = amount * (10 * decimals);
        _balances[msg.sender] -= converted_amount;
        _balances[recipient] += converted_amount;
        emit Transfer(msg.sender, recipient, amount);

        return true;

    }

    function allowance(address owner, address spender) public view override returns(uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns(bool) {

        require(spender != address(0), "Please give valid address");
        require( amount >= 0 , "Please give amount positive");
        require(_balances[msg.sender] >= amount, "There is no enough balance in account");

        uint256 converted_amount = amount * (10 * decimals);

        _allowance[msg.sender][spender] += converted_amount;
        return true;

    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {

        require(amount >= 0, "The amount must be zero or positive");
        uint256 converted_amount = amount * (10 * decimals);

        require(sender != address(0), "Please give valid address for sender");
        require(recipient != address(0), "Please give valid address for recipient");
        require(_balances[sender] >= converted_amount, "Transfer amount exceeds balance");
        require(_allowance[sender][msg.sender] >= converted_amount, "There is no enough balance in account");

        _balances[sender] -= converted_amount;
        _balances[recipient] += converted_amount;
        _allowance[sender][msg.sender] -= converted_amount;
        emit Transfer(sender, recipient, converted_amount);

        return true;

    }

    function mint(address owner, uint256 total) internal returns(bool) {

        require(total > 0, "The total amount must be greater than 0");
        _balances[owner] = total;
        emit Transfer(address(0), owner, total);

        return true;
    }

}