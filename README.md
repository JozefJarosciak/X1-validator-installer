
# X1 Validator Installer

This script automates the installation and setup of an Xolana X1 validator node, including creation of Solana accounts and key generation, airdrops, system tuning, etc.

&nbsp;
<hr>
&nbsp;


## ⚙️ Prerequisites

### OS Requirements:
Ensure you have the following installed on your system:
- **Ubuntu Linux Server** (ideally 22.04+)
&nbsp;

### Hardware Requirements:
- **CPU**: AMD Ryzen 9 7900X 12-Core Processor (or equivalent)
- **Memory (RAM)**: 128 GB DDR5 4800MHz (e.g., 4 x 32GB 4800MHz)
- **Hard Disk**: 2 TB SSD (e.g., Samsung SSD 980 PRO 2TB)
- **OS**: Ubuntu 22.04.4 LTS
- **Bandwidth**: 1 Gbps (10 Gbps Port recommended)
&nbsp;

### **Increase `ulimit` Limits on Ubuntu Configuration**
Validators on X1 (a Solana-based network) require high performance and need to handle numerous concurrent connections, transactions, and on-chain operations.
Thus, it is essential to raise the `ulimit` (open file descriptor limit) to ensure your validator can run reliably under high load.
Note: The script tries to automate this, but it's not always successful!

Edit the limits.conf and modify security limits configuration:
```bash
sudo nano /etc/security/limits.conf
```

Add to the bottom of the file, save & reboot server before installation:
```bash
ubuntu  soft  nofile  1000000
ubuntu  hard  nofile  1000000
```

These settings ensure that the validator can open up to 1,000,000 files and network sockets when needed, preventing bottlenecks.
&nbsp;

### Firewall Configuration:
Ensure your firewall allows **TCP/UDP port range 8000-10000** (otherwise X1 won't be able to communicate)

The firewall configuration should look something like this:

![image](https://github.com/user-attachments/assets/99f51fec-d7fd-4437-ae6c-91fa3fec288f)



&nbsp;
<hr>
&nbsp;


## 🛠️ One-Liner Installation Command

To install the X1 Validator on your machine, use the following one-liner command. This command will download the `x1-install.sh` script from the repository, make it executable, and run it:

```bash
cd ~ && wget -O ~/x1-install.sh https://raw.githubusercontent.com/JozefJarosciak/X1-validator-installer/master/x1-install.sh > /dev/null 2>&1 && chmod +x ~/x1-install.sh > /dev/null 2>&1 && ~/x1-install.sh
```

When the installation is completed, you can start your validator using the following command:

```bash
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
ulimit -n 1000000
solana-validator --identity $HOME/x1_validator/identity.json --vote-account $HOME/x1_validator/vote.json --rpc-port 8899 --entrypoint 216.202.227.220:8001 --full-rpc-api --log - --max-genesis-archive-unpacked-size 1073741824 --no-incremental-snapshots --require-tower --enable-rpc-transaction-history --enable-extended-tx-metadata-storage --skip-startup-ledger-verification --no-poh-speed-test --bind-address 0.0.0.0
```

**Note:**
- The `export PATH` and `ulimit` commands are included to ensure the environment is correctly set up when starting the validator. The script sets these during execution, but including them here ensures they are set if you start a new shell session.
- **Important**: During installation, you’ll see a screen displaying the locations of your key files. **Make sure to back up your keys** from the displayed locations after installation.

&nbsp;
<hr>
&nbsp;


## 🚀 Running the Validator

As part of the setup, the script attempts to **request 5 SOL (XN)** into the **identity wallet** using the **Xolana network faucet** at: [https://xolana.xen.network/web_faucet](https://xolana.xen.network/web_faucet).

**Note:** The faucet has a limitation of **5 SOL (XN) per hour per account**.

This SOL (XN) in the identity wallet is required to:

- **Cover transaction fees** (e.g., votes, on-chain operations)
- **Initialize accounts** like the vote and stake accounts


### Staking with Available SOL (XN)

After creating the vote account, the script automatically stakes the **maximum available SOL (XN)**, leaving a small buffer (e.g., **0.5 SOL (XN)**) for transaction fees. This means the initial stake amount may be less than the recommended amount due to faucet limitations.

You can **start the validator** with this initial stake, but to maximize participation and potential rewards, you may want to **increase your stake later**.


### Increasing Your Stake

To increase your stake:

1. **Wait for the faucet cooldown** (typically **1 hour per account**) and request additional SOL (XN) from the faucet.

2. **Fund your identity wallet** with the additional SOL (XN) by running:

   ```bash
   # Request additional SOL (XN) from the faucet
   curl -s -X POST -H "Content-Type: application/json" -d "{"pubkey":"<your_identity_pubkey>"}" https://xolana.xen.network/faucet
   ```

   Replace `<your_identity_pubkey>` with your actual identity public key.

3. **Delegate the additional SOL (XN)** to your existing stake account or create a new stake account:

   ```bash
   # Check your current balance
   solana balance $HOME/x1_validator/identity.json

   # Create a new stake account (optional)
   solana-keygen new --no-passphrase --outfile $HOME/x1_validator/new_stake.json
   solana create-stake-account $HOME/x1_validator/new_stake.json <amount_to_stake>

   # Delegate stake to your vote account
   solana delegate-stake $HOME/x1_validator/new_stake.json $HOME/x1_validator/vote.json
   ```

   **Note:** Replace `<amount_to_stake>` with the amount you wish to stake.


### SOL (XN) - Distribution Recommendations

- **Identity Wallet**: Keep at least **0.5 SOL (XN)** to cover fees for essential operations.
- **Stake Account**: Stake as much SOL (XN) as possible to maximize rewards, considering the faucet limitations.


&nbsp;
<hr>
&nbsp;


## 🎥 One-Liner Video Demo
One-Liner Video Demo: [https://x.com/xenpub/status/1846402568030757357](https://x.com/xenpub/status/1846402568030757357)

&nbsp;
<hr>
&nbsp;


## 📜 Licensing (MIT)

This project is licensed under the **MIT License**.

**MIT License Summary:**
- You can do almost anything with this code, as long as you provide proper attribution.
- The software is provided "as is," without warranty of any kind, express or implied.

&nbsp;
<hr>
&nbsp;


## 🤝 Contributing & Feedback

This script has been updated to handle faucet limitations and dynamically adjust the staking amount based on the available balance. While the script aims to provide a seamless installation experience, **it may contain bugs or edge cases** that have not been considered yet.

We encourage developers to **review the code** thoroughly and report or correct any mistakes they find.

If you have any suggestions for improvement or new features, please feel free to:
1. **Submit an issue** with detailed descriptions of the problem.
2. **Create a pull request** with your improvements to make the script more stable for everyone.
3. Help expand the functionality by **adding commits** that enhance performance, stability, or flexibility.

Together, we can **refine this project and make it more robust** over time!

Thank you for your contributions, reviews, and suggestions. Every bit of feedback helps the community!

&nbsp;
<hr>
&nbsp;


## 📚 Other Resources
- See your validator online: [http://x1val.online/](http://x1val.online/)
- Read Xen-Tzu's X1 Validator guide to understand how all this works: [https://docs.x1.xyz/explorer](https://docs.x1.xyz/explorer)
- X1 vs SOLANA: [https://x.com/xenpub/status/1843837470821281953](https://x.com/xenpub/status/1843837470821281953)
- If you'd like to help, donate here: [https://xen.pub/donate.php](https://xen.pub/donate.php)
