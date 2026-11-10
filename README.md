# my-docker-gweh

Compose configurations from one homelab host (`.116`), plus framework templates for the projects that have to be built rather than pulled.

## Layout

```
<app>/                     one folder per stack that pulls an image (Portainer / CasaOS / plain compose)
  docker-compose.yml
  .env.example             placeholders only
templates/<framework>/     build templates: Dockerfile + compose + .env.example
```

## Where the app files came from

| Origin | Location on the host |
|---|---|
| Portainer stacks | `/data/compose/<stack-id>/docker-compose.yml` inside the Portainer volume |
| CasaOS apps | `/var/lib/casaos/apps/<app>/docker-compose.yml` |
| Project directories | `/home/dede/<project>/docker-compose.yml` |
| `docker-socket-proxy/`, `homepage/` | started with `docker run` — reconstructed from `docker inspect` |


Normalisation applied everywhere: obsolete top-level `version:` dropped, empty `container_name` removed, and **every value whose key looks sensitive** (`*PASS*`, `*SECRET*`, `*TOKEN*`, `*API_KEY*`, URLs with embedded credentials) replaced with `${KEY}`. Real values stayed on the host. Duplicate stacks of the same app were merged into one folder — the variant without a running container was dropped.

## Templates for built projects

| Template | Stack | What it does | Used by |
|---|---|---|---|
| `templates/node-fastify-prisma` | Fastify + Prisma (Node 22, TS) | multi-stage build, `prisma generate` in build, `prisma migrate deploy` at start, Postgres with healthcheck | api-database-film, database-weebase, warung-api, amikom-adaptor |
| `templates/php-laravel` | Laravel (PHP 8.3 FPM) | composer + npm asset stages, nginx + MySQL, storage volume | arsip-soal, porto-ari, bolasoft-arena |
| `templates/node-nextjs` | Next.js (Node 22) | standalone output, non-root user (needs `output: 'standalone'`) | Ampulife-ari |
| `templates/static-vite-react` | Vite SPA (React/Vue) | build then serve with nginx, SPA fallback to index.html | warung-web, Porto |
| `templates/python-worker` | Python worker/bot | slim image, no published port, log rotation, `./data` bind | notifikasi-scrape-web, Notifikasi-scrape-web-via-discord |

Copy a template folder into the project root, then `cp .env.example .env` and `docker compose up -d --build`.

`zcode-gateway/` is kept as its own stack on purpose: it is a deployed service with its own runtime env, not framework boilerplate.

## Usage

```bash
cd <app-directory>
cp .env.example .env   # when present, then edit
docker compose up -d
```

All files (apps and templates) pass YAML validation. Each stack is self-contained: copy `.env.example` to `.env`, adjust values (defaults work for local data under `./data`), then `docker compose up -d`.

## Shared networks

One external Docker network is shared across stacks:

| Network | Created by | Consumed by |
|---|---|---|
| `network-shared-db` | `mysql-shared` (declares it with `name: network-shared-db`) | `databasement`, `mysqld-exporter`, `mailhog` |

Start `mysql-shared` first (`docker compose up -d` inside `mysql-shared/`); the consumer stacks fail until the network exists. On a fresh host:

```bash
docker network create network-shared-db   # or start mysql-shared first
```

## Apps

