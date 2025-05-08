# Exit on error
$ErrorActionPreference = "Stop"

Write-Host "Checking Kogase health..." -ForegroundColor Cyan

# Check each service
Write-Host "===== Service Health Checks =====" -ForegroundColor Green

# Backend check
$backendStatus = docker-compose ps backend
if ($backendStatus -match "Up") {
    Write-Host "✅ Backend service: Running" -ForegroundColor Green
    # Check API health
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -Method Get -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ API responding correctly" -ForegroundColor Green
        }
        else {
            Write-Host "  ❌ API not responding properly" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ❌ API not responding" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Backend service: Not running" -ForegroundColor Red
}

# Frontend check
$frontendStatus = docker-compose ps frontend
if ($frontendStatus -match "Up") {
    Write-Host "✅ Frontend service: Running" -ForegroundColor Green
    # Check frontend health
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method Get -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ Frontend responding correctly" -ForegroundColor Green
        }
        else {
            Write-Host "  ❌ Frontend not responding properly" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ❌ Frontend not responding" -ForegroundColor Red
    }
}
else {
    Write-Host "❌ Frontend service: Not running" -ForegroundColor Red
}

Write-Host "===== Resource Usage =====" -ForegroundColor Green
docker stats --no-stream $(docker-compose ps -q)

Write-Host "============================================" -ForegroundColor Green
Write-Host "Health check complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green 