/*
========================================================
PROYECTO: BiciMAD Mobility Analytics
ARCHIVO: 14_eda_2022.sql
OBJETIVO:
Realizar el análisis exploratorio anual de los viajes
BiciMAD correspondientes a 2022.
========================================================
*/

USE BiciMAD;
GO

/*
========================================================
1. VOLUMEN DE VIAJES POR MES
========================================================
*/

SELECT
    mes,
    COUNT(*) AS total_viajes
FROM dbo.trips_2022
GROUP BY mes
ORDER BY mes;

/*
RESULTADO:

El volumen de viajes presenta una variación clara a lo largo del año.

- Mes con mayor demanda: mayo, con 477.934 viajes.
- Otros meses de alta actividad:
    septiembre: 447.210
    junio:      434.399
    octubre:    433.718

- Meses con menor actividad:
    enero:      244.760
    diciembre:  246.554

- Agosto presenta también una reducción notable de la demanda,
  con 274.744 viajes.

OBSERVACIÓN:

Se aprecia un posible patrón estacional, con mayor utilización
durante primavera y comienzos de otoño, y menor actividad
durante invierno y el periodo vacacional de agosto.
*/


/*
========================================================
2. VOLUMEN DE VIAJES POR DÍA DE LA SEMANA
========================================================
*/

SELECT
    CASE ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS dia_semana,

    COUNT(*) AS total_viajes

FROM dbo.trips_2022

GROUP BY ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)

ORDER BY ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1);

/*
RESULTADO:

La demanda es mayor durante los días laborables.

- Miércoles presenta el mayor volumen: 680.983 viajes.
- Martes y jueves también muestran una demanda elevada:
    martes: 658.459
    jueves: 649.124

- El volumen disminuye durante el fin de semana:
    sábado: 499.546
    domingo: 455.570

- Domingo es el día con menor número de viajes.

OBSERVACIÓN:

El patrón semanal sugiere un uso importante de BiciMAD
asociado a desplazamientos cotidianos durante los días
laborables.

Para comprobar esta hipótesis se analizará a continuación
la distribución de los viajes por hora del día.
*/

/*
========================================================
3. VOLUMEN DE VIAJES POR HORA DEL DÍA
========================================================
*/

SELECT
    DATEPART(HOUR, unlock_date) AS hora,
    COUNT(*) AS total_viajes
FROM dbo.trips_2022
GROUP BY DATEPART(HOUR, unlock_date)
ORDER BY hora;

/*
RESULTADO:

La distribución horaria muestra varios periodos de alta demanda.

Principales horas punta:
- 19:00 -> 325.736 viajes
- 18:00 -> 311.622 viajes
- 20:00 -> 288.845 viajes
- 14:00 -> 280.877 viajes
- 08:00 -> 259.789 viajes

La demanda es especialmente baja durante la madrugada,
alcanzando el mínimo a las 04:00 con 31.168 viajes.

OBSERVACIÓN:

Se identifica un patrón de doble pico:

1. Un pico matinal alrededor de las 08:00.
2. Un pico mucho más intenso entre las 18:00 y las 20:00.

También se observa un aumento relevante alrededor de las 14:00.

Este comportamiento es compatible con desplazamientos asociados
a rutinas diarias, trabajo, estudios y actividades de tarde.

Para comprobar mejor esta interpretación se comparará el patrón
horario de los días laborables con el de los fines de semana.
*/

/*
========================================================
4. PATRÓN HORARIO: LABORABLES VS FIN DE SEMANA
========================================================
*/

;WITH viajes_diarios AS (
    SELECT
        fecha,
        DATEPART(HOUR, unlock_date) AS hora,

        CASE
            WHEN ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)
                 BETWEEN 1 AND 5
            THEN 'Laborable'
            ELSE 'Fin de semana'
        END AS tipo_dia,

        COUNT(*) AS viajes
    FROM dbo.trips_2022
    GROUP BY
        fecha,
        DATEPART(HOUR, unlock_date),
        CASE
            WHEN ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)
                 BETWEEN 1 AND 5
            THEN 'Laborable'
            ELSE 'Fin de semana'
        END
)

SELECT
    hora,
    tipo_dia,
    CAST(AVG(CAST(viajes AS decimal(10,2))) AS decimal(10,2))
        AS promedio_viajes_dia
FROM viajes_diarios
GROUP BY hora, tipo_dia
ORDER BY hora, tipo_dia;

/*
RESULTADO:

La comparación entre días laborables y fines de semana
confirma que existen patrones de uso claramente diferentes.

DÍAS LABORABLES:

- Se observa un fuerte pico matinal:
    08:00 -> 939,37 viajes/día de media

- El principal periodo de demanda se produce por la tarde:
    18:00 -> 972,83
    19:00 -> 1.009,87
    20:00 -> 871,94

- La hora de máxima demanda es las 19:00.

FIN DE SEMANA:

- No aparece el fuerte pico matinal de las 08:00.
- La demanda aumenta progresivamente desde media mañana
  y permanece relativamente elevada durante la tarde.
- El máximo se alcanza alrededor de las 19:00:
    19:00 -> 601,63 viajes/día de media.

- Durante la madrugada, el uso es notablemente superior
  al observado en los días laborables.

OBSERVACIÓN:

Los resultados refuerzan la hipótesis de que BiciMAD cumple
una función importante en la movilidad cotidiana durante
los días laborables, con picos coincidentes con horarios
habituales de entrada y salida.

Durante el fin de semana el patrón es más uniforme y se
desplaza hacia las horas centrales y nocturnas, lo que
sugiere un mayor peso de desplazamientos de ocio y actividades
no vinculadas directamente a horarios laborales.
*/

/*
========================================================
5. TOP 10 ESTACIONES DE ORIGEN
========================================================
*/

SELECT TOP 10
    station_unlock,
    unlock_station_name,
    COUNT(*) AS total_salidas
FROM dbo.trips_2022
WHERE station_unlock IS NOT NULL
GROUP BY
    station_unlock,
    unlock_station_name
ORDER BY total_salidas DESC;

/*
RESULTADO:

Las estaciones con mayor número de salidas durante 2022 son:

1. Plaza de la Cebada        -> 40.846
2. Plaza de Lavapiés         -> 38.885
3. Segovia 45                -> 33.802
4. Marqués de Vadillo        -> 32.776
5. Quevedo                   -> 30.651
6. Puerta de Madrid          -> 30.301
7. Antón Martín              -> 29.167
8. Puerta de Toledo          -> 27.453
9. Paseo de la Florida       -> 26.931
10. Plaza de la Independencia-> 26.412

OBSERVACIÓN:

La demanda de origen está concentrada en un grupo reducido
de estaciones con un volumen de salidas claramente superior
al resto.

Estas estaciones pueden considerarse puntos de alta generación
de viajes y serán relevantes posteriormente para estudiar
desequilibrios entre salidas y llegadas.
*/

