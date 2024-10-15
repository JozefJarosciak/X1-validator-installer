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
while true; do
    print_color "prompt" "Please enter the directory where you want to install the validator setup (press Enter to use default: $default_install_dir):"

    # Manually show the default directory and capture input
    read install_dir

    # If the user presses Enter without entering a directory, use the default
    if [ -z "$install_dir" ]; then
        install_dir=$default_install_dir
    fi

    # Check if directory exists
    if [ -d "$install_dir" ]; then
        print_color "prompt" "Directory $install_dir already exists. Would you like to delete it (y) or enter a different directory (n)? [y/n]"
        read choice
        if [ "$choice" == "y" ]; then
            rm -rf "$install_dir"
            print_color "info" "Deleted directory $install_dir"
            mkdir -p "$install_dir"
            break
        else
            print_color "prompt" "Please enter a different directory."
        fi
    else
        print_color "info" "Creating directory $install_dir"
        mkdir -p "$install_dir"
        break
    fi
done


# Change to the installation directory
cd $install_dir

# Check if Rust is installed, otherwise install it
if ! command -v rustc &> /dev/null; then
    print_color "info" "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    print_color "info" "Reloading PATH to include Cargo's bin directory..."
    . "$HOME/.cargo/env"
else
    print_color "success" "Rust is already installed: $(rustc --version)"
fi

# Verify Rust installation
if ! rustc --version &> /dev/null; then
    print_color "error" "Rust installation failed. Exiting..."
    exit 1
else
    print_color "success" "Rust installation successful: $(rustc --version)"
fi

# Install Solana CLI tools from the official release
print_color "info" " "
print_color "info" " "
print_color "info" "Installing Solana CLI tools..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.25/install)" || {
    print_color "error" "Failed to install Solana CLI tools. Exiting..."
    exit 1
}

# Add Solana CLI to the PATH environment variable permanently
if ! grep -q 'solana' ~/.profile; then
    print_color "info" "Adding Solana CLI to the PATH environment variable..."
    echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.profile
fi

# Reload PATH in the current shell to make Solana commands immediately available
print_color "info" "Updating PATH for the current shell session..."
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Confirm installation
if ! command -v solana &> /dev/null; then
    print_color "error" "Solana CLI installation failed. Please try closing and reopening your terminal or manually running the following command to update your PATH:"
    print_color "info" 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"'
    exit 1
fi

print_color "success" "Solana CLI installed successfully."
print_color "info" " "
print_color "info" " "
# Create wallets automatically
print_color "info" "Creating identity, vote, and stake accounts..."

# Automatically generate identity, vote, and stake keypairs without asking for passphrases
solana-keygen new --no-passphrase --outfile $install_dir/identity.json
identity_pubkey=$(solana-keygen pubkey $install_dir/identity.json)

solana-keygen new --no-passphrase --outfile $install_dir/vote.json
vote_pubkey=$(solana-keygen pubkey $install_dir/vote.json)

solana-keygen new --no-passphrase --outfile $install_dir/stake.json
stake_pubkey=$(solana-keygen pubkey $install_dir/stake.json)

solana-keygen new --no-passphrase --outfile $HOME/.config/solana/withdrawer.json
withdrawer_pubkey=$(solana-keygen pubkey $HOME/.config/solana/withdrawer.json)

# Output wallet information
print_color "success" "Wallets created successfully!"
print_color "error" "********************************************************"
print_color "info" "Identity Wallet Address: $identity_pubkey"
print_color "info" "Vote Wallet Address: $vote_pubkey"
print_color "info" "Stake Wallet Address: $stake_pubkey"
print_color "info" "Withdrawer Public Key: $withdrawer_pubkey"
print_color "info" "Private keys are stored in the following locations:"
print_color "info" "Identity Private Key: $install_dir/identity.json"
print_color "info" "Vote Private Key: $install_dir/vote.json"
print_color "info" "Stake Private Key: $install_dir/stake.json"
print_color "error" "********************************************************"
print_color "prompt" "Please take note of the addresses above and save the private keys securely."

# Retry Airdrop up to 3 times
attempt=1
max_attempts=3
success=false

while [ $attempt -le $max_attempts ]; do
    print_color "info" "Requesting airdrop of 10 SOL (Attempt $attempt of $max_attempts)..."
    solana airdrop 10 $identity_pubkey

    # Wait 5 seconds before checking the balance
    print_color "info" "Waiting 5 seconds to verify airdrop..."
    sleep 5

    balance=$(solana balance $identity_pubkey)

    if [ "$balance" != "0 SOL" ]; then
        print_color "success" "Identity account funded with $balance SOL"
        success=true
        break
    fi

    attempt=$((attempt + 1))
    sleep 5  # Wait 5 seconds before retrying
done

if [ "$success" = false ]; then
    print_color "error" "Failed to get airdrop. Please fund the identity account manually."
    exit 1
fi

# Create the vote account with a different withdrawer pubkey
print_color "info" "Creating vote account..."
solana create-vote-account $install_dir/vote.json $install_dir/identity.json $withdrawer_pubkey --commission 10

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

# System Tuning
print_color "info" "Tuning system for Solana validator performance..."

sudo bash -c "cat >/etc/sysctl.d/21-solana-validator.conf <<EOF
# Increase UDP buffer sizes
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728

# Increase memory mapped files limit
vm.max_map_count = 1000000

# Increase number of allowed open file descriptors
fs.nr_open = 1000000
EOF"

sudo sysctl -p /etc/sysctl.d/21-solana-validator.conf

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
