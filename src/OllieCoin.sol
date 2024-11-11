// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OllieCoin is ERC20, Ownable {

    ERC20 public rwc;

    uint256 public cumulativeRewardPerToken; // Tracks lifetime RWC reward per OLC
    mapping(address => uint256) public lastCumulativeRewardPerToken; // Tracks user's last cumulativeRewardPerToken accounted for
    mapping(address => uint256) public owed;

    event RewardDistributed(uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _rwc) ERC20("OllieCoin", "OLC") Ownable(msg.sender) {
        rwc = ERC20(_rwc);
    }

    function distribute(ERC20 token, uint256 amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), amount);

        uint256 perTokenReward = 1e18; // 1 RWC per OLC per epoch
        cumulativeRewardPerToken += perTokenReward; // Permanently increase reward per token
        
        emit RewardDistributed(amount);
    }

    function claim() external {
        _checkpointRewards(msg.sender);
        uint256 reward = owed[msg.sender];
        owed[msg.sender] = 0;
        rwc.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * Tracks the rewards of a user. We checkpoint the last time a reward calculation is made for a user
     * @param account user
     */
    function _checkpointRewards(address account) internal {
        uint256 userCumulative = lastCumulativeRewardPerToken[account];
        if (userCumulative < cumulativeRewardPerToken) {
            // Update owed amount. 
            owed[account] += (cumulativeRewardPerToken - userCumulative) * balanceOf(account) / 1e18;

            // Checkpoints the cumulativeRewardPerToken for the user. 
            lastCumulativeRewardPerToken[account] = cumulativeRewardPerToken; 
        }
    }

    /**
     * A 'hook' called on every transfer. Checkpoint _before_ the transfer to make sure the sender is allocated
     * their reward / receiver is not over-allocated
     * @param from sender
     * @param to receiver
     * @param value amount
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        _checkpointRewards(from);
        _checkpointRewards(to);
        super._update(from, to, value);
    }
}
