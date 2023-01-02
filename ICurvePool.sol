// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface ICurvePool {
  function get_virtual_price() external view returns (uint256);

  function coins(uint256 i) external view returns (address);

  function remove_liquidity_one_coin(
    uint256 tokenAmt,
    int128 idx,
    uint256 minAmt
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 tokenAmt,
    int128 idx,
    uint256 minAmt,
    bool useUnderlying
  ) external returns (uint256);
}