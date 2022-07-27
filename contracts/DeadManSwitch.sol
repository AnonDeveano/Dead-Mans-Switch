// SPDX-License-Identifier: NLPL

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DeadManSwitch {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ======== INITIALIZATION ======== */
    // Automatically sets address of deployer to be owner
    constructor() {
        owner = msg.sender;
    }

    // Restricts vulnerability in other functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Address is not owner");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, address indexed to, uint256 amount);
    event DepositTokens(
        address indexed user,
        address to,
        address tokenAddress,
        uint256 amount
    );

    event Withdrawn(address indexed user, address indexed to, uint256 amount);
    event TokensWithdrawn(
        address indexed user,
        address to,
        address _tokenAddress,
        uint256 amount
    );

    event timePeriodSet(uint256 time);

    /* ========== STATE VARIABLES ========== */
    address owner;

    // pingActive is required for this contract and timePeriod is up to the user
    bool pingActive;
    uint256 timePeriod = block.timestamp + 12 weeks;

    // Where funds will be sent to if/when ping expires
    address payable distAddress;

    // Ether balance;
    uint256 vaultBalance;

    mapping(address => uint256) public tokenWallet;
    address[] public tokenArray;

    /* ========== ADMIN ========== */

    // Change distribution address
    function setNewAddress(address payable newAddress) public onlyOwner {
        require(newAddress != address(0), "Cannot be zero address");
        distAddress = newAddress;
    }

    // Set new admin of contract
    // Only attack vector I can recognize by including this is if private keys are compromised
    function setNewOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Cannot be zero address");
        owner = newOwner;
    }

    // Set time duration for ping()
    // This is measured in seconds; 1 min = 60, 1 hour = 3600, etc.
    function setTimePeriod(uint256 time) public onlyOwner {
        timePeriod = block.timestamp + time;
        emit timePeriodSet(timePeriod);
    }

    /* ========== FUNCTIONS ========== */

    // Deposit
    function depositEthers() public payable {
        vaultBalance = vaultBalance.add(msg.value);
        emit Deposit(msg.sender, address(this), msg.value);
    }

    // Deposit tokens
    // onlyOwner flag as some ERC20 tokens may have malicious code
    function depositTokens(address _token, uint256 value)
        public
        payable
        onlyOwner
    {
        IERC20 token = IERC20(_token);
        token.safeTransferFrom(msg.sender, address(this), value);
        address currentAddress = _token;
        uint256 walletValue = tokenWallet[_token];

        if (walletValue > 0) {
            tokenWallet[currentAddress] += value;
        } else {
            tokenWallet[currentAddress] = value;
            tokenArray.push(currentAddress);
        }

        emit DepositTokens(msg.sender, address(this), _token, msg.value);
    }

    // Withdraw
    function withdrawEthers(uint256 amount) public onlyOwner {
        require(vaultBalance >= amount);
        vaultBalance = vaultBalance.sub(amount);
        distAddress.transfer(address(this).balance);
        emit Withdrawn(owner, distAddress, address(this).balance);
    }

    // Withdraws token to specified hardcoded address
    function withdrawTokens(address tokenContract) external onlyOwner {
        IERC20 token = IERC20(tokenContract);
        uint256 value = token.balanceOf(address(this));
        token.safeTransfer(distAddress, value);
        tokenWallet[tokenContract] = 0;
        emit TokensWithdrawn(owner, distAddress, tokenContract, value);
    }

    // Ping, if done before timePeriod expires, renews bool/timePeriod
    // Else, sends ether to the distAddress
    // Needs token interaction here as well
    function Ping() public payable onlyOwner {
        uint256 ethBalance = address(this).balance;
        address currentAddress;

        for (uint256 i = 0; i < tokenArray.length; i++) {
            currentAddress = tokenArray[i];
            IERC20 token = IERC20(currentAddress);
            uint256 value = tokenWallet[currentAddress];

            if (block.timestamp < timePeriod) {
                pingActive = true;
                timePeriod = block.timestamp + 12 weeks;
            } else {
                token.safeTransfer(distAddress, value);
                tokenWallet[currentAddress] = 0;
            }
        }

        distAddress.transfer(ethBalance);
    }

    /* ========== GETTERS ========== */

    // Get Ethers balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Get Token Balance
    function getTokenBalance(address _token) public view returns (uint256) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    // Get token addresses in tokenArray
    function getTokenAddresses() external view returns (address[] memory) {
        return tokenArray;
    }

    receive() external payable {}
}
