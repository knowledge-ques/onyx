# Deployment Instructions for Basic Authentication

## Prerequisites
- Ensure Docker and Docker Compose are installed on your server
- Have access to the server where Onyx will be deployed
- The `.env` file with `AUTH_TYPE=basic` is already configured in `deployment/docker_compose/`

## Deployment Steps

### 1. Navigate to the deployment directory
```bash
cd /path/to/onyx/deployment/docker_compose
```

### 2. Verify the .env configuration
Ensure the `.env` file contains:
```
AUTH_TYPE=basic
```

### 3. Stop existing services (if running)
If you have an existing deployment running, stop it first:
```bash
# For production deployment
docker compose -f docker-compose.prod.yml -p onyx-stack down

# For production without Let's Encrypt
docker compose -f docker-compose.prod-no-letsencrypt.yml -p onyx-stack down
```

### 4. Deploy with Basic Authentication

#### Option A: Production with Let's Encrypt (HTTPS)
```bash
# Pull latest images and start services
docker compose -f docker-compose.prod.yml -p onyx-stack up -d --pull always

# Or build from source
docker compose -f docker-compose.prod.yml -p onyx-stack up -d --build
```

#### Option B: Production without Let's Encrypt (HTTP/custom SSL)
```bash
# Pull latest images and start services
docker compose -f docker-compose.prod-no-letsencrypt.yml -p onyx-stack up -d --pull always

# Or build from source
docker compose -f docker-compose.prod-no-letsencrypt.yml -p onyx-stack up -d --build
```

#### Option C: Development/Testing (HTTP only)
```bash
# For development environment
docker compose -f docker-compose.dev.yml -p onyx-stack up -d --pull always
```

### 5. Verify deployment
```bash
# Check if all containers are running
docker compose -f docker-compose.prod.yml -p onyx-stack ps

# Check logs for any errors
docker compose -f docker-compose.prod.yml -p onyx-stack logs -f
```

### 6. Access the application
- Navigate to your configured domain (e.g., http://localhost or https://yourdomain.com)
- The first user to register will automatically become an admin
- Subsequent users will have basic access

## Important Notes

1. **First User is Admin**: The first user who registers after enabling basic auth will automatically be assigned the ADMIN role.

2. **Nginx Configuration**: The nginx configuration remains unchanged and will properly proxy requests to the application.

3. **Database Persistence**: User data is stored in the PostgreSQL database, which persists between container restarts.

4. **Session Duration**: User sessions expire after 7 days by default (configured via `SESSION_EXPIRE_TIME_SECONDS`).

5. **Email Verification** (Optional): To enable email verification, uncomment and configure the SMTP settings in the `.env` file:
   ```
   REQUIRE_EMAIL_VERIFICATION=true
   SMTP_USER=your-email@company.com
   SMTP_PASS=your-email-password
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   ```

## Rollback Instructions

If you need to rollback to previous authentication settings:
```bash
# Stop the services
docker compose -f docker-compose.prod.yml -p onyx-stack down

# Restore the backup .env file
cp .env.backup.<timestamp> .env

# Start services again
docker compose -f docker-compose.prod.yml -p onyx-stack up -d
```

## Monitoring

Monitor the application logs:
```bash
# All services
docker compose -f docker-compose.prod.yml -p onyx-stack logs -f

# Specific service
docker compose -f docker-compose.prod.yml -p onyx-stack logs -f api_server
docker compose -f docker-compose.prod.yml -p onyx-stack logs -f web_server
docker compose -f docker-compose.prod.yml -p onyx-stack logs -f nginx
```

## Troubleshooting

1. **Containers not starting**: Check logs with `docker compose logs -f`
2. **Authentication not working**: Verify `AUTH_TYPE=basic` in the `.env` file
3. **Nginx errors**: Check nginx configuration hasn't been modified
4. **Database connection issues**: Ensure PostgreSQL container is running and healthy

## Security Recommendations

1. Use HTTPS in production (docker-compose.prod.yml with Let's Encrypt)
2. Configure strong passwords for PostgreSQL
3. Consider enabling email verification for additional security
4. Regularly update Docker images to get security patches
5. Monitor access logs for suspicious activity