# Ghost Docker Setup

A self-hosted [Ghost](https://ghost.org/) blogging platform running on Docker, using a custom Alpine-based image with MySQL 8 as the database backend.

## Stack

| Service | Image | Port |
|---------|-------|------|
| Ghost | Custom (`node:22-alpine3.22`) | `80` → `2368` |
| MySQL | `mysql:8.0` | `3306` (internal) |

## Project Structure

```
.
├── Dockerfile.ghost        # Custom Ghost image based on node:22-alpine3.22
├── ghost-entrypoint.sh     # Container entrypoint script
├── docker-compose.yml      # Service definitions
└── README.md
```

## Requirements

- Docker Engine 24+
- Docker Compose v2+

## Getting Started

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd <repo-directory>
```

### 2. Configure environment variables

Edit `docker-compose.yml` and update the following values:

```yaml
# MySQL
MYSQL_ROOT_PASSWORD: changeMe
MYSQL_USER: ghost
MYSQL_PASSWORD: ghostPassword
MYSQL_DATABASE: ghostdb

# Ghost
url: http://<your-server-ip-or-domain>
database__connection__password: ghostPassword
```

> **Important:** The `url` value must match the address you use to access Ghost from the browser. Ghost will reject requests from mismatched hosts in production mode.

### 3. Build and start

```bash
docker compose up -d --build
```

### 4. Access Ghost

| Page | URL |
|------|-----|
| Blog | `http://<your-ip>/` |
| Admin panel | `http://<your-ip>/ghost` |

## Configuration Notes

### Why `server__host: 0.0.0.0`?

By default, Ghost listens only on `127.0.0.1` inside the container, which prevents Docker from forwarding external traffic to it. Setting `server__host: 0.0.0.0` makes Ghost bind to all interfaces, allowing the port mapping to work correctly.

### Why `node:22-alpine3.22` instead of `alpine:3.22`?

Ghost 6.x requires Node.js v22 LTS. Using `node:22-alpine3.22` as the base image provides a verified Node.js 22 installation on Alpine 3.22 without extra setup steps. The result is functionally identical to building from `alpine:3.22` with manual Node.js installation.

### Why Ghost CLI instead of the GitHub source zip?

The Ghost GitHub repository is a **monorepo** managed with `pnpm` workspaces and catalog references. Running `npm install` directly on it will fail with `EUNSUPPORTEDPROTOCOL: catalog:`. Ghost CLI installs the production-ready, pre-bundled version of Ghost — which is the correct way to deploy it.

## Persistent Data

Named Docker volumes are used to persist data across container restarts:

| Volume | Purpose |
|--------|---------|
| `ghost_content` | Ghost content files (images, themes, data) |
| `ghost_db` | MySQL database files |

To back up Ghost content:

```bash
docker run --rm \
  -v ghost_content:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/ghost-content-backup.tar.gz -C /data .
```

## Stopping and Removing

```bash
# Stop containers
docker compose down

# Stop and remove volumes (destructive)
docker compose down -v
```

## Troubleshooting

### Ghost is running but the browser can't connect

Check that `url` in `docker-compose.yml` matches the hostname/IP you are using to access the site. Ghost will reset connections from unrecognized hosts in production mode.

### Port 80 is accessible but returns an empty reply

Verify that Ghost is listening on `0.0.0.0` inside the container:

```bash
docker exec <container-id> netstat -tulpn | grep 2368
# Expected: tcp 0.0.0.0:2368 ...
# Problem : tcp 127.0.0.1:2368 ... (missing server__host: 0.0.0.0)
```

### View Ghost logs

```bash
docker logs <container-id> -f
```

## License

This project is provided as-is for self-hosting purposes. Ghost itself is released under the [MIT License](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
