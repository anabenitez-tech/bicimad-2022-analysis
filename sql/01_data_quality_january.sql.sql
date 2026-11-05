/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 01_data_quality_january.sql
OBJETIVO:
Realizar una primera revisión de calidad de los datos
correspondientes a enero de 2022 antes de continuar
con el análisis y el modelado.
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
FROM dbo.trips_22_01_January;


/*
Durante la importación se detectó que el fichero contenía
filas vacías intercaladas entre los registros reales.
Se comprueba cuántas filas están vacías.
*/

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
FROM dbo.trips_22_01_January;


/*
RESULTADO:
- Filas importadas: 489.520
- Filas vacías: 244.760
- Viajes reales esperados: 244.760
*/


-- Eliminación de filas completamente vacías
DELETE FROM dbo.trips_22_01_January
WHERE idTrip IS NULL
   OR LTRIM(RTRIM(idTrip)) = '';


-- Comprobación del número de registros después de la limpieza
SELECT COUNT(*) AS total_viajes
FROM dbo.trips_22_01_January;


/*
RESULTADO:
Después de eliminar las filas vacías quedan 244.760 viajes.
*/


/*
========================================================
2. REVISIÓN DE LA ESTRUCTURA DE LA TABLA
========================================================
*/

-- Visualización de columnas y tipos de datos
EXEC sp_help 'dbo.trips_22_01_January';


/*
Durante la importación se decidió mantener trip_minutes
como texto (nvarchar) para evitar pérdida de información.

Antes de convertir la columna a formato numérico se comprueba
si existen valores que no puedan convertirse.
*/


-- Búsqueda de valores no convertibles en trip_minutes
SELECT TOP 20
    trip_minutes
FROM dbo.trips_22_01_January
WHERE TRY_CONVERT(decimal(10,2), trip_minutes) IS NULL
  AND trip_minutes IS NOT NULL;


/*
RESULTADO:
No se detectaron valores no convertibles.
Todos los valores de trip_minutes pueden convertirse
correctamente a formato numérico.
*/


/*
========================================================
3. ANÁLISIS INICIAL DE LA DURACIÓN DE LOS VIAJES
========================================================
*/

-- Duración mínima, máxima y media de los viajes
SELECT
    MIN(TRY_CONVERT(decimal(10,2), trip_minutes)) AS min_trip_minutes,
    MAX(TRY_CONVERT(decimal(10,2), trip_minutes)) AS max_trip_minutes,
    AVG(TRY_CONVERT(decimal(10,2), trip_minutes)) AS avg_trip_minutes
FROM dbo.trips_22_01_January;


/*
RESULTADO:
- Duración mínima: -8677,33 minutos
- Duración máxima: 36027,35 minutos
- Duración media: 30,96 minutos

Se detectan valores negativos y duraciones extremadamente altas,
por lo que se realiza una revisión adicional.
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

FROM dbo.trips_22_01_January;


/*
RESULTADO:
- Viajes con duración negativa: 1.604
- Viajes superiores a 24 horas: 1.632
- Total viajes: 244.760
*/


/*
========================================================
4. COMPARACIÓN ENTRE trip_minutes Y LOS TIMESTAMPS
========================================================
*/

-- Comparación entre la duración almacenada y la calculada
SELECT TOP 20
    trip_minutes,
    unlock_date,
    lock_date,
    DATEDIFF(SECOND, unlock_date, lock_date) / 60.0 AS calculated_minutes
FROM dbo.trips_22_01_January
WHERE
    TRY_CONVERT(decimal(10,2), trip_minutes) < 0
    OR TRY_CONVERT(decimal(10,2), trip_minutes) > 1440;


/*
Se observa que trip_minutes y la diferencia entre
unlock_date y lock_date no siempre coinciden.
*/


-- Número de viajes donde ambas duraciones coinciden o no
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

FROM dbo.trips_22_01_January;


