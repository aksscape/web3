// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title QuantumLedger
 * @dev Immutable quantum-resistant ledger storing hashed entries with timestamps and metadata.
 */
contract QuantumLedger {
    struct LedgerEntry {
        bytes32 dataHash;       // Quantum-resistant hash (e.g., SHA-3/Keccak or post-quantum hash)
        address submitter;      // Address who submitted the entry
        uint256 timestamp;      // Block timestamp when entry was submitted
        string metadataURI;     // Optional metadata URI pointing to off-chain details (IPFS, Arweave)
    }

    // Mapping of entry indices to ledger entries
    mapping(uint256 => LedgerEntry) private ledgerEntries;
    uint256 private entryCount;

    // Events
    event EntryAdded(uint256 indexed entryId, bytes32 indexed dataHash, address indexed submitter, uint256 timestamp, string metadataURI);

    /**
     * @dev Adds a new ledger entry
     * @param dataHash The hash of the data being recorded (must be quantum-resistant)
     * @param metadataURI Optional URI for associated metadata/details
     */
    function addEntry(bytes32 dataHash, string calldata metadataURI) external {
        require(dataHash != bytes32(0), "Invalid data hash");

        entryCount++;
        ledgerEntries[entryCount] = LedgerEntry({
            dataHash: dataHash,
            submitter: msg.sender,
            timestamp: block.timestamp,
            metadataURI: metadataURI
        });

        emit EntryAdded(entryCount, dataHash, msg.sender, block.timestamp, metadataURI);
    }

    /**
     * @dev Retrieves a ledger entry by its ID
     * @param entryId The ID of the ledger entry
     * @return dataHash The stored data hash
     * @return submitter The address who submitted the entry
     * @return timestamp The block timestamp when entry was added
     * @return metadataURI The associated metadata URI
     */
    function getEntry(uint256 entryId) external view returns (
        bytes32 dataHash,
        address submitter,
        uint256 timestamp,
        string memory metadataURI
    ) {
        require(entryId > 0 && entryId <= entryCount, "Entry does not exist");
        LedgerEntry storage entry = ledgerEntries[entryId];
        return (entry.dataHash, entry.submitter, entry.timestamp, entry.metadataURI);
    }

    /**
     * @dev Verifies if the provided data hash matches a ledger entry by entryId
     * @param entryId The ledger entry ID
     * @param dataHash The data hash to verify
     * @return isMatch True if hashes match, false otherwise
     */
    function verifyEntry(uint256 entryId, bytes32 dataHash) external view returns (bool isMatch) {
        require(entryId > 0 && entryId <= entryCount, "Entry does not exist");
        return ledgerEntries[entryId].dataHash == dataHash;
    }

    /**
     * @dev Returns total number of entries recorded
     */
    function getEntryCount() external view returns (uint256) {
        return entryCount;
    }
}
