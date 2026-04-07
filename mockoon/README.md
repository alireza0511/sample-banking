# Mockoon API Mock Server

This folder contains the Mockoon environment configuration for the Kind Banking API.

## Setup

1. Install Mockoon: https://mockoon.com/download/
2. Open Mockoon
3. File → Open environment → Select `kind-banking-api.json`
4. Click the green "Start server" button

## Server Details

- **URL:** `http://localhost:3000`
- **Prefix:** `/api/v1`
- **Default latency:** 200ms

## Available Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Login with username/password |
| POST | `/api/v1/auth/logout` | Logout |

### Accounts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/accounts` | Get all accounts |
| GET | `/api/v1/accounts/:accountId` | Get account details |
| GET | `/api/v1/accounts/:accountId/transactions` | Get transactions |

### Transfers
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/transfers` | Create transfer |
| POST | `/api/v1/transfers/zelle` | Send via Zelle |
| GET | `/api/v1/payees` | Get saved payees |

### Bills
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/bills` | Get billers |
| POST | `/api/v1/bills/pay` | Pay a bill |

### Cards
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/cards` | Get all cards |
| POST | `/api/v1/cards/:cardId/toggle-freeze` | Freeze/unfreeze |
| POST | `/api/v1/cards/:cardId/reveal` | Reveal card number |

### User
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/user/profile` | Get user profile |

### Deposits
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/deposits/check` | Mobile check deposit |

## Test Login

Use these credentials to test login:
- **Username:** `demo`
- **Password:** `any`

Any other username will return a 401 error.

## CLI Usage (Optional)

```bash
# Install Mockoon CLI
npm install -g @mockoon/cli

# Run from this folder
mockoon-cli start --data kind-banking-api.json
```
