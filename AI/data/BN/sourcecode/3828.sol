pragma solidity ^0.4.18;

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

 


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ERC918Interface {
  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

contract MiningKingInterface {
    function getKing() public returns (address);
    function transferKing(address newKing) public;

    event TransferKing(address from, address to);
}

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;

}



contract Owned {

    address public owner;

    address public newOwner;


    event OwnershipTransferred(address indexed _from, address indexed _to);


    function Owned() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}





contract LavaWallet is Owned {


  using SafeMath for uint;

   
   mapping(address => mapping (address => uint256)) balances;

    
   mapping(address => mapping (address => mapping (address => uint256))) allowed;

   mapping(address => uint256) depositedTokens;

   mapping(bytes32 => uint256) burnedSignatures;


    address public relayKingContract;



  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);
  event Transfer(address indexed from, address indexed to,address token, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender,address token, uint tokens);

  function LavaWallet(address relayKingContractAddress ) public  {
    relayKingContract = relayKingContractAddress;
  }


   
  function() public payable {
      revert();
  }


    
  function depositTokens(address from, address token, uint256 tokens ) public returns (bool success)
  {
       

      if(!ERC20Interface(token).transferFrom(from, this, tokens)) revert();


      balances[token][from] = balances[token][from].add(tokens);
      depositedTokens[token] = depositedTokens[token].add(tokens);

      Deposit(token, from, tokens, balances[token][from]);

      return true;
  }


   
  function withdrawTokens(address token, uint256 tokens) public returns (bool success){
    balances[token][msg.sender] = balances[token][msg.sender].sub(tokens);
    depositedTokens[token] = depositedTokens[token].sub(tokens);

    if(!ERC20Interface(token).transfer(msg.sender, tokens)) revert();


     Withdraw(token, msg.sender, tokens, balances[token][msg.sender]);
     return true;
  }

   
  function withdrawTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success) {
      balances[token][from] = balances[token][from].sub(tokens);
      depositedTokens[token] = depositedTokens[token].sub(tokens);
      allowed[token][from][to] = allowed[token][from][to].sub(tokens);

      if(!ERC20Interface(token).transfer(to, tokens)) revert();


      Withdraw(token, from, tokens, balances[token][from]);
      return true;
  }


  function balanceOf(address token,address user) public constant returns (uint) {
       return balances[token][user];
   }



   
  function approveTokens(address spender, address token, uint tokens) public returns (bool success) {
      allowed[token][msg.sender][spender] = tokens;
      Approval(msg.sender, token, spender, tokens);
      return true;
  }

   
   
   function transferTokens(address to, address token, uint tokens) public returns (bool success) {
        balances[token][msg.sender] = balances[token][msg.sender].sub(tokens);
        balances[token][to] = balances[token][to].add(tokens);
        Transfer(msg.sender, token, to, tokens);
        return true;
    }


     
     
   function transferTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success) {
       balances[token][from] = balances[token][from].sub(tokens);
       allowed[token][from][to] = allowed[token][from][to].sub(tokens);
       balances[token][to] = balances[token][to].add(tokens);
       Transfer(token, from, to, tokens);
       return true;
   }

    
    
   function getLavaTypedDataHash(bytes methodname, address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                     uint256 expires, uint256 nonce) public constant returns (bytes32)
   {
         bytes32 hardcodedSchemaHash = 0x8fd4f9177556bbc74d0710c8bdda543afd18cc84d92d64b5620d5f1881dceb37;  


        bytes32 typedDataHash = sha3(
            hardcodedSchemaHash,
            sha3(methodname,from,to,this,token,tokens,relayerReward,expires,nonce)
          );

        return typedDataHash;
   }


   function tokenApprovalWithSignature(address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                     uint256 expires, bytes32 sigHash, bytes signature) internal returns (bool success)
   {

       address recoveredSignatureSigner = ECRecovery.recover(sigHash,signature);

        
       require(from == recoveredSignatureSigner);

       require(msg.sender == getRelayingKing()
         || msg.sender == from
         || msg.sender == to);   

        
       require(block.number < expires);

       uint burnedSignature = burnedSignatures[sigHash];
       burnedSignatures[sigHash] = 0x1;  
       if(burnedSignature != 0x0 ) revert();

        
       allowed[token][from][msg.sender] = relayerReward;
       Approval(from, token, msg.sender, relayerReward);

        
       if(!transferTokensFrom(from, msg.sender, token, relayerReward)) revert();

        
       allowed[token][from][to] = tokens;
       Approval(from, token, to, tokens);


       return true;
   }

   function approveTokensWithSignature(address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                     uint256 expires, uint256 nonce, bytes signature) public returns (bool success)
   {


       bytes32 sigHash = getLavaTypedDataHash('approve',from,to,token,tokens,relayerReward,expires,nonce);

       if(!tokenApprovalWithSignature(from,to,token,tokens,relayerReward,expires,sigHash,signature)) revert();


       return true;
   }

    
  function transferTokensFromWithSignature(address from, address to,  address token, uint256 tokens,  uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature) public returns (bool success)
  {


       

      bytes32 sigHash = getLavaTypedDataHash('transfer',from,to,token,tokens,relayerReward,expires,nonce);

      if(!tokenApprovalWithSignature(from,to,token,tokens,relayerReward,expires,sigHash,signature)) revert();

       
      if(!transferTokensFrom( from, to, token, tokens)) revert();


      return true;

  }

    
  function withdrawTokensFromWithSignature(address from, address to,  address token, uint256 tokens,  uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature) public returns (bool success)
  {

       

      bytes32 sigHash = getLavaTypedDataHash('withdraw',from,to,token,tokens,relayerReward,expires,nonce);

      if(!tokenApprovalWithSignature(from,to,token,tokens,relayerReward,expires,sigHash,signature)) revert();

       
      if(!withdrawTokensFrom( from, to, token, tokens)) revert();


      return true;

  }




    function tokenAllowance(address token, address tokenOwner, address spender) public constant returns (uint remaining) {

        return allowed[token][tokenOwner][spender];

    }



     function burnSignature(bytes methodname, address from, address to, address token, uint256 tokens, uint256 relayerReward, uint256 expires, uint256 nonce,  bytes signature) public returns (bool success)
     {

        bytes32 sigHash = getLavaTypedDataHash(methodname,from,to,token,tokens,relayerReward,expires,nonce);


         address recoveredSignatureSigner = ECRecovery.recover(sigHash,signature);

          
         if(recoveredSignatureSigner != from) revert();

          
         if(from != msg.sender) revert();

          
         uint burnedSignature = burnedSignatures[sigHash];
         burnedSignatures[sigHash] = 0x2;  
         if(burnedSignature != 0x0 ) revert();

         return true;
     }


      
      
     function signatureBurnStatus(bytes32 digest) public view returns (uint)
     {
       return (burnedSignatures[digest]);
     }




        
     function receiveApproval(address from, uint256 tokens, address token, bytes data) public returns (bool success) {


       return depositTokens(from, token, tokens );

     }

      
     function approveAndCall(bytes methodname, address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                       uint256 expires, uint256 nonce, bytes signature ) public returns (bool success) {



            bytes32 sigHash = getLavaTypedDataHash(methodname,from,to,token,tokens,relayerReward,expires,nonce);



          if(!tokenApprovalWithSignature(from,to,token,tokens,relayerReward,expires,sigHash,signature)) revert();

          ApproveAndCallFallBack(to).receiveApproval(from, tokens, token, methodname);

         return true;

     }

     function getRelayingKing() public returns (address)
     {
       return MiningKingInterface(relayKingContract).getKing();
     }



  

  
  

  

 function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

     
     uint tokenBalance = ERC20Interface(tokenAddress).balanceOf(this);

      
     uint undepositedTokens = tokenBalance.sub(depositedTokens[tokenAddress]);

      
     assert(tokens <= undepositedTokens);

     if(!ERC20Interface(tokenAddress).transfer(owner, tokens)) revert();



     return true;

 }



}