/*
========================================================
6. TOP 10 ESTACIONES DE DESTINO
========================================================
*/

SELECT TOP 10
    station_lock,
    lock_station_name,
    COUNT(*) AS total_llegadas
FROM dbo.trips_2022
WHERE station_lock IS NOT NULL
GROUP BY
    station_lock,
    lock_station_name
ORDER BY total_llegadas DESC;

/*
RESULTADO:

Las estaciones con mayor número de llegadas durante 2022 son:

1. Plaza de la Cebada         -> 41.222
2. Plaza de Lavapiés          -> 38.183
3. Marqués de Vadillo         -> 35.732
4. Segovia 45                 -> 34.351
5. Quevedo                    -> 31.143
6. Paseo de la Florida        -> 30.096
7. Antón Martín               -> 29.556
8. Puerta de Madrid           -> 29.287
9. Puerta del Ángel           -> 28.823
10. Puerta de Toledo          -> 27.980

OBSERVACIÓN:

El ranking de destinos presenta una fuerte similitud con
el ranking de estaciones de origen.

Esto indica que varias estaciones concentran un alto nivel
de actividad tanto en salidas como en llegadas.

No obstante, algunas diferencias entre ambos rankings sugieren
la existencia de posibles desequilibrios de flujo entre estaciones.

Por ejemplo, Puerta del Ángel aparece entre las estaciones con
más llegadas, pero no entre las principales estaciones de origen.

Este aspecto se analizará mediante el balance neto entre
llegadas y salidas por estación.
*/

/*
========================================================
7. BALANCE NETO POR ESTACIÓN
========================================================
*/

;WITH salidas AS (
    SELECT
        station_unlock AS station_id,
        MAX(unlock_station_name) AS station_name,
        COUNT(*) AS total_salidas
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
    GROUP BY station_unlock
),

llegadas AS (
    SELECT
        station_lock AS station_id,
        MAX(lock_station_name) AS station_name,
        COUNT(*) AS total_llegadas
    FROM dbo.trips_2022
    WHERE station_lock IS NOT NULL
    GROUP BY station_lock
)

SELECT TOP 20
    COALESCE(s.station_id, l.station_id) AS station_id,
    COALESCE(s.station_name, l.station_name) AS station_name,
    ISNULL(s.total_salidas, 0) AS total_salidas,
    ISNULL(l.total_llegadas, 0) AS total_llegadas,
    ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0) AS balance_neto
FROM salidas s
FULL OUTER JOIN llegadas l
    ON s.station_id = l.station_id
ORDER BY ABS(
    ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0)
) DESC;

/*
========================================================
7.1 VALIDACIÓN DE ID Y NOMBRE DE ESTACIÓN
========================================================
*/

SELECT
    station_unlock AS station_id,
    COUNT(DISTINCT unlock_station_name) AS nombres_distintos
FROM dbo.trips_2022
WHERE station_unlock IS NOT NULL
  AND unlock_station_name IS NOT NULL
GROUP BY station_unlock
HAVING COUNT(DISTINCT unlock_station_name) > 1
ORDER BY nombres_distintos DESC;

/*
========================================================
7.2 REVISIÓN DE CAMBIOS DE NOMBRE POR MES
========================================================
*/

SELECT
    mes,
    station_unlock AS station_id,
    unlock_station_name AS station_name,
    COUNT(*) AS total_viajes
FROM dbo.trips_2022
WHERE station_unlock IN ('132', '220')
GROUP BY
    mes,
    station_unlock,
    unlock_station_name
ORDER BY
    station_unlock,
    mes,
    total_viajes DESC;

    /*
OBSERVACIÓN:

La relación entre station_id y station_name presenta inconsistencias.

En la mayoría de los casos se observa un cambio de formato
en el nombre de la estación durante el año.

Ejemplo:

station_id = 132
- Paseo de la Florida
- 161 - Paseo de la Florida

Ambos nombres representan aparentemente la misma estación,
pero también existen unos pocos registros asociados a
"Glorieta de los Cuatro Caminos".

Un comportamiento similar se observa para station_id = 220,
principalmente asociado a Marqués de Vadillo pero con algunos
registros vinculados a Plaza del Encuentro.

Por tanto, no se utilizará MAX(station_name) para asignar
el nombre de una estación, ya que puede seleccionar un nombre
minoritario o incorrecto.

Será necesario determinar el nombre predominante de cada
station_id antes de analizar los balances entre estaciones.
*/

/*
========================================================
7.3 NOMBRE PREDOMINANTE POR STATION_ID
========================================================
*/

;WITH nombres AS (
    SELECT
        station_unlock AS station_id,
        unlock_station_name AS station_name,
        COUNT(*) AS frecuencia
    FROM dbo.trips_2022
    WHERE station_unlock IN ('132', '220')
      AND unlock_station_name IS NOT NULL
    GROUP BY
        station_unlock,
        unlock_station_name
),

ranking AS (
    SELECT
        station_id,
        station_name,
        frecuencia,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY frecuencia DESC
        ) AS rn
    FROM nombres
)

SELECT
    station_id,
    station_name,
    frecuencia
FROM ranking
WHERE rn = 1
ORDER BY station_id;

/*
========================================================
7.4 BALANCE NETO POR ESTACIÓN CON NOMBRE PREDOMINANTE
========================================================
*/

;WITH nombres_origen AS (
    SELECT
        station_unlock AS station_id,
        unlock_station_name AS station_name,
        COUNT(*) AS frecuencia
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
      AND unlock_station_name IS NOT NULL
    GROUP BY
        station_unlock,
        unlock_station_name
),

ranking_nombres AS (
    SELECT
        station_id,
        station_name,
        frecuencia,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY frecuencia DESC
        ) AS rn
    FROM nombres_origen
),

nombre_principal AS (
    SELECT
        station_id,
        station_name
    FROM ranking_nombres
    WHERE rn = 1
),

salidas AS (
    SELECT
        station_unlock AS station_id,
        COUNT(*) AS total_salidas
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
    GROUP BY station_unlock
),

llegadas AS (
    SELECT
        station_lock AS station_id,
        COUNT(*) AS total_llegadas
    FROM dbo.trips_2022
    WHERE station_lock IS NOT NULL
    GROUP BY station_lock
)

SELECT TOP 20
    COALESCE(s.station_id, l.station_id) AS station_id,
    np.station_name,
    ISNULL(s.total_salidas, 0) AS total_salidas,
    ISNULL(l.total_llegadas, 0) AS total_llegadas,
    ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0) AS balance_neto
