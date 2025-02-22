pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

library ExtendedMath {
     
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
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

contract ERC918Interface  {

    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

    function getChallengeNumber() public constant returns (bytes32);

    function getMiningDifficulty() public constant returns (uint);

    function getMiningTarget() public constant returns (uint);

    function getMiningReward() public constant returns (uint);

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;
    bytes32 public challengeNumber;


}

 
 
 

contract _0xGoldToken is ERC20Interface, Owned, ERC918Interface {

    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public latestDifficultyPeriodStarted;
    uint public epochCount;                  
    uint public _BLOCKS_PER_READJUSTMENT = 100;

     
    uint public  _MINIMUM_TARGET = 2**16;
    uint public  _MAXIMUM_TARGET = 2**234;
    
    address public parentAddress;      

    uint public miningTarget;
    bytes32 public challengeNumber;    

    uint public rewardEra;
    uint public maxSupplyForEra;

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    bool locked = false;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
     
     
    function _0xGoldToken() public onlyOwner{

        symbol = "0xGOLD";
        name = "0xGold Token";
        decimals = 10;
        _totalSupply = 5000000 * 10**uint(decimals);

        if(locked) revert();

        locked = true;
        tokensMinted = 500000000000000;  
        rewardEra = 0;
        maxSupplyForEra = _totalSupply.div(2);
        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;

        _startNewMiningEpoch();
        
        parentAddress = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;  
        
        balances[owner] = tokensMinted;
        Transfer(address(0), owner, tokensMinted);


    }

    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {

       
      bytes32 digest =  keccak256(challengeNumber, msg.sender, nonce );

       
      if (digest != challenge_digest) revert();

       
      if(uint256(digest) > miningTarget) revert();

       
      bytes32 solution = solutionForChallenge[challengeNumber];
      solutionForChallenge[challengeNumber] = digest;
      if(solution != 0x0) revert();   

      uint reward_amount = getMiningReward();
      balances[msg.sender] = balances[msg.sender].add(reward_amount);
      tokensMinted = tokensMinted.add(reward_amount);

       
      assert(tokensMinted <= maxSupplyForEra);

       
      lastRewardTo = msg.sender;
      lastRewardAmount = reward_amount;
      lastRewardEthBlockNumber = block.number;

      _startNewMiningEpoch();

      Mint(msg.sender, reward_amount, epochCount, challengeNumber );

      return true;

    }

     
    function _startNewMiningEpoch() internal {

       

       
       
      if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 2)
      {
        rewardEra = rewardEra + 1;
      }

       
       
      maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));

      epochCount = epochCount.add(1);

       
      if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
      {
        _reAdjustDifficulty();
      }

       
       
      challengeNumber = block.blockhash(block.number - 1);

    }

     
    function _reAdjustDifficulty() internal {

        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
         

         
        uint epochsMined = _BLOCKS_PER_READJUSTMENT;  

        uint targetEthBlocksPerDiffPeriod = epochsMined * 28;  

         
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );

          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
           

           
          miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));    
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );
          uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000);  

           
          miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));    
        }

        latestDifficultyPeriodStarted = block.number;

        if(miningTarget < _MINIMUM_TARGET)  
        {
          miningTarget = _MINIMUM_TARGET;
        }

        if(miningTarget > _MAXIMUM_TARGET)  
        {
          miningTarget = _MAXIMUM_TARGET;
        }
    }


     
    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

     
     function getMiningDifficulty() public constant returns (uint) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public constant returns (uint) {
       return miningTarget;
   }

     
    function getMiningReward() public constant returns (uint) {
          
         return (16 * 10**uint(decimals) ).div( 2**rewardEra ) ;
    }

     
    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {
        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
        return digest;
      }

       
      function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {
          bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
          if(uint256(digest) > testTarget) revert();
          return (digest == challenge_digest);
        }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
     
     
    
    function merge() public returns (bool success) {

            bytes32 future_challengeNumber = block.blockhash(block.number - 1);
            if(challengeNumber == future_challengeNumber){
                return false;  
            }

             
            if(ERC918Interface(parentAddress).lastRewardTo() != msg.sender){
                return false;  
            }
            
             

            if(ERC918Interface(parentAddress).lastRewardEthBlockNumber() != block.number){
                return false;  
            }


             bytes32 parentChallengeNumber = ERC918Interface(parentAddress).challengeNumber();
             bytes32 solution = solutionForChallenge[parentChallengeNumber];
             if(solution != 0x0) return false;   
             bytes32 digest = 'merge';
             solutionForChallenge[parentChallengeNumber] = digest;


             
            
                       uint reward_amount = getMiningReward();

            balances[msg.sender] = balances[msg.sender].add(reward_amount);

            tokensMinted = tokensMinted.add(reward_amount);


             
            assert(tokensMinted <= maxSupplyForEra);

             
            lastRewardTo = msg.sender;
            lastRewardAmount = reward_amount;
            lastRewardEthBlockNumber = block.number;


             _startNewMiningEpoch();

              Mint(msg.sender, reward_amount, epochCount, 0 );  

           return true;

        }


}