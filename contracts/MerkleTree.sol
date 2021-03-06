/**
 *Submitted for verification at Etherscan.io on 2020-10-14
 */

// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.4;
import "./interfaces/Types.sol";

// Based on official specification in https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}

interface ITree is Types {
    function enqueueOutbound(OutboundRequest memory _request) external payable;

    function get_root() external view returns (bytes32);
}

contract MerkleTree is ITree, ERC165 {
    uint256 constant TREE_DEPTH = 32;
    // NOTE: this also ensures `count` will fit into 64-bits
    uint256 constant MAX_ELEMENTS_COUNT = 2**TREE_DEPTH - 1;

    bytes32[TREE_DEPTH] public branch;
    uint256 public count;

    bytes32[TREE_DEPTH] public zero_hashes;

    constructor() {
        // Compute hashes in empty sparse Merkle tree
        for (uint256 height = 0; height < TREE_DEPTH - 1; height++)
            zero_hashes[height + 1] = sha256(abi.encodePacked(zero_hashes[height], zero_hashes[height]));
    }

    function get_root() external view override returns (bytes32) {
        bytes32 node;
        uint256 size = count;
        for (uint256 height = 0; height < TREE_DEPTH; height++) {
            if ((size & 1) == 1) {
                node = sha256(abi.encodePacked(branch[height], node));
            } else {
                node = sha256(abi.encodePacked(node, zero_hashes[height]));
            }
            size /= 2;
        }
        return node;
    }

    function enqueueOutbound(OutboundRequest calldata _request) external payable override {
        require(_request.amount <= type(uint64).max, "DepositContract: deposit value too high");

        // Compute deposit data root (`DepositData` hash tree root)
        bytes32 node = createTransferHash(_request);

        // Avoid overflowing the Merkle tree (and prevent edge case in computing `branch`)
        require(count < MAX_ELEMENTS_COUNT, "DepositContract: merkle tree full");

        // Add deposit data root to Merkle tree (update a single `branch` node)
        count += 1;
        uint256 size = count;
        for (uint256 height = 0; height < TREE_DEPTH; height++) {
            if ((size & 1) == 1) {
                branch[height] = node;
                return;
            }
            node = sha256(abi.encodePacked(branch[height], node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    function computeRoot(
        bytes32 leafInput,
        uint256 path,
        bytes32[] memory witness
    ) internal pure returns (bytes32) {
        // Copy to avoid assigning to the function parameter.
        bytes32 leaf = leafInput;
        for (uint256 i = 0; i < witness.length; i++) {
            // get i-th bit from right
            if (((path >> i) & 1) == 0) {
                leaf = sha256(abi.encodePacked(leaf, witness[i]));
            } else {
                leaf = sha256(abi.encodePacked(witness[i], leaf));
            }
        }
        return leaf;
    }

    function verify(
        bytes32 root,
        bytes32 leaf,
        uint256 path,
        bytes32[] memory witness
    ) external pure returns (bool) {
        return computeRoot(leaf, path, witness) == root;
    }

    function createTransferHash(Types.OutboundRequest calldata _request) public pure returns (bytes32) {
        return
            bytes32(
                sha256(
                    abi.encode(
                        _request.from,
                        _request.receiver,
                        _request.destinationChainID,
                        _request.amount,
                        _request.transferID
                    )
                )
            );
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(ERC165).interfaceId || interfaceId == type(ITree).interfaceId;
    }
}
