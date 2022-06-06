// SPDX-License-Identifier: NLPL

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TheHardStuff.sol";

contract DeadManSwitch is TheHardStuff {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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

    // When depositing tokens, the token address is stored here
    // so that it can be iterated upon the else of ping()
    mapping(address => uint256) private tokenWallet;
    address[] private tokenArray;

    /* ========== ADMIN ========== */

    // Automatically sets address of deployer to be owner
    constructor() {
        msg.sender == owner;
    }

    // Restricts vulnerability in other functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Address is not owner");
        _;
    }

    // Change distribution address
    function setNewAddress(address payable newAddress) private onlyOwner {
        require(newAddress != address(0), "Cannot be zero address");
        distAddress = newAddress;
    }

    // Set new admin of contract
    // Only attack vector I can recognize by including this is if private keys are compromised
    function setNewOwner(address newOwner) private onlyOwner {
        require(newOwner != address(0), "Cannot be zero address");
        owner = newOwner;
    }

    // Set time duration for ping()
    function setTimePeriod(uint256 time) private onlyOwner {
        timePeriod = time;
        emit timePeriodSet(timePeriod);
    }

    /* ========== FUNCTIONS ========== */

    // Deposit
    function depositEthers(uint256 amount) public payable {
        require(msg.value == amount);
        vaultBalance = vaultBalance.add(amount);
        emit Deposit(msg.sender, address(this), msg.value);
    }

    // Deposit tokens
    // Omitted safeApprove because decreased
    function depositTokens(address _token, uint256 value) public payable {
        IERC20 token = IERC20(_token);
        address tokenWalletIndex = tokenWallet[tokenAddy];
        token.approve(address(this), value);
        token.safeTransferFrom(msg.sender, address(this), value);

        // If token address is found in tokenWallet mapping; value just gets incremented
        if (tokenWalletIndex > 0) {
            tokenWallet[tokenWalletIndex].value += value;
        }

        // No corresponding address - add address to array and add index to mapping
        tokenArray.push(token.address);

        // tokenArray.length - 1 makes the array start at 0 index
        tokenWallet[tokenAddy] = tokenArray.length - 1;

        token.safeDecreaseAllowance(address(this), value);
        emit DepositTokens(msg.sender, address(this), _token, msg.value);
    }

    // Withdraw
    function withdrawEthers(uint256 amount) private onlyOwner {
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
        emit TokensWithdrawn(owner, distAddress, tokenContract, value);
    }

    // Ping, if done before timePeriod expires, renews bool/timePeriod
    // Else, sends ether to the distAddress
    // Needs token interaction here as well
    function Ping() private onlyOwner {
        uint256 ethBalance = address(this).balance;
        if (block.timestamp < timePeriod) {
            pingActive = true;
            timePeriod = block.timestamp + 12 weeks;
        } else {
            distAddress.transfer(ethBalance);
        }
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

    receive() external payable {}
}
