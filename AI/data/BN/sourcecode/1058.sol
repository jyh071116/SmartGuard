pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
contract EscapeMmmEvents {
    event onOffered (
        address indexed playerAddress,
        uint256 offerAmount,
        address affiliateAddress,
        address siteOwner,
        uint256 timestamp
    );
    event onAccepted (
        address indexed playerAddress,
        uint256 acceptAmount
    );
    event onWithdraw (
        address indexed playerAddress,
        uint256 withdrawAmount
    );
    event onAirDrop (
        address indexed playerAddress,
        uint256 airdropAmount,
        uint256 offerAmount
    );
}

 
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

 
 
 
 
contract EFMAPlatform is EscapeMmmEvents, Ownable {
    using SafeMath for *;

     
     
     
     
    string constant public name = "Escape Financial Mutual Aid Platform";
    string constant public symbol = "EFMAP";

    address private xTokenAddress = 0xfe8b40a35ff222c8475385f74e77d33954531b41;

    uint8 public feePercent_ = 1;  
    uint8 public affPercent_ = 5;  
    uint8 public sitePercent_ = 5;  
    uint8 public airDropPercent_ = 10;  
    uint8 public xTokenPercent_ = 3;  

    uint256 constant public interestPeriod_ = 1 hours;
    uint256 constant public maxInterestTime_ = 7 days;
     
     
     
     
    uint256 public airDropPool_;
    uint256 public airDropTracker_ = 0;  

     
     
     
     
    mapping (address => FMAPDatasets.Player) public players_;
    mapping (address => mapping (uint256 => FMAPDatasets.OfferInfo)) public playerOfferOrders_;  
    mapping (address => mapping (uint256 => uint256)) public playerAcceptOrders_;  
    uint256 private restOfferAmount_ = 0;  
    FMAPDatasets.AcceptOrder private currentOrder_;  
    mapping (uint256 => FMAPDatasets.AcceptOrder) public acceptOrders_;  

    address private teamXWallet;
    uint256 public _totalFee;
    uint256 public _totalXT;

     
     
     
     
    constructor() public {
        teamXWallet = msg.sender;
         
        FMAPDatasets.AcceptOrder memory ao;
        ao.nextOrder = 1;
        ao.playerAddress = msg.sender;
        ao.acceptAmount = 1 finney;
        acceptOrders_[0] = ao;
        currentOrder_ = ao;
    }

    function transFee() public onlyOwner {
        teamXWallet.transfer(_totalFee);
    }
    function setTeamWallet(address wallet) public onlyOwner {
        teamXWallet = wallet;
    }
    function setXToken(address xToken) public onlyOwner {
        xTokenAddress = xToken;
    }

     
     
     
     
    modifier isHuman() {
        require(AddressUtils.isContract(msg.sender) == false, "sorry, only human allowed");
        _;
    }

     
     
     
     
     
    function() isHuman() public payable {
        FMAPDatasets.OfferInfo memory offerInfo = packageOfferInfo(address(0), msg.value);
        offerCore(offerInfo, false);
    }

    function offerHelp(address siteOwner, address affiliate) isHuman() public payable {
        FMAPDatasets.OfferInfo memory offerInfo = packageOfferInfo(siteOwner, msg.value);
        bool updateAff = false;
        if(affiliate != address(0) && affiliate != offerInfo.affiliateAddress) {
            offerInfo.affiliateAddress = affiliate;
            updateAff = true;
        }
        offerCore(offerInfo, updateAff);

        emit onOffered(offerInfo.playerAddress, offerInfo.offerAmount, offerInfo.affiliateAddress, offerInfo.siteOwner, offerInfo.timestamp);
    }

    function offerHelpUsingBalance(address siteOwner, address affiliate, uint256 ethAmount) isHuman() public {
        require(ethAmount <= players_[msg.sender].balance, "sorry, you don't have enough balance");
        FMAPDatasets.OfferInfo memory offerInfo = packageOfferInfo(siteOwner, ethAmount);
        bool updateAff = false;
        if(affiliate != address(0) && affiliate != offerInfo.affiliateAddress) {
            offerInfo.affiliateAddress = affiliate;
            updateAff = true;
        }
        players_[msg.sender].balance = players_[msg.sender].balance.sub(ethAmount);
        offerCore(offerInfo, updateAff);

        emit onOffered(offerInfo.playerAddress, offerInfo.offerAmount, offerInfo.affiliateAddress, offerInfo.siteOwner, offerInfo.timestamp);
    }

    function acceptHelp(uint256 amount) isHuman() public returns (uint256 canAcceptLeft) {
        (canAcceptLeft, ) = calcCanAcceptAmount(msg.sender, true, 0);
        require(amount <= canAcceptLeft, "sorry, you don't have enough acceptable amount");

        uint256 _nextOrderId = currentOrder_.nextOrder;
        FMAPDatasets.AcceptOrder memory acceptOrder;
        acceptOrder.playerAddress = msg.sender;
        acceptOrder.acceptAmount = amount;
        acceptOrder.acceptedAmount = 0;
        acceptOrder.nextOrder = _nextOrderId + 1;
        acceptOrders_[_nextOrderId] = acceptOrder;

         
        if (currentOrder_.orderId == _nextOrderId || currentOrder_.acceptAmount == currentOrder_.acceptedAmount) {
            currentOrder_ = acceptOrder;
        }

        players_[acceptOrder.playerAddress].totalAccepted = amount.add(players_[acceptOrder.playerAddress].totalAccepted);
        players_[acceptOrder.playerAddress].acceptOrderCount++;

        if (restOfferAmount_ > 0) {
            matching();
        }
        calcAndSetPlayerTotalCanAccept(acceptOrder.playerAddress, amount);

        emit onAccepted(acceptOrder.playerAddress, acceptOrder.acceptAmount);

        return (canAcceptLeft);
    }

    function withdraw() isHuman() public {
        require(players_[msg.sender].balance >= 1 finney, "sorry, withdraw at least 1 finney");

        uint256 _balance = players_[msg.sender].balance;
        players_[msg.sender].balance = 0;
        msg.sender.transfer(_balance);

        emit onWithdraw(msg.sender, _balance);
    }

     
     
     
     
    function getCanAcceptAmount(address playerAddr) public view returns (uint256 canAccept, uint256 earliest) {
        (canAccept, earliest) = calcCanAcceptAmount(playerAddr, true, 0);
        return (canAccept, earliest);
    }

    function getBalance(address playerAddr) public view returns (uint256) {
        uint256 balance = players_[playerAddr].balance;
        return (balance);
    }

    function getPlayerInfo(address playerAddr) public view
        returns (uint256 totalAssets, uint256 nextPeriodAssets, uint256 balance, uint256 canAccept, uint256 airdrop, uint256 offered, uint256 accepted, uint256 affiliateEarned, uint256 siteEarned, uint256 nextUpdateTime) {
        FMAPDatasets.Player memory _player = players_[playerAddr];
        uint256 _calculatedCanAccept;
        (_calculatedCanAccept, ) = calcCanAcceptAmount(playerAddr, false, 0);
        totalAssets = _player.balance.add(_calculatedCanAccept);
        (_calculatedCanAccept, ) = calcCanAcceptAmount(playerAddr, false, interestPeriod_);
        nextPeriodAssets = _player.balance.add(_calculatedCanAccept);
        (canAccept, nextUpdateTime) = calcCanAcceptAmount(playerAddr, true, 0);

        return (totalAssets, nextPeriodAssets, _player.balance, canAccept, _player.airDroped, _player.totalOffered, _player.totalAccepted, _player.affiliateEarned, _player.siteEarned, nextUpdateTime);
    }

     
     
     
     
    function packageOfferInfo(address siteOwner, uint256 amount) private view returns (FMAPDatasets.OfferInfo) {
        FMAPDatasets.OfferInfo memory offerInfo;
        offerInfo.playerAddress = msg.sender;
        offerInfo.offerAmount = amount;
        offerInfo.affiliateAddress = players_[msg.sender].lastAffiliate;
        offerInfo.siteOwner = siteOwner;
        offerInfo.timestamp = block.timestamp;
        offerInfo.interesting = true;
        return (offerInfo);
    }

     
     
     
     
    function offerCore(FMAPDatasets.OfferInfo memory offerInfo, bool updateAff) private {
        uint256 _fee = (offerInfo.offerAmount).mul(feePercent_).div(100);  
        uint256 _aff = (offerInfo.offerAmount).mul(affPercent_).div(100);  
        uint256 _sit = (offerInfo.offerAmount).mul(sitePercent_).div(100);  
        uint256 _air = (offerInfo.offerAmount).mul(airDropPercent_).div(100);  
        uint256 _xt = (offerInfo.offerAmount).mul(xTokenPercent_).div(100);  

        uint256 _leftAmount = offerInfo.offerAmount;

        if (offerInfo.affiliateAddress == offerInfo.siteOwner) {  
            offerInfo.affiliateAddress = address(0);
        }
         
        players_[offerInfo.playerAddress].totalOffered = (offerInfo.offerAmount).add(players_[offerInfo.playerAddress].totalOffered);
        if (offerInfo.affiliateAddress == address(0) || offerInfo.affiliateAddress == offerInfo.playerAddress) {
            _fee = _fee.add(_aff);
            _aff = 0;
        }
        if (offerInfo.siteOwner == address(0) || offerInfo.siteOwner == offerInfo.playerAddress) {
            _fee = _fee.add(_sit);
            _sit = 0;
        }

        _totalFee = _totalFee.add(_fee);
        _totalXT = _totalXT.add(_xt);
        if (_totalXT > 1 finney) {
            xTokenAddress.transfer(_totalXT);
        }

        _leftAmount = _leftAmount.sub(_fee);

         
        if (_aff > 0) {
            players_[offerInfo.affiliateAddress].balance = _aff.add(players_[offerInfo.affiliateAddress].balance);
            players_[offerInfo.affiliateAddress].affiliateEarned = _aff.add(players_[offerInfo.affiliateAddress].affiliateEarned);
            _leftAmount = _leftAmount.sub(_aff);
        }
         
        if (_sit > 0) {
            players_[offerInfo.siteOwner].balance = _sit.add(players_[offerInfo.siteOwner].balance);
            players_[offerInfo.siteOwner].siteEarned = _sit.add(players_[offerInfo.siteOwner].siteEarned);
            _leftAmount = _leftAmount.sub(_sit);
        }

         
        if (offerInfo.offerAmount >= 1 finney) {
            airDropTracker_ = airDropTracker_ + FMAPMath.calcTrackerCount(offerInfo.offerAmount);
            if (airdrop() == true) {
                uint256 _airdrop = FMAPMath.calcAirDropAmount(offerInfo.offerAmount);
                players_[offerInfo.playerAddress].balance = _airdrop.add(players_[offerInfo.playerAddress].balance);
                players_[offerInfo.playerAddress].airDroped = _airdrop.add(players_[offerInfo.playerAddress].airDroped);
                emit onAirDrop(offerInfo.playerAddress, _airdrop, offerInfo.offerAmount);
            }
        }
        airDropPool_ = airDropPool_.add(_air);
        _leftAmount = _leftAmount.sub(_air);

        if (updateAff) {
            players_[offerInfo.playerAddress].lastAffiliate = offerInfo.affiliateAddress;
        }

        restOfferAmount_ = restOfferAmount_.add(_leftAmount);
        if (currentOrder_.acceptAmount > currentOrder_.acceptedAmount) {
            matching();
        }

        playerOfferOrders_[offerInfo.playerAddress][players_[offerInfo.playerAddress].offeredCount] = offerInfo;
        players_[offerInfo.playerAddress].offeredCount = (players_[offerInfo.playerAddress].offeredCount).add(1);

        if (players_[offerInfo.playerAddress].playerAddress == address(0)) {
            players_[offerInfo.playerAddress].playerAddress = offerInfo.playerAddress;
        }
    }

    function matching() private {
        while (restOfferAmount_ > 0 && currentOrder_.acceptAmount > currentOrder_.acceptedAmount) {
            uint256 needAcceptAmount = (currentOrder_.acceptAmount).sub(currentOrder_.acceptedAmount);
            if (needAcceptAmount <= restOfferAmount_) {  
                restOfferAmount_ = restOfferAmount_.sub(needAcceptAmount);
                players_[currentOrder_.playerAddress].balance = needAcceptAmount.add(players_[currentOrder_.playerAddress].balance);
                currentOrder_.acceptedAmount = (currentOrder_.acceptedAmount).add(needAcceptAmount);
                currentOrder_ = acceptOrders_[currentOrder_.nextOrder];
            } else {  
                currentOrder_.acceptedAmount = (currentOrder_.acceptedAmount).add(restOfferAmount_);
                players_[currentOrder_.playerAddress].balance = (players_[currentOrder_.playerAddress].balance).add(restOfferAmount_);
                restOfferAmount_ = 0;
            }
        }
    }

    function calcAndSetPlayerTotalCanAccept(address pAddr, uint256 acceptAmount) private {
        uint256 _now = block.timestamp;
        uint256 _latestCalced = players_[pAddr].lastCalcOfferNo;
        uint256 _acceptedAmount = acceptAmount;

        while(_latestCalced < players_[pAddr].offeredCount) {
            FMAPDatasets.OfferInfo storage oi = playerOfferOrders_[pAddr][_latestCalced];
            uint256 _ts = _now.sub(oi.timestamp);
            if (oi.interesting == true) {
                if (_ts >= maxInterestTime_) {                    
                     
                    uint256 interest1 = oi.offerAmount.sub(oi.acceptAmount).mul(1).div(1000).mul(maxInterestTime_ / interestPeriod_);  
                    players_[pAddr].canAccept = (players_[pAddr].canAccept).add(oi.offerAmount).add(interest1);
                    oi.interesting = false;

                     
                    if (oi.offerAmount.sub(oi.acceptAmount) > _acceptedAmount) {
                        _acceptedAmount = 0;
                        oi.acceptAmount = oi.acceptAmount.add(_acceptedAmount);
                    } else {
                        _acceptedAmount = _acceptedAmount.sub(oi.offerAmount.sub(oi.acceptAmount));
                        oi.acceptAmount = oi.offerAmount;
                    }
                } else if (_acceptedAmount > 0) {
                    if (_acceptedAmount < oi.offerAmount.sub(oi.acceptAmount)) {
                        oi.acceptAmount = oi.acceptAmount.add(_acceptedAmount);
                        _acceptedAmount = 0;
                    } else {
                        uint256 interest0 = oi.offerAmount.sub(oi.acceptAmount).mul(1).div(1000).mul(_ts / interestPeriod_);
                        players_[pAddr].canAccept = (players_[pAddr].canAccept).add(oi.offerAmount).add(interest0);
                        oi.interesting = false;
                        
                        _acceptedAmount = _acceptedAmount.sub(oi.offerAmount.sub(oi.acceptAmount));
                        oi.acceptAmount = oi.offerAmount;
            
                    }
                }
            } else if (oi.offerAmount > oi.acceptAmount && _acceptedAmount > 0) {
                 
                if (oi.offerAmount.sub(oi.acceptAmount) > _acceptedAmount) {
                    _acceptedAmount = 0;
                    oi.acceptAmount = oi.acceptAmount.add(_acceptedAmount);
                } else {
                    _acceptedAmount = _acceptedAmount.sub(oi.offerAmount.sub(oi.acceptAmount));
                    oi.acceptAmount = oi.offerAmount;
                }
            }
            if (_acceptedAmount == 0) {
                break;
            }
            _latestCalced = _latestCalced + 1;
        }
        players_[pAddr].lastCalcOfferNo = _latestCalced;
    }

    function airdrop() private view returns (bool) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.timestamp, block.difficulty, block.gaslimit, airDropTracker_, block.coinbase, msg.sender)));
        if(seed - (seed / 10000).mul(10000) < airDropTracker_) {
            return (true);
        }
        return (false);
    }

    function calcCanAcceptAmount(address pAddr, bool isLimit, uint256 offsetTime) private view returns (uint256, uint256 nextUpdateTime) {
        uint256 _totalCanAccepted = players_[pAddr].canAccept;
        uint256 i = players_[pAddr].offeredCount;
        uint256 _now = block.timestamp.add(offsetTime);
        uint256 _nextUpdateTime = _now.add(interestPeriod_);
        for(;i > 0; i--) {
            FMAPDatasets.OfferInfo memory oi = playerOfferOrders_[pAddr][i - 1];
            if (oi.interesting == true) {
                uint256 timepassed = _now.sub(oi.timestamp);
                if (!isLimit || (timepassed >= interestPeriod_)) {  
                    uint256 interest;
                    if (timepassed < maxInterestTime_) {
                        interest = oi.offerAmount.sub(oi.acceptAmount).mul(1).div(1000).mul(timepassed / interestPeriod_);
                        
                        uint256 oiNextUpdateTime = (timepassed / interestPeriod_).add(1).mul(interestPeriod_).add(oi.timestamp);
                        if (_nextUpdateTime > oiNextUpdateTime) {
                            _nextUpdateTime = oiNextUpdateTime;
                        }
                    } else {
                        interest = oi.offerAmount.sub(oi.acceptAmount).mul(1).div(1000).mul(maxInterestTime_ / interestPeriod_);
                    }
                    _totalCanAccepted = _totalCanAccepted.add(oi.offerAmount).add(interest);
                }
            } else if (oi.timestamp == 0) {
                continue;
            } else {
                break;
            }
        }

        return (_totalCanAccepted.sub(players_[pAddr].totalAccepted), _nextUpdateTime);
    }

}

 
 
 
 
