# BitStack

BitStack is a decentralized lending protocol built on the Stacks blockchain that enables Bitcoin-backed loans. Users can collateralize their Bitcoin to borrow assets through trustless smart contracts.

## Features

- Bitcoin-backed lending using Stacks smart contracts
- Peer-to-peer loan matching
- Customizable loan terms (duration, interest rate)
- 150% minimum collateralization ratio
- Automated interest calculation and repayment processing
- Protocol fee mechanism for sustainability

## Smart Contract Functions

### Core Functions

1. `create-loan`: Create a new loan request with specified terms
   - Parameters: amount, collateral, interest rate, duration
   - Creates a new loan entry in pending status

2. `fund-loan`: Fund an existing loan request
   - Parameters: loan-id
   - Matches a lender to a pending loan
   - Updates loan status to active

3. `repay-loan`: Repay an active loan
   - Parameters: loan-id
   - Calculates total repayment including interest
   - Updates loan status to repaid

### Read-Only Functions

1. `get-loan`: Retrieve loan details by ID
2. `get-user-loans`: Get all loans associated with a user

## Technical Details

### Collateralization

- Minimum collateral requirement: 100,000 satoshis
- Collateralization ratio: 150%
- Dynamic interest calculation based on blocks elapsed

### Security Features

- Principal-based authorization checks
- Error handling for common edge cases
- State validation before critical operations

## Development

### Prerequisites

- Clarity CLI
- Stacks blockchain local development environment
- Node.js and npm (for testing environment)

### Testing

```bash
# Run contract tests
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

