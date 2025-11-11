FROM php:8.3-fpm

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Criar usuário www-data
RUN groupadd -g 1000 www-data 2>/dev/null || true \
    && useradd -u 1000 -g www-data -m -s /bin/bash www-data 2>/dev/null || true

# Definir diretório de trabalho
WORKDIR /var/www/html

# Copiar arquivos da aplicação
COPY --chown=www-data:www-data . /var/www/html

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Instalar Xdebug para code coverage
RUN pecl install xdebug-3.3.1 \
    && docker-php-ext-enable xdebug

# Configurar Xdebug (sobrescrever qualquer configuração existente)
RUN rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "zend_extension=xdebug" > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=no" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.output_dir=/tmp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Mudar para usuário www-data
USER www-data

# Expor porta do PHP-FPM
EXPOSE 9000

# Comando padrão
CMD ["php-fpm"]
