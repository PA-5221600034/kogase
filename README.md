# Kogase - Komu's Game Service

Kogase is an open-source, self-hosted game analytics and telemetry platform.

## Quick Installation

### One-line Installation (Recommended)

**For Linux/macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/atqamz/kogase/master/install.sh | bash
```

**For Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/atqamz/kogase/master/install.ps1 | iex
```

For more installation options and troubleshooting, see [INSTALL.md](INSTALL.md).

## Features

- **Game Telemetry**: Track player actions, sessions, and custom events
- **Analytics Dashboard**: Visualize your game's performance metrics
- **Multiple Projects**: Manage multiple games from a single dashboard
- **Self-hosted**: Full control over your data
- **Unity SDK**: Easy integration with Unity games

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Make (optional, for using Makefile commands)

### Running with Docker Compose

1. Clone the repository:
   ```
   git clone https://github.com/atqamz/kogase.git
   cd kogase
   ```

2. Run the setup script:

   **On Linux/Mac**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

   **On Windows (PowerShell)**:
   ```powershell
   .\setup.ps1
   ```

   This will:
   - Create the .env file if it doesn't exist
   - Build all Docker images
   - Start all containers
   - Display access URLs

3. Access the application:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8080/api/v1
   - API Documentation: http://localhost:8080/swagger/index.html

### Docker Compose Services

The Docker Compose setup includes the following services:

- **Backend**: Go API running on port 8080
- **Frontend**: Next.js application running on port 3000
- **Postgres**: PostgreSQL database running on port 5432

### Docker Development

To rebuild a specific service:

```bash
docker-compose build [service]
```

To restart a service:

```bash
docker-compose restart [service]
```

To view service logs:

```bash
docker-compose logs -f [service]
```

### Using the Makefile

The repository includes a Makefile to simplify common Docker operations:

```bash
# Start all containers
make up

# Stop all containers
make down

# Show logs for all containers
make logs

# Show logs for a specific service
make backend-logs
make frontend-logs
make db-logs

# Rebuild and restart all containers
make rebuild

# Run health check
make health

# See all available commands
make help
```

### Health Checks

You can run a health check on the Docker containers using the following commands:

**On Linux/Mac**:
```bash
chmod +x healthcheck.sh
./healthcheck.sh
```

**On Windows (PowerShell)**:
```powershell
.\healthcheck.ps1
```

This will check:
- If all services are running
- If the backend API is responding
- If the frontend is accessible
- The resource usage of each container

### Running the Backend Locally

1. Ensure you have Go 1.22 or later installed
2. Set up a PostgreSQL database
3. Configure the `.env` file in the `backend` directory
4. Run the backend:
   ```
   cd backend
   go run main.go
   ```

## API Documentation

The API is documented using Swagger. When the server is running, access the interactive documentation at:

```
http://localhost:8080/swagger/index.html
```

You can explore all available endpoints and test them directly from the browser. The API supports two types of authentication:

1. **JWT Tokens** - For dashboard and admin access
   - Obtain a token via `/api/v1/auth/login`
   - Use the token in the `Authorization` header: `Bearer your_token`

2. **API Keys** - For SDK and game clients
   - Generate an API key for your project in the dashboard
   - Use the key in the `X-API-Key` header

## Project Structure

```
kogase/
├── backend/            # Go backend
│   ├── controllers/    # API controllers
│   ├── middleware/     # Custom middleware
│   ├── models/         # Database models
│   ├── server/         # Server configuration
│   └── utils/          # Utility functions
├── frontend/           # Next.js frontend
├── unity-sdk/          # Unity SDK
├── docker-compose.yaml # Docker Compose configuration
├── Makefile            # Commands for Docker operations
├── setup.sh            # Setup script for Linux/Mac
├── setup.ps1           # Setup script for Windows
├── healthcheck.sh      # Health check script for Linux/Mac
└── healthcheck.ps1     # Health check script for Windows
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Environment

This project includes a development setup with hot reloading for both backend and frontend services.

### Requirements

- Docker and Docker Compose

### Running in Development Mode

1. Clone the repository
2. Start the development environment:

**For Linux/macOS:**
```bash
# Make the script executable
chmod +x dev.sh

# Run the development environment
./dev.sh
```

**For Windows (PowerShell):**
```powershell
# Run the development environment
.\dev.ps1
```

Or manually with Docker Compose:

```bash
docker-compose -f docker-compose.dev.yaml up --build
```

### Development Features

- **Backend**: Uses Air for hot reloading Go code. Any changes to your Go files will automatically rebuild and restart the server.
- **Frontend**: Uses Next.js built-in development server with hot module replacement. Changes to React components and styles are instantly reflected.
- **Volumes**: Local files are mounted into the containers, ensuring all changes are immediately synced.

### Endpoints

- Frontend: http://localhost:3000
- Backend API: http://localhost:8080/api/v1
- Swagger UI: http://localhost:8080/swagger/index.html 