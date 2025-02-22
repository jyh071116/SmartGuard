pragma solidity ^0.4.20;

 

pragma solidity^0.4.11;

library AttributeStore {
    struct Data {
        mapping(bytes32 => uint) store;
    }

    function getAttribute(Data storage self, bytes32 _UUID, string _attrName)
    public view returns (uint) {
        bytes32 key = keccak256(_UUID, _attrName);
        return self.store[key];
    }

    function setAttribute(Data storage self, bytes32 _UUID, string _attrName, uint _attrVal)
    public {
        bytes32 key = keccak256(_UUID, _attrName);
        self.store[key] = _attrVal;
    }
}

 

pragma solidity^0.4.11;

library DLL {

  uint constant NULL_NODE_ID = 0;

  struct Node {
    uint next;
    uint prev;
  }

  struct Data {
    mapping(uint => Node) dll;
  }

  function isEmpty(Data storage self) public view returns (bool) {
    return getStart(self) == NULL_NODE_ID;
  }

  function contains(Data storage self, uint _curr) public view returns (bool) {
    if (isEmpty(self) || _curr == NULL_NODE_ID) {
      return false;
    } 

    bool isSingleNode = (getStart(self) == _curr) && (getEnd(self) == _curr);
    bool isNullNode = (getNext(self, _curr) == NULL_NODE_ID) && (getPrev(self, _curr) == NULL_NODE_ID);
    return isSingleNode || !isNullNode;
  }

  function getNext(Data storage self, uint _curr) public view returns (uint) {
    return self.dll[_curr].next;
  }

  function getPrev(Data storage self, uint _curr) public view returns (uint) {
    return self.dll[_curr].prev;
  }

  function getStart(Data storage self) public view returns (uint) {
    return getNext(self, NULL_NODE_ID);
  }

  function getEnd(Data storage self) public view returns (uint) {
    return getPrev(self, NULL_NODE_ID);
  }

   
  function insert(Data storage self, uint _prev, uint _curr, uint _next) public {
    require(_curr != NULL_NODE_ID);

    remove(self, _curr);

    require(_prev == NULL_NODE_ID || contains(self, _prev));
    require(_next == NULL_NODE_ID || contains(self, _next));

    require(getNext(self, _prev) == _next);
    require(getPrev(self, _next) == _prev);

    self.dll[_curr].prev = _prev;
    self.dll[_curr].next = _next;

    self.dll[_prev].next = _curr;
    self.dll[_next].prev = _curr;
  }

  function remove(Data storage self, uint _curr) public {
    if (!contains(self, _curr)) {
      return;
    }

    uint next = getNext(self, _curr);
    uint prev = getPrev(self, _curr);

    self.dll[next].prev = prev;
    self.dll[prev].next = next;

    delete self.dll[_curr];
  }
}

 

 
 
pragma solidity ^0.4.8;

contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract PLCRVoting {

     
     
     

    event _VoteCommitted(uint indexed pollID, uint numTokens, address indexed voter);
    event _VoteRevealed(uint indexed pollID, uint numTokens, uint votesFor, uint votesAgainst, uint indexed choice, address indexed voter);
    event _PollCreated(uint voteQuorum, uint commitEndDate, uint revealEndDate, uint indexed pollID, address indexed creator);
    event _VotingRightsGranted(uint numTokens, address indexed voter);
    event _VotingRightsWithdrawn(uint numTokens, address indexed voter);
    event _TokensRescued(uint indexed pollID, address indexed voter);

     
     
     

    using AttributeStore for AttributeStore.Data;
    using DLL for DLL.Data;
    using SafeMath for uint;

    struct Poll {
        uint commitEndDate;      
        uint revealEndDate;      
        uint voteQuorum;	     
        uint votesFor;		     
        uint votesAgainst;       
        mapping(address => bool) didCommit;   
        mapping(address => bool) didReveal;    
    }

     
     
     

    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    mapping(uint => Poll) public pollMap;  
    mapping(address => uint) public voteTokenBalance;  

    mapping(address => DLL.Data) dllMap;
    AttributeStore.Data store;

    EIP20Interface public token;

     
    function init(address _token) public {
        require(_token != 0 && address(token) == 0);

        token = EIP20Interface(_token);
        pollNonce = INITIAL_POLL_NONCE;
    }

     
     
     

     
    function requestVotingRights(uint _numTokens) public {
        require(token.balanceOf(msg.sender) >= _numTokens);
        voteTokenBalance[msg.sender] += _numTokens;
        require(token.transferFrom(msg.sender, this, _numTokens));
        emit _VotingRightsGranted(_numTokens, msg.sender);
    }

     
    function withdrawVotingRights(uint _numTokens) external {
        uint availableTokens = voteTokenBalance[msg.sender].sub(getLockedTokens(msg.sender));
        require(availableTokens >= _numTokens);
        voteTokenBalance[msg.sender] -= _numTokens;
        require(token.transfer(msg.sender, _numTokens));
        emit _VotingRightsWithdrawn(_numTokens, msg.sender);
    }

     
    function rescueTokens(uint _pollID) public {
        require(isExpired(pollMap[_pollID].revealEndDate));
        require(dllMap[msg.sender].contains(_pollID));

        dllMap[msg.sender].remove(_pollID);
        emit _TokensRescued(_pollID, msg.sender);
    }

     
    function rescueTokensInMultiplePolls(uint[] _pollIDs) public {
         
        for (uint i = 0; i < _pollIDs.length; i++) {
            rescueTokens(_pollIDs[i]);
        }
    }

     
     
     

     
    function commitVote(uint _pollID, bytes32 _secretHash, uint _numTokens, uint _prevPollID) public {
        require(commitPeriodActive(_pollID));

         
         
        if (voteTokenBalance[msg.sender] < _numTokens) {
            uint remainder = _numTokens.sub(voteTokenBalance[msg.sender]);
            requestVotingRights(remainder);
        }

         
        require(voteTokenBalance[msg.sender] >= _numTokens);
         
        require(_pollID != 0);
         
        require(_secretHash != 0);

         
        require(_prevPollID == 0 || dllMap[msg.sender].contains(_prevPollID));

        uint nextPollID = dllMap[msg.sender].getNext(_prevPollID);

         
        if (nextPollID == _pollID) {
            nextPollID = dllMap[msg.sender].getNext(_pollID);
        }

        require(validPosition(_prevPollID, nextPollID, msg.sender, _numTokens));
        dllMap[msg.sender].insert(_prevPollID, _pollID, nextPollID);

        bytes32 UUID = attrUUID(msg.sender, _pollID);

        store.setAttribute(UUID, "numTokens", _numTokens);
        store.setAttribute(UUID, "commitHash", uint(_secretHash));

        pollMap[_pollID].didCommit[msg.sender] = true;
        emit _VoteCommitted(_pollID, _numTokens, msg.sender);
    }

     
    function commitVotes(uint[] _pollIDs, bytes32[] _secretHashes, uint[] _numsTokens, uint[] _prevPollIDs) external {
         
        require(_pollIDs.length == _secretHashes.length);
        require(_pollIDs.length == _numsTokens.length);
        require(_pollIDs.length == _prevPollIDs.length);

         
        for (uint i = 0; i < _pollIDs.length; i++) {
            commitVote(_pollIDs[i], _secretHashes[i], _numsTokens[i], _prevPollIDs[i]);
        }
    }

     
    function validPosition(uint _prevID, uint _nextID, address _voter, uint _numTokens) public constant returns (bool valid) {
        bool prevValid = (_numTokens >= getNumTokens(_voter, _prevID));
         
        bool nextValid = (_numTokens <= getNumTokens(_voter, _nextID) || _nextID == 0);
        return prevValid && nextValid;
    }

     
    function revealVote(uint _pollID, uint _voteOption, uint _salt) public {
         
        require(revealPeriodActive(_pollID));
        require(pollMap[_pollID].didCommit[msg.sender]);                          
        require(!pollMap[_pollID].didReveal[msg.sender]);                         
        require(keccak256(_voteOption, _salt) == getCommitHash(msg.sender, _pollID));  

        uint numTokens = getNumTokens(msg.sender, _pollID);

        if (_voteOption == 1) { 
            pollMap[_pollID].votesFor += numTokens;
        } else {
            pollMap[_pollID].votesAgainst += numTokens;
        }

        dllMap[msg.sender].remove(_pollID);  
        pollMap[_pollID].didReveal[msg.sender] = true;

        emit _VoteRevealed(_pollID, numTokens, pollMap[_pollID].votesFor, pollMap[_pollID].votesAgainst, _voteOption, msg.sender);
    }

     
    function revealVotes(uint[] _pollIDs, uint[] _voteOptions, uint[] _salts) external {
         
        require(_pollIDs.length == _voteOptions.length);
        require(_pollIDs.length == _salts.length);

         
        for (uint i = 0; i < _pollIDs.length; i++) {
            revealVote(_pollIDs[i], _voteOptions[i], _salts[i]);
        }
    }

     
    function getNumPassingTokens(address _voter, uint _pollID, uint _salt) public constant returns (uint correctVotes) {
        require(pollEnded(_pollID));
        require(pollMap[_pollID].didReveal[_voter]);

        uint winningChoice = isPassed(_pollID) ? 1 : 0;
        bytes32 winnerHash = keccak256(winningChoice, _salt);
        bytes32 commitHash = getCommitHash(_voter, _pollID);

        require(winnerHash == commitHash);

        return getNumTokens(_voter, _pollID);
    }

     
     
     

     
    function startPoll(uint _voteQuorum, uint _commitDuration, uint _revealDuration) public returns (uint pollID) {
        pollNonce = pollNonce + 1;

        uint commitEndDate = block.timestamp.add(_commitDuration);
        uint revealEndDate = commitEndDate.add(_revealDuration);

        pollMap[pollNonce] = Poll({
            voteQuorum: _voteQuorum,
            commitEndDate: commitEndDate,
            revealEndDate: revealEndDate,
            votesFor: 0,
            votesAgainst: 0
        });

        emit _PollCreated(_voteQuorum, commitEndDate, revealEndDate, pollNonce, msg.sender);
        return pollNonce;
    }

     
    function isPassed(uint _pollID) constant public returns (bool passed) {
        require(pollEnded(_pollID));

        Poll memory poll = pollMap[_pollID];
        return (100 * poll.votesFor) > (poll.voteQuorum * (poll.votesFor + poll.votesAgainst));
    }

     
     
     

     
    function getTotalNumberOfTokensForWinningOption(uint _pollID) constant public returns (uint numTokens) {
        require(pollEnded(_pollID));

        if (isPassed(_pollID))
            return pollMap[_pollID].votesFor;
        else
            return pollMap[_pollID].votesAgainst;
    }

     
    function pollEnded(uint _pollID) constant public returns (bool ended) {
        require(pollExists(_pollID));

        return isExpired(pollMap[_pollID].revealEndDate);
    }

     
    function commitPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].commitEndDate);
    }

     
    function revealPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].revealEndDate) && !commitPeriodActive(_pollID);
    }

     
    function didCommit(address _voter, uint _pollID) constant public returns (bool committed) {
        require(pollExists(_pollID));

        return pollMap[_pollID].didCommit[_voter];
    }

     
    function didReveal(address _voter, uint _pollID) constant public returns (bool revealed) {
        require(pollExists(_pollID));

        return pollMap[_pollID].didReveal[_voter];
    }

     
    function pollExists(uint _pollID) constant public returns (bool exists) {
        return (_pollID != 0 && _pollID <= pollNonce);
    }

     
     
     

     
    function getCommitHash(address _voter, uint _pollID) constant public returns (bytes32 commitHash) {
        return bytes32(store.getAttribute(attrUUID(_voter, _pollID), "commitHash"));
    }

     
    function getNumTokens(address _voter, uint _pollID) constant public returns (uint numTokens) {
        return store.getAttribute(attrUUID(_voter, _pollID), "numTokens");
    }

     
    function getLastNode(address _voter) constant public returns (uint pollID) {
        return dllMap[_voter].getPrev(0);
    }

     
    function getLockedTokens(address _voter) constant public returns (uint numTokens) {
        return getNumTokens(_voter, getLastNode(_voter));
    }

     
    function getInsertPointForNumTokens(address _voter, uint _numTokens, uint _pollID)
    constant public returns (uint prevNode) {
       
      uint nodeID = getLastNode(_voter);
      uint tokensInNode = getNumTokens(_voter, nodeID);

       
      while(nodeID != 0) {
         
        tokensInNode = getNumTokens(_voter, nodeID);
        if(tokensInNode <= _numTokens) {  
          if(nodeID == _pollID) {
             
            nodeID = dllMap[_voter].getPrev(nodeID);
          }
           
          return nodeID; 
        }
         
        nodeID = dllMap[_voter].getPrev(nodeID);
      }

       
      return nodeID;
    }

     
     
     

     
    function isExpired(uint _terminationDate) constant public returns (bool expired) {
        return (block.timestamp > _terminationDate);
    }

     
    function attrUUID(address _user, uint _pollID) public pure returns (bytes32 UUID) {
        return keccak256(_user, _pollID);
    }
}

 

