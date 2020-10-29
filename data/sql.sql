WITH criterios AS (
    SELECT 'P' AS orc_ped, 
    (SELECT cia_ativa FROM parametros AS cia) AS cia, 
    CAST('2020-09-10' AS DATE) AS data, 
    60 AS dias_data_ped,
    10 AS fase, 
    3000 AS meta_diaria_fase_m2 FROM rdb$database
),
turnos_cte AS (
    SELECT cod, hora_inicial, hora_final, turnos FROM turnos WHERE CAST(hora_final AS TIME) > CAST(hora_inicial AS TIME)
    UNION
    SELECT cod, hora_inicial, CAST('23:59:59' AS TIME) AS hora_final, turnos FROM turnos WHERE CAST(hora_final AS TIME) < CAST(hora_inicial AS TIME)
    UNION
    SELECT cod, CAST('00:00:00' AS TIME) AS hora_inicial, hora_final, turnos FROM turnos WHERE CAST(hora_final AS TIME) < CAST(hora_inicial AS TIME)    
),
producao AS (
    SELECT PROD.fase, FP.fase AS descr_fase, PROD.turno, T.turnos AS descr_turno, PROD.quantidade, PROD.m2, PROD.m2 / criterios.meta_diaria_fase_m2 * 100 AS perc_meta_m2 FROM (
        SELECT fase, turno, COUNT(*) AS quantidade, SUM(area) AS m2 FROM (
            SELECT OPP.fase, (
                SELECT FIRST 1 T.cod FROM turnos_cte T
                WHERE CAST(OPP.sai_hora AS TIME) BETWEEN CAST(T.hora_inicial AS TIME) AND CAST(T.hora_final AS TIME)
            ) AS turno, OPI.area_tot AS area
            FROM orc_ped_pecas OPP, criterios
            INNER JOIN orc_ped_itens OPI ON OPI.orc_ped = OPP.orc_ped AND OPI.cia = OPP.cia AND OPI.data_ped = OPP.data_ped AND OPI.numero = OPP.numero AND OPI.ordem_dig = OPP.ordem_dig
            WHERE OPP.orc_ped = 'P' AND OPP.cia = (SELECT cia_ativa FROM parametros) AND OPP.data_ped >= criterios.data - criterios.dias_data_ped AND OPP.saida = criterios.data AND OPP.fase = criterios.fase
        )
        GROUP BY 1,2
    ) PROD, criterios
    INNER JOIN fases_prod FP ON FP.seq = PROD.fase
    INNER JOIN turnos T ON T.cod = PROD.turno
),
ocorrencias AS (
    SELECT turno, SUM(m2) AS m2 FROM (
        SELECT (
            SELECT FIRST 1 T.cod FROM turnos_cte T
            WHERE CAST(PO.hora AS TIME) BETWEEN CAST(T.hora_inicial AS TIME) AND CAST(T.hora_final AS TIME)
        ) AS turno, OPI.area_tot AS m2 FROM ppcp_ocorrencias PO, criterios
        INNER JOIN orc_ped_itens OPI ON OPI.orc_ped = PO.orc_ped AND OPI.cia = PO.cia AND OPI.data_ped = PO.data_ped AND OPI.numero = PO.numero AND OPI.ordem_dig = PO.ordem_dig
        WHERE PO.orc_ped = criterios.orc_ped AND PO.cia = criterios.cia AND PO.data_ped >= criterios.data - criterios.dias_data_ped AND PO.data = criterios.data AND PO.fase = criterios.fase
    )
    GROUP BY 1
)
SELECT producao.*, ocorrencias.m2 AS m2_ocorr, COALESCE(ocorrencias.m2, 0) / COALESCE(producao.m2, 1) * 100 AS perc_ocorr FROM producao
LEFT JOIN ocorrencias ON ocorrencias.turno = producao.turno