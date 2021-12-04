const truffleAssert = require('truffle-assertions');
import { assert, web3, artifacts } from "hardhat";

const Vendor = artifacts.require("Vendor");
const TestToken = artifacts.require("TestToken");

const bn1e18 = web3.utils.toBN(1e18);

describe("Vendor", () => {
    let accounts: string[];
    let owner: any;
    let payer: any;
    let testTokenInstance: any;
    let vendorInstance: any;
    const DAIContractAddress: string = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
    const DaiABI: any = [{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"}, {"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}];
    let DAIContractInstance: any;
    const paymentAmount = bn1e18.muln(1);

    beforeEach(async function () {
        accounts = await web3.eth.getAccounts();
        owner = accounts[0];
        payer = accounts[1];

        await web3.eth.sendTransaction({from:accounts[9],to:payer, value:paymentAmount.mul(web3.utils.toBN(99))})
        console.log('scv_01');
        testTokenInstance = await TestToken.new(10000);
        console.log('scv_02');
        vendorInstance = await Vendor.new(testTokenInstance.address);
        console.log('scv_03');
        await testTokenInstance.transfer(vendorInstance.address, web3.utils.toBN(1).mul(bn1e18));
        console.log('scv_04');
        DAIContractInstance = await new web3.eth.Contract(DaiABI, DAIContractAddress);
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


            const amount = await vendorInstance._tokensAmountToBuy();
            const price = await vendorInstance._tokenPrice();

            // console.log('scv_amount_price', amount.toNumber(), price.toNumber())

            console.log('scv_transaction', transaction);
            console.log('scv_balanceBefore', ethBalanceBefore)
            console.log('scv_balanceAfter', ethBalanceAfter)

            console.log('scv_are_they_equal?', web3.utils.toBN(result.receipt.gasUsed).mul(web3.utils.toBN(transaction.gasPrice)).eq(web3.utils.toBN(ethBalanceBefore).sub(web3.utils.toBN(ethBalanceAfter))))
            assert.equal(true, web3.utils.toBN(result.receipt.gasUsed).mul(web3.utils.toBN(transaction.gasPrice)).eq(web3.utils.toBN(ethBalanceBefore).sub(web3.utils.toBN(ethBalanceAfter))));
        });

        // it("Should not be able to buy tokens due to 0 eth sent", async () => {
        //     await truffleAssert.reverts(
        //         vendorInstance.buyTokens({from: payer, value: 0}),
        //         "Send ETH to buy some tokens"
        //     );
        // });
        //
        // it("Should not be able to call adminFeature due to not time yet", async () => {
        //     await truffleAssert.reverts(
        //         vendorInstance.adminFeature(),
        //         "You will not pass!!!"
        //     );
        // });
        //
        // it("Should  be able to call adminFeature successfully", async () => {
        //     await increaseTime(web3, 604801);
        //     const result = await vendorInstance.adminFeature();
        //
        //     truffleAssert.eventEmitted(result, 'Success', (ev: any) => {
        //         return ev.owner.toLowerCase() === owner.toLowerCase();
        //     });
        // });

    });

    describe('BuyTokensForDAI', function(){
        it("Should throw an error if balance of DAI at Vendor contract is too low", async () => {
            await truffleAssert.reverts(
                vendorInstance.buyTokensForDAI(0),
                "Maybe you would like to buy something greater than 0?"
            );
        });

        it("Should throw an error if amount < 0", async () => {
            await truffleAssert.reverts(
                    vendorInstance.buyTokensForDAI(0),
                    "Maybe you would like to buy something greater than 0?"
                );
            });
        });

        // it("Should swap Tokens for DAI successfully", async () => {
        //     const DAIContract = await new web3.eth.Contract(DaiABI, DAIContractAddress);
        //
        //     const tokenBalanceBefore = await testTokenInstance.balanceOf(payer);
        //     const vendorTokenBalanceBefore = await testTokenInstance.balanceOf(vendorInstance.address);
        //
        //     const DAIBalanceBefore = await DAIContractInstance.methods.balanceOf(payer);
        //     const vendorDAIBalanceBefore = await DAIContractInstance.methods.balanceOf(vendorInstance.address);
        //
        //     const result = await vendorInstance.buyTokensForDAI(web3.utils.toBN(17).mul(bn1e18));
        //
        //     // truffleAssert.eventEmitted(result, 'Bought', (ev: any) => {
        //     //     return ev.payer.toLowerCase() === payer.toLowerCase() && ev.value.eq(web3.utils.toBN("1000000000000000000"));
        //     // });
        //
        //     const vendorTokenBalanceAfter = await testTokenInstance.balanceOf(vendorInstance.address);
        //     const tokenBalanceAfter = await testTokenInstance.balanceOf(payer);
        //
        //     const DAIBalanceAfter = await DAIContractInstance.methods.balanceOf(payer);
        //     const vendorDAIBalanceAfter = await DAIContractInstance.methods.balanceOf(vendorInstance.address);
        //
        //     assert.notEqual(web3.utils.toBN(0), vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter));
        //     assert.equal(true, tokenBalanceBefore.eq(tokenBalanceAfter.sub(vendorTokenBalanceBefore.sub(vendorTokenBalanceAfter))));
        //
        //     assert.notEqual(web3.utils.toBN(0), vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter));
        //     assert.equal(true, DAIBalanceBefore.eq(DAIBalanceAfter.sub(vendorDAIBalanceBefore.sub(vendorDAIBalanceAfter))));
        // });



});



