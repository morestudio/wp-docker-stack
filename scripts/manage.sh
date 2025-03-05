#!/bin/bash

# Set environment variable for docker-compose files
COMPOSE_FILES="-f docker-compose.yml"

# Function to determine which compose files to use based on environment
set_environment() {
    case "$ENVIRONMENT" in
        "local")
            COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.local.yml"
            ;;
        "dev")
            COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.dev.yml"
            ;;
        "prod")
            COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.prod.yml"
            ;;
        *)
            echo "Invalid environment. Use: local, dev, or prod"
            exit 1
            ;;
    esac
}

# Check if environment is set
if [ -z "$ENVIRONMENT" ]; then
    echo "Please set ENVIRONMENT variable (local, dev, or prod)"
    echo "Example: ENVIRONMENT=local ./scripts/manage.sh start"
    exit 1
fi

set_environment

case "$1" in
    "start")
        docker-compose $COMPOSE_FILES up -d
        ;;
    "stop")
        docker-compose $COMPOSE_FILES down
        ;;
    "restart")
        docker-compose $COMPOSE_FILES restart
        ;;
    "rebuild")
        docker-compose $COMPOSE_FILES down
        docker-compose $COMPOSE_FILES build
        docker-compose $COMPOSE_FILES up -d
        ;;
    "logs")
        docker-compose $COMPOSE_FILES logs -f
        ;;
    "pull")
        git pull origin main
        docker-compose $COMPOSE_FILES build wordpress
        docker-compose $COMPOSE_FILES up -d
        ;;
    "status")
        docker-compose $COMPOSE_FILES ps
        ;;
    "wp")
        if [ -z "$2" ]; then
            echo "Please provide WP-CLI command"
            echo "Example: ENVIRONMENT=local ./scripts/manage.sh wp plugin list"
            exit 1
        fi
        # Remove the first argument (wp) and pass the rest to wp-cli
        shift
        docker-compose $COMPOSE_FILES exec -u www-data wordpress wp "$@"
        ;;
    "shell")
        docker-compose $COMPOSE_FILES exec wordpress bash
        ;;
    "db-backup")
        BACKUP_FILE="backup-$(date +%Y%m%d%H%M%S).sql"
        echo "Creating database backup: $BACKUP_FILE"
        docker-compose $COMPOSE_FILES exec -T mysql mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > "backups/$BACKUP_FILE"
        echo "Backup created: backups/$BACKUP_FILE"
        ;;
    "db-restore")
        if [ -z "$2" ]; then
            echo "Please provide backup file path"
            echo "Example: ENVIRONMENT=local ./scripts/manage.sh db-restore backups/backup-file.sql"
            exit 1
        fi
        echo "Restoring database from: $2"
        cat "$2" | docker-compose $COMPOSE_FILES exec -T mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
        echo "Database restored from $2"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|pull|status|wp|shell|db-backup|db-restore}"
        exit 1
        ;;
esac 