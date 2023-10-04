// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title 'MultiTransfer'
/// @author Katy Nozari
/// @notice You can use this contract for sending ETH/ERC20 Tokens to
///  multiple addresses.
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.

contract MultiTransferV2 is Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev These errors are custom error types that can be used to throw exceptions or revert transactions with specific error messages when certain conditions are not met in the contract.

    error NoAddressesSpecified();
    error NoAmountsSpecified();
    error ArrayLengthMismatch();
    error InsufficientEtherValue();
    error InsufficientTokenAllowance();
    error InsufficientTokenAmount();
    error TooManyAddresses();

    address private immutable i_owner;

    /// @dev events are a way to log and record specific occurrences or activities that happen within a smart contract

    event Multisended(
        address indexed _from,
        uint256 indexed total,
        address tokenAddress
    );
    event MultisendTokenAndEther(
        uint256 totalToken,
        address tokenAddress,
        uint256 totalEther,
        address eAddress
    );
    event ClaimedTokens(address token, address owner, uint256 balance);

    constructor() {
        i_owner = msg.sender;
    }

    /**
     * @dev receive is a special function introduced in Solidity version 0.6.0 and later.
     *  It is executed when the contract receives Ether without any specific function call or data attached to the transaction.
     */
    receive() external payable {}

    /**
     * @dev fallback is another special function in Solidity that serves as a catch-all for handling transactions
     * when no other function matches the provided function signature or when no data is included in the transaction.
     */
    fallback() external payable {}

    /**
     * @notice Sending ETH to multiple addresses. Returns a boolean value (true or false) when it is called.
     * @dev This function sends ETH to multiple addresses using two arrays which
     * includes the address and the amount.
     * @param _addresses Array of addresses to send to, it is payable which means that the _addresses can recieve ETH. Calldata is better than memory for gas saving.
     * @param _amounts Array of amounts to send, calldata is better than memory for gas saving.
     * The function is payable which means that it is a special type of function that is able to receive Ether (ETH) as part of a transaction
     * external means it can only be called from outside the contract, typically by other contracts or externally owned accounts (EOAs). It s better to use external instead of public here
     *  for gas saving.
     */
    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) external payable whenNotPaused returns (bool) {
        /// The function checks if both input arrays have non-zero lengths. If either of them is empty,
        if (_addresses.length <= 0) {
            revert NoAddressesSpecified();
        }
        if (_addresses.length > 100) {
            revert TooManyAddresses();
        }
        if (_amounts.length <= 0) {
            revert NoAmountsSpecified();
        }
        /// The function checks if the lengths of both input arrays are the same. If they are not, it reverts the transaction with a custom error message (ArrayLengthMismatch).
        if (_addresses.length != _amounts.length) {
            revert ArrayLengthMismatch();
        }
        uint256 _value = msg.value;
        for (uint256 i = 0; i < _addresses.length; ++i) {
            /// It then iterates through the _addresses and _amounts arrays,
            /// checking if the sender has provided enough Ether to cover each transfer. If not, it reverts the transaction with a custom error message (InsufficientEtherValue).
            if (_value < _amounts[i]) {
                revert InsufficientEtherValue();
            }
            /// For each valid transfer, it calls the internal function _transfer to send Ether to the recipient address. It also updates the _value variable accordingly.
            _transferEth(_addresses[i], _amounts[i]);
            _value -= _amounts[i];
        }
        /// @dev Inside the multiTransferETH function, when a transaction occurs, we emit the Multisended event with the relevant data.
        /// This event can be listened to by external applications to track transactions between addresses.
        emit Multisended(
            msg.sender,
            msg.value,
            0x000000000000000000000000000000000000bEEF
        );
        return true;
    }

    /**
     * @notice Transfer token to multiple addresses.
     * @dev This function sends ERC20 token to multiple addresses using these parameters:
     * @param _token The token to send
     * @param _addresses Array of addresses to send to
     * @param _amounts Array of amounts to send, calldata is better than memory for gas saving.
     * @param _amountSum Sum of _amounts array to send
     */
    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        uint256 _amountSum
    ) external whenNotPaused {
        /// The function checks these items: both input arrays have non-zero lengths, length of addresses should not be greater than 100, and equal to length of amounts.
        if (_addresses.length <= 0) {
            revert NoAddressesSpecified();
        }
        if (_addresses.length > 100) {
            revert TooManyAddresses();
        }
        if (_amounts.length <= 0) {
            revert NoAmountsSpecified();
        }
        if (_addresses.length != _amounts.length) {
            revert ArrayLengthMismatch();
        }
        /// Check the allowance to be sure that token approve is done before. (msg.sender approved address(this): MultiTransferV2 to spent _amountSum)
        IERC20 token = IERC20(_token);
        if (token.allowance(msg.sender, address(this)) < _amountSum) {
            revert InsufficientTokenAllowance();
        }
        /// Transfer _amountSum to address(this) via msg.sender. address(this) distributes each _amount[i] to _addresses[i]
        token.safeTransferFrom(msg.sender, address(this), _amountSum);

        for (uint256 i = 0; i < _addresses.length; ++i) {
            if (_amountSum < _amounts[i]) {
                revert InsufficientTokenAmount();
            }
            /// _amounts[i] of token is transferred to _addresses[i] via address(this), and _amountSum will be updated after each transfer
            _transferToken(address(token), _addresses[i], _amounts[i]);

            _amountSum -= _amounts[i];
        }
        /// @dev Inside the multiTransferToken function, when a transaction occurs, we emit the Multisended event with the relevant data.
        /// This event can be listened to by external applications to track transactions between addresses.
        emit Multisended(msg.sender, _amountSum, address(token));
    }

    /**
     * @notice Transfer ETH and token to multiple addresses in one transaction.
     * @dev This function sends ERC20 token to multiple addresses using these parameters:
     * @param _token The token to send
     * @param _addresses Array of addresses to send to, it is payable which means that the _addresses can recieve ETH.
     * @param _amounts Array of token amounts to send
     * @param _amountSum Sum of _amounts array to send
     * @param _amountsEther Array of ETH amounts to send
     * The function is payable which means that it is a special type of function that is able to receive Ether (ETH) as part of a transaction
     */
    function multiTransferTokenEther(
        address _token,
        address payable[] calldata _addresses,
        uint256[] calldata _amounts,
        uint256 _amountSum,
        uint256[] calldata _amountsEther
    ) external payable whenNotPaused {
        /// The function checks these items: both input arrays have non-zero lengths, length of addresses should not be greater than 100, and equal to length of amounts ETH/ERC20.

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

        /// Check the allowance to be sure that token approve is done before. (msg.sender approved address(this) to spent _amountSum)
        if (token.allowance(msg.sender, address(this)) < _amountSum) {
            revert InsufficientTokenAllowance();
        }

        token.safeTransferFrom(msg.sender, address(this), _amountSum);

        /// For each valid transfer, it calls the internal function _transfer to send Ether and safeTransfer to transfer tokens to the recipient address.
        /// It also updates the _value and _amountSum variable accordingly.
        for (uint256 i = 0; i < _addresses.length; ++i) {
            _transferEth(_addresses[i], _amountsEther[i]);
            _transferToken(address(token), _addresses[i], _amounts[i]);

            _value -= _amountsEther[i];
            _amountSum -= _amounts[i];
        }

        /// @dev Inside the multiTransferTokenAndEther function, when a transaction occurs, we emit the MultisendTokenAndEther event with the relevant data.
        /// This event can be listened to by external applications to track transactions between addresses.
        emit MultisendTokenAndEther(
            _amountSum,
            address(token),
            msg.value,
            0x000000000000000000000000000000000000bEEF
        );
    }

    /**
    @dev This function is used to pause the operation of the smart contract. 
    When this function is called by the owner, it invokes the _pause() function of OpenZeppelin's Pausable contract.
    */
    function emergencyStop() external onlyOwner {
        _pause();
    }

    /**
    @dev This function is used to unpause the operation of the smart contract. 
    When this function is called by the owner, it invokes the _unpause() function of OpenZeppelin's Pausable contract.
    */

    function unPaused() external onlyOwner {
        _unpause();
    }

    /**
     * @notice If there exists any ETH or ERC20 token in balance of this contract, owner can withdraw them. Be careful for calculating _value and _amountSum.
     * @dev This function works as withdraw
     * @param _token The token to send
     * onlyOwner can withdraw funds.
     */
    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        _transferToken(address(erc20token), owner(), balance);

        /// @dev Inside the claimTokens function, when a transaction occurs, we emit the ClaimedTokens event with the relevant data.
        emit ClaimedTokens(_token, owner(), balance);
    }

    /// @notice `_transfer` is used internally to transfer funds safely.
    function _transferEth(address _to, uint256 _amount) internal {
        require(_to != address(0), "Invalid recipient address");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        // payable(_to).transfer(_amount);
    }

    function _transferToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0), "Invalid recipient address");
        IERC20 token = IERC20(_token);
        token.safeTransfer(_to, _amount);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
