#!/bin/bash
# Kogase Installer Script for Linux/Mac
# This script clones the Kogase repository and sets up the project

# Exit on error and treat unset variables as errors
set -euo pipefail

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

echo "
██╗  ██╗ ██████╗  ██████╗  █████╗ ███████╗███████╗
██║ ██╔╝██╔═══██╗██╔════╝ ██╔══██╗██╔════╝██╔════╝
█████╔╝ ██║   ██║██║  ███╗███████║███████╗█████╗  
██╔═██╗ ██║   ██║██║   ██║██╔══██║╚════██║██╔══╝  
██║  ██╗╚██████╔╝╚██████╔╝██║  ██║███████║███████╗
╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                                   
Komu's Game Service
"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install Git and try again."
    echo "Ubuntu/Debian: sudo apt update && sudo apt install git"
    echo "CentOS/RHEL: sudo yum install git"
    echo "macOS: brew install git (or install Xcode Command Line Tools)"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker and try again."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose and try again."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker and try again."
    echo "Linux: sudo systemctl start docker"
    echo "macOS/Windows: Start Docker Desktop"
    exit 1
fi

# Check available disk space (need at least 2GB)
available_space=$(df . | awk 'NR==2 {print $4}')
if [[ $available_space -lt 2097152 ]]; then  # 2GB in KB
    print_warning "Less than 2GB of disk space available. Installation may fail."
    read -p "Do you want to continue? (y/N): " continue_install
    if [[ ! "${continue_install}" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Set the repository URL
REPO_URL="https://github.com/PA-5221600034/kogase.git"

# Ask for installation directory or use default
echo "Where would you like to install Kogase? (default: ./kogase)"
read -r INSTALL_DIR

# Handle empty input - use default if user just pressed Enter
if [[ -z "${INSTALL_DIR}" ]]; then
    INSTALL_DIR="./kogase"
fi

# Convert to absolute path for consistency
INSTALL_DIR=$(realpath "${INSTALL_DIR}" 2>/dev/null || echo "${INSTALL_DIR}")

# Validate the installation directory
if [[ "${INSTALL_DIR}" == "." || "${INSTALL_DIR}" == "./" ]]; then
    print_error "Cannot install to current directory. Please specify a subdirectory."
    exit 1
fi

# Check if directory already exists and is not empty
if [[ -d "${INSTALL_DIR}" ]] && [[ -n "$(ls -A "${INSTALL_DIR}" 2>/dev/null)" ]]; then
    print_warning "Directory '${INSTALL_DIR}' already exists and is not empty."
    echo "This may cause conflicts during installation."
    read -p "Do you want to continue? (y/N): " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled by user."
        exit 0
    fi
fi

print_info "Installing Kogase to: ${INSTALL_DIR}"

# Clone the repository
print_info "Cloning Kogase repository..."
if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
    print_error "Failed to clone repository. This could be due to:"
    echo "  - Network connectivity issues"
    echo "  - Repository access permissions"
    echo "  - Insufficient disk space"
    echo "  - Directory permissions"
    exit 1
fi

# Initialize submodules recursively
print_info "Initializing submodules..."
cd "$INSTALL_DIR" || {
    print_error "Failed to change to installation directory: $INSTALL_DIR"
    exit 1
}

if ! git submodule update --init --recursive; then
    print_warning "Failed to initialize submodules. This might be due to network issues."
    echo "You can try running 'git submodule update --init --recursive' manually later."
    # Don't exit here as submodules might be optional
fi

# Change to the installation directory
cd "$INSTALL_DIR"

# Run the setup script
print_info "Setting up Kogase..."
if [[ ! -f "setup.sh" ]]; then
    print_error "setup.sh not found in the repository. This might indicate a problem with the clone."
    exit 1
fi

chmod +x setup.sh

if ! ./setup.sh; then
    print_error "Setup script failed. Please check the error messages above."
    echo "You can try running the setup manually:"
    echo "  cd $INSTALL_DIR"
    echo "  ./setup.sh"
    exit 1
fi

print_success "
Installation complete! 🎉

To check the health of your installation:
  $ cd $INSTALL_DIR
  $ ./healthcheck.sh

To manage your Kogase installation:
  $ cd $INSTALL_DIR
  $ make help
" 