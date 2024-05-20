// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IDonaswapMigrator {
    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external;
}
