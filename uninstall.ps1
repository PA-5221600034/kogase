# Kogase Uninstaller Script for Windows
# This script removes Kogase Docker containers, images, volumes, and optionally the project directory

param(
    [switch]$ContainersOnly,
    [switch]$WithImages,
    [switch]$WithVolumes,
    [switch]$WithNetworks,
    [switch]$Complete,
    [switch]$RemoveAll,
    [switch]$Help
)

# Color functions for better output
function Write-Error-Color {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Warning-Color {
    param([string]$Message)
    Write-Host "Warning: $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Blue
}

Write-Host @"
██╗  ██╗ ██████╗  ██████╗  █████╗ ███████╗███████╗
██║ ██╔╝██╔═══██╗██╔════╝ ██╔══██╗██╔════╝██╔════╝
█████╔╝ ██║   ██║██║  ███╗███████║███████╗█████╗  
██╔═██╗ ██║   ██║██║   ██║██╔══██║╚════██║██╔══╝  
██║  ██╗╚██████╔╝╚██████╔╝██║  ██║███████║███████╗
╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                                   
Kogase Uninstaller
"@ -ForegroundColor Cyan

# Check if Docker is installed and running
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error-Color "Docker is not installed. Nothing to uninstall."
    exit 1
}

try {
    docker info | Out-Null
} catch {
    Write-Error-Color "Docker daemon is not running. Please start Docker Desktop and try again."
    exit 1
}

# Check if Docker Compose is installed
$SkipDockerCompose = $false
if (-not (Get-Command "docker compose" -ErrorAction SilentlyContinue)) {
    Write-Warning-Color "Docker Compose is not installed. Skipping container cleanup."
    $SkipDockerCompose = $true
}

# Get the current directory (project root)
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectName = Split-Path -Leaf $ProjectDir

Write-Info "Project directory: $ProjectDir"
Write-Info "Project name: $ProjectName"

# Function to stop and remove Docker Compose services
function Cleanup-DockerCompose {
    if ($SkipDockerCompose) {
        Write-Warning-Color "Skipping Docker Compose cleanup (not installed)"
        return
    }

    Write-Info "Stopping and removing Docker Compose services..."
    
    # Check if docker-compose.yaml exists
    if (-not (Test-Path "$ProjectDir\docker-compose.yaml") -and -not (Test-Path "$ProjectDir\docker-compose.yml")) {
        Write-Warning-Color "No docker-compose.yaml file found. Skipping compose cleanup."
        return
    }

    Set-Location $ProjectDir
    
    try {
        # Check if services are running
        $runningServices = docker compose ps -q 2>$null
        if ($runningServices) {
            docker compose down --remove-orphans --volumes --timeout 30
            Write-Success "Docker Compose services stopped and removed"
        } else {
            Write-Info "No running Docker Compose services found"
        }
    } catch {
        Write-Warning-Color "Failed to stop some services gracefully, attempting force removal..."
        try {
            docker compose kill
            docker compose rm -f
        } catch {
            Write-Warning-Color "Force removal also failed: $_"
        }
    }
}

# Function to remove Docker images
function Cleanup-DockerImages {
    Write-Info "Removing Docker images..."
    
    $composeProjectName = $ProjectName.ToLower()
    
    # Find and remove images related to this project
    try {
        $allImages = docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
        $projectImages = $allImages | Where-Object { $_ -match "^$composeProjectName[_-]" }
        
        # Also look for backend/frontend images
        if (Test-Path "$ProjectDir\backend") {
            $backendImages = $allImages | Where-Object { $_ -match "$composeProjectName.*backend" }
            $projectImages += $backendImages
        }
        
        if (Test-Path "$ProjectDir\frontend") {
            $frontendImages = $allImages | Where-Object { $_ -match "$composeProjectName.*frontend" }
            $projectImages += $frontendImages
        }
        
        $projectImages = $projectImages | Sort-Object -Unique | Where-Object { $_ -ne "" }
        
        if ($projectImages) {
            foreach ($image in $projectImages) {
                try {
                    docker rmi $image 2>$null
                    Write-Success "Removed image: $image"
                } catch {
                    Write-Warning-Color "Failed to remove image: $image (may be in use)"
                }
            }
        } else {
            Write-Info "No project-specific images found to remove"
        }
        
        # Optionally remove dangling images
        $danglingImages = docker images -f "dangling=true" -q 2>$null
        if ($danglingImages) {
            $removeDangling = Read-Host "Found dangling images. Remove them? (y/N)"
            if ($removeDangling -match "^[Yy]$") {
                try {
                    $danglingImages | ForEach-Object { docker rmi $_ 2>$null }
                    Write-Success "Removed dangling images"
                } catch {
                    Write-Warning-Color "Some dangling images could not be removed"
                }
            }
        }
    } catch {
        Write-Warning-Color "Error during image cleanup: $_"
    }
}

