import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import { Registry__factory, HyphenImplL1__factory, IERC20__factory } from "../typechain";

describe("deploy Registry implementation", () => {
  let signer: SignerWithAddress;

  before(async () => {
    const USDC_HOLDER = "0xF977814e90dA44bFA03b6295A0616a897441aceC";
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [USDC_HOLDER],
    });

    signer = await ethers.getSigner(USDC_HOLDER);
  });

  it("should add routes", async () => {
    const regDeployer = new Registry__factory(signer);
    const reg = await regDeployer.deploy();
    const placeHolderAddress = "0xF977814e90dA44bFA03b6295A0616a897441aceC";
    const tx = await reg.addRoutes([
      {
        route: placeHolderAddress,
        enabled: true,
        isMiddleware: true,
      },
    ]);
    const routeResult = await tx.wait();
    const routeAddedEvent = routeResult.events?.find(
      event => event.eventSignature === "NewRouteAdded(uint256,address,bool,bool)" && event.event === "NewRouteAdded",
    );
    expect(routeAddedEvent?.args?.length).to.be.equals(4);

    const routeUpdatedResult = await (
      await reg.updateRoute(0, {
        route: placeHolderAddress,
        enabled: true,
        isMiddleware: true,
      })
    ).wait();

    const routeUpdatedEvent = routeUpdatedResult.events?.find(
      event => event.eventSignature === "RouteUpdated(uint256,address,bool,bool)" && event.event === "RouteUpdated",
    );
    expect(routeUpdatedEvent?.args?.length).to.be.equals(4);
  });
});
