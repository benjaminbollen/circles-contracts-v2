// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
interface IUpgradeableRenounceableProxy {
    function implementation() external view returns (address);
    function upgradeToAndCall(address _newImplementation, bytes memory _data) external;
    function renounceUpgradeability() external;
}
contract UpgradeableRenounceableProxy is ERC1967Proxy {
    // Errors

    error BlockReceive();
    
    // Constants

    /// @dev Initial proxy admin.
    address internal immutable ADMIN_INIT;

    // Constructor

    constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {
        // set the admin to the deployer
        ERC1967Utils.changeAdmin(msg.sender);
        // set the admin as immutable
        ADMIN_INIT = msg.sender;
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    /// @dev Dispatch if caller is admin.
    function _fallback() internal virtual override {
        if (msg.sender == ADMIN_INIT && msg.sender == ERC1967Utils.getAdmin()) {
            _dispatchAdmin();
        } else {
            super._fallback();
        }
    }

    /// @dev Upgrades to new implementation, renounces the ability to upgrade or moves to regular flow based on admin request.
    function _dispatchAdmin() private {
        if (msg.sig == IUpgradeableRenounceableProxy.upgradeToAndCall.selector) {
            // upgrades to new implementation
            (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } else if (msg.sig == IUpgradeableRenounceableProxy.renounceUpgradeability.selector) {
            // renounces the ability to upgrade the contract, by setting the admin to 0x01.
            ERC1967Utils.changeAdmin(address(0x01));
        } else {
            _delegate(_implementation());
        }
    }

    // Fallback function

    receive() external payable {
        revert BlockReceive();
    }
}
