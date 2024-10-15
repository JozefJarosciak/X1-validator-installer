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

# Section 1: Setup Validator Directory
print_color "info" "===== 1/11: Validator Directory Setup ====="

default_install_dir="$HOME/x1_validator"
print_color "prompt" "Validator Directory (default: $default_install_dir):"
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

mkdir -p "$install_dir" > /dev/null 2>&1
cd "$install_dir" || exit 1
print_color "success" "Directory created: $install_dir"


# Section 2: Install Rust
print_color "info" "\n===== 2/11: Rust Installation ====="

if ! command -v rustc &> /dev/null; then
    print_color "info" "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1
    . "$HOME/.cargo/env" > /dev/null 2>&1
else
    print_color "success" "Rust is already installed: $(rustc --version)"
fi


# Section 3: Install Solana CLI
print_color "info" "\n===== 3/11: Solana CLI Installation ====="

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


# Section 4: Switch to Xolana Network
print_color "info" "\n===== 4/11: Switch to Xolana Network ====="

solana config set -u http://xolana.xen.network:8899 > /dev/null 2>&1
network_url=$(solana config get | grep 'RPC URL' | awk '{print $NF}')
if [ "$network_url" != "http://xolana.xen.network:8899" ]; then
    print_color "error" "Failed to switch to Xolana network."
    exit 1
fi
print_color "success" "Switched to Xolana network."


# Section 5: Wallets Creation
print_color "info" "\n===== 5/11: Creating Wallets ====="

solana-keygen new --no-passphrase --outfile $install_dir/identity.json > /dev/null 2>&1
identity_pubkey=$(solana-keygen pubkey $install_dir/identity.json)
solana-keygen new --no-passphrase --outfile $install_dir/vote.json > /dev/null 2>&1
vote_pubkey=$(solana-keygen pubkey $install_dir/vote.json)
solana-keygen new --no-passphrase --outfile $install_dir/stake.json > /dev/null 2>&1
stake_pubkey=$(solana-keygen pubkey $install_dir/stake.json)

solana-keygen new --no-passphrase --outfile $HOME/.config/solana/withdrawer.json > /dev/null 2>&1
withdrawer_pubkey=$(solana-keygen pubkey $HOME/.config/solana/withdrawer.json)

print_color "success" "Wallets created successfully!"
print_color "info" "Identity: $identity_pubkey"
print_color "info" "Vote: $vote_pubkey"
print_color "info" "Stake: $stake_pubkey"


# Section 6: Request Faucet Funds
print_color "info" "\n===== 6/11: Requesting Faucet Funds ====="

request_faucet() {
    response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"pubkey\":\"$1\"}" https://xolana.xen.network/faucet)
    if echo "$response" | grep -q "Please wait"; then
        wait_message=$(echo "$response" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
        print_color "error" "Faucet request failed: $wait_message"
    elif echo "$response" | grep -q '"success":true'; then
        print_color "success" "5 SOL requested successfully."
    else
        print_color "error" "Faucet request failed. Response: $response"
    fi
}

request_faucet $identity_pubkey
print_color "info" "Waiting 30 seconds to verify balance..."
sleep 30

balance=$(solana balance $identity_pubkey)
if [ "$balance" != "0 SOL" ]; then
    print_color "success" "Identity funded with $balance."
else
    print_color "error" "Failed to get 5 SOL. Exiting."
    exit 1
fi


# Section 7: Create Vote Account
print_color "info" "\n===== 7/11: Creating Vote Account ====="

solana create-vote-account $install_dir/vote.json $install_dir/identity.json $withdrawer_pubkey --commission 5 > /dev/null 2>&1
print_color "success" "Vote account created."


# Section 8: Create and Fund Stake Account
print_color "info" "\n===== 8/11: Creating Stake Account ====="

solana create-stake-account $install_dir/stake.json 5 > /dev/null 2>&1
print_color "success" "Stake account funded with 5 SOL."


# Section 9: System Tuning
print_color "info" "\n===== 9/11: System Tuning ====="
print_color "info" "Please provide your password for system tuning."

sudo bash -c "cat >/etc/sysctl.d/21-solana-validator.conf <<EOF
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728
vm.max_map_count = 1000000
fs.nr_open = 1000000
EOF" > /dev/null 2>&1

sudo sysctl -p /etc/sysctl.d/21-solana-validator.conf > /dev/null 2>&1
print_color "success" "System tuned for validator performance."


# Section 10: Create and Start Validator Service
print_color "info" "\n===== 10/11: Creating Validator Service ====="

# Remove existing service if it exists
if sudo systemctl is-active --quiet 'x1-validator'; then
    print_color "info" "Stopping and removing existing X1 Validator service..."
    sudo systemctl stop 'x1-validator' > /dev/null 2>&1
    sudo systemctl disable 'x1-validator' > /dev/null 2>&1
    sudo rm /etc/systemd/system/x1-validator.service > /dev/null 2>&1
fi

# Create the X1 Validator service
sudo bash -c "cat >/etc/systemd/system/x1-validator.service <<EOF
[Unit]
Description=X1 Validator Service
After=network.target

[Service]
User=$USER
ExecStart=$(which solana-validator) \\
    --identity $install_dir/identity.json \\
    --vote-account $install_dir/vote.json \\
    --rpc-port 8899 \\
    --entrypoint 216.202.227.220:8001 \\
    --full-rpc-api \\
    --log - \\
    --max-genesis-archive-unpacked-size 1073741824 \\
    --no-incremental-snapshots \\
    --require-tower \\
    --enable-rpc-transaction-history \\
    --enable-extended-tx-metadata-storage \\
    --skip-startup-ledger-verification \\
    --no-poh-speed-test
Restart=always
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd, enable, and start the service
sudo systemctl daemon-reload > /dev/null 2>&1
sudo systemctl enable x1-validator > /dev/null 2>&1
sudo systemctl start x1-validator > /dev/null 2>&1

# Section 11: Validate and Final Instructions
print_color "info" "\n===== 11/11: Verifying Validator Service ====="

if sudo systemctl is-active --quiet x1-validator; then
    print_color "success" "X1 Validator service started successfully!"
else
    print_color "error" "X1 Validator service failed to start."
    exit 1
fi

print_color "info" "\n===== Validator Service Commands ====="
print_color "info" "To manage the X1 Validator service, use the following commands:"
print_color "info" "Start:   sudo systemctl start x1-validator"
print_color "info" "Stop:    sudo systemctl stop x1-validator"
print_color "info" "Restart: sudo systemctl restart x1-validator"
print_color "info" "Status:  sudo systemctl status x1-validator"

print_color "success" "\nX1 Validator setup complete!"
