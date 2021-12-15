import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { MerkleTree } from "../../src/types/MerkleTree";
import { MerkleTree__factory } from "../../src/types/factories/MerkleTree__factory";

task("deploy:MerkleTree").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const merkleTreeFactory: MerkleTree__factory = <MerkleTree__factory>await ethers.getContractFactory("MerkleTree");
  const merkleTree: MerkleTree = <MerkleTree>await merkleTreeFactory.deploy(taskArguments.greeting);
  await merkleTree.deployed();
  console.log("MerkleTree deployed to: ", merkleTree.address);
});
