/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 13_consolidacion_anual.sql
OBJETIVO:
Revisar y homogeneizar la estructura de las tablas mensuales
antes de consolidar todos los viajes de 2022.
========================================================
*/

USE BiciMAD;
GO

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'trips_22_%'
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;


    /*
========================================================
REVISIÓN DE ESTRUCTURA DE LAS TABLAS MENSUALES
========================================================

RESULTADO:

Se detectaron diferencias de esquema entre los meses:

1. idTrip no está disponible en todos los ficheros.
   Se utilizará nvarchar(max) en la tabla anual y NULL
   en los meses donde no exista.

2. station_unlock y station_lock aparecen como tipos
   numéricos en los primeros meses, pero desde marzo
   pueden contener identificadores alfanuméricos.
   Se homogeneizarán como nvarchar(50).

3. dock_unlock y dock_lock presentan diferentes tipos
   entre meses.
   Se homogeneizarán como nvarchar(50).

4. trip_minutes fue importado como texto para evitar
   pérdida de información durante la carga.
   Tras comprobar que todos los registros son convertibles,
   se almacenará como decimal(10,2) en la tabla anual.

5. lock_date aparece como nvarchar(50) en mayo y junio,
   mientras que en el resto de meses es datetime2.
   Se convertirá a datetime2 durante la consolidación.

6. Las columnas de geolocalización, direcciones y nombres
   presentan diferentes longitudes.
   Se homogeneizarán como nvarchar(max).

DECISIÓN:

No se modificarán las tablas mensuales originales.
La estandarización se realizará durante la creación
de la tabla anual consolidada.
*/

/*
========================================================
CREACIÓN DE LA TABLA ANUAL
========================================================
*/

CREATE TABLE dbo.trips_2022 (
    fecha                  date,
    mes                    tinyint,
    idTrip                 nvarchar(max),
    idBike                 int,
    fleet                  tinyint,
    trip_minutes           decimal(10,2),
    geolocation_unlock     nvarchar(max),
    address_unlock         nvarchar(max),
    unlock_date            datetime2,
    locktype               nvarchar(100),
    unlocktype             nvarchar(100),
    geolocation_lock       nvarchar(max),
    address_lock           nvarchar(max),
    lock_date              datetime2,
    station_unlock         nvarchar(50),
    dock_unlock            nvarchar(50),
    unlock_station_name    nvarchar(max),
    station_lock           nvarchar(50),
    dock_lock              nvarchar(50),
    lock_station_name      nvarchar(max)
);

/*
========================================================
CARGA DE ENERO 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    1 AS mes,
    CAST(idTrip AS nvarchar(max)),
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_01_January;

SELECT COUNT(*) AS enero_cargado
FROM dbo.trips_2022
WHERE mes = 1;

/*
========================================================
CARGA DE FEBRERO 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    2 AS mes,
    NULL AS idTrip,
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_02_February;

SELECT COUNT(*) AS febrero_cargado
FROM dbo.trips_2022
WHERE mes = 2;

/*
========================================================
CARGA DE MARZO 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    3 AS mes,
    CAST(idTrip AS nvarchar(max)),
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_03_March;

SELECT COUNT(*) AS marzo_cargado
FROM dbo.trips_2022
WHERE mes = 3;

/*
========================================================
CARGA DE ABRIL 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    4 AS mes,
    CAST(idTrip AS nvarchar(max)),
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_04_April;

SELECT COUNT(*) AS abril_cargado
FROM dbo.trips_2022
WHERE mes = 4;

/*
========================================================
CARGA DE MAYO 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    5 AS mes,
    CAST(idTrip AS nvarchar(max)),
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    TRY_CONVERT(datetime2, lock_date),
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_05_May;

SELECT COUNT(*) AS mayo_cargado
FROM dbo.trips_2022
WHERE mes = 5;

/*
========================================================
CARGA DE JUNIO 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    6 AS mes,
    CAST(idTrip AS nvarchar(max)),
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    TRY_CONVERT(datetime2, lock_date),
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_06_June;

SELECT COUNT(*) AS junio_cargado
FROM dbo.trips_2022
WHERE mes = 6;

/*
========================================================
CARGA DE JULIO 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    7 AS mes,
    CAST(idTrip AS nvarchar(max)),
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_07_July;

SELECT COUNT(*) AS julio_cargado
FROM dbo.trips_2022
WHERE mes = 7;

/*
========================================================
CARGA DE AGOSTO 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    8 AS mes,
    NULL AS idTrip,
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_08_August;

SELECT COUNT(*) AS agosto_cargado
FROM dbo.trips_2022
WHERE mes = 8;

/*
========================================================
CARGA DE SEPTIEMBRE 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    9 AS mes,
    NULL AS idTrip,
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_09_September;

SELECT COUNT(*) AS septiembre_cargado
FROM dbo.trips_2022
WHERE mes = 9;

/*
========================================================
CARGA DE OCTUBRE 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    10 AS mes,
    NULL AS idTrip,
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_10_October;

SELECT COUNT(*) AS octubre_cargado
FROM dbo.trips_2022
WHERE mes = 10;

/*
========================================================
CARGA DE NOVIEMBRE 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    11 AS mes,
    NULL AS idTrip,
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_11_November;

SELECT COUNT(*) AS noviembre_cargado
FROM dbo.trips_2022
WHERE mes = 11;

/*
========================================================
CARGA DE DICIEMBRE 2022 EN LA TABLA ANUAL
========================================================
*/