pragma solidity^0.4.11;




contract Parameterizer {

     
     
     

    event _ReparameterizationProposal(string name, uint value, bytes32 propID, uint deposit, uint appEndDate, address indexed proposer);
    event _NewChallenge(bytes32 indexed propID, uint challengeID, uint commitEndDate, uint revealEndDate, address indexed challenger);
    event _ProposalAccepted(bytes32 indexed propID, string name, uint value);
    event _ProposalExpired(bytes32 indexed propID);
    event _ChallengeSucceeded(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _ChallengeFailed(bytes32 indexed propID, uint indexed challengeID, uint rewardPool, uint totalTokens);
    event _RewardClaimed(uint indexed challengeID, uint reward, address indexed voter);


     
     
     

    using SafeMath for uint;

    struct ParamProposal {
        uint appExpiry;
        uint challengeID;
        uint deposit;
        string name;
        address owner;
        uint processBy;
        uint value;
    }

    struct Challenge {
        uint rewardPool;         
        address challenger;      
        bool resolved;           
        uint stake;              
        uint winningTokens;      
        mapping(address => bool) tokenClaims;
    }

     
     
     

    mapping(bytes32 => uint) public params;

     
    mapping(uint => Challenge) public challenges;

     
    mapping(bytes32 => ParamProposal) public proposals;

     
    EIP20Interface public token;
    PLCRVoting public voting;
    uint public PROCESSBY = 604800;  

     
    function init(
        address _token,
        address _plcr,
        uint[] _parameters
    ) public {
        require(_token != 0 && address(token) == 0);
        require(_plcr != 0 && address(voting) == 0);

        token = EIP20Interface(_token);
        voting = PLCRVoting(_plcr);

         
        set("minDeposit", _parameters[0]);
        
         
        set("pMinDeposit", _parameters[1]);

         
        set("applyStageLen", _parameters[2]);

         
        set("pApplyStageLen", _parameters[3]);

         
        set("commitStageLen", _parameters[4]);
        
         
        set("pCommitStageLen", _parameters[5]);
        
         
        set("revealStageLen", _parameters[6]);

         
        set("pRevealStageLen", _parameters[7]);

         
        set("dispensationPct", _parameters[8]);

         
        set("pDispensationPct", _parameters[9]);

         
        set("voteQuorum", _parameters[10]);

         
        set("pVoteQuorum", _parameters[11]);
    }

     
     
     

     
    function proposeReparameterization(string _name, uint _value) public returns (bytes32) {
        uint deposit = get("pMinDeposit");
        bytes32 propID = keccak256(_name, _value);

        if (keccak256(_name) == keccak256("dispensationPct") ||
            keccak256(_name) == keccak256("pDispensationPct")) {
            require(_value <= 100);
        }

        require(!propExists(propID));  
        require(get(_name) != _value);  

         
        proposals[propID] = ParamProposal({
            appExpiry: now.add(get("pApplyStageLen")),
            challengeID: 0,
            deposit: deposit,
            name: _name,
            owner: msg.sender,
            processBy: now.add(get("pApplyStageLen"))
                .add(get("pCommitStageLen"))
                .add(get("pRevealStageLen"))
                .add(PROCESSBY),
            value: _value
        });

        require(token.transferFrom(msg.sender, this, deposit));  

        emit _ReparameterizationProposal(_name, _value, propID, deposit, proposals[propID].appExpiry, msg.sender);
        return propID;
    }

     
    function challengeReparameterization(bytes32 _propID) public returns (uint challengeID) {
        ParamProposal memory prop = proposals[_propID];
        uint deposit = prop.deposit;

        require(propExists(_propID) && prop.challengeID == 0);

         
        uint pollID = voting.startPoll(
            get("pVoteQuorum"),
            get("pCommitStageLen"),
            get("pRevealStageLen")
        );

        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: SafeMath.sub(100, get("pDispensationPct")).mul(deposit).div(100),
            stake: deposit,
            resolved: false,
            winningTokens: 0
        });

        proposals[_propID].challengeID = pollID;        

         
        require(token.transferFrom(msg.sender, this, deposit));

        var (commitEndDate, revealEndDate,) = voting.pollMap(pollID);

        emit _NewChallenge(_propID, pollID, commitEndDate, revealEndDate, msg.sender);
        return pollID;
    }

     
    function processProposal(bytes32 _propID) public {
        ParamProposal storage prop = proposals[_propID];
        address propOwner = prop.owner;
        uint propDeposit = prop.deposit;

        
         
         
        if (canBeSet(_propID)) {
             
             
            set(prop.name, prop.value);
            emit _ProposalAccepted(_propID, prop.name, prop.value);
            delete proposals[_propID];
            require(token.transfer(propOwner, propDeposit));
        } else if (challengeCanBeResolved(_propID)) {
             
            resolveChallenge(_propID);
        } else if (now > prop.processBy) {
             
            emit _ProposalExpired(_propID);
            delete proposals[_propID];
            require(token.transfer(propOwner, propDeposit));
        } else {
             
             
            revert();
        }

        assert(get("dispensationPct") <= 100);
        assert(get("pDispensationPct") <= 100);

         
        now.add(get("pApplyStageLen"))
            .add(get("pCommitStageLen"))
            .add(get("pRevealStageLen"))
            .add(PROCESSBY);

        delete proposals[_propID];
    }

     
    function claimReward(uint _challengeID, uint _salt) public {
         
        require(challenges[_challengeID].tokenClaims[msg.sender] == false);
        require(challenges[_challengeID].resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID, _salt);
        uint reward = voterReward(msg.sender, _challengeID, _salt);

         
         
        challenges[_challengeID].winningTokens -= voterTokens;
        challenges[_challengeID].rewardPool -= reward;

         
        challenges[_challengeID].tokenClaims[msg.sender] = true;

        emit _RewardClaimed(_challengeID, reward, msg.sender);
        require(token.transfer(msg.sender, reward));
    }

     
    function claimRewards(uint[] _challengeIDs, uint[] _salts) public {
         
        require(_challengeIDs.length == _salts.length);

         
        for (uint i = 0; i < _challengeIDs.length; i++) {
            claimReward(_challengeIDs[i], _salts[i]);
        }
    }

     
     
     

     
    function voterReward(address _voter, uint _challengeID, uint _salt)
    public view returns (uint) {
        uint winningTokens = challenges[_challengeID].winningTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
        return (voterTokens * rewardPool) / winningTokens;
    }

     
    function canBeSet(bytes32 _propID) view public returns (bool) {
        ParamProposal memory prop = proposals[_propID];

        return (now > prop.appExpiry && now < prop.processBy && prop.challengeID == 0);
    }

     
    function propExists(bytes32 _propID) view public returns (bool) {
        return proposals[_propID].processBy > 0;
    }

     
    function challengeCanBeResolved(bytes32 _propID) view public returns (bool) {
        ParamProposal memory prop = proposals[_propID];
        Challenge memory challenge = challenges[prop.challengeID];

        return (prop.challengeID > 0 && challenge.resolved == false && voting.pollEnded(prop.challengeID));
    }

     
    function challengeWinnerReward(uint _challengeID) public view returns (uint) {
        if(voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
             
            return 2 * challenges[_challengeID].stake;
        }

        return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
    }

     
    function get(string _name) public view returns (uint value) {
        return params[keccak256(_name)];
    }

     
    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
        return challenges[_challengeID].tokenClaims[_voter];
    }

     
     
     

     
    function resolveChallenge(bytes32 _propID) private {
        ParamProposal memory prop = proposals[_propID];
        Challenge storage challenge = challenges[prop.challengeID];

         
        uint reward = challengeWinnerReward(prop.challengeID);

        challenge.winningTokens = voting.getTotalNumberOfTokensForWinningOption(prop.challengeID);
        challenge.resolved = true;

        if (voting.isPassed(prop.challengeID)) {  
            if(prop.processBy > now) {
                set(prop.name, prop.value);
            }
            emit _ChallengeFailed(_propID, prop.challengeID, challenge.rewardPool, challenge.winningTokens);
            require(token.transfer(prop.owner, reward));
        }
        else {  
            emit _ChallengeSucceeded(_propID, prop.challengeID, challenge.rewardPool, challenge.winningTokens);
            require(token.transfer(challenges[prop.challengeID].challenger, reward));
        }
    }

     
    function set(string _name, uint _value) private {
        params[keccak256(_name)] = _value;
    }
}

 

 

