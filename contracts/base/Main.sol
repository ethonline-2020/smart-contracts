/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/

pragma solidity ^0.4.21;

import "./EIP20Interface.sol";
import "./ctokenInterface.sol";

contract pouch is EIP20Interface {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name; //fancy name: eg Simon Bucks
    uint8 public decimals; //How many decimals to show.
    string public symbol; //An identifier: eg SBX

    address daiAddress = 0xB5E5D0F8C0cbA267CD3D7035d6AdC8eBA7Df7Cdd;
    address cDaiAddress = 0x2B536482a01E620eE111747F8334B395a42A555E;

    EIP20Interface daiToken = EIP20Interface(daiAddress);
    ctokenInterface cDai = ctokenInterface(cDaiAddress);

    uint256 cDaiAllowedAmount = 35000000000000000000000000000000000000000000000000;

    constructor(string _tokenName, uint8 _decimalUnits, string _tokenSymbol)
        public
    {
        name = _tokenName; // Set the name for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        symbol = _tokenSymbol; // Set the symbol for display purposes

        daiToken.approve(cDaiAddress, cDaiAllowedAmount);
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function deposit(uint256 value) external {
        // Check if User's Dai Balance is more or equal to the value sent.
        uint256 userBalance = daiToken.balanceOf(msg.sender);
        require(
            userBalance >= value,
            "User does not have the required DAI balance."
        );

        daiToken.transferFrom(msg.sender, address(this), value);
        balances[msg.sender] += value;
        totalSupply += value;
        emit Transfer(
            0x0000000000000000000000000000000000000000,
            msg.sender,
            value
        );

        // Check for Dai allowance given from this contract to Cdai Contract
        uint256 cDaiAllowance = daiToken.allowance(address(this), cDaiAddress);
        if (cDaiAllowance < value) {
            uint256 amount = value > cDaiAllowedAmount
                ? value
                : cDaiAllowedAmount;
            daiToken.approve(cDaiAddress, amount);
        }

        cDai.mint(value);
    }

    function withdraw(uint256 value) external {
        // Check if User's PCH balance is more or equal to the value sent.
        uint256 pouchBalance = balanceOf(msg.sender);
        require(
            pouchBalance >= value,
            "User does not have the required PCH balance."
        );

        // Burn PCH
        transfer(0x0000000000000000000000000000000000000000, value);
        totalSupply -= value;

        // Redeem User's DAI from compound and transfer it to user.
        cDai.redeemUnderlying(value);
        daiToken.transfer(msg.sender, value);
    }

}