INSERT INTO dbo.trips_2022 (
    fecha,
    mes,
    idTrip,
    idBike,
    fleet,
    trip_minutes,
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    station_unlock,
    dock_unlock,
    unlock_station_name,
    station_lock,
    dock_lock,
    lock_station_name
)
SELECT
    fecha,
    12 AS mes,
    NULL AS idTrip,
    idBike,
    fleet,
    TRY_CONVERT(decimal(10,2), trip_minutes),
    geolocation_unlock,
    address_unlock,
    unlock_date,
    locktype,
    unlocktype,
    geolocation_lock,
    address_lock,
    lock_date,
    CAST(station_unlock AS nvarchar(50)),
    CAST(dock_unlock AS nvarchar(50)),
    unlock_station_name,
    CAST(station_lock AS nvarchar(50)),
    CAST(dock_lock AS nvarchar(50)),
    lock_station_name
FROM dbo.trips_22_12_December;

SELECT COUNT(*) AS diciembre_cargado
FROM dbo.trips_2022
WHERE mes = 12;

/*
========================================================
VALIDACIÓN GLOBAL DE LA TABLA ANUAL
========================================================
*/

SELECT
    COUNT(*) AS total_viajes_2022
FROM dbo.trips_2022;

/*
========================================================
VALIDACIÓN DEL NÚMERO DE VIAJES POR MES
========================================================
*/

SELECT
    mes,
    COUNT(*) AS total_viajes
FROM dbo.trips_2022
GROUP BY mes
ORDER BY mes;

/*
========================================================
VALIDACIÓN DE CONVERSIONES EN LA TABLA ANUAL
========================================================
*/

SELECT
    SUM(CASE WHEN trip_minutes IS NULL THEN 1 ELSE 0 END) AS trip_minutes_nulos,
    SUM(CASE WHEN unlock_date IS NULL THEN 1 ELSE 0 END) AS unlock_date_nulos,
    SUM(CASE WHEN lock_date IS NULL THEN 1 ELSE 0 END) AS lock_date_nulos
FROM dbo.trips_2022;

/*
========================================================
VALIDACIÓN DE COHERENCIA ENTRE FECHA Y MES
========================================================
*/

SELECT
    COUNT(*) AS registros_mes_incorrecto
FROM dbo.trips_2022
WHERE MONTH(fecha) <> mes;

/*
========================================================
CONCLUSIONES DE LA CONSOLIDACIÓN ANUAL
========================================================

1. Se consolidaron correctamente los 12 meses de 2022
   en la tabla dbo.trips_2022.

2. El total anual es de 4.143.941 viajes.

3. Los recuentos mensuales coinciden con los resultados
   obtenidos durante la limpieza individual de cada mes.

4. Se homogeneizaron correctamente los tipos de datos:
   - trip_minutes -> decimal(10,2)
   - station_unlock / station_lock -> nvarchar(50)
   - dock_unlock / dock_lock -> nvarchar(50)
   - lock_date -> datetime2
   - columnas de texto variables -> nvarchar(max)

5. Los meses sin idTrip se cargaron con NULL en dicha columna.

6. La conversión de tipos no generó valores nulos inesperados:
   - trip_minutes nulos: 0
   - unlock_date nulos: 0
   - lock_date nulos: 0

7. No se detectaron incoherencias entre la columna mes
   y el mes correspondiente de fecha.

RESULTADO FINAL:

La tabla dbo.trips_2022 queda preparada para comenzar
el análisis exploratorio anual.

========================================================
FIN DE LA CONSOLIDACIÓN ANUAL
========================================================
*/