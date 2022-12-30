const { ethers } = require('hardhat');
const { expect } = require("chai");
const { BigNumber } = require('ethers');
const UniswapV2FactoryAbi = require('@uniswap/v2-core/build/IUniswapV2Factory.json');
const UniswapV2PairAbi = require('@uniswap/v2-core/build/IUniswapV2Pair.json');
const uniswapV2FactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';

describe("Flashloan", function () {
  const totalAmount = BigNumber.from(10).pow(5);
  const amount = BigNumber.from(10).pow(4).mul(7);
  const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

  it("Flash swapped", async function () {
    const UniswapFlashloanCycleSwap = await ethers.getContractFactory('FlashloanCyclicalSwap');
    const uniswapFlashloanCycleSwap = await UniswapFlashloanCycleSwap.deploy();

    const token = await ethers.getContractAt('IERC20', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48');

    await token.transfer(uniswapFlashloanCycleSwap.address, totalAmount);

    const uniswapFactory = await ethers.getContractAt(UniswapV2FactoryAbi.abi, uniswapV2FactoryAddress);
    const pairForFlashloan = await uniswapFactory.getPair(token.address, WETH);
    const pairContract = await ethers.getContractAt(UniswapV2PairAbi.abi, pairForFlashloan);

    const data = ethers.utils.defaultAbiCoder.encode(['address'], [token.address]);
    
    const tx = await uniswapFlashloanCycleSwap.runFlashSwap(token.address, amount)

    const receipt = await tx.wait();
    const events = receipt.events?.filter((x) => {return x.event == 'CyclicalSwap'}).map((x) => {
      return x.args;
    })
    const wethStart = events[0][1]
    const wethEnd = events[events.length - 1][3]
    events.forEach((x) => {
      console.log("     Exchanged %s %s for %s %s", x[1], x[0], x[3], x[2]);
    });
    if (wethStart > wethEnd) {
      console.log("     You lost %s WETH", wethStart - wethEnd);
    } else {
      console.log("     You earned %s WETH", wethEnd - wethStart);
    }

    const weth = await ethers.getContractAt("IERC20", WETH);
    let wethBalance = await weth.balanceOf(uniswapFlashloanCycleSwap.address);
    expect(amount >= wethBalance);
  });
});
