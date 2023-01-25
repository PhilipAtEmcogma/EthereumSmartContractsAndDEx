//remeber to use the name of the contract "Wallet" not the name of the js file "wallet"
const Link = artifacts.require("Link");
const Dex = artifacts.require("Dex");

//remeber in order to use "await", the function need to be async
module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(Link);
};