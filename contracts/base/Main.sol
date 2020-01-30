pragma solidity >=0.5.0 <0.6.0;


interface MintInterface {
       function mint(uint) external returns (uint);
       function redeemUnderlying(uint redeemAmount) external returns (uint);
       function balanceOf(address owner) external view returns (uint);
}  

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);

}

contract PayZap {
    uint public totalDaiDeposits; 
    mapping (address => bool) registeredUser;
    mapping(address=>uint) balances;
    address daiAddress = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
    address cDaiAddress = 0x6D7F0754FFeb405d23C51CE938289d4835bE3b14;

      MintInterface cDai = MintInterface(cDaiAddress);
      TokenInterface dai = TokenInterface(daiAddress);
         
    function checkDaiAllowance() view external returns(uint){
        return dai.allowance(msg.sender, address(this));
    }
    
    
    function userBalance() view external returns (uint) {
        return balances[msg.sender];
    }

    function deposit(uint amount) external {
        dai.transferFrom(msg.sender, address(this), amount);
        totalDaiDeposits += amount;
        dai.approve(cDaiAddress,amount);
        cDai.mint(amount);
        balances[msg.sender] += amount;
        registeredUser[msg.sender] = true;
    }
    
    

    
    function transact(address recipient, uint amount)external {
        require(registeredUser[msg.sender] == true, 'Sender not registered');
        require(amount <= balances[msg.sender], 'Insufficient Funds');
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
    }
    
    function withdraw(uint amount) external {
        require(amount <= balances[msg.sender], 'Insufficient Funds');
         cDai.redeemUnderlying(amount);
         dai.transfer(msg.sender, amount);
         balances[msg.sender] -= amount;
    }
    
    function contractBalance() view external returns (uint) {
        return cDai.balanceOf(address(this));
    }
    
}
    
    
