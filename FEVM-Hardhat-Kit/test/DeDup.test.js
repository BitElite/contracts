const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("DeDup Contract", async function () {
    const [owner] = await ethers.getSigners()

    const DeDupContract = await ethers.getContractFactory("DeDup")

    const DeDup = await DeDupContract.attach(
        "0x9554f87b74B324570d1B326c4549C1394635Ef64" // The deployed contract address
    )
    it("Deployment should assign the Admin address", async function () {
        const AdminAddress = await DeDup.Admin()
        console.log(AdminAddress)
        // expect(await AdminAddress.to.equal("0x75BBA77238AF21bf7Cfa1B515fa5EAee4419BaBB"));
    })

    it("Return true if CID exists", async function () {
      //const CID = ethers.utils.keccak256("0x1234");
      // const tx = await DeDup.withDrawUser();
      // await tx.wait({value:"",from:owner})

      const tx = await owner.sendTransaction({
        to: "0x9554f87b74B324570d1B326c4549C1394635Ef64",
        value: ethers.utils.parseUnits("0.001", "ether"),
        gasLimit: ethers.utils.parseUnits("9", "gwei"),
        nonce: owner.getTransactionCount(),
        maxPriorityFeePerGas: ethers.utils.parseUnits("100", "gwei"),
        chainId: 31415,
      });
    })
})
