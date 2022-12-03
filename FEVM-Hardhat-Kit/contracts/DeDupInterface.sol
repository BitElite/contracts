pragma solidity ^0.8.0;

interface DeDupInterface {
        struct data {
        bytes32 CID;
        uint numOwners;
        uint currentPrice;
        uint sizeInKB;
        address[] owners;
        mapping(address=>uint) isPaid;
        uint moneyToDistribute;
        mapping(address=>uint) isOwner;
    }
    
    function addOwner(bytes32 CID, uint size, address owner) external;
    function isCIDExsists(bytes32 CID)  view external returns(bool);
    function getPrice(bytes32 CID) view external returns(uint);
}