FROM salidas s
FULL OUTER JOIN llegadas l
    ON s.station_id = l.station_id
LEFT JOIN nombre_principal np
    ON np.station_id = COALESCE(s.station_id, l.station_id)
ORDER BY ABS(
    ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0)
) DESC;

/*
RESULTADO:

Se detectan desequilibrios relevantes entre llegadas y salidas
en determinadas estaciones.

ESTACIONES CON MAYOR BALANCE POSITIVO
(más llegadas que salidas):

- 132 - Paseo de la Florida              -> +3.480
- 220 - Marqués de Vadillo               -> +3.413
- 224 - Puerta del Ángel                 -> +3.400
- 232 - Caramuel                         -> +2.073
- 135 - Entrada Matadero                 -> +2.028

ESTACIONES CON MAYOR BALANCE NEGATIVO
(más salidas que llegadas):

- 154 - Paseo de la Castellana con Raimundo Fernández -> -2.268
- 200 - Avenida de los Toreros                          -> -1.942
- 102 - Alcalá                                         -> -1.691
- 156 - Bravo Murillo 44                               -> -1.448
- 158 - Plaza de San Juan de la Cruz                   -> -1.415

OBSERVACIÓN:

Los resultados muestran que el sistema presenta desequilibrios
espaciales entre estaciones.

Las estaciones con balance positivo tienden a acumular bicicletas,
mientras que las estaciones con balance negativo tienden a perderlas.

Este patrón puede generar problemas operativos de disponibilidad,
por lo que será especialmente relevante al combinar estos datos
con los registros de estado de las estaciones.
*/

/*
========================================================
8. DESEQUILIBRIO RELATIVO POR ESTACIÓN
========================================================
*/

;WITH salidas AS (
    SELECT
        station_unlock AS station_id,
        COUNT(*) AS total_salidas
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
    GROUP BY station_unlock
),

llegadas AS (
    SELECT
        station_lock AS station_id,
        COUNT(*) AS total_llegadas
    FROM dbo.trips_2022
    WHERE station_lock IS NOT NULL
    GROUP BY station_lock
)

SELECT TOP 20
    COALESCE(s.station_id, l.station_id) AS station_id,
    ISNULL(s.total_salidas, 0) AS total_salidas,
    ISNULL(l.total_llegadas, 0) AS total_llegadas,

    ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0)
        AS balance_neto,

    CAST(
        100.0 *
        (
            ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0)
        )
        /
        NULLIF(
            ISNULL(l.total_llegadas, 0) + ISNULL(s.total_salidas, 0),
            0
        )
        AS decimal(10,2)
    ) AS desequilibrio_pct

FROM salidas s
FULL OUTER JOIN llegadas l
    ON s.station_id = l.station_id

ORDER BY ABS(
    100.0 *
    (
        ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0)
    )
    /
    NULLIF(
        ISNULL(l.total_llegadas, 0) + ISNULL(s.total_salidas, 0),
        0
    )
) DESC;

/*
OBSERVACIÓN:

El ranking de desequilibrio porcentual está dominado por
identificadores con muy pocos movimientos.

Ejemplos:
- 106b -> 7 salidas y 0 llegadas
- 111a -> 3 salidas y 0 llegadas
- 20   -> 0 salidas y 7 llegadas

Aunque presentan desequilibrios cercanos al 100%, su volumen
es demasiado bajo para considerarlos prioritarios desde un
punto de vista operativo.

DECISIÓN:

Para analizar desequilibrios relativos relevantes se aplicará
un umbral mínimo de actividad total por estación.
*/

/*
========================================================
8.1 DESEQUILIBRIO RELATIVO EN ESTACIONES CON ACTIVIDAD RELEVANTE
========================================================
*/

;WITH salidas AS (
    SELECT
        station_unlock AS station_id,
        COUNT(*) AS total_salidas
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
    GROUP BY station_unlock
),

llegadas AS (
    SELECT
        station_lock AS station_id,
        COUNT(*) AS total_llegadas
    FROM dbo.trips_2022
    WHERE station_lock IS NOT NULL
    GROUP BY station_lock
)

SELECT TOP 20
    COALESCE(s.station_id, l.station_id) AS station_id,

    ISNULL(s.total_salidas, 0) AS total_salidas,

    ISNULL(l.total_llegadas, 0) AS total_llegadas,

    ISNULL(l.total_llegadas, 0)
        - ISNULL(s.total_salidas, 0) AS balance_neto,

    CAST(
        100.0 *
        (
            ISNULL(l.total_llegadas, 0)
            - ISNULL(s.total_salidas, 0)
        )
        /
        NULLIF(
            ISNULL(l.total_llegadas, 0)
            + ISNULL(s.total_salidas, 0),
            0
        )
        AS decimal(10,2)
    ) AS desequilibrio_pct

FROM salidas s

FULL OUTER JOIN llegadas l
    ON s.station_id = l.station_id

WHERE
    ISNULL(s.total_salidas, 0)
    + ISNULL(l.total_llegadas, 0) >= 1000

ORDER BY ABS(
    100.0 *
    (
        ISNULL(l.total_llegadas, 0)
        - ISNULL(s.total_salidas, 0)
    )
    /
    NULLIF(
        ISNULL(l.total_llegadas, 0)
        + ISNULL(s.total_salidas, 0),
        0
    )
) DESC;

/*
RESULTADO:

Tras aplicar un umbral mínimo de 1.000 movimientos anuales,
el ranking de desequilibrio relativo resulta mucho más útil.

Principales estaciones con balance negativo relativo:

- station_id 28  -> -11,89%
- station_id 144 -> -7,81%
- station_id 29  -> -7,56%
- station_id 102 -> -7,17%
- station_id 200 -> -6,93%

Principales estaciones con balance positivo relativo:

- station_id 233 -> +6,88%
- station_id 85  -> +5,55%
- station_id 224 -> +5,50%
- station_id 132 -> +5,37%

OBSERVACIÓN:

Un porcentaje negativo indica que la estación registra
más salidas que llegadas, por lo que tiende a perder bicicletas.

Un porcentaje positivo indica que registra más llegadas que
salidas, por lo que tiende a acumular bicicletas.

Este tipo de desequilibrio es relevante para identificar
estaciones potencialmente sensibles a problemas de disponibilidad.
*/

/*
========================================================
8.2 NOMBRES DE LAS ESTACIONES CON MAYOR DESEQUILIBRIO
========================================================
*/

;WITH nombres AS (
    SELECT
        station_unlock AS station_id,
        unlock_station_name AS station_name,
        COUNT(*) AS frecuencia
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
      AND unlock_station_name IS NOT NULL
    GROUP BY
        station_unlock,
        unlock_station_name
),

