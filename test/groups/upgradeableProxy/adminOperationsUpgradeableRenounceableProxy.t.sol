// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import "forge-std/console.sol";
import "../../../src/groups/UpgradeableRenounceableProxy.sol";
import "../../../src/errors/Errors.sol";
import "../groupSetup.sol";

contract adminOperationsUpgradeableRenounceableProxy is Test, GroupSetup {
    // State variables

    address public group;
    IUpgradeableRenounceableProxy public proxy;

    // Constructor

    constructor() GroupSetup() {}

    // Setup

    function setUp() public {
        // first 35 addresses are registered as human
        // in mock deployment, with 14 days of mint
        groupSetup();

        // 36: Kevin
        group = addresses[36];

        // create a proxy deployment with the mint policy as implementation
        vm.startPrank(group);
        proxy = IUpgradeableRenounceableProxy(address(new UpgradeableRenounceableProxy(mintPolicy, "")));
        hub.registerGroup(address(proxy), "ProxyPolicyGroup", "PPG", bytes32(0));
        vm.stopPrank();

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(group);
            hub.trust(addresses[i], INDEFINITE_FUTURE);
        }
    }

    // Tests

    function testGetImplementation() public {
        address implementation = proxy.implementation();
        assertEq(implementation, mintPolicy);
    }

    /* todo: - test getting admin from proxy
     *       - test admin cannot be changed
     *       - test noone else can call upgradeToAndCall
     *       - test upgradeToAndCall with call data
     *       - test renouncing admin
     */

    function testUpgradeToAndCall() public {
        address originalImplementation = proxy.implementation();
        assertEq(originalImplementation, mintPolicy);

        // deploy a new copy of base mint policy
        address newMintPolicy = address(new MintPolicy());

        // upgrade the proxy to the new implementation
        vm.prank(group);
        proxy.upgradeToAndCall(newMintPolicy, "");

        // check that the implementation has changed
        address newImplementation = proxy.implementation();
        assertEq(newImplementation, newMintPolicy);
    }
}
