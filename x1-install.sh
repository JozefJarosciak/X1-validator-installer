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
        cd "$install_dir"
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

### Set Solana CLI to Xolana Network ###
print_color "info" "Setting Solana CLI to Xolana network..."
solana config set -u http://xolana.xen.network:8899

# Verify the network configuration
network_url=$(solana config get | grep 'RPC URL' | awk '{print $NF}')
if [ "$network_url" != "http://xolana.xen.network:8899" ]; then
    print_color "error" "Failed to switch to the Xolana network. Exiting..."
    exit 1
fi

print_color "success" "Successfully switched to Xolana network: $network_url"
print_color "info" " "

# Test Solana CLI by checking version
solana --version




# Check if Solana config directory exists, and prompt the user for removal if it does
solana_config_dir="$HOME/.config/solana"

if [ -d "$solana_config_dir" ]; then
    print_color "prompt" "The Solana configuration directory ($solana_config_dir) already exists. Would you like to remove it and create a fresh setup? [y/n]"
    read choice

    if [ "$choice" == "y" ]; then
        rm -rf "$solana_config_dir"
        print_color "info" "Deleted existing Solana configuration directory: $solana_config_dir"
    else
        print_color "error" "Installation cannot proceed without cleaning up the existing configuration. Exiting..."
        exit 1
    fi
fi


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

# Set the default keypair to the generated identity keypair
print_color "info" "Setting default keypair to the generated identity keypair..."
solana config set -k $install_dir/identity.json

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

# Check balance of the identity account
print_color "info" "Checking balance for identity account..."
balance=$(solana balance $identity_pubkey)

if [ -z "$balance" ]; then
    print_color "error" "Failed to retrieve balance for identity account. Please verify the Solana network configuration and try again."
    exit 1
fi

print_color "success" "Identity account balance: $balance"

# Request SOL from Xolana Faucet
request_faucet() {
    pubkey=$1
    print_color "info" "Requesting 5 SOL from the Xolana faucet for pubkey: $pubkey"

    # Make POST request using curl
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"pubkey\":\"$pubkey\"}" \
        https://xolana.xen.network/faucet)

    # Check if the response contains "Please wait"
    if echo "$response" | grep -q "Please wait"; then
        # Extract the full message from the response
        wait_message=$(echo "$response" | jq -r '.message')
        print_color "error" "Faucet request failed: $wait_message"
    elif echo "$response" | grep -q '"success":true'; then
        print_color "success" "Successfully requested 5 SOL from the faucet."
    else
        print_color "error" "Failed to request SOL from the faucet. Response: $response"
    fi
}

# Retry Faucet up to 3 times
attempt=1
max_attempts=1
success=false

while [ $attempt -le $max_attempts ]; do
    print_color "info" "Requesting faucet for 5 SOL (Attempt $attempt of $max_attempts)..."
    request_faucet $identity_pubkey

    # Wait 5 seconds before checking the balance
    print_color "info" "Waiting 30 seconds to verify balance..."
    sleep 30

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
    print_color "error" "Failed to get 5 SOL from the faucet. Please fund the identity account manually."
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
