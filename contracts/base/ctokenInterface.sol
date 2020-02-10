pragma solidity ^0.4.21;

interface ctokenInterface {
    function mint(uint256) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function exchangeRateCurrent() external view returns (uint256);
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
}
