 

pragma solidity ^0.4.21;


 
contract ERC20Basic {
  uint256 public totalSupply;
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



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}


 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}


 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}



contract FreezableToken is StandardToken {
     
    mapping (bytes32 => uint64) internal chains;
     
    mapping (bytes32 => uint) internal freezings;
     
    mapping (address => uint) internal freezingBalance;

    event Freezed(address indexed to, uint64 release, uint amount);
    event Released(address indexed owner, uint amount);


     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner];
    }

     
    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezingBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }

     
    function freezingCount(address _addr) public view returns (uint count) {
        uint64 release = chains[toKey(_addr, 0)];
        while (release != 0) {
            count ++;
            release = chains[toKey(_addr, release)];
        }
    }

     
    function getFreezing(address _addr, uint _index) public view returns (uint64 _release, uint _balance) {
        for (uint i = 0; i < _index + 1; i ++) {
            _release = chains[toKey(_addr, _release)];
            if (_release == 0) {
                return;
            }
        }
        _balance = freezings[toKey(_addr, _release)];
    }

     
    function freezeTo(address _to, uint _amount, uint64 _until) public {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        Transfer(msg.sender, _to, _amount);
        emit Freezed(_to, _until, _amount);
    }

     
    function releaseOnce() public {
        bytes32 headKey = toKey(msg.sender, 0);
        uint64 head = chains[headKey];
        require(head != 0);
        require(uint64(block.timestamp) > head);
        bytes32 currentKey = toKey(msg.sender, head);

        uint64 next = chains[currentKey];

        uint amount = freezings[currentKey];
        delete freezings[currentKey];

        balances[msg.sender] = balances[msg.sender].add(amount);
        freezingBalance[msg.sender] = freezingBalance[msg.sender].sub(amount);

        if (next == 0) {
            delete chains[headKey];
        }
        else {
            chains[headKey] = next;
            delete chains[currentKey];
        }
        emit Released(msg.sender, amount);
    }

     
    function releaseAll() public returns (uint tokens) {
        uint release;
        uint balance;
        (release, balance) = getFreezing(msg.sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseOnce();
            tokens += balance;
            (release, balance) = getFreezing(msg.sender, 0);
        }
    }

    function toKey(address _addr, uint _release) internal pure returns (bytes32 result) {
         
        result = 0x5749534800000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_addr, 0x10000000000000000))
            result := or(result, _release)
        }
    }

    function freeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = toKey(_to, _until);
        bytes32 parentKey = toKey(_to, uint64(0));
        uint64 next = chains[parentKey];

        if (next == 0) {
            chains[parentKey] = _until;
            return;
        }

        bytes32 nextKey = toKey(_to, next);
        uint parent;

        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;

            next = chains[nextKey];
            nextKey = toKey(_to, next);
        }

        if (_until == next) {
            return;
        }

        if (next != 0) {
            chains[key] = next;
        }

        chains[parentKey] = _until;
    }
}

 

contract ERC223Receiver {
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC223Basic is ERC20Basic {
    function transfer(address to, uint value, bytes data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


contract SuccessfulERC223Receiver is ERC223Receiver {
    event Invoked(address from, uint value, bytes data);

    function tokenFallback(address _from, uint _value, bytes _data) public {
        emit Invoked(_from, _value, _data);
    }
}

contract FailingERC223Receiver is ERC223Receiver {
    function tokenFallback(address, uint, bytes) public {
        revert();
    }
}

contract ERC223ReceiverWithoutTokenFallback {
}

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



contract FreezableMintableToken is FreezableToken, MintableToken {
     
    function mintAndFreeze(address _to, uint _amount, uint64 _until) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        emit Mint(_to, _amount);
        emit Freezed(_to, _until, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}

contract Consts {
    uint constant TOKEN_DECIMALS = 18;
    uint8 constant TOKEN_DECIMALS_UINT8 = 18;
    uint constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    string constant TOKEN_NAME = "WM PROFESSIONAL";
    string constant TOKEN_SYMBOL = "WMPRO";
    bool constant PAUSED = false;
    address constant TARGET_USER = 0xf91189AE847537bdb3a12506F7b58492A4308212;
    
    uint constant START_TIME = 1531692000;
    
    bool constant CONTINUE_MINTING = false;
}




 
contract ERC223Token is ERC223Basic, BasicToken, FailingERC223Receiver {
    using SafeMath for uint;

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }
}


contract MainToken is Consts, FreezableMintableToken, BurnableToken, Pausable
    
{
    

    function name() pure public returns (string _name) {
        return TOKEN_NAME;
    }

    function symbol() pure public returns (string _symbol) {
        return TOKEN_SYMBOL;
    }

    function decimals() pure public returns (uint8 _decimals) {
        return TOKEN_DECIMALS_UINT8;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transfer(_to, _value);
    }
}




 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}



 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}


contract MainCrowdsale is Consts, FinalizableCrowdsale {
    function hasStarted() public constant returns (bool) {
        return now >= startTime;
    }

    function finalization() internal {
        super.finalization();

        if (PAUSED) {
            MainToken(token).unpause();
        }

        if (!CONTINUE_MINTING) {
            token.finishMinting();
        }

        token.transferOwnership(TARGET_USER);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate).div(1 ether);

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }
}


