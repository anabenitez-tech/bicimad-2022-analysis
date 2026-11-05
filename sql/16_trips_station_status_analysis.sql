/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 16_trips_station_status_analysis.sql

OBJETIVO:

Cruzar los datos de viajes de dbo.trips_2022
con los datos de disponibilidad de
dbo.station_status_2022.

El objetivo es analizar si las estaciones con mayor
desequilibrio entre salidas y llegadas presentan también
problemas reales de disponibilidad, como:

- quedarse sin bicicletas;
- quedarse sin bases libres;
- presentar patrones persistentes de desequilibrio.

========================================================
*/

USE BiciMAD;
GO

/*
========================================================
1. VALIDACIÓN DEL CRUCE ENTRE VIAJES Y ESTACIONES
========================================================
*/

SELECT
    COUNT(DISTINCT t.station_unlock) AS estaciones_origen_viajes,
    COUNT(DISTINCT s.station_id) AS estaciones_station_status
FROM dbo.trips_2022 t
LEFT JOIN (
    SELECT DISTINCT station_id
    FROM dbo.station_status_2022
) s
    ON TRY_CONVERT(int, t.station_unlock) = s.station_id;

    /*
========================================================
2. ESTACIONES DE VIAJES SIN CORRESPONDENCIA EN STATION STATUS
========================================================
*/

SELECT DISTINCT
    t.station_unlock
FROM dbo.trips_2022 t
LEFT JOIN (
    SELECT DISTINCT station_id
    FROM dbo.station_status_2022
) s
    ON TRY_CONVERT(int, t.station_unlock) = s.station_id
WHERE t.station_unlock IS NOT NULL
  AND s.station_id IS NULL
ORDER BY t.station_unlock;

/*
========================================================
3. COMPROBACIÓN DE IDs NO ENCONTRADOS COMO STATION_NUMBER
========================================================
*/

WITH estaciones_sin_match AS (
    SELECT DISTINCT
        t.station_unlock
    FROM dbo.trips_2022 t
    LEFT JOIN (
        SELECT DISTINCT station_id
        FROM dbo.station_status_2022
    ) s
        ON TRY_CONVERT(int, t.station_unlock) = s.station_id
    WHERE t.station_unlock IS NOT NULL
      AND s.station_id IS NULL
)

SELECT
    e.station_unlock,
    s.station_id,
    s.station_number,
    s.station_name
FROM estaciones_sin_match e
LEFT JOIN (
    SELECT DISTINCT
        station_id,
        station_number,
        station_name
    FROM dbo.station_status_2022
) s
    ON e.station_unlock = s.station_number
ORDER BY e.station_unlock;

/*
========================================================
4. IDENTIFICACIÓN DE LOS CÓDIGOS 501-508
========================================================
*/

