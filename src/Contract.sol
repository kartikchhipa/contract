// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
pragma experimental ABIEncoderV2;

contract Contract {
    
    address public admin;

    enum Phase {
        Init, 
        Reg, 
        Vote,
        Result,
        Done
    }

    constructor () {
        admin = msg.sender;
        candidates.push();
        candidateVotes.push();
        phase = Phase.Init;
    }

    // struct to store the candidate details
    struct Candidate {
        uint256 id;
        string name;
        string party;
        string ipfsHash;
    }

    // struct to store the vote. i.e the candidate id and the corresponding priority
    struct Votes {
        uint id;
        uint priority;
    }

    // struct to store voter details 
    struct Voter {
        uint256 id;
        bool voted;
        bool isRegistered;
    } 

    // struct to store Votes for each candidate this is done to avoid 
    // expoing the votes of each candidate to the public by using the Candidate struct
    struct CandidateVote {
        string name;
        uint256 id;
        uint256 votes;
    } 

    modifier onlyAdmin () {
        require ( msg.sender == admin, "Only admin can call this function" );
        _;
    }

    Phase private phase = Phase.Init;

    modifier ValidPhase(Phase _phase) {
        require ( phase == _phase, "Invalid phase" );
        _;
    }

    function setPhase ( Phase _phase ) public onlyAdmin {
        require ( uint(_phase) == (uint(phase) + 1) && uint(_phase) < uint(Phase.Done), "Not Allowed" );
        phase = _phase;
    }

    // array to store the candidates
    Candidate[] public candidates;
    // array to store the votes for each candidate 
    CandidateVote[] private candidateVotes;

    // mapping to store the index of the candidate in the array
    mapping (uint256 => uint256) public candidate_map;
    // mapping to store the index of the candidateVote in the array
    mapping (uint256 => uint256) public candidateVote_map;
    // mapping to store the voter details
    mapping (uint256 => Voter ) public voter_map;

    function addCandidate ( string memory _name, string memory _party, string memory _ipfsHash ) private onlyAdmin ValidPhase(Phase.Reg) {
        uint256 id = uint256(keccak256(abi.encode(_name)));
        require ( candidate_map[id] == 0, "Candidate already exists!" );
        Candidate memory candidate = Candidate(id, _name, _party, _ipfsHash);  // creating a new candidate in memory
        candidates.push(candidate); // pushing the candidate to the array
        candidate_map[id] = candidates.length - 1; // mapping the candidate id to the index of the candidate in the array 
        CandidateVote memory candidateVote = CandidateVote(_name, id , 0); // creating a new candidateVote in memory 
        candidateVotes.push(candidateVote); // pushing the candidateVote to the array
        candidateVote_map[id] = candidateVotes.length - 1; // mapping the candidate id to the index of the candidateVote in the array
    }

    // function to retrieve the candidate details
    function getCandidates () public view returns (Candidate[] memory) {
        require ( phase!=Phase.Init, "Invalid Phase!" );
        return candidates;
    }

    // function to register voters using their aadhaar number
    function addVoter ( string memory _aadhaar ) private ValidPhase(Phase.Reg) {
        uint256 id = uint256(keccak256(abi.encode(_aadhaar)));
        require( voter_map[id].isRegistered == false, "Voter already registered!" );
        Voter memory voter = Voter(id, false, true);
        voter_map[id] = voter;
    }

    // function to vote for the candidates based on priority voting system
    function vote ( string memory _aadhaar, Votes[] calldata _votes ) private ValidPhase(Phase.Vote) {
        uint256 id = uint256(keccak256(abi.encode(_aadhaar)));
        require( voter_map[id].isRegistered == true, "Voter not registered" );
        require( voter_map[id].voted == false, "Voter already voted" );
        voter_map[id].voted = true;
        for ( uint256 i = 0 ; i < _votes.length ; i++ ) {
            candidateVotes[candidateVote_map[_votes[i].id]].votes += _votes[i].priority;
        }
    }

    // function to vote for candidate based on first past the post system
    function vote1 ( string memory _aadhaar, uint256 _candidateId ) public ValidPhase(Phase.Vote){
        uint256 id = uint256(keccak256(abi.encode(_aadhaar)));
        require( voter_map[id].isRegistered == true, "Voter not registered" );
        require( voter_map[id].voted == false, "Voter already voted" );
        voter_map[id].voted = true;
        candidateVotes[candidateVote_map[_candidateId]].votes++;
    }

    // function to get the result of the election
    function getCandidateVotes () public view returns (CandidateVote[] memory) {
        require( phase == Phase.Done, "Invalid Phase!");
        return candidateVotes;
    }

    CandidateVote private winner;

    function votingResult() public view returns(CandidateVote memory) {
        require( phase == Phase.Done , "Invalid Phase!");
        return winner;
    }

    function generateResult () public ValidPhase(Phase.Result) ValidPhase(Phase.Result) {
        uint256 maxVotes = 0;
        for ( uint256 i = 0 ; i < candidateVotes.length ; i++ ) {
            if ( candidateVotes[i].votes > maxVotes ) {
                maxVotes = candidateVotes[i].votes;
            }
        }
        uint count = 0;
        for ( uint256 i = 0 ; i < candidateVotes.length ; i++ ) {
            if ( candidateVotes[i].votes == maxVotes ) {
                count++;
            }
        }

        uint256 randomBytes = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, blockhash(block.number-1))));
        uint256 random = randomBytes % count;
        CandidateVote[] memory result = new CandidateVote[](count);
        uint256 index = 0;
        for ( uint256 i = 0 ; i < candidateVotes.length ; i++ ) {
            if ( candidateVotes[i].votes == maxVotes ) {
                result[index] = candidateVotes[i];
                index++;
            }
        }
        winner = result[random];
        phase = Phase.Done;
    }
}