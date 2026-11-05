/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 15_station_status_import.sql
OBJETIVO:
Importar y transformar los datos históricos de estado
de las estaciones BiciMAD durante 2022.
========================================================
*/

USE BiciMAD;
GO

/*
========================================================
1. TABLA STAGING PARA JSON
========================================================
*/

CREATE TABLE dbo.station_status_json_staging (
    json_line nvarchar(max)
);

/*
========================================================
2. CARGA DEL JSON DE ENERO 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202201.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_enero
FROM dbo.station_status_json_staging;

SELECT TOP 5
    JSON_VALUE(json_line, '$._id') AS snapshot_time
FROM dbo.station_status_json_staging;

/*
========================================================
3. CREACIÓN DE TABLA DE ESTADO DE ESTACIONES
========================================================
*/

CREATE TABLE dbo.station_status_2022 (
    snapshot_time      datetime2,
    station_id         int,
    station_number     nvarchar(20),
    station_name       nvarchar(200),
    address            nvarchar(300),
    latitude           decimal(12,8),
    longitude          decimal(12,8),
    total_bases        int,
    free_bases         int,
    dock_bikes         int,
    reservations_count int,
    no_available       int,
    activate           int,
    light              int
);

/*
========================================================
4. EXPANSIÓN DEL JSON DE ENERO
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS filas_estado_enero
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    GROUP BY snapshot_time
) x;

SELECT
    MIN(snapshot_time) AS primer_snapshot,
    MAX(snapshot_time) AS ultimo_snapshot
FROM dbo.station_status_2022;
SELECT
    SUM(CASE WHEN snapshot_time IS NULL THEN 1 ELSE 0 END) AS snapshot_nulos,
    SUM(CASE WHEN station_id IS NULL THEN 1 ELSE 0 END) AS station_id_nulos,
    SUM(CASE WHEN station_name IS NULL THEN 1 ELSE 0 END) AS station_name_nulos,
    SUM(CASE WHEN total_bases IS NULL THEN 1 ELSE 0 END) AS total_bases_nulos,
    SUM(CASE WHEN free_bases IS NULL THEN 1 ELSE 0 END) AS free_bases_nulos,
    SUM(CASE WHEN dock_bikes IS NULL THEN 1 ELSE 0 END) AS dock_bikes_nulos
FROM dbo.station_status_2022;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
5. CARGA DEL JSON DE FEBRERO 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202202.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_febrero
FROM dbo.station_status_json_staging;

/*
========================================================
6. EXPANSIÓN DEL JSON DE FEBRERO
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    MIN(snapshot_time) AS primer_snapshot_febrero,
    MAX(snapshot_time) AS ultimo_snapshot_febrero
FROM dbo.station_status_2022
WHERE snapshot_time >= '2022-02-01'
  AND snapshot_time <  '2022-03-01';

  SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-02-01'
      AND snapshot_time <  '2022-03-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
7. CARGA DEL JSON DE MARZO 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202203.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_marzo
FROM dbo.station_status_json_staging;

/*
========================================================
8. EXPANSIÓN DEL JSON DE MARZO
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-03-01'
      AND snapshot_time <  '2022-04-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
9. CARGA DEL JSON DE ABRIL 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202204.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_abril
FROM dbo.station_status_json_staging;

/*
========================================================
10. EXPANSIÓN DEL JSON DE ABRIL
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-04-01'
      AND snapshot_time <  '2022-05-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
11. CARGA DEL JSON DE MAYO 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202205.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_mayo
FROM dbo.station_status_json_staging;

/*
========================================================
12. EXPANSIÓN DEL JSON DE MAYO
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-05-01'
      AND snapshot_time <  '2022-06-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
13. CARGA DEL JSON DE JUNIO 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202206.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_junio
FROM dbo.station_status_json_staging;

SELECT
    COUNT(*) AS total_lineas,
    SUM(CASE WHEN ISJSON(json_line) = 1 THEN 1 ELSE 0 END) AS json_validos
FROM dbo.station_status_json_staging;

/*
========================================================
14. EXPANSIÓN DEL JSON DE JUNIO
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-06-01'
      AND snapshot_time <  '2022-07-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
15. CARGA DEL JSON DE JULIO 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202207.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_julio
FROM dbo.station_status_json_staging;

/*
========================================================
16. EXPANSIÓN DEL JSON DE JULIO
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-07-01'
      AND snapshot_time <  '2022-08-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
17. CARGA DEL JSON DE AGOSTO 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202208.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_agosto
FROM dbo.station_status_json_staging;

/*
========================================================
18. EXPANSIÓN DEL JSON DE AGOSTO
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-08-01'
      AND snapshot_time <  '2022-09-01'
    GROUP BY snapshot_time
) x;

SELECT
    COUNT(*) AS filas_agosto,
    COUNT(DISTINCT snapshot_time) AS snapshots_agosto
FROM dbo.station_status_2022
WHERE snapshot_time >= '2022-08-01'
  AND snapshot_time <  '2022-09-01';

  SELECT
    MIN(repeticiones) AS min_repeticiones,
    MAX(repeticiones) AS max_repeticiones
FROM (
    SELECT
        snapshot_time,
        station_id,
        COUNT(*) AS repeticiones
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-08-01'
      AND snapshot_time <  '2022-09-01'
    GROUP BY snapshot_time, station_id
) x;

WITH duplicados AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY snapshot_time, station_id
            ORDER BY snapshot_time
        ) AS rn
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-08-01'
      AND snapshot_time <  '2022-09-01'
)
DELETE FROM duplicados
WHERE rn > 1;

SELECT
    COUNT(*) AS filas_agosto,
    COUNT(DISTINCT snapshot_time) AS snapshots_agosto
FROM dbo.station_status_2022
WHERE snapshot_time >= '2022-08-01'
  AND snapshot_time <  '2022-09-01';

  SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-08-01'
      AND snapshot_time <  '2022-09-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
19. CARGA DEL JSON DE SEPTIEMBRE 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202209.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_septiembre
FROM dbo.station_status_json_staging;

/*
========================================================
20. EXPANSIÓN DEL JSON DE SEPTIEMBRE
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-09-01'
      AND snapshot_time <  '2022-10-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;


/*
========================================================
21. CARGA DEL JSON DE OCTUBRE 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202210.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_octubre
FROM dbo.station_status_json_staging;

/*
========================================================
22. EXPANSIÓN DEL JSON DE OCTUBRE
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-10-01'
      AND snapshot_time <  '2022-11-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
23. CARGA DEL JSON DE NOVIEMBRE 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202211.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_noviembre
FROM dbo.station_status_json_staging;

/*
========================================================
24. EXPANSIÓN DEL JSON DE NOVIEMBRE
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-11-01'
      AND snapshot_time <  '2022-12-01'
    GROUP BY snapshot_time
) x;

TRUNCATE TABLE dbo.station_status_json_staging;

/*
========================================================
25. CARGA DEL JSON DE DICIEMBRE 2022
========================================================
*/

