pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    var numOfHashersPerLevel = 2**(n-1);
    var numOfLevels = n + 1;

    // The total number of hashers
    var numHashers = 0;
    for (var i = 0; i < numOfLevels; i++) {
        numHashers += 2 ** i;
    }

    component hashers[numHashers];

    // Instantiate all hashers
    for (var i = 0; i < numHashers; i ++) {
        hashers[i] = Poseidon(2);
    }

    var numLeafHashers = 2**(n-1); // num of leaves divide by 2
    // Wire the leaf values into the leaf hashers
    for (var i = 0; i < numLeafHashers; i ++){
        for (var j = 0; j < 2; j++){
            hashers[i].inputs[j] <== leaves[i * 2 + j];
        }
    }

    // Wire the outputs of the leaf hashers to the intermediate hasher inputs
    var k = 0;
    for (var i = numLeafHashers; i < numHashers; i ++) {
        for (var j = 0; j < 2; j++){
            hashers[i].inputs[j] <== hashers[k * 2 + j].out;
        }
        k ++;
    }

    // Wire the output of the final hash to this circuit's output
    root <== hashers[numHashers-1].out;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    component hashers[n];

    // Instantiate all hashers
    for (var i = 0; i < n; i++) {
        hashers[i] = Poseidon(2);
    }

    signal results[n+1]; // all the intermediate hashing results
    leaf ==> results[0]; // initialize the first result as a leaf so it can be used in loop

    component switcher[n];
    for (var i=0; i<n; i++) {
        assert (path_index[i] == 0 || path_index[i] == 1);
        switcher[i] = Switcher();
        switcher[i].L <== results[i];
        switcher[i].R <== path_elements[i];
        // if 0 path element is on the left, else is on the right
        switcher[i].sel <== path_index[i];
        hashers[i].inputs[0] <== switcher[i].outL;
        hashers[i].inputs[1] <== switcher[i].outR;
        results[i+1] <== hashers[i].out;
    }
    root <== results[n];
}

