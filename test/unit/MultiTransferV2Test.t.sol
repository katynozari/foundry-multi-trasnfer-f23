// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MultiTransferV2} from "../../src/MultiTransferV2.sol";
import {DeployMultiTransferV2} from "../../script/DeployMultiTransferV2.s.sol";
import {MockToken} from "../mocks/MockToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiTransferV2Test is Test {
    using SafeERC20 for IERC20;

    MultiTransferV2 multiTransfer;
    address immutable USER = makeAddr("user");
    address immutable FIRST_RECIEPIENT = makeAddr("firstRecipient");
    address immutable SECOND_RECIPIENT = makeAddr("secondRecipient");
    MockToken token;

    uint256 constant STARTING_BALANCE = 20 ether;
    uint256 constant FIRST_SEND_VALUE = 0.01 ether;
    uint256 constant SECOND_SEND_VALUE = 0.02 ether;

    function setUp() external {
        DeployMultiTransferV2 deployMultiTransferV2 = new DeployMultiTransferV2();
        multiTransfer = deployMultiTransferV2.run();
        vm.deal(USER, STARTING_BALANCE);
        token = new MockToken("Life", "LFT", 300000e18);
        deal(address(token), USER, 200000);
    }

    function testOwnerIsMsgSender() public {
        // console.log(multiTransfer.owner());
        // console.log(msg.sender);
        assertEq(multiTransfer.owner(), msg.sender);
    }

    // Ether Transfer Section

    function testMultiTransferETHFailsWithLengthOfAddressesIsZero() public {
        address payable[] memory addresses;
        // addresses[0] = payable(address(0)); // Cast to address payable

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = FIRST_SEND_VALUE;
        // console.log(addresses.length);
        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferETH(addresses, amounts); // send value, address
    }

    function testMultiTransferEthFailsWhitTooManyAddresses() public {
        address payable[] memory recipients = new address payable[](256);
        uint256[] memory amounts = new uint256[](256);

        for (uint256 i = 0; i < 256; i++) {
            recipients[i] = payable(makeAddr("recipient"));
            amounts[i] = 0.01 ether;
        }

        vm.expectRevert(); // hey, the next line should revert/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferETH(recipients, amounts);
    }

    function testMultiTransferETHFailsWithLengthOfAmountsIsZero() public {
        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payable

        uint256[] memory dynamicEmptyArray;

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferETH(addresses, dynamicEmptyArray); //
    }

    function testMultiTransferETHFailsWhenLengthOfAmountsAndAddressesAreNotEqual()
        public
    {
        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payable

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = FIRST_SEND_VALUE;
        amounts[1] = SECOND_SEND_VALUE;

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferETH(addresses, amounts);
    }

    function testMultiTransferETH() public {
        address payable[] memory addresses = new address payable[](2);
        addresses[0] = payable(FIRST_RECIEPIENT);
        addresses[1] = payable(SECOND_RECIPIENT);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = FIRST_SEND_VALUE;
        amounts[1] = SECOND_SEND_VALUE;

        uint256 startingUserBalance = USER.balance;
        uint256 startingFirstRecipientBalance = FIRST_RECIEPIENT.balance;
        uint256 startingSecondRecipientBalance = SECOND_RECIPIENT.balance;

        //Act
        vm.startPrank(USER);
        multiTransfer.multiTransferETH{
            value: FIRST_SEND_VALUE + SECOND_SEND_VALUE
        }(addresses, amounts);
        vm.stopPrank();

        // ASSERT

        uint256 endingUserBalance = USER.balance;
        uint256 endingFirstRecipientBalance = FIRST_RECIEPIENT.balance;
        uint256 endingSecondRecipientBalance = SECOND_RECIPIENT.balance;
        assertEq(
            endingFirstRecipientBalance,
            startingFirstRecipientBalance + FIRST_SEND_VALUE
        );
        assertEq(
            endingSecondRecipientBalance,
            startingSecondRecipientBalance + SECOND_SEND_VALUE
        );
        assertEq(
            endingUserBalance,
            startingUserBalance - (FIRST_SEND_VALUE + SECOND_SEND_VALUE)
        );
    }

    function testMultiTransferETHFailsWithInsufficientEtherValue() public {
        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(FIRST_RECIEPIENT);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = FIRST_SEND_VALUE;

        //Act
        vm.expectRevert();
        multiTransfer.multiTransferETH(addresses, amounts);
    }

    // Token Transfer Section

    function testMultiTransferTokenFailsWithLengthOfAddressesIsZero() public {
        address[] memory addresses;
        // addresses[0] = payable(address(0)); // Cast to address payable

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5000;
        amounts[1] = 1000;
        uint256 totalAmount = amounts[0] + amounts[1];

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferToken(
            address(token),
            addresses,
            amounts,
            totalAmount
        );
    }

    function testMultiTransferTokenFailsWhitManyAddresses() public {
        address[] memory recipients = new address[](256);
        uint256[] memory amountsToken = new uint256[](256);

        for (uint256 i = 0; i < 256; i++) {
            recipients[i] = payable(makeAddr("recipient"));
            amountsToken[i] = 1;
        }
        uint256 totalTokenAmount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            totalTokenAmount += amountsToken[i];
        }

        vm.expectRevert(); // hey, the next line should revert/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferToken(
            address(token),
            recipients,
            amountsToken,
            totalTokenAmount // Sufficient allowance
        );
    }

    function testMultiTransferTokenFailsWithLengthOfAmountsIsZero() public {
        address[] memory addresses = new address[](1);
        addresses[0] = FIRST_RECIEPIENT;

        uint256[] memory dynamicEmptyArray;
        uint256 totalAmount = 0;

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferToken(
            address(token),
            addresses,
            dynamicEmptyArray,
            totalAmount
        );
    }

    function testMultiTransferTokenFailsWhenLengthOfAmountsAndAddressesAreNotEqual()
        public
    {
        address[] memory addresses = new address[](1);
        addresses[0] = FIRST_RECIEPIENT;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5000;
        amounts[1] = 1000;

        uint256 totalAmount = amounts[0] + amounts[1];

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferToken(
            address(token),
            addresses,
            amounts,
            totalAmount
        );
    }

    function testMultiTransferTokenFailsWhitInsufficientTokenAllowanceError_WithoutApprove()
        public
    {
        address[] memory addresses = new address[](2);
        addresses[0] = FIRST_RECIEPIENT; // or any other address
        addresses[1] = SECOND_RECIPIENT;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5000;
        amounts[1] = 6000;

        vm.expectRevert(); // Expect a revert
        multiTransfer.multiTransferToken(
            address(token),
            addresses,
            amounts,
            11000 // Insufficient allowance
        );
    }

    function testMultiTransferTokenFailsWhitInsufficientTokenAllowanceError_WithApprove()
        public
    {
        vm.startPrank(USER);
        // Approve some allowance
        token.approve(address(multiTransfer), 1000);
        vm.stopPrank();

        address[] memory addresses = new address[](2);
        addresses[0] = FIRST_RECIEPIENT; // or any other address
        addresses[1] = SECOND_RECIPIENT;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5000;
        amounts[1] = 6000;

        vm.startPrank(USER);
        vm.expectRevert(); // Expect a revert
        multiTransfer.multiTransferToken(
            address(token),
            addresses,
            amounts,
            11000 // Insufficient allowance
        );
        vm.stopPrank();
    }

    function testMultiTransferTokenFailsWhitInsufficientTokenAmount() public {
        vm.startPrank(USER);
        // Approve sufficient allowance
        token.approve(address(multiTransfer), 1000);
        vm.stopPrank();

        address[] memory addresses = new address[](2);
        addresses[0] = FIRST_RECIEPIENT; // or any other address
        addresses[1] = SECOND_RECIPIENT;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 500;
        amounts[1] = 100;
        console.log(token.balanceOf(USER));
        console.log(token.allowance(USER, address(multiTransfer)));

        vm.startPrank(USER);
        vm.expectRevert(); // Expect a revert
        multiTransfer.multiTransferToken(
            address(token),
            addresses,
            amounts,
            400 // Insufficient amount sum
        );
        vm.stopPrank();
    }

    // Test Token Transfers:
    function testMultiTransferTokenSuccessWithSufficientTokenAllowance()
        public
    {
        // Set up
        vm.startPrank(USER);
        // Approve sufficient allowance
        token.approve(address(multiTransfer), 1000);
        vm.stopPrank();
        console.log(token.balanceOf(USER));

        console.log(token.allowance(USER, address(multiTransfer)));
        console.log(token.balanceOf(FIRST_RECIEPIENT));
        console.log(token.balanceOf(SECOND_RECIPIENT));

        address[] memory addresses = new address[](2);
        addresses[0] = FIRST_RECIEPIENT; // or any other address
        addresses[1] = SECOND_RECIPIENT;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 500;
        amounts[1] = 100;

        uint256 startingUserBalance = token.balanceOf(USER);
        uint256 startingFirstRecipientBalance = token.balanceOf(
            FIRST_RECIEPIENT
        );
        uint256 startingSecondRecipientBalance = token.balanceOf(
            SECOND_RECIPIENT
        );

        // Act
        vm.startPrank(USER);
        multiTransfer.multiTransferToken(
            address(token),
            addresses,
            amounts,
            600 // Sufficient allowance
        );
        vm.stopPrank();

        console.log(token.balanceOf(USER));
        console.log(token.balanceOf(FIRST_RECIEPIENT));
        console.log(token.balanceOf(SECOND_RECIPIENT));

        // Assert
        uint256 endingUserBalance = token.balanceOf(USER);
        uint256 endingFirstRecipientBalance = token.balanceOf(FIRST_RECIEPIENT);
        uint256 endingSecondRecipientBalance = token.balanceOf(
            SECOND_RECIPIENT
        );

        assertEq(
            endingFirstRecipientBalance,
            startingFirstRecipientBalance + 500
        );
        assertEq(
            endingSecondRecipientBalance,
            startingSecondRecipientBalance + 100
        );
        assertEq(endingUserBalance, startingUserBalance - 600);
    }

    // test multiTransferTokenEther

    function testMultiTransferTokenEtherFailsWithLengthOfAddressesIsZero()
        public
    {
        address payable[] memory addresses;

        uint256[] memory amountsEther = new uint256[](1);
        amountsEther[0] = FIRST_SEND_VALUE;

        uint256[] memory amountsToken = new uint256[](1);
        amountsToken[0] = 5000;
        uint256 totalAmount = amountsToken[0];

        // console.log(addresses.length);

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferTokenEther(
            address(token),
            addresses,
            amountsToken,
            totalAmount,
            amountsEther
        ); // send value, address
    }

    function testMultiTransferTokenEtherFailsWithLengthOfTokenAmountsIsZero()
        public
    {
        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payabl

        uint256[] memory amountsEther = new uint256[](1);
        amountsEther[0] = FIRST_SEND_VALUE;

        uint256[] memory dynamicEmptyArrayToken;
        uint256 totalAmount = 0;

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferTokenEther(
            address(token),
            addresses,
            dynamicEmptyArrayToken,
            totalAmount,
            amountsEther
        );
    }

    function testMultiTransferTokenEtherFailsWithLengthOfEtherAmountsIsZero()
        public
    {
        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payabl

        uint256[] memory dynamicEmptyArrayEther;

        uint256[] memory amountsToken = new uint256[](1);
        amountsToken[0] = FIRST_SEND_VALUE;
        uint256 totalAmount = amountsToken[0];

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferTokenEther(
            address(token),
            addresses,
            amountsToken,
            totalAmount,
            dynamicEmptyArrayEther
        ); // send value, address
    }

    function testMultiTransferTokenEtherFailsWhenLengthOfTokenAmountsAndAddressesAreNotEqual()
        public
    {
        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payabl

        uint256[] memory amountsEther = new uint256[](1);
        amountsEther[0] = FIRST_SEND_VALUE;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5000;
        amounts[1] = 1000;

        uint256 totalAmount = amounts[0] + amounts[1];

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferTokenEther(
            address(token),
            addresses,
            amounts,
            totalAmount,
            amountsEther
        );
    }

    function testMultiTransferTokenEtherFailsWhenLengthOfEtherAmountsAndAddressesAreNotEqual()
        public
    {
        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payabl

        uint256[] memory amountsEther = new uint256[](2);
        amountsEther[0] = FIRST_SEND_VALUE;
        amountsEther[1] = SECOND_SEND_VALUE;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5000;

        uint256 totalAmount = amounts[0];

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferTokenEther(
            address(token),
            addresses,
            amounts,
            totalAmount,
            amountsEther
        );
    }

    function testMultiTransferTokenEtherFailsWhitInsufficientTokenAllowanceError()
        public
    {
        address payable[] memory addresses = new address payable[](2);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payabl
        addresses[1] = payable(SECOND_RECIPIENT);

        uint256[] memory amountsEther = new uint256[](2);
        amountsEther[0] = FIRST_SEND_VALUE;
        amountsEther[1] = SECOND_SEND_VALUE;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5000;
        amounts[1] = 6000;
        uint256 totalAmount = amounts[0] + amounts[1];

        vm.expectRevert(); // Expect a revert
        multiTransfer.multiTransferTokenEther(
            address(token),
            addresses,
            amounts,
            totalAmount,
            amountsEther // Insufficient allowance
        );
    }

    // Test Token  ETHER Transfers:
    function testMultiTransferTokenEtherSuccessWithSufficientTokenAllowance()
        public
    {
        // Set up
        vm.startPrank(USER);
        // Approve sufficient allowance
        token.approve(address(multiTransfer), 1000);
        vm.stopPrank();

        address payable[] memory addresses = new address payable[](2);
        addresses[0] = payable(FIRST_RECIEPIENT); // Cast to address payabl
        addresses[1] = payable(SECOND_RECIPIENT);

        uint256[] memory etherAmounts = new uint256[](2);
        etherAmounts[0] = FIRST_SEND_VALUE;
        etherAmounts[1] = SECOND_SEND_VALUE;

        uint256[] memory tokenAmounts = new uint256[](2);
        tokenAmounts[0] = 500;
        tokenAmounts[1] = 100;
        uint256 totalAmount = tokenAmounts[0] + tokenAmounts[1];

        uint256 startingUserBalance = USER.balance;
        uint256 startingFirstRecipientBalance = FIRST_RECIEPIENT.balance;
        uint256 startingSecondRecipientBalance = SECOND_RECIPIENT.balance;

        uint256 startingUserTokenBalance = token.balanceOf(USER);
        uint256 startingFirstRecipientTokenBalance = token.balanceOf(
            FIRST_RECIEPIENT
        );
        uint256 startingSecondRecipientTokenBalance = token.balanceOf(
            SECOND_RECIPIENT
        );

        // Act
        vm.startPrank(USER);
        multiTransfer.multiTransferTokenEther{
            value: FIRST_SEND_VALUE + SECOND_SEND_VALUE
        }(address(token), addresses, tokenAmounts, totalAmount, etherAmounts);
        vm.stopPrank();

        // Assert

        uint256 endingUserBalance = USER.balance;
        uint256 endingFirstRecipientBalance = FIRST_RECIEPIENT.balance;
        uint256 endingSecondRecipientBalance = SECOND_RECIPIENT.balance;

        uint256 endingUserTokenBalance = token.balanceOf(USER);
        uint256 endingFirstRecipientTokenBalance = token.balanceOf(
            FIRST_RECIEPIENT
        );
        uint256 endingSecondRecipientTokenBalance = token.balanceOf(
            SECOND_RECIPIENT
        );

        console.log(token.balanceOf(USER));
        console.log(token.balanceOf(FIRST_RECIEPIENT));
        console.log(token.balanceOf(SECOND_RECIPIENT));

        assertEq(
            endingFirstRecipientBalance,
            startingFirstRecipientBalance + FIRST_SEND_VALUE
        );
        assertEq(
            endingSecondRecipientBalance,
            startingSecondRecipientBalance + SECOND_SEND_VALUE
        );
        assertEq(
            endingUserBalance,
            startingUserBalance - (FIRST_SEND_VALUE + SECOND_SEND_VALUE)
        );

        assertEq(
            endingFirstRecipientTokenBalance,
            startingFirstRecipientTokenBalance + 500
        );
        assertEq(
            endingSecondRecipientTokenBalance,
            startingSecondRecipientTokenBalance + 100
        );
        assertEq(endingUserTokenBalance, startingUserTokenBalance - 600);
    }

    function testEmergencyStop() public {
        assertFalse(multiTransfer.paused()); // Ensure the contract is initially unpaused
        vm.prank(multiTransfer.owner());
        multiTransfer.emergencyStop(); // Pause the contract
        assertTrue(multiTransfer.paused());

        vm.prank(multiTransfer.owner());
        multiTransfer.unPaused(); // Unpause the contract
        assertFalse(multiTransfer.paused());
    }

    function testReceiveEther() public payable {
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0.05 ether;

        // Send Ether to the contract using the receive function
        payable(address(multiTransfer)).transfer(sentEther);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testFallbackWithInvalidFunctionSelector() public payable {
        // Send Ether to the contract using the fallback function with an invalid function selector
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0.05 ether;
        (bool success, ) = address(multiTransfer).call{value: sentEther}(
            "0xabcdef"
        );
        assertTrue(success);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testFallbackWithData() public payable {
        // Send Ether to the contract using the fallback function with data
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0.05 ether;
        (bool success, ) = address(multiTransfer).call{value: sentEther}(
            "0x1234"
        );
        assertTrue(success);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testMultiTransferTokenEtherFailsWhitManyAddresses() public {
        address payable[] memory recipients = new address payable[](256);
        uint256[] memory amountsEther = new uint256[](256);
        uint256[] memory amountsToken = new uint256[](256);

        for (uint256 i = 0; i < 256; i++) {
            recipients[i] = payable(makeAddr("recipient"));
            amountsEther[i] = 0.01 ether;
            amountsToken[i] = 1;
        }
        uint256 totalTokenAmount = 0;
        uint256 totalEtherAmount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            totalTokenAmount += amountsToken[i];
            totalEtherAmount += amountsEther[i];
        }

        vm.expectRevert(); // hey, the next line should revert/fail
        // assert (this tx fails/reverts)
        multiTransfer.multiTransferTokenEther{value: totalEtherAmount}(
            address(token),
            recipients,
            amountsToken,
            totalTokenAmount,
            amountsEther
        );
    }

    function testClaimedTokenEthNotOwner() public {
        vm.expectRevert();
        vm.startPrank(USER);
        multiTransfer.claimTokens(address(0));
        vm.stopPrank();
    }

    function testClaimedTokenTokenNotOwner() public {
        vm.expectRevert();
        vm.startPrank(USER);
        multiTransfer.claimTokens(address(token));
        vm.stopPrank();
    }

    function testClaimEth() public {
        vm.deal(address(multiTransfer), STARTING_BALANCE);
        uint256 startingMultiTransferBalance = address(multiTransfer).balance;
        uint256 startingOwnerBalance = multiTransfer.getOwner().balance;
        // console.log(address(multiTransfer).balance);

        vm.startPrank(multiTransfer.getOwner());
        multiTransfer.claimTokens(address(0));
        vm.stopPrank();
        //    console.log(address(multiTransfer).balance);
        uint256 endingMultiTransferBalance = address(multiTransfer).balance;
        uint256 endingOwnerBalance = multiTransfer.getOwner().balance;

        assertEq(endingMultiTransferBalance, 0);
        assertEq(
            startingMultiTransferBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    function testClaimTokenErc20() public {
        deal(address(token), address(multiTransfer), 200000);
        uint256 startingMultiTransferBalance = token.balanceOf(
            address(multiTransfer)
        );
        uint256 startingOwnerBalance = token.balanceOf(
            multiTransfer.getOwner()
        );

        vm.startPrank(multiTransfer.getOwner());
        multiTransfer.claimTokens(address(token));
        vm.stopPrank();

        uint256 endingMultiTransferBalance = token.balanceOf(
            address(multiTransfer)
        );
        uint256 endingOwnerBalance = token.balanceOf(multiTransfer.getOwner());

        assertEq(endingMultiTransferBalance, 0);
        assertEq(
            startingMultiTransferBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    function testClaimedTokenEthWithBalanceWhichIsIncreasedByTransfer() public {
        // Transfer some ERC20 tokens to the contract for testing
        uint256 sentEther = 0.1 ether;
        payable(address(multiTransfer)).transfer(sentEther);

        uint256 startingMultiTransferBalance = address(multiTransfer).balance;

        uint256 startingOwnerBalance = multiTransfer.getOwner().balance;

        vm.startPrank(multiTransfer.getOwner());
        multiTransfer.claimTokens(address(0));
        vm.stopPrank();

        uint256 endingMultiTransferBalance = address(multiTransfer).balance;

        uint256 endingOwnerBalance = multiTransfer.getOwner().balance;

        assertEq(endingMultiTransferBalance, 0); // Contract's token balance should be zero after claiming
        assertEq(
            startingOwnerBalance + startingMultiTransferBalance,
            endingOwnerBalance // Owner's balance should increase by the claimed amount
        );
    }

    function testClaimedTokenErc20WithBalanceWhichIsIncreasedByTransfer()
        public
    {
        // Transfer some ERC20 tokens to the contract for testing
        uint256 transferAmount = 100;
        IERC20 erc20token = IERC20(token);
        erc20token.safeTransfer(address(multiTransfer), transferAmount);

        uint256 startingMultiTransferBalance = token.balanceOf(
            address(multiTransfer)
        );
        uint256 startingOwnerBalance = token.balanceOf(
            multiTransfer.getOwner()
        );

        vm.startPrank(multiTransfer.getOwner());
        multiTransfer.claimTokens(address(token));
        vm.stopPrank();

        uint256 endingMultiTransferBalance = token.balanceOf(
            address(multiTransfer)
        );
        uint256 endingOwnerBalance = token.balanceOf(multiTransfer.getOwner());

        assertEq(endingMultiTransferBalance, 0); // Contract's token balance should be zero after claiming
        assertEq(
            startingOwnerBalance + startingMultiTransferBalance,
            endingOwnerBalance // Owner's balance should increase by the claimed amount
        );
    }

    function testClaimEthWhenBalanceIsZero() public {
        uint256 startingOwnerBalance = multiTransfer.getOwner().balance;

        vm.startPrank(multiTransfer.getOwner());
        multiTransfer.claimTokens(address(0));
        vm.stopPrank();

        uint256 endingOwnerBalance = multiTransfer.getOwner().balance;

        assertEq(startingOwnerBalance, endingOwnerBalance); // Owner's balance should remain unchanged
    }

    function testClaimErc20WhenBalanceIsZero() public {
        uint256 startingOwnerBalance = token.balanceOf(
            multiTransfer.getOwner()
        );

        vm.startPrank(multiTransfer.getOwner());
        multiTransfer.claimTokens(address(token));
        vm.stopPrank();

        uint256 endingOwnerBalance = token.balanceOf(multiTransfer.getOwner());

        assertEq(startingOwnerBalance, endingOwnerBalance); // Owner's token balance should remain unchanged
    }

    function testTransferToInvalidRecipient() public {
        address payable[] memory recipient = new address payable[](1);
        recipient[0] = payable(address(0)); // Cast to address payable

        uint256[] memory amount = new uint256[](1);
        amount[0] = FIRST_SEND_VALUE;

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        vm.startPrank(USER);
        multiTransfer.multiTransferETH{value: FIRST_SEND_VALUE}(
            recipient,
            amount
        );
        vm.stopPrank();
    }

    function testTransferToInvalidRecipientForTwoAddresses() public {
        address payable[] memory recipients = new address payable[](2);
        recipients[0] = payable(FIRST_RECIEPIENT);
        recipients[1] = payable(address(0)); // Cast to address payable

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = FIRST_SEND_VALUE;
        amounts[1] = SECOND_SEND_VALUE;

        vm.expectRevert(); // hey, the next line should revet/fail
        // assert (this tx fails/reverts)
        vm.startPrank(USER);
        multiTransfer.multiTransferETH{
            value: FIRST_SEND_VALUE + SECOND_SEND_VALUE
        }(recipients, amounts);
        vm.stopPrank();
    }

    // function testTranferToken() public {
    //     address _to = address(0);
    //     uint256 _amount = 0.1 ether;
    //     IERC20 erc20token = IERC20(token);
    //     vm.expectRevert(); // hey, the next line should revet/fail
    //     // assert (this tx fails/reverts)
    //     vm.startPrank(USER);
    //     multiTransfer._transferToken(address(erc20token), _to, _amount);
    //     vm.stopPrank();
    // }
}
