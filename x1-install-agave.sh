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

# Section 0: Install Build Dependencies
print_color "info" "\n===== 0/13: Installing Build Dependencies ====="

print_color "info" "Updating package list..."
sudo apt-get update > /dev/null 2>&1

print_color "info" "Installing build-essential and other dependencies..."
sudo apt-get install -y build-essential libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_color "success" "Build dependencies installed successfully."
else
    print_color "error" "Failed to install build dependencies."
    exit 1
fi

# Section 1: Install Rust
print_color "info" "\n===== 1/13: Rust Installation ====="

if ! command -v rustc &> /dev/null; then
    print_color "info" "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1
    source "$HOME/.cargo/env" > /dev/null 2>&1
else
    print_color "success" "Rust is already installed: $(rustc --version)"
fi
print_color "success" "Rust installed."

# Section 2: Install Solana CLI
print_color "info" "\n===== 2/13: Solana CLI Installation ====="

print_color "info" "Installing Solana CLI..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.25/install)" > /dev/null 2>&1 || {
    print_color "error" "Solana CLI installation failed."
    exit 1
}

# Add Solana to PATH and reload
if ! grep -q 'solana' ~/.profile; then
    echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.profile
fi
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH" > /dev/null 2>&1
print_color "success" "Solana CLI installed."

# Source the profile to update the current shell
source ~/.profile

# Section 3: Setup Validator Directory
print_color "info" "\n===== 3/13: Validator Directory Setup ====="

default_install_dir="$HOME/agave-xolana"
print_color "prompt" "Validator Directory (press Enter for default: $default_install_dir):"
read install_dir

if [ -z "$install_dir" ]; then
    install_dir=$default_install_dir
fi

if [ -d "$install_dir" ]; then
    print_color "prompt" "Directory exists. Delete it? [y/n]"
    read choice
    if [ "$choice" == "y" ]; then
        rm -rf "$install_dir" > /dev/null 2>&1
        print_color "info" "Deleted $install_dir"
    else
        print_color "error" "Please choose a different directory."
        exit 1
    fi
fi

# Section 4: Clone Agave-Xolana Repository
print_color "info" "\n===== 4/13: Cloning Agave-Xolana Repository ====="

print_color "info" "Cloning Agave-Xolana repository into $install_dir..."
git clone https://github.com/FairCrypto/agave-xolana.git "$install_dir" > /dev/null 2>&1
git checkout dyn_fees_v1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_color "success" "Agave-Xolana repository cloned into $install_dir"
else
    print_color "error" "Failed to clone Agave-Xolana repository."
    exit 1
fi

cd "$install_dir" || exit 1

# Section 5: Switch to the Correct Branch
print_color "info" "\n===== 5/13: Switching to dyn_fees_v1 Branch ====="

git checkout dyn_fees_v1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_color "success" "Switched to branch dyn_fees_v1"
else
    print_color "error" "Failed to switch to branch dyn_fees_v1."
    exit 1
fi

# Section 6: Build the Validator
print_color "info" "\n===== 6/13: Building the Validator ====="

print_color "info" "Building the validator in release mode. This may take a while..."
cargo build --release > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_color "success" "Validator built successfully."
else
    print_color "error" "Failed to build the validator."
    exit 1
fi

# Section 7: Wallets Creation
print_color "info" "\n===== 7/13: Creating Wallets ====="

solana-keygen new --no-passphrase --outfile $install_dir/identity.json > /dev/null 2>&1
identity_pubkey=$(solana-keygen pubkey $install_dir/identity.json)

solana-keygen new --no-passphrase --outfile $install_dir/vote.json > /dev/null 2>&1
vote_pubkey=$(solana-keygen pubkey $install_dir/vote.json)

solana-keygen new --no-passphrase --outfile $install_dir/stake.json > /dev/null 2>&1
stake_pubkey=$(solana-keygen pubkey $install_dir/stake.json)

solana-keygen new --no-passphrase --outfile $install_dir/withdrawer.json > /dev/null 2>&1
withdrawer_pubkey=$(solana-keygen pubkey $install_dir/withdrawer.json)

# Output wallet information
print_color "success" "Wallets created successfully!"
print_color "error" "********************************************************"
print_color "info" "Identity Wallet Address: $identity_pubkey"
print_color "info" "Vote Wallet Address: $vote_pubkey"
print_color "info" "Stake Wallet Address: $stake_pubkey"
print_color "info" "Withdrawer Public Key: $withdrawer_pubkey"
print_color "info" " "
print_color "info" "Private keys are stored in the following locations:"
print_color "info" "Identity Private Key: $install_dir/identity.json"
print_color "info" "Vote Private Key: $install_dir/vote.json"
print_color "info" "Stake Private Key: $install_dir/stake.json"
print_color "info" "Withdrawer Private Key: $install_dir/withdrawer.json"
print_color "error" "********************************************************"
print_color "prompt" "IMPORTANT: After installation, make sure to save both the public addresses and private key files listed above in a secure location!"

