pragma solidity >=0.5.0;

interface PTokenInterface {
    // function transfer(address, uint256) external returns (bool);
    // function transferFrom(address, address, uint256) external returns (bool);
    // function balanceOf(address owner) external view returns (uint256);
    // function allowance(address, address) external view returns (uint256);
    // function approve(address, uint256) external returns (bool);

    // function permitted(
    //     address,
    //     address,
    //     uint256,
    //     uint256,
    //     bool,
    //     uint8,
    //     bytes32,
    //     bytes32
    // ) external;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event Reward(address indexed _to, uint256 _value);
}