# Function to remove Docker volumes
function Cleanup-DockerVolumes {
    Write-Info "Removing Docker volumes..."
    
    $composeProjectName = $ProjectName.ToLower()
    
    try {
        $allVolumes = docker volume ls --format "{{.Name}}" 2>$null
        $projectVolumes = $allVolumes | Where-Object { $_ -match "^$composeProjectName[_-]" }
        
        if ($projectVolumes) {
            foreach ($volume in $projectVolumes) {
                try {
                    docker volume rm $volume 2>$null
                    Write-Success "Removed volume: $volume"
                } catch {
                    Write-Warning-Color "Failed to remove volume: $volume (may be in use)"
                }
            }
        } else {
            Write-Info "No project-specific volumes found to remove"
        }
        
        # Optionally remove dangling volumes
        $danglingVolumes = docker volume ls -f "dangling=true" -q 2>$null
        if ($danglingVolumes) {
            $removeDangling = Read-Host "Found dangling volumes. Remove them? (y/N)"
            if ($removeDangling -match "^[Yy]$") {
                try {
                    $danglingVolumes | ForEach-Object { docker volume rm $_ 2>$null }
                    Write-Success "Removed dangling volumes"
                } catch {
                    Write-Warning-Color "Some dangling volumes could not be removed"
                }
            }
        }
    } catch {
        Write-Warning-Color "Error during volume cleanup: $_"
    }
}

# Function to remove Docker networks
function Cleanup-DockerNetworks {
    Write-Info "Removing Docker networks..."
    
    $composeProjectName = $ProjectName.ToLower()
    
    try {
        $allNetworks = docker network ls --format "{{.Name}}" 2>$null
        $projectNetworks = $allNetworks | Where-Object { 
            $_ -match "^$composeProjectName[_-]" -and 
            $_ -ne "bridge" -and 
            $_ -ne "host" -and 
            $_ -ne "none" 
        }
        
        if ($projectNetworks) {
            foreach ($network in $projectNetworks) {
                try {
                    docker network rm $network 2>$null
                    Write-Success "Removed network: $network"
                } catch {
                    Write-Warning-Color "Failed to remove network: $network (may be in use)"
                }
            }
        } else {
            Write-Info "No project-specific networks found to remove"
        }
    } catch {
        Write-Warning-Color "Error during network cleanup: $_"
    }
}

# Function to clean up project files
function Cleanup-ProjectFiles {
    Write-Info "Cleaning up project files..."
    
    # Remove .env file if it exists
    if (Test-Path "$ProjectDir\.env") {
        Remove-Item "$ProjectDir\.env" -Force
        Write-Success "Removed .env file"
    }
    
    # Remove any log files
    try {
        Get-ChildItem -Path $ProjectDir -Filter "*.log" -Recurse | Remove-Item -Force
        Write-Success "Removed log files"
    } catch {
        # Ignore if no log files found
    }
    
    # Remove any temporary files
    try {
        Get-ChildItem -Path $ProjectDir -Filter "*.tmp" -Recurse | Remove-Item -Force
        Write-Success "Removed temporary files"
    } catch {
        # Ignore if no temp files found
    }
    
    Write-Success "Project files cleaned up"
}

# Function to remove entire project directory
function Remove-ProjectDirectory {
    Write-Host "This will permanently delete the entire project directory: $ProjectDir" -ForegroundColor Red
    $confirmDelete = Read-Host "Are you sure you want to continue? (yes/NO)"
    
    if ($confirmDelete -eq "yes") {
        Set-Location (Split-Path -Parent $ProjectDir)
        Remove-Item -Path $ProjectDir -Recurse -Force
        Write-Success "Project directory removed completely"
        exit 0
    } else {
        Write-Info "Project directory removal cancelled"
    }
}

