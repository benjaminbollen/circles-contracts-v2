// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import "forge-std/console.sol";
import "../../src/errors/Errors.sol";
import "./setup.sol";

contract UpgradeableRenounceableProxyTest is Test, GroupSetup {
    // Constructor

    constructor() GroupSetup() {}

    // Setup

    function setUp() public {}
}
