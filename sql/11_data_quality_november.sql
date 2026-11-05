/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 11_data_quality_november.sql
OBJETIVO:
Realizar un control de calidad resumido de los datos
correspondientes a noviembre de 2022.
========================================================
*/

USE BiciMAD;
GO

SELECT COUNT(*) AS total_registros
FROM dbo.trips_22_11_November;

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

FROM dbo.trips_22_11_November;

/*
RESULTADO:
- Filas importadas: 716.788
- Filas vacías: 358.394
- Viajes reales esperados: 358.394
*/

DELETE FROM dbo.trips_22_11_November
WHERE fecha IS NULL
  AND idBike IS NULL
  AND unlock_date IS NULL
  AND lock_date IS NULL;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_11_November;

/*
========================================================
2. CONTROL DE DUPLICADOS - NOVIEMBRE 2022
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
    FROM dbo.trips_22_11_November
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
Se detectaron 18 grupos de registros duplicados exactos.
Cada grupo contiene una fila duplicada adicional.

DECISIÓN:
Se eliminarán las 18 filas duplicadas conservando
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
    FROM dbo.trips_22_11_November
)

DELETE FROM duplicados
WHERE rn > 1;

SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_11_November;

/*
========================================================
3. CONTROL DE CALIDAD RESUMIDO - NOVIEMBRE 2022
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

FROM dbo.trips_22_11_November;


-- Fechas invertidas
SELECT
    COUNT(*) AS fechas_invertidas
FROM dbo.trips_22_11_November
WHERE lock_date < unlock_date;


-- Discrepancias entre duración y timestamps
SELECT
    COUNT(*) AS discrepancias
FROM dbo.trips_22_11_November
WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


-- Nulos en estaciones
SELECT
    SUM(CASE WHEN station_unlock IS NULL THEN 1 ELSE 0 END) AS origen_nulo,
    SUM(CASE WHEN station_lock IS NULL THEN 1 ELSE 0 END) AS destino_nulo
FROM dbo.trips_22_11_November;


-- Nulos en fechas
SELECT
    SUM(CASE WHEN unlock_date IS NULL THEN 1 ELSE 0 END) AS unlock_date_nulos,
    SUM(CASE WHEN lock_date IS NULL THEN 1 ELSE 0 END) AS lock_date_nulos
FROM dbo.trips_22_11_November;

SELECT
    COUNT(*) AS fechas_invertidas,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1 ELSE 0
        END
    ) AS fechas_invertidas_y_trip_negativo

FROM dbo.trips_22_11_November

WHERE lock_date < unlock_date;

-- Eliminación del único viaje con duración negativa
-- y fecha de bloqueo anterior a la fecha de desbloqueo
DELETE FROM dbo.trips_22_11_November
WHERE lock_date < unlock_date
  AND TRY_CONVERT(decimal(10,2), trip_minutes) < 0;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_11_November;

/*
RESULTADO:
Se detectó 1 único registro con duración negativa y
lock_date anterior a unlock_date.

DECISIÓN:
Se elimina al tratarse de una anomalía temporal aislada
con impacto despreciable sobre el volumen total del mes.
*/

/*
========================================================
4. COMPROBACIONES FINALES - NOVIEMBRE 2022
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

FROM dbo.trips_22_11_November

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

FROM dbo.trips_22_11_November;

SELECT
    trip_minutes,
    unlock_date,
    lock_date,

    DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
        AS calculated_minutes,

    (
        DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
        - TRY_CONVERT(decimal(10,2), trip_minutes)
    ) AS difference_minutes

FROM dbo.trips_22_11_November

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1

AND ABS(
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
) >= 0.1;

/*
OBSERVACIÓN:
Se detectó una única discrepancia que no sigue el patrón
de múltiplos exactos de 60 minutos:

- trip_minutes: 0,17 minutos
- duración según timestamps: 89,38 minutos
- diferencia: 89,21 minutos
- fecha: 23/11/2022

Al tratarse de un único caso aislado, se conserva el registro
y se documenta la inconsistencia sin aplicar una corrección
automática.
*/

/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - NOVIEMBRE 2022
========================================================

1. Se importaron inicialmente 716.788 filas.

2. Se identificaron y eliminaron 358.394 filas vacías,
   quedando 358.394 viajes reales.

3. El fichero de noviembre no contiene la columna idTrip,
   por lo que el control de duplicados se realizó utilizando
   el resto de columnas disponibles.

4. Se detectaron 18 registros duplicados exactos.
   Tras eliminarlos, el dataset quedó en 358.376 viajes.

5. trip_minutes:
   - No contiene valores nulos.
   - Todos sus valores pueden convertirse a formato numérico.
   - Se detectó 1 duración negativa.
   - Se detectaron 1.497 viajes con duración superior a 24 horas.

6. Se detectó 1 registro con lock_date anterior a unlock_date.

7. Este registro coincidía con el único viaje que presentaba
   trip_minutes negativo y fue eliminado.

8. El dataset quedó finalmente en 358.375 viajes.

9. Se detectaron 12.099 discrepancias entre trip_minutes
   y la duración calculada a partir de los timestamps.

10. De estas discrepancias, 12.098 corresponden a múltiplos
    exactos de 60 minutos, manteniendo el patrón sistemático
    observado durante el año.

11. Se detectó una única excepción a este patrón:
    trip_minutes = 0,17 minutos frente a una duración calculada
    de 89,38 minutos.

    Al tratarse de un caso aislado, se conserva el registro
    y se documenta la inconsistencia.

12. Se detectaron:
    - 1.011 viajes sin estación de origen.
    - 1.289 viajes sin estación de destino.

13. Todos los registros con estaciones nulas conservan
    la geolocalización correspondiente.

14. No existen valores nulos en unlock_date ni lock_date.

DECISIONES:

- Se mantiene trip_minutes como campo principal de duración.
- Se eliminó el único registro con duración negativa
  y fechas invertidas.
- Se conserva y documenta la única discrepancia que no sigue
  el patrón de múltiplos de 60 minutos.
- No se eliminan los registros con estaciones nulas porque
  conservan información geográfica.
- Los viajes superiores a 24 horas se mantienen por ahora
  para analizarlos conjuntamente al finalizar el año.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - NOVIEMBRE 2022
========================================================
*/