| Folder | Services | Image(s) | Build | .env |
|---|---|---|---|---|
| `9router` | 9router | decolua/9router:0.5.116 | — | yes |
| `anaconda3` | anaconda3 | continuumio/anaconda3:2024.10-1 | — | yes |
| `big-bear-glances` | big-bear-glances | nicolargo/glances:4.3.0.8-full | — | — |
| `big-bear-ntfy` | app | binwiederhier/ntfy:v2.25.0 | — | — |
| `big-bear-phpmyadmin` | phpmyadmin | phpmyadmin/phpmyadmin:5.2.2 | — | yes |
| `big-bear-portainer` | app | portainer/portainer-ce:2.33.1-alpine | — | — |
| `big-bear-stirling-pdf` | stirling-pdf | stirlingtools/stirling-pdf:2.14.0 | — | yes |
| `changedetection` | changedetection, playwright-chrome | dgtlmoon/changedetection.io:0.70<br>dgtlmoon/sockpuppetbrowser:0.0.3 | — | — |
| `cloudflared` | cloudflared | wisdomsky/cloudflared-web:2026.5.0 | — | — |
| `databasement` | app, worker | davidcrty/databasement:1 | — | yes |
| `docker-socket-proxy` | proxy | alpine/socat:1.8.1.3 | — | — |
| `flaresolverr` | flaresolverr | ghcr.io/flaresolverr/flaresolverr:v3.4.6 | — | — |
| `ghost` | ghost, db | ghost:5-alpine<br>mysql:8.0 | — | yes |
| `homepage` | homepage | ghcr.io/gethomepage/homepage:v2.7.0 | — | yes |
| `immich-v2-complete` | immich-server, immich-machine-learning, db, redis | ghcr.io/immich-app/immich-server:v3.4.0<br>ghcr.io/immich-app/immich-machine-learning:v3.4.0<br>ghcr.io/immich-app/postgres:14-vectorchord0.3.0-pgvectors0.2.0<br>redis:6.2-alpine | — | yes |
| `jenkins-server` | jenkins | jenkins/jenkins:2.590 | — | — |
| `kavita` | kavita | jvmilazz0/kavita:0.9.1 | — | yes |
| `koharu` | koharu | ghcr.io/mayocream/koharu:0.46.0 | — | yes |
| `kutt-service` | kutt, kutt-redis | kutt/kutt:v3.2.6<br>redis:7-alpine | — | yes |
| `linuxserver-kali-linux` | app | linuxserver/kali-linux:version-3b400208 | — | — |
| `linuxserver-nginx` | app | linuxserver/nginx:1.28.0 | — | — |
| `linuxserver-prowlarr` | app | linuxserver/prowlarr:2.7.0 | — | — |
| `linuxserver-sonarr` | app | linuxserver/sonarr:4.0.20 | — | yes |
| `mailhog` | mailhog | mailhog/mailhog:v1.0.1 | — | — |
| `mariadb` | mariadb | linuxserver/mariadb:11.4.5 | — | yes |
| `minio_s3_local` | minio | quay.io/minio/minio:RELEASE.2025-10-15T17-29-55Z | — | yes |
| `myspeed` | myspeed | germannewsmaker/myspeed:1.0.9 | — | — |
| `mysql-shared` | db-mysql, phpmyadmin, db-postgres, pgadmin | mysql:8.0<br>phpmyadmin:5.2<br>postgres:15-alpine<br>dpage/pgadmin4:9.19 | — | yes |
| `mysqld-exporter` | mysqld-exporter, postgres-exporter-app1 | prom/mysqld-exporter:v0<br>prometheuscommunity/postgres-exporter:v0 | — | yes |
| `nginx-portrainer` | nginx | linuxserver/nginx:1.30.6 | — | — |
| `nginxproxymanager` | nginxproxymanager | jc21/nginx-proxy-manager:2.12.3 | — | — |
| `node-exporter` | node-exporter, cadvisor, promtail | prom/node-exporter:v1<br>ghcr.io/google/cadvisor:v0.60.6<br>grafana/promtail:3.6.9 | — | — |
| `omniroute` | omniroute | diegosouzapw/omniroute:3.8.53 | — | — |
| `openspeedtest` | openspeedtest | openspeedtest/latest:v2.0.6 | — | — |
| `openwebui` | openwebui | ghcr.io/open-webui/open-webui:v0.13.3-slim | — | — |
| `paperless-ngx` | broker, db, gotenberg, tika, webserver | docker.io/library/redis:7<br>docker.io/library/postgres:16<br>docker.io/gotenberg/gotenberg:8<br>docker.io/apache/tika:4.2.0<br>ghcr.io/paperless-ngx/paperless-ngx:3.4.2 | — | yes |
| `postgis-geoserver` | db, geoserver | postgis/postgis:17-3.6<br>docker.osgeo.org/geoserver:2.28.6 | — | yes |
| `postgis-mapserver` | db, mapserver | postgis/postgis:17-3.6<br>camptocamp/mapserver:8.6-gdal3.12 | — | yes |
| `qbittorrent` | qbittorrent | ghcr.io/hotio/qbittorrent:release-5.0.4 | — | yes |
| `slskd` | slskd, soularr | slskd/slskd:0.26.2<br>ghcr.io/mrusse/soularr:1.2.3 | — | yes |
| `uptimekuma` | uptimekuma | louislam/uptime-kuma:1.23.16 | — | — |
| `vaultwarden` | vaultwarden | vaultwarden/server:1.37.5 | — | — |
| `zcode-gateway` | zcode-gateway | zcode-gateway:local | yes | yes |

Image tags are pinned to a verified major (or exact) version; floating `:latest`/`:release` tags are gone. Bump deliberately, not silently.

## Security notes

- `docker-socket-proxy` exposes the Docker API. It is pinned to `127.0.0.1` here; anyone who reaches that port controls the host. Remove the stack if it is not needed.

- `.env.example` files hold placeholders only. Never commit a filled `.env`.

- Database and admin ports (MySQL, MariaDB, Postgres, phpMyAdmin, pgAdmin, MailHog) are bound to `127.0.0.1`. Change the bind only if you understand the exposure.

- `linuxserver-kali-linux` intentionally does **not** mount `docker.sock` (a root-equivalent hole through its exposed web UI). `jenkins-server` keeps the socket for CI but runs without `privileged`/`user: root`.

- `databasement`: the Laravel `APP_KEY` that was committed here historically is considered compromised — generate a new one (`php artisan key:generate --show`) when deploying.

- `big-bear-stirling-pdf` ships with login enabled; set real credentials in `.env`.

- `ghost`, `databasement`, `mysqld-exporter`/`promtail` previously pointed at absolute host paths (`/DATA/AppData`, `/storage/...`, `/etc/...`). All are now env vars defaulting to `./data`, and the exporter configs ship as starter files (`promtail-config.yml`, `mysqld-exporter/config/.my.cnf.example`).

