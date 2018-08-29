var Wiji = artifacts.require("./wiji_token.sol");
var Wiji_ICO = artifacts.require("./wiji_sale.sol");
var wiji_instance;

module.exports = function(deployer)
{
  deployer.deploy(Wiji).then(function()
  {
    return Wiji.deployed();
  }).then(function(instance)
  {
    wiji_instance = instance;
    return deployer.deploy(Wiji_ICO, Wiji.address);
  }).then(function()
  {
    return Wiji_ICO.deployed().then(function()
    {
      wiji_instance.set_ico_address(Wiji_ICO.address);
    });
  });
};