ranking AS (
    SELECT
        station_id,
        station_name,
        frecuencia,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY frecuencia DESC
        ) AS rn
    FROM nombres
)

SELECT
    station_id,
    station_name
FROM ranking
WHERE rn = 1
  AND station_id IN (
      '28','144','29','102','200',
      '233','85','224','132'
  )
ORDER BY station_id;

/*
========================================================
CONCLUSIONES SOBRE DESEQUILIBRIO ENTRE ESTACIONES
========================================================

Tras filtrar estaciones con al menos 1.000 movimientos anuales,
se identifican varios puntos con desequilibrios relevantes.

ESTACIONES QUE TIENDEN A PERDER BICICLETAS
(más salidas que llegadas):

- 25a - Plaza de Celenque A
  station_id 28
  desequilibrio: -11,89%

- 148 - Serrano 210
  station_id 144
  desequilibrio: -7,81%

- 25b - Plaza de Celenque B
  station_id 29
  desequilibrio: -7,56%

- 97 - Alcalá
  station_id 102
  desequilibrio: -7,17%

- 192 - Avenida de los Toreros
  station_id 200
  desequilibrio: -6,93%


ESTACIONES QUE TIENDEN A ACUMULAR BICICLETAS
(más llegadas que salidas):

- 225 - Doctor Lozano
  station_id 233
  desequilibrio: +6,88%

- 80b - Atocha B
  station_id 85
  desequilibrio: +5,55%

- 216 - Puerta del Ángel
  station_id 224
  desequilibrio: +5,50%

- 161 - Paseo de la Florida
  station_id 132
  desequilibrio: +5,37%


INTERPRETACIÓN:

Las estaciones con balance negativo pueden presentar mayor riesgo
de quedarse sin bicicletas si no existe reposición suficiente.

Las estaciones con balance positivo pueden tender a acumular bicicletas,
lo que podría aumentar el riesgo de saturación de anclajes.

Estos resultados son especialmente relevantes para una futura
comparación con los datos de estado de estaciones y disponibilidad
de bicicletas/anclajes.
*/

/*
========================================================
9. DISTRIBUCIÓN DE LA DURACIÓN DE LOS VIAJES
========================================================
*/

SELECT DISTINCT
    MIN(trip_minutes) OVER () AS duracion_minima,

    CAST(
        AVG(trip_minutes) OVER ()
        AS decimal(10,2)
    ) AS duracion_media,

    CAST(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY trip_minutes)
        OVER ()
        AS decimal(10,2)
    ) AS mediana,

    CAST(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY trip_minutes)
        OVER ()
        AS decimal(10,2)
    ) AS percentil_90,

    CAST(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY trip_minutes)
        OVER ()
        AS decimal(10,2)
    ) AS percentil_95,

    MAX(trip_minutes) OVER () AS duracion_maxima

FROM dbo.trips_2022;

/*
RESULTADO:

- Duración mínima:   -8.677,33 minutos
- Duración media:        22,51 minutos
- Mediana:               10,75 minutos
- Percentil 90:          23,70 minutos
- Percentil 95:          30,10 minutos
- Duración máxima:   41.795,60 minutos

OBSERVACIÓN:

La distribución de la duración está fuertemente sesgada.

La mediana (10,75 minutos) es muy inferior a la media
(22,51 minutos), lo que indica que un pequeño número de
duraciones extremadamente elevadas aumenta considerablemente
la media.

El 90% de los viajes dura como máximo 23,70 minutos y
el 95% no supera los 30,10 minutos.

También existen duraciones negativas y valores extremadamente
elevados que deben tratarse como anomalías antes de interpretar
los extremos de la distribución.

Por ello, la mediana y los percentiles son métricas más
representativas que la media para describir la duración
típica de los viajes.
*/

/*
========================================================
9.1 CUANTIFICACIÓN DE DURACIONES ATÍPICAS
========================================================
*/

SELECT
    COUNT(*) AS total_viajes,

    SUM(
        CASE WHEN trip_minutes < 0
        THEN 1 ELSE 0 END
    ) AS duraciones_negativas,

    SUM(
        CASE WHEN trip_minutes > 1440
        THEN 1 ELSE 0 END
    ) AS viajes_mas_24h,

    SUM(
        CASE WHEN trip_minutes BETWEEN 0 AND 1440
        THEN 1 ELSE 0 END
    ) AS viajes_entre_0_y_24h

FROM dbo.trips_2022;

/*
RESULTADO:

- Total de viajes:               4.143.941
- Duraciones negativas:             1.606
- Viajes superiores a 24 horas:    14.773
- Viajes entre 0 y 24 horas:    4.127.562

OBSERVACIÓN:

Las duraciones negativas representan una proporción muy pequeña
del total anual.

Los viajes superiores a 24 horas también son poco frecuentes,
aunque su duración extrema puede distorsionar métricas como
la media.

Por tanto, para describir la duración típica de los viajes
se utilizarán métricas robustas como la mediana y los percentiles.

No se eliminarán todavía los viajes superiores a 24 horas,
ya que podrían corresponder a casos excepcionales reales o a
problemas de registro que conviene estudiar por separado.
*/

/*
========================================================
9.2 DURACIÓN DE VIAJES DENTRO DE UN RANGO PLAUSIBLE
========================================================
*/

SELECT DISTINCT
    CAST(
        AVG(trip_minutes) OVER ()
        AS decimal(10,2)
    ) AS media_0_24h,

    CAST(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY trip_minutes)
        OVER ()
        AS decimal(10,2)
    ) AS mediana_0_24h,

    CAST(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY trip_minutes)
        OVER ()
        AS decimal(10,2)
    ) AS p90_0_24h,

    CAST(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY trip_minutes)
        OVER ()
        AS decimal(10,2)
    ) AS p95_0_24h

FROM dbo.trips_2022
WHERE trip_minutes BETWEEN 0 AND 1440;

/*
RESULTADO:

Para los viajes con duración entre 0 y 24 horas:

- Duración media:   12,17 minutos
- Mediana:          10,72 minutos
- Percentil 90:     23,45 minutos
- Percentil 95:     29,38 minutos

COMPARACIÓN:

Al excluir duraciones negativas y viajes superiores a 24 horas,
la media disminuye de 22,51 a 12,17 minutos.

Sin embargo, la mediana y los percentiles apenas cambian.

OBSERVACIÓN:

Esto confirma que los valores extremos afectan fuertemente
a la media, pero tienen un impacto muy reducido sobre métricas
robustas como la mediana y los percentiles.

Por tanto, para describir la duración típica de los viajes,
se utilizará principalmente la mediana y, como referencia
complementaria, la media restringida al rango 0-24 horas.
*/

