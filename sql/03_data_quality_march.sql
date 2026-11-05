/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 03_data_quality_march.sql
OBJETIVO:
Realizar una revisión de calidad de los datos
correspondientes a marzo de 2022.
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
FROM dbo.trips_22_03_March;

/*
Comprobación de filas vacías
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

FROM dbo.trips_22_03_March;

/*
RESULTADO:
- Filas importadas: 554.382
- Filas vacías: 277.191
- Viajes reales esperados: 277.191
*/


DELETE FROM dbo.trips_22_03_March
WHERE fecha IS NULL
  AND idBike IS NULL
  AND unlock_date IS NULL
  AND lock_date IS NULL;

  SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_03_March;

/*
========================================================
2. CONTROL DE DUPLICADOS
========================================================
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
    FROM dbo.trips_22_03_March
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
Se detectaron 6 grupos de registros duplicados exactos.
Cada grupo contiene una fila duplicada adicional.

DECISIÓN:
Se eliminarán las 6 filas duplicadas conservando
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
    FROM dbo.trips_22_03_March
)

DELETE FROM duplicados
WHERE rn > 1;

SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_03_March;

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

FROM dbo.trips_22_03_March;

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
FROM dbo.trips_22_03_March;

/*
RESULTADO:
- Duración mínima: -0,07 minutos.
- Duración máxima: 38.880,75 minutos.
- Duración media: 21,47 minutos.

Se detecta al menos un valor negativo, aunque de magnitud muy reducida,
y también existen duraciones extremadamente altas.
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
FROM dbo.trips_22_03_March;


/*
RESULTADO:
- Viajes con duración negativa: 1
- Viajes con duración superior a 24 horas: 774
- Total de viajes: 277.185

La presencia de duraciones negativas en marzo es mínima.
Persisten algunos viajes con duraciones extremadamente altas.
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

FROM dbo.trips_22_03_March

WHERE lock_date < unlock_date;

/*
RESULTADO:
Se detectó 1 viaje con lock_date anterior a unlock_date.

Ese mismo registro coincide con el único viaje
que presenta trip_minutes negativo.

Esto confirma nuevamente la relación entre
duraciones negativas e inconsistencias en los timestamps.
*/

SELECT
    CAST(unlock_date AS date) AS fecha,
    COUNT(*) AS viajes_fecha_invertida
FROM dbo.trips_22_03_March
WHERE lock_date < unlock_date
GROUP BY CAST(unlock_date AS date)
ORDER BY fecha;

-- Eliminación del único viaje con fecha invertida y duración negativa
DELETE FROM dbo.trips_22_03_March
WHERE lock_date < unlock_date
  AND TRY_CONVERT(decimal(10,2), trip_minutes) < 0;

  /*
RESULTADO:
El único viaje con fecha invertida y duración negativa
se registró el 31/03/2022.

Al tratarse de un único registro aislado, se considera
una anomalía puntual.
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

FROM dbo.trips_22_03_March;

/*
RESULTADO:
- Total de viajes: 277.184
- Duración coincidente: 269.178
- Duración no coincidente: 8.006

Aproximadamente el 2,89% de los viajes presenta discrepancias
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

FROM dbo.trips_22_03_March

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;

/*
RESULTADO:
Las 8.006 discrepancias detectadas en marzo corresponden
a diferencias en múltiplos exactos de 60 minutos.

Este patrón coincide con el observado en enero y febrero,
lo que refuerza la hipótesis de un desfase sistemático
en determinados timestamps.

DECISIÓN:
Se mantiene trip_minutes como campo principal de duración.
*/

SELECT
    SUM(CASE WHEN station_unlock IS NULL THEN 1 ELSE 0 END) AS origen_nulo,
    SUM(CASE WHEN station_lock IS NULL THEN 1 ELSE 0 END) AS destino_nulo
FROM dbo.trips_22_03_March;

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

FROM dbo.trips_22_03_March;

/*
RESULTADO:
- Solo estación de origen nula: 211
- Solo estación de destino nula: 311
- Ambas estaciones nulas: 1.114

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

FROM dbo.trips_22_03_March;

/*
RESULTADO:
Todos los registros con station_unlock y/o station_lock nulos
conservan la geolocalización correspondiente.

- Origen nulo con geolocalización: 211 de 211
- Destino nulo con geolocalización: 311 de 311
- Ambas estaciones nulas con geolocalización: 1.114 de 1.114

DECISIÓN:
No se eliminarán estos registros, ya que existe la posibilidad
de recuperar posteriormente la estación correspondiente
mediante coordenadas.
*/

SELECT
    SUM(CASE WHEN unlock_date IS NULL THEN 1 ELSE 0 END) AS unlock_date_nulos,
    SUM(CASE WHEN lock_date IS NULL THEN 1 ELSE 0 END) AS lock_date_nulos
FROM dbo.trips_22_03_March;


/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - MARZO 2022
========================================================

1. Se importaron inicialmente 554.382 filas.

2. Se identificaron y eliminaron 277.191 filas vacías,
   quedando 277.191 viajes reales.

3. Se detectaron 6 registros duplicados exactos.
   Tras eliminarlos, el dataset quedó en 277.185 viajes.

4. trip_minutes:
   - No contiene valores nulos.
   - Todos sus valores pueden convertirse a formato numérico.
   - Se detectó 1 valor negativo.
   - Se detectaron 774 viajes con duración superior a 24 horas.

5. El único viaje con duración negativa coincidía con
   un registro donde lock_date era anterior a unlock_date.

6. Ese registro correspondía al 31/03/2022.
   Al tratarse de una única anomalía aislada, se eliminó.

7. Tras la eliminación, el dataset quedó en 277.184 viajes.

8. En 8.006 viajes, trip_minutes no coincide con la duración
   calculada entre unlock_date y lock_date.

9. Las 8.006 discrepancias corresponden a múltiplos exactos
   de 60 minutos, reproduciendo el patrón observado en
   enero y febrero.

10. Se detectaron:
    - 1.325 viajes sin estación de origen.
    - 1.425 viajes sin estación de destino.
    - 1.114 viajes sin estación de origen ni destino.

11. Todos los registros con estaciones nulas conservan
    la geolocalización correspondiente.

12. unlock_date y lock_date no contienen valores nulos.

13. A partir de marzo se detectan identificadores de estación
    alfanuméricos, como '1a', por lo que station_unlock y
    station_lock deben tratarse como texto y no como enteros.

DECISIONES:
- Se mantiene trip_minutes como campo principal de duración.
- Se eliminó el único registro con duración negativa y
  fecha invertida.
- Se conservarán los registros con estaciones nulas, ya que
  podrían recuperarse posteriormente mediante geolocalización.
- Los identificadores de estación se mantendrán como texto
  para soportar valores alfanuméricos.
- Se documenta el desfase sistemático de timestamps como
  una incidencia recurrente del dataset.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - MARZO 2022
========================================================
*/