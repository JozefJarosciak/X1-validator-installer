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
cd ~ && wget -O ~/x1-install.sh https://raw.githubusercontent.com/JozefJarosciak/X1-validator-installer/master/x1-install.sh && chmod +x ~/x1-install.sh && ~/x1-install.sh


