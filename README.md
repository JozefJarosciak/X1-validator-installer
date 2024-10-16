# X1 Validator Installer

This script automates the installation and setup of an Xolana X1 validator node, including creation of Solana accounts and key generation, airdrops, system tuning, etc.

## Prerequisites

Ensure you have the following installed on your system:
- Linux based operating system (Tested on Ubuntu 22.04)
- Ensure your system has at least 32 GB of RAM and 500 GB SSD Drive (ideally NVME)
- Read more at: https://docs.x1.xyz/explorer

## One-Liner Installation Command

To install the X1 Validator on your machine, use the following one-liner command. This command will download the `x1-install.sh` script from the repository, make it executable, and run it:

```bash
cd ~ && wget -O ~/x1-install.sh https://raw.githubusercontent.com/JozefJarosciak/X1-validator-installer/master/x1-install.sh > /dev/null 2>&1 && chmod +x ~/x1-install.sh > /dev/null 2>&1 && ~/x1-install.sh
```

When the install is completed, run validator using the following command:

```bash
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"; ulimit -n 1000000; solana-validator --identity $HOME/x1_validator/identity.json --vote-account $HOME/x1_validator/vote.json --rpc-port 8899 --entrypoint 216.202.227.220:8001 --full-rpc-api --log - --max-genesis-archive-unpacked-size 1073741824 --no-incremental-snapshots --require-tower --enable-rpc-transaction-history --enable-extended-tx-metadata-storage --skip-startup-ledger-verification --no-poh-speed-test --bind-address 0.0.0.0
```

## One-Liner Video Demo:

One-Liner Video Demo: https://x.com/xenpub/status/1846402568030757357

## Other Resources
See your validator online: http://x1val.online/

Visit: https://xen.pub