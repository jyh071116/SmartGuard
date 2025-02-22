 
pragma solidity ^0.4.23;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
pragma solidity ^0.4.23;





 
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

 
pragma solidity ^0.4.23;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
pragma solidity ^0.4.23;




 
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

 
pragma solidity ^0.4.23;





 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 
pragma solidity ^0.4.23;






 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 
pragma solidity ^0.4.23;


 
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

 
pragma solidity ^0.4.24;



 
contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    constructor(address[] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

     
    function releaseTokensTo(address buyer) internal returns(bool);

     
    function senderAllowedFor(address buyer)
    internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
    public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
    public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
    private returns (bool)
    {
         
        bytes32 hash = sha256(abi.encodePacked("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount));
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }

     
    function () public {
        revert();
    }
}
 
pragma solidity ^0.4.24;


contract ICOEngineInterface {

     
    function started() public view returns(bool);

     
    function ended() public view returns(bool);

     
    function startTime() public view returns(uint);

     
    function endTime() public view returns(uint);

     
     
     

     
     
     

     
    function totalTokens() public view returns(uint);

     
     
    function remainingTokens() public view returns(uint);

     
    function price() public view returns(uint);
}
 
pragma solidity ^0.4.23;






 
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
pragma solidity ^0.4.23;





 
contract StandardToken is ERC20, BasicToken {

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

 
pragma solidity ^0.4.23;





 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
pragma solidity ^0.4.23;





 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
pragma solidity ^0.4.23;




 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 
 
pragma solidity ^0.4.24;







contract GotToken is CanReclaimToken, MintableToken, PausableToken, BurnableToken {
    string public constant name = "GOToken";
    string public constant symbol = "GOT";
    uint8 public constant decimals = 18;

     
    constructor() public {
         
        paused = true;
    }
}


 
 

pragma solidity ^0.4.24;







contract PGOVault {
    using SafeMath for uint256;
    using SafeERC20 for GotToken;

    uint256[4] public vesting_offsets = [
        360 days,
        540 days,
        720 days,
        900 days
    ];

    uint256[4] public vesting_amounts = [
        0.875e7 * 1e18,
        0.875e7 * 1e18,
        0.875e7 * 1e18,
        0.875e7 * 1e18
    ];

    address public pgoWallet;
    GotToken public token;
    uint256 public start;
    uint256 public released;
    uint256 public vestingOffsetsLength = vesting_offsets.length;

     
    constructor(
        address _pgoWallet,
        address _token,
        uint256 _start
    )
        public
    {
        pgoWallet = _pgoWallet;
        token = GotToken(_token);
        start = _start;
    }

     
    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);

        released = released.add(unreleased);

        token.safeTransfer(pgoWallet, unreleased);
    }

     
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

     
    function vestedAmount() public view returns (uint256) {
        uint256 vested = 0;
        for (uint256 i = 0; i < vestingOffsetsLength; i = i.add(1)) {
            if (block.timestamp > start.add(vesting_offsets[i])) {
                vested = vested.add(vesting_amounts[i]);
            }
        }
        return vested;
    }
    
     
    function unreleasedAmount() public view returns (uint256) {
        uint256 unreleased = 0;
        for (uint256 i = 0; i < vestingOffsetsLength; i = i.add(1)) {
            unreleased = unreleased.add(vesting_amounts[i]);
        }
        return unreleased.sub(released);
    }
}


 
 

pragma solidity ^0.4.24;







contract PGOMonthlyInternalVault {
    using SafeMath for uint256;
    using SafeERC20 for GotToken;

    struct Investment {
        address beneficiary;
        uint256 totalBalance;
        uint256 released;
    }

     
    uint256 public constant VESTING_DIV_RATE = 21;                   
    uint256 public constant VESTING_INTERVAL = 30 days;              
    uint256 public constant VESTING_CLIFF = 90 days;                 
    uint256 public constant VESTING_DURATION = 720 days;             

    GotToken public token;
    uint256 public start;
    uint256 public end;
    uint256 public cliff;

     

     
     

    mapping(address => Investment) public investments;

     
    function init(address[] beneficiaries, uint256[] balances, uint256 startTime, address _token) public {
         
        require(token == address(0));
        require(beneficiaries.length == balances.length);

        start = startTime;
        cliff = start.add(VESTING_CLIFF);
        end = start.add(VESTING_DURATION);

        token = GotToken(_token);

        for (uint256 i = 0; i < beneficiaries.length; i = i.add(1)) {
            investments[beneficiaries[i]] = Investment(beneficiaries[i], balances[i], 0);
        }
    }

     
    function release(address beneficiary) public {
        uint256 unreleased = releasableAmount(beneficiary);
        require(unreleased > 0);

        investments[beneficiary].released = investments[beneficiary].released.add(unreleased);
        token.safeTransfer(beneficiary, unreleased);
    }

     
    function release() public {
        release(msg.sender);
    }

     
    function getInvestment(address beneficiary) public view returns(address, uint256, uint256) {
        return (
            investments[beneficiary].beneficiary,
            investments[beneficiary].totalBalance,
            investments[beneficiary].released
        );
    }

     
    function releasableAmount(address beneficiary) public view returns (uint256) {
        return vestedAmount(beneficiary).sub(investments[beneficiary].released);
    }

     
    function vestedAmount(address beneficiary) public view returns (uint256) {
        uint256 vested = 0;
        if (block.timestamp >= cliff && block.timestamp < end) {
             
            uint256 totalBalance = investments[beneficiary].totalBalance;
            uint256 monthlyBalance = totalBalance.div(VESTING_DIV_RATE);
            uint256 time = block.timestamp.sub(cliff);
            uint256 elapsedOffsets = time.div(VESTING_INTERVAL);
            uint256 vestedToSum = elapsedOffsets.mul(monthlyBalance);
            vested = vested.add(vestedToSum);
        }
        if (block.timestamp >= end) {
             
            vested = investments[beneficiary].totalBalance;
        }
        return vested;
    }
}


 
 

pragma solidity ^0.4.24;








contract PGOMonthlyPresaleVault is PGOMonthlyInternalVault {
     
    function vestedAmount(address beneficiary) public view returns (uint256) {
        uint256 vested = 0;

        if (block.timestamp >= start) {
             
            vested = investments[beneficiary].totalBalance.div(3);
        }
        if (block.timestamp >= cliff && block.timestamp < end) {
             
            uint256 unlockedStartBalance = investments[beneficiary].totalBalance.div(3);
            uint256 totalBalance = investments[beneficiary].totalBalance;
            uint256 lockedBalance = totalBalance.sub(unlockedStartBalance);
            uint256 monthlyBalance = lockedBalance.div(VESTING_DIV_RATE);
            uint256 daysToSkip = 90 days;
            uint256 time = block.timestamp.sub(start).sub(daysToSkip);
            uint256 elapsedOffsets = time.div(VESTING_INTERVAL);
            vested = vested.add(elapsedOffsets.mul(monthlyBalance));
        }
        if (block.timestamp >= end) {
             
            vested = investments[beneficiary].totalBalance;
        }
        return vested;
    }
}


 
 
pragma solidity ^0.4.24;












contract GotCrowdSale is Pausable, CanReclaimToken, ICOEngineInterface, KYCBase {
     
    uint256 public constant START_TIME = 1529416800;
     
    uint256 public constant END_TIME = 1530655140;                        
     
     
    uint256 public constant TOKEN_PER_ETHER = 740;                        

     
     
    uint256 public constant MONTHLY_INTERNAL_VAULT_CAP = 2.85e7 * 1e18;
     
    uint256 public constant PGO_UNLOCKED_LIQUIDITY_CAP = 1.5e7 * 1e18;
     
    uint256 public constant PGO_INTERNAL_RESERVE_CAP = 3.5e7 * 1e18;
     
    uint256 public constant RESERVED_PRESALE_CAP = 1.5754888e7 * 1e18;
     
     
     
     
    uint256 public constant RESERVATION_CAP = 0.4297111e7 * 1e18;
     
    uint256 public constant TOTAL_ICO_CAP = 0.5745112e7 * 1e18;

    uint256 public start;                                              
    uint256 public end;                                                
    uint256 public cap;                                                
    uint256 public tokenPerEth;
    uint256 public availableTokens;                                    
    address[] public kycSigners;                                       
    bool public capReached;
    uint256 public weiRaised;
    uint256 public tokensSold;

     
     
    PGOMonthlyInternalVault public pgoMonthlyInternalVault;
     
    PGOMonthlyPresaleVault public pgoMonthlyPresaleVault;
     
    PGOVault public pgoVault;

     
    address public pgoInternalReserveWallet;
     
    address public pgoUnlockedLiquidityWallet;
     
    address public wallet;

    GotToken public token;

     
    bool public didOwnerEndCrowdsale;

     
    constructor(
        address _token,
        address _wallet,
        address _pgoInternalReserveWallet,
        address _pgoUnlockedLiquidityWallet,
        address _pgoMonthlyInternalVault,
        address _pgoMonthlyPresaleVault,
        address[] _kycSigners
    )
        public
        KYCBase(_kycSigners)
    {
        require(END_TIME >= START_TIME);
        require(TOTAL_ICO_CAP > 0);

        start = START_TIME;
        end = END_TIME;
        cap = TOTAL_ICO_CAP;
        wallet = _wallet;
        tokenPerEth = TOKEN_PER_ETHER; 
        availableTokens = TOTAL_ICO_CAP;
        kycSigners = _kycSigners;

        token = GotToken(_token);
        pgoMonthlyInternalVault = PGOMonthlyInternalVault(_pgoMonthlyInternalVault);
        pgoMonthlyPresaleVault = PGOMonthlyPresaleVault(_pgoMonthlyPresaleVault);
        pgoInternalReserveWallet = _pgoInternalReserveWallet;
        pgoUnlockedLiquidityWallet = _pgoUnlockedLiquidityWallet;
        wallet = _wallet;
         
        pgoVault = new PGOVault(pgoInternalReserveWallet, address(token), END_TIME);
    }

     
    function mintPreAllocatedTokens() public onlyOwner {
        mintTokens(pgoUnlockedLiquidityWallet, PGO_UNLOCKED_LIQUIDITY_CAP);
        mintTokens(address(pgoVault), PGO_INTERNAL_RESERVE_CAP);
    }

     
    function initPGOMonthlyInternalVault(address[] beneficiaries, uint256[] balances)
        public
        onlyOwner
        equalLength(beneficiaries, balances)
    {
        uint256 totalInternalBalance = 0;
        uint256 balancesLength = balances.length;

        for (uint256 i = 0; i < balancesLength; i++) {
            totalInternalBalance = totalInternalBalance.add(balances[i]);
        }
         
        require(totalInternalBalance == MONTHLY_INTERNAL_VAULT_CAP);

        pgoMonthlyInternalVault.init(beneficiaries, balances, END_TIME, token);

        mintTokens(address(pgoMonthlyInternalVault), MONTHLY_INTERNAL_VAULT_CAP);
    }

     
    function initPGOMonthlyPresaleVault(address[] beneficiaries, uint256[] balances)
        public
        onlyOwner
        equalLength(beneficiaries, balances)
    {
        uint256 totalPresaleBalance = 0;
        uint256 balancesLength = balances.length;

        for (uint256 i = 0; i < balancesLength; i++) {
            totalPresaleBalance = totalPresaleBalance.add(balances[i]);
        }
         
        require(totalPresaleBalance == RESERVED_PRESALE_CAP);

        pgoMonthlyPresaleVault.init(beneficiaries, balances, END_TIME, token);

        mintTokens(address(pgoMonthlyPresaleVault), totalPresaleBalance);
    }

     
    function mintReservation(address[] beneficiaries, uint256[] balances)
        public
        onlyOwner
        equalLength(beneficiaries, balances)
    {
         

        uint256 totalReservationBalance = 0;
        uint256 balancesLength = balances.length;

        for (uint256 i = 0; i < balancesLength; i++) {
            totalReservationBalance = totalReservationBalance.add(balances[i]);
            uint256 amount = balances[i];
             
            tokensSold = tokensSold.add(amount);
             
            availableTokens = availableTokens.sub(amount);
            mintTokens(beneficiaries[i], amount);
        }

        require(totalReservationBalance <= RESERVATION_CAP);
    }

     
    function closeCrowdsale() public onlyOwner {
        require(block.timestamp >= START_TIME && block.timestamp < END_TIME);
        didOwnerEndCrowdsale = true;
    }

     
    function finalise() public onlyOwner {
        require(didOwnerEndCrowdsale || block.timestamp > end || capReached);

        token.finishMinting();
        token.unpause();

         
         
         
         
        token.transferOwnership(owner);
    }

     
    function price() public view returns (uint256 _price) {
        return tokenPerEth;
    }

     
    function started() public view returns(bool) {
        if (block.timestamp >= start) {
            return true;
        } else {
            return false;
        }
    }

     
    function ended() public view returns(bool) {
        if (block.timestamp >= end) {
            return true;
        } else {
            return false;
        }
    }

     
    function startTime() public view returns(uint) {
        return start;
    }

     
    function endTime() public view returns(uint) {
        return end;
    }

     
    function totalTokens() public view returns(uint) {
        return cap;
    }

     
    function remainingTokens() public view returns(uint) {
        return availableTokens;
    }

     
    function senderAllowedFor(address buyer) internal view returns(bool) {
        require(buyer != address(0));

        return true;
    }

     
    function releaseTokensTo(address buyer) internal returns(bool) {
        require(validPurchase());

        uint256 overflowTokens;
        uint256 refundWeiAmount;

        uint256 weiAmount = msg.value;
        uint256 tokenAmount = weiAmount.mul(price());

        if (tokenAmount >= availableTokens) {
            capReached = true;
            overflowTokens = tokenAmount.sub(availableTokens);
            tokenAmount = tokenAmount.sub(overflowTokens);
            refundWeiAmount = overflowTokens.div(price());
            weiAmount = weiAmount.sub(refundWeiAmount);
            buyer.transfer(refundWeiAmount);
        }

        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
        availableTokens = availableTokens.sub(tokenAmount);
        mintTokens(buyer, tokenAmount);
        forwardFunds(weiAmount);

        return true;
    }

     
    function forwardFunds(uint256 _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }

     
    function validPurchase() internal view returns (bool) {
        require(!paused && !capReached);
        require(block.timestamp >= start && block.timestamp <= end);

        return true;
    }

     
    function mintTokens(address to, uint256 amount) private {
        token.mint(to, amount);
    }

    modifier equalLength(address[] beneficiaries, uint256[] balances) {
        require(beneficiaries.length == balances.length);
        _;
    }
}