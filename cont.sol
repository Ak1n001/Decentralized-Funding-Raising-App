// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProjectFunding  {
    
    struct Project {
        string name;
        string description;
        address creator;
        address tokenAddress;
        uint256 targetAmount;
        uint256 totalFunds;
        bool isActive;
    }

    Project[] public projects;
    mapping(address => uint256) public contributions;

    event ProjectCreated(
        uint256 indexed projectId,
        string name,
        address indexed creator,
        address tokenAddress,
        uint256 targetAmount
    );

    event ContributionReceived(
        uint256 indexed projectId,
        address indexed contributor,
        uint256 amount
    );

    function createProject(
        string memory _name,
        string memory _description,
        uint256 _targetAmount
    ) external {
        require(_targetAmount > 0, "Target amount must be greater than 0");

        // Deploy a new ERC-20 token for the project
        ProjectToken token = new ProjectToken(_name, "PTK");
        
        Project memory newProject = Project({
            name: _name,
            description: _description,
            creator: msg.sender,
            tokenAddress: address(token),
            targetAmount: _targetAmount,
            totalFunds: 0,
            isActive: true
        });

        projects.push(newProject);

        emit ProjectCreated(
            projects.length - 1,
            _name,
            msg.sender,
            address(token),
            _targetAmount
        );
    }

    function contribute(uint256 _projectId) external payable {
        require(_projectId < projects.length, "Invalid project ID");
        Project storage project = projects[_projectId];
        require(project.isActive, "Project is no longer active");
        require(msg.value > 0, "Contribution must be greater than 0");

        project.totalFunds += msg.value;
        contributions[msg.sender] += msg.value;

        // Mint tokens to the contributor based on the value of contribution
        ProjectToken(project.tokenAddress).mint(msg.sender, msg.value);

        emit ContributionReceived(_projectId, msg.sender, msg.value);

        // Deactivate project if funding goal is reached
        if (project.totalFunds >= project.targetAmount) {
            project.isActive = false;
        }
    }

    function withdrawFunds(uint256 _projectId) external {
        require(_projectId < projects.length, "Invalid project ID");
        Project storage project = projects[_projectId];
        require(msg.sender == project.creator, "Only project creator can withdraw funds");
        require(!project.isActive, "Project funding goal not reached yet");

        uint256 amount = project.totalFunds;
        project.totalFunds = 0;

        payable(msg.sender).transfer(amount);
    }

    function getProjects() external view returns (Project[] memory) {
        return projects;
    }
}

// Custom ERC-20 Token for each project
contract ProjectToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external  {
        _mint(to, amount);
    }
}
