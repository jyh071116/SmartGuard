pragma solidity ^0.4.23;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




 
contract StandardToken is ERC20Basic {

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
   
  mapping(address => uint256) balances;
   

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
    
  function batchTransfer(address[] _toList, uint256[] _tokensList) public  returns (bool) {
      require(_toList.length <= 100);
      require(_toList.length == _tokensList.length);
      
      uint256 sum = 0;
      for (uint32 index = 0; index < _tokensList.length; index++) {
          sum = sum.add(_tokensList[index]);
      }

       
      require (balances[msg.sender] >= sum);
        
      for (uint32 i = 0; i < _toList.length; i++) {
          transfer(_toList[i],_tokensList[i]);
      }
      return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
contract TokenVesting is StandardToken,Ownable {
  using SafeMath for uint256;

  event AddToVestMap(address vestcount);
  event DelFromVestMap(address vestcount);

  event Released(address vestcount,uint256 amount);
  event Revoked(address vestcount);

  struct tokenToVest{
      bool  exist;
      uint256  start;
      uint256  cliff;
      uint256  duration;
      uint256  torelease;
      uint256  released;
  }

   
  mapping (address=>tokenToVest) vestToMap;


   
  function addToVestMap(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    uint256 _torelease
  ) public onlyOwner{
    require(_beneficiary != address(0));
    require(_cliff <= _duration);
    require(_start > block.timestamp);
    require(!vestToMap[_beneficiary].exist);

    vestToMap[_beneficiary] = tokenToVest(true,_start,_start.add(_cliff),_duration,
        _torelease,uint256(0));

    emit AddToVestMap(_beneficiary);
  }


   
  function delFromVestMap(
    address _beneficiary
  ) public onlyOwner{
    require(_beneficiary != address(0));
    require(vestToMap[_beneficiary].exist);

    delete vestToMap[_beneficiary];

    emit DelFromVestMap(_beneficiary);
  }



   
  function release(address _beneficiary) public {

    tokenToVest storage value = vestToMap[_beneficiary];
    require(value.exist);
    uint256 unreleased = releasableAmount(_beneficiary);
    require(unreleased > 0);
    require(unreleased + value.released <= value.torelease);


    vestToMap[_beneficiary].released = vestToMap[_beneficiary].released.add(unreleased);

    transfer(_beneficiary, unreleased);

    emit Released(_beneficiary,unreleased);
  }

   
  function releasableAmount(address _beneficiary) public view returns (uint256) {
    return vestedAmount(_beneficiary).sub(vestToMap[_beneficiary].released);
  }

   
  function vestedAmount(address _beneficiary) public view returns (uint256) {

    tokenToVest storage value = vestToMap[_beneficiary];
     
    uint256 totalBalance = value.torelease;

    if (block.timestamp < value.cliff) {
      return 0;
    } else if (block.timestamp >= value.start.add(value.duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(value.start)).div(value.duration);
    }
  }
}

 

contract PausableToken is TokenVesting, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }
  
  function batchTransfer(address[] _toList, uint256[] _tokensList) public whenNotPaused returns (bool) {
      return super.batchTransfer(_toList, _tokensList);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function release(address _beneficiary) public whenNotPaused{
    super.release(_beneficiary);
  }
}

 
contract DELCToken is BurnableToken, MintableToken, PausableToken {
   
  string public name;
  string public symbol;
   
  uint8 public decimals;

  constructor() public {
    name = "DELC Relation Person Token";
    symbol = "DELC";
    decimals = 18;
    totalSupply = 10000000000 * 10 ** uint256(decimals);

     
    balances[msg.sender] = totalSupply;
    
    emit Transfer(address(0), msg.sender, totalSupply);
    
  }

   
   
   
   

   
   
   
}