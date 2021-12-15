import { expect, assert } from "chai";
import { ethers, network } from "hardhat";
import { Signer, Contract, providers } from "ethers";
import {
  ERC20Gateway,
  ERC20Gateway__factory,
  ERC20__factory,
  IERC20__factory,
  L1Router,
  L1Router__factory,
  MerkleTree,
  MerkleTree__factory,
} from "../src/types";
import { OutboundRequestStruct } from "../src/types/ITree";

describe("deploy gateway and erc20s", () => {
  let destinationChainSigner: Signer;
  let sendingChainSigner: Signer;
  let l1Signer: Signer;
  let sendingChainProvider: providers.Provider;
  let destinationChainProvider: providers.Provider;
  let l1Provider: providers.Provider;
  let request: OutboundRequestStruct;
  before(async () => {
    sendingChainProvider = new ethers.providers.JsonRpcProvider("http://localhost:9545");
    destinationChainProvider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
    l1Provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
    sendingChainSigner = ethers.provider.getSigner();
    destinationChainSigner = ethers.provider.getSigner();
    l1Signer = ethers.provider.getSigner();
  });

  it("deploy MerkleTree and enqueue", async () => {
    // deploy on L1
    const L1Rotuer = await setupL1(l1Signer);

    // deploy token
    const sendingERC20 = await deployERC20(sendingChainSigner);

    // deploy token
    const receivingERC20 = await deployERC20(destinationChainSigner);

    // deploy gateways
    const { chainId } = await destinationChainProvider.getNetwork();
    await installGateway(sendingChainSigner, sendingERC20, receivingERC20, chainId, L1Rotuer);
  });
});

async function deployERC20(deployer: Signer): Promise<Contract> {
  const erc20Factory = new ERC20__factory(deployer);
  const erc20Contract = await erc20Factory.deploy("USDC", "USDC");
  return erc20Contract;
}

async function installGateway(
  signer: Signer,
  sourceToken: Contract,
  destinationToken: Contract,
  destinationChainID: number,
  router: Contract,
) {
  const factory = new ERC20Gateway__factory(signer);
  const gateway = await factory.deploy(
    sourceToken.address,
    destinationToken.address,
    destinationChainID,
    router.address,
    router.address,
  );
}

async function setupDestination(destinationChainSigner: Signer) {}

async function setupL1(signer: Signer): Promise<Contract> {
  const tempDummyAddress = "0x75bbC04fA183dd0ac75857a0400F93f766748f01";
  const factory = new L1Router__factory(signer);
  const routerContract = await factory.deploy(tempDummyAddress, tempDummyAddress, tempDummyAddress, tempDummyAddress);
  return routerContract;
}
