/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 05_data_quality_may.sql
OBJETIVO:
Realizar un control de calidad resumido de los datos
correspondientes a mayo de 2022.
========================================================
*/

USE BiciMAD;
GO

SELECT COUNT(*) AS total_registros
FROM dbo.trips_22_05_May;

/*
========================================================
1. VALIDACIÓN INICIAL DE LA CARGA
========================================================
*/

SELECT
    COUNT(*) AS filas_totales,

    SUM(
        CASE
            WHEN fecha IS NULL
             AND idBike IS NULL
             AND unlock_date IS NULL
             AND lock_date IS NULL
            THEN 1
            ELSE 0
        END
    ) AS filas_vacias

FROM dbo.trips_22_05_May;

/*
RESULTADO:
- Filas importadas: 955.868
- Filas vacías: 477.934
- Viajes reales esperados: 477.934
*/

DELETE FROM dbo.trips_22_05_May
WHERE fecha IS NULL
  AND idBike IS NULL
  AND unlock_date IS NULL
  AND lock_date IS NULL;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_05_May;

/*
========================================================
2. CONTROL DE DUPLICADOS
========================================================
*/

WITH duplicados AS (
    SELECT
        fecha,
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
        lock_station_name,
        COUNT(*) AS repeticiones
    FROM dbo.trips_22_05_May
    GROUP BY
        fecha,
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
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS grupos_duplicados,
    SUM(repeticiones - 1) AS filas_duplicadas_extra
FROM duplicados;

/*
RESULTADO:
No se detectaron registros duplicados exactos en mayo.
*/

/*
========================================================
3. CONTROL DE CALIDAD RESUMIDO - MAYO 2022
========================================================
*/

-- Calidad de trip_minutes
SELECT
    SUM(CASE WHEN trip_minutes IS NULL THEN 1 ELSE 0 END) AS trip_minutes_nulos,

    SUM(
        CASE
            WHEN trip_minutes IS NOT NULL
             AND TRY_CONVERT(decimal(10,2), trip_minutes) IS NULL
            THEN 1 ELSE 0
        END
    ) AS trip_minutes_no_convertibles,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1 ELSE 0
        END
    ) AS duraciones_negativas,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) > 1440
            THEN 1 ELSE 0
        END
    ) AS viajes_mas_24h

FROM dbo.trips_22_05_May;


-- Fechas invertidas
SELECT
    COUNT(*) AS fechas_invertidas
FROM dbo.trips_22_05_May
WHERE lock_date < unlock_date;


-- Discrepancias entre duración y timestamps
SELECT
    COUNT(*) AS discrepancias
FROM dbo.trips_22_05_May
WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


-- Nulos en estaciones
SELECT
    SUM(CASE WHEN station_unlock IS NULL THEN 1 ELSE 0 END) AS origen_nulo,
    SUM(CASE WHEN station_lock IS NULL THEN 1 ELSE 0 END) AS destino_nulo
FROM dbo.trips_22_05_May;


-- Nulos en fechas
SELECT
    SUM(CASE WHEN unlock_date IS NULL THEN 1 ELSE 0 END) AS unlock_date_nulos,
    SUM(CASE WHEN lock_date IS NULL THEN 1 ELSE 0 END) AS lock_date_nulos
FROM dbo.trips_22_05_May;

/*
========================================================
4. COMPROBACIONES FINALES - MAYO 2022
========================================================
*/

-- Comprobar si las discrepancias siguen siendo múltiplos de 60 minutos
SELECT
    COUNT(*) AS discrepancias_totales,

    SUM(
        CASE
            WHEN ABS(
                (
                    DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
                    - TRY_CONVERT(decimal(10,2), trip_minutes)
                )
                -
                ROUND(
                    (
                        DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
                        - TRY_CONVERT(decimal(10,2), trip_minutes)
                    ) / 60.0,
                    0
                ) * 60
            ) < 0.1
            THEN 1
            ELSE 0
        END
    ) AS diferencias_horas_completas

FROM dbo.trips_22_05_May

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


-- Comprobar si los registros con estación nula conservan geolocalización
SELECT
    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND geolocation_unlock IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS origen_nulo_con_geo,

    SUM(
        CASE
            WHEN station_lock IS NULL
             AND geolocation_lock IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS destino_nulo_con_geo

FROM dbo.trips_22_05_May;

/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - MAYO 2022
========================================================

1. Se importaron inicialmente 955.868 filas.

2. Se identificaron y eliminaron 477.934 filas vacías,
   quedando 477.934 viajes reales.

3. No se detectaron registros duplicados exactos.

4. trip_minutes:
   - No contiene valores nulos.
   - Todos sus valores pueden convertirse a formato numérico.
   - No se detectaron duraciones negativas.
   - Se detectaron 1.237 viajes con duración superior a 24 horas.

5. No se detectaron registros con lock_date anterior a unlock_date.

6. Se detectaron 15.966 viajes en los que trip_minutes
   no coincide con la duración calculada a partir de
   unlock_date y lock_date.

7. Las 15.966 discrepancias corresponden a múltiplos exactos
   de 60 minutos.

   Este resultado reproduce el mismo patrón observado
   en los meses anteriores y refuerza la existencia de
   un desfase sistemático en determinados timestamps.

8. Se detectaron:
   - 1.681 viajes sin estación de origen.
   - 1.883 viajes sin estación de destino.

9. Los 1.681 registros con estación de origen nula
   conservan geolocation_unlock.

10. Los 1.883 registros con estación de destino nula
    conservan geolocation_lock.

11. No existen valores nulos en unlock_date ni lock_date.

DECISIONES:

- Se mantiene trip_minutes como campo principal de duración.
- Se documenta el desfase sistemático de timestamps.
- No se eliminan los registros con estaciones nulas, ya que
  conservan información geográfica suficiente para una posible
  recuperación posterior de la estación.
- Los viajes superiores a 24 horas se conservan de momento
  para analizarlos posteriormente de forma conjunta.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - MAYO 2022
========================================================
*/