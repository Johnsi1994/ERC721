const {MerkleTree} = require("merkletreejs")
const keccak256 = require("keccak256")

// List of 4 Ethereum addresses
let addresses = [
    "0x1fB23Df60A94666893F2b75eD7f179288cf88298",
    "0x221A744e381C2dae12A78Cfad9d62d44520206E7",
    "0x23CFaD0a9DFec8Cc897DdbE97C991BA6Fc510f64",
    "0x0A340b01AD7A7e74ECCf5634213a49daD3b856B9"
]

// Hash leaves
let leaves = addresses.map(addr => keccak256(addr))

// Create tree
let merkleTree = new MerkleTree(leaves, keccak256, {sortPairs: true})
let rootHash = merkleTree.getRoot().toString('hex')

// Pretty-print tree
console.log("merkleTree: ")
console.log(merkleTree.toString())
// print rootHash
console.log("rootHash: " + rootHash)

// Proof
let address = addresses[1]
let hashedAddress = keccak256(address)
let proof = merkleTree.getHexProof(hashedAddress)
console.log("proof: ")
console.log(proof)

// Check proof
let v = merkleTree.verify(proof, hashedAddress, rootHash)
console.log("verify: " + v) // returns true