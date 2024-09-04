// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RankedChoice} from "src/RankedChoice.sol";

contract RankedChoiceTest is Test {
    address[] voters;
    address[] candidates;

    uint256 constant MAX_VOTERS = 100;
    uint256 constant MAX_CANDIDATES = 20;
    uint256 constant VOTERS_ADDRESS_MODIFIER = 100;
    uint256 constant CANDIDATES_ADDRESS_MODIFIER = 200;

    RankedChoice rankedChoice;

    address[] orderedCandidates;

    function setUp() public {
        for (uint256 i = 0; i < MAX_VOTERS; i++) {
            voters.push(address(uint160(i + VOTERS_ADDRESS_MODIFIER)));
        }
        rankedChoice = new RankedChoice(voters);

        for (uint256 i = 0; i < MAX_CANDIDATES; i++) {
            candidates.push(address(uint160(i + CANDIDATES_ADDRESS_MODIFIER)));
        }
    }

    function testVote() public {
        orderedCandidates = [candidates[0], candidates[1], candidates[2]];
        vm.prank(voters[0]);
        rankedChoice.rankCandidates(orderedCandidates);

        assertEq(rankedChoice.getUserCurrentVote(voters[0]), orderedCandidates);
    }

    function testSelectPresident() public {
        assert(rankedChoice.getCurrentPresident() != candidates[0]);

        orderedCandidates = [candidates[0], candidates[1], candidates[2]];
        uint256 startingIndex = 0;
        uint256 endingIndex = 60;
        for (uint256 i = startingIndex; i < endingIndex; i++) {
            vm.prank(voters[i]);
            rankedChoice.rankCandidates(orderedCandidates);
        }

        startingIndex = endingIndex + 1;
        endingIndex = 100;
        orderedCandidates = [candidates[3], candidates[1], candidates[4]];
        for (uint256 i = startingIndex; i < endingIndex; i++) {
            vm.prank(voters[i]);
            rankedChoice.rankCandidates(orderedCandidates);
        }

        vm.warp(block.timestamp + rankedChoice.getDuration());

        rankedChoice.selectPresident();
        assertEq(rankedChoice.getCurrentPresident(), candidates[0]);
    }

    function testSelectPresidentWhoIsSecondMostPopular() public {
        assert(rankedChoice.getCurrentPresident() != candidates[0]);

        orderedCandidates = [candidates[0], candidates[1], candidates[2]];
        uint256 startingIndex = 0;
        uint256 endingIndex = 24;
        for (uint256 i = startingIndex; i < endingIndex; i++) {
            vm.prank(voters[i]);
            rankedChoice.rankCandidates(orderedCandidates);
        }

        startingIndex = endingIndex + 1;
        endingIndex = 49;
        orderedCandidates = [candidates[3], candidates[1], candidates[4]];
        for (uint256 i = startingIndex; i < endingIndex; i++) {
            vm.prank(voters[i]);
            rankedChoice.rankCandidates(orderedCandidates);
        }

        startingIndex = endingIndex + 1;
        endingIndex = 74;
        orderedCandidates = [candidates[7], candidates[1], candidates[10]];
        for (uint256 i = 0; i < MAX_VOTERS / 3; i++) {
            vm.prank(voters[i]);
            rankedChoice.rankCandidates(orderedCandidates);
        }

        startingIndex = endingIndex + 1;
        endingIndex = 82;
        orderedCandidates = [candidates[12], candidates[1], candidates[18]];
        for (uint256 i = 0; i < MAX_VOTERS / 3; i++) {
            vm.prank(voters[i]);
            rankedChoice.rankCandidates(orderedCandidates);
        }

        startingIndex = endingIndex + 1;
        endingIndex = 100;
        orderedCandidates = [candidates[1], candidates[9], candidates[11]];
        for (uint256 i = 0; i < MAX_VOTERS / 3; i++) {
            vm.prank(voters[i]);
            rankedChoice.rankCandidates(orderedCandidates);
        }

        vm.warp(block.timestamp + rankedChoice.getDuration());

        rankedChoice.selectPresident();
        assertEq(rankedChoice.getCurrentPresident(), candidates[1]);
    }
}
