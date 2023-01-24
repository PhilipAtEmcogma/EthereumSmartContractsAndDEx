//remeber to use the name of the contract "Wallet" not the name of the js file "wallet"
const Link = artifacts.require("Link");
const Wallet = artifacts.require("Wallet");

//remeber in order to use "await", the function need to be async
module.exports = async function(deployer, network, accounts){
    await deployer.deploy(Link);

    let wallet = await Wallet.deployed();
    let link = await Link.deployed();

    await link.approve(wallet.address, 500); //assigning 500 tokens to wallet as quota to use
    wallet.addToken(web3.utils.fromUtf8("LINK"), link.address);
    //fromUtf8 takes string input and returns its UTF-8 encoded version as bytes
    await wallet.deposit(100, web3.utils.fromUtf8("LINK"));

    let balanceOfLink = await wallet.balances(accounts[0], web3.utils.fromUtf8("LINK"));
    console.log(balanceOfLink);
};