#!/bin/bash
# Init database aplikasi (ERP): dua role dengan hak terpisah (least-privilege).
#   - <APP_MIGRATOR_USER>: owner database, DDL (CREATE/ALTER) — untuk migration
#   - <APP_WEB_USER>:      DML saja (SELECT/INSERT/UPDATE/DELETE) — untuk runtime
#
# Dijalankan otomatis oleh entrypoint image postgres HANYA saat volume data
# masih kosong (pertama kali up). Semua nilai diambil dari env container
# (sumber: .env). Bila APP_DB_NAME kosong, init dilewati (opsional).
set -e

if [ -z "${APP_DB_NAME:-}" ]; then
  echo "APP_DB_NAME kosong — init database aplikasi dilewati (opsional)."
  exit 0
fi

: "${APP_WEB_USER:?APP_WEB_USER tidak terdefinisi (isi .env)}"
: "${APP_WEB_PASSWORD:?APP_WEB_PASSWORD tidak terdefinisi (isi .env)}"
: "${APP_MIGRATOR_USER:?APP_MIGRATOR_USER tidak terdefinisi (isi .env)}"
: "${APP_MIGRATOR_PASSWORD:?APP_MIGRATOR_PASSWORD tidak terdefinisi (isi .env)}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
CREATE ROLE "$APP_WEB_USER" LOGIN PASSWORD '$APP_WEB_PASSWORD';
CREATE ROLE "$APP_MIGRATOR_USER" LOGIN PASSWORD '$APP_MIGRATOR_PASSWORD';
CREATE DATABASE "$APP_DB_NAME" OWNER "$APP_MIGRATOR_USER";
EOSQL

# Hak akses: app_web hanya DML di schema public database aplikasi.
# Owner DB = app_migrator; default privileges membuat tabel BARU hasil
# migration otomatis ter-grant ke app_web.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$APP_DB_NAME" <<-EOSQL
CREATE EXTENSION IF NOT EXISTS postgis;
GRANT USAGE ON SCHEMA public TO "$APP_WEB_USER";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "$APP_WEB_USER";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO "$APP_WEB_USER";
ALTER DEFAULT PRIVILEGES FOR ROLE "$APP_MIGRATOR_USER" IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "$APP_WEB_USER";
ALTER DEFAULT PRIVILEGES FOR ROLE "$APP_MIGRATOR_USER" IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO "$APP_WEB_USER";
EOSQL

echo "init aplikasi selesai: db=$APP_DB_NAME web=$APP_WEB_USER migrator=$APP_MIGRATOR_USER"
