/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 18_powerbi_views.sql

OBJETIVO:

Crear vistas SQL preparadas para Power BI,
simplificando el modelo de datos y dejando
listas las principales métricas y dimensiones
para visualización.
========================================================
*/

USE BiciMAD;
GO

/*
========================================================
1. VISTA DE VIAJES NORMALIZADOS
========================================================
*/

CREATE VIEW dbo.vw_trips_powerbi AS

SELECT
    t.fecha,
    t.mes,
    t.idBike,
    t.fleet,
    t.trip_minutes,
    t.unlock_date,
    t.lock_date,

    mu.station_id AS station_unlock_id,
    ml.station_id AS station_lock_id,

    t.es_viaje_breve_circular

FROM dbo.trips_2022 t

LEFT JOIN dbo.station_id_mapping mu
    ON t.station_unlock = mu.trip_station_code

LEFT JOIN dbo.station_id_mapping ml
    ON t.station_lock = ml.trip_station_code;

    /*
========================================================
2. VALIDACIÓN DE VW_TRIPS_POWERBI
========================================================
*/

SELECT
    COUNT(*) AS total_filas,
    SUM(CASE WHEN station_unlock_id IS NULL THEN 1 ELSE 0 END) AS origen_sin_mapear,
    SUM(CASE WHEN station_lock_id IS NULL THEN 1 ELSE 0 END) AS destino_sin_mapear
FROM dbo.vw_trips_powerbi;

/*
========================================================
3. VALIDACIÓN DE ESTACIONES SIN MAPEAR
========================================================
*/

SELECT
    SUM(CASE WHEN station_unlock IS NULL THEN 1 ELSE 0 END)
        AS origen_null_original,

    SUM(CASE WHEN station_lock IS NULL THEN 1 ELSE 0 END)
        AS destino_null_original

FROM dbo.trips_2022;

/*
========================================================
4. VISTA DE DISPONIBILIDAD DE ESTACIONES
========================================================
*/

CREATE VIEW dbo.vw_station_status_powerbi AS

SELECT
    s.snapshot_time,
    s.station_id,
    d.station_number,
    d.station_name,
    d.address,
    d.latitude,
    d.longitude,
    s.total_bases,
    s.free_bases,
    s.dock_bikes,
    s.reservations_count,
    s.no_available,
    s.activate,
    s.light,

    CASE
        WHEN s.no_available = 0 AND s.dock_bikes = 0 THEN 1
        ELSE 0
    END AS is_empty,

    CASE
        WHEN s.no_available = 0 AND s.free_bases = 0 THEN 1
        ELSE 0
    END AS is_full

FROM dbo.station_status_2022 s
INNER JOIN dbo.dim_station d
    ON s.station_id = d.station_id;

    /*
========================================================
5. VALIDACIÓN DE VW_STATION_STATUS_POWERBI
========================================================
*/

SELECT
    COUNT(*) AS total_filas,
    SUM(is_empty) AS registros_estacion_vacia,
    SUM(is_full) AS registros_estacion_llena
FROM dbo.vw_station_status_powerbi;

/*
========================================================
6. VISTA RESUMEN DE ESTACIONES PARA POWER BI
========================================================
*/

CREATE VIEW dbo.vw_station_summary_powerbi AS

WITH salidas AS (
    SELECT
        station_unlock_id AS station_id,
        COUNT(*) AS viajes_salida
    FROM dbo.vw_trips_powerbi
    WHERE station_unlock_id IS NOT NULL
      AND es_viaje_breve_circular = 0
    GROUP BY station_unlock_id
),

llegadas AS (
    SELECT
        station_lock_id AS station_id,
        COUNT(*) AS viajes_llegada
    FROM dbo.vw_trips_powerbi
    WHERE station_lock_id IS NOT NULL
      AND es_viaje_breve_circular = 0
    GROUP BY station_lock_id
),

disponibilidad AS (
    SELECT
        station_id,
        COUNT(*) AS snapshots_operativos,
        SUM(is_empty) AS snapshots_sin_bicis,
        SUM(is_full) AS snapshots_sin_huecos
    FROM dbo.vw_station_status_powerbi
    WHERE no_available = 0
    GROUP BY station_id
)