/*
RESULTADO:
- Total viajes: 244.760
- Duración coincidente: 235.003
- Duración no coincidente: 9.757
*/


/*
========================================================
5. PATRÓN DE LAS DISCREPANCIAS DE DURACIÓN
========================================================
*/

-- Diferencias más frecuentes entre ambas formas de calcular la duración
SELECT TOP 20
    ROUND(
        DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
        - TRY_CONVERT(decimal(10,2), trip_minutes),
        0
    ) AS diferencia_minutos,

    COUNT(*) AS numero_viajes

FROM dbo.trips_22_01_January

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1

GROUP BY
    ROUND(
        DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
        - TRY_CONVERT(decimal(10,2), trip_minutes),
        0
    )

ORDER BY numero_viajes DESC;


/*
Se detectan diferencias de 60, 120, 180, 240 minutos, etc.

Esto indica que las discrepancias suelen ser múltiplos exactos
de una hora.
*/


-- Comprobación de que todas las discrepancias son múltiplos de 60 minutos
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

FROM dbo.trips_22_01_January

WHERE ABS(
    TRY_CONVERT(decimal(10,2), trip_minutes)
    - DATEDIFF(SECOND, unlock_date, lock_date) / 60.0
) >= 0.1;


/*
RESULTADO:
- Discrepancias totales: 9.757
- Discrepancias en múltiplos exactos de 60 minutos: 9.757

Esto sugiere un desfase sistemático en algunos timestamps
y no un error aleatorio en la duración.
*/


/*
========================================================
6. CONTROL DE VALORES NULOS EN trip_minutes
========================================================
*/

SELECT
    COUNT(*) AS total_viajes,

    SUM(
        CASE
            WHEN trip_minutes IS NULL
            THEN 1
            ELSE 0
        END
    ) AS trip_minutes_nulos

FROM dbo.trips_22_01_January;


/*
RESULTADO:
No existen valores nulos en trip_minutes.
*/


/*
========================================================
7. CONTROL DE DUPLICADOS
========================================================
*/

SELECT
    COUNT(*) AS total_filas,
    COUNT(DISTINCT idTrip) AS viajes_unicos
FROM dbo.trips_22_01_January;


/*
RESULTADO:
No se detectaron duplicados por idTrip.
*/


/*
========================================================
8. REVISIÓN DE ESTACIONES
========================================================
*/

-- Número de estaciones distintas utilizadas como origen y destino
SELECT
    COUNT(DISTINCT station_unlock) AS estaciones_origen,
    COUNT(DISTINCT station_lock) AS estaciones_destino
FROM dbo.trips_22_01_January;


/*
RESULTADO:
- Estaciones de origen: 262
- Estaciones de destino: 259
*/


-- Estaciones que aparecen como origen pero nunca como destino
SELECT DISTINCT
    station_unlock,
    unlock_station_name

FROM dbo.trips_22_01_January

WHERE station_unlock NOT IN (
    SELECT DISTINCT station_lock
    FROM dbo.trips_22_01_January
    WHERE station_lock IS NOT NULL
)

ORDER BY station_unlock;


/*
RESULTADO:
- 115 - Ferraz
- 123 - Guzmán el Bueno
- 124 - Manuel Silvela
*/


-- Número de salidas desde esas estaciones
SELECT
    station_unlock,
    unlock_station_name,
    COUNT(*) AS numero_salidas

FROM dbo.trips_22_01_January

WHERE station_unlock IN (115, 123, 124)

GROUP BY
    station_unlock,
    unlock_station_name

ORDER BY numero_salidas DESC;


/*
RESULTADO:
- Manuel Silvela: 12 salidas
- Ferraz: 11 salidas
- Guzmán el Bueno: 9 salidas

En total representan solo 32 viajes.
*/


-- Estaciones que aparecen como destino pero nunca como origen
SELECT DISTINCT
    station_lock,
    lock_station_name

