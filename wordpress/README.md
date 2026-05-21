# WordPress Docker Setup

A self-hosted [WordPress](https://wordpress.org/) blogging and CMS platform running on Docker, using a custom Apache-based image with PHP and MariaDB 10.11 as the database backend, plus phpMyAdmin for easy database management.

## Stack

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| **webserver** | Custom (`php:apache-bookworm`) | `80` → `80` | WordPress website hosted on Apache |
| **db** | `mariadb:10.11` | *Internal* | MariaDB database backend |
| **phpmyadmin** | `phpmyadmin` | `8800` → `80` | Database management tool |

> [!WARNING]
> By default, the database service is kept internal to the Docker network for security. however, `phpmyadmin` is exposed on host port `8800`. For production or secure environments, it is highly recommended to protect `phpmyadmin` behind a reverse proxy with strict access control, comment it out, or remove it entirely from `docker-compose.yml`.

## Project Structure

```
.
├── Dockerfile.webserver     # Custom Apache + PHP image preconfigured for WordPress
├── vhost.conf               # Apache VirtualHost configuration
├── docker-compose.yml       # Service definitions
└── README.md
```

## Requirements

- Docker Engine 24+
- Docker Compose v2+

## Getting Started

### 1. Clone the repository

```bash
git clone git@github.com:1drs/docker-compose.git
cd docker-compose/wordpress
```

### 2. Configure environment variables

Edit the `docker-compose.yml` file to configure credentials.

> [!IMPORTANT]
> The database credentials under both `db` and `phpmyadmin` services **must match**. When you first access WordPress via the web browser, you will also need to provide these database credentials to complete the WordPress installation wizard (using `db` as the Database Host).

Update the following keys in `docker-compose.yml`:

```yaml
services:
  db:
    # ...
    environment:
      MARIADB_ROOT_PASSWORD: changeMe            # Root password for MariaDB administrative access
      MARIADB_USER: wordpress                    # WordPress database user
      MARIADB_PASSWORD: notSecureChangeMe        # WordPress database password
      MARIADB_DATABASE: wordpressdb              # WordPress database name

  phpmyadmin:
    # ...
    environment:
      PMA_HOST: db                               # Hostname of the database service
      PMA_USER: wordpress                        # Must match MARIADB_USER or use 'root'
      PMA_PASSWORD: notSecureChangeMe            # Must match MARIADB_PASSWORD or MARIADB_ROOT_PASSWORD
      PMA_PORT: 3306
```

### 3. Build and start

```bash
docker compose up -d --build
```

### 4. Access Services

| Page | URL | Description |
|------|-----|-------------|
| **WordPress Site** | `http://<your-ip>/` | WordPress install wizard / front page |
| **phpMyAdmin** | `http://<your-ip>:8800/` | Database administration panel |

Once you visit the WordPress site URL for the first time, select your language and complete the installation wizard by providing the credentials configured in `docker-compose.yml`. Note that the **Database Host** must be set to `db` (the service name defined in `docker-compose.yml`).

---

## Configuration Notes

### Why a custom `Dockerfile.webserver`?

Instead of using the official pre-packaged WordPress image, this setup uses a custom Dockerfile based on `php:apache-bookworm`. This offers several key benefits:

1. **Direct PHP Extension Control**: Installs exactly what WordPress needs (`mysqli`, `pdo`, `pdo_mysql`, and `gd` with JPEG/WebP support) to ensure stability and compatibility.
2. **Local Mirror for Speed**: Changes the default Debian repository to a local Indonesian mirror (`kartolo.sby.datautama.net.id`) for significantly faster package installation.
3. **Specific Version Pinning**: Downloads and extracts WordPress v6.9.4 directly into Apache's document root `/var/www/html` and ensures files have correct ownership (`www-data:www-data`) so that media uploads and automatic updates work seamlessly.
4. **Custom VirtualHost**: Deploys a tailored VirtualHost configuration and enables `mod_rewrite` to support SEO-friendly custom permalinks out-of-the-box.

### Custom virtual host (`vhost.conf`)

By setting `AllowOverride All` in `vhost.conf` for `/var/www/html`, Apache honors WordPress's `.htaccess` file, enabling beautiful custom permalinks and routing configuration.

---

## Persistent Data

Named Docker volumes are used to persist data across container restarts:

| Volume | Purpose | Mount Path in Container |
|--------|---------|-------------------------|
| `wp_data` | WordPress core files, themes, plugins, and media uploads | `/var/www/html` |
| `db_data` | MariaDB database storage files | `/var/lib/mysql` |

---

## Backup and Restore

### 1. Backing up data

#### WordPress Site Files
Run a temporary container to archive the `wp_data` volume:
```bash
docker run --rm \
  -v wp_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/wordpress-files-backup.tar.gz -C /data .
```

#### MariaDB Database
Dump the database to a `.sql` file using `mariadb-dump`:
```bash
docker compose exec -T db mariadb-dump -u wordpress -pnotSecureChangeMe wordpressdb > db-backup.sql
```
*(Replace `wordpress`, `notSecureChangeMe`, and `wordpressdb` with your configured credentials.)*

### 2. Restoring data

#### WordPress Site Files
Extract the archive back into the `wp_data` volume:
```bash
docker run --rm \
  -v wp_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/wordpress-files-backup.tar.gz -C /data"
```

#### MariaDB Database
Restore the SQL schema and data back to the database:
```bash
docker compose exec -T db mariadb -u wordpress -pnotSecureChangeMe wordpressdb < db-backup.sql
```

---

## Production & Reverse Proxy Setup (SSL/HTTPS)

For production deployments, it is best practice to run WordPress behind an SSL-terminating reverse proxy (such as Nginx, Caddy, or Traefik).

Since WordPress dynamically generates absolute URLs, you must configure your reverse proxy to forward standard headers:

```nginx
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto https;
proxy_set_header Host $http_host;
```

Additionally, to prevent redirect loops and mixed content warnings, add the following code block to the top of your `wp-config.php` (inside `/var/www/html`, which is mounted via the `wp_data` volume) once it is generated:

```php
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
```

---

## Troubleshooting

### "Error Establishing a Database Connection"
- Double-check that your MariaDB environment variables in `docker-compose.yml` exactly match the credentials entered in the WordPress installation screen.
- Verify that you are using `db` as the Database Host during setup, NOT `localhost`.

### Site loads, but all styling/CSS is missing
This usually happens when WordPress is accessed over `https://` but the **Site Address** and **WordPress Address** settings are still configured with `http://`. Update these values under **Settings > General** inside the WordPress dashboard.

### View container logs
Monitor logs in real-time to diagnose startup or server errors:
```bash
docker compose logs -f webserver
docker compose logs -f db
```

## License

This project is provided as-is for self-hosting purposes. WordPress is released under the [GNU GPLv2](https://wordpress.org/about/license/).
