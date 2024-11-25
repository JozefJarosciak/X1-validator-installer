If you're running a validator from before Nov 13, 2024, use these upgrade instructions (otherwise ignore): 
**Transition from Old Validator to New Agave Validator**

Step-by-Step Guide

1. Clone the Agave-Xolana Repository
   Download the repository containing the updated validator software:
   ```bash
   git clone https://github.com/FairCrypto/agave-xolana.git
   cd agave-xolana
   ```

2. Switch to the Correct Branch
   Check out the branch with dynamic fee updates:
   ```bash
   git checkout dyn_fees_v1
   ```

3. Verify the Branch
   Ensure you’re on the correct branch by running:
   ```bash
   git branch
   ```
   You should see `* dyn_fees_v1` indicating that you are on the right branch.

4. Build the Validator
   Compile the validator in release mode:
   ```bash
   cargo build --release
   ```

5. Stop the Current (Old) Validator
   Make sure your existing validator process is stopped before proceeding.

6. Remove the Old Ledger Directory
   Delete the old ledger to prepare for a fresh sync:
   ```bash
   rm -rf ./ledger
   ```

7. Copy Key Files to the New Agave Directory
   Move the necessary key files from your old validator directory to the new one.
   If your old validator was in `/root/xolana` and the new validator is in `/root/agave-xolana`, use:
   ```bash
   cp /root/xolana/{identity.json,vote.json,stake.json,withdrawer.json} /root/agave-xolana/
   ```

8. Update Solana CLI Configuration
   Configure the Solana CLI to use the new RPC endpoint:
   ```bash
   solana config set -u https://xolana.xen.network
   ```
   This sets `xolana.xen.network` as the default RPC URL for CLI commands, ensuring that commands like balance checks or transactions interact with the correct server.

9. Launch the Validator
   Start the new validator from within the `agave-xolana` folder:
   ```bash
   ./target/release/agave-validator --identity identity.json --limit-ledger-size 50000000 --rpc-port 8899 --entrypoint xolana.xen.network:8001 --full-rpc-api --log - --vote-account vote.json --max-genesis-archive-unpacked-size 1073741824 --require-tower --enable-rpc-transaction-history --enable-extended-tx-metadata-storage --rpc-pubsub-enable-block-subscription
   ```

10. (Optional) Set Up the Validator as a Systemd Service
    To enable automatic startup on boot and manage the validator as a service:

    - Create a new service file:
      ```bash
      sudo nano /etc/systemd/system/solana-validator.service
      ```

    - Add the following content to the file:
      ```ini
      [Unit]
      Description=Agave Xolana Validator
      After=network.target

      [Service]
      User=root
      WorkingDirectory=/root/agave-xolana
      ExecStart=/root/agave-xolana/target/release/agave-validator         --identity identity.json         --limit-ledger-size 50000000         --rpc-port 8899         --entrypoint xolana.xen.network:8001         --full-rpc-api         --log -         --vote-account vote.json         --max-genesis-archive-unpacked-size 1073741824         --require-tower         --enable-rpc-transaction-history         --enable-extended-tx-metadata-storage         --rpc-pubsub-enable-block-subscription
      Restart=always
      RestartSec=60s

      [Install]
      WantedBy=multi-user.target
      ```

    - Reload the Systemd Daemon:
      ```bash
      sudo systemctl daemon-reload
      ```

    - Enable the Service to Start on Boot:
      ```bash
      sudo systemctl enable solana-validator.service
      ```

    - Start the Validator Service:
      ```bash
      sudo systemctl start solana-validator.service
      ```

    - Verify the Service Status:
      Check that the service is running correctly:
      ```bash
      sudo systemctl status solana-validator
      ```