WITH nombres AS (
    SELECT
        station_unlock,
        unlock_station_name,
        COUNT(*) AS viajes,
        ROW_NUMBER() OVER (
            PARTITION BY station_unlock
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM dbo.trips_2022
    WHERE station_unlock IN (
        '501','502','503','504',
        '505','506','507','508'
    )
    GROUP BY
        station_unlock,
        unlock_station_name
)

SELECT
    station_unlock,
    unlock_station_name,
    viajes
FROM nombres
WHERE rn = 1
ORDER BY station_unlock;

/*
INTERPRETACIÓN:

La columna station_unlock no utiliza un único sistema de
identificación durante todo 2022.

Se han detectado tres casos:

1. Valores que corresponden directamente a station_id.
2. Valores que corresponden a station_number
   (por ejemplo 1a, 106a, 80b).
3. Códigos especiales 501-508 que representan estaciones
   existentes mediante un identificador alternativo.

Los códigos especiales encontrados son:

501 -> 1a -> Puerta del Sol A
502 -> 1b -> Puerta del Sol B
503 -> 2  -> Miguel Moya
504 -> 3  -> Plaza Conde Suchil
505 -> 4  -> Malasaña
506 -> 5  -> Fuencarral
507 -> 6  -> Colegio Arquitectos
508 -> 7  -> Hortaleza

Por este motivo, el cruce entre viajes y station status
no debe realizarse únicamente mediante station_id.
*/

/*
========================================================
5. TABLA DE EQUIVALENCIAS DE ESTACIONES
========================================================
*/

CREATE TABLE dbo.station_id_mapping (
    trip_station_code nvarchar(50),
    station_id int
);

/*
========================================================
6. EQUIVALENCIAS DIRECTAS POR STATION_ID
========================================================
*/

INSERT INTO dbo.station_id_mapping (
    trip_station_code,
    station_id
)
SELECT DISTINCT
    CAST(station_id AS nvarchar(50)),
    station_id
FROM dbo.station_status_2022;

SELECT COUNT(*) AS mappings_actuales
FROM dbo.station_id_mapping;

/*
========================================================
7. EQUIVALENCIAS POR STATION_NUMBER
========================================================
*/

INSERT INTO dbo.station_id_mapping (
    trip_station_code,
    station_id
)
SELECT DISTINCT
    station_number,
    station_id
FROM dbo.station_status_2022 s
WHERE station_number IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.station_id_mapping m
      WHERE m.trip_station_code = s.station_number
  );

  SELECT COUNT(*) AS mappings_actuales
FROM dbo.station_id_mapping;

/*
========================================================
8. EQUIVALENCIAS ESPECIALES 501-508
========================================================
*/

INSERT INTO dbo.station_id_mapping (
    trip_station_code,
    station_id
)
VALUES
    ('501', 1),
    ('502', 2),
    ('503', 3),
    ('504', 4),
    ('505', 5),
    ('506', 6),
    ('507', 7),
    ('508', 8);

    SELECT COUNT(*) AS mappings_totales
FROM dbo.station_id_mapping;

/*
========================================================
9. VALIDACIÓN FINAL DEL MAPEO DE ESTACIONES
========================================================
*/

SELECT
    COUNT(DISTINCT t.station_unlock) AS codigos_origen_distintos,
    COUNT(DISTINCT m.trip_station_code) AS codigos_mapeados
FROM dbo.trips_2022 t
LEFT JOIN dbo.station_id_mapping m
    ON t.station_unlock = m.trip_station_code
WHERE t.station_unlock IS NOT NULL;

/*
========================================================
10. VALIDACIÓN DEL MAPEO DE ESTACIONES DE DESTINO
========================================================
*/

SELECT
    COUNT(DISTINCT t.station_lock) AS codigos_destino_distintos,
    COUNT(DISTINCT m.trip_station_code) AS codigos_mapeados
FROM dbo.trips_2022 t
LEFT JOIN dbo.station_id_mapping m
    ON t.station_lock = m.trip_station_code
WHERE t.station_lock IS NOT NULL;

/*
========================================================
11. BALANCE DE VIAJES POR ESTACIÓN NORMALIZADA
========================================================
*/

WITH salidas AS (
    SELECT
        m.station_id,
        COUNT(*) AS viajes_salida
    FROM dbo.trips_2022 t
    INNER JOIN dbo.station_id_mapping m
        ON t.station_unlock = m.trip_station_code
    WHERE t.station_unlock IS NOT NULL
      AND t.es_viaje_breve_circular = 0
    GROUP BY m.station_id
),
llegadas AS (
    SELECT
        m.station_id,
        COUNT(*) AS viajes_llegada
    FROM dbo.trips_2022 t
    INNER JOIN dbo.station_id_mapping m
        ON t.station_lock = m.trip_station_code
    WHERE t.station_lock IS NOT NULL
      AND t.es_viaje_breve_circular = 0
    GROUP BY m.station_id
)

