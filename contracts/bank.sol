// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./token.sol";

contract Bank {
    // Create an instance of the contract (JVCToken)
    JVCToken internal token;

    // Storage location for the users
    struct User {
        string uname;
        uint256 balance;
    }

    // Use address as a key to access the storage location for the users
    mapping(address => User) private users;

    // Constants for minimum deposit and maximum withdrawal amount
    uint256 private constant minDepAmt = 100 wei;
    uint256 private constant maxWithdAmt = 1 ether;

    // Custom datatype recognised as unsigned integer to store the state of deposit and withdrawal.
    enum Status {
        Pending,
        Failed,
        Successful
    }
    Status public status;

    // Events to log the status of the withdrawal and deposit activities
    event DepositSuccessful(address indexed user, uint256 amount);
    event DepositFailed(address indexed user, string message);
    event WithdrawalSuccessful(address indexed user, uint256 amount);
    event WithdrawalFailed(address indexed user, string message);

    // Function modifier to ensure an address in not a contract address
    modifier verifyAddr() {
        require(!isContractAddr(msg.sender), "This is a contract address!");
        _;
    }

    // Get the token address which will be used to interact with the deployed contract (JVCToken)
    constructor(address _tokenAddress) {
        token = JVCToken(_tokenAddress);
    }

    // Add users to the bank
    function registerUser(string memory uname) public {
        require(bytes(users[msg.sender].uname).length == 0, "User already registered!");
        uint256 userBalance = token.checkBalanceOf(msg.sender); // Default to 0 if none.
        users[msg.sender] = User(uname, userBalance);
    }

    // Serach for a specific user with the address
    function getUserByAddress(address userAddress) public view returns (User memory) {
        return users[userAddress];
    }

    // Place a deposit from the the address trigering the function to the bank(contract address)
    function deposit() public payable verifyAddr {
        require(msg.value > minDepAmt, "Minimum deposit amount not met");
        token.transfer(address(this), msg.value);
        status = Status.Successful;
        emit DepositSuccessful(msg.sender, msg.value);
    }

    // Place a withdrawal from the bank (contract address) to the address in request(msg.sender)
    function withdraw(uint256 amount) public payable verifyAddr {
        require(amount < users[msg.sender].balance, "Insufficient balance");
        require(amount < maxWithdAmt, "Withdrawal amount exceeds limit");
        users[address(this)].balance -= amount;
        users[msg.sender].balance += amount;
        // token.removeMoney(msg.sender, amount);
        emit WithdrawalSuccessful(msg.sender, amount);
        status = Status.Successful;
    }

    // Mint new tokens
    function mintToken(uint256 amount) public {
        token.mint(address(this), amount);
    }

    // Burn some of the tokens
    function burnToken(uint256 amount) public {
        token.burn(address(this), amount);
    }

    // Transfer onwership of the token
    function changeOwnership(address newOwner) public {
        token.transferOwnership(newOwner);
    }

    // Get the balance of the smart contract
    function getContractBalance() public view returns (uint256) {
        return (token.checkBalanceOf(address(this)));
    }

    // Get some meta data about the JVC token
    function getTokenInfo()
        public
        returns (
            uint256 totalSupply,
            string memory tokenName,
            string memory tokenSymbol,
            uint256 tokenDecimal
        )
    {
        return (token.tokenInfo());
    }

    // Get the acount balance of a user
    function getBalanceOf(address _addr) public view returns(uint balance){
        return token.checkBalanceOf(_addr);
    }

    // Helper function to check contract address
    function isContractAddr(address addr) internal view returns (bool) {
        return addr.code.length > 0;
    }
}
