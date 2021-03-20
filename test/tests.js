const { web3tx, toWad, toBN } = require("@decentral.ee/web3-helpers");
const { expectRevert } = require("@openzeppelin/test-helpers");

const xDAO = artifacts.require("xCreativeDAO");
const xERC20 = artifacts.require("xCreative");
const xERC721 = artifacts.require("xCreativeWrapper");
const xOracle = artifacts.require("MockOracle");
const Mock721 = artifacts.require("Mock721");

contract("xCreative", accounts => {

  let gov;
  let x20;
  let x721;
  let xora;
  let mock721;

  const errorHandler = err => {
    if (err) throw err;
  };

  function genId(tokenAddress, tokenId) {
    return web3.utils.soliditySha3(tokenAddress, tokenId);
  };

  beforeEach(async function() {

    mock721 = await web3tx(Mock721.new, "Deploying ERC721")("TotallyFakeNFT", "TFNFT");
    xora = await web3tx(xOracle.new, "Deploying xOracle")();
    gov = await web3tx(xDAO.new, "Deploying DAO")(
      xora.address, 25, 5
    );
    x20 = await web3tx(xERC20.new, "Deploying xCreative")(
      gov.address
    );
    await gov.whitelistERC20(x20.address);
    x721 = await web3tx(xERC721.new, "Deploying xWrapper")(
      gov.address
    );

    await gov.mint(accounts[1], toWad(10));
    await mock721.batchMint(accounts[1], ["1", "2", "3", "4"]);
  });
  
  it("Running uses cases", async () => {

    const wrapId = genId(mock721.address, 1);

    const data = web3.eth.abi.encodeParameters(["uint256"],[toWad("1").toString()]);
    //Wrap existing erc721
    const overST = await mock721.
      contract.methods["safeTransferFrom(address,address,uint256,bytes)"](accounts[1], x721.address, 1, data).encodeABI();
    await web3.eth.sendTransaction({ to: mock721.address, from: accounts[1], data: overST , gasPrice: 1e9, gas:1000000});

    const r = await x721.balanceOf(accounts[1]);
    const ownerOf = await x721.ownerOf(wrapId);
    console.log(r.toString());
    console.log(" ID (0x): ", wrapId, " -> ", ownerOf ," = ", accounts[1]);
    });


});