SELECT TOP 20
    s.station_id,
    st.station_number,
    st.station_name,
    ISNULL(sa.viajes_salida, 0) AS viajes_salida,
    ISNULL(l.viajes_llegada, 0) AS viajes_llegada,
    ISNULL(l.viajes_llegada, 0) - ISNULL(sa.viajes_salida, 0) AS balance_neto
FROM (
    SELECT DISTINCT station_id
    FROM dbo.station_status_2022
) s
LEFT JOIN salidas sa
    ON s.station_id = sa.station_id
LEFT JOIN llegadas l
    ON s.station_id = l.station_id
LEFT JOIN (
    SELECT DISTINCT
        station_id,
        station_number,
        station_name
    FROM dbo.station_status_2022
) st
    ON s.station_id = st.station_id
ORDER BY ABS(
    ISNULL(l.viajes_llegada, 0) - ISNULL(sa.viajes_salida, 0)
) DESC;

/*
========================================================
12. BALANCE DE VIAJES VS DISPONIBILIDAD DE ESTACIONES
========================================================
*/

WITH salidas AS (
    SELECT
        m.station_id,
        COUNT(*) AS viajes_salida
    FROM dbo.trips_2022 t
    INNER JOIN dbo.station_id_mapping m
        ON t.station_unlock = m.trip_station_code
    WHERE t.es_viaje_breve_circular = 0
    GROUP BY m.station_id
),

llegadas AS (
    SELECT
        m.station_id,
        COUNT(*) AS viajes_llegada
    FROM dbo.trips_2022 t
    INNER JOIN dbo.station_id_mapping m
        ON t.station_lock = m.trip_station_code
    WHERE t.es_viaje_breve_circular = 0
    GROUP BY m.station_id
),

disponibilidad AS (
    SELECT
        station_id,
        MAX(station_number) AS station_number,
        MAX(station_name) AS station_name,
        COUNT(*) AS snapshots_operativos,

        100.0 * SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END)
        / COUNT(*) AS pct_sin_bicis,

        100.0 * SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END)
        / COUNT(*) AS pct_sin_huecos

    FROM dbo.station_status_2022
    WHERE no_available = 0
    GROUP BY station_id
)

SELECT TOP 20
    d.station_id,
    d.station_number,
    d.station_name,
    ISNULL(sa.viajes_salida, 0) AS viajes_salida,
    ISNULL(l.viajes_llegada, 0) AS viajes_llegada,

    ISNULL(l.viajes_llegada, 0)
      - ISNULL(sa.viajes_salida, 0) AS balance_neto,

    ROUND(d.pct_sin_bicis, 2) AS pct_sin_bicis,
    ROUND(d.pct_sin_huecos, 2) AS pct_sin_huecos

FROM disponibilidad d
LEFT JOIN salidas sa
    ON d.station_id = sa.station_id
LEFT JOIN llegadas l
    ON d.station_id = l.station_id

ORDER BY ABS(
    ISNULL(l.viajes_llegada, 0)
    - ISNULL(sa.viajes_salida, 0)
) DESC;

/*
INTERPRETACIÓN:

El cruce entre el balance neto de viajes y la disponibilidad
de las estaciones muestra un patrón coherente:

- Las estaciones con balance neto positivo
  (más llegadas que salidas) tienden a presentar
  mayores porcentajes de tiempo sin bases libres.

- Las estaciones con balance neto negativo
  (más salidas que llegadas) tienden a presentar
  mayores porcentajes de tiempo sin bicicletas.

Ejemplos:

- Marqués de Vadillo:
  balance +3.413
  8,93% de snapshots operativos sin huecos libres.

- Puerta del Ángel:
  balance +3.400
  7,43% sin huecos libres.

- Paseo de la Castellana con Raimundo Fernández:
  balance -2.268
  8,83% sin bicicletas.

Estos resultados sugieren que el desequilibrio entre entradas
y salidas está relacionado con los problemas de disponibilidad
observados en las estaciones.

El análisis no demuestra causalidad, pero proporciona evidencia
consistente de una relación entre los flujos de viajes y los
estados de saturación o falta de bicicletas.
*/

