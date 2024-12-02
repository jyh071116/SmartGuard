pragma solidity ^0.4.11;

 
contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract WaltonTokenLocker {

    address public beneficiary;
    uint256 public releaseTime;
    string constant public name = "refund locker";

    Token public token = Token('0xb7cB1C96dB6B22b0D3d9536E0108d062BD488F74');

    function WaltonTokenLocker() public {
         
        beneficiary = address('0x38A9e09E14397Fe3A5Fe59dfc1d98D8B8897D610');
        releaseTime = 1538236800;      
    }

     
     
    function release() public {
        if (block.timestamp < releaseTime)
            throw;

        uint256 totalTokenBalance = token.balanceOf(this);
        if (totalTokenBalance > 0)
            if (!token.transfer(beneficiary, totalTokenBalance))
                throw;
    }
     
    function releaseToken(address _tokenContractAddress) public {
        if (block.timestamp < releaseTime)
            throw;

        Token _token = Token(_tokenContractAddress);
        uint256 totalTokenBalance = _token.balanceOf(this);
        if (totalTokenBalance > 0)
            if (!_token.transfer(beneficiary, totalTokenBalance))
                throw;
    }


     
    function releaseTimestamp() public constant returns (uint timestamp) {
        return releaseTime;
    }

    function currentTimestamp() public constant returns (uint timestamp) {
        return block.timestamp;
    }

    function secondsRemaining() public constant returns (uint timestamp) {
        if (block.timestamp < releaseTime)
            return releaseTime - block.timestamp;
        else
            return 0;
    }

    function tokenLocked() public constant returns (uint amount) {
        return token.balanceOf(this);
    }

     
     
     
     

}