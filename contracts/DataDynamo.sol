// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    struct Campaign {
        address payable creator;
        uint256 goal;
        uint256 raised;
        uint256 deadline;
        string title;
        string description;
        bool goalReached;
        bool fundsWithdrawn;
        mapping(address => uint256) contributions;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignCounter;
    
    event CampaignCreated(uint256 indexed campaignId, address indexed creator, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed creator, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    
    // Function 1: Create a new crowdfunding campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) external {
        require(_goal > 0, "Goal must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        Campaign storage newCampaign = campaigns[campaignCounter];
        newCampaign.creator = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.deadline = deadline;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.raised = 0;
        newCampaign.goalReached = false;
        newCampaign.fundsWithdrawn = false;
        
        emit CampaignCreated(campaignCounter, msg.sender, _goal, deadline);
        campaignCounter++;
    }
    
    // Function 2: Contribute to a campaign
    function contribute(uint256 _campaignId) external payable {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(_campaignId < campaignCounter, "Campaign does not exist");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be greater than 0");
        require(!campaign.goalReached, "Campaign goal already reached");
        
        campaign.contributions[msg.sender] += msg.value;
        campaign.raised += msg.value;
        
        if (campaign.raised >= campaign.goal) {
            campaign.goalReached = true;
        }
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }
    
    // Function 3: Withdraw funds or get refund
    function withdrawOrRefund(uint256 _campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(_campaignId < campaignCounter, "Campaign does not exist");
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        
        if (campaign.goalReached && msg.sender == campaign.creator) {
            // Creator withdraws funds if goal is reached
            require(!campaign.fundsWithdrawn, "Funds already withdrawn");
            
            campaign.fundsWithdrawn = true;
            uint256 amount = campaign.raised;
            
            campaign.creator.transfer(amount);
            emit FundsWithdrawn(_campaignId, msg.sender, amount);
            
        } else if (!campaign.goalReached) {
            // Contributors get refund if goal not reached
            uint256 contributedAmount = campaign.contributions[msg.sender];
            require(contributedAmount > 0, "No contribution to refund");
            
            campaign.contributions[msg.sender] = 0;
            payable(msg.sender).transfer(contributedAmount);
            emit RefundIssued(_campaignId, msg.sender, contributedAmount);
        } else {
            revert("No action available");
        }
    }
    
    // View functions for frontend integration
    function getCampaignDetails(uint256 _campaignId) external view returns (
        address creator,
        uint256 goal,
        uint256 raised,
        uint256 deadline,
        string memory title,
        string memory description,
        bool goalReached,
        bool fundsWithdrawn
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.goal,
            campaign.raised,
            campaign.deadline,
            campaign.title,
            campaign.description,
            campaign.goalReached,
            campaign.fundsWithdrawn
        );
    }
    
    function getContribution(uint256 _campaignId, address _contributor) external view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}
