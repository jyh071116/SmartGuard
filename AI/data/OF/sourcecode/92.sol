pragma solidity ^0.4.24;






library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    
    
    
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }
  
  

  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    
    
    
    return a / b;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {

  address public owner;

  
   constructor() public {
    owner = address(0xEFeAc37a6a5Fb3630313742a2FADa6760C6FF653);
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address newOwner)public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}


contract ERC20Basic is Ownable {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => bool) public frozenAccount;

  event FrozenFunds(
      address target, 
      bool frozen
      );
      
  event Burn(
        address indexed burner, 
        uint256 value
        );
        
        
      
   function burnTokens(address _who, uint256 _amount) public onlyOwner {
       require(balances[_who] >= _amount);
       
       balances[_who] = balances[_who].sub(_amount);
       
       totalSupply = totalSupply.sub(_amount);
       
       emit Burn(_who, _amount);
       emit Transfer(_who, address(0), _amount);
   }


    
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
  
  function transfer(address _to, uint256 _value)public returns (bool) {
    require(!frozenAccount[msg.sender]);
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  
  function balanceOf(address _owner)public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract AdvanceToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;
  

  
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(!frozenAccount[_from]);                     

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

  
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract CRYPTOLANCERSToken is AdvanceToken {

  string public constant name = "CRYPTOLANCERS";
  string public constant symbol = "CLT";
  uint256 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 100000000 * 10**decimals;

  
  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[0xEFeAc37a6a5Fb3630313742a2FADa6760C6FF653] = totalSupply;
 }
}