BULK INSERT dbo.station_status_json_staging
FROM 'C:\Users\Sistemas\Desktop\BOOTCAMP DATA\Master Data Sciencie & AI\BiciMADRID\bicimad_2022\202212.json'
WITH (
    ROWTERMINATOR = '0x0a',
    FIELDTERMINATOR = '0x0b',
    CODEPAGE = '65001'
);

SELECT COUNT(*) AS total_snapshots_diciembre
FROM dbo.station_status_json_staging;

/*
========================================================
26. EXPANSIÓN DEL JSON DE DICIEMBRE
========================================================
*/

INSERT INTO dbo.station_status_2022 (
    snapshot_time,
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude,
    total_bases,
    free_bases,
    dock_bikes,
    reservations_count,
    no_available,
    activate,
    light
)
SELECT
    TRY_CONVERT(datetime2, JSON_VALUE(s.json_line, '$._id')) AS snapshot_time,
    j.id,
    j.number,
    j.name,
    j.address,
    TRY_CONVERT(decimal(12,8), j.latitude),
    TRY_CONVERT(decimal(12,8), j.longitude),
    j.total_bases,
    j.free_bases,
    j.dock_bikes,
    j.reservations_count,
    j.no_available,
    j.activate,
    j.light
FROM dbo.station_status_json_staging s
CROSS APPLY OPENJSON(s.json_line, '$.stations')
WITH (
    id                 int            '$.id',
    number             nvarchar(20)   '$.number',
    name               nvarchar(200)  '$.name',
    address            nvarchar(300)  '$.address',
    latitude           nvarchar(50)   '$.latitude',
    longitude          nvarchar(50)   '$.longitude',
    total_bases        int            '$.total_bases',
    free_bases         int            '$.free_bases',
    dock_bikes         int            '$.dock_bikes',
    reservations_count int            '$.reservations_count',
    no_available       int            '$.no_available',
    activate           int            '$.activate',
    light              int            '$.light'
) j;

