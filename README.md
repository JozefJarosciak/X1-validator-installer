# X1 Validator Installer

This script automates the installation and setup of an Xolana X1 validator node, including creation of Solana accounts and key generation, airdrops, system tuning, etc.

## Prerequisites

Ensure you have the following installed on your system:
- Ubuntu Linux Server
- Ensure your dedicated server has at least: 128 GB RAM & 2 TB SSD.
  - For example, Xen.pub Validator is running on the following specs:
    - CPU.............: AMD Ryzen 9 7900X 12-Core Processor
    - Memory..........: DDR5 4800MHz 128GB (4 x 32GB 4800MHz)
    - Disk 1..........: Samsung SSD 980 PRO 2TB
    - OS..............: Ubuntu 22.04.4 LTS
    - Bandwidth.......: 1GBPS (10GB Port)
- Ensure your firewall allows TCP/UDP port range 8000-10000 (otherwise X1 won't be able to communicate)

## One-Liner Installation Command

To install the X1 Validator on your machine, use the following one-liner command. This command will download the `x1-install.sh` script from the repository, make it executable, and run it:

```bash
cd ~ && wget -O ~/x1-install.sh https://raw.githubusercontent.com/JozefJarosciak/X1-validator-installer/master/x1-install.sh > /dev/null 2>&1 && chmod +x ~/x1-install.sh > /dev/null 2>&1 && ~/x1-install.sh
```

When the install is completed, run validator using the following command:

```bash
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"; ulimit -n 1000000; solana-validator --identity $HOME/x1_validator/identity.json --vote-account $HOME/x1_validator/vote.json --rpc-port 8899 --entrypoint 216.202.227.220:8001 --full-rpc-api --log - --max-genesis-archive-unpacked-size 1073741824 --no-incremental-snapshots --require-tower --enable-rpc-transaction-history --enable-extended-tx-metadata-storage --skip-startup-ledger-verification --no-poh-speed-test --bind-address 0.0.0.0
```
Note: Export PATH and ULIMIT should not be necessary, as script is also setting it during execution, but I included it just in case.

## One-Liner Video Demo:

One-Liner Video Demo: https://x.com/xenpub/status/1846402568030757357

## Other Resources
- See your validator online: http://x1val.online/
- Read Xen-Tzu's X1 Validator guide to understand how this work: https://docs.x1.xyz/explorer
- Visit: https://xen.pub