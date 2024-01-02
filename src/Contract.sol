// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;

contract Contract {
    
    address public admin;

    constructor () {
        admin = msg.sender;
        candidates.push();
        candidateVotes.push();
    }

    struct Candidate {
        uint256 id;
        string name;
        string party;
        string ipfsHash;
    }

    struct Voter {
        uint256 id;
        bool voted;
        bool isRegistered;
    }

    struct CandidateVote {
        string name;
        uint256 id;
        uint256 votes;
    }

    modifier onlyAdmin () {
        require ( msg.sender == admin, "Only admin can call this function" );
        _;
    }

    Candidate[] public candidates;
    CandidateVote[] private candidateVotes;

    mapping (uint256 => uint256) public candidate_map;
    mapping (uint256 => uint256) public candidateVote_map;
    mapping (uint256 => Voter ) public voter_map;

    function addCandidate ( string memory _name, string memory _party, string memory _ipfsHash ) public onlyAdmin {
        uint256 id = uint256(keccak256(abi.encode(_name , _party , _ipfsHash)));
        Candidate memory candidate = Candidate(id, _name, _party, _ipfsHash);
        candidates.push(candidate);
        candidate_map[id] = candidates.length - 1;
        CandidateVote memory candidateVote = CandidateVote(_name, id , 0);
        candidateVotes.push(candidateVote);
        candidateVote_map[id] = candidateVotes.length - 1;
    }

    function getCandidates () public view returns (Candidate[] memory) {
        return candidates;
    }

    function addVoter ( string memory _aadhaar ) public {
        uint256 id = uint256(keccak256(abi.encode(_aadhaar)));
        require( voter_map[id].isRegistered == false, "Voter already registered" );
        Voter memory voter = Voter(id, false, true);
        voter_map[id] = voter;
    }

    struct Votes {
        uint id;
        uint priority;
    }

    function vote ( string memory _aadhaar, Votes[] memory _votes ) public {
        uint256 id = uint256(keccak256(abi.encode(_aadhaar)));
        require( voter_map[id].isRegistered == true, "Voter not registered" );
        require( voter_map[id].voted == false, "Voter already voted" );
        voter_map[id].voted = true;
        for ( uint256 i = 0 ; i < _votes.length ; i++ ) {
            candidateVotes[candidateVote_map[_votes[i].id]].votes += _votes[i].priority;
        }
    }

    function vote1 ( string memory _aadhaar, uint256 _candidateId ) public {
        uint256 id = uint256(keccak256(abi.encode(_aadhaar)));
        require( voter_map[id].isRegistered == true, "Voter not registered" );
        require( voter_map[id].voted == false, "Voter already voted" );
        voter_map[id].voted = true;
        candidateVotes[candidateVote_map[_candidateId]].votes++;
    }

    function getCandidateVotes () public view returns (CandidateVote[] memory) {
        return candidateVotes;
    }

    function getResult () public view returns (CandidateVote memory) {
        uint256 maxVotes = 0;
        uint256 maxVotesIndex = 0;
        for ( uint256 i = 0 ; i < candidateVotes.length ; i++ ) {
            if ( candidateVotes[i].votes > maxVotes ) {
                maxVotes = candidateVotes[i].votes;
                maxVotesIndex = i;
            }
        }
        return candidateVotes[maxVotesIndex];
    }

}
