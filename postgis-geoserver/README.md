# postgis-geoserver

PostgreSQL 17 + PostGIS 3.6 sebagai database geospasial, dipasangkan dengan
GeoServer 2.28 (web UI + WMS/WFS/WCS/WMTS) — varian alternatif dari stack
`postgis-mapserver`. Port host dan nama network/volume sudah dibedakan, jadi
kedua stack boleh berjalan bersamaan bila ingin membandingkan keduanya.

## Layanan

| Service | Image | Port host | Keterangan |
|---|---|---|---|
| db | `postgis/postgis:17-3.6` | 127.0.0.1:5434 | Postgres 17 + PostGIS 3.6 |
| geoserver | `docker.osgeo.org/geoserver:2.28.6` | 8091 | Web UI di `/geoserver`, Rangkaian port: phpmyadmin 8089, pgadmin 8090, geoserver 8091 |

## Pemakaian

```bash
cp .env.example .env
# sesuaikan POSTGRES_PASSWORD dan GEOSERVER_ADMIN_PASSWORD
docker compose up -d
```

- Web UI: <http://localhost:8091/geoserver> — login `admin` /
  `GEOSERVER_ADMIN_PASSWORD` (default bawaan image: `geoserver`).
- Aktifkan ekstensi di database:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

## Menambahkan store PostGIS

1. Login web UI → **Stores → Add new Store → PostGIS**.
2. Isi: host `db`, port `5432`, database/user/password sesuai `.env`
   (nilai sudah tersedia sebagai env di container).
3. Publish layer → layer akan muncul sebagai WMS/WFS di
   `http://localhost:8091/geoserver/wms` dan `/geoserver/wfs`.

Data directory GeoServer tersimpan di named volume `geoserver_data`
(bernama `postgis-geoserver_geoserver-data`), jadi konfigurasi store/layer
bertahan antar restart.

## Database aplikasi (ERP) — opsional

Selain database GIS, stack ini bisa menyiapkan database terpisah untuk
aplikasi (mis. ERP) dengan dua user berhak berbeda:

| User | Hak | Dipakai untuk |
|---|---|---|
| `APP_MIGRATOR_USER` | owner DB, DDL (CREATE/ALTER TABLE) | proses migration |
| `APP_WEB_USER` | DML saja (SELECT/INSERT/UPDATE/DELETE) | runtime aplikasi |

Setup: isi `APP_DB_NAME`, `APP_WEB_USER`, `APP_WEB_PASSWORD`,
`APP_MIGRATOR_USER`, `APP_MIGRATOR_PASSWORD` di `.env`, lalu **up dengan
volume masih kosong** — script `db-init/01-erp.sh` dijalankan otomatis oleh
entrypoint postgres saat pertama kali membuat volume. Kosongkan semua variabel
`APP_*` bila tidak dipakai (init dilewati).

Catatan penting:

- Init script hanya jalan saat volume `postgis-data` masih kosong. Kalau DB
  pernah up dan ingin init ulang: `docker compose down -v` (semua data DB
  hilang) lalu up lagi.
- Tabel-tabel aplikasi TIDAK dibuat init script — itu tugas migration
  aplikasi (url `MIGRATION_DATABASE_URL` pakai user migrator), sedangkan
  runtime pakai url dengan user web (DML-only).

Format connection URL untuk aplikasi:

```
APP_DATABASE_URL=postgres://<APP_WEB_USER>:<APP_WEB_PASSWORD>@127.0.0.1:5434/<APP_DB_NAME>
MIGRATION_DATABASE_URL=postgres://<APP_MIGRATOR_USER>:<APP_MIGRATOR_PASSWORD>@127.0.0.1:5434/<APP_DB_NAME>
```

## Catatan keamanan

- Kedua port di-bind ke `127.0.0.1` secara default; set `LAN_IP=0.0.0.0`
  bila memang perlu akses dari jaringan.
- Setelah setup awal, hapus `GEOSERVER_ADMIN_PASSWORD` dari `.env` — kalau
  variabel itu masih ada, user/role yang ditambah dari UI bisa tertimpa
  setiap container restart (dokumentasi image GeoServer).

## Koneksi DB dari QGIS / aplikasi lain

```
Host: 127.0.0.1  Port: 5434  DB: gis_db  User: postgis_user
```
