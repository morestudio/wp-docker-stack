# These ARG instructions define build-time variables with default values
ARG UPLOAD_MAX_FILESIZE=${UPLOAD_MAX_FILESIZE:-64M}
ARG POST_MAX_SIZE=${POST_MAX_SIZE:-64M}
ARG WORDPRESS_DEBUG=${WORDPRESS_DEBUG:-0}
ARG MEMORY_LIMIT=${MEMORY_LIMIT:-256M}
ARG MAX_EXECUTION_TIME=${MAX_EXECUTION_TIME:-300}
ARG MAX_INPUT_VARS=${MAX_INPUT_VARS:-3000}

FROM php:8.3-fpm

# Install dependencies and WordPress extensions
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    mariadb-client \
    less \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mysqli \
    pdo_mysql \
    zip \
    exif \
    opcache

# Install and enable Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Create necessary directories for PHP with secure permissions
RUN mkdir -p /var/log/php-fpm /var/lib/php/sessions /var/www/.opcache \
    && chown -R www-data:www-data /var/log/php-fpm /var/lib/php/sessions /var/www/.opcache \
    && chmod -R 750 /var/log/php-fpm \
    && chmod -R 1733 /var/lib/php/sessions \
    && chmod -R 755 /var/www/.opcache

# Set recommended PHP.ini settings
RUN { \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_vars = 3000'; \
    echo 'date.timezone = UTC'; \
    } > /usr/local/etc/php/conf.d/wordpress-recommended.ini

# Install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && mkdir -p /var/www/.wp-cli/cache \
    && chown -R www-data:www-data /var/www/.wp-cli

# Add wp-cli bash completion
RUN curl -o /etc/bash_completion.d/wp-cli -O https://raw.githubusercontent.com/wp-cli/wp-cli/main/utils/wp-completion.bash

# Set up WordPress
WORKDIR /var/www/html

# Use WP-CLI to download WordPress core
RUN wp core download --allow-root \
    && chown -R www-data:www-data /var/www/html

# Copy WP-CLI configuration and custom packages
COPY ./wp-cli.yml /var/www/html/wp-cli.yml

# Set ownership for WordPress files
RUN chown -R www-data:www-data /var/www/html

# Use custom entrypoint script for initialization
COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["php-fpm"] 