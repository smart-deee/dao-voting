# DAO Voting Smart Contract

A Clarity smart contract implementing a decentralized autonomous organization (DAO) voting system with STX token-weighted voting.

## Features

- **STX Token-Weighted Voting**: Voting power is proportional to STX balance
- **Secure Deposit/Withdraw**: Members can deposit/withdraw STX tokens
- **Proposal System**: Create and vote on time-bound proposals
- **Democratic Decision Making**: Majority-based voting outcomes
- **Built-in Security**: Protection against double voting and timing attacks

## Contract Functions

### Deposit/Withdraw
```clarity
(deposit (amount uint)) -> (response bool uint)
(withdraw (amount uint)) -> (response bool uint)
```

### Proposal Management
```clarity
(create-proposal (title (string-ascii 64)) (duration uint)) -> (response uint uint)
(vote (id uint) (support bool)) -> (response bool uint)
(finalize (id uint)) -> (response bool uint)
```

## Error Codes

| Code | Description |
|------|-------------|
| `u100` | No deposit/insufficient balance |
| `u101` | Proposal not found |
| `u102` | Already voted |
| `u103` | Too early to vote/finalize |
| `u104` | Too late to vote |
| `u105` | Invalid input parameters |

## Usage Example

```clarity
;; Create a new proposal
(contract-call? .dao-voting create-proposal "Should we add feature X?" u144)

;; Deposit STX to get voting power
(contract-call? .dao-voting deposit u1000)

;; Vote on proposal
(contract-call? .dao-voting vote u1 true)

;; Finalize proposal after voting period
(contract-call? .dao-voting finalize u1)
```

## Installation

1. Clone this repository
2. Deploy using Clarinet or Stacks CLI
```bash
clarinet deploy
```

## Testing

Run the test suite using Clarinet:
```bash
clarinet test
```

## Security Considerations

- Voting power is determined by STX balance at time of vote
- Proposals have strict time boundaries
- Members can only vote once per proposal
- All operations validate inputs and state changes

## License

MIT License

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---
Built with ❤️ for the Stacks ecosystem
