// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiTransferV1 is Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    error NoAddressesSpecified();
    error NoAmountsSpecified();
    error ArrayLengthMismatch();
    error InsufficientEtherValue();
    error InsufficientTokenAllowance();
    error InsufficientTokenAmount();
    error TooManyAddresses();

    event Multisended(uint256 total, address tokenAddress);
    event MultisendTokenAndEther(
        uint256 totalToken,
        address tokenAddress,
        uint256 totalEther,
        address eAddress
    );

    receive() external payable {}

    fallback() external payable {}

    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) external payable whenNotPaused returns (bool) {
        if (_addresses.length <= 0) {
            revert NoAddressesSpecified();
        }
        if (_amounts.length <= 0) {
            revert NoAmountsSpecified();
        }
        if (_addresses.length != _amounts.length) {
            revert ArrayLengthMismatch();
        }
        uint256 value = msg.value;
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (value < _amounts[i]) {
                revert InsufficientEtherValue();
            }
            value -= _amounts[i];
            _addresses[i].transfer(_amounts[i]);
        }
        return true;
        // emit Multisended(msg.value, 0x000000000000000000000000000000000000bEEF);
    }

    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        uint256 _amountSum
    ) external whenNotPaused {
        if (_addresses.length <= 0) {
            revert NoAddressesSpecified();
        }
        if (_amounts.length <= 0) {
            revert NoAmountsSpecified();
        }
        if (_addresses.length != _amounts.length) {
            revert ArrayLengthMismatch();
        }

        IERC20 token = IERC20(_token);
        if (token.allowance(msg.sender, address(this)) < _amountSum) {
            revert InsufficientTokenAllowance();
        }
        token.safeTransferFrom(msg.sender, address(this), _amountSum);
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_amountSum < _amounts[i]) {
                revert InsufficientTokenAmount();
            }
            _amountSum -= _amounts[i];
            token.safeTransfer(_addresses[i], _amounts[i]);
        }
        // emit Multisended(_amountSum, address(token));
    }

    function multiTransferTokenEther(
        address _token,
        address payable[] calldata _addresses,
        uint256[] calldata _amounts,
        uint256 _amountSum,
        uint256[] calldata _amountsEther
    ) external payable whenNotPaused {
        if (_addresses.length <= 0) {
            revert NoAddressesSpecified();
        }
        if (_amounts.length <= 0) {
            revert NoAmountsSpecified();
        }
        if (_amountsEther.length <= 0) {
            revert NoAmountsSpecified();
        }
        if (_addresses.length != _amounts.length) {
            revert ArrayLengthMismatch();
        }
        if (_addresses.length != _amountsEther.length) {
            revert ArrayLengthMismatch();
        }
        if (_addresses.length > 255) {
            revert TooManyAddresses();
        }

        uint256 _value = msg.value;
        IERC20 token = IERC20(_token);

        token.safeTransferFrom(msg.sender, address(this), _amountSum);
        for (uint256 i = 0; i < _addresses.length; i++) {
            _amountSum -= _amounts[i];
            _value -= _amountsEther[i];

            token.safeTransfer(_addresses[i], _amounts[i]);
            _addresses[i].transfer(_amountsEther[i]);
        }
        // emit MultisendTokenAndEther(
        //     _amountSum,
        //     address(token),
        //     msg.value,
        //     0x000000000000000000000000000000000000bEEF
        // );
    }

    function emergencyStop() external onlyOwner {
        _pause();
    }

    function unPaused() external onlyOwner {
        _unpause();
    }
}
