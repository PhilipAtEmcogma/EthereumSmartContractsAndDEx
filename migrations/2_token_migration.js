//remeber to use the name of the contract "Wallet" not the name of the js file "wallet"
const Link = artifacts.require("Link");
const Dex = artifacts.require("Dex");

//remeber in order to use "await", the function need to be async
module.exports = async function(deployer, network, accounts){
    await deployer.deploy(Link);

    let dex = await Dex.deployed();
    let link = await Link.deployed();

    await link.approve(dex.address, 500); //assigning 500 tokens to wallet as quota to use
    dex.addToken(web3.utils.fromUtf8("LINK"), link.address);
    //fromUtf8 takes string input and returns its UTF-8 encoded version as bytes
    await dex.deposit(100, web3.utils.fromUtf8("LINK"));

    let balanceOfLink = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"));
    console.log(balanceOfLink);
};