contract Checkable {
    address private serviceAccount;
     
    bool private triggered = false;

     
    event Triggered(uint balance);
     
    event Checked(bool isAccident);

    function Checkable() public {
        serviceAccount = msg.sender;
    }

     
    function changeServiceAccount(address _account) onlyService public {
        assert(_account != 0);
        serviceAccount = _account;
    }

     
    function isServiceAccount() view public returns (bool) {
        return msg.sender == serviceAccount;
    }

     
    function check() onlyService notTriggered payable public {
        if (internalCheck()) {
            emit Triggered(this.balance);
            triggered = true;
            internalAction();
        }
    }

     
    function internalCheck() internal returns (bool);

     
    function internalAction() internal;

    modifier onlyService {
        require(msg.sender == serviceAccount);
        _;
    }

    modifier notTriggered() {
        require(!triggered);
        _;
    }
}


contract BonusableCrowdsale is Consts, Crowdsale {

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 bonusRate = getBonusRate(weiAmount);
        uint256 tokens = weiAmount.mul(bonusRate).div(1 ether);

         
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function getBonusRate(uint256 weiAmount) internal view returns (uint256) {
        uint256 bonusRate = rate;

        
         
        uint[4] memory weiRaisedStartsBoundaries = [uint(0),uint(0),uint(0),uint(0)];
        uint[4] memory weiRaisedEndsBoundaries = [uint(20000000000000000000000),uint(20000000000000000000000),uint(20000000000000000000000),uint(20000000000000000000000)];
        uint64[4] memory timeStartsBoundaries = [uint64(1531692000),uint64(1532987940),uint64(1534802340),uint64(1536616740)];
        uint64[4] memory timeEndsBoundaries = [uint64(1532987940),uint64(1534802340),uint64(1536616740),uint64(1537826340)];
        uint[4] memory weiRaisedAndTimeRates = [uint(400),uint(300),uint(200),uint(100)];

        for (uint i = 0; i < 4; i++) {
            bool weiRaisedInBound = (weiRaisedStartsBoundaries[i] <= weiRaised) && (weiRaised < weiRaisedEndsBoundaries[i]);
            bool timeInBound = (timeStartsBoundaries[i] <= now) && (now < timeEndsBoundaries[i]);
            if (weiRaisedInBound && timeInBound) {
                bonusRate += bonusRate * weiRaisedAndTimeRates[i] / 1000;
            }
        }
        

        
         
        uint[2] memory weiAmountBoundaries = [uint(20000000000000000000),uint(10000000000000000000)];
        uint[2] memory weiAmountRates = [uint(0),uint(50)];

        for (uint j = 0; j < 2; j++) {
            if (weiAmount >= weiAmountBoundaries[j]) {
                bonusRate += bonusRate * weiAmountRates[j] / 1000;
                break;
            }
        }
        

        return bonusRate;
    }
}



contract TemplateCrowdsale is Consts, MainCrowdsale
    
    , BonusableCrowdsale
    
    
    , RefundableCrowdsale
    
    , CappedCrowdsale
    
{
    event Initialized();
    event TimesChanged(uint startTime, uint endTime, uint oldStartTime, uint oldEndTime);
    bool public initialized = false;

    function TemplateCrowdsale(MintableToken _token) public
        Crowdsale(START_TIME > now ? START_TIME : now, 1546297140, 1500 * TOKEN_DECIMAL_MULTIPLIER, 0x04B21fe3FBa3E8E548EfC51013E71242a55212cF)
        CappedCrowdsale(20000000000000000000000)
        
        RefundableCrowdsale(1000000000000000000000)
        
    {
        token = _token;
    }

    function init() public onlyOwner {
        require(!initialized);
        initialized = true;

        if (PAUSED) {
            MainToken(token).pause();
        }

        
        address[4] memory addresses = [address(0xdadc35adc3091329a2a593a6c2ba2f1539aae965),address(0xe99d4d19b23bfe83916b346814ee06043154ae78),address(0xaae82f543abb3abda4faacb887e2f802d48ed2da),address(0xaf2bde98fe39733b0f2a89053a3060c0bf8f77da)];
        uint[4] memory amounts = [uint(1500000000000000000000000),uint(5000000000000000000000000),uint(10000000000000000000000000),uint(3500000000000000000000000)];
        uint64[4] memory freezes = [uint64(1577746805),uint64(1577746805),uint64(0),uint64(0)];

        for (uint i = 0; i < addresses.length; i++) {
            if (freezes[i] == 0) {
                MainToken(token).mint(addresses[i], amounts[i]);
            } else {
                MainToken(token).mintAndFreeze(addresses[i], amounts[i], freezes[i]);
            }
        }
        

        transferOwnership(TARGET_USER);

        emit Initialized();
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return MintableToken(0);
    }

    

    

    

    

    
    function setEndTime(uint _endTime) public onlyOwner {
         
        require(now < endTime);
         
        require(now < _endTime);
        require(_endTime > startTime);
        emit TimesChanged(startTime, _endTime, startTime, endTime);
        endTime = _endTime;
    }
    

    

}