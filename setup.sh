#!/bin/bash

# Exit on error
set -e

echo "Setting up Kogase development environment..."

# Copy environment files if they don't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env
fi

echo "Building Docker images..."
docker compose build

echo "Starting Docker containers..."
docker compose up -d

echo "Waiting for services to initialize..."
sleep 5

echo "============================================"
echo "Kogase is now running!"
echo "============================================"
echo "Frontend: http://localhost:3000"
echo "Backend API: http://localhost:8080/api/v1"
echo "API Documentation: http://localhost:8080/swagger/index.html"
echo "============================================"
echo "Use 'docker-compose logs -f' to view logs"
echo "Use 'make help' to see all available commands"
echo "============================================" 