# X1 Validator Installer

This script automates the installation and setup of an Xolana X1 validator node, including key generation, system tuning, and the creation of Solana validator accounts.

## Prerequisites

Ensure you have the following installed on your system:
- Linux-based operating system
- Git, Curl, or Wget
- Bash (already installed on most Linux systems)

## One-Liner Installation Command

To install the X1 Validator on your machine, use the following one-liner command. This command will download the `x1-install.sh` script from the repository, make it executable, and run it:

```bash
cd ~ && wget -O ~/x1-install.sh https://raw.githubusercontent.com/JozefJarosciak/X1-validator-installer/master/x1-install.sh > /dev/null 2>&1 && chmod +x ~/x1-install.sh > /dev/null 2>&1 && ~/x1-install.sh
```

When the install is completed, run validator using the following command:

```bash
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"; ulimit -n 1000000; solana-validator --identity $HOME/x1_validator/identity.json --vote-account $HOME/x1_validator/vote.json --rpc-port 8899 --entrypoint 216.202.227.220:8001 --full-rpc-api --log - --max-genesis-archive-unpacked-size 1073741824 --no-incremental-snapshots --require-tower --enable-rpc-transaction-history --enable-extended-tx-metadata-storage --skip-startup-ledger-verification --no-poh-speed-test --bind-address 0.0.0.0
```