# Section 8: Update Solana CLI Configuration
print_color "info" "\n===== 8/13: Updating Solana CLI Configuration ====="

solana config set -u https://xolana.xen.network > /dev/null 2>&1
network_url=$(solana config get | grep 'RPC URL' | awk '{print $NF}')
if [ "$network_url" != "https://xolana.xen.network" ]; then
    print_color "error" "Failed to set Solana CLI configuration."
    exit 1
fi
print_color "success" "Solana CLI configured to use https://xolana.xen.network"

# Section 9: Requesting Faucet Funds
print_color "info" "\n===== 9/13: Requesting Faucet Funds ====="

request_faucet() {
    response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"pubkey\":\"$1\"}" https://xolana.xen.network/faucet)
    if echo "$response" | grep -q "Please wait"; then
        # Extract the wait time in minutes
        wait_time=$(echo "$response" | sed -n 's/.*Please wait \([0-9]*\) minutes.*/\1/p')

        # Add 1 minute to the wait time
        wait_time=$((wait_time + 1))

        # Inform the user and wait
        print_color "error" "Faucet request failed: Please wait $wait_time minutes. The faucet is limited to 5 SOL per hour."
        print_color "info" "Waiting $wait_time minutes before retrying..."
        sleep $((wait_time * 60))

        # Retry after the wait
        request_faucet "$1"
    elif echo "$response" | grep -q '"success":true'; then
        print_color "success" "5 SOL requested successfully."
    else
        print_color "error" "Faucet request failed. Response: $response"
    fi
}

request_faucet $identity_pubkey
print_color "info" "Waiting 30 seconds to verify balance..."
sleep 30

balance=$(solana balance $identity_pubkey | awk '{print $1}')
if (( $(echo "$balance > 0" | bc -l) )); then
    print_color "success" "Identity funded with $balance SOL."
else
    print_color "error" "Failed to get SOL. Exiting."
    exit 1
fi

# Set default keypair to identity keypair
print_color "info" "Setting default keypair to identity keypair..."
solana config set --keypair $install_dir/identity.json

# Section 10: Create Vote Account with Commission 5%
print_color "info" "\n===== 10/13: Creating Vote Account ====="

solana create-vote-account $install_dir/vote.json $install_dir/identity.json $withdrawer_pubkey --commission 5
if [ $? -eq 0 ]; then
    print_color "success" "Vote account created with 5% commission."
else
    print_color "error" "Failed to create vote account."
    exit 1
fi

# Check balance after creating vote account
balance=$(solana balance $identity_pubkey | awk '{print $1}')
print_color "info" "Balance after creating vote account: $balance SOL"

# Section 11: Create and Fund Stake Account
print_color "info" "\n===== 11/13: Creating Stake Account ====="

if (( $(echo "$balance > 0.5" | bc -l) )); then
    stake_amount=$(echo "$balance - 0.5" | bc)
    print_color "info" "Staking $stake_amount SOL."

    solana create-stake-account $install_dir/stake.json $stake_amount
    if [ $? -eq 0 ]; then
        print_color "success" "Stake account created and funded with $stake_amount SOL."
    else
        print_color "error" "Failed to create and fund stake account."
        exit 1
    fi
else
    print_color "error" "Insufficient funds to create stake account."
    exit 1
fi

# Section 12: System Tuning
print_color "info" "\n===== 12/13: System Tuning ====="
print_color "info" "If needed, please provide admin password for system tuning."

sudo bash -c "cat >/etc/sysctl.d/21-solana-validator.conf <<EOF
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728
vm.max_map_count = 1000000
fs.nr_open = 1000000
EOF"
sudo sysctl -p /etc/sysctl.d/21-solana-validator.conf

# Set ulimit for current session
ulimit -n 1000000

print_color "success" "System tuned for validator performance."

# Section 13: Start the Validator
print_color "info" "\n===== 13/13: Finished ====="
print_color "success" "\nAgave Xolana Validator setup complete!"
print_color "success" "\nStart your Agave Xolana Validator by using the following command:"
print_color "prompt" "\ncd $install_dir; ulimit -n 1000000; ./target/release/agave-validator --identity $install_dir/identity.json --limit-ledger-size 50000000 --rpc-port 8899 --entrypoint xolana.xen.network:8001 --full-rpc-api --log - --vote-account $install_dir/vote.json --max-genesis-archive-unpacked-size 1073741824 --require-tower --enable-rpc-transaction-history --enable-extended-tx-metadata-storage --rpc-pubsub-enable-block-subscription --full-snapshot-interval-slots 300 --maximum-incremental-snapshots-to-retain 100 --maximum-full-snapshots-to-retain 50 --minimal-snapshot-download-speed 5000000"
print_color "info" "\n\nOptionally, you can set up the validator as a systemd service for automatic management."