FROM dbo.trips_22_01_January

WHERE station_lock NOT IN (
    SELECT DISTINCT station_unlock
    FROM dbo.trips_22_01_January
    WHERE station_unlock IS NOT NULL
)

ORDER BY station_lock;


/*
RESULTADO:
No se detectaron estaciones que aparezcan únicamente como destino.
*/


/*
========================================================
9. ESTACIONES NULAS
========================================================
*/

-- Número de registros sin estación de origen o destino
SELECT
    SUM(
        CASE
            WHEN station_unlock IS NULL
            THEN 1
            ELSE 0
        END
    ) AS origen_nulo,

    SUM(
        CASE
            WHEN station_lock IS NULL
            THEN 1
            ELSE 0
        END
    ) AS destino_nulo

FROM dbo.trips_22_01_January;


/*
RESULTADO:
- Sin estación de origen: 1.870
- Sin estación de destino: 2.307
*/


-- Clasificación de los registros según el tipo de ausencia
SELECT
    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND station_lock IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS solo_origen_nulo,

    SUM(
        CASE
            WHEN station_unlock IS NOT NULL
             AND station_lock IS NULL
            THEN 1
            ELSE 0
        END
    ) AS solo_destino_nulo,

    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND station_lock IS NULL
            THEN 1
            ELSE 0
        END
    ) AS ambos_nulos

FROM dbo.trips_22_01_January;


/*
RESULTADO:
- Solo origen nulo: 374
- Solo destino nulo: 811
- Ambos nulos: 1.496
*/


/*
========================================================
10. GEOLOCALIZACIÓN DE LOS REGISTROS SIN ESTACIÓN
========================================================
*/

