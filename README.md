# BitStack 

BitStack is a decentralized lending protocol built on the Stacks blockchain that enables Bitcoin-backed loans. Users can collateralize their Bitcoin to borrow assets through trustless smart contracts.

## Features 

- Bitcoin-backed lending using Stacks smart contracts
- Peer-to-peer loan matching
- Customizable loan terms (duration, interest rate)
- 150% minimum collateralization ratio
- Automated interest calculation and repayment processing
- Partial collateral withdrawal
- Automated liquidation mechanism
- Protocol fee mechanism for sustainability

## Smart Contract Functions

### Core Functions

1. `create-loan`: Create a new loan request with specified terms
   - Parameters: amount, collateral, interest rate, duration
   - Creates a new loan entry in pending status
   - Validates input parameters
   - Enforces minimum collateralization ratio

2. `fund-loan`: Fund an existing loan request
   - Parameters: loan-id
   - Matches a lender to a pending loan
   - Updates loan status to active
   - Prevents self-funding

3. `repay-loan`: Repay an active loan
   - Parameters: loan-id
   - Calculates total repayment including interest
   - Updates loan status to repaid

4. `withdraw-excess-collateral`: Manage collateral
   - Allows partial collateral withdrawal
   - Maintains minimum collateralization ratio
   - Provides flexibility for borrowers

5. `check-and-liquidate`: Manage loan liquidations
   - Automatically liquidates loans below 125% collateralization
   - Applies 10% liquidation penalty
   - Protects lender interests

### Read-Only Functions

1. `get-loan`: Retrieve loan details by ID
2. `get-user-loans`: Get all loans associated with a user
3. `get-liquidation`: Retrieve liquidation details

## Technical Details

### Loan Parameters
- Minimum collateral: 100,000 satoshis
- Collateralization ratio: 150% minimum
- Maximum loan duration: ~20 days
- Maximum interest rate: 10%
- Liquidation threshold: 125%
- Protocol fee: 1% (100 basis points)

### Security Features
- Principal-based authorization checks
- Comprehensive input validation
- Error handling for common edge cases
- State validation before critical operations
- Automated liquidation mechanism
- Collateral ratio protection

## Risks and Considerations
- Liquidation risk if collateral value drops
- Interest rate fluctuations
- Smart contract complexity
- Potential market volatility

## Contributing
1. Fork the repository
2. Create a feature branch
3. Implement and test changes
4. Submit a pull request
5. Ensure code quality and test coverage

