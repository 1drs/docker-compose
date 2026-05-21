# Ghost Docker Setup

A self-hosted [Ghost](https://ghost.org/) blogging platform running on Docker, using a custom Alpine-based image with MySQL 8 as the database backend.

## Stack

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| **Ghost** | Custom (`node:22-alpine3.22`) | `80` → `2368` | Main blogging platform |
| **MySQL** | `mysql:8.0` | `3306` (exposed) | Database backend |

> [!WARNING]
> By default, the database port `3306` is published in `docker-compose.yml`. For production or secure environments, it is highly recommended to comment out or remove the `ports` mapping under the `db` service to keep it internal to the Docker network.

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
git clone git@github.com:1drs/docker-compose.git
cd docker-compose/ghost
```

### 2. Configure environment variables

Edit the `docker-compose.yml` file to configure credentials and URL settings.

> [!IMPORTANT]
> The database credentials under both `db` and `ghost` services **must match**. If you change the username, password, or database name in the `db` service, you must update the corresponding variables in the `ghost` service.

Update the following keys in `docker-compose.yml`:

```yaml
services:
  db:
    # ...
    environment:
      MYSQL_ROOT_PASSWORD: changeMe        # Root password for MySQL administrative access
      MYSQL_USER: ghost                   # Ghost database user
      MYSQL_PASSWORD: ghostPassword       # Ghost database password (must match database__connection__password)
      MYSQL_DATABASE: ghostdb             # Ghost database name (must match database__connection__database)

  ghost:
    # ...
    environment:
      url: http://<your-server-ip-or-domain>   # The external URL used to access Ghost
      database__connection__user: ghost        # Must match MYSQL_USER
      database__connection__password: ghostPassword # Must match MYSQL_PASSWORD
      database__connection__database: ghostdb  # Must match MYSQL_DATABASE
```

> [!NOTE]
> The `url` value must match the exact address you use to access Ghost in your browser (including protocol and port if not 80). Ghost will reject requests from mismatched hosts in production mode.

### 3. Build and start

```bash
docker compose up -d --build
```

### 4. Access Ghost

| Page | URL |
|------|-----|
| **Blog** | `http://<your-ip>/` |
| **Admin Panel** | `http://<your-ip>/ghost` |

## Configuration Notes

### Why `server__host: 0.0.0.0`?

By default, Ghost listens only on `127.0.0.1` inside the container, which prevents Docker from forwarding external traffic to it. Setting `server__host: 0.0.0.0` makes Ghost bind to all interfaces, allowing the port mapping to work correctly.

### Why `node:22-alpine3.22` instead of `alpine:3.22`?

Ghost 6.x requires Node.js v22 LTS. Using `node:22-alpine3.22` as the base image provides a verified Node.js 22 installation on Alpine 3.22 without extra setup steps. The result is functionally identical to building from `alpine:3.22` with manual Node.js installation.

### Why Ghost CLI instead of the GitHub source zip?

The Ghost GitHub repository is a **monorepo** managed with `pnpm` workspaces and catalog references. Running `npm install` directly on it will fail with `EUNSUPPORTEDPROTOCOL: catalog:`. Ghost CLI installs the production-ready, pre-bundled version of Ghost — which is the correct way to deploy it.

## Persistent Data

Named Docker volumes are used to persist data across container restarts:

| Volume | Purpose | Mount Path in Container |
|--------|---------|-------------------------|
| `ghost_content` | Ghost content files (images, themes, data) | `/var/lib/ghost/content` |
| `ghost_db` | MySQL database files | `/var/lib/mysql` |

---

## Backup and Restore

### 1. Backing up data

#### Ghost Content (Themes, Images, Uploads)
Run a temporary container to archive the `ghost_content` volume:
```bash
docker run --rm \
  -v ghost_content:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/ghost-content-backup.tar.gz -C /data .
```

#### MySQL Database
Dump the database to a `.sql` file using `mysqldump`:
```bash
docker compose exec -T db mysqldump -u ghost -pghostPassword ghostdb > db-backup.sql
```
*(Replace `ghost`, `ghostPassword`, and `ghostdb` if you modified them in `docker-compose.yml`.)*

### 2. Restoring data

#### Ghost Content
Extract the archive back into the `ghost_content` volume:
```bash
docker run --rm \
  -v ghost_content:/data \
  -v $(pwd):/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/ghost-content-backup.tar.gz -C /data"
```

#### MySQL Database
Restore the SQL schema and data back to the database:
```bash
docker compose exec -T db mysql -u ghost -pghostPassword ghostdb < db-backup.sql
```

---

## Production & Reverse Proxy Setup (SSL/HTTPS)

For production environments, it is best practice to run Ghost behind a reverse proxy (like Nginx, Caddy, or Traefik) that handles SSL termination.

When deploying behind an SSL-terminating reverse proxy:
1. Update `url` in `docker-compose.yml` to use `https://`:
   ```yaml
   url: https://your-domain.com
   ```
2. Configure your reverse proxy to forward the standard headers:
   ```nginx
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto https;
   proxy_set_header Host $http_host;
   ```
   *(Without the `X-Forwarded-Proto https` header, Ghost may run into infinite redirect loops.)*

---

## Troubleshooting

### Ghost is running but the browser can't connect
Check that `url` in `docker-compose.yml` matches the hostname/IP you are using to access the site. Ghost will reset connections from unrecognized hosts in production mode.

### Verify that Ghost is listening on `0.0.0.0`
Verify that Ghost is bound correctly inside the container:
```bash
docker compose exec ghost netstat -tulpn | grep 2368
# Expected: tcp 0.0.0.0:2368 ...
# Problem : tcp 127.0.0.1:2368 ... (missing server__host: 0.0.0.0)
```

### View container logs
View live logs to diagnose startup issues or runtime errors:
```bash
docker compose logs -f ghost
```

## License

This project is provided as-is for self-hosting purposes. Ghost itself is released under the [MIT License](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
