// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title QuantumLedger
 * @dev Multi-asset logical ledger with tagged entries per account
 * @notice Tracks arbitrary asset codes and their deltas for each address
 */
contract QuantumLedger {
    address public owner;

    // assetCode is a bytes32 identifier, e.g. keccak256("USD"), keccak256("GAME_GOLD")
    struct Entry {
        uint256 id;
        bytes32 assetCode;
        int256  delta;        // positive = credit, negative = debit
        uint256 absolute;     // absolute value of delta for easy reading
        string  note;         // optional description
        uint256 timestamp;
    }

    // account => assetCode => balance
    mapping(address => mapping(bytes32 => int256)) public balances;

    // global entry log per account
    mapping(address => Entry[]) public entriesOf;

    // global incrementing id for entries
    uint256 public nextEntryId;

    event EntryRecorded(
        address indexed account,
        uint256 indexed id,
        bytes32 indexed assetCode,
        int256 delta,
        int256 newBalance,
        string note,
        uint256 timestamp
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Record a credit (positive delta) for a specific asset and account
     * @param account Target account
     * @param assetCode Asset identifier
     * @param amount Absolute amount (will be applied as positive delta)
     * @param note Optional description
     */
    function credit(
        address account,
        bytes32 assetCode,
        uint256 amount,
        string calldata note
    ) external onlyOwner {
        require(account != address(0), "Zero address");
        require(assetCode != 0, "Invalid asset");
        require(amount > 0, "Amount = 0");

        int256 delta = int256(amount);
        _record(account, assetCode, delta, amount, note);
    }

    /**
     * @dev Record a debit (negative delta) for a specific asset and account
     * @param account Target account
     * @param assetCode Asset identifier
     * @param amount Absolute amount (will be applied as negative delta)
     * @param note Optional description
     */
    function debit(
        address account,
        bytes32 assetCode,
        uint256 amount,
        string calldata note
    ) external onlyOwner {
        require(account != address(0), "Zero address");
        require(assetCode != 0, "Invalid asset");
        require(amount > 0, "Amount = 0");

        int256 delta = -int256(amount);
        _record(account, assetCode, delta, amount, note);
    }

    function _record(
        address account,
        bytes32 assetCode,
        int256 delta,
        uint256 absolute,
        string calldata note
    ) internal {
        int256 newBal = balances[account][assetCode] + delta;
        balances[account][assetCode] = newBal;

        uint256 id = nextEntryId++;
        entriesOf[account].push(
            Entry({
                id: id,
                assetCode: assetCode,
                delta: delta,
                absolute: absolute,
                note: note,
                timestamp: block.timestamp
            })
        );

        emit EntryRecorded(
            account,
            id,
            assetCode,
            delta,
            newBal,
            note,
            block.timestamp
        );
    }

    /**
     * @dev Get all entries for an account
     * @param account Address to query
     */
    function getEntries(address account)
        external
        view
        returns (Entry[] memory)
    {
        return entriesOf[account];
    }

    /**
     * @dev Get balance of an asset for an account
     * @param account Address to query
     * @param assetCode Asset identifier
     */
    function getBalance(address account, bytes32 assetCode)
        external
        view
        returns (int256)
    {
        return balances[account][assetCode];
    }

    /**
     * @dev Transfer ownership of the QuantumLedger contract
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
