# Directus

Self-hosted [Directus](https://directus.io/) headless CMS with PostgreSQL and Redis, running on a custom Fedora 43-based image.

## Stack

| Service | Image | Port |
|---------|-------|------|
| Directus | Custom (`fedora:43`) | `80` → `8055` |
| PostgreSQL | `postgres:16-alpine` | `5432` (internal) |
| Redis | `redis:7-alpine` | `6379` (internal) |

## Project Structure

```
.
├── Dockerfile.directus       # Custom Directus image based on fedora:43
├── directus-entrypoint.sh    # Runs DB migration then starts Directus
├── docker-compose.yml
└── README.md
```

## Requirements

- Docker Engine 24+
- Docker Compose v2+

## Getting Started

### 1. Configure

Edit `docker-compose.yml` and update the following before running:

```yaml
SECRET: change-this-to-a-random-secret-string   # JWT signing key — change this
PUBLIC_URL: http://<your-ip-or-domain>           # Must match how you access the site

POSTGRES_PASSWORD: directusPassword              # Change in both db and directus sections
DB_PASSWORD: directusPassword

ADMIN_EMAIL: admin@example.com
ADMIN_PASSWORD: adminPassword
```

> **Note:** `SECRET` must be a strong random string. You can generate one with:
> ```bash
> openssl rand -base64 32
> ```

### 2. Build and start

```bash
docker compose up -d --build
```

The first run will:
1. Pull PostgreSQL and Redis images
2. Build the Directus image from `fedora:43`
3. Run database migrations (`directus bootstrap`)
4. Create the admin account using `ADMIN_EMAIL` / `ADMIN_PASSWORD`

### 3. Access

| URL | Description |
|-----|-------------|
| `http://<your-ip>/` | Directus app |
| `http://<your-ip>/admin` | Admin panel |

Login with the credentials set in `ADMIN_EMAIL` and `ADMIN_PASSWORD`.

## Persistent Data

All data is stored in named Docker volumes:

| Volume | Purpose |
|--------|---------|
| `directus_db` | PostgreSQL database files |
| `directus_uploads` | Uploaded media and assets |
| `directus_extensions` | Custom Directus extensions |

## Stopping and Removing

```bash
# Stop containers (data preserved)
docker compose down

# Stop and remove all volumes (destructive)
docker compose down -v
```

## Notes

### Why Fedora 43?
Fedora 43 ships Node.js 22 in its default DNF repositories, which satisfies Directus's Node.js 22+ requirement without needing third-party package sources.

### Why `directus bootstrap`?
The `bootstrap` command handles two things: running database schema migrations and creating the initial admin user from environment variables. It is idempotent — safe to run on every container start.

### `PUBLIC_URL` vs port mapping
Directus is mapped from internal port `8055` to host port `80`. The `PUBLIC_URL` environment variable tells Directus what external URL to use when generating links and redirects — it should reflect the externally accessible address, not the internal port.

### Redis
Redis is used for caching and is recommended for reliable WebSocket and rate-limiting behavior. It is optional for single-instance deployments — to remove it, delete the `cache` service and the `CACHE_*` / `REDIS_*` environment variables from the `directus` service.
