# postgis-mapserver

PostgreSQL 17 + PostGIS 3.6 sebagai database geospasial, dipasangkan dengan
MapServer 8 (CGI/FastCGI) untuk melayani WMS/WFS dari data di database.

## Layanan

| Service | Image | Port host | Keterangan |
|---|---|---|---|
| db | `postgis/postgis:17-3.6` | 127.0.0.1:5433 | Postgres 17 + PostGIS 3.6 (port 5433 agar tidak bentrok `postgres-shared` di mysql-shared) |
| mapserver | `camptocamp/mapserver:8.6-gdal3.12` | 8989 | WMS/WFS/OGC API endpoint |

Catatan: image resmi `mapserver/mapserver` di Docker Hub stagnan di v7.4.2;
`camptocamp/mapserver` adalah image yang aktif dirawat (tag per minor release).

## Pemakaian

```bash
cp .env.example .env
# sesuaikan POSTGRES_PASSWORD
docker compose up -d
```

Aktifkan ekstensi PostGIS di database:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

## Mapfile & data

- Mapfile: `config/mapfiles/` dipasang read-only ke `/etc/mapserver` di container.
- Data geospasial (shapefile/GeoTIFF dsb.): taruh di `data/` (atau set
  `GIS_DATA_DIR`), dipasang read-only ke `/mapdata`.
- Contoh `demo.map` menyediakan layer PostGIS `peta_coba` (buat tabelnya atau
  sesuaikan CONNECTION/DATA).

Mapfile dipilih via parameter `?map=`; `MS_MAP_PATTERN` membatasi path yang
boleh dimuat ke `/etc/mapserver/*.map` agar tidak ada file arbitrer yang bisa
dibaca MapServer.

## Uji cepat (GetCapabilities)

```
http://localhost:8989/?map=/etc/mapserver/demo.map&service=WMS&request=GetCapabilities
http://localhost:8989/?map=/etc/mapserver/demo.map&service=WFS&request=GetCapabilities
```

## Koneksi dari QGIS / aplikasi lain

```
Host: 127.0.0.1  Port: 5433  DB: gis_db  User: postgis_user
```

DB hanya di-bind ke localhost — untuk akses dari mesin lain, set
`LAN_IP=0.0.0.0` pada port MapServer, dan gunakan tunnel (mis.
`ssh -L 5433:127.0.0.1:5433`) untuk akses database dari luar host.

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
  aplikasi (`MIGRATION_DATABASE_URL` pakai user migrator), sedangkan runtime
  pakai url dengan user web (DML-only).

Format connection URL untuk aplikasi:

```
APP_DATABASE_URL=postgres://<APP_WEB_USER>:<APP_WEB_PASSWORD>@127.0.0.1:5433/<APP_DB_NAME>
MIGRATION_DATABASE_URL=postgres://<APP_MIGRATOR_USER>:<APP_MIGRATOR_PASSWORD>@127.0.0.1:5433/<APP_DB_NAME>
```
