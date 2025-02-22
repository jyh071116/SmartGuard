



pragma solidity ^0.4.18;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}






contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




contract StandardTokenExt is StandardToken {

  
  function isToken() public pure returns (bool weAre) {
    return true;
  }
}


contract BurnableToken is StandardTokenExt {

  
  address public constant BURN_ADDRESS = 0;

  
  event Burned(address burner, uint burnedAmount);

  
  function burn(uint burnAmount) public {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply_ = totalSupply_.sub(burnAmount);
    Burned(burner, burnAmount);

    
    
    
    Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}


contract UpgradeAgent {

  uint public originalSupply;

  
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}



contract UpgradeableToken is StandardTokenExt {

  
  address public upgradeMaster;

  
  UpgradeAgent public upgradeAgent;

  
  uint256 public totalUpgraded;

  
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  
  event UpgradeAgentSet(address agent);

  
  function UpgradeableToken(address _upgradeMaster) public {
    upgradeMaster = _upgradeMaster;
  }

  
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        
        revert();
      }

      
      if (value == 0) revert();

      balances[msg.sender] = balances[msg.sender].sub(value);

      
      totalSupply_ = totalSupply_.sub(value);
      totalUpgraded = totalUpgraded.add(value);

      
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

  
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
        
        revert();
      }

      if (agent == 0x0) revert();
      
      if (msg.sender != upgradeMaster) revert();
      
      if (getUpgradeState() == UpgradeState.Upgrading) revert();

      upgradeAgent = UpgradeAgent(agent);

      
      if(!upgradeAgent.isUpgradeAgent()) revert();
      
      if (upgradeAgent.originalSupply() != totalSupply_) revert();

      UpgradeAgentSet(upgradeAgent);
  }

  
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  
  function setUpgradeMaster(address master) public {
      if (master == 0x0) revert();
      if (msg.sender != upgradeMaster) revert();
      upgradeMaster = master;
  }

  
  function canUpgrade() public view returns(bool);

}


contract Ownable {
  address public owner;


  
  function Ownable() public {
    owner = msg.sender;
  }


  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}





contract ReleasableToken is ERC20, Ownable {

  
  address public releaseAgent;

  
  bool public released = false;

  
  mapping (address => bool) public transferAgents;

  
  mapping (address => bool) public lockAddresses;

  
  modifier canTransfer(address _sender) {
    if(lockAddresses[_sender]) {
      revert();
    }
    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }

    _;
  }

  
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    
    releaseAgent = addr;
  }

  
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  
  function setLockAddress(address addr, bool state) onlyOwner inReleaseState(false) public {
    lockAddresses[addr] = state;
  }

  
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        revert();
    }
    _;
  }

  
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        revert();
    }
    _;
  }

  function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
    
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
    
    return super.transferFrom(_from, _to, _value);
  }

}


library SafeMathLib {

  function times(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b)  internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}




contract MintableToken is StandardTokenExt, Ownable {

  using SafeMathLib for uint;

  bool public mintingFinished = false;

  
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);
  event Minted(address receiver, uint amount);

  
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply_ = totalSupply_.plus(amount);
    balances[receiver] = balances[receiver].plus(amount);

    
    
    Transfer(0, receiver, amount);
  }

  
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
    
    if(!mintAgents[msg.sender]) {
        revert();
    }
    _;
  }

  
  modifier canMint() {
    if(mintingFinished) revert();
    _;
  }
}



contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken {

  
  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;

  
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable) public
    UpgradeableToken(msg.sender) {

    
    
    
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply_ = _initialSupply;

    decimals = _decimals;

    
    balances[owner] = totalSupply_;

    if(totalSupply_ > 0) {
      Minted(owner, totalSupply_);
    }

    
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply_ == 0) {
        revert(); 
      }
    }
  }

  
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

  
  function canUpgrade() public constant returns(bool) {
    return released;
  }

  
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}



contract BurnableCrowdsaleToken is BurnableToken, CrowdsaleToken {

  function BurnableCrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable) public
    CrowdsaleToken(_name, _symbol, _initialSupply, _decimals, _mintable) {

  }
}




contract AMLToken is BurnableCrowdsaleToken {

  
  event OwnerReclaim(address fromWhom, uint amount);

  function AMLToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable) public BurnableCrowdsaleToken(_name, _symbol, _initialSupply, _decimals, _mintable) {

  }

  
  
  
  function transferToOwner(address fromWhom) public onlyOwner {
    if (released) revert();

    uint amount = balanceOf(fromWhom);
    balances[fromWhom] = balances[fromWhom].sub(amount);
    balances[owner] = balances[owner].add(amount);
    Transfer(fromWhom, owner, amount);
    OwnerReclaim(fromWhom, amount);
  }
}