/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 17_station_master.sql

OBJETIVO:

Crear una tabla maestra de estaciones BiciMAD a partir
de los datos de station_status_2022.

La tabla tendrá una fila por station_id y servirá como
dimensión de estaciones para análisis posteriores y Power BI.
========================================================
*/

USE BiciMAD;
GO

/*
========================================================
1. CREACIÓN DE DIMENSIÓN DE ESTACIONES
========================================================
*/

CREATE TABLE dbo.dim_station (
    station_id     int PRIMARY KEY,
    station_number nvarchar(20),
    station_name   nvarchar(200),
    address        nvarchar(300),
    latitude       decimal(12,8),
    longitude      decimal(12,8)
);

SELECT TOP 5 *
FROM dbo.dim_station;

/*
========================================================
2. CARGA DE LA DIMENSIÓN DE ESTACIONES
========================================================
*/

INSERT INTO dbo.dim_station (
    station_id,
    station_number,
    station_name,
    address,
    latitude,
    longitude
)
SELECT
    station_id,
    MAX(station_number) AS station_number,
    MAX(station_name) AS station_name,
    MAX(address) AS address,
    MAX(latitude) AS latitude,
    MAX(longitude) AS longitude
FROM dbo.station_status_2022
GROUP BY station_id;

SELECT COUNT(*) AS total_estaciones
FROM dbo.dim_station;

/*
========================================================
3. VALIDACIÓN DE DIM_STATION
========================================================
*/

SELECT
    SUM(CASE WHEN station_id IS NULL THEN 1 ELSE 0 END) AS station_id_nulos,
    SUM(CASE WHEN station_number IS NULL THEN 1 ELSE 0 END) AS station_number_nulos,
    SUM(CASE WHEN station_name IS NULL THEN 1 ELSE 0 END) AS station_name_nulos,
    SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS latitude_nulos,
    SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END) AS longitude_nulos
FROM dbo.dim_station;

/*
========================================================
4. VALIDACIÓN DE ESTABILIDAD DE ATRIBUTOS
========================================================
*/

SELECT
    SUM(CASE WHEN nombres > 1 THEN 1 ELSE 0 END) AS estaciones_con_varios_nombres,
    SUM(CASE WHEN numeros > 1 THEN 1 ELSE 0 END) AS estaciones_con_varios_numeros
FROM (
    SELECT
        station_id,
        COUNT(DISTINCT station_name) AS nombres,
        COUNT(DISTINCT station_number) AS numeros
    FROM dbo.station_status_2022
    GROUP BY station_id
) x;

/*
========================================================
CIERRE DEL ARCHIVO 17_station_master.sql
========================================================

RESULTADO FINAL:

- Se creó dbo.dim_station.
- Total de estaciones: 264.
- 0 nulos en los campos principales.
- Cada station_id mantiene un único station_number.
- Cada station_id mantiene un único station_name.

La tabla queda preparada para usarse como dimensión
de estaciones en análisis posteriores y Power BI.

========================================================
FIN DEL ARCHIVO
========================================================
*/