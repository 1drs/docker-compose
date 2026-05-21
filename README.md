# Self-Hosted Docker Compose Templates

A curated collection of production-ready, highly optimized, and self-hosted `docker-compose` templates. Each setup features custom base images, proper volume persistence, security best practices, and detailed backup/restore instructions.

---

## Available Stacks

This repository contains multi-container Docker applications pre-configured and ready for deployment.

| Stack / Application | Database | Cache | Base Image | Features & Tools | Link |
|:---|:---|:---|:---|:---|:---|
| 🌐 **WordPress** | MariaDB 10.11 | — | Custom `php:apache-bookworm` | phpMyAdmin, `mod_rewrite` enabled | [View Setup](./wordpress) |
| 👻 **Ghost** | MySQL 8.0 | — | Custom `node:22-alpine` | Ghost CLI pre-bundled, high performance | [View Setup](./ghost) |
| 🗄️ **Directus** | PostgreSQL 16 | Redis 7 | Custom `fedora:43` | Node.js 22, DB migrations, Redis Caching | [View Setup](./directus) |

---

## Key Highlights & Philosophy

Unlike generic, out-of-the-box `docker-compose` files, these configurations are designed with concrete production requirements in mind:

- **Custom & Optimized Base Images**: We build specific container configurations (e.g., Node 22 on Alpine, Fedora 43, Apache + PHP) to ensure high compatibility and clean dependencies rather than using bloated defaults.
- **Isolated Networks**: Database services are kept internal to the Docker network where possible, preventing unnecessary public port exposure.
- **Persistent Data**: Proper volume mapping using named Docker volumes ensures your application files, media assets, and database schemas persist across updates and restarts.
- **Backup & Restore Playbooks**: Each template includes complete, step-by-step shell instructions to safely backup and restore both raw assets and active database volumes.

---

## Global Requirements

To run any of the templates in this repository, your host system must have the following installed:

- **Docker Engine** v24.0.0 or higher
- **Docker Compose** v2.0.0 or higher

Check your installed versions using:
```bash
docker --version
docker compose version
```

---

## Quick Start

### 1. Clone this Repository
```bash
git clone https://github.com/1drs/docker-compose.git
cd docker-compose
```

### 2. Choose a Stack & Navigate
Choose the application you want to deploy:
```bash
# For WordPress
cd wordpress

# For Ghost
cd ghost

# For Directus
cd directus
```

### 3. Review & Configure
Open `docker-compose.yml` in your preferred editor. Customize the credentials, database names, ports, or passwords.
> [!IMPORTANT]
> Always change default passwords (e.g. `changeMe`, `notSecureChangeMe`) to secure, random strings before launching containers in a public or production environment.

### 4. Build and Launch
Build the custom Dockerfile and start the multi-container stack in the background:
```bash
docker compose up -d --build
```

### 5. Check Status
Verify that all services are up and running:
```bash
docker compose ps
```

---

## Global Management Commands

Here are some of the most useful commands you'll use across all projects:

### Starting and Stopping Services
```bash
# Start services in detached mode (background)
docker compose up -d

# Stop services, keeping all volume data intact
docker compose down

# Stop services and completely delete all volumes (Caution: destructive!)
docker compose down -v
```

### Checking Logs
```bash
# Follow live logs from all services
docker compose logs -f

# Follow live logs for a specific service (e.g., db)
docker compose logs -f db
```

---

## Production Security Checklist

1. **Disable Public DB Ports**: Ensure database services (`db`) do *not* publish ports to the host (e.g. `ports` section should be commented out or omitted for direct DB access) unless strictly required.
2. **Reverse Proxy & SSL**: Deploy your services behind a secure reverse proxy such as Nginx, Caddy, or Traefik. Ensure they pass the `X-Forwarded-Proto https` header to prevent infinite redirect loops.
3. **Volume Backups**: Follow the dedicated backup guidelines inside each project's directory to set up cron jobs for daily snapshots.

---

## License

This repository is licensed under the [Apache License 2.0](./LICENSE) unless otherwise specified in individual directories. Feel free to copy, modify, and distribute these templates for your personal or enterprise setups.
