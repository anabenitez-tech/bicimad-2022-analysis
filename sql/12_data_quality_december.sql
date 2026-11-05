/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 12_data_quality_december.sql
OBJETIVO:
Realizar un control de calidad resumido de los datos
correspondientes a diciembre de 2022.
========================================================
*/

USE BiciMAD;
GO

SELECT COUNT(*) AS total_registros
FROM dbo.trips_22_12_December;

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

FROM dbo.trips_22_12_December;

/*
RESULTADO:
- Filas importadas: 493.140
- Filas vacías: 246.570
- Viajes reales esperados: 246.570
*/

DELETE FROM dbo.trips_22_12_December
WHERE fecha IS NULL
  AND idBike IS NULL
  AND unlock_date IS NULL
  AND lock_date IS NULL;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_12_December;

/*
========================================================
2. CONTROL DE DUPLICADOS - DICIEMBRE 2022
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
    FROM dbo.trips_22_12_December
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
Se detectaron 13 grupos de registros duplicados exactos.
Cada grupo contiene una fila duplicada adicional.

DECISIÓN:
Se eliminarán las 13 filas duplicadas conservando
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
    FROM dbo.trips_22_12_December
)

DELETE FROM duplicados
WHERE rn > 1;

SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_12_December;

/*
========================================================
3. CONTROL DE CALIDAD DE trip_minutes
========================================================
*/

SELECT
    SUM(CASE WHEN trip_minutes IS NULL THEN 1 ELSE 0 END) AS nulos,

    SUM(
        CASE
            WHEN trip_minutes IS NOT NULL
             AND TRY_CONVERT(decimal(10,2), trip_minutes) IS NULL
            THEN 1 ELSE 0
        END
    ) AS no_convertibles,

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

FROM dbo.trips_22_12_December;

/*
RESULTADO:
- Valores nulos en trip_minutes: 0
- Valores no convertibles: 0
- Duraciones negativas: 3
- Viajes superiores a 24 horas: 1.566

OBSERVACIÓN:
Las duraciones negativas deben comprobarse frente a
unlock_date y lock_date antes de decidir su eliminación.
Los viajes superiores a 24 horas se mantienen por ahora
para analizarlos conjuntamente al finalizar el año.
*/

SELECT
    COUNT(*) AS fechas_invertidas,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1 ELSE 0
        END
    ) AS fechas_invertidas_y_trip_negativo

FROM dbo.trips_22_12_December

WHERE lock_date < unlock_date;

/*
RESULTADO:
Se detectaron 3 registros con lock_date anterior a unlock_date.
Los 3 coinciden con los únicos viajes con trip_minutes negativo.

DECISIÓN:
Se eliminan los 3 registros al tratarse de anomalías temporales
aisladas y claramente inconsistentes.
*/

DELETE FROM dbo.trips_22_12_December
WHERE lock_date < unlock_date
  AND TRY_CONVERT(decimal(10,2), trip_minutes) < 0;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_12_December;

/*
========================================================
4. COMPROBACIONES FINALES - DICIEMBRE 2022
========================================================
*/

-- Discrepancias entre trip_minutes y timestamps
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

FROM dbo.trips_22_12_December

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


-- Estaciones nulas que conservan geolocalización
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

FROM dbo.trips_22_12_December;

/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - DICIEMBRE 2022
========================================================

1. Se importaron inicialmente 493.140 filas.

2. Se identificaron y eliminaron 246.570 filas vacías,
   quedando 246.570 viajes reales.

3. El fichero de diciembre no contiene la columna idTrip,
   por lo que el control de duplicados se realizó utilizando
   el resto de columnas disponibles.

4. Se detectaron 13 registros duplicados exactos.
   Tras eliminarlos, el dataset quedó en 246.557 viajes.

5. trip_minutes:
   - No contiene valores nulos.
   - Todos sus valores pueden convertirse a formato numérico.
   - Se detectaron 3 duraciones negativas.
   - Se detectaron 1.566 viajes con duración superior a 24 horas.

6. Se detectaron 3 registros con lock_date anterior a unlock_date.

7. Los 3 registros coincidían exactamente con los 3 viajes
   que presentaban trip_minutes negativo.

8. Estos 3 registros fueron eliminados como anomalías temporales
   claramente inconsistentes.

9. El dataset quedó finalmente en 246.554 viajes.

10. Se detectaron 9.362 discrepancias entre trip_minutes
    y la duración calculada a partir de los timestamps.

11. Las 9.362 discrepancias corresponden a múltiplos exactos
    de 60 minutos, manteniendo el patrón sistemático observado
    durante el año.

12. Se detectaron:
    - 665 viajes sin estación de origen.
    - 769 viajes sin estación de destino.

13. Todos los registros con estaciones nulas conservan
    la geolocalización correspondiente.

DECISIONES:

- Se mantiene trip_minutes como campo principal de duración.
- Se eliminaron los 3 registros con duración negativa
  y fechas invertidas.
- No se corrigen automáticamente las discrepancias temporales,
  ya que siguen un patrón sistemático de horas completas.
- No se eliminan los registros con estaciones nulas porque
  conservan información geográfica.
- Los viajes superiores a 24 horas se mantienen por ahora
  para analizarlos conjuntamente a nivel anual.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - DICIEMBRE 2022
========================================================
*/