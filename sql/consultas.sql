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

-- ===========================================================================
-- ANALISES CRUZADAS (misturam duas dimensoes)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- @dataset: genero_x_faixa | Genero x Faixa etaria (heatmap)
-- 7. Nota media por genero e faixa etaria (formato longo, para heatmap)
-- ---------------------------------------------------------------------------
SELECT
    fg.nomeGenero AS genero,
    CASE u.faixaEtaria
        WHEN 1  THEN 'Menos de 18'
        WHEN 18 THEN '18-24'
        WHEN 25 THEN '25-34'
        WHEN 35 THEN '35-44'
        WHEN 45 THEN '45-49'
        WHEN 50 THEN '50-55'
        WHEN 56 THEN '56+'
    END                        AS faixa_etaria,
    u.faixaEtaria              AS cod_faixa,
    COUNT(*)                   AS qtd_avaliacoes,
    ROUND(AVG(a.nota), 2)      AS nota_media
FROM avaliacao a
JOIN usuario u      ON u.idUsuario = a.idUsuario
JOIN filme_genero fg ON fg.idFilme = a.idFilme
GROUP BY fg.nomeGenero, u.faixaEtaria;

-- ---------------------------------------------------------------------------
-- @dataset: genero_x_sexo | Genero x Sexo (diferenca F-M)
-- 8. Nota media por genero separada por sexo e a diferenca (gosto F vs M)
-- ---------------------------------------------------------------------------
SELECT
    fg.nomeGenero AS genero,
    ROUND(AVG(CASE WHEN u.sexo = 'F' THEN a.nota END), 2) AS nota_feminino,
    ROUND(AVG(CASE WHEN u.sexo = 'M' THEN a.nota END), 2) AS nota_masculino,
    ROUND(AVG(CASE WHEN u.sexo = 'F' THEN a.nota END)
        - AVG(CASE WHEN u.sexo = 'M' THEN a.nota END), 2) AS dif_f_menos_m,
    COUNT(*)                                              AS qtd_avaliacoes
FROM avaliacao a
JOIN usuario u       ON u.idUsuario = a.idUsuario
JOIN filme_genero fg ON fg.idFilme = a.idFilme
GROUP BY fg.nomeGenero
ORDER BY dif_f_menos_m DESC;

-- ---------------------------------------------------------------------------
-- @dataset: popularidade_x_qualidade | Popularidade x Qualidade (por filme)
-- 9. Para cada filme (>=50 avaliacoes): volume vs nota media -> grafico de bolhas
-- ---------------------------------------------------------------------------
SELECT
    f.titulo,
    COUNT(*)              AS qtd_avaliacoes,
    ROUND(AVG(a.nota), 2) AS nota_media
FROM avaliacao a
JOIN filme f ON f.idFilme = a.idFilme
GROUP BY f.idFilme, f.titulo
HAVING COUNT(*) >= 50;

-- ---------------------------------------------------------------------------
-- @dataset: avaliacoes_por_ocupacao | Avaliacoes por ocupacao
-- 10. Volume e nota media por ocupacao do usuario (codigos MovieLens 0-20)
-- ---------------------------------------------------------------------------
SELECT
    u.codOcupacao AS cod_ocupacao,
    CASE u.codOcupacao
        WHEN 0  THEN 'Outro / N/A'          WHEN 1  THEN 'Academico / Educador'
        WHEN 2  THEN 'Artista'              WHEN 3  THEN 'Administrativo'
        WHEN 4  THEN 'Estudante (grad.)'    WHEN 5  THEN 'Atend. ao cliente'
        WHEN 6  THEN 'Saude / Medico'       WHEN 7  THEN 'Executivo / Gerente'
        WHEN 8  THEN 'Agricultor'           WHEN 9  THEN 'Do lar'
        WHEN 10 THEN 'Estudante (K-12)'     WHEN 11 THEN 'Advogado'
        WHEN 12 THEN 'Programador'          WHEN 13 THEN 'Aposentado'
        WHEN 14 THEN 'Vendas / Marketing'   WHEN 15 THEN 'Cientista'
        WHEN 16 THEN 'Autonomo'             WHEN 17 THEN 'Tecnico / Engenheiro'
        WHEN 18 THEN 'Artesao'              WHEN 19 THEN 'Desempregado'
        WHEN 20 THEN 'Escritor'
    END                        AS ocupacao,
    COUNT(*)                   AS qtd_avaliacoes,
    COUNT(DISTINCT u.idUsuario) AS qtd_usuarios,
    ROUND(AVG(a.nota), 2)      AS nota_media
FROM avaliacao a
JOIN usuario u ON u.idUsuario = a.idUsuario
GROUP BY u.codOcupacao
ORDER BY qtd_avaliacoes DESC;
