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
    address group;
    
    // UpgradeableRenounceableProxy public policyProxy;

    // Constructor

    constructor() GroupSetup() {}

    // Setup

    function setUp() public {
        groupSetup();

        group = addresses[39];
    }

    // // Tests

    // function testProxyGroup() public {

    // }
}
