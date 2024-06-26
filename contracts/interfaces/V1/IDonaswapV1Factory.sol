// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IDonaswapV1Factory {
    function getExchange(address) external view returns (address);
}
