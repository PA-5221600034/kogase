#!/bin/bash

# Exit on error
set -e

echo "Checking Kogase health..."

# Check each service
echo "===== Service Health Checks ====="

# Backend check
backend_status=$(docker-compose ps backend | grep "Up" || echo "Down")
if [[ $backend_status == *"Up"* ]]; then
    echo "✅ Backend service: Running"
    # Check API health
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/health > /dev/null 2>&1; then
        echo "  ✅ API responding correctly"
    else
        echo "  ❌ API not responding"
    fi
else
    echo "❌ Backend service: Not running"
fi

# Frontend check
frontend_status=$(docker-compose ps frontend | grep "Up" || echo "Down")
if [[ $frontend_status == *"Up"* ]]; then
    echo "✅ Frontend service: Running"
    # Check frontend health
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 > /dev/null 2>&1; then
        echo "  ✅ Frontend responding correctly"
    else
        echo "  ❌ Frontend not responding"
    fi
else
    echo "❌ Frontend service: Not running"
fi

echo "===== Resource Usage ====="
docker stats --no-stream $(docker-compose ps -q)

echo "============================================"
echo "Health check complete!"
echo "============================================" 