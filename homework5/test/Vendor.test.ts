const truffleAssert = require('truffle-assertions');
import { assert, web3, artifacts } from "hardhat";

const Vendor = artifacts.require("Vendor");
const TestToken = artifacts.require("TestToken");
const DAIMockToken = artifacts.require("DAIToken");

const bn1e18 = web3.utils.toBN(1e18);

describe("Vendor", () => {
    let accounts: string[];
    let owner: any;
    let payer: any;
    let testTokenInstance: any;
    let vendorInstance: any;
    // const DAIContractAddress: string = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
    const DaiABI: any = [{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}, {"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}];
    let DAITokenInstance: any;
    const paymentAmount = bn1e18.muln(1);

    beforeEach(async function () {
        accounts = await web3.eth.getAccounts();
        owner = accounts[0];
        payer = accounts[1];

        testTokenInstance = await TestToken.new(10000);
        DAITokenInstance = await DAIMockToken.new(50);
        vendorInstance = await Vendor.new(testTokenInstance.address, DAITokenInstance.address);

        await DAITokenInstance.transfer(vendorInstance.address, web3.utils.toBN(5).mul(bn1e18));
        await testTokenInstance.transfer(vendorInstance.address, web3.utils.toBN(5).mul(bn1e18));
    });

    describe( "buyTokens", function() {
        it("Should buyTokens successfully", async () => {
            const tokenBalanceBefore = await testTokenInstance.balanceOf(payer);
            const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(vendorInstance.address);

            const result = await vendorInstance.buyTokens({from: payer, value: paymentAmount});

            // truffleAssert.eventEmitted(result, 'Bought', (ev: any) => {
            //     return ev.payer.toLowerCase() === payer.toLowerCase() && ev.value.eq(web3.utils.toBN("1000000000000000000"));
            // });

            const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(vendorInstance.address);
            const tokenBalanceAfter = await testTokenInstance.balanceOf(payer);

            assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
            assert.equal(true, tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))));
        });

        it("Should get back ether if there is not enough Vendor token balance", async () => {
            const ethBalanceBefore = await web3.eth.getBalance(payer);
            const result = await vendorInstance.buyTokens({from: payer, value: paymentAmount.mul(web3.utils.toBN(1000))});
            const ethBalanceAfter = await web3.eth.getBalance(payer);
            const transaction = await web3.eth.getTransaction(result.tx);

            assert.equal(true, web3.utils.toBN(result.receipt.gasUsed).mul(web3.utils.toBN(transaction.gasPrice)).eq(web3.utils.toBN(ethBalanceBefore).sub(web3.utils.toBN(ethBalanceAfter))));
        });
    });

    describe('BuyTokensForDAI', function(){
        it("Should throw an error if amount < 0", async () => {
            await truffleAssert.reverts(
                    vendorInstance.buyTokensForDAI(0),
                    "Maybe you would like to buy something greater than 0?"
                );
            });
        });

    it("Should throw an error if balance of DAI-token at msg.sender balance is too low", async () => {
        await truffleAssert.reverts(
            vendorInstance.buyTokensForDAI(web3.utils.toBN(100).mul(bn1e18)),
            "Sorry, you do not have enough DAI-tokens for swap"
        );
    });

    it("Should throw an error if balance of SGRN-token at Vendor contract is too low", async () => {
        await truffleAssert.reverts(
            vendorInstance.buyTokensForDAI(web3.utils.toBN(30).mul(bn1e18)),
            "Sorry, there is not enough tokens on my balance"
        );
    });





        it("Should swap Tokens for DAI successfully", async () => {
            await testTokenInstance.transfer(vendorInstance.address, web3.utils.toBN(500).mul(bn1e18));
            await DAITokenInstance.approve(vendorInstance.address,web3.utils.toBN(50).mul(bn1e18));
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
            assert.equal(true, tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))));

            assert.notEqual(web3.utils.toBN(0), vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter));
            assert.equal(true, DAIBalanceBefore.eq(DAIBalanceAfter.sub(vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter))));
        });

    // it("Should revert if amount is 0", async () => {
    //     await testTokenInstance.transfer(vendorInstance.address, web3.utils.toBN(500).mul(bn1e18));
    //     // await DAITokenInstance.approve(vendorInstance.address,web3.utils.toBN(500).mul(bn1e18) )
    //     // const tokenBalanceBefore = await testTokenInstance.balanceOf(owner);
    //     // const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(vendorInstance.address);
    //     //
    //     // const DAIBalanceBefore = await DAITokenInstance.balanceOf(owner);
    //     // const vendorDAIBalanceBefore = await DAITokenInstance.balanceOf(vendorInstance.address);
    //
    //     await truffleAssert.reverts(
    //         vendorInstance.buyTokensForDAI(0),
    //         "Maybe you would like to buy something greater than 0?"
    //     );
    //
    //     await vendorInstance.buyTokensForDAI(web3.utils.toBN(17).mul(bn1e18));
    //
    //     // const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(vendorInstance.address);
    //     // const tokenBalanceAfter = await testTokenInstance.balanceOf(owner);
    //     //
    //     // const DAIBalanceAfter = await DAITokenInstance.balanceOf(owner);
    //     // const vendorDAIBalanceAfter = await DAITokenInstance.balanceOf(vendorInstance.address);
    //     //
    //     // assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
    //     // assert.equal(true, tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))));
    //     //
    //     // assert.notEqual(web3.utils.toBN(0), vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter));
    //     // assert.equal(true, DAIBalanceBefore.eq(DAIBalanceAfter.sub(vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter))));
    // });



});



