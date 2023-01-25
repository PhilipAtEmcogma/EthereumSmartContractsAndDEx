//remeber to use the name of the contract "Wallet" not the name of the js file "wallet"
const Dex = artifacts.require("Dex");

module.exports = function(deployer){
    deployer.deploy(Dex);
};