pragma solidity ^0.4.19;

 

contract ProxyFactory {
    event ProxyDeployed(address proxyAddress, address targetAddress);
    event ProxiesDeployed(address[] proxyAddresses, address targetAddress);

    function createManyProxies(uint256 _count, address _target, bytes _data)
        public
    {
        address[] memory proxyAddresses = new address[](_count);

        for (uint256 i = 0; i < _count; ++i) {
            proxyAddresses[i] = createProxyImpl(_target, _data);
        }

        ProxiesDeployed(proxyAddresses, _target);
    }

    function createProxy(address _target, bytes _data)
        public
        returns (address proxyContract)
    {
        proxyContract = createProxyImpl(_target, _data);

        ProxyDeployed(proxyContract, _target);
    }
    
    function createProxyImpl(address _target, bytes _data)
        internal
        returns (address proxyContract)
    {
        assembly {
            let contractCode := mload(0x40)  
           
            mstore(add(contractCode, 0x0b), _target)  
            mstore(sub(contractCode, 0x09), 0x000000000000000000603160008181600b9039f3600080808080368092803773)  
            mstore(add(contractCode, 0x2b), 0x5af43d828181803e808314602f57f35bfd000000000000000000000000000000)  

            proxyContract := create(0, contractCode, 60)  
            if iszero(extcodesize(proxyContract)) {
                revert(0, 0)
            }
           
             
            let dataLength := mload(_data) 
            if iszero(iszero(dataLength)) {
                if iszero(call(gas, proxyContract, 0, add(_data, 0x20), dataLength, 0, 0)) {
                    revert(0, 0)
                }
            }
        }
    }
}

 

 
pragma solidity ^0.4.8;


