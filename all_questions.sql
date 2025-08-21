
/* ==============================================================
   Q01 – TOP 5 cursos com mais inscrições **ativas**
   Retorne: id_curso · nome · total_inscritos
=================================================================*/
-- SUA QUERY AQUI
SELECT TOP 5
    i.id_curso,                 
    c.nome AS nome_curso,       
    COUNT(i.id_inscricao) AS total_inscritos  
FROM 
    [Teste_entrevista].[dbo].[inscricoes] AS i
INNER JOIN 
    [Teste_entrevista].[dbo].[cursos] AS c
    ON i.id_curso = c.id_curso   
WHERE 
    i.[status] = 'Ativo'         -- Filtra apenas inscrições ativas
GROUP BY 
    i.id_curso, 
    c.nome                       
ORDER BY 
    total_inscritos DESC;


/* ==============================================================
   Q02 – Taxa de conclusão por curso
   Para cada curso, calcule:
     • total_inscritos
     • total_concluidos   (status = 'concluída')
     • taxa_conclusao (%) = concluídos / inscritos * 100
   Ordene descendentemente pela taxa de conclusão.
=================================================================*/
-- SUA QUERY AQUI

-- Primeiro, vamos calcular os totais de inscritos e concluídos por curso
WITH TotaisCurso AS (
    SELECT
        c.nome AS nome_curso,
        -- Contando quantos alunos estão inscritos em cada curso
        COUNT(i.id_inscricao) AS total_inscritos,
        -- Contando quantos alunos concluíram o curso
        SUM(CASE WHEN i.status = 'concluido' THEN 1 ELSE 0 END) AS total_concluidos
    FROM 
        [Teste_entrevista].[dbo].[inscricoes] AS i
    INNER JOIN 
        [Teste_entrevista].[dbo].[cursos] AS c 
        ON i.id_curso = c.id_curso
    -- Agrupando por curso para calcular os totais por curso
    GROUP BY 
        c.id_curso,
        c.nome
)

-- Agora calculamos a taxa de conclusão e mostramos o resultado
SELECT
    -- Você pode descomentar a linha abaixo para mostrar o nome do curso
    -- nome_curso,
    total_inscritos,
    total_concluidos,
    -- Calculando a taxa de conclusão em porcentagem
    -- Protegendo contra divisão por zero com NULLIF e convertendo para float
    ROUND(
        ISNULL(
            CAST(total_concluidos AS FLOAT) / NULLIF(total_inscritos, 0) * 100, 
            0
        ), 
        2
    ) AS taxa_conclusao
FROM
    TotaisCurso
-- Ordenando pelo curso com maior taxa de conclusão
ORDER BY
    taxa_conclusao DESC;


/* ==============================================================
   Q03 – Tempo médio (dias) para concluir cada **nível** de curso
   Definições:
     • Início = data_insc   (tabela inscricoes) OK
     • Fim    = maior data em progresso onde porcentagem = 100
   Calcule a média de dias entre início e fim,
   agrupando por cursos.nivel (ex.: Básico, Avançado). OK 
=================================================================*/
-- SUA QUERY AQUI

/*No levantamento da questao para fazer o campo fim, a unica tabela que deveria ter os valores corretos nao batem
com a realidade das outras tabelas, exemplo na questão pedea maior data em progresso onde porcentagem = 100 
na tabela [dbo].[progresso] nas colunas [percentual] e [data_ultima_atividade] onde poderiam encontramos informações
para fechamento da coluna fim nao tem nada especificado e visto que a coluna ,[data_ultima_atividade] está com alguns valores inputados errados,
sendo necessario verifica com o time de engenharia de dados.
Ex: se vc filtra o aluno id_aluno:5	nome: Carlos Silva na tabela [dbo].[inscricoes] 
ele só está matruculado em um curso id_curso:1	nome:Fundamentos da Medicina esse curso só tem 3 modulos e a data de inscrição 
e se filtra ele na tabela de [dbo].[progresso] ele vai aparece em mais de tres modulo onde nao está matriculado no curso correspondente na tabela inscrição
outro ponto na coluna [data_inscricao] o curso


/* ==============================================================
   Q04 – TOP 10 módulos com maior **taxa de abandono**
   - Considere abandono quando porcentagem < 20 %
   - Inclua apenas módulos com pelo menos 20 alunos
   Retorne: id_modulo · titulo · abandono_pct
   Ordene do maior para o menor.
=================================================================*/

-- SUA QUERY AQUI

