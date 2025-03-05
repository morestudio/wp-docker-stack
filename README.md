# WordPress Docker Stack

A comprehensive Docker-based WordPress development and deployment environment using WordPress, Docker, PHP-FPM 8.4, MySQL 8.4, Nginx, Redis, and Traefik.

## Stack Features

- **WordPress**: Latest version with PHP-FPM 8.4
- **MySQL 8.4**: Database server
- **Nginx**: Web server
- **Redis**: Object caching
- **Traefik**: Reverse proxy with SSL/TLS support (dev/prod)
- **WP-CLI**: Command-line interface for WordPress management
- **OPcache**: PHP optimization with fine-tuned settings

## Enhanced WP-CLI Integration

This stack features a comprehensive WP-CLI integration that streamlines WordPress management:

- WordPress core installation and updates via WP-CLI
- Automated site configuration and initial setup
- Customizable default theme installation
- Built-in Redis cache plugin integration
- Optimized permalink structure setup
- Removal of unnecessary default plugins/themes
- Database backup and restore functionality

## PHP Performance Optimizations

The stack includes optimized PHP configurations for maximum WordPress performance:

- **OPcache**: Bytecode caching to speed up PHP execution
- **PHP-FPM Pool**: Optimized process manager settings for better resource usage
- **Custom PHP Settings**: Tailored PHP configurations for WordPress workloads
- **JIT Compilation**: PHP 8.4 JIT enabled for additional performance
- **File Caching**: Secondary caching layer for OPcache
- **Redis Object Cache**: Integration with WordPress object caching

These optimizations significantly improve WordPress performance, especially under heavy load.

## Directory Structure

```
.
├── backups/                  # Database backups
├── config/                   # Configuration files
│   ├── nginx/                # Nginx configuration
│   │   └── default.conf      # Default Nginx config
│   └── php/                  # PHP configuration files
│       ├── www.conf          # PHP-FPM pool configuration
│       ├── opcache.ini       # OPcache settings
│       └── custom.ini        # Additional PHP settings
├── letsencrypt/              # Let's Encrypt certificates (created on first run)
├── scripts/                  # Management scripts
│   └── manage.sh             # Main management script
├── wordpress/                # WordPress source code
│   ├── Dockerfile            # WordPress container definition
│   ├── docker-entrypoint.sh  # Container initialization script
│   ├── wp-cli.yml            # WP-CLI configuration
│   ├── themes/                # WordPress themes
│   ├── plugins/               # WordPress plugins
│   └── wp-cli-packages/       # WP-CLI packages
├── .env                      # Environment variables (copy from .env.example)
├── .env.example              # Example environment variables
├── docker-compose.yml        # Base Docker Compose configuration
├── docker-compose.local.yml  # Local environment configuration
├── docker-compose.dev.yml    # Development environment configuration
└── docker-compose.prod.yml   # Production environment configuration
```

## Setup Instructions

1. **Copy environment variables file**:
   ```bash
   cp .env.example .env
   ```

2. **Edit environment variables**:
   Open `.env` in your editor and customize as needed.

3. **Start the environment**:
   ```bash
   # For local development
   ENVIRONMENT=local ./scripts/manage.sh start
   
   # For development environment
   ENVIRONMENT=dev ./scripts/manage.sh start
   
   # For production environment
   ENVIRONMENT=prod ./scripts/manage.sh start
   ```

## Local Development Configuration

When running in the local development environment, non-standard ports are used to avoid conflicts:

| Service   | Standard Port | Local Port | URL/Connection String                   |
|-----------|---------------|------------|----------------------------------------|
| WordPress | 80            | 8080       | http://localhost:8080                   |
| MySQL     | 3306          | 33060      | mysql://localhost:33060                 |
| Redis     | 6379          | 63790      | redis://localhost:63790                 |

These non-standard ports help prevent conflicts with other services you might be running on your development machine.

## Usage

The management script provides the following commands:

```bash
ENVIRONMENT=<local|dev|prod> ./scripts/manage.sh <command>
```

Available commands:
- `start`: Start all services
- `stop`: Stop all services
- `restart`: Restart all services
- `logs`: View logs
- `pull`: Update code from git and rebuild
- `status`: Check container status
- `wp`: Run WP-CLI commands
- `shell`: Access the WordPress container shell
- `db-backup`: Create a database backup
- `db-restore`: Restore a database from backup

## WP-CLI Usage

The stack includes WP-CLI for managing WordPress from the command line:

```bash
# List installed plugins
ENVIRONMENT=local ./scripts/manage.sh wp plugin list

# Update all plugins
ENVIRONMENT=local ./scripts/manage.sh wp plugin update --all

# Install a theme
ENVIRONMENT=local ./scripts/manage.sh wp theme install twentytwentytwo

# Create a new user
ENVIRONMENT=local ./scripts/manage.sh wp user create john john@example.com --role=author

# Export/import content
ENVIRONMENT=local ./scripts/manage.sh wp export > export.xml
ENVIRONMENT=local ./scripts/manage.sh wp import export.xml --authors=create

# Update WordPress core
ENVIRONMENT=local ./scripts/manage.sh wp core update
ENVIRONMENT=local ./scripts/manage.sh wp core update-db

# Manage media
ENVIRONMENT=local ./scripts/manage.sh wp media regenerate --yes
```

## Database Management

```bash
# Create a database backup
ENVIRONMENT=local ./scripts/manage.sh db-backup

# Restore a database from backup
ENVIRONMENT=local ./scripts/manage.sh db-restore backups/backup-20230101120000.sql
```

## Development Workflow

1. Clone the repository
2. Start the local environment
3. Develop in the `wordpress` directory (themes, plugins, etc.)
4. Git commit your changes
5. Deploy to dev/prod using the management script

## Security Considerations

- Sensitive configuration is separated from source code
- Production environment uses SSL/TLS encryption
- Nginx configuration blocks access to sensitive files
- Environment variables store passwords and secrets
- WordPress security keys are auto-generated 