library FMAPMath {
    using SafeMath for uint256;
    function calcTrackerCount(uint256 ethAmount) internal pure returns (uint256) {
        if (ethAmount >= 1 finney && ethAmount < 10 finney) {
            return (1);
        } else if (ethAmount < 50 finney) {
            return (2);
        } else if (ethAmount < 200 finney) {
            return (3);
        } else if (ethAmount < 500 finney) {
            return (4);
        } else if (ethAmount < 1 ether) {
            return (5);
        } else if (ethAmount >= 1 ether) {
            return ethAmount.div(1 ether).add(5);
        }
        return (0);
    }
    function calcAirDropAmount(uint256 ethAmount) internal pure returns (uint256) {
        if (ethAmount >= 1 finney && ethAmount < 10 finney) {
            return (5);
        } else if (ethAmount < 50 finney) {
            return (10);
        } else if (ethAmount < 200 finney) {
            return (15);
        } else if (ethAmount < 500 finney) {
            return (20);
        } else if (ethAmount < 1 ether) {
            return (25);
        } else if (ethAmount >= 1 ether) {
            uint256 a = ethAmount.div(1 ether).add(5).mul(5);
            return (a > 75 ? 75 : a);
        }
        return (0);
    }
}
 
 
 
 
library FMAPDatasets {
    struct OfferInfo {
        address playerAddress;
        uint256 offerAmount;
        uint256 acceptAmount;  
        address affiliateAddress;
        address siteOwner;
        uint256 timestamp;
        bool interesting;
    }
    struct AcceptOrder {
        uint256 orderId;
        address playerAddress;
        uint256 acceptAmount;
        uint256 acceptedAmount;
        uint256 nextOrder;
    }
    struct Player {
        address playerAddress;
        address lastAffiliate;
        uint256 totalOffered;
        uint256 totalAccepted;
        uint256 airDroped;
        uint256 balance;  
        uint256 offeredCount;
        uint256 acceptOrderCount;
        uint256 canAccept;
        uint256 lastCalcOfferNo;
        uint256 affiliateEarned;
        uint256 siteEarned;
    }
}

 
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


 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}