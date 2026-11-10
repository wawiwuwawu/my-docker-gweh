# Laravel (PHP 8.3 FPM) — composer deps, front-end assets, then php-fpm runtime.
#
# Assumes the standard Laravel layout: public/index.php is the docroot.
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

FROM node:22-alpine AS assets
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM php:8.3-fpm-alpine AS runtime
WORKDIR /var/www/html
RUN apk add --no-cache icu-dev libzip-dev oniguruma-dev \
    && docker-php-ext-install pdo pdo_mysql bcmath intl zip opcache \
    && addgroup -S laravel && adduser -S laravel -G laravel

COPY --from=vendor /app/vendor ./vendor
COPY . .
COPY --from=assets /app/public/build ./public/build
RUN composer dump-autoload --optimize \
    && chown -R laravel:laravel storage bootstrap/cache

USER laravel
EXPOSE 9000
# php-fpm is the runtime; cache/route optimisation belongs in an entrypoint if needed
CMD ["php-fpm"]
