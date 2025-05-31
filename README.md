# Forest Carbon Credits

A Clarity smart contract for managing carbon credit issuance and trading for forest conservation projects on the Stacks blockchain.

## Features

- Register forest conservation projects
- Issue carbon credits for verified projects
- Purchase and trade carbon credits
- Track user balances and project verification status

## Contract Functions

### Public Functions

- `register-forest-project(project-name, initial-credits)` - Register a new forest project
- `verify-project(project-id)` - Verify a project (owner only)
- `purchase-credits(project-id, amount)` - Purchase carbon credits

### Read-Only Functions

- `get-project-info(project-id)` - Get project details
- `get-user-balance(user, project-id)` - Get user's credit balance
- `get-total-projects()` - Get total number of projects

## Usage

1. Deploy the contract
2. Register forest projects using `register-forest-project`
3. Verify projects using `verify-project`
4. Users can purchase credits using `purchase-credits`

## Testing

Run tests with Clarinet:
\`\`\`bash
clarinet test
\`\`\`

## License

MIT License