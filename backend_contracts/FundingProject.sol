// SPDX-License-Identifier: GPL-3.0

import "./ERC20.sol";
import "./ERC721.sol";
pragma solidity >=0.8.2 <0.9.0;

contract FundingProject {

    struct Milestone {

        uint256 id;
        string description;
        uint256 targetFund; // Milestones According to funding
        bool completed;
        uint256 badgeTokenId;

    }

    struct ProjectMetadata {
        uint256 id; // Project Id
        string name; // Project Name
        string description; // Project Description
        uint256 proposalDate; // Deadline
        address creator;
    }

    struct ProjectStats {
        uint256 milestoneCount;
        uint256 goalAmount;  
        uint256 fundsRaised;
        uint256 like_number;  // Filter Purpose
        uint256 dislike_number; // Filter Purpose
        uint256 percentage; // Progress
        bool isActive;
    }

    struct Project {
        ProjectMetadata metadata;
        ProjectStats stats;
        address erc20TokenAddress; // ERC-20
        address badgeContractAddress; // ERC-721
    }


    uint256 public projectCount = 0;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(uint256 => Milestone)) public projectMilestones; // Keep track of milestones of Project
    mapping(address => mapping(uint256 => uint256)) public userDonations; // Keep track of user Donations ??? Optimize olabilir
    mapping(address => mapping(uint256 => bool)) public checkUserDonation; // Check Whether user donate project or not
    
    // userReaction : 2 -> represent pressed like
    // userReaction : 1 -> represent pressed dislike
    // userReaction : 0 -> no voted yet    
    mapping(address => mapping(uint256 => uint256)) public userReaction; // Keep track of user reaction


    modifier Active(uint256 project_id) {

        require(block.timestamp <= projects[project_id].metadata.proposalDate, "The project is not active anymore.");
        _;

    }

    // Create project
    function createProject(string memory _name, string memory _description, uint256 proposalTime,
                        string memory tokkenName, string memory tokkenSymbol, 
                        string memory nftTokkenName, string memory nftTokkenSymbol, uint256 _goalAmount) public returns(bool) {
        
        require(_goalAmount > 0, "The Goal Amount must be bigger than 0.");
        require(proposalTime >= 0, "The proposal time must be bigger than 0.");
        ERC20 projectToken = new ERC20(tokkenName, tokkenSymbol, _goalAmount);
        ERC721 projectNFTToken = new ERC721(nftTokkenName, nftTokkenSymbol);

        projects[projectCount] = Project({
            metadata: ProjectMetadata({
                id: projectCount,
                name: _name,
                description: _description,
                proposalDate: block.timestamp + proposalTime,
                creator: msg.sender
            }),
            stats: ProjectStats({
                milestoneCount: 0,
                goalAmount: _goalAmount,
                fundsRaised: 0,
                like_number: 0,
                dislike_number: 0,
                percentage: 0,
                isActive: true
            }),
            erc20TokenAddress: address(projectToken),
            badgeContractAddress: address(projectNFTToken)
        });
        
        projectCount++;
        return true;

    }

    // Create milestone
    function addMilestone(uint256 project_id, uint256 _targetFund, string memory _description) public Active(project_id) returns(bool) {

        Project storage project = projects[project_id];
        require(msg.sender == project.metadata.creator, "Only The owner of project can add milestone.");
        require(_targetFund > project.stats.fundsRaised, "The target fund has already been passed.");
        require(_targetFund <= project.stats.goalAmount, "The target fund exceeds goal amount.");

        uint256 milestoneId = project.stats.milestoneCount;
        projectMilestones[project_id][milestoneId] = Milestone({
            id: milestoneId,
            description: _description,
            targetFund: _targetFund * 1 wei,
            completed: false,
            badgeTokenId: ERC721(project.badgeContractAddress).currentTokenId()           
        });

        project.stats.milestoneCount++;
        ERC721(project.badgeContractAddress).incrementTokenID(); // İncrease Token ID
        return true;

    }

    // check milestone
    function completeMilestone(uint256 project_id) internal {
        Project storage project = projects[project_id];
        for (uint256 i = 0; i < project.stats.milestoneCount; i++) {
            Milestone storage milestone = projectMilestones[project_id][i];
            if (!milestone.completed && project.stats.fundsRaised >= milestone.targetFund) {
                ERC721(project.badgeContractAddress).mint(project.metadata.creator, milestone.badgeTokenId);
                milestone.completed = true;
            }
        }
    }


    // Donate
    function donateProject(uint256 project_id) public payable returns(bool) {

        Project storage project = projects[project_id];
        require(msg.sender != project.metadata.creator, "The Owner of the Project cannot donate.");
        require(block.timestamp < project.metadata.proposalDate, "The Project is over.");
        require(project.stats.fundsRaised != project.stats.goalAmount, "The Goal amount is reached.");
        require(msg.value >  0 * 1 wei, "Please provide positive value for donating amount");

        uint256 fund = msg.value * 1 wei;
        if ((fund + project.stats.fundsRaised) > project.stats.goalAmount) { // Give remaining money back
            payable(msg.sender).transfer(fund + project.stats.fundsRaised - project.stats.goalAmount);
            fund = project.stats.goalAmount - project.stats.fundsRaised;
        }

        project.stats.fundsRaised += fund;
        calculatePercentage(project_id); // Calculate percentage dynamically
        completeMilestone(project_id); // ? 
        userDonations[msg.sender][project.metadata.id] += fund;
        checkUserDonation[msg.sender][project.metadata.id] = true;
        ERC20(project.erc20TokenAddress).transfer(msg.sender, fund);

        return true;
    }


    // Calculation Percentage
    function calculatePercentage(uint256 project_id) internal returns(bool) {

        Project storage project = projects[project_id];
        // There is a check for goalAmount in the create object
        uint256 new_percentage = (project.stats.fundsRaised * 100) / project.stats.goalAmount;
        project.stats.percentage = new_percentage;

        return true;
        
    }

    // Update Reaction
    function updateReaction(uint256 project_id, uint256 reaction) public Active(project_id) returns(bool) {

        Project storage project = projects[project_id];
        require(msg.sender != project.metadata.creator, "The Owner of the Project cannot like.");
        require(checkUserDonation[msg.sender][project.metadata.id], "Only donators can like or dislike.");

        uint256 current_reaction = userReaction[msg.sender][project_id];
        if (current_reaction == 0) { // No reaction 
            if (reaction == 2) {
                project.stats.like_number++;
                userReaction[msg.sender][project_id] == 2;
            }
            else {
                project.stats.dislike_number++;
                userReaction[msg.sender][project_id] == 1;
            }
        }
        else {
            if (current_reaction == 1 && reaction != 1) {
                project.stats.like_number++;
                project.stats.dislike_number--;
                userReaction[msg.sender][project_id] == 2;
            }
            else if (current_reaction == 2 && reaction != 2) {
                project.stats.dislike_number++;
                project.stats.like_number--;
                userReaction[msg.sender][project_id] == 1;
            }
        }
        return true;
    }

    function refresh() public  {
        for (uint256 i = 0; i < projectCount; i++) {
            projects[i].stats.isActive = (block.timestamp < projects[i].metadata.proposalDate);
        }

    }

}