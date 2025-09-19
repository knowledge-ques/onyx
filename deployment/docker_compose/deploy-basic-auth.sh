#!/bin/bash

# Deployment script for Onyx with Basic Authentication
# Usage: ./deploy-basic-auth.sh [prod|prod-no-letsencrypt|dev]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default deployment type
DEPLOY_TYPE=${1:-prod}

# Project name
PROJECT_NAME="onyx-stack"

echo -e "${GREEN}Onyx Basic Authentication Deployment Script${NC}"
echo "=========================================="

# Check if we're in the correct directory
if [ ! -f "docker-compose.${DEPLOY_TYPE}.yml" ]; then
    echo -e "${RED}Error: docker-compose.${DEPLOY_TYPE}.yml not found!${NC}"
    echo "Please run this script from the deployment/docker_compose directory"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please ensure .env file exists with AUTH_TYPE=basic"
    exit 1
fi

# Verify AUTH_TYPE is set to basic
if ! grep -q "AUTH_TYPE=basic" .env; then
    echo -e "${YELLOW}Warning: AUTH_TYPE=basic not found in .env file${NC}"
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}Using deployment type: ${DEPLOY_TYPE}${NC}"

# Create backup of current .env
BACKUP_FILE=".env.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}Creating backup: ${BACKUP_FILE}${NC}"
cp .env "$BACKUP_FILE"

# Stop existing deployment if running
echo -e "${YELLOW}Checking for existing deployment...${NC}"
if docker compose -f "docker-compose.${DEPLOY_TYPE}.yml" -p "$PROJECT_NAME" ps --quiet 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}Stopping existing deployment...${NC}"
    docker compose -f "docker-compose.${DEPLOY_TYPE}.yml" -p "$PROJECT_NAME" down
    sleep 5
fi

# Pull latest images
echo -e "${GREEN}Pulling latest images...${NC}"
docker compose -f "docker-compose.${DEPLOY_TYPE}.yml" -p "$PROJECT_NAME" pull

# Start the deployment
echo -e "${GREEN}Starting deployment...${NC}"
docker compose -f "docker-compose.${DEPLOY_TYPE}.yml" -p "$PROJECT_NAME" up -d

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Check service status
echo -e "${GREEN}Checking service status...${NC}"
docker compose -f "docker-compose.${DEPLOY_TYPE}.yml" -p "$PROJECT_NAME" ps

# Show logs for last 50 lines
echo -e "${GREEN}Recent logs:${NC}"
docker compose -f "docker-compose.${DEPLOY_TYPE}.yml" -p "$PROJECT_NAME" logs --tail=50

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
echo "=========================================="
echo -e "${GREEN}Next steps:${NC}"
echo "1. Navigate to your configured domain"
echo "2. Register the first user (will become admin automatically)"
echo "3. Monitor logs with: docker compose -f docker-compose.${DEPLOY_TYPE}.yml -p $PROJECT_NAME logs -f"
echo ""
echo -e "${YELLOW}To rollback if needed:${NC}"
echo "1. docker compose -f docker-compose.${DEPLOY_TYPE}.yml -p $PROJECT_NAME down"
echo "2. cp ${BACKUP_FILE} .env"
echo "3. docker compose -f docker-compose.${DEPLOY_TYPE}.yml -p $PROJECT_NAME up -d"