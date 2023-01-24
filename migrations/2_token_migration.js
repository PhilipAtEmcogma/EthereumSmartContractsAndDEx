//remeber to use the name of the contract "Wallet" not the name of the js file "wallet"
const Link = artifacts.require("Link");

module.exports = function(deployer){
    deployer.deploy(Link);
};