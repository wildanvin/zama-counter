import { task } from "hardhat/config";
import type { TaskArguments } from "hardhat/types";

import { createInstances } from "../test/instance";
import { getSigners } from "../test/signers";

task("task:mint")
  .addParam("mint", "Tokens to mint")
  .addParam("account", "Specify which account [alice, bob, carol, dave]")
  .setAction(async function (taskArguments: TaskArguments, hre) {
    const { ethers, deployments } = hre;
    const EncryptedERC20 = await deployments.get("EncryptedERC20");
    const signers = await getSigners(ethers);

    const instances = await createInstances(EncryptedERC20.address, ethers, signers);

    const encryptedERC20 = await ethers.getContractAt("EncryptedERC20", EncryptedERC20.address);

    await encryptedERC20
      .connect((signers as any)[taskArguments.account])
      .mint((instances as any)[taskArguments.account].encrypt32(+taskArguments.mint));

    console.log("Mint done: ", taskArguments.mint);
  });