SELECT
    d.station_id,
    d.station_number,
    d.station_name,
    d.address,
    d.latitude,
    d.longitude,

    ISNULL(s.viajes_salida, 0) AS viajes_salida,
    ISNULL(l.viajes_llegada, 0) AS viajes_llegada,

    ISNULL(l.viajes_llegada, 0)
      - ISNULL(s.viajes_salida, 0) AS balance_neto,

    disp.snapshots_operativos,
    disp.snapshots_sin_bicis,
    disp.snapshots_sin_huecos,

    ROUND(
        100.0 * disp.snapshots_sin_bicis
        / NULLIF(disp.snapshots_operativos, 0),
        2
    ) AS pct_sin_bicis,

    ROUND(
        100.0 * disp.snapshots_sin_huecos
        / NULLIF(disp.snapshots_operativos, 0),
        2
    ) AS pct_sin_huecos

FROM dbo.dim_station d

LEFT JOIN salidas s
    ON d.station_id = s.station_id

LEFT JOIN llegadas l
    ON d.station_id = l.station_id

LEFT JOIN disponibilidad disp
    ON d.station_id = disp.station_id;

    /*
========================================================
7. VALIDACIÓN DE VW_STATION_SUMMARY_POWERBI
========================================================
*/

SELECT
    COUNT(*) AS total_estaciones,
    SUM(CASE WHEN station_id IS NULL THEN 1 ELSE 0 END) AS station_id_nulos,
    SUM(CASE WHEN pct_sin_bicis IS NULL THEN 1 ELSE 0 END) AS pct_sin_bicis_nulos,
    SUM(CASE WHEN pct_sin_huecos IS NULL THEN 1 ELSE 0 END) AS pct_sin_huecos_nulos
FROM dbo.vw_station_summary_powerbi;


/*
========================================================
8. IDENTIFICACIÓN DE ESTACIÓN SIN SNAPSHOTS OPERATIVOS
========================================================
*/

SELECT
    station_id,
    station_number,
    station_name,
    snapshots_operativos,
    pct_sin_bicis,
    pct_sin_huecos
FROM dbo.vw_station_summary_powerbi
WHERE pct_sin_bicis IS NULL
   OR pct_sin_huecos IS NULL;

   /*
========================================================
9. VALIDACIÓN DE LA ESTACIÓN PRIM
========================================================
*/

SELECT
    station_id,
    station_number,
    station_name,
    no_available,
    COUNT(*) AS registros
FROM dbo.station_status_2022
WHERE station_id = 20
GROUP BY
    station_id,
    station_number,
    station_name,
    no_available
ORDER BY no_available;

/*
========================================================
9. VALIDACIÓN DE LA ESTACIÓN PRIM
========================================================
*/

SELECT
    station_id,
    station_number,
    station_name,
    no_available,
    COUNT(*) AS registros
FROM dbo.station_status_2022
WHERE station_id = 20
GROUP BY
    station_id,
    station_number,
    station_name,
    no_available
ORDER BY no_available;

/*
INTERPRETACIÓN:

La estación Prim (station_id = 20) aparece marcada como
no disponible durante los 8.738 snapshots de 2022.

Por este motivo no existen snapshots operativos válidos
para calcular:
- porcentaje de tiempo sin bicicletas;
- porcentaje de tiempo sin huecos libres.

Se mantienen estos valores como NULL para no interpretar
como 0% una estación que realmente no estuvo operativa.
*/

/*
========================================================
CIERRE DEL ARCHIVO 18_powerbi_views.sql
========================================================

VISTAS CREADAS:

1. dbo.vw_trips_powerbi
   - 4.143.941 viajes
   - estaciones de origen y destino normalizadas
   - mantiene los viajes con estación desconocida como NULL

2. dbo.vw_station_status_powerbi
   - 2.306.832 registros de estado
   - incluye información de estación
   - incorpora indicadores:
     is_empty
     is_full

3. dbo.vw_station_summary_powerbi
   - 264 estaciones
   - viajes de salida
   - viajes de llegada
   - balance neto
   - snapshots operativos
   - porcentaje sin bicicletas
   - porcentaje sin huecos libres

VALIDACIONES:

- La vista de viajes conserva el total original de registros.
- Los códigos de estación válidos quedan correctamente mapeados.
- La vista de disponibilidad reproduce los resultados obtenidos
  previamente en el análisis SQL.
- La estación Prim (station_id = 20) estuvo marcada como no disponible
  durante los 8.738 snapshots de 2022 y por ello mantiene métricas
  operativas como NULL.

RESULTADO:

El modelo SQL queda preparado para su consumo desde Power BI,
evitando realizar transformaciones complejas directamente
en la capa de visualización.

========================================================
FIN DEL ARCHIVO
========================================================
*/