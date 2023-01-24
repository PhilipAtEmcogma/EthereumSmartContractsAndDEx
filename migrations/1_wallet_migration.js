//remeber to use the name of the contract "Wallet" not the name of the js file "wallet"
const Wallet = artifacts.require("Wallet");

module.exports = function(deployer){
    deployer.deploy(Wallet);
};