// ++++++++++++++++ Define Contracts ++++++++++++++++ 

const openOraclePriceData = artifacts.require("OpenOraclePriceData");
const uniswapAnchoredView = artifacts.require("UniswapAnchoredView");

// ++++++++++++++++  Main Migration ++++++++++++++++ 

const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployToken(deployer, network, accounts),
  ]);
};

module.exports = migration;

// ++++++++++++++++  Deploy Functions ++++++++++++++++ 
async function deployToken(deployer, network, accounts) {
  let deploy_account = accounts[0];
  let gas_price = 1000000000;

  await deployer.deploy(openOraclePriceData);
  let oracleDataAddress = openOraclePriceData.address;

  let priceReporter = "0x0346d0d8e8Df04Cf5f6e674FA0B23fb52FE1d6ab"; // address
  let anchorToleranceMantissa = web3.utils.toBN(20 ** 16).toString();
  let anchorPeriod = 1800;
  let configs = tokenConfig(); // TokenConfig[]
  await deployer.deploy(uniswapAnchoredView, oracleDataAddress, priceReporter, anchorToleranceMantissa, anchorPeriod, configs);

  // setReporter
  let contract_data = new web3.eth.Contract(openOraclePriceData.abi, oracleDataAddress);
  await Promise.all([
    contract_data.methods.setReporter(uniswapAnchoredView.address).send({ from: deploy_account, gasPrice: gas_price, gas: 100000}, function(err, txId) {
      if (err != null) {
        console.log("_setMarketBorrowCaps error: " + err);
      }
      console.log("_setMarketBorrowCaps txid: "+txId);
    }),

  ]);

}

function tokenConfig() {
  // address gToken;
  // address underlying;
  // bytes32 symbolHash;
  // uint256 baseUnit;
  // PriceSource priceSource;
  // uint256 fixedPrice;
  // address uniswapMarket;
  // bool isUniswapReversed;
  return [
    [
      "0x096F5e3256045C5d000486062360292DB0476D79",
      "0x0000000000000000000000000000000000000000",
      "0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4",
      "1000000000000000000",2,0,"0x69C601e4Ac1C8377Bb9981c5c438BAC1a3176B50",true
    ],
    [
      "0x21636d81864809a335ABE1618De54768cc2142B9",
      "0x1E122Cc141f9Cd659A9BB6931fafECCA98E12C5a",
      "0x8b1a1d9c2b109e527c9134b25b1a1833b16b6594f92daa9f6d9b7a6024bce9d0",
      "1000000",1,1000000,"0x0000000000000000000000000000000000000000",false
    ],
    [
      "0xDac781B50F9F61BD1c0E0eE2c547F083D5FA7e7d",
      "0xB835f29cCA30e6AE66125a2e0c03E75665be6aee",
      "0xa5e92f3efb6826155f1f728e162af9d7cda33a574a1153b58f03ea01cc37e568",
      "1000000000000000000",2,0,"0xEEFe56A1fAaEc608fb4945d06FC56D945612E5E4",true
    ]
  ];
}