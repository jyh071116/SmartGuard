pragma solidity ^0.4.18;

 

contract EtherDeltaI {

  uint public feeMake;  
  uint public feeTake;  

  mapping (address => mapping (address => uint)) public tokens;  
  mapping (address => mapping (bytes32 => bool)) public orders;  
  mapping (address => mapping (bytes32 => uint)) public orderFills;  

  function deposit() payable;

  function withdraw(uint amount);

  function depositToken(address token, uint amount);

  function withdrawToken(address token, uint amount);

  function balanceOf(address token, address user) constant returns (uint);

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce);

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount);

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool);

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint);

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s);

}

 

 
library KindMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

 

contract KeyValueStorage {

  mapping(address => mapping(bytes32 => uint256)) _uintStorage;
  mapping(address => mapping(bytes32 => address)) _addressStorage;
  mapping(address => mapping(bytes32 => bool)) _boolStorage;
  mapping(address => mapping(bytes32 => bytes32)) _bytes32Storage;

   

  function getAddress(bytes32 key) public view returns (address) {
      return _addressStorage[msg.sender][key];
  }

  function getUint(bytes32 key) public view returns (uint) {
      return _uintStorage[msg.sender][key];
  }

  function getBool(bytes32 key) public view returns (bool) {
      return _boolStorage[msg.sender][key];
  }

  function getBytes32(bytes32 key) public view returns (bytes32) {
      return _bytes32Storage[msg.sender][key];
  }

   

  function setAddress(bytes32 key, address value) public {
      _addressStorage[msg.sender][key] = value;
  }

  function setUint(bytes32 key, uint value) public {
      _uintStorage[msg.sender][key] = value;
  }

  function setBool(bytes32 key, bool value) public {
      _boolStorage[msg.sender][key] = value;
  }

  function setBytes32(bytes32 key, bytes32 value) public {
      _bytes32Storage[msg.sender][key] = value;
  }

   

  function deleteAddress(bytes32 key) public {
      delete _addressStorage[msg.sender][key];
  }

  function deleteUint(bytes32 key) public {
      delete _uintStorage[msg.sender][key];
  }

  function deleteBool(bytes32 key) public {
      delete _boolStorage[msg.sender][key];
  }

  function deleteBytes32(bytes32 key) public {
      delete _bytes32Storage[msg.sender][key];
  }

}

 

contract StorageStateful {
  KeyValueStorage public keyValueStorage;
}

 

contract StorageConsumer is StorageStateful {
  function StorageConsumer(address _storageAddress) public {
    require(_storageAddress != address(0));
    keyValueStorage = KeyValueStorage(_storageAddress);
  }
}

 

contract Token {
   
  function totalSupply() public returns (uint256);

   
   
  function balanceOf(address _owner) public returns (uint256);

   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

   
   
   
   
  function approve(address _spender, uint256 _value) public returns (bool);

   
   
   
  function allowance(address _owner, address _spender) public returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint256 public decimals;
  string public name;
}

 

contract EnclavesDEXProxy is StorageConsumer {
  using KindMath for uint256;

  address public admin;  
  address public feeAccount;  

  struct EtherDeltaInfo {
    uint256 feeMake;
    uint256 feeTake;
  }

  EtherDeltaInfo public etherDeltaInfo;

  uint256 public feeTake;  
  uint256 public feeAmountThreshold;  

  address public etherDelta;

  bool public useEIP712 = true;
  bytes32 public tradeABIHash;
  bytes32 public withdrawABIHash;

  bool freezeTrading;
  bool depositTokenLock;

  mapping (address => mapping (uint256 => bool)) nonceCheck;

  mapping (address => mapping (address => uint256)) public tokens;  
  mapping (address => mapping (bytes32 => bool)) public orders;  
  mapping (address => mapping (bytes32 => uint256)) public orderFills;  

  address internal implementation;
  address public proposedImplementation;
  uint256 public proposedTimestamp;

  event Upgraded(address _implementation);
  event UpgradedProposed(address _proposedImplementation, uint256 _proposedTimestamp);

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  function EnclavesDEXProxy(address _storageAddress, address _implementation, address _admin, address _feeAccount, uint256 _feeTake, uint256 _feeAmountThreshold, address _etherDelta, bytes32 _tradeABIHash, bytes32 _withdrawABIHash) public
    StorageConsumer(_storageAddress)
  {
    require(_implementation != address(0));
    implementation = _implementation;
    admin = _admin;
    feeAccount = _feeAccount;
    feeTake = _feeTake;
    feeAmountThreshold = _feeAmountThreshold;
    etherDelta = _etherDelta;
    tradeABIHash = _tradeABIHash;
    withdrawABIHash = _withdrawABIHash;
    etherDeltaInfo.feeMake = EtherDeltaI(etherDelta).feeMake();
    etherDeltaInfo.feeTake = EtherDeltaI(etherDelta).feeTake();
  }

  function getImplementation() public view returns(address) {
    return implementation;
  }

  function proposeUpgrade(address _proposedImplementation) public onlyAdmin {
    require(implementation != _proposedImplementation);
    require(_proposedImplementation != address(0));
    proposedImplementation = _proposedImplementation;
    proposedTimestamp = now + 2 weeks;
    UpgradedProposed(proposedImplementation, now);
  }

  function upgrade() public onlyAdmin {
    require(proposedImplementation != address(0));
    require(proposedTimestamp < now);
    implementation = proposedImplementation;
    Upgraded(implementation);
  }

  function () payable public {
    bytes memory data = msg.data;
    address impl = getImplementation();

    assembly {
      let result := delegatecall(gas, impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

}