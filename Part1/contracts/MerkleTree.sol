//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol";

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // by default this array is full of 0s
        hashes = new uint256[](15);
        uint numLeaves = 8;
        //the level from which we get the data to hash
        uint numNodesPerLevel = numLeaves;
        uint level = 0; // leaves are at level 0
        uint baseIndex=0; // index where we start saving hash results
        while (numNodesPerLevel >= 2) {
            uint hashIndex = baseIndex;
            baseIndex = baseIndex + numNodesPerLevel;
            for (uint i=0; i<numNodesPerLevel/2; i++) {
                uint256[2] memory inputs = [hashes[hashIndex + 2*i], hashes[hashIndex + 2*i + 1]];
                hashes[baseIndex + i] = PoseidonT3.poseidon(inputs);
            }
            numNodesPerLevel = numNodesPerLevel / 2;
            level++;
        }
        root = hashes[baseIndex];
    }

    function getRoot() public view returns (uint256) {
        return root;
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        hashes[index] = hashedLeaf; 
        uint targetIndex = index;
        uint otherIndex;
        uint numNodesPerLevel = 8;
        uint256[2] memory inputs;
        while (numNodesPerLevel>=2) {
            if (targetIndex % 2 == 0) {
                otherIndex = targetIndex+1;
                inputs = [hashes[targetIndex], hashes[otherIndex]];
                targetIndex = targetIndex + numNodesPerLevel;
                console.log("new target index %d", targetIndex);
            }
            else {
                otherIndex = targetIndex-1;
                inputs = [hashes[otherIndex], hashes[targetIndex]];
                targetIndex = otherIndex + numNodesPerLevel;
                console.log("new target index %d", targetIndex);
            }
            hashes[targetIndex] = PoseidonT3.poseidon(inputs);
            numNodesPerLevel = numNodesPerLevel/2;
        }
        index++;
        console.log("add leaf with root at index %d", targetIndex);
        root = hashes[targetIndex];
        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {
        console.log("input from circuit is %s", input[0]);
        console.log("contract root is %s", root);
        return input[0]==root && verifyProof(a,b,c,input);
    }
}
