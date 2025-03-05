#!/bin/bash
set -euo pipefail

# Function to wait for MySQL to be ready
wait_for_mysql() {
  echo "Waiting for MySQL to be ready..."
  for i in {1..30}; do
    if mysql -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
      echo "MySQL is ready!"
      return 0
    fi
    echo "MySQL not ready yet... waiting 2 seconds..."
    sleep 2
  done
  echo "Could not connect to MySQL after 60 seconds"
  return 1
}

# Wait for MySQL to be ready
wait_for_mysql

# Check if wp-config.php exists
if [ ! -f wp-config.php ]; then
  echo "Creating wp-config.php using WP-CLI..."
  
  # Create wp-config.php using WP-CLI
  wp config create --allow-root \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --dbcharset="utf8" \
    --dbcollate="utf8_general_ci" \
    --extra-php <<PHP
define('WP_DEBUG', ${WORDPRESS_DEBUG:-false});

// Add Redis configuration for object caching
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', '6379');


// Set home and site URL automatically
if ( isset( \$_SERVER['HTTP_X_FORWARDED_PROTO'] ) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    \$_SERVER['HTTPS'] = 'on';
}
PHP

  echo "wp-config.php created successfully"
  
  # Initialize WordPress if database is empty
  if ! $(wp core is-installed --allow-root); then
    echo "WordPress is not installed. Running initial setup..."
    wp core install --allow-root \
      --url="${WP_SITEURL:-localhost}" \
      --title="${WP_TITLE:-WordPress Site}" \
      --admin_user="${WP_ADMIN_USER:-admin}" \
      --admin_password="${WP_ADMIN_PASSWORD:-admin}" \
      --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}" \
      --skip-email
    
    echo "WordPress installed successfully!"
    echo "WordPress URL: ${WP_SITEURL:-localhost}"
    
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

# Execute the command passed to the container
exec "$@" 