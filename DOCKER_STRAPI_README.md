# Strapi Backend - Docker Setup

## Quick Start

### 1. Start Services

```bash
# From project root directory
cd /home/akash/Project/infra/portainer/data/geofrontapp

# Start Strapi and PostgreSQL
docker-compose up -d
```

### 2. Check Services Status

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f strapi
docker-compose logs -f postgres
```

### 3. Access Strapi

- **Admin Panel**: http://localhost:1337/admin
- **GraphQL Playground**: http://localhost:1337/graphql
- **API**: http://localhost:1337/api
- **Health Check**: http://localhost:1337/_health

### 4. First-Time Setup

1. Open http://localhost:1337/admin
2. Create your admin account (first time only)
3. Follow the Strapi configuration steps from `STRAPI_SETUP.md`

---

## Services

### PostgreSQL Database
- **Port**: 5432
- **Database**: geofrontapp
- **User**: geofrontapp_user
- **Password**: geofrontapp_password_2025
- **Volume**: postgres_data (persistent storage)

### Strapi CMS
- **Port**: 1337
- **Admin Path**: /admin
- **GraphQL**: /graphql
- **API**: /api
- **Volume**: strapi_data (persistent storage)

---

## Docker Commands

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### Stop and Remove Data (⚠️ Destructive)
```bash
docker-compose down -v
```

### Restart Services
```bash
docker-compose restart
```

### View Logs
```bash
# All services
docker-compose logs -f

# Strapi only
docker-compose logs -f strapi

# PostgreSQL only
docker-compose logs -f postgres
```

### Execute Commands in Container
```bash
# Access Strapi shell
docker-compose exec strapi sh

# Access PostgreSQL
docker-compose exec postgres psql -U geofrontapp_user -d geofrontapp
```

---

## Configuration

### Environment Variables

Edit `.env.strapi` to customize configuration:

```env
# Server
HOST=0.0.0.0
PORT=1337

# Database
DATABASE_HOST=postgres
DATABASE_NAME=geofrontapp
DATABASE_USERNAME=geofrontapp_user
DATABASE_PASSWORD=your_secure_password

# Security - Generate new secrets!
APP_KEYS=your_generated_keys
JWT_SECRET=your_jwt_secret
```

### Generate Secure Secrets

```bash
# Generate random base64 strings
openssl rand -base64 32

# Run this 5 times for:
# - APP_KEYS (4 comma-separated values)
# - API_TOKEN_SALT
# - ADMIN_JWT_SECRET
# - TRANSFER_TOKEN_SALT
# - JWT_SECRET
```

---

## Backup and Restore

### Backup Database

```bash
# Create backup
docker-compose exec postgres pg_dump -U geofrontapp_user geofrontapp > backup_$(date +%Y%m%d_%H%M%S).sql

# Or with docker
docker exec geofrontapp_postgres pg_dump -U geofrontapp_user geofrontapp > backup.sql
```

### Restore Database

```bash
# Restore from backup
docker-compose exec -T postgres psql -U geofrontapp_user geofrontapp < backup.sql

# Or
cat backup.sql | docker exec -i geofrontapp_postgres psql -U geofrontapp_user -d geofrontapp
```

### Backup Strapi Files

```bash
# Backup uploaded files and config
docker-compose exec strapi tar czf /tmp/strapi-backup.tar.gz /srv/app/public /srv/app/config
docker cp geofrontapp_strapi:/tmp/strapi-backup.tar.gz ./strapi-backup.tar.gz
```

---

## Troubleshooting

### Issue: Services won't start

```bash
# Check if ports are in use
lsof -ti:1337
lsof -ti:5432

# Kill processes if needed
lsof -ti:1337 | xargs kill -9
lsof -ti:5432 | xargs kill -9
```

### Issue: Database connection failed

```bash
# Check PostgreSQL is healthy
docker-compose exec postgres pg_isready -U geofrontapp_user

# Check logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### Issue: Strapi won't start

```bash
# Check logs
docker-compose logs strapi

# Rebuild container
docker-compose up -d --force-recreate strapi

# Complete rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Issue: Permission errors

```bash
# Fix volume permissions
docker-compose down
docker volume rm geofrontapp_strapi_data
docker-compose up -d
```

### Issue: Clear all data and start fresh

```bash
# ⚠️ WARNING: This deletes all data!
docker-compose down -v
docker-compose up -d
```

---

## Production Deployment

### Security Checklist

- [ ] Change all default passwords
- [ ] Generate new APP_KEYS, JWT secrets
- [ ] Set NODE_ENV=production
- [ ] Enable DATABASE_SSL=true
- [ ] Configure firewall rules
- [ ] Set up SSL/TLS certificates
- [ ] Enable rate limiting
- [ ] Configure CORS properly
- [ ] Set up backups
- [ ] Enable monitoring

### Production Environment Variables

```env
NODE_ENV=production
DATABASE_SSL=true
HOST=0.0.0.0
PORT=1337
```

### Using with Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:1337;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## Integration with Flutter App

Your Flutter app is already configured to connect to Strapi at:
```dart
static const String _strapiEndpoint = 'http://localhost:1337/graphql';
```

### Network Access

If Flutter app runs on different machine:
1. Update endpoint in `lib/config/graphql_config.dart`
2. Update CORS in Strapi `config/middlewares.js`
3. Ensure firewall allows port 1337

---

## Monitoring

### Health Check

```bash
# Check Strapi health
curl http://localhost:1337/_health

# Should return: {"status":"ok"}
```

### Service Status

```bash
# Check all services
docker-compose ps

# Check resource usage
docker stats geofrontapp_strapi geofrontapp_postgres
```

---

## Useful Commands

```bash
# View all containers
docker ps -a

# Remove stopped containers
docker-compose rm

# Update Strapi image
docker-compose pull strapi
docker-compose up -d --force-recreate strapi

# Shell into Strapi
docker-compose exec strapi sh

# Node.js console in Strapi
docker-compose exec strapi node

# Check database
docker-compose exec postgres psql -U geofrontapp_user -d geofrontapp -c "\dt"
```

---

## File Structure

```
geofrontapp/
├── docker-compose.yml          # Docker services definition
├── .env.strapi                 # Environment variables
├── STRAPI_SETUP.md            # Strapi configuration guide
├── DOCKER_STRAPI_README.md    # This file
└── lib/
    └── config/
        └── graphql_config.dart # Flutter GraphQL config
```

---

## Next Steps

1. ✅ Start services: `docker-compose up -d`
2. ✅ Access admin: http://localhost:1337/admin
3. ✅ Create admin account
4. ✅ Follow `STRAPI_SETUP.md` for content type configuration
5. ✅ Test GraphQL API
6. ✅ Start Flutter app: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8081`

---

## Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Strapi Docker Documentation](https://docs.strapi.io/dev-docs/installation/docker)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [Strapi Documentation](https://docs.strapi.io/)

---

## Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Verify services: `docker-compose ps`
3. Check network: `docker network ls`
4. Review `STRAPI_SETUP.md` for Strapi configuration
