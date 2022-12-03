pragma solidity ^0.8.0;

contract DeDup {
    struct data {
        uint256 numOwners; // Num of owners submitting the same file
        uint256 currentPrice; // Current Price to store the file
        uint256 sizeInKB;   // Size of the file in KB
        uint256 actualPrice; // Start price to store the file
        address[] owners;   // list of owners of the file
        mapping(address => uint256) isPaid; // A mapping to track how much a user had paid
        uint256 moneyToDistribute; // A leftover money to distribute
        mapping(address => uint256) isOwner; // index of the owner in list of owners
        mapping(bytes32 => bool) isConfirmedByAdmin; // Flag to indicate whether Admin approved the deal
        mapping(bytes32=>bool) isConfirmedByOwner; // Flag to indicate whether owner approved the deal
        mapping(address=>uint) userPayTime; // Store the block.number of the user payment
    }
    mapping(string => bool) public CIDExsists;  // A mapping to know duplicate CID
    mapping(string => data) Data;               // A mapping of the struct data
    mapping(address => uint256) public refundPending; // A mapping to know a owners refunded amount
    address payable public Admin;                  // Admin address
    uint256 public pricePerKBInWei;             // Price per KB in wei
    uint256 public AdminPay;             // Pay to be received by Admin
    
    event AcknowledgeReceivePay(string ack);
    event AdminConfirmation(string CID, address owner);
    event OwnerConfirmation(string CID, address owner);
    /** constructor 
     * input: uint256 - represent price per KB In wei
     * returns nil */
    constructor(uint256 _pricePerKBInWei) {
        Admin = payable(msg.sender);
        pricePerKBInWei = _pricePerKBInWei;
    }
    /** modifier
     * checks whether the msg.sender is Admin
     */
    modifier onlyAdmin() {
        require(msg.sender == Admin);
        _;
    }
    /** setPricePerKBInWei
     * sets the new price per KB in Wei
     * inputs: uint256
     * output: nil
     */
    function setPricePerKBInWei(uint256 _pricePerKB) external onlyAdmin {
        pricePerKBInWei = _pricePerKB;
    }

    /** getPricePerKBInWei
     * returns the current price per KB in Wei
     * inputs: nil
     * output: uint256
     */
    function getPricePerKBInWei() external view returns (uint256 _pricePerKB) {
        return pricePerKBInWei;
    }
    /** receivePay
     * user should call for paying the cost of storing the file 
     * inputs: CID, msg.value
     * output: nil
     * events: AcknowledgeReceivePay(string)
     */
    function receivePay(string memory CID) external payable {
        require(msg.value >= Data[CID].currentPrice);
        Data[CID].moneyToDistribute += msg.value;
        Data[CID].isPaid[msg.sender] = msg.value;
        Data[CID].userPayTime[msg.sender] = block.timestamp;
        emit AcknowledgeReceivePay("Payment Received");
    }
    /** addOwner
     * This function is called by Admin to confirm user details
     * This function is called by owner for confirming the deal
     * inputs: bytes32, uint256, address
     * ouputs: nil
     * events: AdminConfirmation, OwnerConfirmation
     */
    function addOwner(
        string memory CID,
        uint256 sizeInKB,
        address owner
    ) public {
        if (msg.sender == Admin) {
            Data[CID].isConfirmedByAdmin[keccak256(abi.encodePacked(CID,sizeInKB,owner))] = true;
            emit AdminConfirmation(CID, owner);
        } else {
            require(Data[CID].isConfirmedByAdmin[keccak256(abi.encodePacked(CID,sizeInKB,msg.sender))], "User not confirmed");
            if (!isCIDExsists(CID)) {
                Data[CID].sizeInKB = sizeInKB;
                Data[CID].isOwner[msg.sender] = Data[CID].numOwners;
                Data[CID].actualPrice = getCurrentPrice(CID, sizeInKB);
                Data[CID].currentPrice = Data[CID].actualPrice / 2;
                AdminPay += Data[CID].moneyToDistribute;
                Data[CID].moneyToDistribute = 0;
                CIDExsists[CID] = true;
                Data[CID].isConfirmedByOwner[keccak256(abi.encodePacked(msg.sender))] = true;
            } else {
                updatePrice(CID);
            }
            Data[CID].numOwners++;
            Data[CID].owners.push(msg.sender);
            emit OwnerConfirmation(CID, owner);
        }
    }
    /** getCurrentPrice
     * Return the current price of the CID.
     * inputs: bytes32, uint256
     * output: uint256
     */
    function getCurrentPrice(string memory CID, uint256 sizeInKB)
        public
        view
        returns (uint256)
    {
        if (isCIDExsists(CID)) {
            return Data[CID].currentPrice;
        } else {
            return sizeInKB * pricePerKBInWei;
        }
    }

    /** updatePrice
     * Internal function to update the refund balances of the owners
     * Also, change the price according to the deduplication price
     * input: bytes32
     * output: nil
     */

    function updatePrice(string memory CID) internal {
        uint256 remaining = Data[CID].moneyToDistribute / (Data[CID].numOwners);
        for (uint256 i = 0; i < Data[CID].numOwners; i++) {
            refundPending[Data[CID].owners[i]] += remaining;
        }
        Data[CID].moneyToDistribute = 0;
        Data[CID].currentPrice =
            Data[CID].actualPrice /
            (Data[CID].numOwners + 2);
    }

    /** withDrawUser
     * This function helps user to withdraw accumulated coins
     * input: nil
     * output: nil
     */
    function withDrawUser() external payable {
        address payable receiver = payable(msg.sender);
        uint amountToBeTransfered = refundPending[msg.sender];
        refundPending[msg.sender] = 0;
        receiver.transfer(amountToBeTransfered);        
    }
    /** withDrawAdmin
     * This function helps Admin to withdraw accumulated coins
     * input: nil
     * output: nil
     */
    function withDrawAdmin() external payable onlyAdmin {
        uint amountToBeTransfered = AdminPay;
        AdminPay =0;
        Admin.transfer(amountToBeTransfered);
    }
    /** refundOwner
     * This function user to withdraw funds if either of the Admin or owner not confirm the deal
     * input: bytes32
     * output: nil
     */
    function refundOwner(string memory CID) payable external{
        require(block.number > Data[CID].userPayTime[msg.sender] + 20);
        require(!Data[CID].isConfirmedByOwner[keccak256(abi.encodePacked(msg.sender))]);
        uint amountToBeTransferred = Data[CID].isPaid[msg.sender];
        Data[CID].isPaid[msg.sender] = 0;
        payable(msg.sender).transfer(amountToBeTransferred);
    }
    /** isCIDExsists
     * input: bytes32
     * output: bool
     */
    function isCIDExsists(string memory CID) public view returns (bool) {
        return CIDExsists[CID];
    }
}
