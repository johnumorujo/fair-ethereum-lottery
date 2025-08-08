# 🎟️ Raffle Smart Contract

A fully on-chain Ethereum raffle system built in Solidity. Participants can enter the raffle by sending ETH, and a verifiably random winner is chosen using Chainlink VRF for fairness and transparency.

This project uses **Foundry** as the development framework and includes a `Makefile` for easy commands.

---

## ✨ Features

- Secure and transparent raffle entry system

- Random winner selection powered by **Chainlink VRF**

- Automatic payout to the winner

- Configurable **entry fee** and **raffle duration**

- Gas-optimized and written with security best practices

---

## 🛠 Tech Stack

- **Solidity** – Smart contract language

- **Chainlink VRF** – Verifiable randomness

- **Foundry** – Testing and deployment

- **Make** – Command shortcuts

  ***

## 📦 Installation

1. Clone the repository:

```bash

git clone https://github.com/johnumorujo/raffle-contract.git

cd raffle-contract

```

2. Install dependencies:

```bash

make install

```

---

## ⚙️ Environment Variables

Create a `.env` file in the project root:

```ini

ETH_SEPOLIA=https://sepolia.infura.io/v3/<YOUR_INFURA_KEY>

ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_KEY>

```

---

## 🚀 Make Commands

| Command               | Description                                           |
| --------------------- | ----------------------------------------------------- |
| `make build`          | 🛠 Compile the contracts                               |
| `make test`           | 🧪 Run the Foundry tests                              |
| `make install`        | 📦 Install all dependencies                           |
| `make deploy-anvil`   | 🖥 Deploy to a local Anvil instance                    |
| `make deploy-sepolia` | 🌐 Deploy to Sepolia testnet (requires `.env` config) |

---

## 🧪 Local Testing

1. Start a local Anvil blockchain:
      ```bash

anvil

````

2. In a new terminal, deploy the contract:
      ```bash

make deploy-anvil

````

---

## 🔗 Sepolia Deployment

To deploy to Sepolia:

```bash

make deploy-sepolia

```

Make sure `.env` contains your RPC URL and Etherscan API key.

## 📄 License

This project is licensed under the MIT License.
