/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 06_data_quality_june.sql
OBJETIVO:
Realizar un control de calidad resumido de los datos
correspondientes a junio de 2022.
========================================================
*/

USE BiciMAD;
GO

SELECT COUNT(*) AS total_registros
FROM dbo.trips_22_06_June;

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

FROM dbo.trips_22_06_June;

/*
RESULTADO:
- Filas importadas: 868.800
- Filas vacías: 434.400
- Viajes reales esperados: 434.400
*/

DELETE FROM dbo.trips_22_06_June
WHERE fecha IS NULL
  AND idBike IS NULL
  AND unlock_date IS NULL
  AND lock_date IS NULL;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_06_June;

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
    FROM dbo.trips_22_06_June
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
No se detectaron registros duplicados exactos en junio.
*/

/*
========================================================
3. CONTROL DE CALIDAD RESUMIDO - JUNIO 2022
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

FROM dbo.trips_22_06_June;


-- Fechas invertidas
SELECT
    COUNT(*) AS fechas_invertidas
FROM dbo.trips_22_06_June
WHERE lock_date < unlock_date;


-- Discrepancias entre duración y timestamps
SELECT
    COUNT(*) AS discrepancias
FROM dbo.trips_22_06_June
WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


-- Nulos en estaciones
SELECT
    SUM(CASE WHEN station_unlock IS NULL THEN 1 ELSE 0 END) AS origen_nulo,
    SUM(CASE WHEN station_lock IS NULL THEN 1 ELSE 0 END) AS destino_nulo
FROM dbo.trips_22_06_June;


-- Nulos en fechas
SELECT
    SUM(CASE WHEN unlock_date IS NULL THEN 1 ELSE 0 END) AS unlock_date_nulos,
    SUM(CASE WHEN lock_date IS NULL THEN 1 ELSE 0 END) AS lock_date_nulos
FROM dbo.trips_22_06_June;

SELECT
    COUNT(*) AS fechas_invertidas,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1 ELSE 0
        END
    ) AS fechas_invertidas_y_trip_negativo
FROM dbo.trips_22_06_June
WHERE lock_date < unlock_date;

-- Eliminación del único viaje con fecha invertida
-- y duración negativa
DELETE FROM dbo.trips_22_06_June
WHERE lock_date < unlock_date
  AND TRY_CONVERT(decimal(10,2), trip_minutes) < 0;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_06_June;

/*
RESULTADO:
Se detectó 1 único registro con duración negativa y
lock_date anterior a unlock_date.

DECISIÓN:
Se elimina al tratarse de una anomalía aislada con un impacto
despreciable sobre el volumen total del mes.
*/

/*
========================================================
4. COMPROBACIONES FINALES - JUNIO 2022
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

FROM dbo.trips_22_06_June

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

FROM dbo.trips_22_06_June;

/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - JUNIO 2022
========================================================

1. Se importaron inicialmente 868.800 filas.

2. Se identificaron y eliminaron 434.400 filas vacías,
   quedando 434.400 viajes reales.

3. No se detectaron registros duplicados exactos.

4. trip_minutes:
   - No contiene valores nulos.
   - Todos sus valores pueden convertirse a formato numérico.
   - Se detectó 1 duración negativa.
   - Se detectaron 1.163 viajes con duración superior a 24 horas.

5. Se detectó 1 registro con lock_date anterior a unlock_date.

6. Ese mismo registro coincidía con el único viaje
   con trip_minutes negativo.

7. Al tratarse de una anomalía aislada, se eliminó.
   El dataset quedó finalmente en 434.399 viajes.

8. Se detectaron 13.773 viajes en los que trip_minutes
   no coincide con la duración calculada a partir de
   unlock_date y lock_date.

9. Las 13.773 discrepancias corresponden a múltiplos exactos
   de 60 minutos, reproduciendo el patrón observado
   en los meses anteriores.

10. Se detectaron:
    - 1.845 viajes sin estación de origen.
    - 2.131 viajes sin estación de destino.

11. Los 1.845 registros con estación de origen nula
    conservan geolocation_unlock.

12. Los 2.131 registros con estación de destino nula
    conservan geolocation_lock.

13. No existen valores nulos en unlock_date ni lock_date.

DECISIONES:

- Se mantiene trip_minutes como campo principal de duración.
- Se elimina el único registro con duración negativa
  y fechas invertidas.
- Se documenta el desfase sistemático de timestamps.
- No se eliminan los registros con estaciones nulas,
  ya que conservan información geográfica útil para una posible
  recuperación posterior de la estación.
- Los viajes superiores a 24 horas se mantienen por ahora
  para analizarlos más adelante de forma conjunta.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - JUNIO 2022
========================================================
*/