//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract KYC{

    struct Customer{
        bytes32 userName;
        bytes32 customerData;
        address bank;
        bool kycStatus;
        uint256 downVotes;
        uint256 upVotes; 
    }

    struct Bank{
        bytes32 bankName;
        address ethAddress;
        bytes32 regNumber; 
        uint256 complaintsReported;
        uint256 kycCount;
        bool isAllowedToVote;
    }

    struct KYCRequest{
        bytes32 userName;
        address bankAddress;
        bytes32 customerData;
    }

    mapping(bytes32 => Customer) customerList;
    mapping(address => Bank) bankList;
    mapping(bytes32 => bool) bankListByRegNumber;
    uint256 private noOfBanks;
    mapping(bytes32 => KYCRequest) kycRequestList;
    address private admin;

    //Deployer of smart contractor is made as admin
    constructor() {
        admin = msg.sender;
    }

    //Add request method creates a new KYC Request
    //Customer with default values should be availailble before the creation of new KYC Request
    function addRequest(bytes32 _custName, bytes32 _custData) isBank() isCustNameAvailable(_custName) isRequestAlreadyMade(_custName) public {
        require(bankList[msg.sender].isAllowedToVote == true, "You cannot do KYC Request. Please contact Admin Team");
        require(customerList[_custName].kycStatus == false, "KYC is already done for this customer");
        kycRequestList[_custName] = KYCRequest({
            userName : _custName,
            bankAddress : msg.sender,
            customerData : _custData
        });
        bankList[msg.sender].kycCount =  bankList[msg.sender].kycCount + 1;
    }

    //Verify KYC method verifies the KYC process and marks the status of Customer as KYC Verified
    function verifyKYC(bytes32 _custName) isBank() isCustomerAvailableInRequest(_custName) public {
        require(msg.sender == kycRequestList[_custName].bankAddress, "Only KYC requested bank can verify customer");
        require(customerList[_custName].kycStatus == false, "Customer is already KYC Verified");
        customerList[_custName].bank =  msg.sender;
        customerList[_custName].kycStatus = true;
    }

    //function to create a new customer with default values.
    function addCustomer(bytes32 _custName, bytes32 _custData) isBank() isCustNameAlreadyExist(_custName) public{
        customerList[_custName] =  Customer({
            userName:_custName,
            customerData : _custData,
            bank : address(0),
            kycStatus : false,
            upVotes : 0,
            downVotes : 0
        });
    }

    //To remove any KYC request
    //KYC Request can be deleted by only its creator or by Admin
    function removeRequest(bytes32 _custName) isAdminOrBank() isCustomerAvailableInRequest(_custName) public {
        require(kycRequestList[_custName].bankAddress == msg.sender || msg.sender == admin, "Only the creator of the KYC request can delete it or by admin team");
        delete kycRequestList[_custName];
    }

    //To view KYC Request details
    function getRequestDetails(bytes32 _custName) isAdminOrBank() isCustomerAvailableInRequest(_custName) public view returns(bytes32, address, bytes32){
        return (kycRequestList[_custName].userName, kycRequestList[_custName].bankAddress, kycRequestList[_custName].customerData);
    }

    //To view Customer details
    function viewCustomer(bytes32 _customerName) isAdminOrBank() isCustNameAvailable(_customerName) public view returns(bytes32, bytes32, address, bool, uint256, uint256){
        return (customerList[_customerName].userName, customerList[_customerName].customerData, customerList[_customerName].bank, 
        customerList[_customerName].kycStatus, customerList[_customerName].downVotes, customerList[_customerName].upVotes);
    }

    //This method will increment the count of the upvote for the specified customer
    function upVoteKYCDetails(bytes32 _custName) isBank() isCustNameAvailable(_custName) validateVoting(_custName) public {
        customerList[_custName].upVotes =  customerList[_custName].upVotes+1;
        checkAndUpdateKYCStatus(_custName);
    }

    //Whenver an upvote or downvote is marked by any bank
    //Check Whether Upvote is greater than downvote if it is not then directly set the kycStatus of the customer as invalid.
    //if Upvote is greater than downvote then check the number of downvote is greater than one-third of the no. of banks 
    //if downvote is lesser. then again set the KYCStatus as invalid.
    function checkAndUpdateKYCStatus(bytes32 _custName) private {
        if(customerList[_custName].upVotes > customerList[_custName].downVotes) {
            if(noOfBanks/3 <= customerList[_custName].downVotes) {
                customerList[_custName].kycStatus = false;
            }
            else {
                customerList[_custName].kycStatus = true;
            }
        }
        else {
            customerList[_custName].kycStatus = false;
        }
    }

    //This method will increment the count of the downvote for the specified customer
    function downVoteKYCDetails(bytes32 _custName) isBank() isCustNameAvailable(_custName) validateVoting(_custName) public {
        customerList[_custName].downVotes =  customerList[_custName].downVotes+1;
        checkAndUpdateKYCStatus(_custName);
    }

    //This method will modify the customer data
    //As the customer date is modified, its KYC status, upvote and downvote would be resetted
    //Customer needs to go under KYC verification again
    function modifyCustomer(bytes32 _custName, bytes32 _modifiedCustData) isBank() isCustNameAvailable(_custName) public {
        customerList[_custName].customerData = _modifiedCustData;
        if(kycRequestList[_custName].bankAddress != address(0))
        {
            delete kycRequestList[_custName];
        }
        customerList[_custName].upVotes = 0;
        customerList[_custName].downVotes = 0;
        customerList[_custName].kycStatus = false;
        customerList[_custName].bank = address(0);
    }

    //To get number of complaints registered against specified bank
    function getBankComplaints(address bankAddress) isAdminOrBank() isBankAvailable(bankAddress) public view returns(uint256) {
        return bankList[bankAddress].complaintsReported;
    }

    //To get required Bank details 
    function getBankDetails(address bankAddress) isAdminOrBank() isBankAvailable(bankAddress) public view returns(Bank memory) {
        return bankList[bankAddress];
    }

    //To report a bank of suspicious activity
    function reportBank(address bankAddress) isBank() isBankAvailable(bankAddress) public {
        bankList[bankAddress].complaintsReported = bankList[bankAddress].complaintsReported + 1;
        checkAndDisableVotingRights(bankAddress);
    }

    //Whenever a bank gets reported for suspicious activity, no. of complaints registered against the bank is checked 
    //If it is greater than one third of the no. of banks then that bank is stopped from Voting/Carring any more KYC Process
    function checkAndDisableVotingRights(address bankAddress) private {
        if(noOfBanks/3 <= bankList[bankAddress].complaintsReported) {
            bankList[bankAddress].isAllowedToVote = false;
        }
        else
        {
            bankList[bankAddress].isAllowedToVote = true;
        }
    }

    //Function to add new bank
    //It can be done only by admin 
    function addBank(bytes32 _bankName, address _bankAddress, bytes32 _regNumber) isAdmin() isBankAlreadyExist(_bankAddress, _regNumber) public{
        Bank memory bank = Bank({
            bankName : _bankName,
            ethAddress : _bankAddress,
            regNumber : _regNumber,
            complaintsReported : 0,
            kycCount : 0,
            isAllowedToVote : true
        });

        bankList[_bankAddress] = bank;
        bankListByRegNumber[_regNumber] = true;
        noOfBanks = noOfBanks +1;
    }

    //Admin can enable/disable voting rights for a bank
    //Whenever it is done other details like no. of complaints reported and kyccount done by that bank would be reset
    function modifyIsAllowedToVote(address _bankAddress, bool _isAllowedToVote)  isAdmin() isBankAvailable(_bankAddress) public {
        bankList[_bankAddress].isAllowedToVote = _isAllowedToVote;
        bankList[_bankAddress].complaintsReported = 0;
        bankList[_bankAddress].kycCount = 0;
    }

    //Method to remove a bank
    //It can be done only by admin
    function removeBank(address _bankAddress)  isAdmin() isBankAvailable(_bankAddress) public {
        delete bankListByRegNumber[bankList[_bankAddress].regNumber];
        delete bankList[_bankAddress];
        noOfBanks = noOfBanks - 1;
    }

    //Modifier to check if the msg.sender is admin
    modifier isAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    //Modifier to check if the msg.sender is admin or bank
    modifier isAdminOrBank() {
        require(msg.sender == admin || bankList[msg.sender].ethAddress == msg.sender, "Only admin or recognized banks can perform this operation");
        _;
    }

    //Modifier to check if the msg.sender is bank
    modifier isBank() {
        require(bankList[msg.sender].ethAddress == msg.sender, "Only recognized banks can perform this operation!!!");
        _;
    }

    //Modifier to check Bank already exists by comparing address and reg number
    modifier isBankAlreadyExist(address _bankAddress, bytes32 _regNumber) {
        require(bankList[_bankAddress].ethAddress == address(0), "Specified Bank address already exists");
        require(bankListByRegNumber[_regNumber] == false, "Specified Registration Number already exists");
        _;
    }

    //Modifier to check if the specified bank address is available in the network
    modifier isBankAvailable(address bankAddress) {
        require(bankList[bankAddress].ethAddress != address(0), "Specified Bank address is not available");
        _;
    }

    //Voting can be done only when Customer's Kyc is done
    //and the Voting bank is allowed to vote 
    //and KYC Verified bank and Voting bank are not the same
    modifier validateVoting(bytes32 _custName) {
        require(customerList[_custName].kycStatus == true, "KYC is not yet verified for this customer");
        require(bankList[msg.sender].isAllowedToVote == true, "You cannot perform voting operation!!");
        require(msg.sender != customerList[_custName].bank, "Upvote/Downvote cannot be done by KYC Verified Bank for the Customer");
        _;
    }

    //Is specified customer exists in Kyc request
    modifier isCustomerAvailableInRequest(bytes32 _customerName) {
        require(kycRequestList[_customerName].customerData != 0, "KYC Request is not available for the specified Customer");
        _;
    }

    //checked kyc request is already raised for the specified customer
    modifier isRequestAlreadyMade(bytes32 _customerName) {
        require(kycRequestList[_customerName].customerData == 0, "KYC Request already made for the customer");
        _;
    }

    //To check customer name already exists
    modifier isCustNameAlreadyExist(bytes32 _customerName) {
        require(customerList[_customerName].customerData == 0, "Specified Customer Name already exists");
        _;
    }

    //To check customer available
    modifier isCustNameAvailable(bytes32 _customerName) {
        require(customerList[_customerName].customerData != 0, "Specified Customer Name is not available");
        _;
    }
}