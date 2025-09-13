#!/bin/bash
# Kogase Uninstaller Script for Linux/Mac
# This script removes Kogase Docker containers, images, volumes, and optionally the project directory

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
                                                   
Kogase Uninstaller
"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Nothing to uninstall."
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker and try again."
    echo "Linux: sudo systemctl start docker"
    echo "macOS/Windows: Start Docker Desktop"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    print_warning "Docker Compose is not installed. Skipping container cleanup."
    SKIP_DOCKER_COMPOSE=true
else
    SKIP_DOCKER_COMPOSE=false
fi

# Get the current directory (project root)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

print_info "Project directory: $PROJECT_DIR"
print_info "Project name: $PROJECT_NAME"

# Function to stop and remove Docker Compose services
cleanup_docker_compose() {
    if [[ "$SKIP_DOCKER_COMPOSE" == "true" ]]; then
        print_warning "Skipping Docker Compose cleanup (not installed)"
        return 0
    fi

    print_info "Stopping and removing Docker Compose services..."
    
    # Check if docker-compose.yaml exists
    if [[ ! -f "$PROJECT_DIR/docker-compose.yaml" ]] && [[ ! -f "$PROJECT_DIR/docker-compose.yml" ]]; then
        print_warning "No docker-compose.yaml file found. Skipping compose cleanup."
        return 0
    fi

    cd "$PROJECT_DIR"
    
    # Stop and remove containers, networks, and optionally volumes
    if docker compose ps -q &> /dev/null; then
        docker compose down --remove-orphans --volumes --timeout 30 || {
            print_warning "Failed to stop some services gracefully, attempting force removal..."
            docker compose kill || true
            docker compose rm -f || true
        }
        print_success "Docker Compose services stopped and removed"
    else
        print_info "No running Docker Compose services found"
    fi
}

# Function to remove Docker images
cleanup_docker_images() {
    print_info "Removing Docker images..."
    
    # Get project name for image filtering (Docker Compose creates images with project name prefix)
    local compose_project_name="${PROJECT_NAME,,}"  # Convert to lowercase
    
    # Find and remove images related to this project
    local images_to_remove=""
    
    # Look for images with the project name prefix
    images_to_remove=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "^${compose_project_name}[_-]" || true)
    
    # Also look for images in the current directory pattern
    if [[ -d "$PROJECT_DIR/backend" ]]; then
        images_to_remove="$images_to_remove $(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "${compose_project_name}[_-]?backend" || true)"
    fi
    
    if [[ -d "$PROJECT_DIR/frontend" ]]; then
        images_to_remove="$images_to_remove $(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "${compose_project_name}[_-]?frontend" || true)"
    fi
    
    # Remove duplicates and empty entries
    images_to_remove=$(echo "$images_to_remove" | tr ' ' '\n' | sort -u | grep -v '^$' || true)
    
    if [[ -n "$images_to_remove" ]]; then
        echo "$images_to_remove" | while IFS= read -r image; do
            if [[ -n "$image" ]]; then
                if docker rmi "$image" 2>/dev/null; then
                    print_success "Removed image: $image"
                else
                    print_warning "Failed to remove image: $image (may be in use)"
                fi
            fi
        done
    else
        print_info "No project-specific images found to remove"
    fi
    
    # Optionally remove dangling images
    local dangling_images
    dangling_images=$(docker images -f "dangling=true" -q || true)
    if [[ -n "$dangling_images" ]]; then
        echo "Found dangling images. Remove them? (y/N)"
        read -r remove_dangling
        if [[ "${remove_dangling}" =~ ^[Yy]$ ]]; then
            echo "$dangling_images" | xargs docker rmi 2>/dev/null && print_success "Removed dangling images" || print_warning "Some dangling images could not be removed"
        fi
    fi
}

# Function to remove Docker volumes
cleanup_docker_volumes() {
    print_info "Removing Docker volumes..."
    
    # Get project name for volume filtering
    local compose_project_name="${PROJECT_NAME,,}"
    
    # Find volumes with the project name prefix
    local volumes_to_remove
    volumes_to_remove=$(docker volume ls --format "{{.Name}}" | grep -E "^${compose_project_name}[_-]" || true)
    
    if [[ -n "$volumes_to_remove" ]]; then
        echo "$volumes_to_remove" | while IFS= read -r volume; do
            if [[ -n "$volume" ]]; then
                if docker volume rm "$volume" 2>/dev/null; then
                    print_success "Removed volume: $volume"
                else
                    print_warning "Failed to remove volume: $volume (may be in use)"
                fi
            fi
        done
    else
        print_info "No project-specific volumes found to remove"
    fi
    
    # Optionally remove dangling volumes
    local dangling_volumes
    dangling_volumes=$(docker volume ls -f "dangling=true" -q || true)
    if [[ -n "$dangling_volumes" ]]; then
        echo "Found dangling volumes. Remove them? (y/N)"
        read -r remove_dangling
        if [[ "${remove_dangling}" =~ ^[Yy]$ ]]; then
            echo "$dangling_volumes" | xargs docker volume rm 2>/dev/null && print_success "Removed dangling volumes" || print_warning "Some dangling volumes could not be removed"
        fi
    fi
}

