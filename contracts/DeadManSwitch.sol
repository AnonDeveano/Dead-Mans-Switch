// SPDX-License-Identifier: NLPL

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Unseizable {
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

    event LengthSet(uint256 length);

    /* ========== STATE VARIABLES ========== */
    address owner;

    // pingActive is required for this contract and timePeriod is up to the user
    bool pingActive;
    uint256 timePeriod = block.timestamp + 12 weeks;

    // Where funds will be sent to if/when ping expires
    address payable distAddress;

    // Ether balance;
    uint256 vaultBalance;

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
        token.approve(address(this), value);
        token.safeTransferFrom(msg.sender, address(this), value);
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

    // Ping, 30 day grace period after deadline then funds are released
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
