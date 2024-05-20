// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.6;

import '@donaswap/lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IDonaswapMigrator.sol';
import './interfaces/V1/IDonaswapV1Factory.sol';
import './interfaces/V1/IDonaswapV1Exchange.sol';
import './interfaces/IDonaswapRouter01.sol';
import './interfaces/IERC20.sol';

contract DonaswapMigrator is IDonaswapMigrator {
    IDonaswapV1Factory immutable factoryV1;
    IDonaswapRouter01 immutable router;

    constructor(address _factoryV1, address _router) public {
        factoryV1 = IDonaswapV1Factory(_factoryV1);
        router = IDonaswapRouter01(_router);
    }

    // needs to accept ETH from any v1 exchange and the router. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    receive() external payable {}

    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
        external
        override
    {
        IDonaswapV1Exchange exchangeV1 = IDonaswapV1Exchange(factoryV1.getExchange(token));
        uint liquidityV1 = exchangeV1.balanceOf(msg.sender);
        require(exchangeV1.transferFrom(msg.sender, address(this), liquidityV1), 'TRANSFER_FROM_FAILED');
        (uint amountETHV1, uint amountTokenV1) = exchangeV1.removeLiquidity(liquidityV1, 1, 1, uint(-1));
        TransferHelper.safeApprove(token, address(router), amountTokenV1);
        (uint amountToken, uint amountETH,) = router.addLiquidityETH{value: amountETHV1}(
            token,
            amountTokenV1,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
        if (amountTokenV1 > amountToken) {
            TransferHelper.safeApprove(token, address(router), 0); // be a good blockchain citizen, reset allowance to 0
            TransferHelper.safeTransfer(token, msg.sender, amountTokenV1 - amountToken);
        } else if (amountETHV1 > amountETH) {
            // addLiquidityETH guarantees that all of amountETHV1 or amountTokenV1 will be used, hence this else is safe
            TransferHelper.safeTransferETH(msg.sender, amountETHV1 - amountETH);
        }
    }
}
