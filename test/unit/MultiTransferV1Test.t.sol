// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MultiTransferV1} from "../../src/MultiTransferV1.sol";
import {DeployMultiTransferV1} from "../../script/DeployMultiTransferV1.s.sol";
import {MockToken} from "../mocks/MockToken.sol";

contract MultiTransferV1Test is Test {
    MultiTransferV1 multiTransfer;
    address immutable USER = makeAddr("user");
    address immutable FIRST_RECIEPIENT = makeAddr("firstRecipient");
    address immutable SECOND_RECIPIENT = makeAddr("secondRecipient");
    MockToken token;

    uint256 constant STARTING_BALANCE = 20 ether;
    uint256 constant FIRST_SEND_VALUE = 0.01 ether;
    uint256 constant SECOND_SEND_VALUE = 0.02 ether;

    function setUp() external {
        DeployMultiTransferV1 deployMultiTransferV1 = new DeployMultiTransferV1();
        multiTransfer = deployMultiTransferV1.run();
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

    function testFallback() public {
        // Send ether to the contract using the fallback function
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0.05 ether;
        (bool success, ) = address(multiTransfer).call{value: sentEther}(
            "0xggfd"
        );
        assertTrue(success);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testFallbackSendingZeroEther() public {
        // Send ether to the contract using the fallback function
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0 ether;
        (bool success, ) = address(multiTransfer).call{value: sentEther}(
            "0xggfd"
        );
        assertTrue(success);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testFallbackWithoutData() public {
        // Send ether to the contract using the fallback function
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0.05 ether;
        (bool success, ) = address(multiTransfer).call{value: sentEther}("");
        assertTrue(success);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testreceiveWithoutData() public {
        // Send Ether to the contract using the receive function
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0.03 ether;
        payable(address(multiTransfer)).transfer(sentEther);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testreceiveWithData() public {
        // Send Ether to the contract using the receive function
        uint256 initialContractBalance = address(multiTransfer).balance;
        uint256 sentEther = 0.03 ether;
        (bool success, ) = payable(address(multiTransfer)).call{
            value: sentEther
        }("0xhghghd");
        assertTrue(success);

        // Check if the contract balance has increased
        uint256 finalContractBalance = address(multiTransfer).balance;
        assertEq(finalContractBalance, initialContractBalance + sentEther);
    }

    function testMultiTransferTokeneEtherFailsWhitTooManyAddresses() public {
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
}
