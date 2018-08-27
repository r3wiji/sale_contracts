var Wiji = artifacts.require("./wiji_token.sol");

module.exports = function(deployer)
{
  deployer.deploy(Wiji);
};
