// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ILaunchpad {

    struct Stake {
        uint stakeTypeId;
        uint startedTime;
        uint amount;
        uint lockTime;
        uint allocation;
        uint apr;
        string stakeTypeName;
        bool isActive;
    }    
    
    mapping(address => uint) public stakes;

    function getStakeData(address user) external view returns (uint) {
        return stakes[user];
    }

}

contract Dao {
    ILaunchpad public starterContract;

    bool private locked = false;

    modifier noReentry() {
        require(!locked, "Reentry attack detected");
        locked = true;
        _;
        locked = false;
    }

   struct Proposal {
        address owner;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votingPeriodInDays;
        bool closed;
        uint256 option1Votes;
        uint256 option2Votes;
        uint256 option3Votes;
        address[] voters;
    }

    Proposal[] public proposals;
    address public owner;

    constructor(address _contract) {
        owner = msg.sender;
        starterContract = ILaunchpad(_contract);

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can create proposals");
        _;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _votingPeriodInDays
    ) external onlyOwner {
        require(_votingPeriodInDays > 0, "Voting period must be greater than zero");

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + (_votingPeriodInDays * 1 days);

        Proposal memory newProposal = Proposal({
            owner: msg.sender,
            title: _title,
            description: _description,
            startTime: startTime,
            endTime: endTime,
            votingPeriodInDays: _votingPeriodInDays,
            closed: false,
            option1Votes: 0,
            option2Votes: 0,
            option3Votes: 0,
            voters: new address[](0) 
        });

        proposals.push(newProposal);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }
    
    function vote(uint256 _proposalIndex, uint256 _vote) external noReentry {
        require(_proposalIndex < proposals.length, "Invalid proposal index");
        require(_vote <= 2, "Invalid vote"); 
        require(starterContract.getStakeData(msg.sender) > 0, "Address has no positive stake");
        Proposal storage proposal = proposals[_proposalIndex];
        require(!proposal.closed, "Proposal is closed");
        require(block.timestamp >= proposal.startTime, "Voting has not started yet");
        require(block.timestamp < proposal.endTime, "Voting has ended");
        require(!hasVoted(proposal, msg.sender), "Already voted");
    
        if (_vote == 1) {
            proposal.option1Votes += 1;
        } else if (_vote == 0) {
            proposal.option2Votes += 1;
        } else if (_vote == 2) {
            proposal.option3Votes += 1;
        }

        proposal.voters.push(msg.sender); 
    }


    function closeProposal(uint256 _proposalIndex) external onlyOwner {
        require(_proposalIndex < proposals.length, "Invalid proposal index");
        Proposal storage proposal = proposals[_proposalIndex];
        require(!proposal.closed, "Proposal is already closed");
        require(block.timestamp >= proposal.endTime, "Voting is still open");

        proposal.closed = true;
    }



    function getProposal(uint256 _proposalIndex) external view returns (
        address owner_,
        string memory title,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        uint256 votingPeriodInDays,
        bool closed,
        uint256 option1Votes,
        uint256 option2Votes,
        uint256 option3Votes,
        address[] memory voters
    ) {
        require(_proposalIndex < proposals.length, "Invalid proposal index");
        Proposal storage proposal = proposals[_proposalIndex];
        return (
            proposal.owner,
            proposal.title,
            proposal.description,
            proposal.startTime,
            proposal.endTime,
            proposal.votingPeriodInDays,
            proposal.closed,
            proposal.option1Votes,
            proposal.option2Votes,
            proposal.option3Votes,
            proposal.voters
        );
    }

    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

     function getStakeData(address _address) external view returns (uint256) {
        return starterContract.getStakeData(_address);
    }
    
    function getAllProposals() external view returns (Proposal[] memory) {
        return proposals;
    }
    
    function hasVoted(Proposal storage proposal, address voter) internal view returns (bool) {
        for (uint256 i = 0; i < proposal.voters.length; i++) {
            if (proposal.voters[i] == voter) {
                return true;
            }
        }
        return false;
    }
 
}
