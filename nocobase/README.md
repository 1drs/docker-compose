# NocoBase Docker Setup

A self-hosted [NocoBase](https://nocobase.com/) private-first, open-source, no-code platform running on Docker, using the official NocoBase image configured with SQLite as the database backend.

## Stack

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| **nocobase** | `nocobase/nocobase:1.6.0` | `80` → `80` | Main NocoBase application server with SQLite |

> [!WARNING]
> By default, NocoBase is exposed directly on host port `80`. For production or public-facing deployments, it is highly recommended to bind it to a custom internal port (or `127.0.0.1:80`) and route traffic through a secure reverse proxy (like Nginx or Caddy) with SSL termination.

## Project Structure

```
.
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
cd docker-compose/nocobase
```

### 2. Configure environment variables

Edit the `docker-compose.yml` file to configure the secret `APP_KEY` before starting the application.

> [!IMPORTANT]
> The `APP_KEY` is a secret key used to encrypt sensitive information and generate user tokens. You must change the default value `change-this-to-a-random-secret-string` to a secure, random string. If the `APP_KEY` is changed later, all previously generated tokens and API keys will be invalidated.

Update the following keys in `docker-compose.yml`:

```yaml
services:
  nocobase:
    # ...
    environment:
      APP_KEY: change-this-to-a-random-secret-string  # A secure random secret key
      DB_DIALECT: sqlite                             # Database dialect (defaults to sqlite)
```

### 3. Start the application

```bash
docker compose up -d
```

### 4. Access NocoBase

| Page | URL | Description |
|------|-----|-------------|
| **NocoBase Site** | `http://<your-ip>/` | Main login page |

Use the following default credentials to log in for the first time:

* **Default Username/Email:** `admin@nocobase.com`
* **Default Password:** `admin123`

> [!IMPORTANT]
> For security reasons, you must change the default password (`admin123`) immediately after your first successful login.

---

## Configuration Notes

### Why SQLite by default?

SQLite is a lightweight, zero-configuration database engine that stores all data in a single file inside the container's storage. It is perfect for testing, development, and low-traffic private deployments. 

If you need to scale NocoBase or require high availability, you can change `DB_DIALECT` to `postgres` or `mysql` and add a database service to the `docker-compose.yml` configuration.

---

## Persistent Data

Named Docker volumes are used to persist data across container restarts:

| Volume | Purpose | Mount Path in Container |
|--------|---------|-------------------------|
| `nocobase_storage` | Application storage (SQLite DB, uploads, plugins, logs) | `/app/nocobase/storage` |

---

## Backup and Restore

Since the SQLite database and all other assets are contained within the `nocobase_storage` volume under the path `/app/nocobase/storage`, a full backup can be taken by backing up this single volume.

### 1. Backing up data

Run a temporary container to archive the `nocobase_storage` volume:
```bash
docker run --rm \
  -v nocobase_storage:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/nocobase-backup.tar.gz -C /data .
```

### 2. Restoring data

Restore the archive back into the volume:
```bash
docker run --rm \
  -v nocobase_storage:/data \
  -v $(pwd):/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/nocobase-backup.tar.gz -C /data"
```

---

## Production & Reverse Proxy Setup (SSL/HTTPS)

For production environments, it is best practice to run NocoBase behind a reverse proxy (like Nginx, Caddy, or Traefik) that handles SSL termination.

When deploying behind an SSL-terminating reverse proxy, configure your proxy to forward standard headers:

```nginx
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto https;
proxy_set_header Host $http_host;
```

---

## Troubleshooting

### View container logs
View live logs to diagnose startup issues or runtime errors:
```bash
docker compose logs -f nocobase
```

## License

This project is provided as-is for self-hosting purposes. NocoBase is released under a dual-licensing model (AGPL-3.0 License for open source use and a Commercial License for enterprise use). See the [NocoBase License Page](https://www.nocobase.com/) for details.
