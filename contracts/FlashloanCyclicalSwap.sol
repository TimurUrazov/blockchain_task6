// // SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

contract FlashloanCyclicalSwap is IUniswapV2Callee {
    event CyclicalSwap(
        string from,
        uint amountIn,
        string to,
        uint amountOut
    );

    modifier onlyWeth(uint amount0, uint amount1, address pair) {
        require(amount0 == 0 || amount1 == 0, "At least one amount must be zero.");
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(token0 == WETH || token1 == WETH, "At least one token must be wETH.");
        _;
    }

    address private constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_FACTORY);

    function singleSwap(address from, address to, uint amountFrom, uint amountOut, string memory tokenFrom, string memory tokenTo) private {
        address pair = factory.getPair(from, to);

        IUniswapV2Pair uniswapPair = IUniswapV2Pair(pair);
        (uint amount0, uint amount1) = uniswapPair.token0() == from ? (uint(0), amountOut) : (amountOut, uint(0));

        IERC20(from).transfer(pair, amountFrom);
        uniswapPair.swap(amount0, amount1, address(this), new bytes(0));

        emit CyclicalSwap(
            tokenFrom,
            amountFrom, 
            tokenTo, 
            amountOut
        );
    }

    function runFlashSwap(address borrower, uint amount) external {
        IUniswapV2Pair(factory.getPair(borrower, WETH)).swap(0, amount, address(this), abi.encode(borrower));
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external override onlyWeth(amount0, amount1, msg.sender) {
        address pair = factory.getPair(
            IUniswapV2Pair(msg.sender).token0(), 
            IUniswapV2Pair(msg.sender).token1()
        );
        address[] memory path = new address[](4);
        path[0] = WETH;
        path[1] = LINK;
        path[2] = DAI;
        path[3] = path[0];
        string[4] memory names = ["WETH", "LINK", "DAI", "WETH"];
        uint amount = amount0 + amount1;
        uint[] memory amounts = UniswapV2Library.getAmountsOut(UNISWAP_FACTORY, amount, path);

        for (uint8 i = 0; i + 1 < path.length; i++) {
            address from = path[i];
            address to = path[i + 1];
            singleSwap(from, to, amounts[i], amounts[i + 1], names[i], names[i + 1]);
        }

        IERC20(abi.decode(data, (address))).transfer(pair, amount * 1000 / 997 + 1);
    }
}