/*
========================================================
10. DURACIÓN MEDIA Y MEDIANA POR DÍA DE LA SEMANA
========================================================
*/

;WITH base AS (
    SELECT
        fecha,
        trip_minutes,

        CASE ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)
            WHEN 1 THEN 'Lunes'
            WHEN 2 THEN 'Martes'
            WHEN 3 THEN 'Miércoles'
            WHEN 4 THEN 'Jueves'
            WHEN 5 THEN 'Viernes'
            WHEN 6 THEN 'Sábado'
            WHEN 7 THEN 'Domingo'
        END AS dia_semana,

        ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1) AS orden_dia

    FROM dbo.trips_2022
    WHERE trip_minutes BETWEEN 0 AND 1440
),

estadisticas AS (
    SELECT
        dia_semana,
        orden_dia,

        CAST(
            AVG(trip_minutes) OVER (PARTITION BY dia_semana)
            AS decimal(10,2)
        ) AS duracion_media,

        CAST(
            PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY trip_minutes)
            OVER (PARTITION BY dia_semana)
            AS decimal(10,2)
        ) AS mediana

    FROM base
)

SELECT DISTINCT
    orden_dia,
    dia_semana,
    duracion_media,
    mediana
FROM estadisticas
ORDER BY orden_dia;

/*
RESULTADO:

Duración por día de la semana:

- Lunes:     media 11,89 min | mediana 10,52 min
- Martes:    media 11,99 min | mediana 10,65 min
- Miércoles: media 12,06 min | mediana 10,73 min
- Jueves:    media 12,07 min | mediana 10,75 min
- Viernes:   media 12,23 min | mediana 10,83 min
- Sábado:    media 12,48 min | mediana 10,73 min
- Domingo:   media 12,67 min | mediana 10,78 min

OBSERVACIÓN:

La duración típica de los viajes es bastante estable durante
toda la semana, con medianas próximas a 11 minutos.

Sin embargo, la duración media aumenta progresivamente hacia
el fin de semana, alcanzando su máximo el domingo.

La mayor diferencia en la media frente a la mediana sugiere
que durante el fin de semana existe una mayor presencia de
viajes relativamente largos.

Esto es compatible con un uso más recreativo o menos ligado
a desplazamientos rutinarios durante sábados y domingos.
*/

/*
========================================================
10.1 DURACIÓN: LABORABLES VS FIN DE SEMANA
========================================================
*/

;WITH base AS (
    SELECT
        trip_minutes,

        CASE
            WHEN ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)
                 BETWEEN 1 AND 5
            THEN 'Laborable'
            ELSE 'Fin de semana'
        END AS tipo_dia

    FROM dbo.trips_2022
    WHERE trip_minutes BETWEEN 0 AND 1440
),

estadisticas AS (
    SELECT
        tipo_dia,

        CAST(
            AVG(trip_minutes) OVER (PARTITION BY tipo_dia)
            AS decimal(10,2)
        ) AS media,

        CAST(
            PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY trip_minutes)
            OVER (PARTITION BY tipo_dia)
            AS decimal(10,2)
        ) AS mediana

    FROM base
)

SELECT DISTINCT
    tipo_dia,
    media,
    mediana
FROM estadisticas
ORDER BY tipo_dia;

/*
RESULTADO:

Comparación de duración entre laborables y fin de semana:

- Laborables:
    media   -> 12,05 minutos
    mediana -> 10,70 minutos

- Fin de semana:
    media   -> 12,57 minutos
    mediana -> 10,77 minutos

OBSERVACIÓN:

La duración típica de los viajes cambia muy poco entre
laborables y fines de semana, ya que las medianas son
prácticamente idénticas.

Sin embargo, la media es algo superior durante el fin
de semana.

Esto sugiere que sábados y domingos existe una mayor
proporción de viajes relativamente largos, aunque el
comportamiento central de la distribución se mantiene estable.
*/

/*
========================================================
11. RUTAS MÁS FRECUENTES
========================================================
*/

SELECT TOP 20
    station_unlock,
    unlock_station_name,
    station_lock,
    lock_station_name,
    COUNT(*) AS total_viajes
FROM dbo.trips_2022
WHERE station_unlock IS NOT NULL
  AND station_lock IS NOT NULL
GROUP BY
    station_unlock,
    unlock_station_name,
    station_lock,
    lock_station_name
ORDER BY total_viajes DESC;

/*
RESULTADO:

El ranking inicial de rutas está dominado por viajes en los que
la estación de origen y la estación de destino son la misma.

Ejemplos:
- Segovia 45 -> Segovia 45: 8.555 viajes
- Plaza de Lavapiés -> Plaza de Lavapiés: 6.922 viajes
- Marqués de Vadillo -> Marqués de Vadillo: 6.511 viajes
- Plaza de la Cebada -> Plaza de la Cebada: 6.382 viajes

OBSERVACIÓN:

Estos viajes pueden representar recorridos circulares,
uso recreativo o desplazamientos que terminan en el mismo
punto de partida.

Para identificar los principales corredores de movilidad
entre estaciones distintas, se excluirán los viajes cuyo
origen y destino coinciden.
*/

/*
========================================================
11.1 RUTAS MÁS FRECUENTES ENTRE ESTACIONES DISTINTAS
========================================================
*/

SELECT TOP 20
    station_unlock,
    unlock_station_name,
    station_lock,
    lock_station_name,
    COUNT(*) AS total_viajes
FROM dbo.trips_2022
WHERE station_unlock IS NOT NULL
  AND station_lock IS NOT NULL
  AND station_unlock <> station_lock
GROUP BY
    station_unlock,
    unlock_station_name,
    station_lock,
    lock_station_name
ORDER BY total_viajes DESC;

/*
RESULTADO:

Al excluir los viajes cuyo origen y destino coinciden,
aparecen corredores frecuentes entre estaciones distintas.

Principales rutas:

- Plaza de la Cebada -> Marqués de Vadillo: 1.193 viajes
- Marqués de Vadillo -> Plaza de la Cebada: 1.172 viajes

- Puente Praga -> Paseo de la Esperanza: 1.086 viajes

- Marqués de Vadillo -> Paseo de la Florida: 1.011 viajes
- Paseo de la Florida -> Marqués de Vadillo: 1.007 viajes

- Ermita Santo -> Paseo de la Florida: 914 viajes
- Paseo de la Florida -> Ermita Santo: 867 viajes

- Plaza de la Independencia -> Puerta del Pacífico: 859 viajes
- Puerta del Pacífico -> Plaza de la Independencia: 776 viajes

OBSERVACIÓN:

Varias de las rutas más frecuentes presentan volúmenes elevados
en ambos sentidos, lo que indica corredores de movilidad
relativamente equilibrados entre pares concretos de estaciones.

Marqués de Vadillo aparece repetidamente entre las rutas
más frecuentes, reforzando su importancia dentro de la red.
*/