SELECT COUNT(*) AS total_filas_acumuladas
FROM dbo.station_status_2022;

SELECT
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(estaciones_por_snapshot) AS min_estaciones,
    MAX(estaciones_por_snapshot) AS max_estaciones
FROM (
    SELECT
        snapshot_time,
        COUNT(*) AS estaciones_por_snapshot
    FROM dbo.station_status_2022
    WHERE snapshot_time >= '2022-12-01'
      AND snapshot_time <  '2023-01-01'
    GROUP BY snapshot_time
) x;

/*
========================================================
27. VALIDACIÓN ANUAL DE STATION STATUS 2022
========================================================
*/

SELECT
    COUNT(*) AS total_filas,
    COUNT(DISTINCT snapshot_time) AS total_snapshots,
    MIN(snapshot_time) AS primer_snapshot,
    MAX(snapshot_time) AS ultimo_snapshot
FROM dbo.station_status_2022;

/*
========================================================
28. COMPROBACIÓN DE DUPLICADOS ANUALES
========================================================
*/

SELECT COUNT(*) AS combinaciones_duplicadas
FROM (
    SELECT
        snapshot_time,
        station_id
    FROM dbo.station_status_2022
    GROUP BY snapshot_time, station_id
    HAVING COUNT(*) > 1
) x;

/*
========================================================
29. NÚMERO DE ESTACIONES DISTINTAS EN 2022
========================================================
*/

SELECT COUNT(DISTINCT station_id) AS estaciones_distintas
FROM dbo.station_status_2022;

/*
========================================================
30. ESTADOS CRÍTICOS DE DISPONIBILIDAD
========================================================
*/

SELECT
    SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END) AS veces_sin_bicis,
    SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END) AS veces_sin_bases_libres
FROM dbo.station_status_2022;

/*
========================================================
31. ESTADO OPERATIVO DE LAS ESTACIONES
========================================================
*/

SELECT
    activate,
    no_available,
    COUNT(*) AS registros
FROM dbo.station_status_2022
GROUP BY
    activate,
    no_available
ORDER BY
    activate,
    no_available;

    /*
========================================================
32. ESTADOS CRÍTICOS SOLO EN ESTACIONES OPERATIVAS
========================================================
*/

SELECT
    SUM(CASE 
            WHEN no_available = 0 AND dock_bikes = 0 
            THEN 1 ELSE 0 
        END) AS veces_sin_bicis_operativa,

    SUM(CASE 
            WHEN no_available = 0 AND free_bases = 0 
            THEN 1 ELSE 0 
        END) AS veces_sin_bases_libres_operativa
FROM dbo.station_status_2022;

/*
========================================================
33. ESTACIONES CON MÁS EPISODIOS SIN BICICLETAS
========================================================
*/

SELECT TOP 15
    station_id,
    station_number,
    station_name,
    COUNT(*) AS veces_sin_bicis
FROM dbo.station_status_2022
WHERE no_available = 0
  AND dock_bikes = 0
GROUP BY
    station_id,
    station_number,
    station_name
ORDER BY veces_sin_bicis DESC;

/*
========================================================
34. PORCENTAJE DE TIEMPO SIN BICICLETAS POR ESTACIÓN
========================================================
*/

