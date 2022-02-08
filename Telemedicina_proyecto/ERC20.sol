// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.9.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

interface IERC20 {

    function totalSupply() external view returns(uint256);

    function balanceOf(address _account) external view returns(uint256);

    function allowance(address _owner, address _spender) external view returns(uint256);

    function transfer(address _recipient, uint256 _amount) external returns(bool);

    function transferenciaLoteria(address _cliente, address _recipient, uint256 _numTokens) external returns(bool);

    function approve(address _spender, uint256 _amount) external returns(bool);

    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns(bool);

}

contract ERC20Basic is IERC20 {

    
    string public constant name = "ERC20AZ";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 2; 

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);

    using safemath for uint256;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed; 
    uint256 totalSupply_; 

    constructor (uint256 initialSupply) public {
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }


    function totalSupply() public override view returns(uint256) {
        return totalSupply_;
    }

    function increaseTotalSupply(uint _newTokenAmount) public {
        totalSupply_ += _newTokenAmount;
        balances[msg.sender] += _newTokenAmount;
    }

    function balanceOf(address _tokenOwner) public override view returns(uint256) {
        return balances[_tokenOwner];
    }

    function allowance(address _owner, address _delegate) public override view returns(uint256) {
        return allowed[_owner][_delegate];
    }

    function transfer(address _recipient, uint256 _numTokens) public override returns(bool) {
        require(_numTokens <= balances[msg.sender], "You do not have enough tokens"); 
        balances[msg.sender] = balances[msg.sender].sub(_numTokens); 
        balances[_recipient] = balances[_recipient].add(_numTokens);

        emit Transfer(msg.sender, _recipient, _numTokens);

        return true;
    }


    function transferenciaLoteria(address _cliente, address _recipient, uint256 _numTokens) public override returns(bool) {
        require(_numTokens <= balances[_cliente], "You do not have enough tokens"); 
        balances[_cliente] = balances[_cliente].sub(_numTokens); 
        balances[_recipient] = balances[_recipient].add(_numTokens);

        emit Transfer(msg.sender, _recipient, _numTokens);

        return true;
    }

    function approve(address _delegate, uint256 _numTokens) public override returns(bool) {
        allowed[msg.sender][_delegate] = _numTokens;

        emit Approval(msg.sender, _delegate, _numTokens);

        return true;
    }

    function transferFrom(address _owner, address _buyer, uint256 _numTokens) public override returns(bool) {

        require(_numTokens <= balances[_owner]); 
        require(_numTokens <= allowed[_owner][msg.sender]); 

        balances[_owner] = balances[_owner].sub(_numTokens);
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_numTokens); 
        balances[_buyer] = balances[_buyer].add(_numTokens);

        emit Transfer(_owner, _buyer, _numTokens);

        return false;
    }

}