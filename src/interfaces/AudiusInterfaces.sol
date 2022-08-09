// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAudiusAdminUpgradeabilityProxy {
    function implementation() external view returns (address);
}

interface IStaking {
    function initialize(
        address _tokenAddress,
        address _governanceAddress
    ) external;

    function totalStakedAt(uint256 _blockNumber) external view returns (uint256);
}

interface IDelegateManagerV2 {
    function initialize (
        address _tokenAddress,
        address _governanceAddress,
        uint256 _undelegateLockupDuration
    ) external;
    function setServiceProviderFactoryAddress(address _spFactory) external;
    function delegateStake(
        address _targetSP,
        uint256 _amount
    ) external returns (uint256);
}

enum Outcome {
	InProgress,
	Rejected,
	ApprovedExecuted,
	QuorumNotMet,
	ApprovedExecutionFailed,
	Evaluating,
	Vetoed,
	TargetContractAddressChanged,
	TargetContractCodeHashChanged
}

enum Vote {None, No, Yes}

interface IGovernance {
    function initialize(
        address _registryAddress,
        uint256 _votingPeriod,
        uint256 _executionDelay,
        uint256 _votingQuorumPercent,
        uint16 _maxInProgressProposals,
        address _guardianAddress
    )
        external;

	function submitProposal(
        bytes32 _targetContractRegistryKey,
        uint256 _callValue,
        string calldata _functionSignature,
        bytes calldata _callData,
        string calldata _name,
        string calldata _description
    ) external returns (uint256);

    function getProposalById(uint256 _proposalId) external view returns (
        uint256 proposalId,
        address proposer,
        uint256 submissionBlockNumber,
        bytes32 targetContractRegistryKey,
        address targetContractAddress,
        uint256 callValue,
        string memory functionSignature,
        bytes memory callData,
        Outcome outcome,
        uint256 voteMagnitudeYes,
        uint256 voteMagnitudeNo,
        uint256 numVotes
    );

	function evaluateProposalOutcome(uint256 _proposalId)
    external returns (Outcome);

    function submitVote(uint256 _proposalId, Vote _vote) external;

    function guardianExecuteTransaction(
        bytes32 _targetContractRegistryKey,
        uint256 _callValue,
        string calldata _functionSignature,
        bytes calldata _callData
    ) external;
}
