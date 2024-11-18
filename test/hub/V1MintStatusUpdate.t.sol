// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/migration/IToken.sol";
import "../../src/migration/Migration.sol";
import "../../src/names/NameRegistry.sol";
import "../setup/TimeCirclesSetup.sol";
import "../setup/AvatarCreation.sol";
import "../migration/MockHub.sol";
import "./MockMigrationHub.sol";

contract V1MintStatusUpdateTest is Test, TimeCirclesSetup, AvatarCreation {
    // State variables

    MockMigrationHub public mockHub;
    MockHubV1 public mockHubV1;

    NameRegistry public nameRegistry;
    Migration public migration;

    // Constructor

    constructor() AvatarCreation(2) {}

    // Setup

    function setUp() public {
        // Set time in 2021
        startTime();

        // Mock hub v1
        mockHubV1 = new MockHubV1();

        // First deploy the mock hub v2 so that we have the address
        mockHub = new MockMigrationHub(mockHubV1, address(2), INFLATION_DAY_ZERO, 365 days);

        // Name registry and migration do not need to be mocked
        nameRegistry = new NameRegistry(IHubV2(address(mockHub)));
        migration = new Migration(mockHubV1, IHubV2(address(mockHub)), INFLATION_DAY_ZERO);

        // update hub v2 with the new addresses of the name registry and migration
        mockHub.setSiblings(address(migration), address(nameRegistry));
    }

    // Tests

    function testMigrationFromV1DuringBootstrap() public {
        // Alice and Bob register in V1
        ITokenV1 tokenAlice = signupInV1(addresses[0]);
        ITokenV1 tokenBob = signupInV1(addresses[1]);

        // move time
        skipTime(5 days + 1 hours + 31 minutes);

        // Alice and Bob mint in V1
        mintV1Tokens(tokenAlice);
        mintV1Tokens(tokenBob);

        // Alice stops her V1 token and registers in V2
        vm.startPrank(addresses[0]);
        tokenAlice.stop();
        assertTrue(tokenAlice.stopped(), "Token not stopped");
        mockHub.registerHuman(address(0), bytes32(0));
        vm.stopPrank();
        assertTrue(mockHub.isHuman(addresses[0]), "Alice not registered");

        // Alice invites Bob, while he is still active in V1
        // to do that she must trust Bob, and then he can register with Alice as inviter
        vm.prank(addresses[0]);
        // Alice trusts Bob
        mockHub.trust(addresses[1], type(uint96).max);
        // Bob registers with Alice as inviter
        vm.prank(addresses[1]);
        // Bob calls register Human with Alice as inviter
        mockHub.registerHuman(addresses[0], bytes32(0));
        assertTrue(mockHub.isHuman(addresses[1]), "Bob not registered");

        // move time
        skipTime(5 days - 31 minutes);

        // Alice can mint in V2
        vm.prank(addresses[0]);
        mockHub.personalMint();

        // Bob cannot mint in V2, but can in V1
        vm.expectRevert();
        vm.prank(addresses[1]);
        mockHub.personalMint();
        mintV1Tokens(tokenBob);

        // Bob stops his V1 token
        vm.prank(addresses[1]);
        tokenBob.stop();

        // Bob can mint in V2, but calculateIssuance will still revert because V1 status not updated
        vm.expectRevert();
        mockHub.calculateIssuance(addresses[1]);
        // however, sending a transaction to update the V1 status does calculate the issuance, and update status
        mockHub.calculateIssuanceWithCheck(addresses[1]);

        // move time
        skipTime(5 days + 31 minutes);

        // Bob can mint in V2
        vm.prank(addresses[1]);
        mockHub.personalMint();

        // todo: split into proper unit tests
        // and cover inflation and unwrap
    }

    // Private functions

    function signupInV1(address _user) private returns (ITokenV1) {
        vm.prank(_user);
        mockHubV1.signup();
        ITokenV1 token = ITokenV1(mockHubV1.userToToken(_user));
        require(address(token) != address(0), "Token not minted");
        require(token.owner() == _user, "Token not owned by user");
        return token;
    }

    function mintV1Tokens(ITokenV1 _token) private returns (uint256) {
        address owner = _token.owner();
        uint256 balanceBefore = _token.balanceOf(owner);
        ITokenV1(_token).update();
        uint256 balanceAfter = _token.balanceOf(owner);
        return balanceAfter - balanceBefore;
    }
}
