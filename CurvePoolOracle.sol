// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ICurvePool.sol";
import "./ICurveLPToken.sol";
import "./Interfaces.sol";


contract CurvePoolOracle is BasePriceOracle {
  /**
   * @dev Maps Curve LP token addresses to pool addresses.
   */
  mapping(address => address) public poolOf;

  /**
   * @dev Maps Curve LP token addresses to underlying token addresses.
   */
  mapping(address => address[]) public underlyingTokens;

  /**
   * @dev Register the pool given LP token address and set the pool info.
   * Source: https://github.com/AlphaFinanceLab/homora-v2/blob/master/contracts/oracle/CurveOracle.sol
   * @param lpToken LP token to find the corresponding pool.
   */
  function registerCurvePool(address lpToken) external {
    address pool = poolOf[lpToken];

    require(pool == address(0), "LP Token is already registed");
    pool = ICurveLPToken(lpToken).minter();
    require(pool != address(0), "no curve pool found for this LP Token");

    poolOf[lpToken] = pool;
    for (uint256 i = 0; i < 8;) {
      try ICurvePool(pool).coins(i) returns(address _coin) {
        underlyingTokens[lpToken].push(_coin);
      } catch {
        break;
      }

      unchecked {
        i++;
      }
    }
  }

  function price(address lpToken) external view override returns (uint256) {
    return _price(lpToken);
  }

  function _price(address lpToken)
    internal
    view
    returns (uint256)
  {
    address pool = poolOf[lpToken];
    require(pool != address(0), "no registered pool found for lpToken");
    address[] memory _underlyingTokens = underlyingTokens[lpToken];
    uint256 minPx = type(uint256).max;
    uint256 n = _underlyingTokens.length;

    for (uint256 i = 0; i < n;) {
      address _underlyingToken = _underlyingTokens[i];
      uint256 tokenPx = BasePriceOracle(msg.sender).price(_underlyingToken);
      if (tokenPx < minPx) minPx = tokenPx;

      unchecked {
        i++;
      }
    }

    require(
      minPx != type(uint256).max,
      "No minimum underlying token price found."
    );

    return (minPx * ICurvePool(pool).get_virtual_price()) / 1e18;
  }
}