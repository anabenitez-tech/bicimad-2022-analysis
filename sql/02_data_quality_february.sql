/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 02_data_quality_february.sql
OBJETIVO:
Realizar una revisión de calidad de los datos
correspondientes a febrero de 2022.
========================================================
*/

USE BiciMAD;
GO

/*
========================================================
1. VALIDACIÓN INICIAL DE LA CARGA
========================================================
*/

-- Comprobación del número total de filas importadas
SELECT COUNT(*) AS total_filas
FROM dbo.trips_22_02_February;

-- Comprobación de filas vacías
SELECT 
    COUNT(*) AS filas_totales,
    SUM(
        CASE 
            WHEN idTrip IS NULL 
              OR LTRIM(RTRIM(idTrip)) = ''
            THEN 1
            ELSE 0
        END
    ) AS filas_vacias
FROM dbo.trips_22_02_February;

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'trips_22_02_February'
ORDER BY ORDINAL_POSITION;

/*
Se detecta una diferencia de esquema respecto a enero:
el fichero de febrero no contiene la columna idTrip.

Por este motivo, las filas vacías se identificarán utilizando
varios campos principales del registro.
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

FROM dbo.trips_22_02_February;

-- Eliminación de filas completamente vacías
DELETE FROM dbo.trips_22_02_February
WHERE fecha IS NULL
  AND idBike IS NULL
  AND unlock_date IS NULL
  AND lock_date IS NULL;

  -- Comprobación del número de registros después de la limpieza
SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_02_February;

/*
========================================================
2. CONTROL DE DUPLICADOS
========================================================
*/

-- Febrero no contiene idTrip.
-- Se revisan posibles duplicados utilizando una combinación
-- de bicicleta, fechas y estaciones.
SELECT
    idBike,
    unlock_date,
    lock_date,
    station_unlock,
    station_lock,
    COUNT(*) AS repeticiones
FROM dbo.trips_22_02_February
GROUP BY
    idBike,
    unlock_date,
    lock_date,
    station_unlock,
    station_lock
HAVING COUNT(*) > 1
ORDER BY repeticiones DESC;

/*
Comprobación de duplicados exactos.
Se comparan todas las columnas disponibles en febrero,
ya que este mes no dispone de idTrip.
*/

WITH duplicados AS (
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
    FROM dbo.trips_22_02_February
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
    SUM(repeticiones - 1) AS filas_duplicadas_extra
FROM duplicados;

/*
RESULTADO:
Se detectaron 9 grupos de registros duplicados exactos.
Cada grupo contiene una fila duplicada adicional.

DECISIÓN:
Se eliminarán las 9 filas duplicadas conservando
una única copia de cada registro.
*/


WITH duplicados AS (
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
    FROM dbo.trips_22_02_February
)

DELETE FROM duplicados
WHERE rn > 1;


SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_02_February;

/*
========================================================
3. CALIDAD DE trip_minutes
========================================================
*/

-- Comprobación de valores nulos y no convertibles
SELECT
    SUM(CASE WHEN trip_minutes IS NULL THEN 1 ELSE 0 END) AS trip_minutes_nulos,

    SUM(
        CASE
            WHEN trip_minutes IS NOT NULL
             AND TRY_CONVERT(decimal(10,2), trip_minutes) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS trip_minutes_no_convertibles

FROM dbo.trips_22_02_February;


/*
RESULTADO:
- No existen valores nulos en trip_minutes.
- Todos los valores pueden convertirse correctamente
  a formato numérico.
*/

-- Estadísticas básicas de duración
SELECT
    MIN(TRY_CONVERT(decimal(10,2), trip_minutes)) AS min_trip_minutes,
    MAX(TRY_CONVERT(decimal(10,2), trip_minutes)) AS max_trip_minutes,
    AVG(TRY_CONVERT(decimal(10,2), trip_minutes)) AS avg_trip_minutes
FROM dbo.trips_22_02_February;

/*
RESULTADO:
- Duración mínima: -4371,93 minutos.
- Duración máxima: 38926,65 minutos.
- Duración media: 20,32 minutos.

Se detectan valores negativos y duraciones extremadamente altas,
por lo que se requiere una revisión adicional.
*/


-- Conteo de duraciones negativas y superiores a 24 horas
SELECT
    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1
            ELSE 0
        END
    ) AS viajes_negativos,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) > 1440
            THEN 1
            ELSE 0
        END
    ) AS viajes_mas_de_24h,

    COUNT(*) AS total_viajes
FROM dbo.trips_22_02_February;

/*
RESULTADO:
- Viajes con duración negativa: 2
- Viajes con duración superior a 24 horas: 842
- Total de viajes: 280.366

La incidencia de duraciones negativas es muy reducida en febrero,
aunque siguen existiendo viajes con duraciones extremadamente altas.
*/

SELECT
    COUNT(*) AS fechas_invertidas,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1
            ELSE 0
        END
    ) AS fechas_invertidas_y_trip_negativo
FROM dbo.trips_22_02_February
WHERE lock_date < unlock_date;

/*
RESULTADO:
Se detectaron 2 viajes con fechas invertidas.
Ambos registros coinciden exactamente con los 2 viajes
que presentan trip_minutes negativo.

Esto confirma que, al igual que en enero, las duraciones negativas
están asociadas a inconsistencias en los timestamps.
*/

SELECT
    CAST(unlock_date AS date) AS fecha,
    COUNT(*) AS viajes_fecha_invertida
FROM dbo.trips_22_02_February
WHERE lock_date < unlock_date
GROUP BY CAST(unlock_date AS date)
ORDER BY fecha;

/*
RESULTADO:
Los 2 viajes con fechas invertidas aparecen en días distintos:

- 14/02/2022: 1 caso
- 21/02/2022: 1 caso

A diferencia de enero, no existe una concentración significativa
en una fecha concreta, por lo que parecen incidencias aisladas.
*/

