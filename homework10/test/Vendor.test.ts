const truffleAssert = require('truffle-assertions');
import { assert, web3, artifacts } from 'hardhat';

const Vendor = artifacts.require('Vendor');
const Proxy = artifacts.require('ERC1967Proxy');
const TestToken = artifacts.require('TestToken');
const DAIMockToken = artifacts.require('DAIToken');
const MockNFTToken = artifacts.require('MockNFTToken');
const VendorV2 = artifacts.require('VendorV2');
const TestTokenWithoutTransfer = artifacts.require('TestTokenWithoutTransfer');

const bn1e18 = web3.utils.toBN(1e18);

describe('Vendor', () => {
  let accounts: string[];
  let owner: any;
  let payer: any;
  let testTokenInstance: any;
  let testTokenWithoutTransferInstance: any;
  let vendorInstance: any;
  let vendorInstanceForProxy: any;
  let vendorInstanceWithBrokenTransferToken: any;
  let vendorV2Instance: any;
  let DAITokenInstance: any;
  let nftTokenInstance: any;
  let proxyInstance: any;
  let myProxyInstance: any;

  const paymentAmount = bn1e18.muln(1);
  const nftTokenId = 123456789;

  beforeEach(async function () {
    accounts = await web3.eth.getAccounts();
    owner = accounts[0];
    payer = accounts[1];

    testTokenInstance = await TestToken.new(10000);
    DAITokenInstance = await DAIMockToken.new(50);
    nftTokenInstance = await MockNFTToken.new(nftTokenId);
    vendorInstance = await Vendor.new();
    vendorInstanceForProxy = await Vendor.new();
    vendorInstanceWithBrokenTransferToken = await Vendor.new();
    vendorV2Instance = await VendorV2.new();
    testTokenWithoutTransferInstance = await TestTokenWithoutTransfer.new('Sasha Grin token', 'SGRN', 1000000);

    await vendorInstance.initialize(
      testTokenInstance.address,
      DAITokenInstance.address,
      nftTokenInstance.address,
      nftTokenId,
    );

    const data = await vendorInstanceForProxy.contract.methods
      .initialize(testTokenInstance.address, DAITokenInstance.address, nftTokenInstance.address, nftTokenId)
      .encodeABI();
    proxyInstance = await Proxy.new(vendorInstanceForProxy.address, data);

    myProxyInstance = await new web3.eth.Contract(vendorInstanceForProxy.abi, proxyInstance.address);

    await testTokenInstance.transfer(proxyInstance.address, web3.utils.toBN(5).mul(bn1e18));
    await testTokenInstance.transfer(vendorInstance.address, web3.utils.toBN(5).mul(bn1e18));

    await testTokenWithoutTransferInstance.transfer2(
      vendorInstanceWithBrokenTransferToken.address,
      web3.utils.toBN(100).mul(bn1e18),
    );
  });

  describe('Buy tokens with ETH', function () {
    it('Should buyTokens with ETH successfully', async () => {
      const tokenBalanceBefore = await testTokenInstance.balanceOf(owner);
      const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(vendorInstance.address);

      await vendorInstance.buyTokens({ from: owner, value: paymentAmount });

      const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(vendorInstance.address);
      const tokenBalanceAfter = await testTokenInstance.balanceOf(owner);

      assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
      assert.equal(
        true,
        tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))),
      );
    });

    it('Should get back ether if there is not enough Vendor token balance', async () => {
      const ethBalanceBefore = await web3.eth.getBalance(owner);
      const result = await vendorInstance.buyTokens({ from: owner, value: paymentAmount.mul(web3.utils.toBN(1000)) });
      const ethBalanceAfter = await web3.eth.getBalance(owner);
      const transaction = await web3.eth.getTransaction(result.tx);

      assert.equal(
        true,
        web3.utils
          .toBN(result.receipt.gasUsed)
          .mul(web3.utils.toBN(transaction.gasPrice))
          .eq(web3.utils.toBN(ethBalanceBefore).sub(web3.utils.toBN(ethBalanceAfter))),
      );
    });

    it("Should throw an error if msg.sender is not an owner of 'key NFT token'", async () => {
      await truffleAssert.reverts(
        vendorInstance.buyTokens({ from: payer, value: paymentAmount }),
        "Sorry, you don't have a key to use this.",
      );
    });

    it('Should emit "Log" event on try catch#1 in buyTokens method', async () => {
      const result = await vendorInstanceWithBrokenTransferToken.buyTokens({ from: owner, value: paymentAmount });
      await truffleAssert.eventEmitted(result, 'Log');

      await truffleAssert.eventEmitted(result, 'LogBytes');

      const tokenBalanceBefore = await testTokenInstance.balanceOf(owner);
      const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(vendorInstance.address);

      await vendorInstance.buyTokens({ from: owner, value: paymentAmount, gas: 200 });

      const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(vendorInstance.address);
      const tokenBalanceAfter = await testTokenInstance.balanceOf(owner);

      assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
      assert.equal(
        true,
        tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))),
      );
    });
  });

  describe('Buy tokens with DAI', function () {
    it('Should swap Tokens for DAI successfully', async () => {
      await testTokenInstance.transfer(vendorInstance.address, web3.utils.toBN(500).mul(bn1e18));
      await DAITokenInstance.approve(vendorInstance.address, web3.utils.toBN(50).mul(bn1e18));
      const tokenBalanceBefore = await testTokenInstance.balanceOf(owner);
      const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(vendorInstance.address);

      const DAIBalanceBefore = await DAITokenInstance.balanceOf(owner);
      const vendorDAIBalanceBefore = await DAITokenInstance.balanceOf(vendorInstance.address);

      await vendorInstance.buyTokensForDAI(web3.utils.toBN(3).mul(bn1e18));

      const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(vendorInstance.address);
      const tokenBalanceAfter = await testTokenInstance.balanceOf(owner);

      const DAIBalanceAfter = await DAITokenInstance.balanceOf(owner);
      const vendorDAIBalanceAfter = await DAITokenInstance.balanceOf(vendorInstance.address);

      assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
      assert.equal(
        true,
        tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))),
      );

      assert.notEqual(web3.utils.toBN(0), vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter));
      assert.equal(true, DAIBalanceBefore.eq(DAIBalanceAfter.sub(vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter))));
    });

    it('Should throw an error if amount < 0', async () => {
      await truffleAssert.reverts(
        vendorInstance.buyTokensForDAI(0),
        'Maybe you would like to buy something greater than 0?',
      );
    });

    it('Should throw an error if balance of DAI-token at msg.sender balance is too low', async () => {
      await truffleAssert.reverts(
        vendorInstance.buyTokensForDAI(web3.utils.toBN(100).mul(bn1e18)),
        'Sorry, you do not have enough DAI-tokens for swap',
      );
    });

    it('Should throw an error if balance of SGRN-token at Vendor contract is too low', async () => {
      await truffleAssert.reverts(
        vendorInstance.buyTokensForDAI(web3.utils.toBN(30).mul(bn1e18)),
        'Sorry, there is not enough tokens on my balance',
      );
    });

    it('Should throw an error if there is not enough allowance', async () => {
      await truffleAssert.reverts(
        vendorInstance.buyTokensForDAI(web3.utils.toBN(3).mul(bn1e18)),
        'Check the token allowance please',
      );
    });

    it("Should throw an error if msg.sender is not an owner of 'key NFT token'", async () => {
      await truffleAssert.reverts(
        vendorInstance.buyTokensForDAI(web3.utils.toBN(3), { from: payer }),
        "Sorry, you don't have a key to use this.",
      );
    });
  });

  describe('_PROXY_ Buy tokens with ETH', function () {
    it('Should buyTokens with ETH successfully', async () => {
      const tokenBalanceBefore = await testTokenInstance.balanceOf(owner);
      const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(proxyInstance.address);

      await myProxyInstance.methods.buyTokens().send({ from: owner, value: paymentAmount });

      const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(proxyInstance.address);
      const tokenBalanceAfter = await testTokenInstance.balanceOf(owner);

      assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
      assert.equal(
        true,
        tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))),
      );
    });

    it('Should get back ether if there is not enough Vendor token balance', async () => {
      const ethBalanceBefore = await web3.eth.getBalance(owner);
      const result = await myProxyInstance.methods
        .buyTokens()
        .send({ from: owner, value: paymentAmount.mul(web3.utils.toBN(1000)) });

      const ethBalanceAfter = await web3.eth.getBalance(owner);

      const transaction = await web3.eth.getTransaction(result.transactionHash);

      assert.equal(
        true,
        web3.utils
          .toBN(result.gasUsed)
          .mul(web3.utils.toBN(transaction.gasPrice))
          .eq(web3.utils.toBN(ethBalanceBefore).sub(web3.utils.toBN(ethBalanceAfter))),
      );
    });

    it("Should throw an error if msg.sender is not an owner of 'key NFT token'", async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.buyTokens().send({ from: payer, value: paymentAmount }),
        "Sorry, you don't have a key to use this.",
      );
    });
  });

  describe('_PROXY_ Buy tokens with DAI', function () {
    it('Should swap Tokens for DAI successfully', async () => {
      await testTokenInstance.transfer(proxyInstance.address, web3.utils.toBN(500).mul(bn1e18));
      await DAITokenInstance.approve(proxyInstance.address, web3.utils.toBN(50).mul(bn1e18));
      const tokenBalanceBefore = await testTokenInstance.balanceOf(owner);
      const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(proxyInstance.address);

      const DAIBalanceBefore = await DAITokenInstance.balanceOf(owner);
      const vendorDAIBalanceBefore = await DAITokenInstance.balanceOf(proxyInstance.address);

      await myProxyInstance.methods.buyTokensForDAI(web3.utils.toBN(3).mul(bn1e18));

      const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(proxyInstance.address);
      const tokenBalanceAfter = await testTokenInstance.balanceOf(owner);

      const DAIBalanceAfter = await DAITokenInstance.balanceOf(owner);
      const vendorDAIBalanceAfter = await DAITokenInstance.balanceOf(proxyInstance.address);

      assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
      assert.equal(
        true,
        tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))),
      );

      assert.notEqual(web3.utils.toBN(0), vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter));
      assert.equal(true, DAIBalanceBefore.eq(DAIBalanceAfter.sub(vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter))));
    });

    it('Should throw an error if amount < 0', async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.buyTokensForDAI(0).call(),
        'Maybe you would like to buy something greater than 0?',
      );
    });

    it('Should throw an error if balance of DAI-token at msg.sender balance is too low', async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.buyTokensForDAI(web3.utils.toBN(100).mul(bn1e18)).call(),
        'Sorry, you do not have enough DAI-tokens for swap',
      );
    });

    it('Should throw an error if balance of SGRN-token at Vendor contract is too low', async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.buyTokensForDAI(web3.utils.toBN(30).mul(bn1e18)).call(),
        'Sorry, there is not enough tokens on my balance',
      );
    });

    it('Should throw an error if there is not enough allowance', async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.buyTokensForDAI(web3.utils.toBN(3).mul(bn1e18)).call(),
        'Check the token allowance please',
      );
    });

    it("Should throw an error if msg.sender is not an owner of 'key NFT token'", async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.buyTokensForDAI(web3.utils.toBN(3)).call({ from: payer }),
        "Sorry, you don't have a key to use this.",
      );
    });

    it('Should allow to upgrade only for owner', async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.upgradeTo(vendorV2Instance.address).call({ from: payer }),
        'Ownable: caller is not the owner',
      );
    });
  });

  describe('Upgradeability test', function () {
    it('Should allow to upgrade only for owner', async () => {
      await truffleAssert.reverts(
        myProxyInstance.methods.upgradeTo(vendorV2Instance.address).call({ from: payer }),
        'Ownable: caller is not the owner',
      );
    });
  });
});