/*
========================================================
11.2 VIAJES CON MISMA ESTACIÓN DE ORIGEN Y DESTINO
========================================================
*/

SELECT
    COUNT(*) AS total_viajes_validos,

    SUM(
        CASE
            WHEN station_unlock = station_lock
            THEN 1 ELSE 0
        END
    ) AS viajes_misma_estacion,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN station_unlock = station_lock
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS decimal(10,2)
    ) AS porcentaje_misma_estacion

FROM dbo.trips_2022

WHERE station_unlock IS NOT NULL
  AND station_lock IS NOT NULL;

  /*
RESULTADO:

- Viajes con estaciones de origen y destino válidas: 4.120.837
- Viajes que terminan en la misma estación de origen: 755.188
- Porcentaje de viajes circulares: 18,33%

OBSERVACIÓN:

Los viajes que empiezan y terminan en la misma estación
representan una proporción relevante del sistema.

Aproximadamente 1 de cada 5 viajes con estaciones válidas
es un viaje circular.

Este comportamiento puede estar asociado a usos recreativos,
recorridos de ida y vuelta o desplazamientos en los que el
usuario regresa al punto de partida.

Por tanto, estos viajes deben analizarse por separado de los
corredores entre estaciones distintas.
*/

/*
========================================================
11.3 DURACIÓN: VIAJES CIRCULARES VS NO CIRCULARES
========================================================
*/

;WITH base AS (
    SELECT
        trip_minutes,

        CASE
            WHEN station_unlock = station_lock
            THEN 'Circular'
            ELSE 'No circular'
        END AS tipo_viaje

    FROM dbo.trips_2022

    WHERE station_unlock IS NOT NULL
      AND station_lock IS NOT NULL
      AND trip_minutes BETWEEN 0 AND 1440
),

estadisticas AS (
    SELECT
        tipo_viaje,

        CAST(
            AVG(trip_minutes) OVER (PARTITION BY tipo_viaje)
            AS decimal(10,2)
        ) AS media,

        CAST(
            PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY trip_minutes)
            OVER (PARTITION BY tipo_viaje)
            AS decimal(10,2)
        ) AS mediana

    FROM base
)

SELECT DISTINCT
    tipo_viaje,
    media,
    mediana
FROM estadisticas
ORDER BY tipo_viaje;

/*
RESULTADO:

- Viajes circulares:
    media   -> 4,05 minutos
    mediana -> 0,35 minutos

- Viajes no circulares:
    media   -> 13,98 minutos
    mediana -> 12,13 minutos

OBSERVACIÓN:

Los viajes circulares presentan una duración muy inferior
a los viajes entre estaciones distintas.

La mediana de los viajes circulares es de solo 0,35 minutos,
aproximadamente 21 segundos.

Este resultado contradice la hipótesis inicial de que la mayoría
de estos registros pudiera corresponder a recorridos recreativos.

La duración extremadamente corta sugiere que una parte importante
podría estar relacionada con devoluciones inmediatas, intentos
de desbloqueo, cambios de bicicleta u otras operaciones breves.

Por tanto, los viajes circulares deben analizarse con mayor detalle
antes de interpretarlos como desplazamientos reales.
*/

/*
========================================================
11.4 DURACIÓN DE LOS VIAJES CIRCULARES
========================================================
*/

SELECT
    COUNT(*) AS total_circulares,

    SUM(CASE WHEN trip_minutes < 1 THEN 1 ELSE 0 END)
        AS menos_1_min,

    SUM(CASE WHEN trip_minutes < 2 THEN 1 ELSE 0 END)
        AS menos_2_min,

    SUM(CASE WHEN trip_minutes < 5 THEN 1 ELSE 0 END)
        AS menos_5_min

FROM dbo.trips_2022

WHERE station_unlock IS NOT NULL
  AND station_lock IS NOT NULL
  AND station_unlock = station_lock
  AND trip_minutes BETWEEN 0 AND 1440;

  /*
RESULTADO:

Viajes circulares analizados: 749.978

- Menos de 1 minuto: 562.859
- Menos de 2 minutos: 622.638
- Menos de 5 minutos: 650.905

OBSERVACIÓN:

La gran mayoría de los viajes circulares presenta una duración
extremadamente reducida.

Este patrón refuerza la hipótesis de que muchos registros
circulares no representan desplazamientos reales, sino eventos
como:

- devoluciones inmediatas,
- intentos de desbloqueo,
- cambios de bicicleta,
- incidencias operativas o registros muy breves.

Por tanto, los viajes circulares deben tratarse con cautela
en los análisis de movilidad y rutas.
*/

/*
========================================================
11.5 PESO DE LOS VIAJES CIRCULARES MUY BREVES
========================================================
*/

SELECT
    COUNT(*) AS total_viajes,

    SUM(
        CASE
            WHEN station_unlock IS NOT NULL
             AND station_lock IS NOT NULL
             AND station_unlock = station_lock
             AND trip_minutes >= 0
             AND trip_minutes < 1
            THEN 1 ELSE 0
        END
    ) AS circulares_menos_1_min,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN station_unlock IS NOT NULL
                 AND station_lock IS NOT NULL
                 AND station_unlock = station_lock
                 AND trip_minutes >= 0
                 AND trip_minutes < 1
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS decimal(10,2)
    ) AS porcentaje_total

FROM dbo.trips_2022;

/*
RESULTADO:

- Total anual de viajes: 4.143.941
- Viajes circulares de menos de 1 minuto: 562.859
- Peso sobre el total anual: 13,58%

OBSERVACIÓN:

Más de uno de cada ocho registros del año corresponde a viajes
que empiezan y terminan en la misma estación y duran menos de
un minuto.

Este volumen es suficientemente elevado como para afectar
significativamente los análisis de movilidad, duración y rutas.

DECISIÓN:

No se eliminarán estos registros de la tabla original.

En su lugar, se recomienda crear una bandera analítica que permita
identificar estos eventos y excluirlos de determinados análisis
cuando el objetivo sea estudiar desplazamientos reales.
*/

/*
========================================================
12. CREACIÓN DE BANDERA PARA VIAJES CIRCULARES MUY BREVES
========================================================
*/

ALTER TABLE dbo.trips_2022
ADD es_viaje_breve_circular bit;

UPDATE dbo.trips_2022
SET es_viaje_breve_circular =
    CASE
        WHEN station_unlock IS NOT NULL
         AND station_lock IS NOT NULL
         AND station_unlock = station_lock
         AND trip_minutes >= 0
         AND trip_minutes < 1
        THEN 1
        ELSE 0
    END;

    SELECT
    es_viaje_breve_circular,
    COUNT(*) AS total
