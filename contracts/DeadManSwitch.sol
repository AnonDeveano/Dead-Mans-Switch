// SPDX-License-Identifier: NLPL

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DeadManSwitch {
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

    // For mapping, iterated upon token deposit
    uint256 tokenNum = 0;

    // pingActive is required for this contract and timePeriod is up to the user
    bool pingActive;
    uint256 timePeriod = block.timestamp + 12 weeks;

    // Where funds will be sent to if/when ping expires
    address payable distAddress;

    // Ether balance;
    uint256 vaultBalance;

    // struct of deposited tokens
    struct dTokens {
        uint256 tokenId;
        address tokenAddress;
        uint256 amount;
    }

    mapping(uint256 => dTokens) public tokenWallet;
    uint256[] public tokenArray;

    /* ========== ADMIN ========== */

    // Automatically sets address of deployer to be owner
    constructor() {
        owner = msg.sender;
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
    function depositEthers() public payable {
        vaultBalance = vaultBalance.add(msg.value);
        emit Deposit(msg.sender, address(this), msg.value);
    }

    // Deposit tokens
    // Omitted safeApprove because decreased
    // onlyOwner flag as some ERC20 tokens may have malicious code
    function depositTokens(address _token, uint256 value)
        public
        payable
        onlyOwner
    {
        IERC20 token = IERC20(_token);
        token.approve(address(this), value);
        token.safeTransferFrom(msg.sender, address(this), value);

        for (uint256 i = 0; i < tokenArray.length; i++) {
            dTokens memory tokenEntry = tokenWallet[i];

            if (tokenEntry.tokenAddress == _token) {
                tokenEntry.amount += value;
            } else {
                tokenWallet[tokenNum] = dTokens(tokenNum, _token, value);
                tokenArray.push(tokenNum);
                tokenNum++;
            }
        }

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

        for (uint256 i = 0; i < tokenArray.length; i++) {
            dTokens memory tokenEntry = tokenWallet[i];
            address iterAddress = tokenEntry.tokenAddress;
            IERC20 token = IERC20(iterAddress);
            uint256 value = tokenWallet[i].amount;

            if (block.timestamp < timePeriod) {
                pingActive = true;
                timePeriod = block.timestamp + 12 weeks;
            } else {
                token.safeTransfer(distAddress, value);
                distAddress.transfer(ethBalance);
            }
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

    // Get token addresses in tokenArray
    function getTokenAddresses() external view returns (address[] memory) {
        ///
    }

    receive() external payable {}
}