/*
========================================================
13. CORRELACIÓN ENTRE BALANCE Y DISPONIBILIDAD
========================================================
*/

WITH salidas AS (
    SELECT
        m.station_id,
        COUNT_BIG(*) AS viajes_salida
    FROM dbo.trips_2022 t
    INNER JOIN dbo.station_id_mapping m
        ON t.station_unlock = m.trip_station_code
    WHERE t.es_viaje_breve_circular = 0
    GROUP BY m.station_id
),

llegadas AS (
    SELECT
        m.station_id,
        COUNT_BIG(*) AS viajes_llegada
    FROM dbo.trips_2022 t
    INNER JOIN dbo.station_id_mapping m
        ON t.station_lock = m.trip_station_code
    WHERE t.es_viaje_breve_circular = 0
    GROUP BY m.station_id
),

base AS (
    SELECT
        d.station_id,

        CAST(
            ISNULL(l.viajes_llegada, 0)
            - ISNULL(sa.viajes_salida, 0)
            AS FLOAT
        ) AS balance_neto,

        CAST(
            100.0
            * SUM(CASE WHEN d.dock_bikes = 0 THEN 1.0 ELSE 0.0 END)
            / COUNT_BIG(*)
            AS FLOAT
        ) AS pct_sin_bicis,

        CAST(
            100.0
            * SUM(CASE WHEN d.free_bases = 0 THEN 1.0 ELSE 0.0 END)
            / COUNT_BIG(*)
            AS FLOAT
        ) AS pct_sin_huecos

    FROM dbo.station_status_2022 d

    LEFT JOIN salidas sa
        ON d.station_id = sa.station_id

    LEFT JOIN llegadas l
        ON d.station_id = l.station_id

    WHERE d.no_available = 0

    GROUP BY
        d.station_id,
        sa.viajes_salida,
        l.viajes_llegada
)

SELECT
    (
        COUNT_BIG(*) * SUM(balance_neto * pct_sin_bicis)
        - SUM(balance_neto) * SUM(pct_sin_bicis)
    )
    /
    NULLIF(
        SQRT(
            (
                COUNT_BIG(*) * SUM(POWER(balance_neto, 2))
                - POWER(SUM(balance_neto), 2)
            )
            *
            (
                COUNT_BIG(*) * SUM(POWER(pct_sin_bicis, 2))
                - POWER(SUM(pct_sin_bicis), 2)
            )
        ),
        0
    ) AS corr_balance_sin_bicis,

    (
        COUNT_BIG(*) * SUM(balance_neto * pct_sin_huecos)
        - SUM(balance_neto) * SUM(pct_sin_huecos)
    )
    /
    NULLIF(
        SQRT(
            (
                COUNT_BIG(*) * SUM(POWER(balance_neto, 2))
                - POWER(SUM(balance_neto), 2)
            )
            *
            (
                COUNT_BIG(*) * SUM(POWER(pct_sin_huecos, 2))
                - POWER(SUM(pct_sin_huecos), 2)
            )
        ),
        0
    ) AS corr_balance_sin_huecos

FROM base;

/*
INTERPRETACIÓN:

La correlación de Pearson entre el balance neto de viajes
y los problemas de disponibilidad confirma el patrón observado
en el análisis por estaciones.

Resultados:

- Correlación balance vs. porcentaje sin bicicletas:
  -0,352

- Correlación balance vs. porcentaje sin huecos:
   0,670

Interpretación:

La correlación positiva de 0,670 indica una relación relevante
entre un balance neto positivo (más llegadas que salidas) y
la frecuencia con la que una estación se queda sin bases libres.

La correlación negativa de -0,352 indica que las estaciones con
más salidas que llegadas tienden a presentar más episodios sin
bicicletas, aunque la relación es menos intensa.

Estos resultados refuerzan la hipótesis de que los desequilibrios
de flujo de las estaciones están relacionados con problemas de
disponibilidad del sistema.

La correlación no implica causalidad y pueden existir otros factores,
como la capacidad de la estación, la localización, la demanda por
franja horaria o las operaciones de redistribución.
*/