FROM dbo.trips_2022
GROUP BY es_viaje_breve_circular
ORDER BY es_viaje_breve_circular;

/*
RESULTADO:

Se creó la variable es_viaje_breve_circular para identificar
registros que cumplen simultáneamente:

- misma estación de origen y destino
- duración igual o superior a 0 minutos
- duración inferior a 1 minuto

Distribución:

- es_viaje_breve_circular = 1 -> 562.859 registros
- es_viaje_breve_circular = 0 -> 3.581.082 registros

DECISIÓN:

La bandera permitirá excluir estos registros en análisis de
movilidad real sin eliminar información de la tabla original.
*/

/*
========================================================
13. VOLUMEN MENSUAL EXCLUYENDO VIAJES BREVES CIRCULARES
========================================================
*/

SELECT
    mes,
    COUNT(*) AS total_viajes_filtrados
FROM dbo.trips_2022
WHERE es_viaje_breve_circular = 0
GROUP BY mes
ORDER BY mes;

/*
RESULTADO:

Volumen mensual excluyendo viajes breves circulares:

- Enero:      205.544
- Febrero:    248.177
- Marzo:      243.947
- Abril:      248.430
- Mayo:       434.084
- Junio:      398.469
- Julio:      343.056
- Agosto:     237.892
- Septiembre: 382.173
- Octubre:    366.509
- Noviembre:  286.161
- Diciembre:  186.640

REDUCCIÓN RESPECTO AL TOTAL ORIGINAL:

- Enero:      -16,02%
- Febrero:    -11,48%
- Marzo:      -11,99%
- Abril:      -10,91%
- Mayo:        -9,17%
- Junio:       -8,27%
- Julio:      -12,00%
- Agosto:     -13,41%
- Septiembre: -14,54%
- Octubre:    -15,50%
- Noviembre:  -20,15%
- Diciembre:  -24,30%

OBSERVACIÓN:

La proporción de viajes circulares muy breves varía de forma
importante a lo largo del año.

El peso de estos registros aumenta especialmente durante
los últimos meses del año, con máximos en noviembre y diciembre.

Esto sugiere que dichos eventos no están distribuidos
uniformemente y podrían estar relacionados con cambios
operativos, incidencias o patrones de uso específicos.
*/

SELECT
    mes,
    COUNT(*) AS total_viajes_filtrados,
    RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS ranking_demanda
FROM dbo.trips_2022
WHERE es_viaje_breve_circular = 0
GROUP BY mes
ORDER BY ranking_demanda;

/*
RESULTADO:

Ranking mensual tras excluir viajes breves circulares:

1. Mayo        -> 434.084
2. Junio       -> 398.469
3. Septiembre  -> 382.173
4. Octubre     -> 366.509
5. Julio       -> 343.056
6. Noviembre   -> 286.161
7. Abril       -> 248.430
8. Febrero     -> 248.177
9. Marzo       -> 243.947
10. Agosto     -> 237.892
11. Enero      -> 205.544
12. Diciembre  -> 186.640

OBSERVACIÓN:

El patrón estacional general se mantiene tras excluir
los viajes breves circulares.

Mayo continúa siendo el mes con mayor demanda y diciembre
el de menor actividad.

Sin embargo, algunos meses cambian de posición relativa,
lo que confirma que la presencia de eventos breves circulares
afectaba de forma desigual al volumen mensual.
*/

/*
========================================================
14. VOLUMEN POR HORA EXCLUYENDO VIAJES BREVES CIRCULARES
========================================================
*/

SELECT
    DATEPART(HOUR, unlock_date) AS hora,
    COUNT(*) AS total_viajes_filtrados
FROM dbo.trips_2022
WHERE es_viaje_breve_circular = 0
GROUP BY DATEPART(HOUR, unlock_date)
ORDER BY hora;

/*
RESULTADO:

Tras excluir los viajes circulares de menos de 1 minuto,
el patrón horario general se mantiene.

Principales horas de demanda:

- 19:00 -> 284.868 viajes
- 18:00 -> 273.950 viajes
- 20:00 -> 252.930 viajes
- 14:00 -> 249.219 viajes
- 08:00 -> 216.488 viajes

OBSERVACIÓN:

La eliminación analítica de los viajes breves circulares
reduce el volumen absoluto, pero no modifica de forma
sustancial la estructura horaria de la demanda.

Se mantienen:

1. Un pico matinal alrededor de las 08:00.
2. Un aumento importante alrededor de las 14:00.
3. El principal periodo de demanda entre las 18:00 y las 20:00,
   con máximo a las 19:00.

Esto refuerza la conclusión de que dichos picos representan
patrones reales de movilidad y no son consecuencia de los
eventos circulares muy breves.
*/

/*
========================================================
14.1 PATRÓN HORARIO FILTRADO:
LABORABLES VS FIN DE SEMANA
========================================================
*/

;WITH viajes_diarios AS (
    SELECT
        fecha,
        DATEPART(HOUR, unlock_date) AS hora,

        CASE
            WHEN ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)
                 BETWEEN 1 AND 5
            THEN 'Laborable'
            ELSE 'Fin de semana'
        END AS tipo_dia,

        COUNT(*) AS viajes

    FROM dbo.trips_2022

    WHERE es_viaje_breve_circular = 0

    GROUP BY
        fecha,
        DATEPART(HOUR, unlock_date),
        CASE
            WHEN ((DATEDIFF(DAY, '19000101', fecha) % 7) + 1)
                 BETWEEN 1 AND 5
            THEN 'Laborable'
            ELSE 'Fin de semana'
        END
)

SELECT
    hora,
    tipo_dia,
    CAST(
        AVG(CAST(viajes AS decimal(10,2)))
        AS decimal(10,2)
    ) AS promedio_viajes_dia

FROM viajes_diarios

GROUP BY
    hora,
    tipo_dia

ORDER BY
    hora,
    tipo_dia;

    /*
RESULTADO:

Tras excluir los viajes circulares de menos de 1 minuto,
se mantienen diferencias claras entre días laborables
y fines de semana.

DÍAS LABORABLES:

- Pico matinal:
    08:00 -> 783,08 viajes/día

- Principal periodo de demanda:
    18:00 -> 856,14 viajes/día
    19:00 -> 883,70 viajes/día
    20:00 -> 764,83 viajes/día

- La hora de máxima demanda sigue siendo las 19:00.


FIN DE SEMANA:

- No aparece el pico matinal de las 08:00.
- La demanda aumenta progresivamente desde media mañana.
- Se mantiene relativamente estable durante la tarde.
- Máximo aproximado:
    13:00 -> 525,77 viajes/día
    19:00 -> 524,83 viajes/día
    20:00 -> 514,98 viajes/día

- Durante la madrugada el uso es claramente superior
  al registrado en los días laborables.


CONCLUSIÓN:

La exclusión de los viajes breves circulares reduce los
volúmenes, pero no altera las conclusiones principales
del patrón temporal.

Los días laborables presentan una estructura compatible
con desplazamientos recurrentes asociados a horarios
de trabajo o estudios.

Los fines de semana presentan un patrón más uniforme,
con mayor peso relativo de las horas centrales, tarde
y madrugada.

Por tanto, el patrón temporal observado puede considerarse
robusto frente al filtrado de eventos breves circulares.
*/

