describe("Gas Reporting", function () {
  it("New Seasons", async function () {
    const pass = await ethers.getContractFactory("Pass");
    const passfr = await pass.deploy("uri", "0x0000000000000000000000000000000000000000");
    const red = await ethers.getContractFactory("Redeemable");
    const redeem = await red.deploy("uri", passfr.address, "0x0000000000000000000000000000000000000000");
    // Base case: maxlevel = 1 and 2xlvlinfo and gas usage: 
    const baseinfo = {
      xpToCompleteLevel: '1',
      freeReward: {
        token: redeem.address,
        id: '1',
        qty: '1'
      },
      premiumReward: {
        token: redeem.address,
        id: '1',
        qty: '1'
      }  
    }
    const lastinfo = {
      xpToCompleteLevel: '0',
      freeReward: {
        token: redeem.address,
        id: '1',
        qty: '1'
      },
      premiumReward: {
        token: redeem.address,
        id: '1',
        qty: '1'
      }  
    }
    let res;
    try {
      res = await passfr.newSeason(1, [baseinfo, lastinfo], {gasLimit: 391653})
      hre.ethers.provider.waitForTransaction(res.hash);
    } catch (e) {
      console.log("ERROR !!!");
    }
    rec = await hre.ethers.provider.getTransactionReceipt(res.hash);
    console.log(rec.gasUsed);
  });
});