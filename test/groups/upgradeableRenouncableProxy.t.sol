// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import "forge-std/console.sol";
import "../../src/groups/UpgradeableRenounceableProxy.sol";
import "../../src/errors/Errors.sol";
import "./groupSetup.sol";

contract UpgradeableRenounceableProxyTest is Test, GroupSetup {
    // State variables
    address public group;

    // Constructor

    constructor() GroupSetup() {}

    // Setup

    function setUp() public {
        // first 35 addresses are registered as human
        // in mock deployment, with 14 days of mint
        groupSetup();

        group = addresses[36];
    }

    // Tests

    function testRegisterGroupWithProxyPolicy() public {
        // create a proxy deployment with the mint policy as implementation
        vm.startPrank(group);
        UpgradeableRenounceableProxy proxy = new UpgradeableRenounceableProxy(mintPolicy, "");
        hub.registerGroup(address(proxy), "ProxyPolicyGroup", "PPG", bytes32(0));
        vm.stopPrank();
    }
}
