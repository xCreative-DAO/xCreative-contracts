const { web3tx, toWad, toBN } = require("@decentral.ee/web3-helpers");
const { expectRevert } = require("@openzeppelin/test-helpers");

const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework");
const deployTestToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-test-token");
const deploySuperToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-super-token");
const SuperfluidSDK = require("@superfluid-finance/js-sdk");


const xDAO = artifacts.require("xCreativeDAO");
const xERC20 = artifacts.require("xCreative");
const xERC721 = artifacts.require("xCreativeWrapper");
const xOracle = artifacts.require("MockOracle");
const Mock721 = artifacts.require("Mock721");

contract("xCreative", accounts => {

  let gov;
  let x20;
  let x20x;
  let x721;
  let xora;
  let mock721;
  let sf;

  const errorHandler = err => {
    if (err) throw err;
  };

  function genId(tokenAddress, tokenId) {
    return web3.utils.soliditySha3(tokenAddress, tokenId);
  };

  beforeEach(async function() {

    await deployFramework(errorHandler, { web3: web3, from: accounts[0] });

    sf = new SuperfluidSDK.Framework({
      web3: web3,
      version: "test"
    });

    await sf.initialize();

    mock721 = await web3tx(Mock721.new, "Deploying ERC721")("TotallyFakeNFT", "TFNFT");
    xora = await web3tx(xOracle.new, "Deploying xOracle")();
    gov = await web3tx(xDAO.new, "Deploying DAO")(
      xora.address, sf.host.address, sf.agreements.ida.address, 10, 25
    );
    x20 = await web3tx(xERC20.new, "Deploying xCreative")(
      gov.address
    );
    const x20Wrap = await sf.createERC20Wrapper(x20);
    x20x = await sf.contracts.ISuperToken.at(x20Wrap.address);
    await gov.whitelistERC20(x20x.address);
    x721 = await web3tx(xERC721.new, "Deploying xWrapper")(
      gov.address
    );

    await gov.whitelistERC721(x721.address);
    await gov.mint(accounts[1], toWad(100));
    //await x20.approve(x20x.address,toWad(100),{ from:accounts[1] });
    await mock721.batchMint(accounts[1], ["1", "2", "3", "4"]);
  });

  it("Running uses cases", async () => {

    const wrapId = genId(mock721.address, 1);
    const data = web3.eth.abi.encodeParameters(["uint256"],[toWad("1").toString()]);
    //Wrap existing erc721
    const overST = await mock721.
      contract.methods["safeTransferFrom(address,address,uint256,bytes)"](accounts[1], x721.address, 1, data).encodeABI();
    await web3.eth.sendTransaction({ to: mock721.address, from: accounts[1], data: overST , gasPrice: 1e9, gas:1000000});
    let r = await x721.balanceOf(accounts[1]);
    let ownerOf = await x721.ownerOf(wrapId);
    console.log(r.toString());
    console.log(" ID (0x): ", wrapId, " -> ", ownerOf ," = ", accounts[1]);
    let tokenInfo = await x721.getToken(wrapId);
    console.log(tokenInfo);

    await x721.buy(wrapId, accounts[2], toWad(2), {from:accounts[2], value: toWad(1)});

    await web3tx(
      sf.host.callAgreement,
      "Seller approves subscription"
    )(
      sf.agreements.ida.address,
      sf.agreements.ida.contract.methods
      .approveSubscription(x20x.address, gov.address, 1, "0x")
      .encodeABI(),
      "0x", // user data
      {
        from: accounts[1]
      }
    );

    console.log("SuperToken Balance (1): ", (await x20x.balanceOf(accounts[1])).toString());
    console.log(await web3.eth.getBalance(x721.address));
    await x721.buy(wrapId, accounts[3], toWad(3), {from:accounts[2], value: toWad(2)});
    await web3tx(
      sf.host.callAgreement,
      "Seller2 approves subscription"
    )(
      sf.agreements.ida.address,
      sf.agreements.ida.contract.methods
      .approveSubscription(x20x.address, gov.address, 1, "0x")
      .encodeABI(),
      "0x", // user data
      {
        from: accounts[2]
      }
    );

    console.log("SuperToken Balance (1): ", (await x20x.balanceOf(accounts[1])).toString());
    console.log("SuperToken Balance (2): ", (await x20x.balanceOf(accounts[2])).toString());
    await x721.buy(wrapId, accounts[4], toWad(4), {from:accounts[4], value: toWad(3)});
    await web3tx(
      sf.host.callAgreement,
      "Seller3 approves subscription"
    )(
      sf.agreements.ida.address,
      sf.agreements.ida.contract.methods
      .approveSubscription(x20x.address, gov.address, 1, "0x")
      .encodeABI(),
      "0x", // user data
      {
        from: accounts[3]
      }
    );
    console.log("SuperToken Balance (1): ", (await x20x.balanceOf(accounts[1])).toString());
    console.log("SuperToken Balance (2): ", (await x20x.balanceOf(accounts[2])).toString());
    console.log("SuperToken Balance (3): ", (await x20x.balanceOf(accounts[3])).toString());
    /*
      //transfer unwraping the token first and burn tokens
    await x721.safeTransferFrom(accounts[1], accounts[2], wrapId, {from: accounts[1]});
    r = await x721.balanceOf(accounts[1]);
    //ownerOf = await x721.ownerOf(wrapId);
    console.log(r.toString());
    tokenInfo = await x721.getToken(wrapId);
    console.log(tokenInfo);
    let soloToken = await mock721.balanceOf(accounts[2]);
    console.log(soloToken.toString());
    */
  });

});