-- Comprobación de geolocalización cuando ambas estaciones son nulas
SELECT
    SUM(
        CASE
            WHEN geolocation_unlock IS NOT NULL
             AND geolocation_lock IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS ambos_con_geolocalizacion,

    SUM(
        CASE
            WHEN geolocation_unlock IS NULL
              OR geolocation_lock IS NULL
            THEN 1
            ELSE 0
        END
    ) AS falta_alguna_geolocalizacion

FROM dbo.trips_22_01_January

WHERE station_unlock IS NULL
  AND station_lock IS NULL;


/*
RESULTADO:
Los 1.496 viajes sin estación de origen ni destino
mantienen geolocalización en ambos extremos.
*/


-- Comprobación de geolocalización en los casos con una sola estación nula
SELECT
    SUM(
        CASE
            WHEN station_unlock IS NULL
             AND station_lock IS NOT NULL
             AND geolocation_unlock IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS origen_nulo_con_geo,

    SUM(
        CASE
            WHEN station_unlock IS NOT NULL
             AND station_lock IS NULL
             AND geolocation_lock IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS destino_nulo_con_geo

FROM dbo.trips_22_01_January;


/*
RESULTADO:
Todos los registros con estaciones nulas disponen
de la geolocalización correspondiente.

DECISIÓN:
No se eliminarán estos viajes, ya que existe la posibilidad
de recuperar la estación posteriormente mediante
asignación geográfica.
*/


/*
========================================================
11. CONTROL DE FECHAS NULAS
========================================================
*/

SELECT
    SUM(
        CASE
            WHEN unlock_date IS NULL
            THEN 1
            ELSE 0
        END
    ) AS unlock_date_nulos,

    SUM(
        CASE
            WHEN lock_date IS NULL
            THEN 1
            ELSE 0
        END
    ) AS lock_date_nulos

FROM dbo.trips_22_01_January;


/*
RESULTADO:
- unlock_date nulos: 0
- lock_date nulos: 0
*/


/*
========================================================
12. FECHAS INVERTIDAS
========================================================
*/

-- Viajes donde la fecha de bloqueo es anterior a la de desbloqueo
SELECT
    COUNT(*) AS viajes_con_fecha_invertida
FROM dbo.trips_22_01_January
WHERE lock_date < unlock_date;


/*
RESULTADO:
1.604 viajes presentan fechas invertidas.
*/


-- Comprobación de relación con trip_minutes negativo
SELECT
    COUNT(*) AS fechas_invertidas,

    SUM(
        CASE
            WHEN TRY_CONVERT(decimal(10,2), trip_minutes) < 0
            THEN 1
            ELSE 0
        END
    ) AS fechas_invertidas_y_trip_negativo

FROM dbo.trips_22_01_January

WHERE lock_date < unlock_date;


/*
RESULTADO:
Los 1.604 viajes con fechas invertidas son exactamente
los mismos 1.604 viajes con trip_minutes negativo.
*/


/*
========================================================
13. DISTRIBUCIÓN DE LAS FECHAS INVERTIDAS
========================================================
*/

SELECT
    CAST(unlock_date AS date) AS fecha,
    COUNT(*) AS viajes_fecha_invertida

FROM dbo.trips_22_01_January

WHERE lock_date < unlock_date

GROUP BY CAST(unlock_date AS date)

ORDER BY fecha;


/*
RESULTADO:
- 06/01/2022: 1.603 casos
- 30/01/2022: 1 caso

El problema está prácticamente concentrado en el 6 de enero.
*/


-- Porcentaje de viajes afectados el 6 de enero
SELECT
    COUNT(*) AS total_viajes_6_enero,

    SUM(
        CASE
            WHEN lock_date < unlock_date
            THEN 1
            ELSE 0
        END
    ) AS viajes_invertidos,

    100.0
    * SUM(
        CASE
            WHEN lock_date < unlock_date
            THEN 1
            ELSE 0
        END
    )
    / COUNT(*) AS porcentaje_afectado

FROM dbo.trips_22_01_January

WHERE CAST(unlock_date AS date) = '2022-01-06';


/*
RESULTADO:
- Viajes del 6 de enero: 3.910
- Viajes con fechas invertidas: 1.603
- Porcentaje afectado: aproximadamente 41%
*/


/*
========================================================
CONCLUSIONES DEL ANÁLISIS DE CALIDAD - ENERO 2022
========================================================

1. Se cargaron inicialmente 489.520 filas.

2. Se eliminaron 244.760 filas vacías, quedando
   244.760 viajes reales.

3. No se detectaron duplicados por idTrip.

4. trip_minutes:
   - No contiene valores nulos.
   - Todos los valores pueden convertirse a formato numérico.
   - Existen 1.604 valores negativos.
   - Existen 1.632 viajes con una duración superior a 24 horas.

5. En 9.757 viajes, trip_minutes no coincide con la diferencia
   entre unlock_date y lock_date.

6. Todas esas discrepancias son múltiplos exactos de 60 minutos,
   lo que sugiere un problema sistemático en algunos timestamps.

7. Las fechas unlock_date y lock_date están completas.

8. Existen 1.604 viajes con fechas invertidas.
   Esos mismos viajes presentan trip_minutes negativo.

9. El 99,9% de las fechas invertidas se concentra el 06/01/2022.
   Ese día, aproximadamente el 41% de los viajes están afectados.

10. Se detectaron:
    - 1.870 viajes sin estación de origen.
    - 2.307 viajes sin estación de destino.
    - 1.496 viajes sin estación de origen ni destino.

11. Todos los registros con estaciones nulas conservan
    información de geolocalización.

12. Por este motivo, los registros con estaciones nulas
    se conservarán para intentar recuperar posteriormente
    la estación correspondiente mediante coordenadas.

13. Se utilizará trip_minutes como campo principal de duración
    de forma provisional, manteniendo documentadas las
    inconsistencias detectadas en los timestamps.

========================================================
FIN DEL ANÁLISIS DE CALIDAD - ENERO 2022
========================================================
*/