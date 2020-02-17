pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./TokenInterface.sol";
import "./cTokenInterface.sol";
import "./PTokenInterface.sol";
import "./SafeMath.sol";

contract Pouch is PTokenInterface {
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    bytes32 public DOMAIN_SEPARATOR;
    address public admin;
    address cDaiAddress = 0xe7bc397DBd069fC7d0109C0636d06888bb50668c;
    cTokenInterface cDai = cTokenInterface(cDaiAddress);
    address daiAddress = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    TokenInterface daiToken = TokenInterface(daiAddress);

    bytes32 public constant DEPOSIT_TYPEHASH = keccak256(
        "Deposit(address holder,uint256 value)"
    );
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256(
        "Withdraw(address holder,uint256 value)"
    );
    bytes32 public constant TRANSACT_TYPEHASH = keccak256(
        "transact(address holder,address to,uint256 value)"
    );

    // // // Required Interfaces

    constructor(address tokenAddress) public {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Pouch"),
                keccak256("1"),
                42, // kovan chainId
                tokenAddress
            )
        );
        admin = tokenAddress;
    }

    using SafeMath for uint256;

    // ** Internal Functions **

    function _mint(address _to, uint256 _value)
        internal
        returns (bool success)
    {
        balances[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function _transfer(address _to, uint256 _value)
        internal
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function getExchangeRate() public view returns (uint256) {
        return cDai.exchangeRateStored();
    }

    function getMySupply() public view returns (uint256) {
        TokenInterface pouch = TokenInterface(admin);
        return pouch.supplyOf();
    }
    function _randomReward() internal view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(now, msg.sender, block.number))
        ) %
            3;
        return randomnumber.mul(1e18);
    }

    function checkContractBalance() public view returns (uint256) {
        return cDai.balanceOf(admin);
    }

    function checkSignature(
        address holder,
        uint256 value,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes32 TYPEHASH
    ) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(TYPEHASH, holder, value))
            )
        );

        require(holder != address(0), "Pouch/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Pouch/invalid-permit");
        require(value <= balances[holder], "Insufficient Funds");

        return true;
    }

    // ** Implementation of Delegate Calls **

    // ** Deposit DAI **
    function deposit(
        address holder,
        uint256 value,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public returns (bool) {
        require(checkSignature(holder, value, r, s, v, DEPOSIT_TYPEHASH));

        // ** Check for sufficient Funds **

        require(daiToken.balanceOf(msg.sender) >= value, "Insufficient Funds");

        daiToken.transferFrom(msg.sender, address(this), value); // **Transfer User's DAI**
        _mint(msg.sender, value); // **Mint PCH tokens for the User**
        daiToken.approve(cDaiAddress, value);
        cDai.mint(value); // **Mint cDai  **
        return true;
    }

    // ** Withdraw DAI**
    function withdraw(
        address holder,
        uint256 value,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public returns (bool) {
        require(checkSignature(holder, value, r, s, v, WITHDRAW_TYPEHASH));

        //          ** Burn Pouch Token **
        _transfer(address(0), value);
        totalSupply -= value;

        //         **  Redeem User's DAI from compound and transfer it to user.**
        cDai.redeemUnderlying(value);
        daiToken.transfer(msg.sender, value);
        return true;
    }

    function transact(
        address holder,
        address to,
        uint256 value,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public returns (bool) {
        require(to != address(0));
        require(checkSignature(holder, value, r, s, v, TRANSACT_TYPEHASH));

        // ** Transfer Funds **
        _transfer(to, value);

        // ** Transfer Rewards,if Any. **
        if (value >= 1e19) {
            uint256 checkProfitInDai = _checkProfits().mul(getExchangeRate());
            uint256 profitInDai = checkProfitInDai.div(1e18);
            if (profitInDai >= 1e18) {
                uint256 myReward = _randomReward();
                cDai.redeemUnderlying(myReward);
                daiToken.transfer(msg.sender, myReward);
                return true;
            }
        }
        return true;
    }

    function _spitProfits() public returns (bool) {
        uint256 profit = _checkProfits();
        cDai.transfer(msg.sender, profit);
        return true;
    }

    function _checkProfits() public view returns (uint256) {
        uint256 contractSupply = getMySupply();
        uint256 adjustedTotalSupply = contractSupply.mul(1e8);
        uint256 ourContractBalance = cDai.balanceOf(admin);
        uint256 cDaiExchangeRate = cDai.exchangeRateStored();
        uint256 cDaiExchangeRateDivided = cDaiExchangeRate.div(1e10);

        uint256 currentPrice = adjustedTotalSupply.div(cDaiExchangeRateDivided);
        uint256 profit = ourContractBalance.sub(currentPrice);
        return profit;
    }

}
