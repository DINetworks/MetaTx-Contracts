// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DIVote is Ownable {
    enum VoteType { YesNo, MultipleChoice }

    struct Proposal {
        string title;
        string description;
        VoteType voteType;
        string[] choices;
        uint256 startTime;
        uint256 endTime;
        uint256 quorum;
        mapping(uint256 => uint256) votes;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voterWeights;
        address[] voterList;
    }

    ERC20Votes public immutable voteToken;
    uint256 public proposalCount;

    mapping(uint256 => Proposal) private proposals;

    event ProposalCreated(uint256 indexed proposalId, string title, uint256 quorum);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 weight, uint256 choice);

    constructor(ERC20Votes _voteToken, address _owner) Ownable(_owner) {
        voteToken = _voteToken;
    }

    function createProposal(
        string calldata _title,
        string calldata _description,
        VoteType _voteType,
        string[] calldata _choices,
        uint256 _duration,
        uint256 _quorum
    ) external onlyOwner {
        require(_choices.length >= 2, "At least two choices required");

        Proposal storage p = proposals[proposalCount];
        p.title = _title;
        p.description = _description;
        p.voteType = _voteType;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + _duration;
        p.quorum = _quorum;

        for (uint256 i = 0; i < _choices.length; i++) {
            p.choices.push(_choices[i]);
        }

        emit ProposalCreated(proposalCount, _title, _quorum);
        proposalCount++;
    }

    function vote(uint256 _proposalId, uint256 _choice) external {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.startTime && block.timestamp <= p.endTime, "Voting not active");
        require(!p.hasVoted[msg.sender], "Already voted");
        require(_choice < p.choices.length, "Invalid choice");

        uint256 weight = voteToken.getPastVotes(msg.sender, p.startTime);
        require(weight > 0, "No voting power at proposal start");

        p.votes[_choice] += weight;
        p.hasVoted[msg.sender] = true;
        p.voterWeights[msg.sender] = weight;
        p.voterList.push(msg.sender);

        emit Voted(_proposalId, msg.sender, weight, _choice);
    }

    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            string memory title,
            string memory description,
            VoteType voteType,
            string[] memory choices,
            uint256 startTime,
            uint256 endTime,
            uint256 quorum
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (p.title, p.description, p.voteType, p.choices, p.startTime, p.endTime, p.quorum);
    }

    function getVotes(uint256 _proposalId) external view returns (uint256[] memory) {
        Proposal storage p = proposals[_proposalId];
        uint256[] memory result = new uint256[](p.choices.length);
        for (uint256 i = 0; i < p.choices.length; i++) {
            result[i] = p.votes[i];
        }
        return result;
    }

    function getVoters(uint256 _proposalId) external view returns (address[] memory, uint256[] memory) {
        Proposal storage p = proposals[_proposalId];
        uint256 length = p.voterList.length;
        address[] memory voters = new address[](length);
        uint256[] memory weights = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address voter = p.voterList[i];
            voters[i] = voter;
            weights[i] = p.voterWeights[voter];
        }

        return (voters, weights);
    }

    function hasQuorum(uint256 _proposalId) public view returns (bool) {
        Proposal storage p = proposals[_proposalId];
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < p.choices.length; i++) {
            totalVotes += p.votes[i];
        }
        return totalVotes >= p.quorum;
    }

    function getResult(uint256 _proposalId) external view returns (string memory result, bool quorumMet) {
        Proposal storage p = proposals[_proposalId];
        quorumMet = hasQuorum(_proposalId);
        if (!quorumMet) {
            return ("Quorum not met", false);
        }

        uint256 winningVote = 0;
        uint256 maxVotes = 0;

        for (uint256 i = 0; i < p.choices.length; i++) {
            if (p.votes[i] > maxVotes) {
                maxVotes = p.votes[i];
                winningVote = i;
            }
        }

        result = p.choices[winningVote];
    }
}