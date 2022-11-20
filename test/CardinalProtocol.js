const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Cardinal Protocol", function () {
  it(
    "Should set the msg.sender to DEFAULT_ADMIN_ROLE",
    async function () {
      const CardinalProtocol = await ethers.getContractFactory(
        "CardinalProtocol"
      );
      const cardinalProtocol = await CardinalProtocol.deploy();
    }
  );
});
