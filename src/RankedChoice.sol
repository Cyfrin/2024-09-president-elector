// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RankedChoice is EIP712 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error RankedChoice__NotTimeToVote();
    error RankedChoice__InvalidInput();
    error RankedChoice__InvalidVoter();
    error RankedChoice__SomethingWentWrong();

    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address private s_currentPresident;
    uint256 private s_previousVoteEndTimeStamp;
    uint256 private s_voteNumber;
    uint256 private immutable i_presidentalDuration;
    bytes32 public constant TYPEHASH = keccak256("rankCandidates(uint256[])");
    uint256 private constant MAX_CANDIDATES = 10;

    // Solidity doesn't support contant reference types
    address[] private VOTERS;
    mapping(address voter => mapping(uint256 voteNumber => address[] orderedCandidates))
        private s_rankings;

    // For selecting the president
    address[] private s_candidateList;
    mapping(address candidate => mapping(uint256 voteNumber => mapping(uint256 roundId => uint256 votes)))
        private s_candidateVotesByRound;

    /*//////////////////////////////////////////////////////////////
                             USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address[] memory voters) EIP712("RankedChoice", "1") {
        VOTERS = voters;
        i_presidentalDuration = 1460 days;
        s_currentPresident = msg.sender;
        s_voteNumber = 0;
    }

    function rankCandidates(address[] memory orderedCandidates) external {
        _rankCandidates(orderedCandidates, msg.sender);
    }

    function rankCandidatesBySig(
        address[] memory orderedCandidates,
        bytes memory signature
    ) external {
        bytes32 structHash = keccak256(abi.encode(TYPEHASH, orderedCandidates));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        _rankCandidates(orderedCandidates, signer);
    }

    function selectPresident() external {
        if (
            block.timestamp - s_previousVoteEndTimeStamp <=
            i_presidentalDuration
        ) {
            revert RankedChoice__NotTimeToVote();
        }

        for (uint256 i = 0; i < VOTERS.length; i++) {
            address[] memory orderedCandidates = s_rankings[VOTERS[i]][
                s_voteNumber
            ];
            for (uint256 j = 0; j < orderedCandidates.length; j++) {
                if (!_isInArray(s_candidateList, orderedCandidates[j])) {
                    s_candidateList.push(orderedCandidates[j]);
                }
            }
        }

        address[] memory winnerList = _selectPresidentRecursive(
            s_candidateList,
            0
        );

        if (winnerList.length != 1) {
            revert RankedChoice__SomethingWentWrong();
        }

        // Reset the election and set President
        s_currentPresident = winnerList[0];
        s_candidateList = new address[](0);
        s_previousVoteEndTimeStamp = block.timestamp;
        s_voteNumber += 1;
    }

    /*//////////////////////////////////////////////////////////////
                           CONTRACT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _selectPresidentRecursive(
        address[] memory candidateList,
        uint256 roundNumber
    ) internal returns (address[] memory) {
        if (candidateList.length == 1) {
            return candidateList;
        }

        // Tally up the picks
        for (uint256 i = 0; i < VOTERS.length; i++) {
            for (
                uint256 j = 0;
                j < s_rankings[VOTERS[i]][s_voteNumber].length;
                j++
            ) {
                address candidate = s_rankings[VOTERS[i]][s_voteNumber][j];
                if (_isInArray(candidateList, candidate)) {
                    s_candidateVotesByRound[candidate][s_voteNumber][
                        roundNumber
                    ] += 1;
                    break;
                } else {
                    continue;
                }
            }
        }

        // Remove the lowest candidate or break
        address fewestVotesCandidate = candidateList[0];
        uint256 fewestVotes = s_candidateVotesByRound[fewestVotesCandidate][
            s_voteNumber
        ][roundNumber];

        for (uint256 i = 1; i < candidateList.length; i++) {
            uint256 votes = s_candidateVotesByRound[candidateList[i]][
                s_voteNumber
            ][roundNumber];
            if (votes < fewestVotes) {
                fewestVotes = votes;
                fewestVotesCandidate = candidateList[i];
            }
        }

        address[] memory newCandidateList = new address[](
            candidateList.length - 1
        );

        bool passedCandidate = false;
        for (uint256 i; i < candidateList.length; i++) {
            if (passedCandidate) {
                newCandidateList[i - 1] = candidateList[i];
            } else if (candidateList[i] == fewestVotesCandidate) {
                passedCandidate = true;
            } else {
                newCandidateList[i] = candidateList[i];
            }
        }

        return _selectPresidentRecursive(newCandidateList, roundNumber + 1);
    }

    function _rankCandidates(
        address[] memory orderedCandidates,
        address voter
    ) internal {
        // Checks
        if (orderedCandidates.length > MAX_CANDIDATES) {
            revert RankedChoice__InvalidInput();
        }
        if (!_isInArray(VOTERS, voter)) {
            revert RankedChoice__InvalidVoter();
        }

        // Internal Effects
        s_rankings[voter][s_voteNumber] = orderedCandidates;
    }

    function _isInArray(
        address[] memory array,
        address someAddress
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == someAddress) {
                return true;
            }
        }
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getUserCurrentVote(
        address voter
    ) external view returns (address[] memory) {
        return s_rankings[voter][s_voteNumber];
    }

    function getDuration() external view returns (uint256) {
        return i_presidentalDuration;
    }

    function getCurrentPresident() external view returns (address) {
        return s_currentPresident;
    }
}
