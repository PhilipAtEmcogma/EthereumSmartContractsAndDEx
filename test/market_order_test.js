const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require('truffle-assertions');

contract("Dex", accounts =>{
    //Seller must have enough tokens for the trade, when creating a SELL market order
    it("Should throw an error when creating a SELL market order without adequate token balance", async() =>{
        let dex = await Dex.deployed();

        let balance = await dex.balance(accounts[0], web3.utils.fromUtf8("LINK"));
        //use assert to test if balance equals to 0, if true no point of futher testing
        assert.equal(balance.toNumber(), 0, "Initial LINK balance is not 0");
        //try to create market order to SELL 10 LINK
        await truffleAssert.reverts(
            dex.createMarketOrder(1, web3.utils.fromUtf8("LINK"), 10)
        )
    })

    //Buyer must have enough ETH for the trade, when creating a BUY market order
    it("Should throw an error when creating a BUY market order without adequate ETH balance", async() =>{
        let dex = await Dex.deployed();

        let balance = await dex.balance(accounts[0], web3.utils.fromUtf8("ETH"));
        //use assert to test if balance equals to 0, if true no point of futher testing
        assert.equal(balance.toNumber(), 0, "Initial ETH balance is not 0");

        //try to create market order to BUY 10 LINK
        await truffleAssert.reverts(
            dex.createMarketOrder(0, web3.utils.fromUtf8("LINK"), 10)
        )
    })

    //Market orders can be submitted even if the order book is empty
    if("Market orders can be submitted even if the order book is empty", async () =>{
        let dex = await Dex.deployed()

        await dex.depositEth({value: 10000}); //deposit some ETH (10k gwei) to buy some tokens

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 0) //get buy side orderbook
        assert(orderbook.length == 0, "Buy side Orderbook length is not 0");

        //the actual market BUY order and make sure it passes
        await truffleAssert.passes(
            dex.createMarketOrder(0, web3.utils.fromUtf8("LINK",10))
        )
    })

    //Market order should be filled until the order book is empty or the market order is 100% filled
    it("Market orders should not fill more limit orders than the market order amount", async() =>{
        let dex = await Dex.deployed();
        let link = await Link.deployed();

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1) //get sell side orderbook
        //to make sure orderbook is empty at first
        assert(orderbook.length == 0, "Sell side Orderbook should be empty at start of test");

        //to make sure to add the LINK token to the contract, so LINK can be deposited
        await dex.addToken(web3.utils.fromUtf8("LINK"), link.address);

        //Send LINK tokens to accounts 1,2,3 from account 0
        //.transfer() are transfer from account[0] by default, so no need to specify
        await link.transfer(accounts[1], 50);
        await link.transfer(accounts[2], 50);
        await link.transfer(accounts[3], 50);

        //Approve DEx for accounts 1,2,3
        //good to use up to 50 LINK
        await link.approve(dex.address, 50, {from: accounts[1]});
        await link.approve(dex.address, 50, {from: accounts[2]});
        await link.approve(dex.address, 50, {from: accounts[3]});

        //Deposit LINK into DEx for account accounts 1,2,3
        await link.deposit(50, web3.utils.fromUtf8("LINK"), {from: accounts[1]});
        await link.deposit(50, web3.utils.fromUtf8("LINK"), {from: accounts[2]});
        await link.deposit(50, web3.utils.fromUtf8("LINK"), {from: accounts[3]});

        //Fill up the sell order book
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5, 300, {from: accounts[1]});
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5, 400, {from: accounts[2]});
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5, 500, {from: accounts[3]});

        //create marker order that should fill 2/3 orders in the book (i.e. 10/15 of the avaliable LINK in the orderbook) 
        await dex.createMarketOrder(0, web3.utils.fromUtf8("LINK"), 10);

        orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1); //get sell side orderbook
        assert(orderbook.length == 1, "Sell side Orderbook should only have 1 order left");
        assert(orderbook[0].filled == 0, "Sell side order should have 0 filled");
    })

    //Market orders should be filled until the order book is empth or the market order is 100% filled
    it("Market orders should be filled until the order book is empty", async () =>{
        let dex = await Dex.deployed();

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1) //Get sell side order
        assert(orderbook.length == 1, "Sell side Orderbook should have 1 order left");

        //Fill up the sell order book again
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5, 400, {from: accounts[1]});
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5, 500, {from: accounts[2]});

        //check buyer LINK balance before LINK purchase
        let balanceBefore = await dex.balance(accounts[0], web3.utils.fromUtf8("LINK"));

        //create market order that could fill more than the entire order book (15 LINK avaliable, but want 50 LINK)
        //thus only 15 out of 50 are filled, and 35 more are pending
        await dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 50);

        //check buyer link balance after LINK purchase
        let balanceAfter = await dex.balance(accounts[0], web3.utils.fromUtf8("LINK"));

        //check Buyer should have 15 more link after, even though order was for 50
        assert.equal(balanceBefore + 15, balanceAfter);
    })

    //the Eth balance of the buy should decrease with the filled amount
    it("The Eth balance of the buyer should decrease with the filled amount", async() =>{
        let dex = await Dex.deployed();
        let link = await Link.deployed();

        //Seller deposits link and creates a sell limit order for 1 link to 300 wei
        await link.approve(dex.address, 500, {from: accounts[1]});
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 1, 300, {from: accounts[1]});

        //check buyer Eth balances before trade
        let balanceBefore = await dex.balance(accounts[0], web3.utils.fromUtf8("ETH"));
        await dex.createMarketOrder(0, web3.utils.fromUtf8("LINK"), 1); //traded 1 link
        let balanceAfter = await dex.balance(accounts[0], web3.utils.fromUtf8("ETH"));

        assert.equal(balanceBefore - 300, balanceAfter);
    })

    //The token balances of the limit order sellers should decrease with the filled amounts.
    it("The token balances of the limit order sellers should decrease with the filled amounts.", async() => {
        let dex = await Dex.deployed();
        let link = await Link.deployed();

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1); //get SELL side orderbook
        assert(orderbook.length == 0, "Sell side Orderbook should be empty at start of test");

        //Seller account[1] already have approved and deposited LINK from previous test

        //Seller account[2] deposits LINK
        await link.approve(dex.address, 500, {from: accounts[2]});
        await dex.deposit(100, web3.utils.fromUtf8("LINK"), {from: accounts[2]});

        //creat 2 limit sell orders, one from account 1 and one from account 2
        //both orders sells 1 LINK but at different price (300 and 400 gwei respectively)
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 1, 300, {from: accounts[1]});
        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 1, 400, {from: accounts[2]});
        
        //check sellers LINK balance before trade
        let account1BalanceBefore = await dex.balances(accounts[1], web3.utils.fromUtf8("LINK"));
        let account2BalanceBefore = await dex.balances(accounts[2], web3.utils.fromUtf8("LINK"));

        //Account[0] created market order to buy up both sell orders
        await dex.createMarketOrder(0, web3.utils.fromUtf8("LINK"), 2);

        //check sellers LINK balances after trade
        let account1BalanceAfter = await dex.balances(accounts[1], web3.utils.fromUtf8("LINK"));
        let account2BalanceAfter = await dex.balances(accounts[2], web3.utils.fromUtf8("LINK"));

        assert.equal(account1BalanceBefore - 1, account1BalanceAfter);
        assert.equal(account2BalanceBefore - 1, account2BalanceAfter);
    })

    //Filled limit orders should be removed from the orderbook
    it("Filled limit orders should be removed from the orderbook", async() => {
        let dex = await Dex.deployed();

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1);
        assert(orderbook.length == 0, "Sell side Orderbook should be empty at start of test");

        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 1 , 300, {from: accounts[1]});
        await dex.createMarketOrder(0, web3.utils.fromUtf8("LINK"), 1);

        orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1); //get sell side orderbook
        assert(orderbook.length == 0, "Sell side Orderbook should be empty after trade");
    })

    //Partly filled limit orders should be modified to represent the filled/remaining amount
    it("Limit orders filled property should be set correctly after a trade", async() => {
        let dex = await Dex.deployed();

        let orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1);
        assert(orderbook.length == 0, "Sell side Orderbook should be empty at start of test");

        await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5, 300, {from: accounts[1]});
        await dex.createMarketOrder(0, web3.utils.fromUtf8("LINK"), 2);

        orderbook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1); //get sell side orderbook
        assert.equal(orderbook[0].filled, 2);
        assert.equal(orderbook[0].amount, 5);
    })
})