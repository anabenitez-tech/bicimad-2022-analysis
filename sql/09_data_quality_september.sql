/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 09_data_quality_september.sql
OBJETIVO:
Realizar un control de calidad resumido de los datos
correspondientes a septiembre de 2022.
========================================================
*/

USE BiciMAD;
GO

SELECT COUNT(*) AS total_registros
FROM dbo.trips_22_09_September;

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

FROM dbo.trips_22_09_September;

/*
RESULTADO:
- Filas importadas: 894.472
- Filas vacías: 447.236
- Viajes reales esperados: 447.236
*/

DELETE FROM dbo.trips_22_09_September
WHERE fecha IS NULL
  AND idBike IS NULL
  AND unlock_date IS NULL
  AND lock_date IS NULL;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_09_September;

/*
========================================================
2. CONTROL DE DUPLICADOS - SEPTIEMBRE 2022
========================================================
*/

;WITH duplicados AS (
    SELECT
        fecha,
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
    FROM dbo.trips_22_09_September
    GROUP BY
        fecha,
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
    COALESCE(SUM(repeticiones - 1), 0) AS filas_duplicadas_extra
FROM duplicados;

/*
RESULTADO:
Se detectaron 23 grupos de registros duplicados exactos.
Cada grupo contiene una fila duplicada adicional.

DECISIÓN:
Se eliminarán las 23 filas duplicadas conservando
una única copia de cada registro.
*/


;WITH duplicados AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY
                fecha,
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
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM dbo.trips_22_09_September
)

DELETE FROM duplicados
WHERE rn > 1;

SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_09_September;

/*
========================================================
3. CONTROL DE CALIDAD RESUMIDO - SEPTIEMBRE 2022
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

FROM dbo.trips_22_09_September;


-- Fechas invertidas
SELECT
    COUNT(*) AS fechas_invertidas
FROM dbo.trips_22_09_September
WHERE lock_date < unlock_date;


-- Discrepancias entre duración y timestamps
SELECT
    COUNT(*) AS discrepancias
FROM dbo.trips_22_09_September
WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


-- Nulos en estaciones
SELECT
    SUM(CASE WHEN station_unlock IS NULL THEN 1 ELSE 0 END) AS origen_nulo,
    SUM(CASE WHEN station_lock IS NULL THEN 1 ELSE 0 END) AS destino_nulo
FROM dbo.trips_22_09_September;


-- Nulos en fechas
SELECT
    SUM(CASE WHEN unlock_date IS NULL THEN 1 ELSE 0 END) AS unlock_date_nulos,
    SUM(CASE WHEN lock_date IS NULL THEN 1 ELSE 0 END) AS lock_date_nulos
FROM dbo.trips_22_09_September;

SELECT
    COUNT(*) AS fechas_invertidas,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1 ELSE 0
        END
    ) AS fechas_invertidas_y_trip_negativo
FROM dbo.trips_22_09_September
WHERE lock_date < unlock_date;

-- Eliminación de viajes con duración negativa
-- y fecha de bloqueo anterior a la fecha de desbloqueo
DELETE FROM dbo.trips_22_09_September
WHERE lock_date < unlock_date
  AND TRY_CONVERT(decimal(10,2), trip_minutes) < 0;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_09_September;

/*
RESULTADO:
Se detectaron 3 registros con duración negativa y
lock_date anterior a unlock_date.

DECISIÓN:
Se eliminan los 3 registros al tratarse de anomalías
temporales claramente identificadas y con impacto mínimo
sobre el volumen total del mes.
*/


/*
========================================================
4. COMPROBACIONES FINALES - SEPTIEMBRE 2022
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

FROM dbo.trips_22_09_September

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


-- Comprobar si las estaciones nulas conservan geolocalización
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

FROM dbo.trips_22_09_September;

/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - SEPTIEMBRE 2022
========================================================

1. Se importaron inicialmente 894.472 filas.

2. Se identificaron y eliminaron 447.236 filas vacías,
   quedando 447.236 viajes reales.

3. El fichero de septiembre no contiene la columna idTrip,
   por lo que el control de duplicados se realizó utilizando
   el resto de columnas disponibles.

4. Se detectaron 23 registros duplicados exactos.
   Tras eliminarlos, el dataset quedó en 447.213 viajes.

5. trip_minutes:
   - No contiene valores nulos.
   - Todos sus valores pueden convertirse a formato numérico.
   - Se detectaron 3 duraciones negativas.
   - Se detectaron 1.526 viajes con duración superior a 24 horas.

6. Se detectaron 3 registros con lock_date anterior
   a unlock_date.

7. Los 3 registros con fechas invertidas coincidían con
   los 3 viajes que presentaban trip_minutes negativo.

8. Se eliminaron estos 3 registros al considerarse
   anomalías temporales claramente identificadas.
   El dataset quedó finalmente en 447.210 viajes.

9. Tras la limpieza, se detectaron 15.245 viajes en los que
   trip_minutes no coincide con la duración calculada a partir
   de unlock_date y lock_date.

10. Las 15.245 discrepancias corresponden a múltiplos exactos
    de 60 minutos, manteniendo el patrón observado
    en los meses anteriores.

11. Se detectaron:
    - 1.521 viajes sin estación de origen.
    - 1.870 viajes sin estación de destino.

12. Los 1.521 registros con estación de origen nula
    conservan geolocation_unlock.

13. Los 1.870 registros con estación de destino nula
    conservan geolocation_lock.

14. No existen valores nulos en unlock_date ni lock_date.

DECISIONES:

- Se mantiene trip_minutes como campo principal de duración.
- Se eliminaron los 3 registros con duración negativa
  y fechas invertidas.
- Se mantiene documentado el desfase sistemático
  de timestamps.
- No se eliminan los registros con estaciones nulas,
  ya que conservan información geográfica.
- Los viajes superiores a 24 horas se mantienen por ahora
  para analizarlos posteriormente de forma conjunta.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - SEPTIEMBRE 2022
========================================================
*/