const Coinflip = artifacts.require("Coinflip");
//const truffleAssert = require("truffle-assertions");

contract("Coinflip", async function (accounts) {
    
    let instance;
    let contractBalance;
    let playerBalance;    

    before(async function(){
        instance = await Coinflip.deployed()
    });

    describe('deposit and withdraw', async () => {
        

        it("should be able to deposit funds to contract", async function () {
            await instance.depositToContract({value: web3.utils.toWei("600", "finney"), from: accounts[0]})
            contractBalance = await web3.eth.getBalance(instance.address);
            assert(contractBalance === web3.utils.toWei("600", "finney"), "Balance is not deposit properly");
        });

        it("should be able to deposit funds to player amount", async function () {
            await instance.depositToPlayer({value: web3.utils.toWei("600", "finney"), from: accounts[1]})
            playerBalance = await instance.playerBalance(accounts[1]);
            console.log("playerBalance: " + playerBalance.toString() + " ||| 600 Finney: " + web3.utils.toWei("600", "finney"));
            assert(playerBalance == web3.utils.toWei("600", "finney"), "Balance is not deposit properly");
        });

    });
});