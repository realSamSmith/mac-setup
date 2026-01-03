#!/usr/bin/env zsh
# =============================================================================
# Mac Setup Bootstrap Script
# =============================================================================
# This script fully automates the initial setup of a new Mac by:
# 1. Installing Xcode Command Line Tools (automatically waits until done)
# 2. Installing Homebrew (if missing)
# 3. Installing Ansible via Homebrew
# 4. Cloning your "mac-setup" repository from GitHub
# 5. Running your main Ansible playbook
# 6. Offering to clean up the temporary cloned repo
#
# No manual key presses required except during interactive playbook steps
# (e.g., signing into 1Password).
# =============================================================================

REPO_URL="https://github.com/realSamSmith/mac-setup.git"
REPO_DIR="$HOME/mac-setup"

echo "=== Mac Setup Bootstrap ==="
echo "This script will prepare your Mac with all required tools and run your configuration."
echo

# -----------------------------------------------------------------------------
# Step 1: Install Xcode Command Line Tools (with automatic wait)
# -----------------------------------------------------------------------------
echo "Step 1: Ensuring Xcode Command Line Tools are installed..."

if xcode-select -p &>/dev/null; then
    echo "   ✓ Xcode Command Line Tools already installed."
else
    echo "   Installing Xcode Command Line Tools..."
    xcode-select --install

    # Wait until the tools are actually installed
    echo "   Waiting for installation to complete..."
    while ! xcode-select -p &>/dev/null; do
        sleep 10
    done
    echo "   ✓ Xcode Command Line Tools installed successfully."
fi

# -----------------------------------------------------------------------------
# Step 2: Install and update Homebrew
# -----------------------------------------------------------------------------
echo "Step 2: Ensuring Homebrew is installed and up to date..."

if command -v brew &>/dev/null; then
    echo "   ✓ Homebrew already installed."
else
    echo "   Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Activate Homebrew in the current shell session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    echo "   ✓ Homebrew installed."
fi

echo "   Updating Homebrew..."
brew update --quiet

# -----------------------------------------------------------------------------
# Step 3: Install Ansible
# -----------------------------------------------------------------------------
echo "Step 3: Ensuring Ansible is installed..."

if command -v ansible &>/dev/null; then
    echo "   ✓ Ansible already installed."
else
    echo "   Installing Ansible via Homebrew..."
    brew install ansible
    echo "   ✓ Ansible installed."
fi

# -----------------------------------------------------------------------------
# Step 4: Clone or update the mac-setup repository
# -----------------------------------------------------------------------------
echo "Step 4: Fetching your setup repository..."

if [[ -d "$REPO_DIR" ]]; then
    echo "   Repository exists — updating with latest changes..."
    (cd "$REPO_DIR" && git pull --quiet)
else
    echo "   Cloning repository from GitHub..."
    git clone --quiet "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR" || { echo "Failed to enter $REPO_DIR"; exit 1; }

# -----------------------------------------------------------------------------
# Step 5: Run the main Ansible playbook
# -----------------------------------------------------------------------------
echo "Step 5: Running your Mac setup playbook..."
echo "   Note: You will be prompted for manual steps (e.g., signing into 1Password)."
echo

if ansible-playbook setup_mac.yml; then
    echo
    echo "=== Setup completed successfully! ==="
else
    echo
    echo "⚠️  The Ansible playbook failed. See output above for details."
    echo "   You can debug or re-run later from: $REPO_DIR"
    exit 1
fi

# -----------------------------------------------------------------------------
# Step 7: Offer to clean up the cloned repository
# -----------------------------------------------------------------------------
echo
echo "Cleanup:"
echo "   The setup files are located at: $REPO_DIR"

read -q "response?Remove this temporary directory now? (y/N) "
echo
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "   Removing $REPO_DIR and Ansible cache..."
    rm -rf "$REPO_DIR" "$HOME/.ansible"
    echo "   Cleanup complete."
else
    echo "   Repository preserved at $REPO_DIR"
    echo "   To re-run the setup later:"
    echo "       cd $REPO_DIR && ansible-playbook setup_mac.yml"
fi

echo
echo "Enjoy your freshly configured Mac! 🚀"
