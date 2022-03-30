
const main = async () => {
  
  const NonFungibleToken = await hre.ethers.getContractFactory("NonFungibleToken");
  let nonFungibleToken = await NonFungibleToken.deploy("NFTA", "NTA", "URI_ERCA");
  await nonFungibleToken.deployed();
  let NFT_address = nonFungibleToken.address; 
  console.log("Contract NFT_address:",NFT_address );

  const NFT_Market = await hre.ethers.getContractFactory("NFT_Market");
  let nft_Market = await NFT_Market.deploy(NFT_address, 10000, 10,50);
  await nft_Market.deployed();
  let NFT_MarketAddress = nft_Market.address; 
  console.log("Contract NFT_MarketAddress:",NFT_MarketAddress );

  await nonFungibleToken.grantRole("0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6", NFT_MarketAddress);
  await nonFungibleToken.toggleMinting(true);
  const gasLimit = ethers.utils.hexValue(1600000)
  const gasPrice =   (await ethers.getDefaultProvider().getGasPrice() ) || ethers.utils.hexValue(16000000)
  console.log('gasPrice',gasPrice.toString())
  let nbToMint=10
  let parameter = {
    value: 10*nbToMint,
    gasLimit: gasLimit,
      gasPrice: gasPrice
  }
  
  const rsp = await nft_Market.mint(nbToMint, parameter); console.log('nft_Market_mint', rsp);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
