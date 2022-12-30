# Uniswap flashloan example

The contract allows to make 3 swaps in cycling way ```wETH -> LINK -> DAI -> wETH```. It uses ```getAmountsOut``` method from [UniswapV2Library.sol](https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol) (which makes us use 0.6.6 compiler version) to define ```amountOut``` for [swap](https://docs.uniswap.org/contracts/v2/reference/smart-contracts/pair#swap-1) method in each swap and pays fee.

## Building and running:
Preliminary add your ```ALCHEMY_KEY``` to environment variables.
```
npm i
npx hardhat test
```

## Logging output
```
  Flashloan
     Exchanged 70000 WETH for 15187714 LINK
     Exchanged 15187714 LINK for 82579360 DAI
     Exchanged 82579360 DAI for 69484 WETH
     You lost 516 WETH
```
