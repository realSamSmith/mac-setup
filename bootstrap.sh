#!/bin/zsh

# Bootstrap script to set up a new Mac by downloading and running the Ansible playbook from GitHub
# After successful setup, it offers to clean up the cloned repository (including itself)

REPO_URL="https://github.com/realSamSmith/mac-setup.git"
REPO_DIR="mac-setup"

echo "=== Mac Setup Bootstrap Script ==="
echo "This script will:"
echo "  - Install Xcode Command Line Tools (if needed)"
echo "  - Install Homebrew (if needed)"
echo "  - Install Ansible"
echo "  - Clone your Ansible repository"
echo "  - Install required Ansible collection"
echo "  - Run the setup playbook"
echo "  - Offer to remove the temporary cloned repository"
echo ""

# Step 1: Install Xcode Command Line Tools
echo "Step 1: Installing Xcode Command Line Tools..."
if ! xcode-select -p > /dev/null; then
    xcode-select --install
	# Wait for it to finish.
	echo "The installation could take some time. Once it finishes press Enter to continue."
	read "?Press Enter to continue..."
	echo    # Adds a newline after the keypress
else
	echo "Xcode Command Line Tools already installed, moving ahead."
fi

# Step 2: Install Homebrew if not present
echo "Step 2: Installing Homebrew (if not already installed)..."
if ! command -v brew >/dev/null 2>&1; then
    echo "Downloading and installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed."
fi

# Update Homebrew
brew update

# Step 3: Install Ansible
echo "Step 3: Installing Ansible..."
brew install ansible

# Step 4: Clone the repository
echo "Step 4: Cloning your Ansible repository from $REPO_URL..."
if [[ -d "$HOME/$REPO_DIR" ]]; then
    echo "Directory $REPO_DIR already exists. Pulling latest changes..."
    cd "$HOME/$REPO_DIR"
    git pull --quiet
    cd ..
else
    git clone --quiet "$REPO_URL" "$HOME/$REPO_DIR"
fi

cd "$HOME/$REPO_DIR"

# Step 5: Install required Ansible collection
echo "Step 5: Installing community.general collection..."
ansible-galaxy collection install --quiet community.general

# Step 6: Run the playbook
echo "Step 6: Running the Ansible playbook (setup_mac.yml)..."
echo "You will be prompted for manual steps during the playbook (e.g., 1Password setup)."
echo ""

if ansible-playbook setup_mac.yml; then
    echo ""
    echo "=== Setup completed successfully! ==="
else
    echo ""
    echo "⚠️  Ansible playbook failed. Check the output above for details."
    echo "You can investigate in $HOME/$REPO_DIR or re-run the script later."
    exit 1
fi

# Step 7: Offer cleanup
echo ""
echo "Cleanup option:"
echo "The setup files were cloned to: $HOME/$REPO_DIR"
read "?Do you want to remove this temporary directory now? (y/N) " response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Removing $HOME/$REPO_DIR..."
    rm -rf "$HOME/$REPO_DIR"
    echo "Cleanup complete. All setup files have been removed."
else
    echo "Keeping the repository at $HOME/$REPO_DIR"
    echo "You can re-run the playbook anytime with:"
    echo "  cd ~/$REPO_DIR && ansible-playbook setup_mac.yml"
fi

echo ""
echo "Enjoy your newly configured Mac! 🚀"
