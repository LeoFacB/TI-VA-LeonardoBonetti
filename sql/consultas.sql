-- Consultas de BI sobre a base leonardobonetti (MovieLens 1M)
-- Podem ser usadas no SQL Lab do Superset ou como datasets virtuais.
--
-- Cada linha "-- @dataset: nome | titulo" marca uma consulta que o servico
-- superset-init cadastra automaticamente como dataset virtual e Saved Query.
--
-- Tabelas e colunas:
--   usuario(idUsuario, sexo, faixaEtaria, codOcupacao, codigoPostal)
--   filme(idFilme, titulo)
--   avaliacao(idUsuario, idFilme, nota, dataHora)   -- dataHora e DATETIME
--   genero(nomeGenero)
--   filme_genero(idFilme, nomeGenero)

USE leonardobonetti;

-- ---------------------------------------------------------------------------
-- @dataset: kpis_gerais | KPIs gerais
-- 1. KPIs: totais de avaliacoes, usuarios e filmes
-- ---------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM avaliacao)                AS total_avaliacoes,
    (SELECT COUNT(*) FROM usuario)                  AS total_usuarios,
    (SELECT COUNT(*) FROM filme)                    AS total_filmes,
    (SELECT ROUND(AVG(nota), 2) FROM avaliacao)     AS nota_media_geral;

-- ---------------------------------------------------------------------------
-- @dataset: nota_por_genero | Nota media por genero
-- 2. Nota media por genero
-- ---------------------------------------------------------------------------
SELECT
    fg.nomeGenero                AS genero,
    COUNT(*)                     AS qtd_avaliacoes,
    ROUND(AVG(a.nota), 2)        AS nota_media
FROM avaliacao a
JOIN filme_genero fg ON fg.idFilme = a.idFilme
GROUP BY fg.nomeGenero
ORDER BY nota_media DESC;

-- ---------------------------------------------------------------------------
-- @dataset: avaliacoes_por_mes | Avaliacoes por mes
-- 3. Avaliacoes por mes
--    (dataHora ja e DATETIME; mes = 1o dia do mes, para graficos de serie temporal)
-- ---------------------------------------------------------------------------
SELECT
    DATE(DATE_FORMAT(a.dataHora, '%Y-%m-01'))  AS mes,
    COUNT(*)                                   AS qtd_avaliacoes,
    ROUND(AVG(a.nota), 2)                      AS nota_media
FROM avaliacao a
GROUP BY mes
ORDER BY mes;

-- ---------------------------------------------------------------------------
-- @dataset: avaliacoes_por_faixa_etaria | Avaliacoes por faixa etaria
-- 4. Avaliacoes por faixa etaria
--    faixaEtaria guarda o codigo do MovieLens (1, 18, 25, 35, 45, 50, 56)
-- ---------------------------------------------------------------------------
SELECT
    u.faixaEtaria AS cod_faixa,
    CASE u.faixaEtaria
        WHEN 1  THEN 'Menos de 18'
        WHEN 18 THEN '18-24'
        WHEN 25 THEN '25-34'
        WHEN 35 THEN '35-44'
        WHEN 45 THEN '45-49'
        WHEN 50 THEN '50-55'
        WHEN 56 THEN '56+'
    END                           AS faixa_etaria,
    COUNT(*)                      AS qtd_avaliacoes,
    COUNT(DISTINCT u.idUsuario)   AS qtd_usuarios,
    ROUND(AVG(a.nota), 2)         AS nota_media
FROM avaliacao a
JOIN usuario u ON u.idUsuario = a.idUsuario
GROUP BY u.faixaEtaria
ORDER BY u.faixaEtaria;

-- ---------------------------------------------------------------------------
-- @dataset: avaliacoes_por_sexo | Avaliacoes por sexo
-- 5. Avaliacoes por sexo
-- ---------------------------------------------------------------------------
SELECT
    CASE u.sexo WHEN 'F' THEN 'Feminino' WHEN 'M' THEN 'Masculino' END AS sexo,
    COUNT(*)                      AS qtd_avaliacoes,
    COUNT(DISTINCT u.idUsuario)   AS qtd_usuarios,
    ROUND(AVG(a.nota), 2)         AS nota_media
FROM avaliacao a
JOIN usuario u ON u.idUsuario = a.idUsuario
GROUP BY u.sexo
ORDER BY qtd_avaliacoes DESC;

-- ---------------------------------------------------------------------------
-- @dataset: top10_filmes | Top 10 filmes (mais de 100 avaliacoes)
-- 6. Top 10 filmes por nota media (com mais de 100 avaliacoes)
-- ---------------------------------------------------------------------------
SELECT
    f.titulo,
    COUNT(*)                 AS qtd_avaliacoes,
    ROUND(AVG(a.nota), 2)    AS nota_media
FROM avaliacao a
JOIN filme f ON f.idFilme = a.idFilme
GROUP BY f.idFilme, f.titulo
HAVING COUNT(*) > 100
ORDER BY nota_media DESC, qtd_avaliacoes DESC
LIMIT 10;