contract EIP20 is EIP20Interface {

    uint256 constant MAX_UINT256 = 2**256 - 1;

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

     function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 

contract PLCRFactory {

  event newPLCR(address creator, EIP20 token, PLCRVoting plcr);

  ProxyFactory public proxyFactory;
  PLCRVoting public canonizedPLCR;

   
  constructor() {
    canonizedPLCR = new PLCRVoting();
    proxyFactory = new ProxyFactory();
  }

   
  function newPLCRBYOToken(EIP20 _token) public returns (PLCRVoting) {
    PLCRVoting plcr = PLCRVoting(proxyFactory.createProxy(canonizedPLCR, ""));
    plcr.init(_token);

    emit newPLCR(msg.sender, _token, plcr);

    return plcr;
  }
  
   
  function newPLCRWithToken(
    uint _supply,
    string _name,
    uint8 _decimals,
    string _symbol
  ) public returns (PLCRVoting) {
     
    EIP20 token = new EIP20(_supply, _name, _decimals, _symbol);
    token.transfer(msg.sender, _supply);

     
    PLCRVoting plcr = PLCRVoting(proxyFactory.createProxy(canonizedPLCR, ""));
    plcr.init(token);

    emit newPLCR(msg.sender, token, plcr);

    return plcr;
  }
}

 

contract ParameterizerFactory {

    event NewParameterizer(address creator, address token, address plcr, Parameterizer parameterizer);

    PLCRFactory public plcrFactory;
    ProxyFactory public proxyFactory;
    Parameterizer public canonizedParameterizer;

     
    constructor(PLCRFactory _plcrFactory) public {
        plcrFactory = _plcrFactory;
        proxyFactory = plcrFactory.proxyFactory();
        canonizedParameterizer = new Parameterizer();
    }

     
    function newParameterizerBYOToken(
        EIP20 _token,
        uint[] _parameters
    ) public returns (Parameterizer) {
        PLCRVoting plcr = plcrFactory.newPLCRBYOToken(_token);
        Parameterizer parameterizer = Parameterizer(proxyFactory.createProxy(canonizedParameterizer, ""));

        parameterizer.init(
            _token,
            plcr,
            _parameters
        );
        emit NewParameterizer(msg.sender, _token, plcr, parameterizer);
        return parameterizer;
    }

     
    function newParameterizerWithToken(
        uint _supply,
        string _name,
        uint8 _decimals,
        string _symbol,
        uint[] _parameters
    ) public returns (Parameterizer) {
         
         
        PLCRVoting plcr = plcrFactory.newPLCRWithToken(_supply, _name, _decimals, _symbol);
        EIP20 token = EIP20(plcr.token());
        token.transfer(msg.sender, _supply);

         
        Parameterizer parameterizer = Parameterizer(proxyFactory.createProxy(canonizedParameterizer, ""));
        parameterizer.init(
            token,
            plcr,
            _parameters
        );

        emit NewParameterizer(msg.sender, token, plcr, parameterizer);
        return parameterizer;
    }
}