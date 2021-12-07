import { expect, assert } from "chai";
import { ethers, network } from "hardhat";
import { MerkleTree, MerkleTree__factory } from "../src/types";
import { OutboundRequestStruct } from "../src/types/ITree";
import { Contract } from "ethers";
import { encode } from "punycode";

describe("deploy gateway and erc20s", () => {
  const TREE_DEPTH = 32;
  let signer: any;
  let request: OutboundRequestStruct;
  before(async () => {
    signer = ethers.provider.getSigner();
    request = {
      from: signer,
      receiver: signer,
      destinationChainID: "123",
      amount: "123",
      transferID: "123",
    };
  });

  it("deploy MerkleTree and enqueue", async () => {
    const signer = ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();
    const mtFactory = new MerkleTree__factory(signer);
    const merkleTree = await mtFactory.deploy();

    const request: OutboundRequestStruct = {
      from: signerAddress,
      receiver: signerAddress,
      destinationChainID: "123",
      amount: "123",
      transferID: "123",
    };
    const expectedLeaf = "0xfb6f61b498ade45bb65a6b83ad0ae3bac423856f0c5f6819f87907d145f2ba12";
    const expectedRoot = "0xfec6d1dc6a7f6295d41f035147d930dabef3462feab54c516836d57eff04f64d";

    const leaf = await enqueueRequest(merkleTree, request);
    expect(leaf).to.equal(expectedLeaf);

    const actualRoot = await merkleTree.get_root();
    expect(actualRoot).to.equal(expectedRoot);
    const path = "0000000000000000000000000000000000000000000000000000000000000000";

    const witness = await createProofWithOneLeaf(TREE_DEPTH);
    const valid = await merkleTree.verify(expectedRoot, leaf, path, witness);
    assert(valid, "verify");
  });

  it("deploy MerkleTree and enqueue", async () => {
    const signer = ethers.provider.getSigner();
    const signerAddress = await signer.getAddress();
    const mtFactory = new MerkleTree__factory(signer);
    const merkleTree = await mtFactory.deploy();

    const request: OutboundRequestStruct = {
      from: signerAddress,
      receiver: signerAddress,
      destinationChainID: "123",
      amount: "123",
      transferID: "123",
    };
    const expectedLeaf = "0xfb6f61b498ade45bb65a6b83ad0ae3bac423856f0c5f6819f87907d145f2ba12";
    const expectedRoot = "0xfec6d1dc6a7f6295d41f035147d930dabef3462feab54c516836d57eff04f64e";

    const leaf = await enqueueRequest(merkleTree, request);
    expect(leaf).to.equal(expectedLeaf);

    const path = "0000000000000000000000000000000000000000000000000000000000000000";

    const witness = await createProofWithOneLeaf(TREE_DEPTH);
    const valid = await merkleTree.verify(expectedRoot, leaf, path, witness);
    assert(!valid, "verify");
  });
});

function hash(data: any) {
  return ethers.utils.sha256(data);
}

async function encodeLeaves(leaf_1: any, leaf_2: any) {
  const coder = ethers.utils.defaultAbiCoder;
  return coder.encode(["bytes32", "bytes32"], [leaf_1, leaf_2]);
}

async function getParentNode(leaf_1: any, leaf_2: any) {
  return hash(await encodeLeaves(leaf_1, leaf_2));
}

async function getZeroAtHeight(merkleTree: MerkleTree, height: number) {
  return await merkleTree.zero_hashes(height);
}

async function createZeros(depth: number) {
  var zero_hashes: string[] = new Array(depth);
  zero_hashes.fill("0x0000000000000000000000000000000000000000000000000000000000000000");
  for (let height = 0; height < depth; height++) {
    zero_hashes[height + 1] = await getParentNode(zero_hashes[height], zero_hashes[height]);
  }
  return zero_hashes;
}

async function enqueueRequest(merkleTree: MerkleTree, request: OutboundRequestStruct): Promise<string> {
  const enqTx = await merkleTree.enqueueOutbound(request);
  const leaf_request_1 = await merkleTree.createTransferHash(request);
  await enqTx.wait();
  return leaf_request_1;
}

async function createProofWithOneLeaf(depth: number) {
  var witness: string[] = new Array(depth);
  const zero_hashes = await createZeros(depth);
  for (let height = 0; height < depth; height++) {
    witness[height] = zero_hashes[height];
  }
  return witness;
}