/*
========================================================
14. DISPONIBILIDAD CRÍTICA POR HORA DEL DÍA
========================================================
*/

SELECT
    DATEPART(HOUR, snapshot_time) AS hora,

    COUNT(*) AS snapshots_operativos,

    SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END) AS snapshots_sin_bicis,

    SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END) AS snapshots_sin_huecos,

    ROUND(
        100.0 * SUM(CASE WHEN dock_bikes = 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS pct_sin_bicis,

    ROUND(
        100.0 * SUM(CASE WHEN free_bases = 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS pct_sin_huecos

FROM dbo.station_status_2022
WHERE no_available = 0

GROUP BY
    DATEPART(HOUR, snapshot_time)

ORDER BY
    hora;

    /*
INTERPRETACIÓN:

El análisis horario de disponibilidad muestra que los problemas
de estaciones vacías o saturadas no se concentran exactamente
en las mismas horas que los picos de demanda de viajes.

La falta de bicicletas presenta sus mayores porcentajes durante
la madrugada, aproximadamente entre las 03:00 y las 05:00,
con valores cercanos al 3,5%.

Durante las horas centrales del día, especialmente entre las
14:00 y las 17:00, el porcentaje de estaciones sin bicicletas
desciende hasta valores próximos al 1,2%.

La falta de bases libres también es más frecuente durante la
madrugada y vuelve a aumentar en las últimas horas del día,
especialmente entre las 21:00 y las 23:00.

Este patrón sugiere que los estados críticos de disponibilidad
no dependen únicamente del volumen instantáneo de viajes,
sino también de cómo se acumulan los desequilibrios de flujo
a lo largo del día y de posibles procesos operativos del sistema.
*/

/*
========================================================
CIERRE DEL ARCHIVO 16_trips_station_status_analysis.sql
========================================================

RESULTADOS PRINCIPALES:

1. Se normalizaron los identificadores de estación de los viajes
   mediante una tabla de equivalencias.

2. Se consiguió mapear:
   - 100% de los códigos de estación de origen.
   - 100% de los códigos de estación de destino.

3. Se identificaron tres sistemas de identificación:
   - station_id
   - station_number
   - códigos especiales 501-508

4. Se recalculó el balance neto de viajes por estación utilizando
   identificadores normalizados.

5. Se cruzó el balance de viajes con los estados reales de
   disponibilidad de las estaciones.

6. Se observó que:
   - balances positivos tienden a asociarse con falta de huecos;
   - balances negativos tienden a asociarse con falta de bicicletas.

7. Correlaciones obtenidas:
   - balance vs. porcentaje sin bicicletas: -0,352
   - balance vs. porcentaje sin huecos:      0,670

8. La relación con la falta de huecos es especialmente relevante:
   las estaciones con más llegadas que salidas presentan una mayor
   tendencia a saturarse.

9. El análisis horario mostró que los estados críticos de
   disponibilidad no coinciden exactamente con los picos de viajes,
   lo que sugiere acumulación de desequilibrios a lo largo del día.

CONCLUSIÓN:

El análisis conjunto de viajes y disponibilidad muestra que los
desequilibrios de flujo entre estaciones están relacionados con
problemas reales de disponibilidad del sistema.

La relación es especialmente clara entre un exceso acumulado de
llegadas y la falta de bases libres.

Estos resultados no demuestran causalidad, pero ofrecen evidencia
cuantitativa útil para identificar estaciones potencialmente
prioritarias para análisis operativo o redistribución.

========================================================
FIN DEL ARCHIVO
========================================================
*/