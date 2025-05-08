# Kogase Development Container

This directory contains configuration files for setting up a consistent development environment using Visual Studio Code's Remote Containers feature.

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop) installed on your machine
- [Visual Studio Code](https://code.visualstudio.com/) with the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension installed

## Environment Setup

1. Copy the `.env.example` file in the project root to `.env` and update any values as needed:

   ```bash
   cp .env.example .env
   ```

2. Open the project in VS Code:

   ```bash
   code .
   ```

3. When prompted to "Reopen in Container", click "Reopen in Container". Alternatively, you can:

   - Press F1
   - Type "Remote-Containers: Reopen in Container" and select it

4. VS Code will build the development container and attach to it. This may take a few minutes the first time.

## What's Included

- Go 1.24.3 with common development tools:
  - golangci-lint
  - goimports
  - swag (for Swagger documentation)
  - air (for hot reloading)
- Bun for frontend development
- PostgreSQL 17 database
- VS Code extensions for Go and TypeScript/React development

## Environment Variables

The following environment variables are set up in the container:

- `DB_HOST=db`
- `DB_USER=postgres`
- `DB_PASSWORD=postgres`
- `DB_NAME=kogase`
- `DB_PORT=5432`
- `BACKEND_PORT=8080`
- `FRONTEND_PORT=3000`

## Port Forwarding

The following ports are forwarded from the container to your local machine:

- 3000: Frontend (Next.js) - mapped to container port 3000
- 8080: Backend (Go/Gin) - mapped to container port 8080
- 5432: PostgreSQL - mapped to container port 5432

All services are bound to all interfaces (0.0.0.0) for remote access.

## Running the Application

Once inside the container, you can run the application components separately.

### Backend (Go/Gin)

Run the backend with hot-reloading enabled:

```bash
cd backend
air -c .air.toml
```

The backend API will be available at http://localhost:18080.

### Frontend (Next.js)

Run the frontend development server:

```bash
cd frontend
bun run dev
```

The frontend will be available at http://localhost:13000.

## Customization

You can customize the development environment by modifying:

- `Dockerfile`: Change the base image, install additional dependencies
- `devcontainer.json`: Add/remove VS Code extensions, change settings
- `docker-compose.yml`: Modify service configurations, add new services