# Function to show menu
function Show-Menu {
    Write-Host "What would you like to uninstall?"
    Write-Host "1) Stop and remove containers only"
    Write-Host "2) Remove containers and images"
    Write-Host "3) Remove containers, images, and volumes"
    Write-Host "4) Remove containers, images, volumes, and networks"
    Write-Host "5) Complete cleanup (containers, images, volumes, networks, and project files)"
    Write-Host "6) Remove everything including project directory"
    Write-Host "7) Cancel"
    Write-Host ""
    $choice = Read-Host "Please select an option (1-7)"
    return $choice
}

# Check if we're in a Kogase project directory
if (-not (Test-Path "$ProjectDir\docker-compose.yaml") -and 
    -not (Test-Path "$ProjectDir\docker-compose.yml") -and 
    -not (Test-Path "$ProjectDir\setup.sh") -and
    -not (Test-Path "$ProjectDir\setup.ps1")) {
    Write-Error-Color "This doesn't appear to be a Kogase project directory."
    Write-Error-Color "Please run this script from the Kogase project root directory."
    exit 1
}

# Handle command line parameters or show help
if ($Help) {
    Write-Host "Kogase Uninstaller"
    Write-Host "Usage: .\uninstall.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -ContainersOnly      Stop and remove containers only"
    Write-Host "  -WithImages          Remove containers and images"
    Write-Host "  -WithVolumes         Remove containers, images, and volumes"
    Write-Host "  -WithNetworks        Remove containers, images, volumes, and networks"
    Write-Host "  -Complete            Complete cleanup (all Docker resources and project files)"
    Write-Host "  -RemoveAll           Remove everything including project directory"
    Write-Host "  -Help                Show this help message"
    Write-Host ""
    Write-Host "If no option is provided, an interactive menu will be shown."
    exit 0
}

# Determine choice based on parameters
$choice = 0
if ($ContainersOnly) { $choice = 1 }
elseif ($WithImages) { $choice = 2 }
elseif ($WithVolumes) { $choice = 3 }
elseif ($WithNetworks) { $choice = 4 }
elseif ($Complete) { $choice = 5 }
elseif ($RemoveAll) { $choice = 6 }
else { $choice = Show-Menu }

switch ($choice) {
    1 {
        Write-Info "Stopping and removing containers only..."
        Cleanup-DockerCompose
    }
    2 {
        Write-Info "Removing containers and images..."
        Cleanup-DockerCompose
        Cleanup-DockerImages
    }
    3 {
        Write-Info "Removing containers, images, and volumes..."
        Cleanup-DockerCompose
        Cleanup-DockerImages
        Cleanup-DockerVolumes
    }
    4 {
        Write-Info "Removing containers, images, volumes, and networks..."
        Cleanup-DockerCompose
        Cleanup-DockerImages
        Cleanup-DockerVolumes
        Cleanup-DockerNetworks
    }
    5 {
        Write-Info "Performing complete cleanup..."
        Cleanup-DockerCompose
        Cleanup-DockerImages
        Cleanup-DockerVolumes
        Cleanup-DockerNetworks
        Cleanup-ProjectFiles
    }
    6 {
        Write-Info "Removing everything including project directory..."
        Cleanup-DockerCompose
        Cleanup-DockerImages
        Cleanup-DockerVolumes
        Cleanup-DockerNetworks
        Remove-ProjectDirectory
    }
    7 {
        Write-Info "Uninstall cancelled"
        exit 0
    }
    default {
        Write-Error-Color "Invalid choice. Please select 1-7."
        exit 1
    }
}

Write-Success @"
============================================
Kogase uninstallation completed! 🎉
============================================
"@

# Show what the user might want to do next
if ($choice -lt 6) {
    Write-Host "The project directory is still available at: $ProjectDir"
    Write-Host "You can:"
    Write-Host "  - Reinstall by running: .\setup.ps1"
    Write-Host "  - Remove the directory manually if no longer needed"
    Write-Host "  - Run this script again with -RemoveAll to delete everything"
}