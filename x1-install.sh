#!/bin/bash

# Function to print color-coded messages
function print_color {
    case $1 in
        "info")
            echo -e "\033[1;34m$2\033[0m"  # Blue for informational
            ;;
        "success")
            echo -e "\033[1;32m$2\033[0m"  # Green for success
            ;;
        "error")
            echo -e "\033[1;31m$2\033[0m"  # Red for errors
            ;;
        "prompt")
            echo -e "\033[1;33m$2\033[0m"  # Yellow for user prompts
            ;;
    esac
}

# Automatically detect the user's home directory and suggest it as the default
default_install_dir="$HOME/validator"

# Prompt user for installation directory, with default pre-filled
print_color "prompt" "Please enter the directory where you want to install the validator setup (press Enter to use default: $default_install_dir):"
read install_dir

# If the user presses Enter without entering a directory, use the default
if [ -z "$install_dir" ]; then
    install_dir=$default_install_dir
fi

# Confirm the directory with the user
print_color "info" "Using installation directory: $install_dir"

# Create the directory if it doesn't exist
if [ ! -d "$install_dir" ]; then
    print_color "info" "Creating directory $install_dir"
    mkdir -p $install_dir
else
    print_color "info" "Directory $install_dir already exists"
fi

# Change to the installation directory
cd $install_dir

# Install Solana CLI tools from the official release
print_color "info" "Installing Solana CLI tools..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.25/install)" || {
    print_color "error" "Failed to install Solana CLI tools. Exiting..."
    exit 1
}

# Add Solana CLI to the PATH environment variable
if ! grep -q 'solana' ~/.profile; then
    print_color "info" "Adding Solana CLI to the PATH environment variable..."
    echo 'export PATH="/home/ubuntu/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.profile
    source ~/.profile
fi

# Confirm installation
solana --version
if [ $? -ne 0 ]; then
    print_color "error" "Solana CLI installation failed. Exiting..."
    exit 1
fi
print_color "success" "Solana CLI installed successfully."

# Create wallets automatically
print_color "info" "Creating identity, vote, and stake accounts..."

solana-keygen new --outfile $install_dir/identity.json
identity_pubkey=$(solana-keygen pubkey $install_dir/identity.json)
solana-keygen new --outfile $install_dir/vote.json
vote_pubkey=$(solana-keygen pubkey $install_dir/vote.json)
solana-keygen new --outfile $install_dir/stake.json
stake_pubkey=$(solana-keygen pubkey $install_dir/stake.json)

# Output wallet information
print_color "success" "Wallets created successfully!"
print_color "info" "Identity Wallet Address: $identity_pubkey"
print_color "info" "Vote Wallet Address: $vote_pubkey"
print_color "info" "Stake Wallet Address: $stake_pubkey"
print_color "info" "Private keys are stored in the following locations:"
print_color "info" "Identity Private Key: $install_dir/identity.json"
print_color "info" "Vote Private Key: $install_dir/vote.json"
print_color "info" "Stake Private Key: $install_dir/stake.json"

# Prompt the user to download and save the private keys securely
print_color "prompt" "Please download and save the private keys from the specified locations and keep them in a secure place."

# Fund the identity account (Airdrop)
print_color "info" "Requesting airdrop for identity account..."
solana airdrop 10 $identity_pubkey

# Check balance
balance=$(solana balance $identity_pubkey)
print_color "success" "Identity account funded with $balance SOL"

# Create the vote account
print_color "info" "Creating vote account..."
solana create-vote-account $install_dir/vote.json $install_dir/identity.json $identity_pubkey --commission 10

# Verify vote account creation
solana vote-account $vote_pubkey

# Create and fund the stake account
print_color "info" "Creating and funding stake account..."
solana create-stake-account $install_dir/stake.json 10

# Verify stake account creation
solana stake-account $stake_pubkey

# Delegate stake
print_color "info" "Delegating stake..."
solana delegate-stake $install_dir/stake.json $install_dir/vote.json

# Validator Setup
print_color "prompt" "Setting up your validator node. This might take some time."

nohup solana-validator \
    --identity $install_dir/identity.json \
    --limit-ledger-size 50000000 \
    --rpc-port 8899 \
    --entrypoint 216.202.227.220:8001 \
    --full-rpc-api \
    --log - \
    --vote-account $install_dir/vote.json \
    --max-genesis-archive-unpacked-size 1073741824 \
    --no-incremental-snapshots \
    --require-tower \
    --enable-rpc-transaction-history \
    --enable-extended-tx-metadata-storage \
    --skip-startup-ledger-verification \
    --no-poh-speed-test &

# Monitor the setup
print_color "info" "Checking validator logs..."
tail -f nohup.out

# Other helpful commands
print_color "info" "Use the following commands to monitor your validator:"
print_color "info" "1. solana gossip"
print_color "info" "2. solana validators"
print_color "info" "3. solana-validator --ledger ledger/ monitor"

print_color "success" "Xolana X1 validator setup complete!"
