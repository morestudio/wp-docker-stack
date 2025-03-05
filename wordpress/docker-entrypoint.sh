#!/bin/bash
set -e

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until mysqladmin ping -h"$WORDPRESS_DB_HOST" --silent; do
    sleep 1
done
echo "MySQL is ready!"

# Check if wp-config.php exists
if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php using WP-CLI..."
    # Create the wp-config.php file with WP-CLI
    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --allow-root
    
    # Additional wp-config.php constants if needed
    if [ "$WORDPRESS_DEBUG" = "1" ]; then
        wp config set WP_DEBUG true --raw --allow-root
        wp config set WP_DEBUG_LOG true --raw --allow-root
        wp config set WP_DEBUG_DISPLAY true --raw --allow-root
    fi
    
    # Add Redis configuration if Redis is used
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root

    echo "wp-config.php created successfully"
    
    # Initialize WordPress if database is empty
    if ! $(wp core is-installed --allow-root); then
      echo "WordPress is not installed. Running initial setup..."
      wp core install --allow-root \
        --url="${WORDPRESS_URL:-localhost}" \
        --title="${WORDPRESS_TITLE:-WordPress Site}" \
        --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
        --skip-email
    
      echo "WordPress installed successfully!"
      echo "WordPress URL: ${WORDPRESS_URL:-localhost}"
      
      # Install recommended plugins
      if [ "${INSTALL_REDIS_PLUGIN:-false}" = "true" ]; then
        echo "Installing Redis Object Cache plugin..."
        wp plugin install redis-cache --activate --allow-root
        wp redis enable --allow-root
        echo "Redis Object Cache plugin installed and activated."
      fi
      
      # Set permalink structure
      wp rewrite structure '/%postname%/' --allow-root
      
      # Set up default theme
      if [ -n "${DEFAULT_THEME:-}" ]; then
        echo "Setting default theme to ${DEFAULT_THEME}..."
        wp theme install "${DEFAULT_THEME}" --activate --allow-root
      fi
      
      # Remove default plugins and themes we don't need
      wp plugin delete hello akismet --allow-root
      wp theme delete twentytwenty twentynineteen --allow-root
      
      echo "WordPress setup completed!"
    fi
fi

# Ensure proper permissions
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Create a system link for easy CLI access
if [ ! -e "/usr/bin/wpcli" ]; then
  ln -s /usr/local/bin/wp /usr/bin/wpcli
fi

# Execute the command passed to docker run
exec "$@" 