# Function to remove Docker networks
cleanup_docker_networks() {
    print_info "Removing Docker networks..."
    
    # Get project name for network filtering
    local compose_project_name="${PROJECT_NAME,,}"
    
    # Find networks with the project name prefix
    local networks_to_remove
    networks_to_remove=$(docker network ls --format "{{.Name}}" | grep -E "^${compose_project_name}[_-]" || true)
    
    if [[ -n "$networks_to_remove" ]]; then
        echo "$networks_to_remove" | while IFS= read -r network; do
            if [[ -n "$network" ]] && [[ "$network" != "bridge" ]] && [[ "$network" != "host" ]] && [[ "$network" != "none" ]]; then
                if docker network rm "$network" 2>/dev/null; then
                    print_success "Removed network: $network"
                else
                    print_warning "Failed to remove network: $network (may be in use)"
                fi
            fi
        done
    else
        print_info "No project-specific networks found to remove"
    fi
}

# Function to clean up project files
cleanup_project_files() {
    print_info "Cleaning up project files..."
    
    # Remove .env file if it exists
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        rm -f "$PROJECT_DIR/.env"
        print_success "Removed .env file"
    fi
    
    # Remove any log files
    find "$PROJECT_DIR" -name "*.log" -type f -delete 2>/dev/null && print_success "Removed log files" || true
    
    # Remove any temporary files
    find "$PROJECT_DIR" -name "*.tmp" -type f -delete 2>/dev/null && print_success "Removed temporary files" || true
    
    print_success "Project files cleaned up"
}

# Function to remove entire project directory
remove_project_directory() {
    echo "This will permanently delete the entire project directory: $PROJECT_DIR"
    echo "Are you sure you want to continue? (yes/NO)"
    read -r confirm_delete
    
    if [[ "${confirm_delete}" == "yes" ]]; then
        cd "$(dirname "$PROJECT_DIR")"
        rm -rf "$PROJECT_DIR"
        print_success "Project directory removed completely"
        exit 0
    else
        print_info "Project directory removal cancelled"
    fi
}

# Main uninstall menu
show_menu() {
    echo "What would you like to uninstall?"
    echo "1) Stop and remove containers only"
    echo "2) Remove containers and images"
    echo "3) Remove containers, images, and volumes"
    echo "4) Remove containers, images, volumes, and networks"
    echo "5) Complete cleanup (containers, images, volumes, networks, and project files)"
    echo "6) Remove everything including project directory"
    echo "7) Cancel"
    echo ""
    read -p "Please select an option (1-7): " choice
}

# Check if we're in a Kogase project directory
if [[ ! -f "$PROJECT_DIR/docker-compose.yaml" ]] && [[ ! -f "$PROJECT_DIR/docker-compose.yml" ]] && [[ ! -f "$PROJECT_DIR/setup.sh" ]]; then
    print_error "This doesn't appear to be a Kogase project directory."
    print_error "Please run this script from the Kogase project root directory."
    exit 1
fi

# Handle command line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        --containers-only)
            choice=1
            ;;
        --with-images)
            choice=2
            ;;
        --with-volumes)
            choice=3
            ;;
        --with-networks)
            choice=4
            ;;
        --complete)
            choice=5
            ;;
        --remove-all)
            choice=6
            ;;
        --help|-h)
            echo "Kogase Uninstaller"
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --containers-only    Stop and remove containers only"
            echo "  --with-images        Remove containers and images"
            echo "  --with-volumes       Remove containers, images, and volumes"
            echo "  --with-networks      Remove containers, images, volumes, and networks"
            echo "  --complete           Complete cleanup (all Docker resources and project files)"
            echo "  --remove-all         Remove everything including project directory"
            echo "  --help, -h           Show this help message"
            echo ""
            echo "If no option is provided, an interactive menu will be shown."
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_error "Use --help for available options"
            exit 1
            ;;
    esac
else
    show_menu
fi

case $choice in
    1)
        print_info "Stopping and removing containers only..."
        cleanup_docker_compose
        ;;
    2)
        print_info "Removing containers and images..."
        cleanup_docker_compose
        cleanup_docker_images
        ;;
    3)
        print_info "Removing containers, images, and volumes..."
        cleanup_docker_compose
        cleanup_docker_images
        cleanup_docker_volumes
        ;;
    4)
        print_info "Removing containers, images, volumes, and networks..."
        cleanup_docker_compose
        cleanup_docker_images
        cleanup_docker_volumes
        cleanup_docker_networks
        ;;
    5)
        print_info "Performing complete cleanup..."
        cleanup_docker_compose
        cleanup_docker_images
        cleanup_docker_volumes
        cleanup_docker_networks
        cleanup_project_files
        ;;
    6)
        print_info "Removing everything including project directory..."
        cleanup_docker_compose
        cleanup_docker_images
        cleanup_docker_volumes
        cleanup_docker_networks
        remove_project_directory
        ;;
    7)
        print_info "Uninstall cancelled"
        exit 0
        ;;
    *)
        print_error "Invalid choice. Please select 1-7."
        exit 1
        ;;
esac

print_success "
============================================
Kogase uninstallation completed! 🎉
============================================
"

# Show what the user might want to do next
if [[ $choice -lt 6 ]]; then
    echo "The project directory is still available at: $PROJECT_DIR"
    echo "You can:"
    echo "  - Reinstall by running: ./setup.sh"
    echo "  - Remove the directory manually if no longer needed"
    echo "  - Run this script again with --remove-all to delete everything"
fi