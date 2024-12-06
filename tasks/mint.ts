import { task } from "hardhat/config";
import type { TaskArguments } from "hardhat/types";

import { MyConfidentialERC20 } from "../types";

task("task:deployConfidentialERC20").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const signers = await ethers.getSigners();
  const erc20Factory = await ethers.getContractFactory("MyConfidentialERC20");
  const erc20 = await erc20Factory.connect(signers[0]).deploy("Naraggara", "NARA");
  await erc20.waitForDeployment();
  console.log("ConfidentialERC20 deployed to: ", await erc20.getAddress());
});

task("task:mint")
  .addParam("mint", "Tokens to mint")
  .setAction(async function (taskArguments: TaskArguments, hre) {
    const { ethers, deployments } = hre;
    const ERC20 = await deployments.get("MyConfidentialERC20");

    const signers = await ethers.getSigners();

    const erc20 = (await ethers.getContractAt("MyConfidentialERC20", ERC20.address)) as MyConfidentialERC20;

    await erc20.connect(signers[0]).mint(+taskArguments.mint);

    console.log("Mint done: ", taskArguments.mint);
  });
