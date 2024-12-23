#!/usr/bin/env bash

# Configurable variables
REMOTE_USER="opc"                                   # Username provided by Oracle after instance creation
REMOTE_HOST="0.0.0.0"                               # Public IP of the instance
SSH_KEY="/home/user/.ssh/your_private_key"          # Path to your private SSH key


# Fixed variables - installation procedure
EXPERIMENTAL_FEATURES="--extra-experimental-features nix-command --extra-experimental-features flakes"
REMOTE_TARGET="$REMOTE_USER@$REMOTE_HOST"
PROJECT_DIR="."
BUILD_TARGET=".#ampere-install"


# Exit on any error
set -e


# --- Functions ---

# Enable public key authentication
enable_public_key_auth() {
echo "Enabling public key authentication on $REMOTE_HOST..."

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$REMOTE_TARGET" << EOF
    if sudo grep -q '^PubkeyAuthentication yes$' /etc/ssh/sshd_config; then
        echo "Public key authentication is already enabled."
    else
        if sudo grep -q '^PubkeyAuthentication no$' /etc/ssh/sshd_config; then
            sudo sed -i 's/^PubkeyAuthentication no$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        elif sudo grep -q '^#PubkeyAuthentication yes$' /etc/ssh/sshd_config; then
            sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        else
            sudo sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        fi

        sudo systemctl restart sshd
        echo "Public key authentication enabled."
    fi
EOF

echo "Public key authentication check and update complete."
}


# Test keyless authentication
test_keyless_auth() {
echo "Testing SSH authentication without a key on $REMOTE_HOST..."

ssh "$REMOTE_TARGET" "echo 'Key authentication successful'"
if [ $? -ne 0 ]; then
    echo "Error: Key authentication failed."
    exit 1
fi

echo "Key authentication successful."
}


# Check if Nix is installed on local machine, and install it if it is not present
check_nix_installation_on_local() {
echo "Checking if Nix is installed..."

if command -v nix >/dev/null 2>&1; then
    echo "Nix is already installed."
    return 0
else
    echo "Nix is not installed. Attempting to install Nix..."
    curl -L https://nixos.org/nix/install | sh
    if command -v nix >/dev/null 2>&1; then
        echo "Nix installation successful."
        return 0;
    else
        echo "Error: Unable to install Nix."
        exit 1
    fi
fi
}


# Install NixOS using nixos-anywhere
install_nixos_on_remote() {
echo "Installing NixOS on $REMOTE_HOST using nixos-anywhere..."

nix $EXPERIMENTAL_FEATURES run github:nix-community/nixos-anywhere -- \
--flake "$PROJECT_DIR/$BUILD_TARGET" \
--generate-hardware-config nixos-generate-config ./ampere-install/hardware-configuration.nix \
"$REMOTE_TARGET" \
--build-on-remote

echo "NixOS installation complete."
}


# Test NixOS installation
test_nixos() {
# Fixed variable - NixOS installation test
REMOTE_USER="root"
REMOTE_TARGET="$REMOTE_USER@$REMOTE_HOST"

echo "Deleting old key..."
ssh-keygen -R "$REMOTE_HOST"

echo "Testing NixOS installation on $REMOTE_HOST..."
MAX_TRIES=15
ATTEMPT=0

while [ "$ATTEMPT" -lt "$MAX_TRIES" ]; do
    ATTEMPT=$((ATTEMPT + 1))
    ssh -o StrictHostKeyChecking=no "$REMOTE_TARGET" "echo 'Successfully authenticated to NixOS'"
    if [ $? -eq 0 ]; then
        echo "NixOS installation test successful."
        return 0
    fi
    echo "Connection refused (attempt $ATTEMPT/$MAX_TRIES). Waiting 10 seconds..."
    sleep 10
done

echo "Error: Couldn't authenticate to NixOS after $MAX_TRIES attempts."
exit 1
}


# Update system for the first time
first_time_update() {
# Fixed variables - first-time update procedure
REMOTE_USER="root"
REMOTE_DIR="/root/build"
REMOTE_TARGET="$REMOTE_USER@$REMOTE_HOST"
BUILD_TARGET=".#ampere-config"

# Step 1: Ensure remote directory exists
echo "Creating remote directory..."
ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

# Step 2: Copy project to remote
echo "Transferring project files to the remote machine..."
rsync -avz --delete \
    --exclude=".git" \
    --exclude="result" \
    "$PROJECT_DIR/" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

# Step 3: Run build command on remote
echo "Building the project on the remote machine..."
ssh "$REMOTE_USER@$REMOTE_HOST" << EOF
    set -e
    cd "$REMOTE_DIR"

    rm -f result

    echo "Moving hardware configuration..."
    mv ampere-install/hardware-configuration.nix ampere-config/hardware-configuration.nix

    echo "Running the build command..."
    nix $EXPERIMENTAL_FEATURES flakes build "$BUILD_TARGET"

    echo "Build completed."
EOF

# Step 4: Apply new configuration on remote
echo "Applying new configuration on the remote machine..."
ssh "$REMOTE_USER@$REMOTE_HOST" << EOF
    set -e
    cd "$REMOTE_DIR"

    echo "Applying new configuration..."

    ./result/bin/switch-to-configuration switch

    echo "Configuration applied successfully."
EOF

echo "System updated successfully"
}


# --- Main ---

echo "Starting the automated NixOS setup on Oracle Cloud..."

enable_public_key_auth
test_keyless_auth
check_nix_installation_on_local
install_nixos_on_remote
test_nixos
first_time_update

echo "NixOS setup completed successfully!"