-- Primeiro, vamos calcular a taxa de abandono por módulo
WITH AbandonoPorModulo AS (
    SELECT
        M.id_modulo,
        M.titulo,
        -- Contando o total de alunos inscritos no módulo
        COUNT(I.id_aluno) AS total_alunos,
        -- Contando quantos alunos cancelaram o módulo
        SUM(CASE WHEN I.status = 'cancelado' THEN 1 ELSE 0 END) AS total_abandono,
        -- Calculando a taxa de abandono e formatando como porcentagem
        FORMAT(
            CAST(SUM(CASE WHEN I.status = 'cancelado' THEN 1 ELSE 0 END) AS FLOAT) 
            / COUNT(I.id_aluno), 
            'P2'
        ) AS abandono_pct

    FROM [Teste_entrevista].[dbo].[inscricoes] I
    INNER JOIN [Teste_entrevista].[dbo].[alunos] A 
        ON A.id_aluno = I.id_aluno
    INNER JOIN [Teste_entrevista].[dbo].[modulos] M 
        ON M.id_curso = I.id_curso -- ligando módulo ao curso do aluno
    INNER JOIN [Teste_entrevista].[dbo].[cursos] C 
        ON C.id_curso = I.id_curso
    INNER JOIN [Teste_entrevista].[dbo].[progresso] P 
        ON P.id_aluno = I.id_aluno
    -- Agrupamos por módulo para calcular a taxa de abandono por módulo
    GROUP BY M.id_modulo, M.titulo
    -- Só vamos considerar módulos com menos de 20 alunos (evita ruído nos módulos grandes)
    HAVING COUNT(I.id_aluno) < 20
)

-- Por fim, vamos pegar os top 10 módulos com maior taxa de abandono
SELECT TOP 10
    id_modulo,
    titulo,
    abandono_pct
FROM AbandonoPorModulo
ORDER BY abandono_pct DESC;


/* ==============================================================
   Q05 – Crescimento de inscrições (janela móvel de 3 meses)
   1. Para cada mês calendário (YYYY-MM), conte inscrições.
   2. Calcule a soma móvel de 3 meses (mês atual + 2 anteriores) → rolling_3m.
   3. Calcule a variação % em relação à janela anterior.
   Retorne: ano_mes · inscricoes_mes · rolling_3m · variacao_pct
=================================================================*/
-- SUA QUERY AQUI

-- Primeiro, vamos contar quantas inscrições temos por mês
WITH Inscricoes_Mensal AS (
    SELECT
        -- Transformando a data em ano-mês para agrupar
        FORMAT(I.data_inscricao, 'yyyy-MM') AS ano_mes,
        COUNT(I.id_inscricao) AS inscricoes_mes
    FROM [Teste_entrevista].[dbo].[inscricoes] I
    GROUP BY FORMAT(I.data_inscricao, 'yyyy-MM')
),
-- Agora calculamos a soma móvel de 3 meses (rolling window)
Rolling AS (
    SELECT
        im1.ano_mes,
        im1.inscricoes_mes,
        (
            -- Somando as inscrições do mês atual + 2 meses anteriores
            SELECT SUM(im2.inscricoes_mes)
            FROM Inscricoes_Mensal im2
            WHERE im2.ano_mes BETWEEN 
                  FORMAT(DATEADD(MONTH, -2, CAST(im1.ano_mes + '-01' AS DATE)), 'yyyy-MM') 
                  AND im1.ano_mes
        ) AS rolling_3m
    FROM Inscricoes_Mensal im1
),
-- Calculando a variação percentual em relação ao período anterior
Variacao AS (
    SELECT
        r1.ano_mes,
        r1.inscricoes_mes,
        r1.rolling_3m,
        CASE 
            -- Se não houver período anterior, deixa NULL
            WHEN LAG(r1.rolling_3m) OVER (ORDER BY r1.ano_mes) = 0 THEN NULL
            ELSE CAST(
                (r1.rolling_3m - LAG(r1.rolling_3m) OVER (ORDER BY r1.ano_mes)) 
                * 100.0 
                / LAG(r1.rolling_3m) OVER (ORDER BY r1.ano_mes) 
                AS DECIMAL(5,2)
            )
        END AS variacao_pct
    FROM Rolling r1
)
-- Por fim, exibimos as colunas solicitadas
SELECT
    ano_mes,
    inscricoes_mes,
    rolling_3m,
    -- Formatando a variação percentual com o símbolo %
    CONCAT(variacao_pct, '%') AS variacao_pct
FROM Variacao
ORDER BY ano_mes;
