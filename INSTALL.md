# Installing Kogase

There are several ways to install and run Kogase. Choose the method that works best for you.

## Prerequisites

- Git
- Docker 
- Docker Compose

## Option 1: One-Line Installer (Recommended)

The easiest way to install Kogase is with our one-line installer. This script will detect your platform, download the appropriate installer, and set up everything for you.

### For Linux/macOS

Open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/PA-5221600034/kogase/master/install.sh | bash
```

### For Windows (PowerShell)

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/PA-5221600034/kogase/master/install.ps1 | iex
```

## Option 2: Manual Installation

### For Linux/macOS

1. Clone the repository:
   ```bash
   git clone https://github.com/PA-5221600034/kogase.git
   cd kogase
   ```

2. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

### For Windows

1. Clone the repository:
   ```powershell
   git clone https://github.com/PA-5221600034/kogase.git
   cd kogase
   ```

2. Run the setup script:
   ```powershell
   .\setup.ps1
   ```

## Accessing Kogase

After installation, you can access Kogase at:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080/api/v1
- **API Documentation**: http://localhost:8080/swagger/index.html

## Managing Your Installation

### Using Docker Compose (All platforms)

```bash
# Start all containers
docker-compose up -d

# Stop all containers
docker-compose down

# Show logs for all containers
docker-compose logs -f
```

## Health Check

To check the health of your installation:

### For Linux/macOS
```bash
./healthcheck.sh
```

### For Windows
```powershell
.\healthcheck.ps1
```

## Troubleshooting

If you encounter any issues during installation:

1. Make sure Docker and Docker Compose are running
2. Check that ports 3000 and 8080 are not in use by other applications
3. Review the logs with `docker-compose logs -f`
4. Run the health check to identify specific service issues

## Uninstalling Kogase

If you need to remove Kogase from your system, we provide uninstall scripts that can clean up Docker containers, images, volumes, and optionally the project directory.

### For Linux/macOS

```bash
./uninstall.sh
```

### For Windows

```powershell
.\uninstall.ps1
```

Both scripts provide several options:

- **Interactive Menu**: Run without parameters to see all available options
- **--containers-only** or **-ContainersOnly**: Stop and remove containers only
- **--with-images** or **-WithImages**: Remove containers and images
- **--with-volumes** or **-WithVolumes**: Remove containers, images, and volumes
- **--with-networks** or **-WithNetworks**: Remove containers, images, volumes, and networks
- **--complete** or **-Complete**: Complete cleanup (all Docker resources and project files)
- **--remove-all** or **-RemoveAll**: Remove everything including project directory
- **--help** or **-Help**: Show help message

### Examples

```bash
# Show interactive menu
./uninstall.sh

# Complete cleanup but keep project directory
./uninstall.sh --complete

# Remove everything including project directory
./uninstall.sh --remove-all

# Get help
./uninstall.sh --help
```

For more details, refer to the main [README.md](README.md) file. 