SELECT TOP 15
    station_id,
    station_number,
    station_name,
    COUNT(*) AS snapshots_operativos,
    SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END) AS snapshots_sin_bicis,
    ROUND(
        100.0 * SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS pct_sin_bicis
FROM dbo.station_status_2022
WHERE no_available = 0
GROUP BY
    station_id,
    station_number,
    station_name
ORDER BY pct_sin_bicis DESC;

/*
========================================================
35. PORCENTAJE DE TIEMPO SIN BASES LIBRES POR ESTACIÓN
========================================================
*/

SELECT TOP 15
    station_id,
    station_number,
    station_name,
    COUNT(*) AS snapshots_operativos,
    SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END) AS snapshots_sin_huecos,
    ROUND(
        100.0 * SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS pct_sin_huecos
FROM dbo.station_status_2022
WHERE no_available = 0
GROUP BY
    station_id,
    station_number,
    station_name
ORDER BY pct_sin_huecos DESC;

/*
========================================================
36. ESTACIONES CON PROBLEMAS EN AMBOS SENTIDOS
========================================================
*/

SELECT TOP 20
    station_id,
    station_number,
    station_name,
    COUNT(*) AS snapshots_operativos,

    SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END) AS snapshots_sin_bicis,

    SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END) AS snapshots_sin_huecos,

    ROUND(
        100.0 * SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS pct_sin_bicis,

    ROUND(
        100.0 * SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS pct_sin_huecos

FROM dbo.station_status_2022
WHERE no_available = 0
GROUP BY
    station_id,
    station_number,
    station_name
ORDER BY
    (
        100.0 * SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END) / COUNT(*)
        +
        100.0 * SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END) / COUNT(*)
    ) DESC;

    /*
========================================================
37. ESTACIONES CON DESEQUILIBRIO EN AMBOS SENTIDOS
========================================================
*/

WITH resumen AS (
    SELECT
        station_id,
        station_number,
        station_name,
        COUNT(*) AS snapshots_operativos,

        100.0 * SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END)
        / COUNT(*) AS pct_sin_bicis,

        100.0 * SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END)
        / COUNT(*) AS pct_sin_huecos

    FROM dbo.station_status_2022
    WHERE no_available = 0
    GROUP BY
        station_id,
        station_number,
        station_name
)

SELECT TOP 20
    station_id,
    station_number,
    station_name,
    snapshots_operativos,
    ROUND(pct_sin_bicis, 2) AS pct_sin_bicis,
    ROUND(pct_sin_huecos, 2) AS pct_sin_huecos
FROM resumen
WHERE pct_sin_bicis >= 2
  AND pct_sin_huecos >= 2
ORDER BY
    pct_sin_bicis + pct_sin_huecos DESC;

    /*
INTERPRETACIÓN:

Se identificaron estaciones que presentan problemas de disponibilidad
en ambos sentidos, es decir, periodos sin bicicletas disponibles y
periodos sin bases libres para devolver bicicletas.

Para evitar clasificar como problemáticas estaciones con incidencias
aisladas, se filtraron aquellas con al menos un 2% de snapshots
operativos sin bicicletas y al menos un 2% sin huecos libres.

Los resultados muestran distintos patrones:
- Algunas estaciones, como Paseo de la Castellana - Glorieta de Emilio
  Castelar, presentan principalmente falta de bicicletas.
- Otras, como Antón Martín, presentan más problemas de saturación,
  con mayor porcentaje de snapshots sin bases libres.
- Estaciones como Plaza de Lavapiés muestran un desequilibrio más
  repartido entre ambos tipos de problema.

Este análisis permite diferenciar entre estaciones con déficit de
bicicletas y estaciones con exceso de llegadas, información útil para
analizar posibles necesidades de redistribución.
*/

/*
========================================================
CIERRE DEL ARCHIVO 15_station_status_import.sql

RESULTADO FINAL:

- Se importaron los 12 meses de station status de 2022.
- Total de filas: 2.306.832
- Total de snapshots: 8.738
- Total de estaciones distintas: 264
- Periodo cubierto:
  2022-01-01 a 2022-12-31

VALIDACIONES REALIZADAS:

- 0 duplicados por snapshot_time + station_id.
- 264 estaciones por snapshot.
- 0 nulos en los campos principales.
- Se detectaron y corrigieron duplicados en agosto.
- Se diferenciaron estados operativos mediante no_available.

ANÁLISIS REALIZADO:

- Frecuencia de estaciones sin bicicletas.
- Frecuencia de estaciones sin bases libres.
- Porcentaje de tiempo operativo en estado crítico.
- Identificación de estaciones con problemas en ambos sentidos.

SIGUIENTE FASE:

Cruzar el estado de las estaciones con los viajes de dbo.trips_2022
para estudiar si los desequilibrios de entradas y salidas coinciden
con problemas reales de disponibilidad.
========================================================
*/