SELECT
    COUNT(*) AS total_viajes,

    SUM(
        CASE
            WHEN ABS(
                TRY_CONVERT(decimal(10,2), trip_minutes)
                - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
            ) < 0.1
            THEN 1
            ELSE 0
        END
    ) AS duracion_coincide,

    SUM(
        CASE
            WHEN ABS(
                TRY_CONVERT(decimal(10,2), trip_minutes)
                - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
            ) >= 0.1
            THEN 1
            ELSE 0
        END
    ) AS duracion_no_coincide

FROM dbo.trips_22_02_February;

/*
RESULTADO:
- Total de viajes: 280.366
- Duración coincidente: 271.572
- Duración no coincidente: 8.794

Aproximadamente el 3,14% de los viajes presenta discrepancias
entre trip_minutes y la duración calculada a partir de los timestamps.
*/

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

FROM dbo.trips_22_02_February

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;

/*
RESULTADO:
Las 8.794 discrepancias detectadas en febrero corresponden
a diferencias en múltiplos exactos de 60 minutos.

Esto reproduce el mismo patrón observado en enero y sugiere
la existencia de un desfase sistemático en determinados timestamps.

DECISIÓN PROVISIONAL:
Se mantiene trip_minutes como campo principal de duración,
documentando la inconsistencia temporal para su revisión posterior.
*/

SELECT
    SUM(CASE WHEN station_unlock IS NULL THEN 1 ELSE 0 END) AS origen_nulo,
    SUM(CASE WHEN station_lock IS NULL THEN 1 ELSE 0 END) AS destino_nulo
FROM dbo.trips_22_02_February;

/*
========================================================
4. ESTACIONES NULAS
========================================================
*/

SELECT
    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND station_lock IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS solo_origen_nulo,

    SUM(
        CASE
            WHEN station_unlock IS NOT NULL
             AND station_lock IS NULL
            THEN 1 ELSE 0
        END
    ) AS solo_destino_nulo,

    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND station_lock IS NULL
            THEN 1 ELSE 0
        END
    ) AS ambos_nulos

FROM dbo.trips_22_02_February;

/*
RESULTADO:
- Solo estación de origen nula: 315
- Solo estación de destino nula: 711
- Ambas estaciones nulas: 1.224

Los totales coinciden con los valores nulos detectados previamente.
*/

SELECT
    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND station_lock IS NOT NULL
             AND geolocation_unlock IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS origen_nulo_con_geo,

    SUM(
        CASE
            WHEN station_unlock IS NOT NULL
             AND station_lock IS NULL
             AND geolocation_lock IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS destino_nulo_con_geo,

    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND station_lock IS NULL
             AND geolocation_unlock IS NOT NULL
             AND geolocation_lock IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS ambos_nulos_con_geo

FROM dbo.trips_22_02_February;

/*
RESULTADO:
Todos los registros con station_unlock y/o station_lock nulos
conservan la geolocalización correspondiente.

- Origen nulo con geolocalización: 315 de 315
- Destino nulo con geolocalización: 711 de 711
- Ambas estaciones nulas con geolocalización: 1.224 de 1.224

DECISIÓN:
No se eliminarán estos registros, ya que existe la posibilidad
de recuperar posteriormente la estación correspondiente
mediante coordenadas.
*/

SELECT
    SUM(CASE WHEN unlock_date IS NULL THEN 1 ELSE 0 END) AS unlock_date_nulos,
    SUM(CASE WHEN lock_date IS NULL THEN 1 ELSE 0 END) AS lock_date_nulos
FROM dbo.trips_22_02_February;

/*
RESULTADO:
No existen valores nulos en unlock_date ni en lock_date.
La información temporal está completa en todos los registros.
*/

/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - FEBRERO 2022
========================================================

1. Se importaron inicialmente 560.750 filas.

2. Se identificaron y eliminaron 280.375 filas vacías,
   quedando 280.375 viajes reales.

3. El fichero de febrero no contiene la columna idTrip,
   a diferencia de enero. Por este motivo, el control
   de duplicados se realizó utilizando el conjunto completo
   de columnas disponibles.

4. Se detectaron 9 filas duplicadas exactas.
   Tras eliminarlas, el dataset quedó en 280.366 viajes.

5. trip_minutes:
   - No contiene valores nulos.
   - Todos sus valores pueden convertirse a formato numérico.
   - Se detectaron 2 valores negativos.
   - Se detectaron 842 viajes con duración superior a 24 horas.

6. Los 2 viajes con duración negativa coinciden exactamente
   con los 2 registros donde lock_date es anterior a unlock_date.

7. Estos casos aparecen de forma aislada:
   - 14/02/2022: 1 caso
   - 21/02/2022: 1 caso

8. En 8.794 viajes, trip_minutes no coincide con la duración
   calculada entre unlock_date y lock_date.

9. Todas estas discrepancias corresponden a múltiplos exactos
   de 60 minutos, reproduciendo el mismo patrón observado
   en enero.

10. Se detectaron:
    - 1.539 viajes sin estación de origen.
    - 1.935 viajes sin estación de destino.
    - 1.224 viajes sin estación de origen ni destino.

11. Todos los registros con estaciones nulas conservan
    la geolocalización correspondiente.

12. unlock_date y lock_date no contienen valores nulos.

DECISIONES:
- Se mantiene trip_minutes como campo principal de duración.
- Se documentan las inconsistencias temporales detectadas.
- Los registros con estaciones nulas no se eliminarán,
  ya que podrían recuperarse posteriormente mediante
  geolocalización.
- Los 9 duplicados exactos sí se eliminaron.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - FEBRERO 2022
========================================================
*/