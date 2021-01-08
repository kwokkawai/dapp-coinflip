import "./Ownable.sol";
pragma solidity 0.5.12;
import "github.com/provable-things/ethereum-api/provableAPI.sol";

contract Coinflip is Ownable, usingProvable{

    string message = "HelloWorld";
    uint public balance;
    address private owner;
    bool public result = false;
    mapping(address => uint) public playerBalance;
    mapping(address => Player) private playerRecord;
    
    struct Player {                                       
        uint balance;     
        uint countWin;                                
        uint countLoss;                                    
    }

    // Oracle
    
    struct Bet {
        address walletAddress;
        bool predictCoinSide;
        uint value;
    }
    
    uint256 constant MAX_INT_FROM_BYTE = 256;
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
    uint256 public latestNumber;
    
    mapping(bytes32 => Bet) public bets;
    
    // events
    //event SetBalance(address indexed user, uint256 balance);
    //event GetBalance(address indexed user, uint256 balance);
    event DepositToContract(address indexed user, uint256 amount, uint256 balance);
    event WithdrawAllFromContract(address indexed user, uint256 amount, uint256 balance);
    event DepositToPlayer(address indexed user, uint256 amount, uint256 balance);
    event WithdrawFromPlayer(address indexed user, uint256 amount, uint256 balance);
    event logNewProvableQuery(string description);
    event generateRandomNumber(address player, bool result);
    
    constructor() payable public {
        owner = msg.sender;
        balance = 0;
    }

    modifier costs(uint cost){
        require(msg.value >= cost);
        _;
    }

    function testRandom() public returns(bytes32) {
        bytes32 queryId = bytes32(keccak256("test"));
        __callback(queryId,"1",bytes("test"));
        return queryId;
    }
    
    function playFlipCoin2(bool coinSide) public payable {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;
        bytes32 queryId = testRandom();
        /*
        bytes32 queryId = provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );*/
        emit logNewProvableQuery("provable query was sent, standing by the answer...");
        Bet memory newBet = Bet(msg.sender, coinSide, msg.value);
        bets[queryId] = newBet;        
    }
    
    function __callback(bytes32 _queryId,string memory _result,bytes memory _proof) public {
        
        require(msg.sender == provable_cbAddress());
        bool flip;
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
        if (randomNumber == 0) {
            flip = true;
        } else {
            flip = false;
        }
        emit generateRandomNumber(bets[_queryId].walletAddress, flip);

        if (bets[_queryId].predictCoinSide == flip) {
            transferToPlayer(msg.sender,value);
            //balance -= value;
            //playerBalance[msg.sender] += value;             
            
            playerRecord[msg.sender].balance = playerBalance[msg.sender];
            playerRecord[msg.sender].countWin += 1;
        } else {
            
            transferToContract(msg.sender,value);
            //balance += value;
            //playerBalance[player] -= value;
            
            playerRecord[msg.sender].balance = playerBalance[msg.sender];
            playerRecord[msg.sender].countLoss += 1;            
        }

        //delete bet from mapping
        delete(bets[_queryId]);        
    }
    
    function flip() private view returns(bool) {
        if(now % 2 == 0){
            return false;
        }
        else if(now % 2 == 1){
            return true;
        }       
    }   
        
    function playFlipCoin(bool coinSide, uint value) public {
        
        result = flip();

        if (result == coinSide) {
            transferToPlayer(msg.sender,value);
            playerRecord[msg.sender].balance = playerBalance[msg.sender];
            playerRecord[msg.sender].countWin += 1;
        } else {
            transferToContract(msg.sender,value);
            playerRecord[msg.sender].balance = playerBalance[msg.sender];
            playerRecord[msg.sender].countLoss += 1;            
        }
    }

    function printPlayer() public view returns (uint, uint, uint) {
        return (playerRecord[msg.sender].balance, playerRecord[msg.sender].countWin, playerRecord[msg.sender].countLoss);
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }

    function setResult(bool newResult) public {
        result = newResult;
    }
    
    function setBalance(uint newBalance) public {
        balance = newBalance;
        //emit SetBalance(msg.sender, balance);
    }

    function getBalance() public view returns(uint) {
        return balance;
        //emit GetBalance(msg.sender, balance);
    }

    // owner deposite fund to contract
    function depositToContract() public payable costs(0.005 ether) onlyOwner {
        balance += msg.value;
        emit DepositToContract(msg.sender, msg.value, balance);
    }

    // owner withdraw fund from contract
    function withdrawAllFromContract() public onlyOwner {
        require(balance > 0);
        uint toTransfer = balance;
        balance = 0;
        msg.sender.transfer(toTransfer);
        emit WithdrawAllFromContract(msg.sender, toTransfer, balance);
    }

    // transfer fund from contract balance to player
    function transferToPlayer(address payable player, uint value) private {
        balance -= value;
        playerBalance[player] += value; 
    }

    // tranfer fund from player to contract balance
    function transferToContract(address payable player, uint value) private {
        balance += value;
        playerBalance[player] -= value;
    }

    // deposite fund to contract for player
    function depositToPlayer() public payable costs(0.005 ether) {
        playerBalance[msg.sender] += msg.value;
        emit DepositToPlayer(msg.sender, msg.value, playerBalance[msg.sender]); 
    }

    // withdraw fund from contract for player
    function withdrawFromPlayer(uint value) public {
        require(playerBalance[msg.sender] >= value);
        uint playerbalance;
        uint toTransfer = value;
        playerBalance[msg.sender] -= toTransfer;
        playerbalance = playerBalance[msg.sender];
        msg.sender.transfer(toTransfer);
        emit WithdrawFromPlayer(msg.sender, toTransfer, playerbalance);
    }

}