/*
========================================================
15. TOP 10 ESTACIONES DE ORIGEN
EXCLUYENDO VIAJES BREVES CIRCULARES
========================================================
*/

SELECT TOP 10
    station_unlock,
    unlock_station_name,
    COUNT(*) AS total_salidas_filtradas
FROM dbo.trips_2022
WHERE station_unlock IS NOT NULL
  AND es_viaje_breve_circular = 0
GROUP BY
    station_unlock,
    unlock_station_name
ORDER BY total_salidas_filtradas DESC;

/*
RESULTADO:

Tras excluir los viajes circulares de menos de 1 minuto,
las estaciones con mayor número de salidas siguen siendo
prácticamente las mismas.

Top 10 estaciones de origen filtradas:

1. Plaza de la Cebada         -> 36.130
2. Plaza de Lavapiés          -> 34.152
3. Marqués de Vadillo         -> 28.601
4. Segovia 45                 -> 28.189
5. Quevedo                    -> 27.579
6. Puerta de Madrid           -> 26.348
7. Antón Martín               -> 25.025
8. Puerta de Toledo           -> 24.323
9. Paseo de la Florida        -> 23.486
10. Plaza de la Independencia -> 23.193

OBSERVACIÓN:

La exclusión de eventos breves circulares reduce los
volúmenes absolutos, pero no altera de forma sustancial
el ranking de las estaciones con mayor demanda de origen.

Esto indica que la concentración de actividad en estas
estaciones es un patrón estructural del sistema.
*/

/*
========================================================
15.1 TOP 10 ESTACIONES DE DESTINO
EXCLUYENDO VIAJES BREVES CIRCULARES
========================================================
*/

SELECT TOP 10
    station_lock,
    lock_station_name,
    COUNT(*) AS total_llegadas_filtradas
FROM dbo.trips_2022
WHERE station_lock IS NOT NULL
  AND es_viaje_breve_circular = 0
GROUP BY
    station_lock,
    lock_station_name
ORDER BY total_llegadas_filtradas DESC;

/*
RESULTADO:

Tras excluir los viajes circulares de menos de 1 minuto,
las estaciones con mayor número de llegadas siguen siendo
prácticamente las mismas.

Top 10 estaciones de destino filtradas:

1. Plaza de la Cebada        -> 36.506
2. Plaza de Lavapiés         -> 33.450
3. Marqués de Vadillo        -> 31.557
4. Segovia 45                -> 28.738
5. Quevedo                   -> 28.071
6. Paseo de la Florida       -> 26.651
7. Puerta del Ángel          -> 25.639
8. Antón Martín              -> 25.414
9. Puerta de Madrid          -> 25.334
10. Puerta de Toledo         -> 24.850

OBSERVACIÓN:

La exclusión de viajes breves circulares reduce los
volúmenes absolutos, pero mantiene la estructura principal
del ranking de destinos.

Plaza de la Cebada, Plaza de Lavapiés y Marqués de Vadillo
siguen destacando como nodos de alta actividad.

Esto confirma que su importancia dentro de la red no depende
de los eventos circulares muy breves.
*/

/*
========================================================
15.2 BALANCE NETO FILTRADO POR ESTACIÓN
========================================================
*/

;WITH nombres AS (
    SELECT
        station_unlock AS station_id,
        unlock_station_name AS station_name,
        COUNT(*) AS frecuencia
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
      AND unlock_station_name IS NOT NULL
      AND es_viaje_breve_circular = 0
    GROUP BY
        station_unlock,
        unlock_station_name
),

ranking_nombres AS (
    SELECT
        station_id,
        station_name,
        frecuencia,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY frecuencia DESC
        ) AS rn
    FROM nombres
),

nombre_principal AS (
    SELECT
        station_id,
        station_name
    FROM ranking_nombres
    WHERE rn = 1
),

salidas AS (
    SELECT
        station_unlock AS station_id,
        COUNT(*) AS total_salidas
    FROM dbo.trips_2022
    WHERE station_unlock IS NOT NULL
      AND es_viaje_breve_circular = 0
    GROUP BY station_unlock
),

llegadas AS (
    SELECT
        station_lock AS station_id,
        COUNT(*) AS total_llegadas
    FROM dbo.trips_2022
    WHERE station_lock IS NOT NULL
      AND es_viaje_breve_circular = 0
    GROUP BY station_lock
)

SELECT TOP 20
    COALESCE(s.station_id, l.station_id) AS station_id,
    np.station_name,
    ISNULL(s.total_salidas, 0) AS total_salidas,
    ISNULL(l.total_llegadas, 0) AS total_llegadas,
    ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0) AS balance_neto
FROM salidas s
FULL OUTER JOIN llegadas l
    ON s.station_id = l.station_id
LEFT JOIN nombre_principal np
    ON np.station_id = COALESCE(s.station_id, l.station_id)
ORDER BY ABS(
    ISNULL(l.total_llegadas, 0) - ISNULL(s.total_salidas, 0)
) DESC;

/*
RESULTADO:

Tras excluir los viajes circulares de menos de 1 minuto,
los principales balances netos por estación permanecen
exactamente iguales.

Ejemplos:

BALANCE POSITIVO:
- Paseo de la Florida      -> +3.480
- Marqués de Vadillo       -> +3.413
- Puerta del Ángel         -> +3.400

BALANCE NEGATIVO:
- Paseo de la Castellana con Raimundo Fernández -> -2.268
- Avenida de los Toreros                          -> -1.942
- Alcalá                                         -> -1.691

OBSERVACIÓN:

Los viajes circulares comienzan y terminan en la misma estación.

Por tanto, cada viaje circular aporta simultáneamente:

+1 salida
+1 llegada

Al excluir estos registros disminuyen tanto las salidas como
las llegadas de la estación en la misma cantidad.

Como consecuencia, el balance neto:

    llegadas - salidas

permanece inalterado.

CONCLUSIÓN:

Los desequilibrios netos detectados anteriormente son robustos
frente a la exclusión de los viajes circulares muy breves.
*/