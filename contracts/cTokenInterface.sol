pragma solidity >=0.5.0;

interface cTokenInterface {
    function mint(uint256) external returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function borrowRatePerBlock() external view returns (uint256);
    function balanceOfUnderlying(address account)
        external
        view
        returns (uint256);
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);
}
