-- =====================================================================================
--  SISTEMA DE GESTÃO — ACADEMIA DE ARTES MARCIAIS BASE FORTE LESTE
--  Script completo de implementação física (MySQL 8.0)
-- -------------------------------------------------------------------------------------
--  Disciplina : Modelagem de Banco de Dados — Prof. Cid Rodrigues De Andrade
--  Base       : Modelo Lógico (DER) + Dicionário de Dados v2.6 + README da 2ª Entrega
--               (Processos de Negócio PN01 a PN12, Requisitos e Regras de Negócio)
--  Grupo      : Nickolas Henrique Bezerra, Pedro Henrique Ruola Coiado, Raphaela Gonçalves Neves e
--               Williams Vargas Neves Paoli dos Santos
--  SGBD       : MySQL 8.0.16 ou superior (é a versão a partir da qual o CHECK é validado)
--  Motor      : InnoDB (transações e chaves estrangeiras)                        [RNF04]
--  Charset    : utf8mb4 / utf8mb4_unicode_ci (acentos do português)              [RNF04]
-- -------------------------------------------------------------------------------------
--  COMO EXECUTAR
--  Rode o arquivo inteiro de uma vez (no MySQL Workbench: Query > Execute All, ou o
--  raio sem cursor). O script apaga e recria o banco, então pode ser executado
--  várias vezes a partir do zero. Ele roda no modo padrão do MySQL 8.0, com
--  ONLY_FULL_GROUP_BY ligado: toda coluna do SELECT está no GROUP BY ou numa função
--  de agregação.
--  Arquivo complementar: operacoes_busca_inclusao_alteracao_exclusao.sql, com os
--  comandos do dia a dia (buscar, adicionar, alterar e excluir). Rode-o DEPOIS deste.
--
--  ORDEM DO SCRIPT (exigida pelo enunciado)
--   1. CREATE DATABASE e USE
--   2. CREATE TABLE
--   3. Constraints (UNIQUE, índices, FOREIGN KEY e CHECK)
--   4. Massa de dados (INSERT INTO)
--   5. Consultas com JOIN
--   6. Exemplos de UPDATE
--   7. Exemplos de DELETE
--   8. Consultas gerenciais (G01 a G18)
--   9. Consultas de auditoria (A01 a A13)
--
--  DATA DE REFERÊNCIA DA MASSA: 01/11/2026
--  Todos os dados representam a situação da academia nesse dia. As consultas usam a
--  variável @DT_REF no lugar de CURDATE() para que os resultados continuem iguais
--  mesmo que o script seja executado semanas depois (em produção, troque por CURDATE()).
--
--  CONVENÇÕES DE NOMES (as mesmas do dicionário de dados)
--   Prefixos de coluna: ID_ identificador, NM_ nome, DT_ data, HR_ horário, VL_ valor
--   monetário, PC_ percentual, QT_ quantidade, TP_ tipo/situação, IN_ indicador
--   (verdadeiro/falso), DS_ descrição, NR_ número que não sofre conta (telefone, CEP).
--   Prefixos de constraint: PK_ chave primária, FK_ chave estrangeira, UK_ único,
--   CK_ verificação (CHECK), IX_ índice.
--
--  COMO LER AS JUSTIFICATIVAS
--   Cada bloco do script traz entre colchetes o requisito ou a regra que ele atende, com
--   a mesma numeração do README e do dicionário de dados: RF = requisito funcional,
--   RNF = requisito não funcional, RO = regra operacional (RO01 a RO07), RE = restrição
--   organizacional e de integridade (RE01 a RE07), PN = processo de negócio (PN01 a PN12)
--   e P = problema da academia (P1 a P7).
--   A matriz abaixo resume ONDE e COMO cada item é garantido. Há três formas:
--     • ESTRUTURA  — o banco garante sozinho (tabela, tipo, PK, FK, UNIQUE, CHECK, ENUM);
--     • AUDITORIA  — a regra depende da data de hoje ou cruza tabelas, o que o CHECK do
--                    MySQL não permite; então uma consulta da Seção 9 aponta quem a violou
--                    (e o arquivo de operações mostra o INSERT que já respeita a regra);
--     • FORA DO SQL — a regra pertence à aplicação ou ao servidor (ex.: backup).
-- =====================================================================================
--
--  MATRIZ DE RASTREABILIDADE — REQUISITOS x IMPLEMENTAÇÃO
-- -------------------------------------------------------------------------------------
--  REQUISITOS FUNCIONAIS
--  RF01 Alunos, responsáveis e interessados
--       ESTRUTURA: tabelas ALUNO, RESPONSAVEL, INTERESSADO e as tabelas de apoio
--       EMAIL_ALUNO, TELEFONE_ALUNO e PROBLEMA_SAUDE_ALUNO (múltiplos contatos e problemas
--       de saúde); endereço decomposto (rua, número, bairro, CEP); situação cadastral em
--       ENUM ('ATIVO','INATIVO','TRANCADO'). Consultas J03 e J04.
--  RF02 Professores e qualificação
--       ESTRUTURA: PROFESSOR com FK obrigatória para MODALIDADE e VL_POR_AULA (>= 0; o do
--       CEO é 0); ESPECIALIZACAO, NIVEL_DE_EXPERIENCIA e REGISTRO_QUALIFICACOES como
--       tabelas de apoio.
--  RF03 Modalidades, turmas e matrículas
--       ESTRUTURA: MODALIDADE (quórum e sistema de faixas), TURMA (21 turmas: dia, horário
--       e capacidade até 30), MATRICULA (histórico: a troca de turma encerra a antiga e cria
--       uma nova). Consultas J01, G05 e A06.
--  RF04 Planos, contratos, mensalidades e despesas
--       ESTRUTURA: PLANO, CONTRATO, PARTICIPA, PAGAMENTO e DESPESA, com CHECKs de valores e
--       de coerência da liquidação. Consultas G01 a G04, G08, G10 e G11; UPDATE U01.
--  RF05 Aulas, reposições e presenças
--       ESTRUTURA: AULA com o professor efetivo e autorrelacionamento ID_AULA_ORIGEM
--       (reposição, sem presença); PRESENCA com PK composta (sem chamada duplicada).
--       Consultas G07, G09 e G14.
--  RF06 Graduações e trancamentos
--       ESTRUTURA: GRADUACAO (aprovação, reprovação e motivo) e TRANCAMENTO (períodos de
--       afastamento). Consultas J02, G15 e G16; UPDATE U02 (retorno que reativa a cobrança
--       e prorroga o contrato).
--
--  REQUISITOS NÃO FUNCIONAIS
--  RNF01 Independência arquitetural e preparo para catraca facial
--       ESTRUTURA: o banco não depende da aplicação (nenhuma trigger ou procedure; todas
--       as regras ficam em constraints e consultas SQL padrão). Chaves substitutas INT
--       (ID_ALUNO) estáveis, que um equipamento futuro pode usar como identificador, e
--       índice IX_PAGAMENTO_VENC_STATUS para a catraca consultar o bloqueio (RE07) na hora.
--       O cadastro biométrico em si fica para uma versão futura (fora do escopo atual).
--  RNF02 Segurança, privacidade e LGPD
--       ESTRUTURA: LOG_ACESSO (quem leu ou alterou CPF e DS_PROBLEMA_SAUDE) com o perfil em
--       ENUM; dados de saúde isolados em PROBLEMA_SAUDE_ALUNO e TRANCAMENTO.DS_MOTIVO;
--       DESPESA sem dados bancários (minimização).
--       FORA DO SQL: as permissões por perfil (Administração e Professor) e a gravação do
--       log só pelo sistema são aplicadas com papéis, usuários e GRANT do MySQL na
--       implantação, conforme a matriz do dicionário (Seção 5) — exemplo comentado na 3.5.
--  RNF03 Desempenho (< 2 s em frequência e inadimplência)
--       ESTRUTURA: IX_PRESENCA_MATRICULA (frequência por matrícula) e o índice composto
--       IX_PAGAMENTO_VENC_STATUS (inadimplentes por vencimento + situação), além de
--       índices em todas as colunas de FK usadas nos JOINs (Seção 3.2).
--  RNF04 Integridade transacional e codificação
--       ESTRUTURA: MySQL 8.0, ENGINE = InnoDB em todas as tabelas (ACID e FKs) e banco
--       criado em utf8mb4 / utf8mb4_unicode_ci. Transação explícita no UPDATE U02.
--  RNF05 Backup e retenção
--       FORA DO SQL: o backup diário é uma rotina agendada no servidor (exemplo de comando
--       na Seção 1). ESTRUTURA: a retenção de 5 anos é protegida pelas FKs RESTRICT, que
--       impedem apagar contratos, pagamentos e despesas que tenham histórico ligado, e
--       pelos perfis da Seção 3.5, que não têm DELETE nessas tabelas.
--
--  REGRAS OPERACIONAIS
--  RO01 Planos, abrangência e Plano Família
--       ESTRUTURA: desconto gravado no PLANO (PC_DESCONTO entre 0 e 100), nunca no aluno;
--       QT_MINIMA_PESSOAS >= 2 no Família; modalidades do contrato em PARTICIPA e
--       acréscimo em CONTRATO.VL_ACRESCIMO_MODALIDADE. Cada familiar tem o próprio contrato;
--       o grupo (2 a 5 pessoas) e o parentesco são conferidos pelo CEO, fora do banco.
--       AUDITORIA: A10 (desconto dado ao aluno fora do plano), A11 (aluno treinando em
--       modalidade que o contrato não cobre) e A12 (mais de um contrato vigente por aluno).
--  RO02 Vencimento no 5º dia útil, sem valor proporcional
--       ESTRUTURA: PAGAMENTO.DT_VENCIMENTO obrigatório; a massa usa sempre o 5º dia útil
--       e o valor integral, e a 1ª parcela vence no 5º dia útil seguinte à assinatura
--       (PN02). AUDITORIA: A01 (matrícula sem parcela) e A07 (parcela vencida sem mudar
--       para ATRASADO). O arquivo de operações gera as parcelas do mês.
--  RO03 Uma única aula experimental gratuita por pessoa
--       ESTRUTURA: UK_INTERESSADO_PESSOA (NM_INTERESSADO + NR_TELEFONE) recusa o segundo
--       agendamento; situação em ENUM ('PENDENTE','CONVERTIDO','ENCERRADO').
--       AUDITORIA: A09 (situação incoerente com o cadastro de alunos).
--  RO04 Multa rescisória e multa por atraso nos planos de fidelidade, sem juros
--       ESTRUTURA: PAGAMENTO.VL_MULTA (multa por atraso; o banco não tem coluna de juros),
--       CONTRATO.DT_CANCELAMENTO e CK_CONTRATO_MULTA (a multa rescisória só existe se houve
--       cancelamento). UPDATE U01 aplica a multa de um mês de atraso (percentual
--       ilustrativo: os valores reais são confidenciais).
--       AUDITORIA: A08 (cancelamento antecipado sem multa ou com multa diferente da
--       calculada pelos meses que faltavam; plano Mensal com multa) e A13 (parcela de plano
--       de fidelidade paga com atraso e sem multa; plano Mensal com multa).
--  RO05 Assiduidade e tempo mínimo para o exame de faixa
--       ESTRUTURA: PRESENCA guarda a frequência que fundamenta a decisão. A decisão é
--       pedagógica (critério do professor), por isso não é bloqueada pelo banco; a
--       frequência é medida por modalidade (P4 e PN08) nas consultas G09, G14 e G15.
--  RO06 Boxe sem faixa e sem taxa de exame
--       ESTRUTURA: MODALIDADE.IN_POSSUI_SISTEMA_FAIXAS, TP_AVALIACAO e TP_NIVEL_FAIXA em
--       ENUM e CK_GRADUACAO_FAIXA (exame de faixa exige faixa; análise técnica não pode ter
--       faixa). A taxa de exame entra na parcela (VL_TAXA_GRADUACAO), com valor por faixa,
--       só para exames de faixa, na mensalidade que vence e é paga antes do exame (PN08).
--  RO07 Repasse por aula ministrada; instrutor auxiliar sem registro
--       ESTRUTURA: AULA.ID_PROFESSOR registra quem DE FATO deu a aula e DESPESA.ID_PROFESSOR
--       registra o repasse; G07 apura aulas x VL_POR_AULA. Os 5 prestadores recebem; o
--       gestor tem VL_POR_AULA = 0. O instrutor auxiliar não tem tabela, por decisão de
--       negócio (não é funcionário e não gera pagamento).
--
--  RESTRIÇÕES ORGANIZACIONAIS E DE INTEGRIDADE
--  RE01 Máximo de 30 alunos ativos por turma
--       ESTRUTURA: QT_CAPACIDADE_MAXIMA DEFAULT 30 com CK (1 a 30). Contar matrículas
--       ativas exige olhar outras linhas, o que o CHECK não faz: AUDITORIA A06 e, no
--       arquivo de operações, o INSERT de matrícula que só grava se houver vaga.
--  RE02 Quórum mínimo de referência (alerta, sem bloqueio)
--       ESTRUTURA: MODALIDADE.QT_MINIMA_REFERENCIA (> 0). AUDITORIA/ALERTA: A06.
--  RE03 Menor de 18 anos com responsável legal; atestado de aptidão física de todos
--       ESTRUTURA: FK ALUNO → RESPONSAVEL; ID_RESPONSAVEL aceita NULL porque o maior de
--       idade não tem responsável. Coluna DT_ENTREGA_ATESTADO, vazia até a entrega, com
--       CK_ALUNO_DT_ATESTADO (depois do nascimento). A idade muda com a data de hoje
--       (CURDATE não é aceito em CHECK) e a entrega pode vir depois da matrícula:
--       AUDITORIA A05 (menor sem responsável; aluno ativo ou trancado sem atestado); J03.
--  RE04 Trancamento só por lesão ou razão médica
--       ESTRUTURA: TP_TRANCAMENTO ENUM('LESAO','RAZAO_MEDICA') e CHECKs de datas.
--       AUDITORIA: A03 (presença durante o trancamento). UPDATE U02 encerra o
--       trancamento, gera a parcela e prorroga DT_FIM.
--  RE05 Professor exclusivo de uma modalidade
--       ESTRUTURA: PROFESSOR.ID_MODALIDADE NOT NULL (uma só modalidade). A compatibilidade
--       com turma, aula e graduação cruza tabelas: AUDITORIA A04.
--  RE06 Domínios de situação e preservação do histórico
--       ESTRUTURA: ENUMs de ALUNO e MATRICULA; FKs RESTRICT impedem a exclusão física de
--       matrículas, contratos, pagamentos e despesas com histórico (exemplo D03).
--  RE07 Bloqueio por inadimplência a partir do 6º dia útil
--       ESTRUTURA: situação da parcela em ENUM ('PAGO','ATRASADO','PENDENTE') e índice
--       IX_PAGAMENTO_VENC_STATUS. AUDITORIA: A02 (presença de bloqueado) e A07;
--       G04 lista os bloqueados; no arquivo de operações a chamada só grava os liberados.
-- =====================================================================================


-- =====================================================================================
-- 1. CRIAÇÃO DO BANCO DE DADOS                                         [RNF04, RNF05]
-- =====================================================================================
-- DROP ... IF EXISTS permite rodar o script de novo sem erro de "banco já existe".
-- ATENÇÃO: apaga todos os dados do banco ACADEMIA_BFL, se ele já existir.
--
-- [RNF05] O backup diário NÃO fica neste script: é uma tarefa agendada no servidor
-- (agendador do Windows ou cron do Linux), por exemplo:
--   mysqldump --single-transaction --routines ACADEMIA_BFL > backup_AAAA-MM-DD.sql
-- --single-transaction tira a cópia sem travar o uso (possível porque o motor é InnoDB).
-- Os arquivos com mais de 30 dias são apagados pela própria rotina (rotação).
DROP DATABASE IF EXISTS ACADEMIA_BFL;

-- [RNF04] utf8mb4 guarda qualquer caractere (acentos, ç, emojis);
-- utf8mb4_unicode_ci compara texto sem diferenciar maiúsculas de minúsculas.
CREATE DATABASE ACADEMIA_BFL
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE ACADEMIA_BFL;


-- =====================================================================================
-- 2. CRIAÇÃO DAS TABELAS
-- =====================================================================================
-- Decisões de tipos de dados (valem para todas as tabelas):
--  • INT AUTO_INCREMENT nas chaves primárias: o próprio banco gera o número. São chaves
--    substitutas, sem significado de negócio, e por isso nunca mudam [RNF01].
--  • DECIMAL(10,2) para dinheiro: guarda o valor exato (FLOAT/DOUBLE geram erro de
--    arredondamento, como 0,1 + 0,2 = 0,30000000000000004) [RF04].
--  • DECIMAL(5,2) para percentuais (até 100,00) [RO01].
--  • CHAR(n) quando o tamanho é sempre o mesmo (CPF = 11 dígitos, CEP = 8 dígitos)
--    e VARCHAR(n) quando o tamanho varia (nomes, e-mails).
--  • CPF, CEP e telefone são texto, e não número: não fazemos conta com eles e um
--    número apagaria o zero à esquerda (CEP 03310-000 viraria 3310000).
--  • ENUM em todas as colunas TP_ (situação, tipo, resultado, perfil, faixa), com lista
--    fechada de valores, como no dicionário de dados v2.6: o banco recusa qualquer valor
--    fora da lista [RE06].
--  • BOOLEAN (no MySQL vira TINYINT(1)) para indicadores sim/não.
--  • TEXT para textos longos e livres (histórico de treino, motivo do trancamento).
--  • ENGINE = InnoDB em todas as tabelas: transações ACID e chaves estrangeiras [RNF04].
--
-- Aqui ficam só as colunas, o NOT NULL e a chave primária. O NOT NULL faz parte da
-- definição da coluna e a PK precisa existir já na criação porque o AUTO_INCREMENT
-- exige que a coluna seja chave. As demais constraints (UNIQUE, FK, CHECK) vêm na
-- Seção 3, o que também evita erro de ordem de criação: como as FKs só são ligadas
-- depois que todas as tabelas existem, a ordem dos CREATE TABLE não importa.
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- 2.1 MODALIDADE — as seis artes marciais oferecidas                    [RF03]
-- -------------------------------------------------------------------------------------
-- QT_MINIMA_REFERENCIA guarda o quórum que dispara o alerta de turma vazia [RE02].
-- IN_POSSUI_SISTEMA_FAIXAS separa exame de faixa de análise técnica (Boxe) [RO06].
-- TP_SITUACAO_MODALIDADE permite "desligar" uma modalidade sem apagá-la [RE06].
CREATE TABLE MODALIDADE (
    ID_MODALIDADE             INT          NOT NULL AUTO_INCREMENT,
    QT_MINIMA_REFERENCIA      INT          NOT NULL,                 -- quórum de referência para abrir horário
    TP_SITUACAO_MODALIDADE    ENUM('ATIVA','INATIVA') NOT NULL DEFAULT 'ATIVA',
    IN_POSSUI_SISTEMA_FAIXAS  BOOLEAN      NOT NULL,                 -- FALSE no Boxe (análise técnica, RO06)
    DT_INICIO_AULAS           DATE         NOT NULL,
    NM_MODALIDADE             VARCHAR(50)  NOT NULL,
    CONSTRAINT PK_MODALIDADE PRIMARY KEY (ID_MODALIDADE)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.2 PROFESSOR — prestador de serviço (ou o gestor) pago por aula      [RF02, RE05, RO07]
-- -------------------------------------------------------------------------------------
-- ID_MODALIDADE é uma coluna única e obrigatória: o professor atua em UMA modalidade [RE05].
-- VL_POR_AULA é a base do repasse por aula ministrada [RO07]. O do gestor (CEO) é 0,
-- porque ele não recebe por aula: retira o seu ganho das mensalidades e das taxas (PN11).
CREATE TABLE PROFESSOR (
    ID_PROFESSOR     INT            NOT NULL AUTO_INCREMENT,
    ID_MODALIDADE    INT            NOT NULL,                        -- leciona uma única modalidade (RE05)
    CPF              CHAR(11)       NOT NULL,
    NM_COMPLETO      VARCHAR(150)   NOT NULL,
    DT_NASCIMENTO    DATE           NOT NULL,
    VL_POR_AULA      DECIMAL(10,2)  NOT NULL,                        -- base do repasse (0 para o CEO)
    NR_CEP           CHAR(8)        NOT NULL,
    DS_RUA           VARCHAR(100)   NOT NULL,
    NR_LOGRADOURO    VARCHAR(10)    NOT NULL,
    NM_BAIRRO        VARCHAR(60)    NOT NULL,
    CONSTRAINT PK_PROFESSOR PRIMARY KEY (ID_PROFESSOR)
) ENGINE = InnoDB;

-- Tabelas de apoio dos atributos multivalorados do professor [RF02].
-- Um atributo com vários valores não cabe numa coluna só (1ª Forma Normal); cada valor
-- vira uma linha. A PK composta (valor + ID do professor) impede repetir o mesmo valor
-- para a mesma pessoa.
CREATE TABLE EMAIL_PROFESSOR (
    DS_EMAIL       VARCHAR(100) NOT NULL,
    ID_PROFESSOR   INT          NOT NULL,
    CONSTRAINT PK_EMAIL_PROFESSOR PRIMARY KEY (DS_EMAIL, ID_PROFESSOR)
) ENGINE = InnoDB;

CREATE TABLE TELEFONE_PROFESSOR (
    NR_TELEFONE    VARCHAR(15)  NOT NULL,
    ID_PROFESSOR   INT          NOT NULL,
    CONSTRAINT PK_TELEFONE_PROFESSOR PRIMARY KEY (NR_TELEFONE, ID_PROFESSOR)
) ENGINE = InnoDB;

CREATE TABLE ESPECIALIZACAO (
    DS_ESPECIALIZACAO  VARCHAR(50) NOT NULL,
    ID_PROFESSOR       INT         NOT NULL,
    CONSTRAINT PK_ESPECIALIZACAO PRIMARY KEY (DS_ESPECIALIZACAO, ID_PROFESSOR)
) ENGINE = InnoDB;

CREATE TABLE NIVEL_DE_EXPERIENCIA (
    DS_NIVEL_EXPERIENCIA  VARCHAR(50) NOT NULL,
    ID_PROFESSOR          INT         NOT NULL,
    CONSTRAINT PK_NIVEL_DE_EXPERIENCIA PRIMARY KEY (DS_NIVEL_EXPERIENCIA, ID_PROFESSOR)
) ENGINE = InnoDB;

CREATE TABLE REGISTRO_QUALIFICACOES (
    DS_REGISTRO_QUALIFICACOES  VARCHAR(200) NOT NULL,
    ID_PROFESSOR               INT          NOT NULL,
    CONSTRAINT PK_REGISTRO_QUALIFICACOES PRIMARY KEY (DS_REGISTRO_QUALIFICACOES, ID_PROFESSOR)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.3 RESPONSAVEL — responsável legal do aluno menor de 18 anos         [RF01, RE03]
-- -------------------------------------------------------------------------------------
-- Tabela separada porque um responsável pode representar vários alunos (irmãos) e
-- porque é ele quem dá o consentimento do menor, inclusive de imagem (LGPD art. 14) [RE03].
CREATE TABLE RESPONSAVEL (
    ID_RESPONSAVEL   INT           NOT NULL AUTO_INCREMENT,
    CPF              CHAR(11)      NOT NULL,
    NM_RESPONSAVEL   VARCHAR(150)  NOT NULL,
    NR_TELEFONE      VARCHAR(15)   NOT NULL,
    DS_PARENTESCO    VARCHAR(30)   NOT NULL,
    CONSTRAINT PK_RESPONSAVEL PRIMARY KEY (ID_RESPONSAVEL)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.4 INTERESSADO — pré-cadastro da aula experimental gratuita          [RF01, RO03]
-- -------------------------------------------------------------------------------------
-- Guarda só o mínimo para o retorno (nome e telefone): minimização de dados [RNF02].
-- TP_STATUS mede a conversão da aula experimental em matrícula [RO03].
CREATE TABLE INTERESSADO (
    ID_INTERESSADO   INT           NOT NULL AUTO_INCREMENT,
    ID_MODALIDADE    INT           NOT NULL,
    NM_INTERESSADO   VARCHAR(150)  NOT NULL,
    TP_STATUS        ENUM('CONVERTIDO','ENCERRADO','PENDENTE') NOT NULL DEFAULT 'PENDENTE',
    NR_TELEFONE      VARCHAR(15)   NOT NULL,
    DT_AULA          DATE          NOT NULL,
    HR_AULA          TIME          NOT NULL,
    CONSTRAINT PK_INTERESSADO PRIMARY KEY (ID_INTERESSADO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.5 ALUNO — pessoa física matriculada na academia                     [RF01, RE03, RE06]
-- -------------------------------------------------------------------------------------
-- ID_RESPONSAVEL aceita NULL porque só o menor de idade tem responsável legal; a exigência
-- para o menor é conferida pela auditoria A05 [RE03].
-- DT_ENTREGA_ATESTADO aceita NULL até o aluno entregar o atestado de aptidão física, que é
-- exigido de TODOS os alunos, adultos e menores [RE03]: a auditoria A05 lista quem ainda deve.
-- TP_STATUS_ALUNO só aceita os três estados do RE06; a inadimplência NÃO é um estado do
-- aluno, ela é derivada dos pagamentos [RE07].
-- IN_ACEITE_USO_IMAGEM + DT_AUTORIZACAO_IMAGEM registram o consentimento (LGPD) [RNF02].
CREATE TABLE ALUNO (
    ID_ALUNO                INT           NOT NULL AUTO_INCREMENT,
    ID_RESPONSAVEL          INT           NULL,                       -- só para menor de 18 anos (RE03)
    ID_INTERESSADO          INT           NULL,                       -- só se veio da aula experimental
    DT_AUTORIZACAO_IMAGEM   DATE          NOT NULL,
    CPF                     CHAR(11)      NOT NULL,
    NM_COMPLETO             VARCHAR(150)  NOT NULL,
    DT_NASCIMENTO           DATE          NOT NULL,
    DS_HISTORICO_TREINO     TEXT          NOT NULL,
    IN_ACEITE_USO_IMAGEM    BOOLEAN       NOT NULL,
    TP_STATUS_ALUNO         ENUM('ATIVO','INATIVO','TRANCADO') NOT NULL DEFAULT 'ATIVO',  -- RE06
    DT_ENTREGA_ATESTADO     DATE          NULL,                       -- exigido de todos (RE03); vazio até a entrega
    NR_CEP                  CHAR(8)       NOT NULL,
    NR_LOGRADOURO           VARCHAR(10)   NOT NULL,
    DS_RUA                  VARCHAR(100)  NOT NULL,
    NM_BAIRRO               VARCHAR(60)   NOT NULL,
    CONSTRAINT PK_ALUNO PRIMARY KEY (ID_ALUNO)
) ENGINE = InnoDB;

-- Atributos multivalorados do aluno: múltiplos contatos e problemas de saúde [RF01].
CREATE TABLE EMAIL_ALUNO (
    DS_EMAIL   VARCHAR(100) NOT NULL,
    ID_ALUNO   INT          NOT NULL,
    CONSTRAINT PK_EMAIL_ALUNO PRIMARY KEY (DS_EMAIL, ID_ALUNO)
) ENGINE = InnoDB;

CREATE TABLE TELEFONE_ALUNO (
    NR_TELEFONE  VARCHAR(15) NOT NULL,
    ID_ALUNO     INT         NOT NULL,
    CONSTRAINT PK_TELEFONE_ALUNO PRIMARY KEY (NR_TELEFONE, ID_ALUNO)
) ENGINE = InnoDB;

-- [RNF02] Dado sensível de saúde isolado numa tabela própria: fica mais fácil restringir
-- a leitura (o professor lê só esta tabela e o nome do aluno, Seção 3.5) e registrar cada
-- acesso em LOG_ACESSO. Sem problema de saúde, registra-se 'nenhum'.
CREATE TABLE PROBLEMA_SAUDE_ALUNO (
    DS_PROBLEMA_SAUDE  VARCHAR(200) NOT NULL,
    ID_ALUNO           INT          NOT NULL,
    CONSTRAINT PK_PROBLEMA_SAUDE_ALUNO PRIMARY KEY (DS_PROBLEMA_SAUDE, ID_ALUNO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.6 TURMA — dia e horário fixos de uma modalidade                     [RF03, RE01, RE05]
-- -------------------------------------------------------------------------------------
-- Grade do PN06: 4 turmas por dia, em horários diferentes, de segunda a sexta; aos sábados
-- só há a turma de Capoeira, que é única. São 21 turmas.
-- QT_CAPACIDADE_MAXIMA nasce com 30 (DEFAULT), o limite físico do tatame [RE01].
-- As vagas ocupadas não são guardadas: são contadas nas matrículas ativas (evita um
-- número que pode ficar desatualizado).
CREATE TABLE TURMA (
    ID_TURMA               INT   NOT NULL AUTO_INCREMENT,
    ID_MODALIDADE          INT   NOT NULL,
    ID_PROFESSOR           INT   NOT NULL,
    DS_DIA_SEMANA          ENUM('SEGUNDA','TERCA','QUARTA','QUINTA','SEXTA','SABADO') NOT NULL,
    HR_INICIO              TIME  NOT NULL,
    QT_CAPACIDADE_MAXIMA   INT   NOT NULL DEFAULT 30,                -- limite físico do tatame (RE01)
    HR_FIM                 TIME  NOT NULL,
    CONSTRAINT PK_TURMA PRIMARY KEY (ID_TURMA)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.7 MATRICULA — vínculo entre um aluno e uma turma                    [RF03, RE06]
-- -------------------------------------------------------------------------------------
-- Resolve o N:N ALUNO x TURMA. Na transferência de turma a matrícula antiga vira
-- 'ENCERRADA' e uma nova é criada; nada é apagado, e o histórico de presença continua
-- ligado à matrícula antiga [RE06].
CREATE TABLE MATRICULA (
    ID_MATRICULA            INT   NOT NULL AUTO_INCREMENT,
    ID_ALUNO                INT   NOT NULL,
    ID_TURMA                INT   NOT NULL,
    DT_MATRICULA            DATE  NOT NULL,
    TP_SITUACAO_MATRICULA   ENUM('ATIVA','TRANCADA','ENCERRADA','CANCELADA') NOT NULL DEFAULT 'ATIVA',
    CONSTRAINT PK_MATRICULA PRIMARY KEY (ID_MATRICULA)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.8 TRANCAMENTO — afastamento por lesão ou razão médica               [RF06, RE04]
-- -------------------------------------------------------------------------------------
-- O ENUM só aceita os dois motivos permitidos [RE04]. Não há coluna de laudo porque a
-- regra dispensa laudo formal. DS_MOTIVO é dado de saúde (sensível) [RNF02].
-- DT_RETORNO_EFETIVA vazia = trancamento em curso (sem parcela e sem presença).
CREATE TABLE TRANCAMENTO (
    ID_TRANCAMENTO        INT   NOT NULL AUTO_INCREMENT,
    ID_MATRICULA          INT   NOT NULL,
    TP_TRANCAMENTO        ENUM('LESAO','RAZAO_MEDICA') NOT NULL,
    DT_RETORNO_EFETIVA    DATE  NULL,                                -- vazia enquanto o aluno está afastado
    DS_MOTIVO             TEXT  NOT NULL,                            -- dado sensível (saúde)
    DT_RETORNO_PREVISTA   DATE  NOT NULL,
    DT_INICIO             DATE  NOT NULL,
    CONSTRAINT PK_TRANCAMENTO PRIMARY KEY (ID_TRANCAMENTO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.9 AULA — ocorrência datada de um treino                              [RF05, RO07]
-- -------------------------------------------------------------------------------------
-- ID_PROFESSOR é quem DE FATO ministrou (pode ser um substituto): é a base do repasse [RO07].
-- ID_AULA_ORIGEM aponta para a própria tabela AULA (autorrelacionamento) e indica qual
-- aula esta reposição substitui [RF05]. A reposição não gera presença: o aluno só assiste,
-- porque não é matriculado nessa aula (PN07).
CREATE TABLE AULA (
    ID_AULA          INT   NOT NULL AUTO_INCREMENT,
    ID_PROFESSOR     INT   NOT NULL,                                 -- quem de fato ministrou
    ID_TURMA         INT   NOT NULL,
    DT_AULA          DATE  NOT NULL,
    HR_INICIO        TIME  NOT NULL,
    ID_AULA_ORIGEM   INT   NULL,                                     -- aula que esta repõe (autorrelacionamento)
    CONSTRAINT PK_AULA PRIMARY KEY (ID_AULA)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.10 PRESENCA — lista de chamada (N:N AULA x MATRICULA)               [RF05, RO05, RE07]
-- -------------------------------------------------------------------------------------
-- PK composta: a mesma matrícula não pode ter duas presenças na mesma aula.
-- É a fonte da frequência, por modalidade, usada para liberar o exame de faixa [RO05].
-- Aluno bloqueado ou trancado não recebe linha de presença [RE07, RE04], e a aula de
-- reposição também não (PN07).
CREATE TABLE PRESENCA (
    ID_AULA        INT      NOT NULL,
    ID_MATRICULA   INT      NOT NULL,
    IN_PRESENTE    BOOLEAN  NOT NULL DEFAULT FALSE,
    CONSTRAINT PK_PRESENCA PRIMARY KEY (ID_AULA, ID_MATRICULA)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.11 PLANO — condição comercial (duração, valor e desconto)           [RF04, RO01]
-- -------------------------------------------------------------------------------------
-- O desconto mora no PLANO, nunca no aluno [RO01]. QT_MINIMA_PESSOAS preenchido
-- identifica os planos Família (a partir de 2 pessoas) [RO01].
CREATE TABLE PLANO (
    ID_PLANO            INT            NOT NULL AUTO_INCREMENT,
    NM_PLANO            VARCHAR(50)    NOT NULL,
    QT_DURACAO_MESES    INT            NOT NULL,
    VL_MENSALIDADE      DECIMAL(10,2)  NOT NULL,                     -- valor-base por pessoa
    PC_DESCONTO         DECIMAL(5,2)   NOT NULL DEFAULT 0,
    QT_MINIMA_PESSOAS   INT            NULL,                         -- preenchido só nos planos Família
    DS_CONDICAO         TEXT           NULL,
    CONSTRAINT PK_PLANO PRIMARY KEY (ID_PLANO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.12 CONTRATO — acordo do aluno com a academia                       [RF04, RO01, RO04, RE04]
-- -------------------------------------------------------------------------------------
-- Cada aluno tem um único contrato vigente; cada modalidade extra entra nele como
-- acréscimo, e não como um segundo contrato (PN02, PN03): a auditoria A12 confere.
-- VL_MENSAL_ACORDADO é congelado: reajuste no PLANO não muda contratos já firmados.
-- VL_ACRESCIMO_MODALIDADE cobra as modalidades extras [RO01].
-- VL_MULTA_RESCISORIA só existe no cancelamento antecipado de plano de fidelidade e é
-- calculada pelos meses que faltam para o fim do ciclo [RO04].
-- DT_FIM é prorrogado pelo tempo de trancamento [RE04].
CREATE TABLE CONTRATO (
    ID_CONTRATO               INT            NOT NULL AUTO_INCREMENT,
    ID_ALUNO                  INT            NOT NULL,               -- aluno do contrato (no Plano Família, cada familiar tem o seu)
    ID_PLANO                  INT            NOT NULL,
    DT_INICIO                 DATE           NOT NULL,
    DT_FIM                    DATE           NOT NULL,               -- fim do ciclo atual
    VL_MENSAL_ACORDADO        DECIMAL(10,2)  NOT NULL,               -- congelado na contratação
    VL_ACRESCIMO_MODALIDADE   DECIMAL(10,2)  NULL,                   -- modalidades além da primeira
    DT_CANCELAMENTO           DATE           NULL,
    VL_MULTA_RESCISORIA       DECIMAL(10,2)  NULL,                   -- só no cancelamento antecipado (RO04)
    CONSTRAINT PK_CONTRATO PRIMARY KEY (ID_CONTRATO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.13 PARTICIPA — modalidades cobertas pelo contrato (N:N)             [RF04, RO01]
-- -------------------------------------------------------------------------------------
CREATE TABLE PARTICIPA (
    ID_MODALIDADE  INT NOT NULL,
    ID_CONTRATO    INT NOT NULL,
    CONSTRAINT PK_PARTICIPA PRIMARY KEY (ID_CONTRATO, ID_MODALIDADE)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.14 PAGAMENTO — parcela mensal do contrato                           [RF04, RO02, RO04, RO06, RE07]
-- -------------------------------------------------------------------------------------
-- Uma linha por mês, sempre com vencimento no 5º dia útil e valor integral [RO02]. A 1ª
-- parcela vence no 5º dia útil seguinte à assinatura (PN02): quem assina depois do 5º dia
-- útil do mês só tem a 1ª parcela no mês seguinte.
-- VL_MULTA = multa moratória dos planos de fidelidade [RO04].
-- VL_TAXA_GRADUACAO = taxa do exame de faixa, com valor por faixa, cobrada na mensalidade
-- que vence antes do exame e paga antes dele (PN08) [RO06].
-- TP_STATUS_PAGAMENTO é a origem da inadimplência e do bloqueio [RE07].
CREATE TABLE PAGAMENTO (
    ID_PAGAMENTO           INT            NOT NULL AUTO_INCREMENT,
    ID_CONTRATO            INT            NOT NULL,
    DT_VENCIMENTO          DATE           NOT NULL,                  -- 5º dia útil (RO02)
    DT_PAGAMENTO           DATE           NULL,                      -- preenchida só na liquidação
    VL_DEVIDO              DECIMAL(10,2)  NOT NULL,
    VL_PAGO                DECIMAL(10,2)  NULL,
    TP_FORMA_PAGAMENTO     ENUM('PIX','CREDITO','DEBITO') NULL,
    VL_MULTA               DECIMAL(10,2)  NULL,                      -- só em planos de maior duração
    VL_TAXA_GRADUACAO      DECIMAL(10,2)  NULL,                      -- taxa do exame de faixa (valor por faixa)
    TP_STATUS_PAGAMENTO    ENUM('PAGO','ATRASADO','PENDENTE') NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT PK_PAGAMENTO PRIMARY KEY (ID_PAGAMENTO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.15 GRADUACAO — exame de faixa ou análise técnica                    [RF06, RO05, RO06, RE05]
-- -------------------------------------------------------------------------------------
-- TP_AVALIACAO separa exame de faixa e análise técnica do Boxe; TP_NIVEL_FAIXA fica
-- vazio na análise técnica [RO06]. A reprovação fica no histórico com o motivo [RF06].
-- TP_NIVEL_FAIXA é ENUM (dicionário v2.6) com as graduações de cada modalidade, na ordem
-- de progressão: graus da faixa branca e faixas do Jiu-Jitsu e do No-Gi, faixas do
-- Kickboxing, prajieds do Muay Thai e cordas da Capoeira.
CREATE TABLE GRADUACAO (
    ID_GRADUACAO           INT           NOT NULL AUTO_INCREMENT,
    ID_ALUNO               INT           NOT NULL,
    ID_PROFESSOR           INT           NOT NULL,                   -- quem avaliou
    ID_MODALIDADE          INT           NOT NULL,
    DS_MOTIVO_REPROVACAO   VARCHAR(100)  NULL,                       -- palavras-chave, só na reprovação
    DT_GRADUACAO           DATE          NOT NULL,
    TP_NIVEL_FAIXA         ENUM('Faixa Branca 1º grau','Faixa Branca 2º grau','Faixa Branca 3º grau',
                                'Faixa Branca 4º grau','Faixa Amarela','Faixa Laranja','Faixa Verde',
                                'Faixa Azul','Faixa Roxa','Faixa Marrom','Faixa Preta',
                                'Prajied Branco','Prajied Amarelo','Prajied Laranja','Prajied Verde',
                                'Prajied Azul','Prajied Marrom','Prajied Preto',
                                'Corda Crua','Corda Amarela','Corda Laranja','Corda Azul','Corda Verde',
                                'Corda Roxa','Corda Marrom','Corda Vermelha') NULL,  -- vazio na análise técnica
    TP_AVALIACAO           ENUM('EXAME_FAIXA','ANALISE_TECNICA') NOT NULL,
    TP_RESULTADO           ENUM('APROVADO','REPROVADO') NOT NULL,
    CONSTRAINT PK_GRADUACAO PRIMARY KEY (ID_GRADUACAO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.16 DESPESA — contas a pagar e repasse aos professores               [RF04, RO07, RNF02]
-- -------------------------------------------------------------------------------------
-- ID_PROFESSOR só é preenchido no repasse por aulas [RO07]. O credor é só um nome:
-- não se guardam dados bancários (minimização, LGPD) [RNF02].
CREATE TABLE DESPESA (
    ID_DESPESA            INT            NOT NULL AUTO_INCREMENT,
    ID_PROFESSOR          INT            NULL,                       -- só no repasse a professor
    DS_CATEGORIA          VARCHAR(40)    NOT NULL,
    VL_DESPESA            DECIMAL(10,2)  NOT NULL,
    DT_VENCIMENTO         DATE           NOT NULL,
    DT_PAGAMENTO          DATE           NULL,
    VL_PAGO               DECIMAL(10,2)  NULL,
    DS_DESCRICAO          VARCHAR(200)   NOT NULL,
    NM_CREDOR             VARCHAR(100)   NOT NULL,
    TP_SITUACAO_DESPESA   ENUM('PAGO','ATRASADO','PENDENTE') NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT PK_DESPESA PRIMARY KEY (ID_DESPESA)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.17 LOG_ACESSO — rastreabilidade de acesso a dado pessoal            [RNF02]
-- -------------------------------------------------------------------------------------
-- Registra quem leu ou alterou CPF e DS_PROBLEMA_SAUDE e toda operação de escrita, sem
-- copiar o dado sensível para o log (só o ID do registro e o nome do campo). É gravado
-- apenas pelo sistema e só a Administração o consulta (dicionário, Seção 6; GRANTs na 3.5).
-- Na PRESENCA, cuja PK é composta, ID_REGISTRO guarda o ID_AULA da chamada alterada.
-- Sem FK em ID_REGISTRO de propósito: ele aponta para tabelas diferentes conforme
-- NM_TABELA, e o log precisa continuar existindo mesmo depois que o registro é excluído.
CREATE TABLE LOG_ACESSO (
    ID_LOG         INT          NOT NULL AUTO_INCREMENT,
    NM_USUARIO     VARCHAR(50)  NOT NULL,
    TP_PERFIL      ENUM('ADMINISTRACAO','PROFESSOR') NOT NULL,       -- os dois perfis do RNF02
    DT_ACESSO      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    TP_OPERACAO    ENUM('CRIACAO','LEITURA','ATUALIZACAO','EXCLUSAO') NOT NULL,
    NM_TABELA      VARCHAR(30)  NOT NULL,
    ID_REGISTRO    INT          NOT NULL,
    NM_CAMPO       VARCHAR(40)  NULL,
    CONSTRAINT PK_LOG_ACESSO PRIMARY KEY (ID_LOG)
) ENGINE = InnoDB;


-- =====================================================================================
-- 3. CONSTRAINTS
-- =====================================================================================
-- PK e NOT NULL já foram declarados na Seção 2. Aqui entram, nesta ordem:
--   3.1 UNIQUE  — valores que não podem se repetir (CPF, nomes de domínio)
--   3.2 Índices — aceleram as buscas críticas                                   [RNF03]
--   3.3 FOREIGN KEY — integridade referencial entre as tabelas                  [RNF04]
--   3.4 CHECK — regras de valor (dinheiro não negativo, datas coerentes, formatos)
--   3.5 Perfis de acesso (exemplo comentado)                                    [RNF02]
--
-- Política de exclusão das FKs:
--   • ON DELETE CASCADE só nas tabelas de apoio multivaloradas (e-mail, telefone...):
--     esses valores não existem sem o dono; se o dono for excluído, vão junto.
--   • Nas demais FKs vale o padrão RESTRICT: o banco IMPEDE apagar um registro que
--     ainda é referenciado (ex.: não dá para apagar uma modalidade que tem turmas).
--     Isso preserva o histórico de matrículas, contratos, pagamentos e despesas [RE06]
--     durante o prazo legal de guarda de 5 anos [RNF05].
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- 3.1 UNIQUE
-- -------------------------------------------------------------------------------------
-- Domínio fechado das 6 modalidades, sem repetição de nome [RF03].
ALTER TABLE MODALIDADE  ADD CONSTRAINT UK_MODALIDADE_NOME   UNIQUE (NM_MODALIDADE);
-- Um CPF identifica uma única pessoa em cada cadastro [RF01, RF02].
ALTER TABLE PROFESSOR   ADD CONSTRAINT UK_PROFESSOR_CPF     UNIQUE (CPF);
ALTER TABLE RESPONSAVEL ADD CONSTRAINT UK_RESPONSAVEL_CPF   UNIQUE (CPF);
ALTER TABLE ALUNO       ADD CONSTRAINT UK_ALUNO_CPF         UNIQUE (CPF);
-- Um interessado vira, no máximo, um aluno (relação 1:1 opcional) [RF01].
-- O UNIQUE aceita vários NULL, então alunos cadastrados direto não conflitam.
ALTER TABLE ALUNO       ADD CONSTRAINT UK_ALUNO_INTERESSADO UNIQUE (ID_INTERESSADO);
-- [RO03] Uma única aula experimental por pessoa, conferida por nome + telefone:
-- o segundo agendamento da mesma pessoa é recusado pelo próprio banco.
ALTER TABLE INTERESSADO ADD CONSTRAINT UK_INTERESSADO_PESSOA UNIQUE (NM_INTERESSADO, NR_TELEFONE);
-- [RF03] Permite renovar a matrícula na mesma turma em outra data, mas não duplicar no mesmo dia.
ALTER TABLE MATRICULA   ADD CONSTRAINT UK_MATRICULA_ALUNO_TURMA_DATA UNIQUE (ID_ALUNO, ID_TURMA, DT_MATRICULA);
-- [RO01] Cada plano comercial tem um nome único (Mensal, Trimestral... Família).
ALTER TABLE PLANO       ADD CONSTRAINT UK_PLANO_NOME        UNIQUE (NM_PLANO);

-- -------------------------------------------------------------------------------------
-- 3.2 ÍNDICES                                                            [RNF03, RNF01]
-- -------------------------------------------------------------------------------------
-- Criados antes das FKs para que cada FK reaproveite o seu índice. Os dois índices
-- marcados com (*) atendem diretamente as consultas que o RNF03 exige em menos de 2 s.
CREATE INDEX IX_PROFESSOR_MODALIDADE   ON PROFESSOR   (ID_MODALIDADE);
CREATE INDEX IX_INTERESSADO_MODALIDADE ON INTERESSADO (ID_MODALIDADE);
CREATE INDEX IX_ALUNO_NOME             ON ALUNO       (NM_COMPLETO);       -- busca por nome na recepção
CREATE INDEX IX_ALUNO_RESPONSAVEL      ON ALUNO       (ID_RESPONSAVEL);
CREATE INDEX IX_TURMA_MODALIDADE       ON TURMA       (ID_MODALIDADE);
CREATE INDEX IX_TURMA_PROFESSOR        ON TURMA       (ID_PROFESSOR);
CREATE INDEX IX_MATRICULA_TURMA        ON MATRICULA   (ID_TURMA);          -- contagem de ativas (RE01)
CREATE INDEX IX_TRANCAMENTO_MATRICULA  ON TRANCAMENTO (ID_MATRICULA);
CREATE INDEX IX_AULA_TURMA_DATA        ON AULA        (ID_TURMA, DT_AULA, HR_INICIO);
CREATE INDEX IX_AULA_PROFESSOR         ON AULA        (ID_PROFESSOR);      -- apuração do repasse
CREATE INDEX IX_AULA_ORIGEM            ON AULA        (ID_AULA_ORIGEM);
CREATE INDEX IX_PRESENCA_MATRICULA     ON PRESENCA    (ID_MATRICULA);      -- (*) frequência por aluno
CREATE INDEX IX_CONTRATO_ALUNO         ON CONTRATO    (ID_ALUNO);
CREATE INDEX IX_CONTRATO_PLANO         ON CONTRATO    (ID_PLANO);
CREATE INDEX IX_PARTICIPA_MODALIDADE   ON PARTICIPA   (ID_MODALIDADE);
CREATE INDEX IX_PAGAMENTO_CONTRATO     ON PAGAMENTO   (ID_CONTRATO);
CREATE INDEX IX_PAGAMENTO_VENC_STATUS  ON PAGAMENTO   (DT_VENCIMENTO, TP_STATUS_PAGAMENTO);  -- (*) inadimplentes e bloqueio na catraca (RNF01)
CREATE INDEX IX_PAGAMENTO_DT_PAGAMENTO ON PAGAMENTO   (DT_PAGAMENTO);      -- relatórios por período
CREATE INDEX IX_GRADUACAO_ALUNO        ON GRADUACAO   (ID_ALUNO);
CREATE INDEX IX_GRADUACAO_MODALIDADE   ON GRADUACAO   (ID_MODALIDADE);
CREATE INDEX IX_GRADUACAO_PROFESSOR    ON GRADUACAO   (ID_PROFESSOR);
CREATE INDEX IX_DESPESA_PROFESSOR      ON DESPESA     (ID_PROFESSOR);
CREATE INDEX IX_DESPESA_VENC_SITUACAO  ON DESPESA     (DT_VENCIMENTO, TP_SITUACAO_DESPESA);
CREATE INDEX IX_LOG_TABELA_REGISTRO    ON LOG_ACESSO  (NM_TABELA, ID_REGISTRO);  -- quem acessou este registro (RNF02)
CREATE INDEX IX_LOG_DT_ACESSO          ON LOG_ACESSO  (DT_ACESSO);

-- -------------------------------------------------------------------------------------
-- 3.3 FOREIGN KEY                                                       [RNF04, RE06]
-- -------------------------------------------------------------------------------------
-- [RF02, RE05] Professor vinculado a UMA modalidade existente, e suas tabelas de apoio
ALTER TABLE PROFESSOR
    ADD CONSTRAINT FK_PROFESSOR_MODALIDADE FOREIGN KEY (ID_MODALIDADE) REFERENCES MODALIDADE (ID_MODALIDADE);
ALTER TABLE EMAIL_PROFESSOR
    ADD CONSTRAINT FK_EMAIL_PROFESSOR_PROFESSOR FOREIGN KEY (ID_PROFESSOR)
        REFERENCES PROFESSOR (ID_PROFESSOR) ON DELETE CASCADE;
ALTER TABLE TELEFONE_PROFESSOR
    ADD CONSTRAINT FK_TELEFONE_PROFESSOR_PROFESSOR FOREIGN KEY (ID_PROFESSOR)
        REFERENCES PROFESSOR (ID_PROFESSOR) ON DELETE CASCADE;
ALTER TABLE ESPECIALIZACAO
    ADD CONSTRAINT FK_ESPECIALIZACAO_PROFESSOR FOREIGN KEY (ID_PROFESSOR)
        REFERENCES PROFESSOR (ID_PROFESSOR) ON DELETE CASCADE;
ALTER TABLE NIVEL_DE_EXPERIENCIA
    ADD CONSTRAINT FK_NIVEL_DE_EXPERIENCIA_PROFESSOR FOREIGN KEY (ID_PROFESSOR)
        REFERENCES PROFESSOR (ID_PROFESSOR) ON DELETE CASCADE;
ALTER TABLE REGISTRO_QUALIFICACOES
    ADD CONSTRAINT FK_REGISTRO_QUALIFICACOES_PROFESSOR FOREIGN KEY (ID_PROFESSOR)
        REFERENCES PROFESSOR (ID_PROFESSOR) ON DELETE CASCADE;

-- [RF01, RE03, RO03] Interessado ligado a uma modalidade; aluno ligado ao responsável
-- (menor) e ao interessado de origem
ALTER TABLE INTERESSADO
    ADD CONSTRAINT FK_INTERESSADO_MODALIDADE FOREIGN KEY (ID_MODALIDADE) REFERENCES MODALIDADE (ID_MODALIDADE);
ALTER TABLE ALUNO
    ADD CONSTRAINT FK_ALUNO_RESPONSAVEL FOREIGN KEY (ID_RESPONSAVEL) REFERENCES RESPONSAVEL (ID_RESPONSAVEL),
    ADD CONSTRAINT FK_ALUNO_INTERESSADO FOREIGN KEY (ID_INTERESSADO) REFERENCES INTERESSADO (ID_INTERESSADO);
ALTER TABLE EMAIL_ALUNO
    ADD CONSTRAINT FK_EMAIL_ALUNO_ALUNO FOREIGN KEY (ID_ALUNO)
        REFERENCES ALUNO (ID_ALUNO) ON DELETE CASCADE;
ALTER TABLE TELEFONE_ALUNO
    ADD CONSTRAINT FK_TELEFONE_ALUNO_ALUNO FOREIGN KEY (ID_ALUNO)
        REFERENCES ALUNO (ID_ALUNO) ON DELETE CASCADE;
ALTER TABLE PROBLEMA_SAUDE_ALUNO
    ADD CONSTRAINT FK_PROBLEMA_SAUDE_ALUNO_ALUNO FOREIGN KEY (ID_ALUNO)
        REFERENCES ALUNO (ID_ALUNO) ON DELETE CASCADE;

-- [RF03, RF06, RE04] Turma, matrícula e trancamento
ALTER TABLE TURMA
    ADD CONSTRAINT FK_TURMA_MODALIDADE FOREIGN KEY (ID_MODALIDADE) REFERENCES MODALIDADE (ID_MODALIDADE),
    ADD CONSTRAINT FK_TURMA_PROFESSOR  FOREIGN KEY (ID_PROFESSOR)  REFERENCES PROFESSOR (ID_PROFESSOR);
ALTER TABLE MATRICULA
    ADD CONSTRAINT FK_MATRICULA_ALUNO FOREIGN KEY (ID_ALUNO) REFERENCES ALUNO (ID_ALUNO),
    ADD CONSTRAINT FK_MATRICULA_TURMA FOREIGN KEY (ID_TURMA) REFERENCES TURMA (ID_TURMA);
ALTER TABLE TRANCAMENTO
    ADD CONSTRAINT FK_TRANCAMENTO_MATRICULA FOREIGN KEY (ID_MATRICULA) REFERENCES MATRICULA (ID_MATRICULA);

-- [RF05, RO07] Aula (com autorrelacionamento da reposição) e presença
ALTER TABLE AULA
    ADD CONSTRAINT FK_AULA_PROFESSOR FOREIGN KEY (ID_PROFESSOR)   REFERENCES PROFESSOR (ID_PROFESSOR),
    ADD CONSTRAINT FK_AULA_TURMA     FOREIGN KEY (ID_TURMA)       REFERENCES TURMA (ID_TURMA),
    ADD CONSTRAINT FK_AULA_ORIGEM    FOREIGN KEY (ID_AULA_ORIGEM) REFERENCES AULA (ID_AULA);
ALTER TABLE PRESENCA
    ADD CONSTRAINT FK_PRESENCA_AULA      FOREIGN KEY (ID_AULA)      REFERENCES AULA (ID_AULA),
    ADD CONSTRAINT FK_PRESENCA_MATRICULA FOREIGN KEY (ID_MATRICULA) REFERENCES MATRICULA (ID_MATRICULA);

-- [RF04, RO01, RO07] Financeiro: contrato, modalidades cobertas, parcelas e repasse
ALTER TABLE CONTRATO
    ADD CONSTRAINT FK_CONTRATO_ALUNO FOREIGN KEY (ID_ALUNO) REFERENCES ALUNO (ID_ALUNO),
    ADD CONSTRAINT FK_CONTRATO_PLANO FOREIGN KEY (ID_PLANO) REFERENCES PLANO (ID_PLANO);
ALTER TABLE PARTICIPA
    ADD CONSTRAINT FK_PARTICIPA_CONTRATO   FOREIGN KEY (ID_CONTRATO)   REFERENCES CONTRATO (ID_CONTRATO),
    ADD CONSTRAINT FK_PARTICIPA_MODALIDADE FOREIGN KEY (ID_MODALIDADE) REFERENCES MODALIDADE (ID_MODALIDADE);
ALTER TABLE PAGAMENTO
    ADD CONSTRAINT FK_PAGAMENTO_CONTRATO FOREIGN KEY (ID_CONTRATO) REFERENCES CONTRATO (ID_CONTRATO);
ALTER TABLE DESPESA
    ADD CONSTRAINT FK_DESPESA_PROFESSOR FOREIGN KEY (ID_PROFESSOR) REFERENCES PROFESSOR (ID_PROFESSOR);

-- [RF06, RE05] Graduação: aluno avaliado, professor avaliador e modalidade
ALTER TABLE GRADUACAO
    ADD CONSTRAINT FK_GRADUACAO_ALUNO      FOREIGN KEY (ID_ALUNO)      REFERENCES ALUNO (ID_ALUNO),
    ADD CONSTRAINT FK_GRADUACAO_PROFESSOR  FOREIGN KEY (ID_PROFESSOR)  REFERENCES PROFESSOR (ID_PROFESSOR),
    ADD CONSTRAINT FK_GRADUACAO_MODALIDADE FOREIGN KEY (ID_MODALIDADE) REFERENCES MODALIDADE (ID_MODALIDADE);

-- -------------------------------------------------------------------------------------
-- 3.4 CHECK
-- -------------------------------------------------------------------------------------
-- Limitações do CHECK no MySQL que explicam por que algumas regras viraram auditoria:
--  • Não aceita funções que mudam com o tempo, como CURDATE(). Por isso "menor de 18 anos
--    precisa de responsável" [RE03] e "parcela vencida deve estar ATRASADO" [RE07] são
--    verificadas pelas consultas de auditoria (Seção 9).
--  • Não compara linhas de tabelas diferentes nem conta linhas: "professor da turma deve
--    ser da modalidade da turma" [RE05], "no máximo 30 matrículas ativas" [RE01], "um único
--    contrato vigente por aluno" e "matrícula só em modalidade coberta pelo contrato" [RO01]
--    também viram auditoria (A04, A06, A12 e A11).
--  • Não pode ser usado em colunas de FK com ação ON DELETE, por isso não há CHECK
--    nas colunas de chave estrangeira.

-- [RF01, RF02, RE03] Formatos: CPF com 11 dígitos, CEP com 8, telefone com DDD (10 ou 11
-- dígitos) e datas plausíveis (autorização de imagem e atestado depois do nascimento)
ALTER TABLE ALUNO
    ADD CONSTRAINT CK_ALUNO_CPF         CHECK (CPF REGEXP '^[0-9]{11}$'),
    ADD CONSTRAINT CK_ALUNO_CEP         CHECK (NR_CEP REGEXP '^[0-9]{8}$'),
    ADD CONSTRAINT CK_ALUNO_NASCIMENTO  CHECK (DT_NASCIMENTO >= '1920-01-01'),
    ADD CONSTRAINT CK_ALUNO_DT_IMAGEM   CHECK (DT_AUTORIZACAO_IMAGEM > DT_NASCIMENTO),
    ADD CONSTRAINT CK_ALUNO_DT_ATESTADO CHECK (DT_ENTREGA_ATESTADO IS NULL OR DT_ENTREGA_ATESTADO > DT_NASCIMENTO);

ALTER TABLE RESPONSAVEL
    ADD CONSTRAINT CK_RESPONSAVEL_CPF      CHECK (CPF REGEXP '^[0-9]{11}$'),
    ADD CONSTRAINT CK_RESPONSAVEL_TELEFONE CHECK (NR_TELEFONE REGEXP '^[0-9]{10,11}$');

-- Valores monetários (seção 1.5 do README): CHECK >= 0 em VL_POR_AULA, VL_MENSALIDADE,
-- VL_MENSAL_ACORDADO, VL_ACRESCIMO_MODALIDADE, VL_MULTA_RESCISORIA, VL_DEVIDO, VL_PAGO,
-- VL_MULTA e VL_TAXA_GRADUACAO. O CHECK impede valor negativo e aceita o zero, porque há
-- casos sem cobrança: o CEO não recebe por aula (VL_POR_AULA = 0) e um desconto de 100%,
-- permitido em PC_DESCONTO, zera a mensalidade. As colunas opcionais continuam aceitando
-- NULL. VL_DESPESA continua > 0: não existe conta a pagar de valor zero.

-- [RF02, RO07] Valor por aula não negativo: base do repasse (o do CEO é 0, PN11)
ALTER TABLE PROFESSOR
    ADD CONSTRAINT CK_PROFESSOR_CPF         CHECK (CPF REGEXP '^[0-9]{11}$'),
    ADD CONSTRAINT CK_PROFESSOR_CEP         CHECK (NR_CEP REGEXP '^[0-9]{8}$'),
    ADD CONSTRAINT CK_PROFESSOR_NASCIMENTO  CHECK (DT_NASCIMENTO >= '1920-01-01'),
    ADD CONSTRAINT CK_PROFESSOR_VL_POR_AULA CHECK (VL_POR_AULA >= 0);

-- [RO03] Telefone válido, porque ele faz parte da identificação única do interessado
ALTER TABLE INTERESSADO
    ADD CONSTRAINT CK_INTERESSADO_TELEFONE CHECK (NR_TELEFONE REGEXP '^[0-9]{10,11}$');

-- [RF01, RF02] Contatos em formato válido
ALTER TABLE EMAIL_ALUNO        ADD CONSTRAINT CK_EMAIL_ALUNO_FORMATO        CHECK (DS_EMAIL LIKE '%_@_%._%');
ALTER TABLE EMAIL_PROFESSOR    ADD CONSTRAINT CK_EMAIL_PROFESSOR_FORMATO    CHECK (DS_EMAIL LIKE '%_@_%._%');
ALTER TABLE TELEFONE_ALUNO     ADD CONSTRAINT CK_TELEFONE_ALUNO_FORMATO     CHECK (NR_TELEFONE REGEXP '^[0-9]{10,11}$');
ALTER TABLE TELEFONE_PROFESSOR ADD CONSTRAINT CK_TELEFONE_PROFESSOR_FORMATO CHECK (NR_TELEFONE REGEXP '^[0-9]{10,11}$');

-- [RF03, RE02] Domínio fechado às 6 modalidades e quórum de referência positivo
ALTER TABLE MODALIDADE
    ADD CONSTRAINT CK_MODALIDADE_NOME CHECK (NM_MODALIDADE IN
        ('Muay Thai','Kickboxing','Jiu-Jitsu','Boxe','Capoeira','No-Gi')),
    ADD CONSTRAINT CK_MODALIDADE_QT_MINIMA CHECK (QT_MINIMA_REFERENCIA > 0);

-- [RF03, RE01] Término depois do início e no máximo 30 alunos no tatame
ALTER TABLE TURMA
    ADD CONSTRAINT CK_TURMA_HORARIO    CHECK (HR_FIM > HR_INICIO),
    ADD CONSTRAINT CK_TURMA_CAPACIDADE CHECK (QT_CAPACIDADE_MAXIMA BETWEEN 1 AND 30);

-- [RE04] Os retornos não podem ser antes do início do afastamento
ALTER TABLE TRANCAMENTO
    ADD CONSTRAINT CK_TRANCAMENTO_RETORNO_PREVISTO CHECK (DT_RETORNO_PREVISTA > DT_INICIO),
    ADD CONSTRAINT CK_TRANCAMENTO_RETORNO_EFETIVO  CHECK (DT_RETORNO_EFETIVA IS NULL OR DT_RETORNO_EFETIVA > DT_INICIO);

-- [RO01] Ciclos comercializados (1, 3, 6 e 12 meses), valor não negativo, desconto entre
-- 0% e 100% e Plano Família a partir de 2 pessoas
ALTER TABLE PLANO
    ADD CONSTRAINT CK_PLANO_DURACAO       CHECK (QT_DURACAO_MESES IN (1, 3, 6, 12)),
    ADD CONSTRAINT CK_PLANO_VL_MENSALIDADE CHECK (VL_MENSALIDADE >= 0),
    ADD CONSTRAINT CK_PLANO_PC_DESCONTO   CHECK (PC_DESCONTO BETWEEN 0 AND 100),
    ADD CONSTRAINT CK_PLANO_QT_PESSOAS    CHECK (QT_MINIMA_PESSOAS IS NULL OR QT_MINIMA_PESSOAS >= 2);

-- [RF04, RO01, RO04] Vigência coerente, valores não negativos e multa rescisória só
-- quando houve cancelamento
ALTER TABLE CONTRATO
    ADD CONSTRAINT CK_CONTRATO_VIGENCIA     CHECK (DT_FIM > DT_INICIO),
    ADD CONSTRAINT CK_CONTRATO_VL_MENSAL    CHECK (VL_MENSAL_ACORDADO >= 0),
    ADD CONSTRAINT CK_CONTRATO_VL_ACRESCIMO CHECK (VL_ACRESCIMO_MODALIDADE IS NULL OR VL_ACRESCIMO_MODALIDADE >= 0),
    ADD CONSTRAINT CK_CONTRATO_CANCELAMENTO CHECK (DT_CANCELAMENTO IS NULL OR DT_CANCELAMENTO >= DT_INICIO),
    ADD CONSTRAINT CK_CONTRATO_MULTA        CHECK (VL_MULTA_RESCISORIA IS NULL
                                                   OR (VL_MULTA_RESCISORIA >= 0 AND DT_CANCELAMENTO IS NOT NULL));

-- [RF04, RO04, RO06, RE07] Valores não negativos e coerência entre a situação e os dados
-- da liquidação: parcela PAGO precisa ter data, valor e forma; parcela não paga não pode
-- ter nenhum deles. Assim a situação usada no bloqueio (RE07) nunca contradiz os valores.
ALTER TABLE PAGAMENTO
    ADD CONSTRAINT CK_PAGAMENTO_VL_DEVIDO CHECK (VL_DEVIDO >= 0),
    ADD CONSTRAINT CK_PAGAMENTO_VL_PAGO   CHECK (VL_PAGO IS NULL OR VL_PAGO >= 0),
    ADD CONSTRAINT CK_PAGAMENTO_VL_MULTA  CHECK (VL_MULTA IS NULL OR VL_MULTA >= 0),
    ADD CONSTRAINT CK_PAGAMENTO_VL_TAXA   CHECK (VL_TAXA_GRADUACAO IS NULL OR VL_TAXA_GRADUACAO >= 0),
    ADD CONSTRAINT CK_PAGAMENTO_LIQUIDACAO CHECK (
           (TP_STATUS_PAGAMENTO = 'PAGO'
              AND DT_PAGAMENTO IS NOT NULL AND VL_PAGO IS NOT NULL AND TP_FORMA_PAGAMENTO IS NOT NULL)
        OR (TP_STATUS_PAGAMENTO <> 'PAGO'
              AND DT_PAGAMENTO IS NULL AND VL_PAGO IS NULL AND TP_FORMA_PAGAMENTO IS NULL));

-- [RF06, RO06] Faixa só no exame de faixa (o Boxe tem análise técnica, sem faixa) e
-- motivo só na reprovação. Os valores de TP_AVALIACAO já são fechados pelo ENUM.
ALTER TABLE GRADUACAO
    ADD CONSTRAINT CK_GRADUACAO_FAIXA CHECK (
           (TP_AVALIACAO = 'EXAME_FAIXA'     AND TP_NIVEL_FAIXA IS NOT NULL)
        OR (TP_AVALIACAO = 'ANALISE_TECNICA' AND TP_NIVEL_FAIXA IS NULL)),
    ADD CONSTRAINT CK_GRADUACAO_MOTIVO CHECK (
           (TP_RESULTADO = 'REPROVADO' AND DS_MOTIVO_REPROVACAO IS NOT NULL)
        OR (TP_RESULTADO = 'APROVADO'  AND DS_MOTIVO_REPROVACAO IS NULL));

-- [RF04, RO07] Categorias de despesa, valor positivo e coerência da liquidação
ALTER TABLE DESPESA
    ADD CONSTRAINT CK_DESPESA_CATEGORIA CHECK (DS_CATEGORIA IN
        ('ALUGUEL','CONSUMO','MANUTENCAO','COMPRAS','PROFESSORES')),
    ADD CONSTRAINT CK_DESPESA_VL_DESPESA CHECK (VL_DESPESA > 0),
    ADD CONSTRAINT CK_DESPESA_VL_PAGO    CHECK (VL_PAGO IS NULL OR VL_PAGO > 0),
    ADD CONSTRAINT CK_DESPESA_LIQUIDACAO CHECK (
           (TP_SITUACAO_DESPESA = 'PAGO'  AND DT_PAGAMENTO IS NOT NULL AND VL_PAGO IS NOT NULL)
        OR (TP_SITUACAO_DESPESA <> 'PAGO' AND DT_PAGAMENTO IS NULL     AND VL_PAGO IS NULL));

-- [RNF02] Os dois perfis que podem aparecer no log já são fechados pelo ENUM de TP_PERFIL.

-- -------------------------------------------------------------------------------------
-- 3.5 PERFIS DE ACESSO (exemplo comentado — aplicado na implantação)       [RNF02, RE06]
-- -------------------------------------------------------------------------------------
-- Os perfis seguem a matriz CRUD do dicionário de dados (Seção 5) e a regra do log
-- (Seção 6). Ficam comentados porque criar papéis e usuários exige privilégio de
-- administrador do servidor e senhas reais. Para testar, tire os "--" e rode como root.
--
-- Cada perfil é um papel (ROLE) do MySQL 8 e cada pessoa tem o seu usuário, com o mesmo
-- login gravado em LOG_ACESSO.NM_USUARIO. O CEO tem dois logins: admin.gestor
-- (Administração) e prof.muaythai (Professor, para as aulas e os exames de Muay Thai).
--
-- O que os GRANTs garantem:
--  • Não há DELETE em CONTRATO, PARTICIPA, PAGAMENTO e DESPESA (retenção fiscal de 5 anos,
--    RE06 e RNF05) nem em TRANCAMENTO, AULA, PRESENCA e GRADUACAO (histórico). Onde o
--    DELETE existe, a FK RESTRICT ainda impede apagar o que tem histórico ligado.
--  • O professor lê de ALUNO só ID_ALUNO, NM_COMPLETO e TP_STATUS_ALUNO (sem CPF,
--    nascimento, endereço e contatos) e as restrições de PROBLEMA_SAUDE_ALUNO. Não vê
--    RESPONSAVEL, CONTRATO, PAGAMENTO, DESPESA, TRANCAMENTO nem LOG_ACESSO.
--  • GRADUACAO é registrada pelo professor; a Administração só a lê.
--  • LOG_ACESSO recebe INSERT apenas da conta técnica do sistema, e ninguém o altera nem o
--    apaga. Se quem é auditado pudesse editar ou apagar o próprio rastro, o log não
--    provaria nada (LGPD, art. 37). A Administração só o lê.
--  • "Só da própria turma" e "só da própria modalidade" são filtros de linha: o GRANT do
--    MySQL não chega à linha, então esse filtro fica com a aplicação, e a auditoria A04
--    confere professor x modalidade.
--
--   CREATE ROLE 'perfil_administracao', 'perfil_professor';
--
--   -- Administração (CEO): C R U D onde a exclusão física é permitida
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.ALUNO                  TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.EMAIL_ALUNO            TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.TELEFONE_ALUNO         TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.PROBLEMA_SAUDE_ALUNO   TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.RESPONSAVEL            TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.INTERESSADO            TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.PROFESSOR              TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.EMAIL_PROFESSOR        TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.TELEFONE_PROFESSOR     TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.ESPECIALIZACAO         TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.NIVEL_DE_EXPERIENCIA   TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.REGISTRO_QUALIFICACOES TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.MODALIDADE             TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.PLANO                  TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.TURMA                  TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.MATRICULA              TO 'perfil_administracao';
--   -- Administração: C R U, sem DELETE (retenção e histórico)
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.CONTRATO    TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.PARTICIPA   TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.PAGAMENTO   TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.DESPESA     TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.TRANCAMENTO TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.AULA        TO 'perfil_administracao';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.PRESENCA    TO 'perfil_administracao';
--   -- Administração: só leitura
--   GRANT SELECT ON ACADEMIA_BFL.GRADUACAO  TO 'perfil_administracao';
--   GRANT SELECT ON ACADEMIA_BFL.LOG_ACESSO TO 'perfil_administracao';
--
--   -- Professor: só o necessário para a aula (privilégio por coluna em ALUNO e PROFESSOR)
--   GRANT SELECT (ID_ALUNO, NM_COMPLETO, TP_STATUS_ALUNO) ON ACADEMIA_BFL.ALUNO TO 'perfil_professor';
--   GRANT SELECT ON ACADEMIA_BFL.PROBLEMA_SAUDE_ALUNO TO 'perfil_professor';
--   GRANT SELECT (ID_PROFESSOR, ID_MODALIDADE, NM_COMPLETO) ON ACADEMIA_BFL.PROFESSOR TO 'perfil_professor';
--   GRANT SELECT ON ACADEMIA_BFL.MODALIDADE TO 'perfil_professor';
--   GRANT SELECT ON ACADEMIA_BFL.PLANO      TO 'perfil_professor';
--   GRANT SELECT ON ACADEMIA_BFL.TURMA      TO 'perfil_professor';
--   GRANT SELECT ON ACADEMIA_BFL.MATRICULA  TO 'perfil_professor';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.INTERESSADO TO 'perfil_professor';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.AULA        TO 'perfil_professor';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.PRESENCA    TO 'perfil_professor';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.GRADUACAO   TO 'perfil_professor';
--
--   -- Usuários: um por pessoa (a senha real é definida na implantação)
--   CREATE USER 'admin.gestor'@'%'    IDENTIFIED BY '<senha forte>' DEFAULT ROLE 'perfil_administracao';
--   CREATE USER 'prof.muaythai'@'%'   IDENTIFIED BY '<senha forte>' DEFAULT ROLE 'perfil_professor';
--   CREATE USER 'prof.kickboxing'@'%' IDENTIFIED BY '<senha forte>' DEFAULT ROLE 'perfil_professor';
--   CREATE USER 'prof.jiujitsu'@'%'   IDENTIFIED BY '<senha forte>' DEFAULT ROLE 'perfil_professor';
--   CREATE USER 'prof.boxe'@'%'       IDENTIFIED BY '<senha forte>' DEFAULT ROLE 'perfil_professor';
--   CREATE USER 'prof.capoeira'@'%'   IDENTIFIED BY '<senha forte>' DEFAULT ROLE 'perfil_professor';
--   CREATE USER 'prof.nogi'@'%'       IDENTIFIED BY '<senha forte>' DEFAULT ROLE 'perfil_professor';
--
--   -- Conta técnica da aplicação: a única que grava o log, e só com INSERT
--   CREATE USER 'sistema_bfl'@'localhost' IDENTIFIED BY '<senha forte>';
--   GRANT INSERT ON ACADEMIA_BFL.LOG_ACESSO TO 'sistema_bfl'@'localhost';


-- =====================================================================================
-- 4. MASSA DE DADOS                                    [RF01 a RF06 — dados para testar tudo]
-- =====================================================================================
-- PRIVACIDADE: todos os dados são FICTÍCIOS. Nenhum nome, CPF, telefone ou valor real da
-- academia foi usado. Os nomes foram sorteados de listas de nomes comuns; os CPFs têm o
-- dígito verificador propositalmente errado (não pertencem a ninguém); os e-mails usam o
-- domínio example.com, reservado para exemplos; os telefones e CEPs são aleatórios.
-- Até o gestor (professor 1) tem nome fictício.
--
-- DATA DE REFERÊNCIA: 01/11/2026. Os dados mostram a academia nesse dia: parcelas de
-- outubro já vencidas, parcelas de novembro ainda a vencer, aulas de outubro registradas.
--
-- VOLUME x REALIDADE DA ACADEMIA (seção 1.2 — Contexto e porte)
-- A quantidade de cada tabela segue a volumetria informada pelo gestor, e não um número
-- fixo: tabelas de domínio têm o tamanho real (6 modalidades, 21 turmas) e as tabelas de
-- movimento cobrem um período curto e completo (ago a nov/2026), o suficiente para as
-- consultas por mês terem o que comparar sem inflar o banco artificialmente.
--
--   Tabela                Qtde  Justificativa
--   MODALIDADE              6  6 artes marciais ativas (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira, No-Gi)
--   PROFESSOR               6  1 gestor que dá aula de Muay Thai (VL_POR_AULA = 0) + 5 prestadores de serviço
--   TURMA                  21  4 turmas por dia de segunda a sexta + a turma única de Capoeira no sábado (PN06)
--   PLANO                   8  4 ciclos (mensal, trimestral, semestral, anual) x versão individual e Família
--   ALUNO                  92  faixa de 80 a 100 alunos; 83 ativos, 6 inativos e 3 trancados
--   RESPONSAVEL            11  14 alunos menores; irmãos dividem o mesmo responsável
--   CONTRATO               92  86 vigentes (faixa de 80 a 100, ativos e trancados) + 6 cancelados;
--                              um contrato por aluno, inclusive no Plano Família. Exceções propositais:
--                              o aluno 92 está sem contrato (A01) e o aluno 9 tem dois vigentes (A12)
--   PARTICIPA             104  cada contrato cobre 1 modalidade; alguns têm modalidade extra
--   MATRICULA             204  aluno treina em 1 a 3 turmas de cada modalidade do contrato (188 ativas,
--                              média de 9 por turma, a maioria acima do quórum mínimo) + histórico
--   TRANCAMENTO             6  afastamentos por lesão/razão médica ao longo de 2026
--   PAGAMENTO             324  80 a 83 faturas por mês (uma por contrato vigente, faixa de 80 a 100)
--                              x 4 meses (ago, set, out e nov/2026)
--   INTERESSADO            24  2 a 4 aulas experimentais por semana (8 a 16 por mês) x ~2 meses
--   AULA                   85  20 turmas com aula em outubro, uma vez por semana, sem o feriado de 12/10
--                              (a 21ª acabou de abrir) + 1 reposição
--   PRESENCA              704  uma linha por matrícula ativa em cada aula de outubro (a reposição não gera presença)
--   GRADUACAO              28  exames de faixa trimestrais (dez/2025 a out/2026) + análises de Boxe
--   DESPESA                50  fixas mensais + compras semanais de limpeza + repasse a 5 professores
--   LOG_ACESSO             20  amostra de 1 mês de acessos a dados pessoais
--   EMAIL_ALUNO           100  pelo menos 1 por aluno (1,n)
--   TELEFONE_ALUNO        123  pelo menos 1 por aluno; menores com o telefone do responsável
--   PROBLEMA_SAUDE_ALUNO   94  pelo menos 1 por aluno ('nenhum' quando não há)
--   Apoio do professor     50  e-mails, telefones, especializações, níveis e qualificações (1,n)
--   TOTAL                2152  registros
--
-- VARIEDADE PARA OS TESTES (situações reais, não só o caso comum)
--   • Alunos ATIVO, INATIVO (contrato cancelado) e TRANCADO; menores com responsável;
--     familiares no Plano Família, cada um com o seu contrato; alunos que vieram da aula
--     experimental.
--   • Contratos de todos os planos, com e sem modalidade extra; cancelamentos com e sem
--     multa; um plano (Família Anual) sem nenhuma venda.
--   • Parcelas pagas em dia, pagas com atraso (com multa nos planos longos), em atraso,
--     a vencer e pagas antecipadamente; 1ª parcela no 5º dia útil seguinte à assinatura;
--     parcelas com taxa de exame de faixa (valor por faixa); pagamentos por Pix, crédito e
--     débito; um contrato cancelado deixando dívida.
--   • Matrículas ATIVA, TRANCADA, ENCERRADA (troca de turma) e CANCELADA; uma turma
--     recém-aberta sem alunos e uma turma abaixo do quórum.
--   • Aulas com substituição de professor e com reposição (sem presença); alunos com
--     frequência baixa em uma das modalidades.
--   • Graduações aprovadas e reprovadas, exame de faixa e análise técnica (Boxe).
--   • Interessados convertidos, desistentes e pendentes; despesas pagas, a vencer e atrasada.
--
-- CASOS PROPOSITAIS PARA AS CONSULTAS DE AUDITORIA (Seção 9)
-- São erros que acontecem na rotina e que nenhuma constraint consegue barrar. Estão
-- descritos no cabeçalho de cada tabela abaixo:
--   A01 aluno matriculado sem contrato (RO02)        A08 cancelamento sem multa (RO04)
--   A02 presença de aluno bloqueado (RE07)           A09 convertido sem aluno (RO03)
--   A03 presença durante trancamento (RE04)          A10 desconto de balcão (RO01)
--   A04 aula com professor de outra mod. (RE05)      A11 modalidade fora do contrato (RO01)
--   A05 aluno sem atestado (RE03)                    A12 dois contratos vigentes (RO01)
--   A06 turma vazia ou abaixo do quórum (RE02)       A13 atraso sem multa em plano longo (RO04)
--   A07 parcela vencida ainda PENDENTE (RE07)
--
-- ORDEM DOS INSERTS: primeiro as tabelas "pai" (sem FK), depois as que dependem delas.
-- Os IDs são informados explicitamente para que as referências entre tabelas fiquem claras.
-- =====================================================================================

-- -------------------------------------------------------------------------------------
-- 4.1 MODALIDADE (6) [RF03, RE02, RO06]
-- As 6 modalidades ativas da academia, com o quórum de referência informado pelo gestor.
-- Boxe é a única sem sistema de faixas (usa análise técnica, RO06).
-- -------------------------------------------------------------------------------------
INSERT INTO MODALIDADE (ID_MODALIDADE, NM_MODALIDADE, QT_MINIMA_REFERENCIA, TP_SITUACAO_MODALIDADE, IN_POSSUI_SISTEMA_FAIXAS, DT_INICIO_AULAS) VALUES
    (1, 'Muay Thai', 4, 'ATIVA', TRUE, '2018-03-05'),
    (2, 'Kickboxing', 8, 'ATIVA', TRUE, '2019-02-04'),
    (3, 'Jiu-Jitsu', 8, 'ATIVA', TRUE, '2018-03-05'),
    (4, 'Boxe', 6, 'ATIVA', FALSE, '2020-08-03'),
    (5, 'Capoeira', 10, 'ATIVA', TRUE, '2021-03-01'),
    (6, 'No-Gi', 8, 'ATIVA', TRUE, '2023-07-03');

-- -------------------------------------------------------------------------------------
-- 4.2 PROFESSOR (6) e tabelas de apoio [RF02, RE05, RO07]
-- O professor 1 representa o gestor (CEO), que também dá as aulas de Muay Thai e tem
-- VL_POR_AULA = 0, porque não recebe por aula (PN11); os outros 5 são prestadores de serviço
-- e recebem o mesmo valor por aula. Nomes, CPFs, telefones e endereços são fictícios.
-- -------------------------------------------------------------------------------------
INSERT INTO PROFESSOR (ID_PROFESSOR, ID_MODALIDADE, CPF, NM_COMPLETO, DT_NASCIMENTO, VL_POR_AULA, NR_CEP, DS_RUA, NR_LOGRADOURO, NM_BAIRRO) VALUES
    (1, 1, '63074003192', 'Lucas Batista Gomes', '1979-04-18', 0.00, '08230935', 'Rua das Acácias', '533', 'Cangaíba'),
    (2, 2, '94825696908', 'Carolina Nunes Carvalho', '1988-09-02', 80.00, '08082932', 'Rua Tangará', '842', 'Vila Carrão'),
    (3, 3, '53240316759', 'Fábio Macedo Freitas', '1985-01-27', 80.00, '08765458', 'Rua das Camélias', '232', 'Guaianases'),
    (4, 4, '80480851817', 'Jonas Mendes Nunes', '1990-06-11', 80.00, '08700062', 'Avenida dos Jasmins', '1522', 'Vila Matilde'),
    (5, 5, '66651861008', 'Igor Machado Cardoso', '1983-11-30', 80.00, '03099465', 'Avenida Cerejeira', '487', 'Água Rasa'),
    (6, 6, '87843089050', 'Gabriela Vieira Rodrigues', '1994-03-08', 80.00, '08826508', 'Rua das Acácias', '1850', 'Vila Matilde');

INSERT INTO EMAIL_PROFESSOR (DS_EMAIL, ID_PROFESSOR) VALUES
    ('lucas.gomes.prof@example.com', 1),
    ('lucas.gomes@example.com', 1),
    ('carolina.carvalho@example.com', 2),
    ('fabio.freitas.prof@example.com', 3),
    ('fabio.freitas@example.com', 3),
    ('jonas.nunes@example.com', 4),
    ('igor.cardoso@example.com', 5),
    ('gabriela.rodrigues@example.com', 6);

INSERT INTO TELEFONE_PROFESSOR (NR_TELEFONE, ID_PROFESSOR) VALUES
    ('1125920472', 1),
    ('11932271681', 1),
    ('11943804605', 2),
    ('11955885616', 3),
    ('11961558957', 4),
    ('1122243241', 5),
    ('11961886490', 5),
    ('11941980860', 6);

INSERT INTO ESPECIALIZACAO (DS_ESPECIALIZACAO, ID_PROFESSOR) VALUES
    ('Defesa pessoal', 1),
    ('Kickboxing', 1),
    ('Muay Thai', 1),
    ('Condicionamento físico', 2),
    ('Kickboxing', 2),
    ('Jiu-Jitsu', 3),
    ('Jiu-Jitsu infantil', 3),
    ('No-Gi', 3),
    ('Boxe', 4),
    ('Preparação física', 4),
    ('Capoeira Angola', 5),
    ('Capoeira infantil', 5),
    ('Capoeira Regional', 5),
    ('Jiu-Jitsu', 6),
    ('No-Gi', 6),
    ('Wrestling', 6);

INSERT INTO NIVEL_DE_EXPERIENCIA (DS_NIVEL_EXPERIENCIA, ID_PROFESSOR) VALUES
    ('22 anos de prática', 1),
    ('Kru - Prajied Preto', 1),
    ('Faixa preta 2º dan', 2),
    ('Faixa preta 3º grau', 3),
    ('Ex-atleta amador - 15 anos de treino', 4),
    ('Contramestre', 5),
    ('Faixa marrom de Jiu-Jitsu', 6);

INSERT INTO REGISTRO_QUALIFICACOES (DS_REGISTRO_QUALIFICACOES, ID_PROFESSOR) VALUES
    ('Curso de arbitragem de Muay Thai pela federação estadual (2016)', 1),
    ('Curso de primeiros socorros (2025)', 1),
    ('Atleta de competições estaduais de 2008 a 2016', 2),
    ('Graduada em Educação Física (2011)', 2),
    ('Certificado de professor pela confederação de Jiu-Jitsu (2014)', 3),
    ('Curso de primeiros socorros (2024)', 3),
    ('Curso de técnico de Boxe (2019)', 4),
    ('Graduado em Educação Física (2013)', 4),
    ('25 anos de prática de capoeira', 5),
    ('Oficinas de musicalidade (berimbau e atabaque)', 5),
    ('Medalhista em campeonatos regionais de grappling (2021-2024)', 6);

-- -------------------------------------------------------------------------------------
-- 4.3 RESPONSAVEL (11) [RF01, RE03, RO01]
-- Responsáveis legais dos alunos menores de 18 anos (RE03).
-- No Plano Família, o responsável pelo menor é um familiar que também é aluno, por isso o CPF
-- se repete em RESPONSAVEL e em ALUNO. Cada familiar tem o próprio CONTRATO.
-- -------------------------------------------------------------------------------------
INSERT INTO RESPONSAVEL (ID_RESPONSAVEL, CPF, NM_RESPONSAVEL, NR_TELEFONE, DS_PARENTESCO) VALUES
    (1, '32218340669', 'Leonardo Queiroz Gomes', '11937896565', 'Pai'),
    (2, '06817943190', 'Ricardo Mendes Pereira', '11902850460', 'Avô'),
    (3, '74194431757', 'Marcelo Oliveira Rocha', '11972573947', 'Tio'),
    (4, '00552788823', 'Vitor Cavalcanti Farias', '11946935394', 'Pai'),
    (5, '67836914780', 'Sabrina Batista Correia', '11947425454', 'Mãe'),
    (6, '10683770633', 'Fernando Barbosa Macedo', '11982220291', 'Avô'),
    (7, '01146676432', 'Débora Nascimento Macedo', '11956276427', 'Mãe'),
    (8, '64361731141', 'Caio Moreira Nascimento', '11921563398', 'Avô'),
    (9, '90143028568', 'Viviane Correia Moura', '11963520220', 'Mãe'),
    (10, '40738498929', 'Hugo Rodrigues Siqueira', '11953706412', 'Pai'),
    (11, '75510711460', 'Vanessa Rodrigues Cavalcanti', '11960555531', 'Mãe');

-- -------------------------------------------------------------------------------------
-- 4.4 INTERESSADO (24) [RF01, RO03]
-- Aulas experimentais de set/2026 a nov/2026 (cerca de 12 por mês, dentro da faixa de 8 a 16).
-- A data e o horário de cada uma coincidem com uma turma da modalidade na grade (PN06); o
-- pré-cadastro pode ser feito antes, no agendamento, por isso o ID não segue a data da aula.
-- CONVERTIDO = virou aluno | ENCERRADO = desistiu | PENDENTE = ainda vai decidir ou a aula já está agendada.
-- Cenário de auditoria: o interessado 19 está CONVERTIDO, mas não tem aluno vinculado (A09).
-- -------------------------------------------------------------------------------------
INSERT INTO INTERESSADO (ID_INTERESSADO, ID_MODALIDADE, NM_INTERESSADO, TP_STATUS, NR_TELEFONE, DT_AULA, HR_AULA) VALUES
    (1, 4, 'Daniel Vieira Queiroz', 'CONVERTIDO', '11951341935', '2026-09-01', '18:00:00'),
    (2, 5, 'Beatriz Ferreira Almeida', 'ENCERRADO', '11988983743', '2026-09-05', '14:00:00'),
    (3, 4, 'Carolina Freitas Machado', 'CONVERTIDO', '11904838041', '2026-09-03', '18:00:00'),
    (4, 5, 'Tatiane Mendes Dias', 'CONVERTIDO', '11933669288', '2026-09-19', '14:00:00'),
    (5, 1, 'Samuel Campos Macedo', 'ENCERRADO', '11977770387', '2026-09-21', '07:00:00'),
    (6, 6, 'Vitor Araújo Lima', 'ENCERRADO', '11934099404', '2026-09-24', '20:00:00'),
    (7, 2, 'Priscila Macedo Oliveira', 'ENCERRADO', '11951863907', '2026-09-25', '18:00:00'),
    (8, 1, 'Eduardo Pereira Rodrigues', 'CONVERTIDO', '11983541274', '2026-09-25', '19:00:00'),
    (9, 4, 'Viviane Oliveira Costa', 'ENCERRADO', '11902641388', '2026-10-01', '18:00:00'),
    (10, 6, 'Fernanda Brandão Rodrigues', 'CONVERTIDO', '11977475313', '2026-10-01', '20:00:00'),
    (11, 3, 'Aline Campos Tavares', 'CONVERTIDO', '11937219453', '2026-10-02', '20:00:00'),
    (12, 5, 'Renata Lopes Gomes', 'ENCERRADO', '11987508056', '2026-10-03', '14:00:00'),
    (13, 2, 'Viviane Teixeira Macedo', 'CONVERTIDO', '11907884745', '2026-10-05', '19:00:00'),
    (14, 6, 'Beatriz Batista Costa', 'CONVERTIDO', '11977276268', '2026-10-08', '20:00:00'),
    (15, 2, 'Cláudia Nascimento Teixeira', 'CONVERTIDO', '11994863739', '2026-10-09', '18:00:00'),
    (16, 3, 'Rafael Ramos Carvalho', 'ENCERRADO', '11935402820', '2026-10-13', '07:00:00'),
    (17, 4, 'Alexandre Almeida Freitas', 'CONVERTIDO', '11958006138', '2026-10-13', '18:00:00'),
    (18, 3, 'Otávio Gomes Mendes', 'ENCERRADO', '11969810319', '2026-10-14', '20:00:00'),
    (19, 1, 'Bianca Nascimento Macedo', 'CONVERTIDO', '11978506123', '2026-10-20', '19:00:00'),
    (20, 2, 'Jéssica Almeida Cardoso', 'PENDENTE', '11908284203', '2026-10-23', '18:00:00'),
    (21, 3, 'Túlio Dias Freitas', 'PENDENTE', '11936389323', '2026-10-27', '07:00:00'),
    (22, 3, 'Jéssica Costa Campos', 'PENDENTE', '11940516049', '2026-10-28', '20:00:00'),
    (23, 1, 'Talita Monteiro Lima', 'PENDENTE', '11926948764', '2026-11-05', '19:00:00'),
    (24, 2, 'Leonardo Farias Dias', 'PENDENTE', '11998604055', '2026-11-06', '18:00:00');

-- -------------------------------------------------------------------------------------
-- 4.5 ALUNO (92) e tabelas de apoio [RF01, RE03, RE06, RNF02]
-- Situação: 83 ATIVO, 6 INATIVO (contrato cancelado), 3 TRANCADO.
-- 14 alunos são menores de idade e têm responsável; 8 deles estão no Plano Família, cada um com o seu contrato.
-- 10 alunos vieram da aula experimental (ID_INTERESSADO preenchido).
-- DT_AUTORIZACAO_IMAGEM é a data do cadastro, quando o CEO pergunta sobre o uso de imagem.
-- Atestado de aptidão física (RE03): todos os alunos entregaram, alguns dias antes da matrícula,
-- exceto 3 casos propositais, que a auditoria A05 deve listar: o aluno 53 (menor, matriculado em
-- 26/01/2026) e os alunos 90 e 92 (adultos, matriculados em 15/10 e 28/10).
-- Cenários de auditoria: alunos 53, 90 e 92 sem atestado (A05);
-- aluno 92 foi matriculado em 28/10 sem contrato (A01).
-- Os dependentes usam o telefone e o e-mail do responsável: a PK composta (valor + ID_ALUNO)
-- permite o mesmo telefone em alunos diferentes, mas não repetido no mesmo aluno.
-- -------------------------------------------------------------------------------------
INSERT INTO ALUNO (ID_ALUNO, ID_RESPONSAVEL, ID_INTERESSADO, DT_AUTORIZACAO_IMAGEM, CPF, NM_COMPLETO, DT_NASCIMENTO, DS_HISTORICO_TREINO, IN_ACEITE_USO_IMAGEM, TP_STATUS_ALUNO, DT_ENTREGA_ATESTADO, NR_CEP, NR_LOGRADOURO, DS_RUA, NM_BAIRRO) VALUES
    (1, NULL, NULL, '2024-04-03', '20742934398', 'Beatriz Barbosa Ramos', '2001-09-26', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', '2024-03-27', '03284345', '609', 'Rua Manacá', 'Ermelino Matarazzo'),
    (2, NULL, NULL, '2024-06-07', '77697705354', 'Larissa Freitas Brandão', '1976-02-25', 'Ex-praticante de karatê (faixa verde).', TRUE, 'ATIVO', '2024-06-05', '03180113', '161', 'Rua Manacá', 'Itaquera'),
    (3, NULL, NULL, '2024-07-12', '71832122578', 'Ricardo Silva Moura', '1972-09-10', 'Fez capoeira na escola por 3 anos.', FALSE, 'ATIVO', '2024-07-03', '08621794', '698', 'Avenida dos Jasmins', 'Vila Formosa'),
    (4, NULL, NULL, '2024-08-05', '67759336244', 'Renato Lopes Mendes', '1990-07-02', 'Nunca treinou; procurou a academia para defesa pessoal.', FALSE, 'ATIVO', '2024-08-01', '03099660', '1131', 'Rua Quaresmeira', 'Aricanduva'),
    (5, NULL, NULL, '2024-10-04', '90322409849', 'Gabriela Santos Carvalho', '1988-10-09', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', '2024-09-23', '08074437', '499', 'Rua Manacá', 'Vila Matilde'),
    (6, NULL, NULL, '2024-10-25', '56691475866', 'Daniela Correia Costa', '2002-04-22', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', '2024-10-19', '08395582', '776', 'Rua Beija-flor', 'Penha'),
    (7, NULL, NULL, '2024-11-12', '89890624959', 'Murilo Barbosa Costa', '1994-08-30', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', '2024-11-11', '03401683', '988', 'Rua das Violetas', 'Cidade Patriarca'),
    (8, NULL, NULL, '2024-11-25', '65743830410', 'Lucas Ferreira Cavalcanti', '1989-06-26', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', '2024-11-16', '08778837', '330', 'Rua Jequitibá', 'Guaianases'),
    (9, NULL, NULL, '2024-11-28', '83043033911', 'Vinícius Lopes Almeida', '1974-09-18', 'Faixa azul de Jiu-Jitsu em outra academia; parado há 2 anos.', TRUE, 'ATIVO', '2024-11-25', '08232031', '116', 'Rua Beija-flor', 'Água Rasa'),
    (10, NULL, NULL, '2024-12-16', '99538026517', 'Murilo Vieira Ramos', '1992-03-17', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', '2024-12-06', '08631085', '211', 'Rua Beija-flor', 'Cidade Patriarca'),
    (11, NULL, NULL, '2024-12-20', '21576968933', 'Larissa Cardoso Queiroz', '1999-06-14', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2024-12-15', '03140389', '892', 'Travessa das Orquídeas', 'Água Rasa'),
    (12, NULL, NULL, '2024-12-23', '49813312204', 'Camila Lima Vieira', '1992-05-01', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', '2024-12-22', '08804282', '1229', 'Avenida Cerejeira', 'Aricanduva'),
    (13, NULL, NULL, '2025-01-02', '94879025344', 'Bruno Cardoso Moura', '1993-02-24', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', '2024-12-26', '08638769', '386', 'Rua dos Cravos', 'Vila Carrão'),
    (14, NULL, NULL, '2025-01-02', '19252676324', 'Carolina Souza Costa', '1978-07-03', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2024-12-31', '03272120', '103', 'Rua Sete Copas', 'Vila Formosa'),
    (15, NULL, NULL, '2025-01-07', '14357742595', 'Gabriela Costa Queiroz', '1982-03-05', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'TRANCADO', '2024-12-29', '08171580', '1794', 'Rua Tangará', 'Itaquera'),
    (16, NULL, NULL, '2025-02-19', '05832381199', 'Vanessa Macedo Cardoso', '1992-09-18', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'TRANCADO', '2025-02-15', '03874942', '1620', 'Rua Tangará', 'Aricanduva'),
    (17, NULL, NULL, '2025-02-21', '07250193934', 'Sérgio Batista Mendes', '1999-01-18', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', '2025-02-10', '08160293', '1902', 'Rua Aroeira', 'Itaquera'),
    (18, NULL, NULL, '2025-03-10', '32218340669', 'Leonardo Queiroz Gomes', '1983-10-23', 'Ex-praticante de karatê (faixa verde).', TRUE, 'ATIVO', '2025-03-04', '03476245', '576', 'Rua das Acácias', 'Artur Alvim'),
    (19, 1, NULL, '2025-03-10', '82432854564', 'Benício Vieira Gomes', '2017-03-20', 'Fez natação por 1 ano.', TRUE, 'ATIVO', '2025-03-05', '03978393', '585', 'Avenida Cerejeira', 'Guaianases'),
    (20, 1, NULL, '2025-03-10', '58293739055', 'Valentina Cardoso Gomes', '2012-10-16', 'Joga futsal na escola.', TRUE, 'ATIVO', '2025-03-05', '03432813', '1502', 'Rua Beija-flor', 'Água Rasa'),
    (21, NULL, NULL, '2025-03-13', '29006094815', 'Rodrigo Correia Campos', '1977-11-13', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', '2025-03-10', '08536473', '928', 'Travessa das Orquídeas', 'São Mateus'),
    (22, NULL, NULL, '2025-04-11', '62139568619', 'Leonardo Souza Nascimento', '1996-09-07', 'Nunca praticou artes marciais; sedentário há 3 anos.', FALSE, 'ATIVO', '2025-04-01', '08896891', '784', 'Rua das Violetas', 'Vila Formosa'),
    (23, NULL, NULL, '2025-04-12', '75946200856', 'Raquel Santos Queiroz', '2001-11-14', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', '2025-04-07', '08261040', '656', 'Rua das Camélias', 'Cangaíba'),
    (24, 2, NULL, '2025-04-14', '97979078018', 'Eduardo Batista Pereira', '2009-03-30', 'Nunca treinou; procurou a academia para defesa pessoal.', FALSE, 'ATIVO', '2025-04-12', '08193521', '174', 'Avenida dos Jasmins', 'Ermelino Matarazzo'),
    (25, NULL, NULL, '2025-04-16', '36281572472', 'Jonas Ramos Campos', '2003-05-18', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', '2025-04-09', '03206961', '1498', 'Rua Flamboyant', 'Penha'),
    (26, 3, NULL, '2025-04-30', '95071296745', 'Bernardo Queiroz Rocha', '2014-05-04', 'Nunca praticou esportes.', FALSE, 'ATIVO', '2025-04-24', '08231001', '213', 'Rua Quaresmeira', 'Tatuapé'),
    (27, NULL, NULL, '2025-05-26', '53222719855', 'Jéssica Nunes Moura', '1983-07-13', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', '2025-05-17', '03639796', '667', 'Avenida dos Jasmins', 'Penha'),
    (28, NULL, NULL, '2025-06-02', '40109147169', 'Ricardo Macedo Pinto', '1980-12-13', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'INATIVO', '2025-05-29', '03925842', '525', 'Avenida dos Jasmins', 'Belém'),
    (29, NULL, NULL, '2025-06-14', '09148600678', 'Vanessa Mendes Ramos', '1975-10-14', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', '2025-06-03', '08321884', '1387', 'Rua Aroeira', 'Vila Formosa'),
    (30, NULL, NULL, '2025-06-21', '19880436819', 'Sabrina Lopes Oliveira', '1983-10-29', 'Pratica musculação há 4 anos; nunca treinou luta.', TRUE, 'ATIVO', '2025-06-15', '08454309', '1402', 'Rua das Violetas', 'Vila Matilde'),
    (31, NULL, NULL, '2025-06-23', '57237053368', 'Rafael Barbosa Silva', '1985-04-07', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', '2025-06-22', '03096911', '1313', 'Rua Quaresmeira', 'São Mateus'),
    (32, NULL, NULL, '2025-07-14', '63210126128', 'Thiago Siqueira Correia', '1979-12-09', 'Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'ATIVO', '2025-07-05', '03044756', '56', 'Rua Quaresmeira', 'Artur Alvim'),
    (33, NULL, NULL, '2025-07-22', '11859434457', 'André Araújo Nunes', '1979-04-27', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', '2025-07-19', '03492733', '541', 'Rua Tangará', 'Tatuapé'),
    (34, NULL, NULL, '2025-07-22', '84078500787', 'Ana Ribeiro Araújo', '1992-09-17', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', '2025-07-12', '03772820', '1863', 'Rua Aroeira', 'Cangaíba'),
    (35, NULL, NULL, '2025-07-28', '90985631482', 'Matheus Farias Lima', '2005-02-24', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2025-07-23', '08907684', '1394', 'Rua das Camélias', 'Aricanduva'),
    (36, NULL, NULL, '2025-08-04', '00552788823', 'Vitor Cavalcanti Farias', '1984-01-13', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', '2025-08-04', '08822463', '619', 'Travessa das Orquídeas', 'Penha'),
    (37, 4, NULL, '2025-08-04', '62201523499', 'Lorenzo Teixeira Farias', '2015-05-16', 'Joga futsal na escola.', TRUE, 'ATIVO', '2025-08-03', '08215779', '607', 'Rua Flamboyant', 'Penha'),
    (38, 4, NULL, '2025-08-04', '15430338779', 'Miguel Cavalcanti Farias', '2013-10-13', 'Primeira atividade esportiva.', TRUE, 'ATIVO', '2025-08-02', '03192858', '1282', 'Rua Flamboyant', 'Penha'),
    (39, NULL, NULL, '2025-08-16', '52280478891', 'Cláudia Moreira Ramos', '2003-03-31', 'Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', '2025-08-07', '08334010', '61', 'Rua das Acácias', 'Vila Matilde'),
    (40, NULL, NULL, '2025-09-01', '63243278213', 'Hugo Cavalcanti Barbosa', '1974-11-06', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', '2025-08-28', '03801196', '1166', 'Rua Flamboyant', 'Água Rasa'),
    (41, NULL, NULL, '2025-09-18', '65886174949', 'Renato Teixeira Tavares', '1976-01-22', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', '2025-09-07', '03291422', '505', 'Rua Aroeira', 'Tatuapé'),
    (42, NULL, NULL, '2025-10-10', '95671357822', 'Gabriel Nunes Gomes', '2003-01-17', 'Ex-praticante de karatê (faixa verde).', TRUE, 'ATIVO', '2025-10-04', '08878690', '227', 'Rua Sete Copas', 'Itaquera'),
    (43, NULL, NULL, '2025-10-13', '69252669706', 'Sabrina Macedo Pinto', '2005-11-30', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', '2025-10-11', '08607924', '1881', 'Rua Manacá', 'Ermelino Matarazzo'),
    (44, NULL, NULL, '2025-10-23', '56663382128', 'Larissa Queiroz Lopes', '1978-11-07', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', '2025-10-15', '03834950', '1495', 'Rua Pau-Brasil', 'Vila Esperança'),
    (45, NULL, NULL, '2025-11-03', '17368456956', 'Camila Almeida Freitas', '1989-03-18', 'Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'INATIVO', '2025-10-31', '08689054', '1342', 'Rua Beija-flor', 'Penha'),
    (46, NULL, NULL, '2025-12-05', '35670349312', 'Samuel Rocha Oliveira', '1973-07-31', 'Fez capoeira na escola por 3 anos.', FALSE, 'ATIVO', '2025-11-25', '03381173', '1241', 'Rua Ipê Roxo', 'Artur Alvim'),
    (47, NULL, NULL, '2025-12-10', '14183037366', 'Isabela Almeida Vieira', '2004-04-10', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', '2025-12-05', '08879837', '1815', 'Rua Pau-Brasil', 'Água Rasa'),
    (48, NULL, NULL, '2025-12-16', '73316445888', 'Elaine Monteiro Queiroz', '1977-04-10', 'Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', '2025-12-16', '03750030', '1707', 'Rua Jequitibá', 'Vila Esperança'),
    (49, NULL, NULL, '2025-12-30', '43274914905', 'Carolina Vieira Pereira', '1991-05-16', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', '2025-12-23', '03522033', '1826', 'Avenida Cerejeira', 'Belém'),
    (50, 5, NULL, '2026-01-02', '15968244668', 'Raquel Moura Correia', '2012-11-27', 'Ex-praticante de karatê (faixa verde).', FALSE, 'ATIVO', '2026-01-02', '03590556', '1100', 'Rua Pau-Brasil', 'Artur Alvim'),
    (51, NULL, NULL, '2026-01-05', '88713017126', 'Juliana Oliveira Ferreira', '1992-07-22', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'INATIVO', '2025-12-27', '03835708', '579', 'Rua Tangará', 'Itaquera'),
    (52, NULL, NULL, '2026-01-05', '36671601625', 'Priscila Barbosa Macedo', '1982-10-03', 'Pratica musculação há 4 anos; nunca treinou luta.', FALSE, 'ATIVO', '2026-01-01', '03277310', '1905', 'Rua Sabiá', 'Vila Matilde'),
    (53, 6, NULL, '2026-01-26', '73696066399', 'Patrícia Dias Macedo', '2013-06-06', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', NULL, '03078966', '431', 'Rua Quaresmeira', 'Penha'),
    (54, NULL, NULL, '2026-02-02', '01146676432', 'Débora Nascimento Macedo', '1985-06-26', 'Pratica natação; quer melhorar o condicionamento.', FALSE, 'ATIVO', '2026-01-27', '03844533', '628', 'Rua Aroeira', 'Tatuapé'),
    (55, 7, NULL, '2026-02-02', '08024920854', 'Théo Ribeiro Macedo', '2011-11-27', 'Nunca praticou esportes.', FALSE, 'ATIVO', '2026-01-25', '03358809', '1008', 'Rua Jequitibá', 'Tatuapé'),
    (56, 7, NULL, '2026-02-02', '91422291069', 'Sofia Gomes Macedo', '2014-12-14', 'Fez balé por 2 anos.', FALSE, 'ATIVO', '2026-01-28', '08699798', '65', 'Rua Sete Copas', 'São Mateus'),
    (57, NULL, NULL, '2026-02-09', '23124360883', 'Patrícia Ribeiro Costa', '1997-12-18', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', '2026-02-05', '08276054', '1845', 'Rua Pau-Brasil', 'Cidade Patriarca'),
    (58, NULL, NULL, '2026-02-09', '88808225489', 'Daniela Monteiro Ferreira', '1988-07-23', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', '2026-01-30', '08188023', '1969', 'Rua Flamboyant', 'Belém'),
    (59, NULL, NULL, '2026-02-10', '01259506553', 'Letícia Cardoso Santos', '1999-08-23', 'Pratica musculação há 4 anos; nunca treinou luta.', FALSE, 'ATIVO', '2026-02-05', '03060507', '1442', 'Rua Sabiá', 'Cidade Patriarca'),
    (60, NULL, NULL, '2026-03-09', '71463007478', 'Yasmin Mendes Oliveira', '1976-09-07', 'Pratica musculação há 4 anos; nunca treinou luta.', TRUE, 'INATIVO', '2026-03-09', '03058800', '304', 'Rua Manacá', 'Vila Carrão');
INSERT INTO ALUNO (ID_ALUNO, ID_RESPONSAVEL, ID_INTERESSADO, DT_AUTORIZACAO_IMAGEM, CPF, NM_COMPLETO, DT_NASCIMENTO, DS_HISTORICO_TREINO, IN_ACEITE_USO_IMAGEM, TP_STATUS_ALUNO, DT_ENTREGA_ATESTADO, NR_CEP, NR_LOGRADOURO, DS_RUA, NM_BAIRRO) VALUES
    (61, NULL, NULL, '2026-03-21', '48996801757', 'Yasmin Vieira Monteiro', '2000-04-22', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', '2026-03-14', '03243180', '1201', 'Rua Ipê Roxo', 'Belém'),
    (62, NULL, NULL, '2026-03-28', '89217740555', 'Hugo Vieira Lima', '2002-06-08', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', '2026-03-26', '08091414', '55', 'Rua Ipê Roxo', 'Guaianases'),
    (63, NULL, NULL, '2026-03-31', '29406570654', 'Otávio Dias Ribeiro', '1991-06-14', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2026-03-22', '03823026', '738', 'Avenida das Hortênsias', 'Cangaíba'),
    (64, NULL, NULL, '2026-04-08', '30915308854', 'Isabela Souza Martins', '1984-12-11', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'TRANCADO', '2026-04-04', '03072518', '251', 'Rua dos Cravos', 'Vila Formosa'),
    (65, 8, NULL, '2026-04-09', '63487301510', 'Manuela Almeida Nascimento', '2014-06-22', 'Fez natação por 1 ano.', TRUE, 'ATIVO', '2026-04-08', '08968400', '462', 'Rua Jequitibá', 'Cangaíba'),
    (66, NULL, NULL, '2026-04-11', '54868236472', 'Marcelo Nascimento Rodrigues', '1994-06-10', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', '2026-04-05', '03901455', '1643', 'Rua Tangará', 'Aricanduva'),
    (67, NULL, NULL, '2026-04-16', '00862569492', 'Aline Lopes Moreira', '2005-07-26', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', '2026-04-15', '03835723', '1891', 'Rua Sabiá', 'Vila Esperança'),
    (68, NULL, NULL, '2026-04-21', '49605189397', 'Otávio Batista Teixeira', '1973-04-03', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', '2026-04-13', '03400072', '1612', 'Rua Sabiá', 'Vila Formosa'),
    (69, NULL, NULL, '2026-04-27', '31836802439', 'Bianca Costa Machado', '1994-07-13', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', '2026-04-23', '08413620', '1256', 'Rua dos Cravos', 'Itaquera'),
    (70, NULL, NULL, '2026-05-04', '51898758960', 'Leonardo Oliveira Freitas', '1981-09-20', 'Pratica natação; quer melhorar o condicionamento.', FALSE, 'INATIVO', '2026-04-24', '08624800', '30', 'Travessa das Orquídeas', 'Ermelino Matarazzo'),
    (71, NULL, NULL, '2026-05-11', '90143028568', 'Viviane Correia Moura', '1978-08-03', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', '2026-05-06', '03311218', '895', 'Travessa das Orquídeas', 'Cangaíba'),
    (72, 9, NULL, '2026-05-11', '10590882124', 'Laura Ramos Moura', '2018-11-09', 'Fez balé por 2 anos.', TRUE, 'ATIVO', '2026-05-01', '08498644', '621', 'Rua Quaresmeira', 'Vila Formosa'),
    (73, NULL, NULL, '2026-07-01', '48437064875', 'Murilo Pinto Martins', '1975-04-05', 'Ex-praticante de karatê (faixa verde).', TRUE, 'INATIVO', '2026-06-25', '08352534', '1338', 'Rua das Camélias', 'São Mateus'),
    (74, 10, NULL, '2026-06-03', '17119168249', 'Aline Silva Siqueira', '2012-12-26', 'Treinou boxe por 1 ano em projeto social.', FALSE, 'ATIVO', '2026-05-29', '08937527', '1511', 'Rua dos Cravos', 'Tatuapé'),
    (75, NULL, NULL, '2026-06-11', '66243238213', 'Viviane Gomes Ramos', '1992-12-04', 'Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', '2026-06-02', '08450899', '871', 'Rua das Acácias', 'Artur Alvim'),
    (76, NULL, NULL, '2026-06-13', '88553229807', 'Gabriela Machado Cavalcanti', '1988-03-27', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', '2026-06-09', '08978398', '1331', 'Rua Tangará', 'Água Rasa'),
    (77, NULL, NULL, '2026-07-06', '75510711460', 'Vanessa Rodrigues Cavalcanti', '1980-05-04', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', '2026-06-25', '03823526', '1896', 'Rua Quaresmeira', 'Artur Alvim'),
    (78, 11, NULL, '2026-07-06', '83296066586', 'Théo Monteiro Cavalcanti', '2017-09-20', 'Fez balé por 2 anos.', FALSE, 'ATIVO', '2026-07-05', '08298077', '176', 'Rua Bem-te-vi', 'Vila Formosa'),
    (79, NULL, NULL, '2026-07-15', '00958677994', 'Priscila Monteiro Ribeiro', '1978-08-19', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', '2026-07-14', '03879348', '1460', 'Avenida Cerejeira', 'Penha'),
    (80, NULL, NULL, '2026-07-27', '86601347849', 'Carolina Ferreira Carvalho', '2001-07-12', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', '2026-07-18', '03009001', '1756', 'Rua Beija-flor', 'Penha'),
    (81, NULL, NULL, '2026-08-03', '27552234514', 'Leonardo Batista Pereira', '2007-01-05', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2026-07-31', '03882518', '1318', 'Rua Jequitibá', 'Penha'),
    (82, NULL, 1, '2026-09-03', '45628674121', 'Daniel Vieira Queiroz', '1987-10-28', 'Fez a aula experimental na academia. Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2026-08-24', '03125168', '984', 'Rua Manacá', 'Vila Esperança'),
    (83, NULL, 3, '2026-09-04', '52611654533', 'Carolina Freitas Machado', '1977-02-18', 'Fez a aula experimental na academia. Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', '2026-09-02', '08127162', '298', 'Rua das Acácias', 'Cangaíba'),
    (84, NULL, 4, '2026-09-21', '18371275341', 'Tatiane Mendes Dias', '1976-03-19', 'Fez a aula experimental na academia. Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2026-09-21', '08989621', '1707', 'Avenida das Hortênsias', 'Belém'),
    (85, NULL, 8, '2026-09-28', '13312141917', 'Eduardo Pereira Rodrigues', '1986-09-17', 'Fez a aula experimental na academia. Pratica musculação há 4 anos; nunca treinou luta.', FALSE, 'ATIVO', '2026-09-20', '08042457', '912', 'Rua Jequitibá', 'Vila Formosa'),
    (86, NULL, 11, '2026-10-06', '36971498622', 'Aline Campos Tavares', '1984-09-03', 'Fez a aula experimental na academia. Fez capoeira na escola por 3 anos.', FALSE, 'ATIVO', '2026-10-04', '03139721', '760', 'Rua Sete Copas', 'Belém'),
    (87, NULL, 10, '2026-10-06', '47325601954', 'Fernanda Brandão Rodrigues', '1987-06-11', 'Fez a aula experimental na academia. Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', '2026-09-28', '03048550', '1857', 'Rua das Violetas', 'Vila Esperança'),
    (88, NULL, 13, '2026-10-06', '88623682562', 'Viviane Teixeira Macedo', '1981-04-04', 'Fez a aula experimental na academia. Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'ATIVO', '2026-10-03', '03961132', '1292', 'Rua Bem-te-vi', 'Vila Formosa'),
    (89, NULL, 14, '2026-10-09', '56232627922', 'Beatriz Batista Costa', '1982-03-24', 'Fez a aula experimental na academia. Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', '2026-09-30', '03168900', '1604', 'Rua das Camélias', 'Penha'),
    (90, NULL, 17, '2026-10-15', '80257653917', 'Alexandre Almeida Freitas', '1981-08-12', 'Fez a aula experimental na academia. Pratica natação; quer melhorar o condicionamento.', FALSE, 'ATIVO', NULL, '08042724', '948', 'Travessa das Orquídeas', 'Guaianases'),
    (91, NULL, 15, '2026-10-15', '07934933944', 'Cláudia Nascimento Teixeira', '1996-09-01', 'Fez a aula experimental na academia. Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'ATIVO', '2026-10-14', '08993350', '1255', 'Avenida Cerejeira', 'Penha'),
    (92, NULL, NULL, '2026-10-28', '86540428441', 'Débora Souza Vieira', '1999-05-21', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', NULL, '08237344', '1875', 'Rua Quaresmeira', 'Vila Matilde');

INSERT INTO EMAIL_ALUNO (DS_EMAIL, ID_ALUNO) VALUES
    ('beatriz.ramos@example.com', 1),
    ('larissa.brandao@example.com', 2),
    ('ricardo.moura@example.com', 3),
    ('renato.mendes@example.com', 4),
    ('gabriela.carvalho@example.com', 5),
    ('daniela.costa@example.com', 6),
    ('murilo.costa@example.com', 7),
    ('lucas.cavalcanti@example.com', 8),
    ('vinicius.almeida@example.com', 9),
    ('murilo.ramos@example.com', 10),
    ('larissa.queiroz@example.com', 11),
    ('camila.vieira@example.com', 12),
    ('bruno.moura@example.com', 13),
    ('carolina.costa@example.com', 14),
    ('carolina.costa69@example.com', 14),
    ('gabriela.queiroz@example.com', 15),
    ('vanessa.cardoso@example.com', 16),
    ('sergio.mendes@example.com', 17),
    ('leonardo.gomes@example.com', 18),
    ('leonardo.gomes@example.com', 19),
    ('leonardo.gomes@example.com', 20),
    ('rodrigo.campos@example.com', 21),
    ('leonardo.nascimento@example.com', 22),
    ('raquel.queiroz@example.com', 23),
    ('eduardo.pereira@example.com', 24),
    ('jonas.campos@example.com', 25),
    ('bernardo.rocha@example.com', 26),
    ('jessica.moura@example.com', 27),
    ('ricardo.pinto@example.com', 28),
    ('vanessa.ramos@example.com', 29),
    ('sabrina.oliveira@example.com', 30),
    ('rafael.silva@example.com', 31),
    ('thiago.correia@example.com', 32),
    ('andre.nunes@example.com', 33),
    ('ana.araujo@example.com', 34),
    ('matheus.lima@example.com', 35),
    ('vitor.farias@example.com', 36),
    ('vitor.farias@example.com', 37),
    ('vitor.farias@example.com', 38),
    ('claudia.ramos@example.com', 39),
    ('hugo.barbosa@example.com', 40),
    ('renato.tavares@example.com', 41),
    ('renato.tavares34@example.com', 41),
    ('gabriel.gomes@example.com', 42),
    ('sabrina.pinto@example.com', 43),
    ('larissa.lopes@example.com', 44),
    ('camila.freitas@example.com', 45),
    ('samuel.oliveira@example.com', 46),
    ('isabela.vieira@example.com', 47),
    ('isabela.vieira63@example.com', 47),
    ('elaine.queiroz@example.com', 48),
    ('elaine.queiroz44@example.com', 48),
    ('carolina.pereira@example.com', 49),
    ('raquel.correia@example.com', 50),
    ('juliana.ferreira@example.com', 51),
    ('priscila.macedo@example.com', 52),
    ('patricia.macedo@example.com', 53),
    ('patricia.macedo72@example.com', 53),
    ('debora.macedo@example.com', 54),
    ('debora.macedo@example.com', 55);
INSERT INTO EMAIL_ALUNO (DS_EMAIL, ID_ALUNO) VALUES
    ('debora.macedo@example.com', 56),
    ('patricia.costa@example.com', 57),
    ('daniela.ferreira@example.com', 58),
    ('leticia.santos@example.com', 59),
    ('leticia.santos61@example.com', 59),
    ('yasmin.oliveira@example.com', 60),
    ('yasmin.monteiro@example.com', 61),
    ('hugo.lima@example.com', 62),
    ('otavio.ribeiro@example.com', 63),
    ('isabela.martins@example.com', 64),
    ('manuela.nascimento@example.com', 65),
    ('marcelo.rodrigues@example.com', 66),
    ('aline.moreira@example.com', 67),
    ('otavio.teixeira@example.com', 68),
    ('bianca.machado@example.com', 69),
    ('leonardo.freitas@example.com', 70),
    ('viviane.moura@example.com', 71),
    ('viviane.moura@example.com', 72),
    ('murilo.martins@example.com', 73),
    ('aline.siqueira@example.com', 74),
    ('viviane.ramos@example.com', 75),
    ('gabriela.cavalcanti@example.com', 76),
    ('vanessa.cavalcanti@example.com', 77),
    ('vanessa.cavalcanti@example.com', 78),
    ('priscila.ribeiro@example.com', 79),
    ('carolina.carvalho@example.com', 80),
    ('leonardo.pereira@example.com', 81),
    ('daniel.queiroz@example.com', 82),
    ('carolina.machado@example.com', 83),
    ('tatiane.dias@example.com', 84),
    ('eduardo.rodrigues@example.com', 85),
    ('eduardo.rodrigues22@example.com', 85),
    ('aline.tavares@example.com', 86),
    ('fernanda.rodrigues@example.com', 87),
    ('viviane.macedo@example.com', 88),
    ('beatriz.costa@example.com', 89),
    ('alexandre.freitas@example.com', 90),
    ('claudia.teixeira@example.com', 91),
    ('debora.vieira@example.com', 92),
    ('debora.vieira13@example.com', 92);

INSERT INTO TELEFONE_ALUNO (NR_TELEFONE, ID_ALUNO) VALUES
    ('1124778764', 1),
    ('11961192076', 1),
    ('11947005659', 2),
    ('11962728058', 3),
    ('11966007570', 4),
    ('11946740353', 5),
    ('11971308404', 5),
    ('11976095933', 6),
    ('11978578133', 7),
    ('1129448786', 8),
    ('11948224498', 8),
    ('11999509279', 9),
    ('11985057394', 10),
    ('11967557097', 11),
    ('11990139409', 11),
    ('11976768916', 12),
    ('1123543173', 13),
    ('11937535808', 13),
    ('11986084778', 14),
    ('11979749034', 15),
    ('11966964215', 16),
    ('11951948697', 17),
    ('11937896565', 18),
    ('11937896565', 19),
    ('11937896565', 20),
    ('11985833213', 21),
    ('1124207069', 22),
    ('11931831981', 22),
    ('11972150545', 23),
    ('1129864014', 24),
    ('11902850460', 24),
    ('11992169474', 24),
    ('11954425261', 25),
    ('11963237251', 26),
    ('11972573947', 26),
    ('11905762184', 27),
    ('11946456786', 28),
    ('11939505091', 29),
    ('11923456564', 30),
    ('11991383297', 31),
    ('11945211323', 32),
    ('11927800997', 33),
    ('11969445228', 34),
    ('11972850277', 35),
    ('1121109043', 36),
    ('11946935394', 36),
    ('11946935394', 37),
    ('11946935394', 38),
    ('11960758039', 39),
    ('11984319033', 39),
    ('1123085795', 40),
    ('11906328714', 40),
    ('11922103069', 41),
    ('1125382880', 42),
    ('11975746605', 42),
    ('11904156238', 43),
    ('1124630956', 44),
    ('11927822749', 44),
    ('11902773001', 45),
    ('11941961804', 45);
INSERT INTO TELEFONE_ALUNO (NR_TELEFONE, ID_ALUNO) VALUES
    ('11963459372', 46),
    ('11967103206', 47),
    ('11990667882', 48),
    ('11944333443', 49),
    ('11947425454', 50),
    ('11996862136', 50),
    ('1129248988', 51),
    ('11945194292', 51),
    ('11976595062', 52),
    ('11982220291', 53),
    ('11982717797', 53),
    ('1127309078', 54),
    ('11956276427', 54),
    ('11956276427', 55),
    ('11956276427', 56),
    ('11982056892', 57),
    ('11914003983', 58),
    ('1122299361', 59),
    ('11905075137', 59),
    ('11942459653', 60),
    ('11931376612', 61),
    ('1122015725', 62),
    ('11990985756', 62),
    ('11930330233', 63),
    ('11916593856', 64),
    ('11921563398', 65),
    ('11934183216', 65),
    ('11968883702', 66),
    ('1128570282', 67),
    ('11981875164', 67),
    ('11986987460', 68),
    ('11912289571', 69),
    ('1126269438', 70),
    ('11996352101', 70),
    ('11963520220', 71),
    ('11963520220', 72),
    ('11935625857', 73),
    ('11934470177', 74),
    ('11953706412', 74),
    ('11992239891', 74),
    ('11933842123', 75),
    ('11983158430', 76),
    ('11960555531', 77),
    ('11960555531', 78),
    ('11977404936', 79),
    ('11906108533', 80),
    ('11968312936', 80),
    ('11928204113', 81),
    ('1120351613', 82),
    ('11951341935', 82),
    ('11904838041', 83),
    ('11950519150', 83),
    ('11933669288', 84),
    ('11983541274', 85),
    ('11937219453', 86),
    ('11977475313', 87),
    ('11997878922', 87),
    ('11907884745', 88),
    ('1125875561', 89),
    ('11977276268', 89);
INSERT INTO TELEFONE_ALUNO (NR_TELEFONE, ID_ALUNO) VALUES
    ('11958006138', 90),
    ('11994863739', 91),
    ('11995492972', 92);

INSERT INTO PROBLEMA_SAUDE_ALUNO (DS_PROBLEMA_SAUDE, ID_ALUNO) VALUES
    ('Hipertensão controlada com medicação', 1),
    ('nenhum', 2),
    ('Rinite alérgica', 3),
    ('nenhum', 4),
    ('nenhum', 5),
    ('nenhum', 6),
    ('nenhum', 7),
    ('Diabetes tipo 1', 8),
    ('Hipertensão controlada com medicação', 9),
    ('nenhum', 10),
    ('nenhum', 11),
    ('nenhum', 12),
    ('nenhum', 13),
    ('nenhum', 14),
    ('nenhum', 15),
    ('Tendinite no ombro esquerdo', 16),
    ('nenhum', 17),
    ('nenhum', 18),
    ('Alergia a látex', 19),
    ('Escoliose leve', 20),
    ('nenhum', 21),
    ('nenhum', 22),
    ('nenhum', 23),
    ('nenhum', 24),
    ('nenhum', 25),
    ('Escoliose leve', 26),
    ('nenhum', 27),
    ('nenhum', 28),
    ('nenhum', 29),
    ('Diabetes tipo 1', 30),
    ('Hérnia de disco lombar - evitar quedas sem orientação', 30),
    ('nenhum', 31),
    ('nenhum', 32),
    ('nenhum', 33),
    ('nenhum', 34),
    ('nenhum', 35),
    ('nenhum', 36),
    ('nenhum', 37),
    ('Rinite alérgica', 38),
    ('nenhum', 39),
    ('nenhum', 40),
    ('nenhum', 41),
    ('nenhum', 42),
    ('Tendinite no ombro esquerdo', 43),
    ('nenhum', 44),
    ('nenhum', 45),
    ('nenhum', 46),
    ('Tendinite no ombro esquerdo', 47),
    ('nenhum', 48),
    ('nenhum', 49),
    ('nenhum', 50),
    ('nenhum', 51),
    ('nenhum', 52),
    ('nenhum', 53),
    ('Rinite alérgica', 54),
    ('nenhum', 55),
    ('Escoliose leve', 56),
    ('nenhum', 57),
    ('nenhum', 58),
    ('nenhum', 59);
INSERT INTO PROBLEMA_SAUDE_ALUNO (DS_PROBLEMA_SAUDE, ID_ALUNO) VALUES
    ('nenhum', 60),
    ('nenhum', 61),
    ('nenhum', 62),
    ('nenhum', 63),
    ('nenhum', 64),
    ('nenhum', 65),
    ('nenhum', 66),
    ('nenhum', 67),
    ('nenhum', 68),
    ('nenhum', 69),
    ('nenhum', 70),
    ('nenhum', 71),
    ('nenhum', 72),
    ('nenhum', 73),
    ('nenhum', 74),
    ('Hipertensão controlada com medicação', 75),
    ('Hérnia de disco lombar - evitar quedas sem orientação', 76),
    ('Hipertensão controlada com medicação', 76),
    ('nenhum', 77),
    ('Escoliose leve', 78),
    ('nenhum', 79),
    ('Tendinite no ombro esquerdo', 80),
    ('nenhum', 81),
    ('nenhum', 82),
    ('nenhum', 83),
    ('Escoliose leve', 84),
    ('nenhum', 85),
    ('Hérnia de disco lombar - evitar quedas sem orientação', 86),
    ('Asma leve controlada', 87),
    ('nenhum', 88),
    ('nenhum', 89),
    ('nenhum', 90),
    ('nenhum', 91),
    ('Rinite alérgica', 92);

-- -------------------------------------------------------------------------------------
-- 4.6 TURMA (21) [RF03, RE01, RE02, RE05]
-- Grade do PN06: 4 turmas por dia, em horários diferentes (07:00, 18:00, 19:00 e 20:00), de
-- segunda a sexta; aos sábados só há a turma de Capoeira, que é única. Cada turma tem o
-- professor da sua modalidade. Jiu-Jitsu e No-Gi têm 1h30 de aula; as demais, 1 hora.
-- A turma 21 (No-Gi, sexta 07:00) acabou de abrir e ainda não tem alunos nem aulas: serve para
-- mostrar o LEFT JOIN e o alerta de quórum (A06), junto com a turma 19 (No-Gi, terça 20:00),
-- que está abaixo do quórum de 8 alunos.
-- -------------------------------------------------------------------------------------
INSERT INTO TURMA (ID_TURMA, ID_MODALIDADE, ID_PROFESSOR, DS_DIA_SEMANA, HR_INICIO, QT_CAPACIDADE_MAXIMA, HR_FIM) VALUES
    (1, 1, 1, 'SEGUNDA', '07:00:00', 30, '08:00:00'),
    (2, 1, 1, 'TERCA', '19:00:00', 30, '20:00:00'),
    (3, 1, 1, 'QUARTA', '07:00:00', 30, '08:00:00'),
    (4, 1, 1, 'QUINTA', '19:00:00', 30, '20:00:00'),
    (5, 1, 1, 'SEXTA', '19:00:00', 30, '20:00:00'),
    (6, 2, 2, 'SEGUNDA', '19:00:00', 30, '20:00:00'),
    (7, 2, 2, 'QUARTA', '19:00:00', 30, '20:00:00'),
    (8, 2, 2, 'SEXTA', '18:00:00', 30, '19:00:00'),
    (9, 3, 3, 'SEGUNDA', '20:00:00', 30, '21:30:00'),
    (10, 3, 3, 'TERCA', '07:00:00', 30, '08:30:00'),
    (11, 3, 3, 'QUARTA', '20:00:00', 30, '21:30:00'),
    (12, 3, 3, 'QUINTA', '07:00:00', 30, '08:30:00'),
    (13, 3, 3, 'SEXTA', '20:00:00', 30, '21:30:00'),
    (14, 4, 4, 'SEGUNDA', '18:00:00', 30, '19:00:00'),
    (15, 4, 4, 'TERCA', '18:00:00', 30, '19:00:00'),
    (16, 4, 4, 'QUARTA', '18:00:00', 30, '19:00:00'),
    (17, 4, 4, 'QUINTA', '18:00:00', 30, '19:00:00'),
    (18, 5, 5, 'SABADO', '14:00:00', 30, '15:30:00'),
    (19, 6, 6, 'TERCA', '20:00:00', 30, '21:30:00'),
    (20, 6, 6, 'QUINTA', '20:00:00', 30, '21:30:00'),
    (21, 6, 6, 'SEXTA', '07:00:00', 30, '08:30:00');

-- -------------------------------------------------------------------------------------
-- 4.7 MATRICULA (204) [RF03, RE06, RO01]
-- Cada aluno treina em 1 a 3 turmas de cada modalidade do contrato (uma matrícula por turma).
-- 188 ATIVA, 3 TRANCADA, 3 ENCERRADA (troca de turma), 10 CANCELADA.
-- Na troca de turma a matrícula antiga fica ENCERRADA e uma nova é criada (o histórico não é apagado).
-- Cenários de auditoria: o aluno 46 treina Boxe desde 16/09 (matrícula 189) sem que a
-- modalidade esteja no contrato dele (A11); o aluno 9 treina Jiu-Jitsu (matrícula 172) por
-- um segundo contrato, aberto em vez do acréscimo no contrato que já tinha (A12).
-- -------------------------------------------------------------------------------------
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (1, 1, 2, '2024-04-03', 'ATIVA'),
    (2, 1, 5, '2024-04-03', 'ATIVA'),
    (3, 2, 2, '2024-06-07', 'ATIVA'),
    (4, 3, 6, '2024-07-12', 'ATIVA'),
    (5, 3, 10, '2024-07-12', 'ATIVA'),
    (6, 3, 11, '2024-07-12', 'ATIVA'),
    (7, 3, 12, '2024-07-12', 'ATIVA'),
    (8, 4, 19, '2024-08-05', 'ATIVA'),
    (9, 4, 20, '2024-08-05', 'ATIVA'),
    (10, 5, 4, '2024-10-04', 'ATIVA'),
    (11, 5, 5, '2024-10-04', 'ATIVA'),
    (12, 6, 16, '2024-10-25', 'ATIVA'),
    (13, 7, 7, '2024-11-12', 'ATIVA'),
    (14, 7, 8, '2024-11-12', 'ATIVA'),
    (15, 8, 1, '2024-11-25', 'ATIVA'),
    (16, 8, 2, '2024-11-25', 'ATIVA'),
    (17, 8, 4, '2024-11-25', 'ATIVA'),
    (18, 9, 14, '2024-11-28', 'ATIVA'),
    (19, 9, 15, '2024-11-28', 'ATIVA'),
    (20, 9, 17, '2024-11-28', 'ATIVA'),
    (21, 10, 10, '2024-12-16', 'ATIVA'),
    (22, 10, 12, '2024-12-16', 'ATIVA'),
    (23, 10, 13, '2024-12-16', 'ATIVA'),
    (24, 11, 6, '2024-12-20', 'ATIVA'),
    (25, 11, 18, '2024-12-20', 'ATIVA'),
    (26, 12, 1, '2024-12-23', 'ATIVA'),
    (27, 12, 3, '2024-12-23', 'ATIVA'),
    (28, 12, 4, '2024-12-23', 'ATIVA'),
    (29, 13, 16, '2025-01-02', 'ENCERRADA'),
    (30, 13, 17, '2025-01-02', 'ATIVA'),
    (31, 14, 9, '2025-01-02', 'ATIVA'),
    (32, 15, 2, '2025-01-07', 'TRANCADA'),
    (33, 16, 10, '2025-02-19', 'TRANCADA'),
    (34, 17, 7, '2025-02-21', 'ATIVA'),
    (35, 17, 8, '2025-02-21', 'ATIVA'),
    (36, 18, 9, '2025-03-10', 'ATIVA'),
    (37, 18, 11, '2025-03-10', 'ATIVA'),
    (38, 18, 13, '2025-03-10', 'ATIVA'),
    (39, 19, 18, '2025-03-10', 'ATIVA'),
    (40, 20, 18, '2025-03-10', 'ATIVA'),
    (41, 21, 6, '2025-03-13', 'ATIVA'),
    (42, 21, 8, '2025-03-13', 'ATIVA'),
    (43, 22, 1, '2025-04-11', 'ATIVA'),
    (44, 22, 2, '2025-04-11', 'ATIVA'),
    (45, 22, 3, '2025-04-11', 'ATIVA'),
    (46, 23, 18, '2025-04-12', 'ATIVA'),
    (47, 24, 2, '2025-04-14', 'ATIVA'),
    (48, 24, 4, '2025-04-14', 'ATIVA'),
    (49, 25, 1, '2025-04-16', 'ATIVA'),
    (50, 25, 3, '2025-04-16', 'ATIVA'),
    (51, 26, 10, '2025-04-30', 'ATIVA'),
    (52, 26, 11, '2025-04-30', 'ATIVA'),
    (53, 26, 12, '2025-04-30', 'ATIVA'),
    (54, 27, 18, '2025-05-26', 'ATIVA'),
    (55, 27, 19, '2025-05-26', 'ATIVA'),
    (56, 27, 20, '2025-05-26', 'ATIVA'),
    (57, 28, 18, '2025-06-02', 'CANCELADA'),
    (58, 29, 15, '2025-06-14', 'ATIVA'),
    (59, 29, 16, '2025-06-14', 'ATIVA'),
    (60, 29, 18, '2025-06-14', 'ATIVA');
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (61, 30, 19, '2025-06-21', 'ATIVA'),
    (62, 30, 20, '2025-06-21', 'ATIVA'),
    (63, 31, 6, '2025-06-23', 'ATIVA'),
    (64, 31, 7, '2025-06-23', 'ATIVA'),
    (65, 32, 9, '2025-07-14', 'ATIVA'),
    (66, 32, 11, '2025-07-14', 'ATIVA'),
    (67, 32, 13, '2025-07-14', 'ATIVA'),
    (68, 33, 4, '2025-07-22', 'ATIVA'),
    (69, 33, 7, '2025-07-22', 'ATIVA'),
    (70, 34, 10, '2025-07-22', 'ATIVA'),
    (71, 34, 12, '2025-07-22', 'ATIVA'),
    (72, 34, 13, '2025-07-22', 'ATIVA'),
    (73, 35, 9, '2025-07-28', 'ATIVA'),
    (74, 35, 11, '2025-07-28', 'ATIVA'),
    (75, 35, 13, '2025-07-28', 'ATIVA'),
    (76, 36, 7, '2025-08-04', 'ATIVA'),
    (77, 36, 8, '2025-08-04', 'ATIVA'),
    (78, 37, 9, '2025-08-04', 'ATIVA'),
    (79, 37, 10, '2025-08-04', 'ATIVA'),
    (80, 37, 12, '2025-08-04', 'ATIVA'),
    (81, 38, 10, '2025-08-04', 'ATIVA'),
    (82, 38, 11, '2025-08-04', 'ATIVA'),
    (83, 38, 13, '2025-08-04', 'ATIVA'),
    (84, 39, 9, '2025-08-16', 'ATIVA'),
    (85, 39, 13, '2025-08-16', 'ATIVA'),
    (86, 40, 6, '2025-09-01', 'ATIVA'),
    (87, 40, 8, '2025-09-01', 'ATIVA'),
    (88, 41, 9, '2025-09-18', 'ATIVA'),
    (89, 41, 11, '2025-09-18', 'ATIVA'),
    (90, 42, 10, '2025-10-10', 'ATIVA'),
    (91, 42, 11, '2025-10-10', 'ATIVA'),
    (92, 42, 12, '2025-10-10', 'ATIVA'),
    (93, 42, 18, '2025-10-10', 'ATIVA'),
    (94, 43, 9, '2025-10-13', 'ATIVA'),
    (95, 43, 10, '2025-10-13', 'ATIVA'),
    (96, 43, 13, '2025-10-13', 'ATIVA'),
    (97, 44, 15, '2025-10-23', 'ATIVA'),
    (98, 44, 16, '2025-10-23', 'ATIVA'),
    (99, 44, 17, '2025-10-23', 'ATIVA'),
    (100, 45, 18, '2025-11-03', 'CANCELADA'),
    (101, 46, 1, '2025-12-05', 'ATIVA'),
    (102, 46, 3, '2025-12-05', 'ATIVA'),
    (103, 47, 18, '2025-12-10', 'ATIVA'),
    (104, 48, 15, '2025-12-16', 'ATIVA'),
    (105, 48, 17, '2025-12-16', 'ENCERRADA'),
    (106, 48, 19, '2025-12-16', 'ATIVA'),
    (107, 48, 20, '2025-12-16', 'ATIVA'),
    (108, 49, 1, '2025-12-30', 'ATIVA'),
    (109, 49, 2, '2025-12-30', 'ATIVA'),
    (110, 50, 18, '2026-01-02', 'ATIVA'),
    (111, 51, 6, '2026-01-05', 'CANCELADA'),
    (112, 51, 7, '2026-01-05', 'CANCELADA'),
    (113, 51, 8, '2026-01-05', 'CANCELADA'),
    (114, 52, 4, '2026-01-05', 'ATIVA'),
    (115, 52, 5, '2026-01-05', 'ATIVA'),
    (116, 53, 10, '2026-01-26', 'ATIVA'),
    (117, 53, 12, '2026-01-26', 'ATIVA'),
    (118, 54, 14, '2026-02-02', 'ATIVA'),
    (119, 54, 15, '2026-02-02', 'ATIVA'),
    (120, 54, 17, '2026-02-02', 'ATIVA');
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (121, 55, 18, '2026-02-02', 'ATIVA'),
    (122, 56, 18, '2026-02-02', 'ATIVA'),
    (123, 57, 9, '2026-02-09', 'ATIVA'),
    (124, 57, 11, '2026-02-09', 'ATIVA'),
    (125, 57, 13, '2026-02-09', 'ATIVA'),
    (126, 58, 9, '2026-02-09', 'ATIVA'),
    (127, 58, 16, '2026-02-09', 'ATIVA'),
    (128, 59, 6, '2026-02-10', 'ATIVA'),
    (129, 59, 7, '2026-02-10', 'ATIVA'),
    (130, 59, 8, '2026-02-10', 'ATIVA'),
    (131, 60, 7, '2026-03-09', 'CANCELADA'),
    (132, 60, 8, '2026-03-09', 'CANCELADA'),
    (133, 61, 1, '2026-03-21', 'ENCERRADA'),
    (134, 61, 5, '2026-03-21', 'ATIVA'),
    (135, 61, 14, '2026-03-21', 'ATIVA'),
    (136, 61, 17, '2026-03-21', 'ATIVA'),
    (137, 62, 14, '2026-03-28', 'ATIVA'),
    (138, 62, 15, '2026-03-28', 'ATIVA'),
    (139, 63, 2, '2026-03-31', 'ATIVA'),
    (140, 63, 5, '2026-03-31', 'ATIVA'),
    (141, 64, 11, '2026-04-08', 'TRANCADA'),
    (142, 65, 2, '2026-04-09', 'ATIVA'),
    (143, 65, 4, '2026-04-09', 'ATIVA'),
    (144, 65, 5, '2026-04-09', 'ATIVA'),
    (145, 66, 6, '2026-04-11', 'ATIVA'),
    (146, 67, 10, '2026-04-16', 'ATIVA'),
    (147, 67, 12, '2026-04-16', 'ATIVA'),
    (148, 67, 13, '2026-04-16', 'ATIVA'),
    (149, 68, 2, '2026-04-21', 'ATIVA'),
    (150, 68, 4, '2026-04-21', 'ATIVA'),
    (151, 68, 20, '2026-04-21', 'ATIVA'),
    (152, 69, 1, '2026-04-27', 'ATIVA'),
    (153, 69, 3, '2026-04-27', 'ATIVA'),
    (154, 70, 18, '2026-05-04', 'CANCELADA'),
    (155, 71, 19, '2026-05-11', 'ATIVA'),
    (156, 71, 20, '2026-05-11', 'ATIVA'),
    (157, 72, 18, '2026-05-11', 'ATIVA'),
    (158, 74, 10, '2026-06-03', 'ATIVA'),
    (159, 74, 11, '2026-06-03', 'ATIVA'),
    (160, 74, 12, '2026-06-03', 'ATIVA'),
    (161, 75, 9, '2026-06-11', 'ATIVA'),
    (162, 75, 13, '2026-06-11', 'ATIVA'),
    (163, 76, 7, '2026-06-13', 'ATIVA'),
    (164, 76, 9, '2026-06-13', 'ATIVA'),
    (165, 73, 1, '2026-07-01', 'CANCELADA'),
    (166, 73, 4, '2026-07-01', 'CANCELADA'),
    (167, 61, 4, '2026-07-03', 'ATIVA'),
    (168, 77, 1, '2026-07-06', 'ATIVA'),
    (169, 77, 2, '2026-07-06', 'ATIVA'),
    (170, 77, 3, '2026-07-06', 'ATIVA'),
    (171, 78, 13, '2026-07-06', 'ATIVA'),
    (172, 9, 11, '2026-07-15', 'ATIVA'),
    (173, 79, 1, '2026-07-15', 'ATIVA'),
    (174, 79, 15, '2026-07-15', 'ATIVA'),
    (175, 79, 16, '2026-07-15', 'ATIVA'),
    (176, 79, 17, '2026-07-15', 'ATIVA'),
    (177, 13, 15, '2026-07-22', 'ATIVA'),
    (178, 80, 1, '2026-07-27', 'ATIVA'),
    (179, 80, 2, '2026-07-27', 'ATIVA'),
    (180, 80, 4, '2026-07-27', 'ATIVA');
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (181, 81, 9, '2026-08-03', 'ATIVA'),
    (182, 81, 11, '2026-08-03', 'ATIVA'),
    (183, 48, 14, '2026-08-12', 'ATIVA'),
    (184, 82, 15, '2026-09-03', 'ATIVA'),
    (185, 82, 16, '2026-09-03', 'ATIVA'),
    (186, 82, 17, '2026-09-03', 'ATIVA'),
    (187, 83, 14, '2026-09-04', 'ATIVA'),
    (188, 83, 17, '2026-09-04', 'ATIVA'),
    (189, 46, 16, '2026-09-16', 'ATIVA'),
    (190, 84, 18, '2026-09-21', 'ATIVA'),
    (191, 85, 4, '2026-09-28', 'ATIVA'),
    (192, 85, 5, '2026-09-28', 'ATIVA'),
    (193, 86, 11, '2026-10-06', 'ATIVA'),
    (194, 87, 19, '2026-10-06', 'ATIVA'),
    (195, 87, 20, '2026-10-06', 'ATIVA'),
    (196, 88, 6, '2026-10-06', 'ATIVA'),
    (197, 88, 7, '2026-10-06', 'ATIVA'),
    (198, 88, 8, '2026-10-06', 'ATIVA'),
    (199, 89, 20, '2026-10-09', 'ATIVA'),
    (200, 90, 14, '2026-10-15', 'ATIVA'),
    (201, 90, 15, '2026-10-15', 'ATIVA'),
    (202, 91, 7, '2026-10-15', 'ATIVA'),
    (203, 91, 8, '2026-10-15', 'ATIVA'),
    (204, 92, 10, '2026-10-28', 'ATIVA');

-- -------------------------------------------------------------------------------------
-- 4.8 TRANCAMENTO (6) [RF06, RE04, RNF02]
-- 3 trancamentos já encerrados (aluno voltou) e 3 em curso (DT_RETORNO_EFETIVA vazia).
-- -------------------------------------------------------------------------------------
INSERT INTO TRANCAMENTO (ID_TRANCAMENTO, ID_MATRICULA, TP_TRANCAMENTO, DT_RETORNO_EFETIVA, DS_MOTIVO, DT_RETORNO_PREVISTA, DT_INICIO) VALUES
    (1, 26, 'LESAO', '2026-04-13', 'Fratura no dedo da mão direita em treino; tala por 5 semanas.', '2026-04-06', '2026-03-02'),
    (2, 104, 'RAZAO_MEDICA', '2026-06-08', 'Pneumonia; repouso por recomendação médica.', '2026-06-04', '2026-05-04'),
    (3, 1, 'LESAO', '2026-08-20', 'Estiramento muscular na coxa; fisioterapia.', '2026-08-17', '2026-07-10'),
    (4, 141, 'LESAO', NULL, 'Entorse grave no tornozelo esquerdo durante jogo de futebol; imobilização por 8 semanas.', '2026-12-15', '2026-09-15'),
    (5, 32, 'RAZAO_MEDICA', NULL, 'Cirurgia de vesícula agendada; afastamento recomendado pelo médico.', '2026-11-30', '2026-10-05'),
    (6, 33, 'LESAO', NULL, 'Ruptura parcial do ligamento do ombro direito; fisioterapia.', '2027-01-20', '2026-10-20');

-- -------------------------------------------------------------------------------------
-- 4.9 AULA (85) [RF05, RO07]
-- Todas as aulas de outubro/2026: cada turma ocorre uma vez por semana; 12/10 foi feriado
-- (sem aula) e a turma 21, recém-aberta, ainda não teve aula.
-- A aula 64 é a reposição (ID_AULA_ORIGEM = 50) da aula de Boxe de 20/10, interrompida por
-- queda de energia: fica registrada e ligada à aula perdida, mas não gera presença (PN07).
-- Cenário de auditoria: a aula 35 (Kickboxing, 14/10) foi dada pelo professor de Muay Thai (A04).
-- -------------------------------------------------------------------------------------
INSERT INTO AULA (ID_AULA, ID_PROFESSOR, ID_TURMA, DT_AULA, HR_INICIO, ID_AULA_ORIGEM) VALUES
    (1, 3, 12, '2026-10-01', '07:00:00', NULL),
    (2, 4, 17, '2026-10-01', '18:00:00', NULL),
    (3, 1, 4, '2026-10-01', '19:00:00', NULL),
    (4, 6, 20, '2026-10-01', '20:00:00', NULL),
    (5, 2, 8, '2026-10-02', '18:00:00', NULL),
    (6, 1, 5, '2026-10-02', '19:00:00', NULL),
    (7, 3, 13, '2026-10-02', '20:00:00', NULL),
    (8, 5, 18, '2026-10-03', '14:00:00', NULL),
    (9, 1, 1, '2026-10-05', '07:00:00', NULL),
    (10, 4, 14, '2026-10-05', '18:00:00', NULL),
    (11, 2, 6, '2026-10-05', '19:00:00', NULL),
    (12, 3, 9, '2026-10-05', '20:00:00', NULL),
    (13, 3, 10, '2026-10-06', '07:00:00', NULL),
    (14, 4, 15, '2026-10-06', '18:00:00', NULL),
    (15, 1, 2, '2026-10-06', '19:00:00', NULL),
    (16, 6, 19, '2026-10-06', '20:00:00', NULL),
    (17, 1, 3, '2026-10-07', '07:00:00', NULL),
    (18, 4, 16, '2026-10-07', '18:00:00', NULL),
    (19, 2, 7, '2026-10-07', '19:00:00', NULL),
    (20, 3, 11, '2026-10-07', '20:00:00', NULL),
    (21, 3, 12, '2026-10-08', '07:00:00', NULL),
    (22, 4, 17, '2026-10-08', '18:00:00', NULL),
    (23, 1, 4, '2026-10-08', '19:00:00', NULL),
    (24, 6, 20, '2026-10-08', '20:00:00', NULL),
    (25, 2, 8, '2026-10-09', '18:00:00', NULL),
    (26, 1, 5, '2026-10-09', '19:00:00', NULL),
    (27, 3, 13, '2026-10-09', '20:00:00', NULL),
    (28, 5, 18, '2026-10-10', '14:00:00', NULL),
    (29, 3, 10, '2026-10-13', '07:00:00', NULL),
    (30, 4, 15, '2026-10-13', '18:00:00', NULL),
    (31, 1, 2, '2026-10-13', '19:00:00', NULL),
    (32, 6, 19, '2026-10-13', '20:00:00', NULL),
    (33, 1, 3, '2026-10-14', '07:00:00', NULL),
    (34, 4, 16, '2026-10-14', '18:00:00', NULL),
    (35, 1, 7, '2026-10-14', '19:00:00', NULL),
    (36, 3, 11, '2026-10-14', '20:00:00', NULL),
    (37, 3, 12, '2026-10-15', '07:00:00', NULL),
    (38, 4, 17, '2026-10-15', '18:00:00', NULL),
    (39, 1, 4, '2026-10-15', '19:00:00', NULL),
    (40, 6, 20, '2026-10-15', '20:00:00', NULL),
    (41, 2, 8, '2026-10-16', '18:00:00', NULL),
    (42, 1, 5, '2026-10-16', '19:00:00', NULL),
    (43, 3, 13, '2026-10-16', '20:00:00', NULL),
    (44, 5, 18, '2026-10-17', '14:00:00', NULL),
    (45, 1, 1, '2026-10-19', '07:00:00', NULL),
    (46, 4, 14, '2026-10-19', '18:00:00', NULL),
    (47, 2, 6, '2026-10-19', '19:00:00', NULL),
    (48, 3, 9, '2026-10-19', '20:00:00', NULL),
    (49, 3, 10, '2026-10-20', '07:00:00', NULL),
    (50, 4, 15, '2026-10-20', '18:00:00', NULL),
    (51, 1, 2, '2026-10-20', '19:00:00', NULL),
    (52, 6, 19, '2026-10-20', '20:00:00', NULL),
    (53, 1, 3, '2026-10-21', '07:00:00', NULL),
    (54, 4, 16, '2026-10-21', '18:00:00', NULL),
    (55, 2, 7, '2026-10-21', '19:00:00', NULL),
    (56, 3, 11, '2026-10-21', '20:00:00', NULL),
    (57, 3, 12, '2026-10-22', '07:00:00', NULL),
    (58, 4, 17, '2026-10-22', '18:00:00', NULL),
    (59, 1, 4, '2026-10-22', '19:00:00', NULL),
    (60, 6, 20, '2026-10-22', '20:00:00', NULL);
INSERT INTO AULA (ID_AULA, ID_PROFESSOR, ID_TURMA, DT_AULA, HR_INICIO, ID_AULA_ORIGEM) VALUES
    (61, 2, 8, '2026-10-23', '18:00:00', NULL),
    (62, 1, 5, '2026-10-23', '19:00:00', NULL),
    (63, 3, 13, '2026-10-23', '20:00:00', NULL),
    (64, 4, 15, '2026-10-24', '12:00:00', 50),
    (65, 5, 18, '2026-10-24', '14:00:00', NULL),
    (66, 1, 1, '2026-10-26', '07:00:00', NULL),
    (67, 4, 14, '2026-10-26', '18:00:00', NULL),
    (68, 2, 6, '2026-10-26', '19:00:00', NULL),
    (69, 3, 9, '2026-10-26', '20:00:00', NULL),
    (70, 3, 10, '2026-10-27', '07:00:00', NULL),
    (71, 4, 15, '2026-10-27', '18:00:00', NULL),
    (72, 1, 2, '2026-10-27', '19:00:00', NULL),
    (73, 6, 19, '2026-10-27', '20:00:00', NULL),
    (74, 1, 3, '2026-10-28', '07:00:00', NULL),
    (75, 4, 16, '2026-10-28', '18:00:00', NULL),
    (76, 2, 7, '2026-10-28', '19:00:00', NULL),
    (77, 3, 11, '2026-10-28', '20:00:00', NULL),
    (78, 3, 12, '2026-10-29', '07:00:00', NULL),
    (79, 4, 17, '2026-10-29', '18:00:00', NULL),
    (80, 1, 4, '2026-10-29', '19:00:00', NULL),
    (81, 6, 20, '2026-10-29', '20:00:00', NULL),
    (82, 2, 8, '2026-10-30', '18:00:00', NULL),
    (83, 1, 5, '2026-10-30', '19:00:00', NULL),
    (84, 3, 13, '2026-10-30', '20:00:00', NULL),
    (85, 5, 18, '2026-10-31', '14:00:00', NULL);

-- -------------------------------------------------------------------------------------
-- 4.10 PRESENCA (704) [RF05, RO05, RE04, RE07]
-- Uma linha por matrícula ativa em cada aula de outubro. Não há linha para quem estava trancado
-- ou bloqueado por parcela em atraso (RE07), nem para a aula de reposição (PN07). Alguns alunos
-- têm frequência baixa de propósito em uma das modalidades (risco de evasão, consulta G09).
-- Cenários de auditoria: presença do aluno 34 na aula 29, já bloqueado por atraso (A02);
-- presença do aluno 15 na aula 15, durante o trancamento (A03).
-- -------------------------------------------------------------------------------------
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (1, 7, TRUE),
    (1, 22, TRUE),
    (1, 53, TRUE),
    (1, 71, TRUE),
    (1, 80, TRUE),
    (1, 92, TRUE),
    (1, 117, TRUE),
    (1, 147, TRUE),
    (1, 160, TRUE),
    (2, 20, TRUE),
    (2, 30, TRUE),
    (2, 99, TRUE),
    (2, 120, TRUE),
    (2, 136, FALSE),
    (2, 176, TRUE),
    (2, 186, TRUE),
    (2, 188, TRUE),
    (3, 10, TRUE),
    (3, 17, TRUE),
    (3, 28, TRUE),
    (3, 48, TRUE),
    (3, 68, TRUE),
    (3, 114, TRUE),
    (3, 143, TRUE),
    (3, 150, TRUE),
    (3, 167, TRUE),
    (3, 180, TRUE),
    (3, 191, TRUE),
    (4, 9, FALSE),
    (4, 56, TRUE),
    (4, 62, TRUE),
    (4, 107, TRUE),
    (4, 151, FALSE),
    (4, 156, TRUE),
    (5, 14, TRUE),
    (5, 35, TRUE),
    (5, 42, TRUE),
    (5, 77, TRUE),
    (5, 87, TRUE),
    (5, 130, TRUE),
    (6, 2, TRUE),
    (6, 11, TRUE),
    (6, 115, TRUE),
    (6, 134, TRUE),
    (6, 140, FALSE),
    (6, 144, FALSE),
    (6, 192, TRUE),
    (7, 23, TRUE),
    (7, 38, TRUE),
    (7, 67, TRUE),
    (7, 72, TRUE),
    (7, 75, FALSE),
    (7, 83, TRUE),
    (7, 85, TRUE),
    (7, 96, TRUE),
    (7, 125, TRUE),
    (7, 148, TRUE),
    (7, 162, TRUE),
    (7, 171, TRUE),
    (8, 25, TRUE),
    (8, 39, FALSE),
    (8, 40, TRUE),
    (8, 54, TRUE),
    (8, 60, FALSE),
    (8, 93, TRUE),
    (8, 103, TRUE),
    (8, 110, TRUE),
    (8, 121, TRUE),
    (8, 122, TRUE),
    (8, 157, TRUE),
    (8, 190, TRUE),
    (9, 15, TRUE),
    (9, 26, TRUE),
    (9, 43, FALSE),
    (9, 49, FALSE),
    (9, 101, TRUE),
    (9, 108, TRUE),
    (9, 152, FALSE),
    (9, 168, TRUE),
    (9, 173, TRUE),
    (9, 178, TRUE),
    (10, 18, FALSE),
    (10, 118, TRUE),
    (10, 135, FALSE),
    (10, 137, TRUE),
    (10, 183, FALSE),
    (10, 187, TRUE),
    (11, 4, FALSE),
    (11, 24, TRUE),
    (11, 41, TRUE),
    (11, 86, TRUE),
    (11, 128, TRUE),
    (11, 145, TRUE),
    (12, 31, TRUE),
    (12, 36, TRUE),
    (12, 65, TRUE),
    (12, 73, FALSE),
    (12, 78, FALSE),
    (12, 84, TRUE),
    (12, 88, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (12, 94, TRUE),
    (12, 123, TRUE),
    (12, 126, TRUE),
    (12, 161, TRUE),
    (12, 164, TRUE),
    (12, 181, TRUE),
    (13, 5, FALSE),
    (13, 21, TRUE),
    (13, 33, TRUE),
    (13, 51, FALSE),
    (13, 70, TRUE),
    (13, 79, TRUE),
    (13, 81, TRUE),
    (13, 90, FALSE),
    (13, 95, TRUE),
    (13, 116, TRUE),
    (13, 146, TRUE),
    (13, 158, TRUE),
    (14, 19, TRUE),
    (14, 58, TRUE),
    (14, 97, TRUE),
    (14, 104, TRUE),
    (14, 119, TRUE),
    (14, 138, TRUE),
    (14, 174, TRUE),
    (14, 177, FALSE),
    (14, 184, TRUE),
    (15, 1, FALSE),
    (15, 3, TRUE),
    (15, 16, TRUE),
    (15, 32, TRUE),
    (15, 44, TRUE),
    (15, 47, TRUE),
    (15, 109, TRUE),
    (15, 139, FALSE),
    (15, 142, TRUE),
    (15, 149, TRUE),
    (15, 169, TRUE),
    (15, 179, TRUE),
    (16, 8, TRUE),
    (16, 55, TRUE),
    (16, 61, TRUE),
    (16, 106, TRUE),
    (16, 155, TRUE),
    (16, 194, FALSE),
    (17, 27, TRUE),
    (17, 45, TRUE),
    (17, 50, TRUE),
    (17, 102, FALSE),
    (17, 153, TRUE),
    (17, 170, TRUE),
    (18, 12, TRUE),
    (18, 59, TRUE),
    (18, 98, TRUE),
    (18, 127, TRUE),
    (18, 175, TRUE),
    (18, 185, TRUE),
    (18, 189, TRUE),
    (19, 13, TRUE),
    (19, 34, TRUE),
    (19, 69, TRUE),
    (19, 76, TRUE),
    (19, 129, TRUE),
    (19, 163, TRUE),
    (19, 197, FALSE),
    (20, 6, FALSE),
    (20, 37, TRUE),
    (20, 52, TRUE),
    (20, 66, TRUE),
    (20, 74, FALSE),
    (20, 82, TRUE),
    (20, 89, TRUE),
    (20, 91, TRUE),
    (20, 124, FALSE),
    (20, 159, FALSE),
    (20, 172, TRUE),
    (20, 182, TRUE),
    (20, 193, TRUE),
    (21, 7, TRUE),
    (21, 22, TRUE),
    (21, 53, TRUE),
    (21, 80, TRUE),
    (21, 92, TRUE),
    (21, 117, TRUE),
    (21, 147, TRUE),
    (21, 160, TRUE),
    (22, 20, TRUE),
    (22, 30, TRUE),
    (22, 99, TRUE),
    (22, 120, FALSE),
    (22, 136, FALSE),
    (22, 176, TRUE),
    (22, 186, TRUE),
    (22, 188, TRUE),
    (23, 28, TRUE),
    (23, 48, TRUE),
    (23, 114, TRUE),
    (23, 150, TRUE),
    (23, 167, TRUE),
    (24, 56, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (24, 107, TRUE),
    (24, 151, FALSE),
    (24, 156, TRUE),
    (24, 195, TRUE),
    (25, 14, FALSE),
    (25, 35, TRUE),
    (25, 42, TRUE),
    (25, 77, FALSE),
    (25, 87, TRUE),
    (25, 198, TRUE),
    (26, 2, FALSE),
    (26, 115, FALSE),
    (26, 134, TRUE),
    (27, 23, TRUE),
    (27, 38, TRUE),
    (27, 67, TRUE),
    (27, 75, FALSE),
    (27, 83, TRUE),
    (27, 85, TRUE),
    (27, 96, TRUE),
    (27, 125, TRUE),
    (27, 148, TRUE),
    (27, 162, TRUE),
    (27, 171, TRUE),
    (28, 25, TRUE),
    (28, 39, TRUE),
    (28, 40, TRUE),
    (28, 54, TRUE),
    (28, 60, TRUE),
    (28, 93, TRUE),
    (28, 103, TRUE),
    (28, 121, TRUE),
    (28, 122, TRUE),
    (28, 157, TRUE),
    (29, 5, FALSE),
    (29, 21, TRUE),
    (29, 33, TRUE),
    (29, 51, TRUE),
    (29, 70, TRUE),
    (29, 79, TRUE),
    (29, 81, FALSE),
    (29, 90, TRUE),
    (29, 95, TRUE),
    (29, 116, TRUE),
    (29, 146, TRUE),
    (29, 158, TRUE),
    (30, 19, TRUE),
    (30, 58, TRUE),
    (30, 97, TRUE),
    (30, 104, TRUE),
    (30, 119, TRUE),
    (30, 138, TRUE),
    (30, 174, FALSE),
    (30, 177, TRUE),
    (30, 184, TRUE),
    (31, 1, FALSE),
    (31, 44, TRUE),
    (31, 47, TRUE),
    (31, 109, TRUE),
    (31, 142, TRUE),
    (31, 149, TRUE),
    (31, 169, TRUE),
    (32, 8, TRUE),
    (32, 55, TRUE),
    (32, 106, TRUE),
    (32, 155, TRUE),
    (32, 194, TRUE),
    (33, 27, TRUE),
    (33, 45, TRUE),
    (33, 50, FALSE),
    (33, 102, TRUE),
    (33, 153, FALSE),
    (33, 170, TRUE),
    (34, 59, TRUE),
    (34, 98, FALSE),
    (34, 175, FALSE),
    (34, 185, FALSE),
    (34, 189, FALSE),
    (35, 13, TRUE),
    (35, 34, TRUE),
    (35, 76, TRUE),
    (35, 197, FALSE),
    (36, 6, FALSE),
    (36, 37, TRUE),
    (36, 52, TRUE),
    (36, 66, TRUE),
    (36, 74, FALSE),
    (36, 82, TRUE),
    (36, 89, TRUE),
    (36, 91, TRUE),
    (36, 124, TRUE),
    (36, 159, TRUE),
    (36, 172, FALSE),
    (36, 182, TRUE),
    (36, 193, TRUE),
    (37, 7, FALSE),
    (37, 22, TRUE),
    (37, 53, TRUE),
    (37, 80, TRUE),
    (37, 92, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (37, 117, TRUE),
    (37, 147, TRUE),
    (37, 160, TRUE),
    (38, 20, FALSE),
    (38, 30, TRUE),
    (38, 99, TRUE),
    (38, 120, TRUE),
    (38, 136, TRUE),
    (38, 176, FALSE),
    (38, 186, TRUE),
    (38, 188, TRUE),
    (39, 10, TRUE),
    (39, 28, TRUE),
    (39, 48, TRUE),
    (39, 68, TRUE),
    (39, 114, TRUE),
    (39, 143, TRUE),
    (39, 150, TRUE),
    (39, 167, TRUE),
    (39, 191, TRUE),
    (40, 9, TRUE),
    (40, 56, TRUE),
    (40, 107, TRUE),
    (40, 151, FALSE),
    (40, 156, TRUE),
    (40, 195, TRUE),
    (40, 199, TRUE),
    (41, 14, TRUE),
    (41, 35, TRUE),
    (41, 42, TRUE),
    (41, 77, TRUE),
    (41, 87, TRUE),
    (41, 130, TRUE),
    (41, 198, FALSE),
    (41, 203, TRUE),
    (42, 2, FALSE),
    (42, 11, TRUE),
    (42, 115, TRUE),
    (42, 134, TRUE),
    (42, 144, TRUE),
    (42, 192, TRUE),
    (43, 23, TRUE),
    (43, 38, TRUE),
    (43, 67, TRUE),
    (43, 75, TRUE),
    (43, 83, TRUE),
    (43, 85, TRUE),
    (43, 96, TRUE),
    (43, 125, TRUE),
    (43, 148, TRUE),
    (43, 162, TRUE),
    (43, 171, TRUE),
    (44, 25, TRUE),
    (44, 39, TRUE),
    (44, 40, TRUE),
    (44, 54, TRUE),
    (44, 60, FALSE),
    (44, 93, TRUE),
    (44, 103, TRUE),
    (44, 110, TRUE),
    (44, 121, TRUE),
    (44, 122, TRUE),
    (44, 157, TRUE),
    (44, 190, TRUE),
    (45, 15, TRUE),
    (45, 26, TRUE),
    (45, 43, TRUE),
    (45, 49, FALSE),
    (45, 101, TRUE),
    (45, 108, TRUE),
    (45, 152, FALSE),
    (45, 168, TRUE),
    (45, 173, TRUE),
    (46, 18, TRUE),
    (46, 118, TRUE),
    (46, 135, FALSE),
    (46, 137, TRUE),
    (46, 183, TRUE),
    (46, 187, TRUE),
    (46, 200, TRUE),
    (47, 4, TRUE),
    (47, 24, FALSE),
    (47, 41, TRUE),
    (47, 86, TRUE),
    (47, 128, TRUE),
    (47, 145, FALSE),
    (47, 196, TRUE),
    (48, 31, TRUE),
    (48, 36, TRUE),
    (48, 65, FALSE),
    (48, 73, TRUE),
    (48, 78, TRUE),
    (48, 84, TRUE),
    (48, 88, FALSE),
    (48, 94, TRUE),
    (48, 123, TRUE),
    (48, 161, TRUE),
    (48, 181, TRUE),
    (49, 5, FALSE),
    (49, 21, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (49, 51, TRUE),
    (49, 79, TRUE),
    (49, 81, TRUE),
    (49, 90, TRUE),
    (49, 95, TRUE),
    (49, 116, TRUE),
    (49, 146, TRUE),
    (49, 158, TRUE),
    (50, 19, FALSE),
    (50, 58, TRUE),
    (50, 97, TRUE),
    (50, 104, TRUE),
    (50, 119, FALSE),
    (50, 138, TRUE),
    (50, 174, FALSE),
    (50, 177, TRUE),
    (50, 184, TRUE),
    (50, 201, TRUE),
    (51, 1, FALSE),
    (51, 3, TRUE),
    (51, 16, TRUE),
    (51, 44, TRUE),
    (51, 47, TRUE),
    (51, 109, TRUE),
    (51, 142, TRUE),
    (51, 149, TRUE),
    (51, 169, TRUE),
    (52, 8, TRUE),
    (52, 55, TRUE),
    (52, 106, TRUE),
    (52, 155, TRUE),
    (52, 194, TRUE),
    (53, 27, TRUE),
    (53, 45, TRUE),
    (53, 50, FALSE),
    (53, 102, TRUE),
    (53, 153, FALSE),
    (53, 170, FALSE),
    (54, 12, TRUE),
    (54, 59, TRUE),
    (54, 98, FALSE),
    (54, 175, TRUE),
    (54, 185, FALSE),
    (54, 189, TRUE),
    (55, 13, TRUE),
    (55, 34, TRUE),
    (55, 69, TRUE),
    (55, 76, TRUE),
    (55, 129, TRUE),
    (55, 197, TRUE),
    (55, 202, TRUE),
    (56, 6, FALSE),
    (56, 37, FALSE),
    (56, 52, TRUE),
    (56, 66, TRUE),
    (56, 74, FALSE),
    (56, 82, TRUE),
    (56, 89, TRUE),
    (56, 91, TRUE),
    (56, 124, TRUE),
    (56, 159, TRUE),
    (56, 172, TRUE),
    (56, 182, FALSE),
    (56, 193, TRUE),
    (57, 7, FALSE),
    (57, 22, TRUE),
    (57, 53, TRUE),
    (57, 80, TRUE),
    (57, 92, TRUE),
    (57, 117, FALSE),
    (57, 147, TRUE),
    (57, 160, FALSE),
    (58, 20, TRUE),
    (58, 30, TRUE),
    (58, 99, TRUE),
    (58, 120, FALSE),
    (58, 136, FALSE),
    (58, 176, TRUE),
    (58, 186, TRUE),
    (58, 188, TRUE),
    (59, 10, TRUE),
    (59, 17, TRUE),
    (59, 28, TRUE),
    (59, 48, TRUE),
    (59, 68, TRUE),
    (59, 114, FALSE),
    (59, 143, TRUE),
    (59, 150, TRUE),
    (59, 167, TRUE),
    (59, 191, TRUE),
    (60, 9, TRUE),
    (60, 56, TRUE),
    (60, 107, TRUE),
    (60, 151, TRUE),
    (60, 156, TRUE),
    (60, 195, TRUE),
    (60, 199, TRUE),
    (61, 14, TRUE),
    (61, 35, TRUE),
    (61, 42, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (61, 77, TRUE),
    (61, 87, TRUE),
    (61, 130, TRUE),
    (61, 198, TRUE),
    (61, 203, TRUE),
    (62, 2, FALSE),
    (62, 11, TRUE),
    (62, 115, TRUE),
    (62, 134, TRUE),
    (62, 144, TRUE),
    (62, 192, TRUE),
    (63, 23, TRUE),
    (63, 38, TRUE),
    (63, 67, TRUE),
    (63, 75, FALSE),
    (63, 83, TRUE),
    (63, 85, FALSE),
    (63, 96, TRUE),
    (63, 125, TRUE),
    (63, 148, TRUE),
    (63, 162, TRUE),
    (63, 171, TRUE),
    (65, 25, TRUE),
    (65, 39, TRUE),
    (65, 40, TRUE),
    (65, 54, FALSE),
    (65, 60, TRUE),
    (65, 93, TRUE),
    (65, 103, TRUE),
    (65, 110, TRUE),
    (65, 121, TRUE),
    (65, 122, TRUE),
    (65, 157, TRUE),
    (65, 190, TRUE),
    (66, 15, TRUE),
    (66, 26, TRUE),
    (66, 43, TRUE),
    (66, 49, TRUE),
    (66, 101, TRUE),
    (66, 108, TRUE),
    (66, 152, TRUE),
    (66, 168, TRUE),
    (66, 173, TRUE),
    (67, 18, TRUE),
    (67, 118, TRUE),
    (67, 135, TRUE),
    (67, 137, TRUE),
    (67, 183, TRUE),
    (67, 187, TRUE),
    (67, 200, TRUE),
    (68, 4, TRUE),
    (68, 24, TRUE),
    (68, 41, TRUE),
    (68, 86, TRUE),
    (68, 128, TRUE),
    (68, 145, TRUE),
    (68, 196, TRUE),
    (69, 31, TRUE),
    (69, 36, TRUE),
    (69, 65, TRUE),
    (69, 73, FALSE),
    (69, 78, TRUE),
    (69, 84, TRUE),
    (69, 88, FALSE),
    (69, 94, TRUE),
    (69, 123, TRUE),
    (69, 161, FALSE),
    (69, 181, TRUE),
    (70, 5, FALSE),
    (70, 21, TRUE),
    (70, 51, TRUE),
    (70, 79, TRUE),
    (70, 81, TRUE),
    (70, 90, TRUE),
    (70, 95, TRUE),
    (70, 116, TRUE),
    (70, 146, FALSE),
    (70, 158, TRUE),
    (71, 19, TRUE),
    (71, 58, TRUE),
    (71, 97, TRUE),
    (71, 104, TRUE),
    (71, 119, TRUE),
    (71, 138, TRUE),
    (71, 174, TRUE),
    (71, 177, TRUE),
    (71, 184, TRUE),
    (71, 201, TRUE),
    (72, 1, FALSE),
    (72, 3, TRUE),
    (72, 16, TRUE),
    (72, 44, FALSE),
    (72, 47, TRUE),
    (72, 109, TRUE),
    (72, 142, TRUE),
    (72, 149, TRUE),
    (72, 169, TRUE),
    (73, 8, TRUE),
    (73, 55, TRUE),
    (73, 106, FALSE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (73, 155, TRUE),
    (73, 194, TRUE),
    (74, 27, TRUE),
    (74, 45, TRUE),
    (74, 50, TRUE),
    (74, 102, TRUE),
    (74, 153, TRUE),
    (74, 170, TRUE),
    (75, 12, TRUE),
    (75, 59, TRUE),
    (75, 98, TRUE),
    (75, 175, FALSE),
    (75, 185, TRUE),
    (75, 189, TRUE),
    (76, 13, TRUE),
    (76, 34, TRUE),
    (76, 69, TRUE),
    (76, 76, TRUE),
    (76, 129, TRUE),
    (76, 197, FALSE),
    (76, 202, FALSE),
    (77, 6, FALSE),
    (77, 37, TRUE),
    (77, 52, TRUE),
    (77, 66, TRUE),
    (77, 74, FALSE),
    (77, 82, TRUE),
    (77, 89, FALSE),
    (77, 91, TRUE),
    (77, 124, TRUE),
    (77, 159, TRUE),
    (77, 172, TRUE),
    (77, 182, TRUE),
    (77, 193, TRUE),
    (78, 7, FALSE),
    (78, 22, TRUE),
    (78, 53, TRUE),
    (78, 80, TRUE),
    (78, 92, TRUE),
    (78, 117, TRUE),
    (78, 147, TRUE),
    (78, 160, TRUE),
    (79, 20, TRUE),
    (79, 30, TRUE),
    (79, 99, TRUE),
    (79, 120, FALSE),
    (79, 136, FALSE),
    (79, 176, FALSE),
    (79, 186, TRUE),
    (79, 188, TRUE),
    (80, 10, FALSE),
    (80, 17, TRUE),
    (80, 28, TRUE),
    (80, 48, TRUE),
    (80, 68, FALSE),
    (80, 114, TRUE),
    (80, 143, TRUE),
    (80, 150, TRUE),
    (80, 167, TRUE),
    (80, 191, TRUE),
    (81, 9, TRUE),
    (81, 56, TRUE),
    (81, 107, TRUE),
    (81, 151, TRUE),
    (81, 156, TRUE),
    (81, 195, FALSE),
    (81, 199, TRUE),
    (82, 14, TRUE),
    (82, 35, TRUE),
    (82, 42, TRUE),
    (82, 77, TRUE),
    (82, 87, TRUE),
    (82, 130, TRUE),
    (82, 198, TRUE),
    (82, 203, TRUE),
    (83, 2, TRUE),
    (83, 11, TRUE),
    (83, 115, FALSE),
    (83, 134, TRUE),
    (83, 144, TRUE),
    (83, 192, TRUE),
    (84, 23, TRUE),
    (84, 38, TRUE),
    (84, 67, TRUE),
    (84, 75, FALSE),
    (84, 83, TRUE),
    (84, 85, TRUE),
    (84, 96, TRUE),
    (84, 125, TRUE),
    (84, 148, TRUE),
    (84, 162, FALSE),
    (84, 171, TRUE),
    (85, 25, TRUE),
    (85, 39, TRUE),
    (85, 40, TRUE),
    (85, 54, TRUE),
    (85, 60, TRUE),
    (85, 93, TRUE),
    (85, 103, FALSE),
    (85, 110, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (85, 121, TRUE),
    (85, 122, TRUE),
    (85, 157, TRUE),
    (85, 190, TRUE);

-- -------------------------------------------------------------------------------------
-- 4.11 PLANO (8) [RF04, RO01, RO04]
-- 4 ciclos (mensal, trimestral, semestral e anual) nas versões individual e Família.
-- O Família Anual ainda não tem nenhum contrato (cenário de plano sem venda).
-- Os percentuais de multa em DS_CONDICAO são ilustrativos: os valores reais são confidenciais.
-- -------------------------------------------------------------------------------------
INSERT INTO PLANO (ID_PLANO, NM_PLANO, QT_DURACAO_MESES, VL_MENSALIDADE, PC_DESCONTO, QT_MINIMA_PESSOAS, DS_CONDICAO) VALUES
    (1, 'Mensal', 1, 180.00, 0.00, NULL, 'Sem fidelidade; cancelamento a qualquer momento, sem multa. Atraso gera apenas bloqueio de acesso.'),
    (2, 'Trimestral', 3, 180.00, 5.00, NULL, 'Fidelidade de 3 meses. Multa de 2% por atraso. Cancelamento antecipado: multa de 20% sobre as mensalidades restantes.'),
    (3, 'Semestral', 6, 180.00, 10.00, NULL, 'Fidelidade de 6 meses. Multa de 2% por atraso. Cancelamento antecipado: multa de 20% sobre as mensalidades restantes.'),
    (4, 'Anual', 12, 180.00, 15.00, NULL, 'Fidelidade de 12 meses. Multa de 2% por atraso. Cancelamento antecipado: multa de 20% sobre as mensalidades restantes.'),
    (5, 'Família Mensal', 1, 180.00, 10.00, 2, 'Valor por pessoa; cada familiar tem o seu contrato. Sem fidelidade.'),
    (6, 'Família Trimestral', 3, 180.00, 15.00, 2, 'Valor por pessoa; fidelidade de 3 meses. Mesmas regras de multa do plano Trimestral.'),
    (7, 'Família Semestral', 6, 180.00, 20.00, 2, 'Valor por pessoa; fidelidade de 6 meses. Mesmas regras de multa do plano Semestral.'),
    (8, 'Família Anual', 12, 180.00, 25.00, 2, 'Valor por pessoa; fidelidade de 12 meses. Mesmas regras de multa do plano Anual.');

-- -------------------------------------------------------------------------------------
-- 4.12 CONTRATO (92) e PARTICIPA [RF04, RO01, RO04, RE04]
-- 86 contratos vigentes + 6 cancelados. VL_MENSAL_ACORDADO = valor do plano com desconto
-- (no Família, o valor é por pessoa e cada familiar tem o seu contrato). Modalidade extra gera
-- VL_ACRESCIMO_MODALIDADE (R$ 60,00 cada).
-- DT_FIM é o fim do ciclo atual: o contrato renova sozinho e só termina por cancelamento; quem já voltou
-- de trancamento teve o DT_FIM prorrogado pelos dias de afastamento (RE04).
-- Multa rescisória (RO04) = 20% (percentual ilustrativo) x mensalidade x parcelas que faltavam para o
-- fim do ciclo na data do cancelamento:
--   contrato 47 (Anual, cancelado em 30/07): 20% x R$ 153,00 x 5 (ago a dez) = R$ 153,00;
--   contrato 64 (Semestral, cancelado em 03/09): 20% x R$ 162,00 x 2 (set e out) = R$ 64,80.
-- Cenários de auditoria: o contrato 66 (Trimestral, jul a set) foi cancelado em 14/08, com a parcela
-- de setembro ainda a cumprir, sem multa (A08); o contrato 92 é um segundo contrato vigente do
-- aluno 9, aberto para o Jiu-Jitsu em vez do acréscimo no contrato 9 (A12).
-- -------------------------------------------------------------------------------------
INSERT INTO CONTRATO (ID_CONTRATO, ID_ALUNO, ID_PLANO, DT_INICIO, DT_FIM, VL_MENSAL_ACORDADO, VL_ACRESCIMO_MODALIDADE, DT_CANCELAMENTO, VL_MULTA_RESCISORIA) VALUES
    (1, 1, 2, '2024-04-03', '2027-02-13', 171.00, NULL, NULL, NULL),
    (2, 2, 3, '2024-06-07', '2026-12-07', 162.00, NULL, NULL, NULL),
    (3, 3, 2, '2024-07-12', '2027-01-12', 171.00, 60.00, NULL, NULL),
    (4, 4, 3, '2024-08-05', '2027-02-05', 162.00, NULL, NULL, NULL),
    (5, 5, 2, '2024-10-04', '2027-01-04', 171.00, NULL, NULL, NULL),
    (6, 6, 3, '2024-10-25', '2027-04-25', 162.00, NULL, NULL, NULL),
    (7, 7, 2, '2024-11-12', '2026-11-12', 171.00, NULL, NULL, NULL),
    (8, 8, 3, '2024-11-25', '2026-11-25', 162.00, NULL, NULL, NULL),
    (9, 9, 3, '2024-11-28', '2026-11-28', 162.00, NULL, NULL, NULL),
    (10, 10, 1, '2024-12-16', '2026-11-16', 180.00, NULL, NULL, NULL),
    (11, 11, 1, '2024-12-20', '2026-11-20', 180.00, 60.00, NULL, NULL),
    (12, 12, 3, '2024-12-23', '2027-02-03', 162.00, NULL, NULL, NULL),
    (13, 13, 1, '2025-01-02', '2026-11-02', 180.00, NULL, NULL, NULL),
    (14, 14, 4, '2025-01-02', '2027-01-02', 153.00, NULL, NULL, NULL),
    (15, 15, 3, '2025-01-07', '2027-01-07', 162.00, NULL, NULL, NULL),
    (16, 16, 1, '2025-02-19', '2026-11-19', 180.00, NULL, NULL, NULL),
    (17, 17, 4, '2025-02-21', '2027-02-21', 153.00, NULL, NULL, NULL),
    (18, 18, 5, '2025-03-10', '2026-11-10', 162.00, NULL, NULL, NULL),
    (19, 21, 1, '2025-03-13', '2026-11-13', 180.00, NULL, NULL, NULL),
    (20, 22, 4, '2025-04-11', '2027-04-11', 153.00, NULL, NULL, NULL),
    (21, 23, 1, '2025-04-12', '2026-11-12', 180.00, NULL, NULL, NULL),
    (22, 24, 2, '2025-04-14', '2027-01-14', 171.00, NULL, NULL, NULL),
    (23, 25, 1, '2025-04-16', '2026-11-16', 180.00, NULL, NULL, NULL),
    (24, 26, 2, '2025-04-30', '2027-01-30', 171.00, NULL, NULL, NULL),
    (25, 27, 2, '2025-05-26', '2026-11-26', 171.00, 60.00, NULL, NULL),
    (26, 28, 1, '2025-06-02', '2026-10-02', 180.00, NULL, '2026-09-12', NULL),
    (27, 29, 2, '2025-06-14', '2026-12-14', 171.00, 60.00, NULL, NULL),
    (28, 30, 4, '2025-06-21', '2027-06-21', 153.00, NULL, NULL, NULL),
    (29, 31, 1, '2025-06-23', '2026-11-23', 180.00, NULL, NULL, NULL),
    (30, 32, 2, '2025-07-14', '2027-01-14', 171.00, NULL, NULL, NULL),
    (31, 33, 3, '2025-07-22', '2027-01-22', 162.00, 60.00, NULL, NULL),
    (32, 34, 1, '2025-07-22', '2026-11-22', 180.00, NULL, NULL, NULL),
    (33, 35, 3, '2025-07-28', '2027-01-28', 162.00, NULL, NULL, NULL),
    (34, 36, 6, '2025-08-04', '2026-11-04', 153.00, NULL, NULL, NULL),
    (35, 39, 1, '2025-08-16', '2026-11-16', 180.00, NULL, NULL, NULL),
    (36, 40, 2, '2025-09-01', '2026-12-01', 171.00, NULL, NULL, NULL),
    (37, 41, 4, '2025-09-18', '2027-09-18', 153.00, NULL, NULL, NULL),
    (38, 42, 2, '2025-10-10', '2027-01-10', 171.00, 60.00, NULL, NULL),
    (39, 43, 1, '2025-10-13', '2026-11-13', 180.00, NULL, NULL, NULL),
    (40, 44, 4, '2025-10-23', '2027-10-23', 153.00, NULL, NULL, NULL),
    (41, 45, 1, '2025-11-03', '2026-09-03', 180.00, NULL, '2026-08-20', NULL),
    (42, 46, 2, '2025-12-05', '2026-12-05', 171.00, NULL, NULL, NULL),
    (43, 47, 1, '2025-12-10', '2026-11-10', 180.00, NULL, NULL, NULL),
    (44, 48, 3, '2025-12-16', '2027-01-20', 162.00, 60.00, NULL, NULL),
    (45, 49, 2, '2025-12-30', '2026-12-30', 171.00, NULL, NULL, NULL),
    (46, 50, 1, '2026-01-02', '2026-11-02', 180.00, NULL, NULL, NULL),
    (47, 51, 4, '2026-01-05', '2027-01-05', 153.00, NULL, '2026-07-30', 153.00),
    (48, 52, 1, '2026-01-05', '2026-11-05', 180.00, NULL, NULL, NULL),
    (49, 53, 1, '2026-01-26', '2026-11-26', 180.00, NULL, NULL, NULL),
    (50, 54, 7, '2026-02-02', '2027-02-02', 144.00, NULL, NULL, NULL),
    (51, 57, 3, '2026-02-09', '2027-02-09', 162.00, NULL, NULL, NULL),
    (52, 58, 3, '2026-02-09', '2027-02-09', 162.00, 60.00, NULL, NULL),
    (53, 59, 1, '2026-02-10', '2026-11-10', 180.00, NULL, NULL, NULL),
    (54, 60, 1, '2026-03-09', '2026-10-09', 180.00, NULL, '2026-09-25', NULL),
    (55, 61, 2, '2026-03-21', '2026-12-21', 171.00, 60.00, NULL, NULL),
    (56, 62, 3, '2026-03-28', '2027-03-28', 162.00, NULL, NULL, NULL),
    (57, 63, 1, '2026-03-31', '2026-11-30', 180.00, NULL, NULL, NULL),
    (58, 64, 2, '2026-04-08', '2027-01-08', 171.00, NULL, NULL, NULL),
    (59, 65, 1, '2026-04-09', '2026-11-09', 180.00, NULL, NULL, NULL),
    (60, 66, 4, '2026-04-11', '2027-04-11', 153.00, NULL, NULL, NULL);
INSERT INTO CONTRATO (ID_CONTRATO, ID_ALUNO, ID_PLANO, DT_INICIO, DT_FIM, VL_MENSAL_ACORDADO, VL_ACRESCIMO_MODALIDADE, DT_CANCELAMENTO, VL_MULTA_RESCISORIA) VALUES
    (61, 67, 2, '2026-04-16', '2027-01-16', 171.00, NULL, NULL, NULL),
    (62, 68, 1, '2026-04-21', '2026-11-21', 180.00, 60.00, NULL, NULL),
    (63, 69, 1, '2026-04-27', '2026-11-27', 180.00, NULL, NULL, NULL),
    (64, 70, 3, '2026-05-04', '2026-11-04', 162.00, NULL, '2026-09-03', 64.80),
    (65, 71, 5, '2026-05-11', '2026-11-11', 162.00, NULL, NULL, NULL),
    (66, 73, 2, '2026-07-01', '2026-10-01', 171.00, NULL, '2026-08-14', NULL),
    (67, 74, 1, '2026-06-03', '2026-11-03', 180.00, NULL, NULL, NULL),
    (68, 75, 1, '2026-06-11', '2026-11-11', 180.00, NULL, NULL, NULL),
    (69, 76, 2, '2026-06-13', '2026-12-13', 171.00, 60.00, NULL, NULL),
    (70, 77, 6, '2026-07-06', '2027-01-06', 153.00, NULL, NULL, NULL),
    (71, 79, 1, '2026-07-15', '2026-11-15', 180.00, 60.00, NULL, NULL),
    (72, 80, 1, '2026-07-27', '2026-11-27', 180.00, NULL, NULL, NULL),
    (73, 81, 1, '2026-08-03', '2026-11-03', 180.00, NULL, NULL, NULL),
    (74, 82, 4, '2026-09-03', '2027-09-03', 153.00, NULL, NULL, NULL),
    (75, 83, 2, '2026-09-04', '2026-12-04', 171.00, NULL, NULL, NULL),
    (76, 84, 1, '2026-09-21', '2026-11-21', 180.00, NULL, NULL, NULL),
    (77, 85, 4, '2026-09-28', '2027-09-28', 153.00, NULL, NULL, NULL),
    (78, 86, 1, '2026-10-06', '2026-11-06', 180.00, NULL, NULL, NULL),
    (79, 87, 1, '2026-10-06', '2026-11-06', 180.00, NULL, NULL, NULL),
    (80, 88, 4, '2026-10-06', '2027-10-06', 153.00, NULL, NULL, NULL),
    (81, 89, 1, '2026-10-09', '2026-11-09', 180.00, NULL, NULL, NULL),
    (82, 90, 3, '2026-10-15', '2027-04-15', 162.00, NULL, NULL, NULL),
    (83, 91, 1, '2026-10-15', '2026-11-15', 180.00, NULL, NULL, NULL),
    -- Plano Família: cada familiar tem o próprio contrato, no mesmo plano e ciclo do familiar
    -- que fechou o grupo (decisão 11 da seção 1.5 do README)
    (84, 19, 5, '2025-03-10', '2026-11-10', 162.00, NULL, NULL, NULL),
    (85, 20, 5, '2025-03-10', '2026-11-10', 162.00, NULL, NULL, NULL),
    (86, 37, 6, '2025-08-04', '2026-11-04', 153.00, NULL, NULL, NULL),
    (87, 38, 6, '2025-08-04', '2026-11-04', 153.00, NULL, NULL, NULL),
    (88, 55, 7, '2026-02-02', '2027-02-02', 144.00, NULL, NULL, NULL),
    (89, 56, 7, '2026-02-02', '2027-02-02', 144.00, NULL, NULL, NULL),
    (90, 72, 5, '2026-05-11', '2026-11-11', 162.00, NULL, NULL, NULL),
    (91, 78, 6, '2026-07-06', '2027-01-06', 153.00, NULL, NULL, NULL),
    -- A12: segundo contrato do aluno 9 (Jiu-Jitsu), que deveria ser acréscimo no contrato 9
    (92, 9, 1, '2026-07-15', '2026-11-15', 180.00, NULL, NULL, NULL);

INSERT INTO PARTICIPA (ID_MODALIDADE, ID_CONTRATO) VALUES
    (1, 1),
    (1, 2),
    (1, 5),
    (1, 8),
    (1, 12),
    (1, 15),
    (1, 20),
    (1, 22),
    (1, 23),
    (1, 31),
    (1, 42),
    (1, 45),
    (1, 48),
    (1, 55),
    (1, 57),
    (1, 59),
    (1, 62),
    (1, 63),
    (1, 66),
    (1, 70),
    (1, 71),
    (1, 72),
    (1, 77),
    (2, 3),
    (2, 7),
    (2, 11),
    (2, 17),
    (2, 19),
    (2, 29),
    (2, 31),
    (2, 34),
    (2, 36),
    (2, 47),
    (2, 53),
    (2, 54),
    (2, 60),
    (2, 69),
    (2, 80),
    (2, 83),
    (3, 3),
    (3, 10),
    (3, 14),
    (3, 16),
    (3, 18),
    (3, 24),
    (3, 30),
    (3, 32),
    (3, 33),
    (3, 35),
    (3, 37),
    (3, 38),
    (3, 39),
    (3, 49),
    (3, 51),
    (3, 52),
    (3, 58),
    (3, 61),
    (3, 67),
    (3, 68),
    (3, 69),
    (3, 73),
    (3, 78),
    (3, 86),
    (3, 87),
    (3, 91),
    (4, 6),
    (4, 9),
    (4, 13),
    (4, 27),
    (4, 40),
    (4, 44),
    (4, 50),
    (4, 52),
    (4, 55),
    (4, 56),
    (4, 71),
    (4, 74),
    (4, 75),
    (4, 82),
    (5, 11),
    (5, 21),
    (5, 25),
    (5, 26),
    (5, 27),
    (5, 38),
    (5, 41),
    (5, 43),
    (5, 46),
    (5, 64),
    (5, 76),
    (5, 84),
    (5, 85),
    (5, 88),
    (5, 89),
    (5, 90),
    (6, 4),
    (6, 25),
    (6, 28),
    (6, 44),
    (6, 62),
    (6, 65),
    (6, 79),
    (6, 81),
    (3, 92);

-- -------------------------------------------------------------------------------------
-- 4.13 PAGAMENTO (324) [RF04, RO02, RO04, RO06, RE07]
-- Parcelas de ago/2026 a nov/2026 (os 3 últimos meses fechados + o mês corrente), vencimento no
-- 5º dia útil: 07/08, 08/09, 07/10 e 09/11 (RO02). Ordem: mês de vencimento e contrato.
-- A 1ª parcela vence no 5º dia útil seguinte à assinatura (PN02), com valor integral: quem assina
-- depois do 5º dia útil (alunos 84 e 85 em setembro; 89, 90 e 91 em outubro) só tem parcela a
-- partir do mês seguinte e, até lá, treina sem estar em atraso.
-- Meses em que o aluno estava trancado não geram parcela. Multa de 2% (ilustrativa) só nos planos de
-- mais de 1 mês (RO04).
-- Faturas por mês: ago 80, set 80, out 81 e nov 83 (uma por contrato vigente).
-- 235 PAGO, 11 ATRASADO, 78 PENDENTE (quase todas de novembro, que ainda vai vencer).
-- Taxa de exame de faixa (PN08): cobrada na mensalidade do mês do exame, que vence antes dele, e
-- quitada antes da data do exame. Valores fictícios por faixa (as primeiras são mais baratas):
-- R$ 40,00 nos graus da faixa branca, Faixa Amarela, Prajied Branco e Corda Crua; R$ 60,00 na Faixa
-- Laranja; R$ 80,00 na Faixa Azul. A análise técnica do Boxe não tem taxa (RO06).
-- Formas de pagamento: Pix, crédito e débito.
-- Cenários de auditoria: parcela de outubro do contrato 14 ainda PENDENTE depois de vencida (A07,
-- pagamento 174); parcela de setembro do contrato 3 paga com R$ 20,00 a menos (A10, pagamento
-- 83); parcela de setembro do contrato 30 (Trimestral) paga em 11/09 sem a multa (A13,
-- pagamento 110).
-- -------------------------------------------------------------------------------------
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (1, 2, '2026-08-07', '2026-08-06', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (2, 3, '2026-08-07', '2026-08-13', 231.00, 235.62, 'CREDITO', 4.62, NULL, 'PAGO'),
    (3, 4, '2026-08-07', '2026-08-04', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (4, 5, '2026-08-07', '2026-08-02', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (5, 6, '2026-08-07', '2026-08-06', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (6, 7, '2026-08-07', '2026-08-07', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (7, 8, '2026-08-07', '2026-08-04', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (8, 9, '2026-08-07', '2026-08-15', 162.00, 165.24, 'PIX', 3.24, NULL, 'PAGO'),
    (9, 10, '2026-08-07', '2026-08-07', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (10, 11, '2026-08-07', '2026-08-02', 240.00, 240.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (11, 12, '2026-08-07', '2026-08-07', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (12, 13, '2026-08-07', '2026-08-04', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (13, 14, '2026-08-07', '2026-08-15', 153.00, 156.06, 'CREDITO', 3.06, NULL, 'PAGO'),
    (14, 15, '2026-08-07', '2026-08-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (15, 16, '2026-08-07', '2026-08-11', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (16, 17, '2026-08-07', '2026-08-03', 153.00, 193.00, 'PIX', NULL, 40.00, 'PAGO'),
    (17, 18, '2026-08-07', '2026-08-05', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (18, 19, '2026-08-07', '2026-08-06', 180.00, 240.00, 'PIX', NULL, 60.00, 'PAGO'),
    (19, 20, '2026-08-07', '2026-08-01', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (20, 21, '2026-08-07', '2026-08-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (21, 22, '2026-08-07', '2026-08-03', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (22, 23, '2026-08-07', '2026-08-03', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (23, 24, '2026-08-07', '2026-08-04', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (24, 25, '2026-08-07', '2026-08-07', 231.00, 271.00, 'CREDITO', NULL, 40.00, 'PAGO'),
    (25, 26, '2026-08-07', '2026-08-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (26, 27, '2026-08-07', '2026-08-05', 231.00, 271.00, 'PIX', NULL, 40.00, 'PAGO'),
    (27, 28, '2026-08-07', '2026-08-01', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (28, 29, '2026-08-07', '2026-08-02', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (29, 30, '2026-08-07', '2026-08-02', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (30, 31, '2026-08-07', '2026-08-01', 222.00, 222.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (31, 32, '2026-08-07', '2026-08-02', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (32, 33, '2026-08-07', '2026-08-14', 162.00, 165.24, 'DEBITO', 3.24, NULL, 'PAGO'),
    (33, 34, '2026-08-07', '2026-08-05', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (34, 35, '2026-08-07', '2026-08-01', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (35, 36, '2026-08-07', '2026-08-12', 171.00, 174.42, 'CREDITO', 3.42, NULL, 'PAGO'),
    (36, 37, '2026-08-07', '2026-08-02', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (37, 38, '2026-08-07', '2026-08-01', 231.00, 231.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (38, 39, '2026-08-07', '2026-08-03', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (39, 40, '2026-08-07', '2026-08-07', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (40, 41, '2026-08-07', '2026-08-04', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (41, 42, '2026-08-07', '2026-08-11', 171.00, 174.42, 'DEBITO', 3.42, NULL, 'PAGO'),
    (42, 43, '2026-08-07', '2026-08-09', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (43, 44, '2026-08-07', '2026-08-02', 222.00, 222.00, 'PIX', NULL, NULL, 'PAGO'),
    (44, 45, '2026-08-07', '2026-08-01', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (45, 46, '2026-08-07', '2026-08-07', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (46, 48, '2026-08-07', '2026-08-03', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (47, 49, '2026-08-07', '2026-08-03', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (48, 50, '2026-08-07', '2026-08-02', 144.00, 144.00, 'PIX', NULL, NULL, 'PAGO'),
    (49, 51, '2026-08-07', '2026-08-06', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (50, 52, '2026-08-07', '2026-08-01', 222.00, 222.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (51, 53, '2026-08-07', '2026-08-06', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (52, 54, '2026-08-07', '2026-08-07', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (53, 55, '2026-08-07', '2026-08-11', 231.00, 235.62, 'DEBITO', 4.62, NULL, 'PAGO'),
    (54, 56, '2026-08-07', '2026-08-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (55, 57, '2026-08-07', '2026-08-01', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (56, 58, '2026-08-07', '2026-08-03', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (57, 59, '2026-08-07', '2026-08-03', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (58, 60, '2026-08-07', '2026-08-04', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (59, 61, '2026-08-07', '2026-08-06', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (60, 62, '2026-08-07', '2026-08-09', 240.00, 280.00, 'PIX', NULL, 40.00, 'PAGO'),
    (61, 63, '2026-08-07', '2026-08-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (62, 64, '2026-08-07', '2026-08-02', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (63, 65, '2026-08-07', '2026-08-01', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (64, 66, '2026-08-07', '2026-08-01', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (65, 67, '2026-08-07', '2026-08-09', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (66, 68, '2026-08-07', '2026-08-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (67, 69, '2026-08-07', '2026-08-15', 231.00, 235.62, 'PIX', 4.62, NULL, 'PAGO'),
    (68, 70, '2026-08-07', '2026-08-01', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (69, 71, '2026-08-07', '2026-08-13', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (70, 72, '2026-08-07', '2026-08-04', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (71, 73, '2026-08-07', '2026-08-03', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (72, 84, '2026-08-07', '2026-08-05', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (73, 85, '2026-08-07', '2026-08-05', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (74, 86, '2026-08-07', '2026-08-05', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (75, 87, '2026-08-07', '2026-08-05', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (76, 88, '2026-08-07', '2026-08-02', 144.00, 144.00, 'PIX', NULL, NULL, 'PAGO'),
    (77, 89, '2026-08-07', '2026-08-02', 144.00, 144.00, 'PIX', NULL, NULL, 'PAGO'),
    (78, 90, '2026-08-07', '2026-08-01', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (79, 91, '2026-08-07', '2026-08-01', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (80, 92, '2026-08-07', '2026-08-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO');
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (81, 1, '2026-09-08', '2026-09-03', 171.00, 211.00, 'CREDITO', NULL, 40.00, 'PAGO'),
    (82, 2, '2026-09-08', '2026-09-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (83, 3, '2026-09-08', '2026-09-06', 231.00, 211.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (84, 4, '2026-09-08', '2026-09-04', 162.00, 242.00, 'CREDITO', NULL, 80.00, 'PAGO'),
    (85, 5, '2026-09-08', '2026-09-05', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (86, 6, '2026-09-08', '2026-09-03', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (87, 7, '2026-09-08', '2026-09-02', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (88, 8, '2026-09-08', '2026-09-17', 162.00, 165.24, 'CREDITO', 3.24, NULL, 'PAGO'),
    (89, 9, '2026-09-08', '2026-09-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (90, 10, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (91, 11, '2026-09-08', '2026-09-08', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (92, 12, '2026-09-08', '2026-09-08', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (93, 13, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (94, 14, '2026-09-08', '2026-09-07', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (95, 15, '2026-09-08', '2026-09-14', 162.00, 165.24, 'PIX', 3.24, NULL, 'PAGO'),
    (96, 16, '2026-09-08', '2026-09-16', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (97, 17, '2026-09-08', '2026-09-03', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (98, 18, '2026-09-08', '2026-09-04', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (99, 19, '2026-09-08', '2026-09-07', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (100, 20, '2026-09-08', '2026-09-15', 153.00, 156.06, 'PIX', 3.06, NULL, 'PAGO'),
    (101, 21, '2026-09-08', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (102, 22, '2026-09-08', '2026-09-02', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (103, 23, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (104, 24, '2026-09-08', '2026-09-07', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (105, 25, '2026-09-08', '2026-09-06', 231.00, 271.00, 'DEBITO', NULL, 40.00, 'PAGO'),
    (106, 26, '2026-09-08', '2026-09-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (107, 27, '2026-09-08', '2026-09-03', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (108, 28, '2026-09-08', '2026-09-02', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (109, 29, '2026-09-08', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (110, 30, '2026-09-08', '2026-09-11', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (111, 31, '2026-09-08', '2026-09-03', 222.00, 222.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (112, 32, '2026-09-08', '2026-09-07', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (113, 33, '2026-09-08', '2026-09-08', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (114, 34, '2026-09-08', '2026-09-05', 153.00, 193.00, 'PIX', NULL, 40.00, 'PAGO'),
    (115, 35, '2026-09-08', '2026-09-09', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (116, 36, '2026-09-08', '2026-09-04', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (117, 37, '2026-09-08', '2026-09-03', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (118, 38, '2026-09-08', '2026-09-06', 231.00, 271.00, 'DEBITO', NULL, 40.00, 'PAGO'),
    (119, 39, '2026-09-08', '2026-09-08', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (120, 40, '2026-09-08', '2026-09-04', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (121, 42, '2026-09-08', '2026-09-07', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (122, 43, '2026-09-08', '2026-09-11', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (123, 44, '2026-09-08', '2026-09-05', 222.00, 222.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (124, 45, '2026-09-08', '2026-09-07', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (125, 46, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (126, 48, '2026-09-08', '2026-09-03', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (127, 49, '2026-09-08', '2026-09-08', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (128, 50, '2026-09-08', '2026-09-07', 144.00, 144.00, 'PIX', NULL, NULL, 'PAGO'),
    (129, 51, '2026-09-08', '2026-09-08', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (130, 52, '2026-09-08', '2026-09-07', 222.00, 222.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (131, 53, '2026-09-08', '2026-09-08', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (132, 54, '2026-09-08', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (133, 55, '2026-09-08', '2026-09-04', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (134, 56, '2026-09-08', '2026-09-07', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (135, 57, '2026-09-08', '2026-09-11', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (136, 58, '2026-09-08', '2026-09-04', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (137, 59, '2026-09-08', '2026-09-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (138, 60, '2026-09-08', '2026-09-05', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (139, 61, '2026-09-08', '2026-09-07', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (140, 62, '2026-09-08', '2026-09-07', 240.00, 240.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (141, 63, '2026-09-08', '2026-09-04', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (142, 65, '2026-09-08', '2026-09-03', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (143, 67, '2026-09-08', '2026-09-06', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (144, 68, '2026-09-08', '2026-09-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (145, 69, '2026-09-08', '2026-09-05', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (146, 70, '2026-09-08', '2026-09-06', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (147, 71, '2026-09-08', '2026-09-02', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (148, 72, '2026-09-08', '2026-09-11', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (149, 73, '2026-09-08', '2026-09-04', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (150, 74, '2026-09-08', '2026-09-08', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (151, 75, '2026-09-08', '2026-09-04', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (152, 84, '2026-09-08', '2026-09-04', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (153, 85, '2026-09-08', '2026-09-04', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (154, 86, '2026-09-08', '2026-09-05', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (155, 87, '2026-09-08', '2026-09-05', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (156, 88, '2026-09-08', '2026-09-07', 144.00, 144.00, 'PIX', NULL, NULL, 'PAGO'),
    (157, 89, '2026-09-08', '2026-09-07', 144.00, 144.00, 'PIX', NULL, NULL, 'PAGO'),
    (158, 90, '2026-09-08', '2026-09-03', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (159, 91, '2026-09-08', '2026-09-06', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (160, 92, '2026-09-08', '2026-09-04', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO');
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (161, 1, '2026-10-07', '2026-10-03', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (162, 2, '2026-10-07', '2026-10-15', 162.00, 165.24, 'DEBITO', 3.24, NULL, 'PAGO'),
    (163, 3, '2026-10-07', '2026-10-03', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (164, 4, '2026-10-07', '2026-10-12', 162.00, 165.24, 'PIX', 3.24, NULL, 'PAGO'),
    (165, 5, '2026-10-07', '2026-10-11', 171.00, 174.42, 'PIX', 3.42, NULL, 'PAGO'),
    (166, 6, '2026-10-07', '2026-10-15', 162.00, 165.24, 'PIX', 3.24, NULL, 'PAGO'),
    (167, 7, '2026-10-07', '2026-10-05', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (168, 8, '2026-10-07', '2026-10-16', 162.00, 165.24, 'DEBITO', 3.24, NULL, 'PAGO'),
    (169, 9, '2026-10-07', '2026-10-06', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (170, 10, '2026-10-07', '2026-10-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (171, 11, '2026-10-07', '2026-10-01', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (172, 12, '2026-10-07', '2026-10-05', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (173, 13, '2026-10-07', '2026-10-04', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (174, 14, '2026-10-07', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (175, 16, '2026-10-07', '2026-10-07', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (176, 17, '2026-10-07', '2026-10-02', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (177, 18, '2026-10-07', '2026-10-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (178, 19, '2026-10-07', '2026-10-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (179, 20, '2026-10-07', '2026-10-04', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (180, 21, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (181, 22, '2026-10-07', '2026-10-02', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (182, 23, '2026-10-07', '2026-10-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (183, 24, '2026-10-07', '2026-10-07', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (184, 25, '2026-10-07', '2026-10-01', 231.00, 231.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (185, 27, '2026-10-07', '2026-10-06', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (186, 28, '2026-10-07', NULL, 153.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (187, 29, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (188, 30, '2026-10-07', '2026-10-06', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (189, 31, '2026-10-07', '2026-10-15', 222.00, 266.44, 'PIX', 4.44, 40.00, 'PAGO'),
    (190, 32, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (191, 33, '2026-10-07', '2026-10-07', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (192, 34, '2026-10-07', '2026-10-02', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (193, 35, '2026-10-07', '2026-10-06', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (194, 36, '2026-10-07', '2026-10-01', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (195, 37, '2026-10-07', '2026-10-07', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (196, 38, '2026-10-07', '2026-10-03', 231.00, 271.00, 'PIX', NULL, 40.00, 'PAGO'),
    (197, 39, '2026-10-07', '2026-10-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (198, 40, '2026-10-07', '2026-10-03', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (199, 42, '2026-10-07', '2026-10-03', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (200, 43, '2026-10-07', '2026-10-02', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (201, 44, '2026-10-07', '2026-10-02', 222.00, 222.00, 'PIX', NULL, NULL, 'PAGO'),
    (202, 45, '2026-10-07', '2026-10-06', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (203, 46, '2026-10-07', '2026-10-16', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (204, 48, '2026-10-07', '2026-10-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (205, 49, '2026-10-07', '2026-10-01', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (206, 50, '2026-10-07', '2026-10-02', 144.00, 144.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (207, 51, '2026-10-07', '2026-10-05', 162.00, 202.00, 'PIX', NULL, 40.00, 'PAGO'),
    (208, 52, '2026-10-07', NULL, 222.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (209, 53, '2026-10-07', '2026-10-15', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (210, 55, '2026-10-07', '2026-10-05', 231.00, 231.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (211, 56, '2026-10-07', '2026-10-01', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (212, 57, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (213, 59, '2026-10-07', '2026-10-13', 180.00, 220.00, 'DEBITO', NULL, 40.00, 'PAGO'),
    (214, 60, '2026-10-07', '2026-10-04', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (215, 61, '2026-10-07', '2026-10-03', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (216, 62, '2026-10-07', '2026-10-01', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (217, 63, '2026-10-07', '2026-10-06', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (218, 65, '2026-10-07', '2026-10-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (219, 67, '2026-10-07', '2026-10-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (220, 68, '2026-10-07', '2026-10-06', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (221, 69, '2026-10-07', NULL, 231.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (222, 70, '2026-10-07', '2026-10-03', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (223, 71, '2026-10-07', '2026-10-04', 240.00, 240.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (224, 72, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (225, 73, '2026-10-07', '2026-10-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (226, 74, '2026-10-07', '2026-10-07', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (227, 75, '2026-10-07', '2026-10-01', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (228, 76, '2026-10-07', '2026-10-16', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (229, 77, '2026-10-07', '2026-10-15', 153.00, 156.06, 'PIX', 3.06, NULL, 'PAGO'),
    (230, 78, '2026-10-07', '2026-10-06', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (231, 79, '2026-10-07', '2026-10-06', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (232, 80, '2026-10-07', '2026-10-06', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (233, 84, '2026-10-07', '2026-10-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (234, 85, '2026-10-07', '2026-10-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (235, 86, '2026-10-07', '2026-10-02', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (236, 87, '2026-10-07', '2026-10-02', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (237, 88, '2026-10-07', '2026-10-02', 144.00, 144.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (238, 89, '2026-10-07', '2026-10-02', 144.00, 144.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (239, 90, '2026-10-07', '2026-10-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (240, 91, '2026-10-07', '2026-10-03', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO');
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (241, 92, '2026-10-07', '2026-10-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (242, 1, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (243, 2, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (244, 3, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (245, 4, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (246, 5, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (247, 6, '2026-11-09', '2026-10-31', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (248, 7, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (249, 8, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (250, 9, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (251, 10, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (252, 11, '2026-11-09', NULL, 240.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (253, 12, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (254, 13, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (255, 14, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (256, 17, '2026-11-09', '2026-10-29', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (257, 18, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (258, 19, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (259, 20, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (260, 21, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (261, 22, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (262, 23, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (263, 24, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (264, 25, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (265, 27, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (266, 28, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (267, 29, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (268, 30, '2026-11-09', '2026-10-29', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (269, 31, '2026-11-09', NULL, 222.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (270, 32, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (271, 33, '2026-11-09', '2026-10-29', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (272, 34, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (273, 35, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (274, 36, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (275, 37, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (276, 38, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (277, 39, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (278, 40, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (279, 42, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (280, 43, '2026-11-09', '2026-10-30', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (281, 44, '2026-11-09', NULL, 222.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (282, 45, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (283, 46, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (284, 48, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (285, 49, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (286, 50, '2026-11-09', NULL, 144.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (287, 51, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (288, 52, '2026-11-09', NULL, 222.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (289, 53, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (290, 55, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (291, 56, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (292, 57, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (293, 59, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (294, 60, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (295, 61, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (296, 62, '2026-11-09', '2026-10-28', 240.00, 240.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (297, 63, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (298, 65, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (299, 67, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (300, 68, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (301, 69, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (302, 70, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (303, 71, '2026-11-09', NULL, 240.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (304, 72, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (305, 73, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (306, 74, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (307, 75, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (308, 76, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (309, 77, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (310, 78, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (311, 79, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (312, 80, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (313, 81, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (314, 82, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (315, 83, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (316, 84, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (317, 85, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (318, 86, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (319, 87, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (320, 88, '2026-11-09', NULL, 144.00, NULL, NULL, NULL, NULL, 'PENDENTE');
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (321, 89, '2026-11-09', NULL, 144.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (322, 90, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (323, 91, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (324, 92, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE');

-- -------------------------------------------------------------------------------------
-- 4.14 GRADUACAO (28) [RF06, RO05, RO06]
-- Exames de faixa trimestrais (dez/2025 a out/2026) e análises técnicas de Boxe, com aprovações e
-- reprovações. Uma aluna reprovada em junho refez o exame em setembro e foi aprovada.
-- A taxa de cada exame de agosto a outubro está na parcela do mesmo mês (ver 4.13).
-- -------------------------------------------------------------------------------------
INSERT INTO GRADUACAO (ID_GRADUACAO, ID_ALUNO, ID_PROFESSOR, ID_MODALIDADE, DS_MOTIVO_REPROVACAO, DT_GRADUACAO, TP_NIVEL_FAIXA, TP_AVALIACAO, TP_RESULTADO) VALUES
    (1, 3, 3, 3, NULL, '2025-12-13', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (2, 14, 3, 3, NULL, '2025-12-13', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (3, 31, 2, 2, NULL, '2025-12-13', 'Faixa Amarela', 'EXAME_FAIXA', 'APROVADO'),
    (4, 23, 5, 5, 'técnica de queda', '2026-03-14', 'Corda Crua', 'EXAME_FAIXA', 'REPROVADO'),
    (5, 24, 1, 1, NULL, '2026-03-14', 'Prajied Branco', 'EXAME_FAIXA', 'APROVADO'),
    (6, 31, 2, 2, NULL, '2026-03-14', 'Faixa Laranja', 'EXAME_FAIXA', 'APROVADO'),
    (7, 40, 2, 2, NULL, '2026-03-14', 'Faixa Amarela', 'EXAME_FAIXA', 'APROVADO'),
    (8, 44, 4, 4, NULL, '2026-04-11', NULL, 'ANALISE_TECNICA', 'APROVADO'),
    (9, 27, 6, 6, 'frequência abaixo da exigida', '2026-06-20', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'REPROVADO'),
    (10, 45, 5, 5, NULL, '2026-06-20', 'Corda Crua', 'EXAME_FAIXA', 'APROVADO'),
    (11, 49, 1, 1, NULL, '2026-06-20', 'Prajied Branco', 'EXAME_FAIXA', 'APROVADO'),
    (12, 51, 2, 2, 'condicionamento', '2026-06-20', 'Faixa Amarela', 'EXAME_FAIXA', 'REPROVADO'),
    (13, 17, 2, 2, NULL, '2026-08-22', 'Faixa Amarela', 'EXAME_FAIXA', 'APROVADO'),
    (14, 21, 2, 2, NULL, '2026-08-22', 'Faixa Laranja', 'EXAME_FAIXA', 'APROVADO'),
    (15, 27, 5, 5, NULL, '2026-08-22', 'Corda Crua', 'EXAME_FAIXA', 'APROVADO'),
    (16, 29, 5, 5, NULL, '2026-08-22', 'Corda Crua', 'EXAME_FAIXA', 'APROVADO'),
    (17, 68, 6, 6, NULL, '2026-08-22', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (18, 54, 4, 4, 'condicionamento', '2026-08-29', NULL, 'ANALISE_TECNICA', 'REPROVADO'),
    (19, 1, 1, 1, NULL, '2026-09-19', 'Prajied Branco', 'EXAME_FAIXA', 'APROVADO'),
    (20, 27, 6, 6, NULL, '2026-09-19', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (21, 4, 6, 6, NULL, '2026-09-19', 'Faixa Azul', 'EXAME_FAIXA', 'APROVADO'),
    (22, 36, 2, 2, NULL, '2026-09-19', 'Faixa Amarela', 'EXAME_FAIXA', 'APROVADO'),
    (23, 42, 5, 5, NULL, '2026-09-19', 'Corda Crua', 'EXAME_FAIXA', 'APROVADO'),
    (24, 33, 1, 1, NULL, '2026-10-17', 'Prajied Branco', 'EXAME_FAIXA', 'APROVADO'),
    (25, 42, 3, 3, NULL, '2026-10-17', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (26, 57, 3, 3, NULL, '2026-10-17', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (27, 65, 1, 1, 'controle de distância', '2026-10-17', 'Prajied Branco', 'EXAME_FAIXA', 'REPROVADO'),
    (28, 61, 4, 4, NULL, '2026-10-24', NULL, 'ANALISE_TECNICA', 'APROVADO');

-- -------------------------------------------------------------------------------------
-- 4.15 DESPESA (50) [RF04, RO07]
-- Despesas fixas mensais (aluguel, água, luz, internet), compras semanais de higiene/limpeza feitas pelo
-- gestor, compras de equipamento, manutenção e o repasse aos 5 professores prestadores de serviço
-- (aulas x R$ 80,00), pago no 5º dia útil do mês seguinte (RO07). O gestor não recebe repasse
-- (VL_POR_AULA = 0). As aulas de cada repasse seguem a grade de 21 turmas, sem os feriados de
-- 09/07, 07/09 e 12/10; o repasse de outubro bate com as aulas registradas em AULA (consulta G07).
-- Há uma despesa ATRASADO (manutenção do ar-condicionado) e as de novembro estão PENDENTE.
-- -------------------------------------------------------------------------------------
INSERT INTO DESPESA (ID_DESPESA, ID_PROFESSOR, DS_CATEGORIA, VL_DESPESA, DT_VENCIMENTO, DT_PAGAMENTO, VL_PAGO, DS_DESCRICAO, NM_CREDOR, TP_SITUACAO_DESPESA) VALUES
    (1, NULL, 'COMPRAS', 234.19, '2026-08-04', '2026-08-04', 234.19, 'Reposição semanal de higiene e limpeza (1ª semana de ago)', 'Atacadão Limpa Bem', 'PAGO'),
    (2, 2, 'PROFESSORES', 1120.00, '2026-08-07', '2026-08-07', 1120.00, 'Repasse de 14 aulas ministradas em jul/2026', 'Carolina Nunes Carvalho', 'PAGO'),
    (3, 3, 'PROFESSORES', 1760.00, '2026-08-07', '2026-08-07', 1760.00, 'Repasse de 22 aulas ministradas em jul/2026', 'Fábio Macedo Freitas', 'PAGO'),
    (4, 4, 'PROFESSORES', 1360.00, '2026-08-07', '2026-08-07', 1360.00, 'Repasse de 17 aulas ministradas em jul/2026', 'Jonas Mendes Nunes', 'PAGO'),
    (5, 5, 'PROFESSORES', 320.00, '2026-08-07', '2026-08-07', 320.00, 'Repasse de 4 aulas ministradas em jul/2026', 'Igor Machado Cardoso', 'PAGO'),
    (6, 6, 'PROFESSORES', 640.00, '2026-08-07', '2026-08-07', 640.00, 'Repasse de 8 aulas ministradas em jul/2026', 'Gabriela Vieira Rodrigues', 'PAGO'),
    (7, NULL, 'ALUGUEL', 3500.00, '2026-08-10', '2026-08-10', 3500.00, 'Aluguel do galpão - ago/2026', 'Imobiliária Horizonte Leste Ltda', 'PAGO'),
    (8, NULL, 'COMPRAS', 183.39, '2026-08-11', '2026-08-11', 183.39, 'Reposição semanal de higiene e limpeza (2ª semana de ago)', 'Atacadão Limpa Bem', 'PAGO'),
    (9, NULL, 'CONSUMO', 119.90, '2026-08-12', '2026-08-12', 119.90, 'Internet e telefone - ago/2026', 'Provedor NetLeste', 'PAGO'),
    (10, NULL, 'CONSUMO', 198.88, '2026-08-15', '2026-08-15', 198.88, 'Conta de água - ago/2026', 'Companhia de Saneamento', 'PAGO'),
    (11, NULL, 'COMPRAS', 195.36, '2026-08-18', '2026-08-18', 195.36, 'Reposição semanal de higiene e limpeza (3ª semana de ago)', 'Mercado Bom Preço', 'PAGO'),
    (12, NULL, 'COMPRAS', 920.00, '2026-08-18', '2026-08-18', 920.00, 'Compra de 2 sacos de pancada de 1,80 m', 'Esporte Total Equipamentos', 'PAGO'),
    (13, NULL, 'CONSUMO', 491.59, '2026-08-20', '2026-08-17', 491.59, 'Conta de energia elétrica - ago/2026', 'Distribuidora de Energia', 'PAGO'),
    (14, NULL, 'COMPRAS', 186.33, '2026-08-25', '2026-08-25', 186.33, 'Reposição semanal de higiene e limpeza (4ª semana de ago)', 'Mercado Bom Preço', 'PAGO'),
    (15, NULL, 'COMPRAS', 160.85, '2026-09-08', '2026-09-08', 160.85, 'Reposição semanal de higiene e limpeza (1ª semana de set)', 'Atacadão Limpa Bem', 'PAGO'),
    (16, 2, 'PROFESSORES', 1040.00, '2026-09-08', '2026-09-08', 1040.00, 'Repasse de 13 aulas ministradas em ago/2026', 'Carolina Nunes Carvalho', 'PAGO'),
    (17, 3, 'PROFESSORES', 1680.00, '2026-09-08', '2026-09-08', 1680.00, 'Repasse de 21 aulas ministradas em ago/2026', 'Fábio Macedo Freitas', 'PAGO'),
    (18, 4, 'PROFESSORES', 1360.00, '2026-09-08', '2026-09-08', 1360.00, 'Repasse de 17 aulas ministradas em ago/2026', 'Jonas Mendes Nunes', 'PAGO'),
    (19, 5, 'PROFESSORES', 400.00, '2026-09-08', '2026-09-08', 400.00, 'Repasse de 5 aulas ministradas em ago/2026', 'Igor Machado Cardoso', 'PAGO'),
    (20, 6, 'PROFESSORES', 640.00, '2026-09-08', '2026-09-08', 640.00, 'Repasse de 8 aulas ministradas em ago/2026', 'Gabriela Vieira Rodrigues', 'PAGO'),
    (21, NULL, 'ALUGUEL', 3500.00, '2026-09-10', '2026-09-09', 3500.00, 'Aluguel do galpão - set/2026', 'Imobiliária Horizonte Leste Ltda', 'PAGO'),
    (22, NULL, 'CONSUMO', 119.90, '2026-09-12', '2026-09-12', 119.90, 'Internet e telefone - set/2026', 'Provedor NetLeste', 'PAGO'),
    (23, NULL, 'COMPRAS', 121.45, '2026-09-15', '2026-09-15', 121.45, 'Reposição semanal de higiene e limpeza (2ª semana de set)', 'Mercado Bom Preço', 'PAGO'),
    (24, NULL, 'CONSUMO', 234.53, '2026-09-15', '2026-09-14', 234.53, 'Conta de água - set/2026', 'Companhia de Saneamento', 'PAGO'),
    (25, NULL, 'CONSUMO', 459.38, '2026-09-20', '2026-09-17', 459.38, 'Conta de energia elétrica - set/2026', 'Distribuidora de Energia', 'PAGO'),
    (26, NULL, 'COMPRAS', 218.22, '2026-09-22', '2026-09-22', 218.22, 'Reposição semanal de higiene e limpeza (3ª semana de set)', 'Atacadão Limpa Bem', 'PAGO'),
    (27, NULL, 'MANUTENCAO', 650.00, '2026-09-22', '2026-09-22', 650.00, 'Troca da lona do ringue de Boxe', 'Tapeçaria Lona Forte', 'PAGO'),
    (28, NULL, 'COMPRAS', 116.27, '2026-09-29', '2026-09-29', 116.27, 'Reposição semanal de higiene e limpeza (4ª semana de set)', 'Mercado Bom Preço', 'PAGO'),
    (29, NULL, 'COMPRAS', 219.24, '2026-10-06', '2026-10-06', 219.24, 'Reposição semanal de higiene e limpeza (1ª semana de out)', 'Atacadão Limpa Bem', 'PAGO'),
    (30, NULL, 'COMPRAS', 540.00, '2026-10-06', '2026-10-06', 540.00, 'Luvas e caneleiras para alunos iniciantes de Muay Thai', 'Esporte Total Equipamentos', 'PAGO'),
    (31, 2, 'PROFESSORES', 960.00, '2026-10-07', '2026-10-07', 960.00, 'Repasse de 12 aulas ministradas em set/2026', 'Carolina Nunes Carvalho', 'PAGO'),
    (32, 3, 'PROFESSORES', 1680.00, '2026-10-07', '2026-10-07', 1680.00, 'Repasse de 21 aulas ministradas em set/2026', 'Fábio Macedo Freitas', 'PAGO'),
    (33, 4, 'PROFESSORES', 1360.00, '2026-10-07', '2026-10-07', 1360.00, 'Repasse de 17 aulas ministradas em set/2026', 'Jonas Mendes Nunes', 'PAGO'),
    (34, 5, 'PROFESSORES', 320.00, '2026-10-07', '2026-10-07', 320.00, 'Repasse de 4 aulas ministradas em set/2026', 'Igor Machado Cardoso', 'PAGO'),
    (35, 6, 'PROFESSORES', 720.00, '2026-10-07', '2026-10-07', 720.00, 'Repasse de 9 aulas ministradas em set/2026', 'Gabriela Vieira Rodrigues', 'PAGO'),
    (36, NULL, 'ALUGUEL', 3500.00, '2026-10-10', '2026-10-10', 3500.00, 'Aluguel do galpão - out/2026', 'Imobiliária Horizonte Leste Ltda', 'PAGO'),
    (37, NULL, 'CONSUMO', 119.90, '2026-10-12', '2026-10-12', 119.90, 'Internet e telefone - out/2026', 'Provedor NetLeste', 'PAGO'),
    (38, NULL, 'COMPRAS', 243.35, '2026-10-13', '2026-10-13', 243.35, 'Reposição semanal de higiene e limpeza (2ª semana de out)', 'Mercado Bom Preço', 'PAGO'),
    (39, NULL, 'CONSUMO', 198.44, '2026-10-15', '2026-10-13', 198.44, 'Conta de água - out/2026', 'Companhia de Saneamento', 'PAGO'),
    (40, NULL, 'COMPRAS', 206.64, '2026-10-20', '2026-10-20', 206.64, 'Reposição semanal de higiene e limpeza (3ª semana de out)', 'Atacadão Limpa Bem', 'PAGO'),
    (41, NULL, 'CONSUMO', 449.61, '2026-10-20', '2026-10-20', 449.61, 'Conta de energia elétrica - out/2026', 'Distribuidora de Energia', 'PAGO'),
    (42, NULL, 'MANUTENCAO', 380.00, '2026-10-25', NULL, NULL, 'Manutenção preventiva do ar-condicionado', 'Clima Frio Refrigeração', 'ATRASADO'),
    (43, NULL, 'COMPRAS', 156.88, '2026-10-27', '2026-10-27', 156.88, 'Reposição semanal de higiene e limpeza (4ª semana de out)', 'Mercado Bom Preço', 'PAGO'),
    (44, 2, 'PROFESSORES', 880.00, '2026-11-09', NULL, NULL, 'Repasse de 11 aulas ministradas em out/2026', 'Carolina Nunes Carvalho', 'PENDENTE'),
    (45, 3, 'PROFESSORES', 1680.00, '2026-11-09', NULL, NULL, 'Repasse de 21 aulas ministradas em out/2026', 'Fábio Macedo Freitas', 'PENDENTE'),
    (46, 4, 'PROFESSORES', 1360.00, '2026-11-09', NULL, NULL, 'Repasse de 17 aulas ministradas em out/2026', 'Jonas Mendes Nunes', 'PENDENTE'),
    (47, 5, 'PROFESSORES', 400.00, '2026-11-09', NULL, NULL, 'Repasse de 5 aulas ministradas em out/2026', 'Igor Machado Cardoso', 'PENDENTE'),
    (48, 6, 'PROFESSORES', 720.00, '2026-11-09', NULL, NULL, 'Repasse de 9 aulas ministradas em out/2026', 'Gabriela Vieira Rodrigues', 'PENDENTE'),
    (49, NULL, 'ALUGUEL', 3500.00, '2026-11-10', NULL, NULL, 'Aluguel do galpão - nov/2026', 'Imobiliária Horizonte Leste Ltda', 'PENDENTE'),
    (50, NULL, 'CONSUMO', 119.90, '2026-11-12', NULL, NULL, 'Internet e telefone - nov/2026', 'Provedor NetLeste', 'PENDENTE');

-- -------------------------------------------------------------------------------------
-- 4.16 LOG_ACESSO (20) [RNF02]
-- Amostra de acessos de outubro: leitura de CPF e de problema de saúde, criações e atualizações.
-- Em produção quem grava o log é o sistema (conta técnica só com INSERT, Seção 3.5); aqui os
-- registros são inseridos manualmente. Os logins são os dos usuários da Seção 3.5: o CEO aparece
-- como admin.gestor (Administração) e como prof.muaythai quando registra aula e exame de Muay Thai.
-- Na PRESENCA (PK composta), ID_REGISTRO é o ID_AULA da chamada alterada.
-- -------------------------------------------------------------------------------------
INSERT INTO LOG_ACESSO (ID_LOG, NM_USUARIO, TP_PERFIL, DT_ACESSO, TP_OPERACAO, NM_TABELA, ID_REGISTRO, NM_CAMPO) VALUES
    (1, 'admin.gestor', 'ADMINISTRACAO', '2026-10-01 08:12:40', 'CRIACAO', 'PAGAMENTO', 161, NULL),
    (2, 'admin.gestor', 'ADMINISTRACAO', '2026-10-02 18:40:05', 'LEITURA', 'ALUNO', 80, 'CPF'),
    (3, 'admin.gestor', 'ADMINISTRACAO', '2026-10-05 10:03:18', 'CRIACAO', 'TRANCAMENTO', 5, NULL),
    (4, 'prof.jiujitsu', 'PROFESSOR', '2026-10-05 19:55:31', 'LEITURA', 'PROBLEMA_SAUDE_ALUNO', 81, 'DS_PROBLEMA_SAUDE'),
    (5, 'admin.gestor', 'ADMINISTRACAO', '2026-10-08 09:20:11', 'ATUALIZACAO', 'PAGAMENTO', 162, 'TP_STATUS_PAGAMENTO'),
    (6, 'prof.kickboxing', 'PROFESSOR', '2026-10-09 18:05:47', 'CRIACAO', 'AULA', 25, NULL),
    (7, 'prof.jiujitsu', 'PROFESSOR', '2026-10-09 21:35:12', 'CRIACAO', 'INTERESSADO', 16, NULL),
    (8, 'admin.gestor', 'ADMINISTRACAO', '2026-10-13 11:45:00', 'LEITURA', 'ALUNO', 40, 'CPF'),
    (9, 'prof.boxe', 'PROFESSOR', '2026-10-15 18:10:22', 'LEITURA', 'PROBLEMA_SAUDE_ALUNO', 9, 'DS_PROBLEMA_SAUDE'),
    (10, 'prof.muaythai', 'PROFESSOR', '2026-10-17 12:30:54', 'CRIACAO', 'GRADUACAO', 24, NULL),
    (11, 'prof.muaythai', 'PROFESSOR', '2026-10-19 07:05:39', 'CRIACAO', 'AULA', 45, NULL),
    (12, 'admin.gestor', 'ADMINISTRACAO', '2026-10-19 08:58:13', 'ATUALIZACAO', 'ALUNO', 8, 'NM_BAIRRO'),
    (13, 'admin.gestor', 'ADMINISTRACAO', '2026-10-20 16:21:07', 'CRIACAO', 'TRANCAMENTO', 6, NULL),
    (14, 'admin.gestor', 'ADMINISTRACAO', '2026-10-22 10:14:28', 'LEITURA', 'RESPONSAVEL', 1, 'CPF'),
    (15, 'prof.nogi', 'PROFESSOR', '2026-10-22 20:07:51', 'ATUALIZACAO', 'PRESENCA', 60, 'IN_PRESENTE'),
    (16, 'admin.gestor', 'ADMINISTRACAO', '2026-10-26 09:33:02', 'ATUALIZACAO', 'CONTRATO', 3, 'VL_ACRESCIMO_MODALIDADE'),
    (17, 'admin.gestor', 'ADMINISTRACAO', '2026-10-28 17:48:36', 'CRIACAO', 'ALUNO', 92, NULL),
    (18, 'admin.gestor', 'ADMINISTRACAO', '2026-10-28 17:52:10', 'CRIACAO', 'MATRICULA', 204, NULL),
    (19, 'admin.gestor', 'ADMINISTRACAO', '2026-10-30 08:40:44', 'LEITURA', 'PROBLEMA_SAUDE_ALUNO', 30, 'DS_PROBLEMA_SAUDE'),
    (20, 'admin.gestor', 'ADMINISTRACAO', '2026-10-31 11:02:59', 'CRIACAO', 'DESPESA', 50, NULL);

-- =====================================================================================
-- 5. CONSULTAS COM JOIN                                         [RF01, RF03, RF06]
-- =====================================================================================
-- Demonstram que o modelo responde às consultas do dia a dia da recepção e dos
-- professores cruzando as tabelas pelas chaves estrangeiras.
-- Variáveis de sessão usadas daqui em diante (simples, sem procedure):
--   @DT_REF         data "de hoje" da massa de dados (em produção: CURDATE())
--   @DT_INICIO_MES  e @DT_FIM_MES  mês de referência dos relatórios (outubro/2026,
--                   último mês fechado). Para outro mês, basta trocar as duas datas.
SET @DT_REF        = '2026-11-01';
SET @DT_INICIO_MES = '2026-10-01';
SET @DT_FIM_MES    = '2026-10-31';

-- J01 — Grade de alunos ativos: em que turma cada aluno treina, em que dia e com qual professor?
-- Atende: RF03 (turmas e matrículas) e RE05 (cada turma com o professor da sua modalidade)
-- INNER JOIN entre 5 tabelas: MATRICULA liga ALUNO e TURMA; TURMA leva à MODALIDADE e ao PROFESSOR.
-- Só aparecem linhas que têm correspondência em todas as tabelas.
SELECT a.ID_ALUNO,
       a.NM_COMPLETO      AS NM_ALUNO,
       mo.NM_MODALIDADE,
       t.DS_DIA_SEMANA,
       t.HR_INICIO,
       t.HR_FIM,
       p.NM_COMPLETO      AS NM_PROFESSOR
FROM MATRICULA m
INNER JOIN ALUNO a       ON a.ID_ALUNO       = m.ID_ALUNO
INNER JOIN TURMA t       ON t.ID_TURMA       = m.ID_TURMA
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = t.ID_MODALIDADE
INNER JOIN PROFESSOR p   ON p.ID_PROFESSOR   = t.ID_PROFESSOR
WHERE m.TP_SITUACAO_MATRICULA = 'ATIVA'
ORDER BY mo.NM_MODALIDADE, t.DS_DIA_SEMANA, t.HR_INICIO, a.NM_COMPLETO;

-- J02 — Histórico de graduações: quais exames cada aluno fez, em que modalidade, com qual
--       avaliador e qual foi o resultado?
-- Atende: RF06 (histórico com aprovações, reprovações e motivos) e RO06 (Boxe sem faixa)
-- COALESCE troca o NULL da faixa (Boxe não tem faixa) por um texto legível.
SELECT a.NM_COMPLETO                                  AS NM_ALUNO,
       mo.NM_MODALIDADE,
       g.DT_GRADUACAO,
       g.TP_AVALIACAO,
       COALESCE(g.TP_NIVEL_FAIXA, '(análise técnica)') AS TP_NIVEL_FAIXA,
       g.TP_RESULTADO,
       g.DS_MOTIVO_REPROVACAO,
       p.NM_COMPLETO                                  AS NM_AVALIADOR
FROM GRADUACAO g
INNER JOIN ALUNO a       ON a.ID_ALUNO       = g.ID_ALUNO
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = g.ID_MODALIDADE
INNER JOIN PROFESSOR p   ON p.ID_PROFESSOR   = g.ID_PROFESSOR
ORDER BY a.NM_COMPLETO, g.DT_GRADUACAO;

-- J03 — Alunos menores de idade: quem é o responsável legal de cada um e o atestado foi entregue?
-- Atende: RF01 e RE03 (menor de 18 anos com responsável legal). Mostra também a entrega do
--         atestado (RE03), que vale para todos os alunos e é conferida na auditoria A05.
-- TIMESTAMPDIFF(YEAR, nascimento, data) calcula a idade em anos completos.
SELECT a.NM_COMPLETO                                      AS NM_ALUNO,
       TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF)      AS QT_IDADE,
       r.NM_RESPONSAVEL,
       r.DS_PARENTESCO,
       r.NR_TELEFONE                                      AS NR_TELEFONE_RESPONSAVEL,
       a.DT_ENTREGA_ATESTADO
FROM ALUNO a
INNER JOIN RESPONSAVEL r ON r.ID_RESPONSAVEL = a.ID_RESPONSAVEL
ORDER BY r.NM_RESPONSAVEL, a.NM_COMPLETO;

-- J04 — Funil da aula experimental: cada interessado virou aluno? (exemplo de LEFT JOIN)
-- Atende: RF01 (interessados) e RO03 (uma aula experimental, com situação Pendente,
--         Convertido ou Encerrado)
-- LEFT JOIN mantém TODOS os interessados; quando não existe aluno ligado, as colunas do
-- aluno vêm NULL. Com INNER JOIN, os não convertidos sumiriam do resultado.
SELECT i.ID_INTERESSADO,
       i.NM_INTERESSADO,
       mo.NM_MODALIDADE,
       i.DT_AULA,
       i.TP_STATUS,
       a.ID_ALUNO,
       a.NM_COMPLETO AS NM_ALUNO_CADASTRADO
FROM INTERESSADO i
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = i.ID_MODALIDADE
LEFT JOIN ALUNO a        ON a.ID_INTERESSADO = i.ID_INTERESSADO
ORDER BY i.DT_AULA, i.HR_AULA;


-- =====================================================================================
-- 6. EXEMPLOS DE UPDATE                                          [RF04, RF06, RNF04]
-- =====================================================================================
-- Boa prática usada nos dois exemplos: o WHERE usa a chave primária (atinge só a linha
-- certa e funciona com o "safe update mode" do Workbench) e repete a situação esperada
-- como trava (se alguém já tiver alterado o registro, o UPDATE não faz nada).

-- U01 — Baixa de uma parcela em atraso: a aluna Sabrina Lopes Oliveira (plano Anual)
--       pagou hoje, via Pix, a parcela de outubro que estava ATRASADO.
-- Atende: RF04 (controle de atrasos e multas).
-- Regra: planos de fidelidade (mais de 1 mês) pagam multa moratória de 2% por mês de
-- atraso [RO04] (percentual ilustrativo); o plano mensal não teria multa, só o bloqueio.
-- Consequência: a parcela sai de ATRASADO e o aluno é desbloqueado [RE07]
-- (as consultas G04 e A02 mudam; a A13 confere que a multa foi lançada).

-- Antes
SELECT ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, VL_DEVIDO, VL_MULTA, VL_PAGO, TP_STATUS_PAGAMENTO
FROM PAGAMENTO
WHERE ID_PAGAMENTO = 186;

UPDATE PAGAMENTO
SET TP_STATUS_PAGAMENTO = 'PAGO',
    DT_PAGAMENTO        = @DT_REF,
    TP_FORMA_PAGAMENTO  = 'PIX',
    VL_MULTA            = ROUND(VL_DEVIDO * 0.02, 2),
    VL_PAGO             = VL_DEVIDO + ROUND(VL_DEVIDO * 0.02, 2) + COALESCE(VL_TAXA_GRADUACAO, 0)
WHERE ID_PAGAMENTO = 186
  AND TP_STATUS_PAGAMENTO = 'ATRASADO';

-- Depois
SELECT ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_MULTA, VL_PAGO,
       TP_FORMA_PAGAMENTO, TP_STATUS_PAGAMENTO
FROM PAGAMENTO
WHERE ID_PAGAMENTO = 186;

-- U02 — Retorno de trancamento: a aluna Isabela Souza Martins, afastada por lesão desde
--       15/09, foi liberada pelo médico e volta a treinar hoje.
-- Atende: RF06 e RE04 (trancamento suspende a cobrança e prorroga o contrato).
-- São 5 alterações que só fazem sentido juntas, por isso ficam numa TRANSAÇÃO [RNF04]:
-- ou todas são gravadas (COMMIT) ou nenhuma (ROLLBACK, em caso de erro).
--   1) fecha o trancamento   2) reativa a matrícula   3) reativa o aluno   [RE06]
--   4) prorroga DT_FIM do contrato pelos dias em que ficou afastada(o)     [RE04]
--   5) gera a parcela de novembro, que não existia porque o mês estava suspenso,
--      com vencimento no 5º dia útil (09/11) e valor integral             [RO02]
START TRANSACTION;

UPDATE TRANCAMENTO
SET DT_RETORNO_EFETIVA = @DT_REF
WHERE ID_TRANCAMENTO = 4
  AND DT_RETORNO_EFETIVA IS NULL;

UPDATE MATRICULA
SET TP_SITUACAO_MATRICULA = 'ATIVA'
WHERE ID_MATRICULA = 141
  AND TP_SITUACAO_MATRICULA = 'TRANCADA';

UPDATE ALUNO
SET TP_STATUS_ALUNO = 'ATIVO'
WHERE ID_ALUNO = 64
  AND TP_STATUS_ALUNO = 'TRANCADO';

-- DATEDIFF conta os dias do afastamento (15/09 até hoje); DATE_ADD soma esses dias ao fim do ciclo.
UPDATE CONTRATO
SET DT_FIM = DATE_ADD(DT_FIM, INTERVAL DATEDIFF(@DT_REF, '2026-09-15') DAY)
WHERE ID_CONTRATO = 58;

-- ID_PAGAMENTO não é informado: o AUTO_INCREMENT gera o próximo número.
INSERT INTO PAGAMENTO (ID_CONTRATO, DT_VENCIMENTO, VL_DEVIDO, TP_STATUS_PAGAMENTO)
VALUES (58, '2026-11-09', 171.00, 'PENDENTE');

COMMIT;

-- Conferência do retorno
SELECT a.NM_COMPLETO, a.TP_STATUS_ALUNO, m.TP_SITUACAO_MATRICULA,
       tr.DT_INICIO, tr.DT_RETORNO_PREVISTA, tr.DT_RETORNO_EFETIVA,
       c.DT_FIM AS DT_FIM_CONTRATO_PRORROGADO
FROM TRANCAMENTO tr
INNER JOIN MATRICULA m ON m.ID_MATRICULA = tr.ID_MATRICULA
INNER JOIN ALUNO a     ON a.ID_ALUNO     = m.ID_ALUNO
INNER JOIN CONTRATO c  ON c.ID_CONTRATO  = 58
WHERE tr.ID_TRANCAMENTO = 4;


-- =====================================================================================
-- 7. EXEMPLOS DE DELETE (exclusão segura)                       [RE06, RNF02, RNF05]
-- =====================================================================================
-- Roteiro de exclusão segura usado aqui:
--   1) consultar antes e conferir que o registro é o certo e não é referenciado;
--   2) excluir pela chave primária, com uma trava no WHERE;
--   3) registrar a operação no log (sem trigger: em produção quem grava é o sistema,
--      pela conta técnica da Seção 3.5; aqui o INSERT é feito à mão para mostrar o registro).
-- [RE06, RNF05] Matrículas encerradas, CONTRATO, PAGAMENTO e DESPESA nunca são excluídos
-- (histórico e retenção fiscal de 5 anos: os perfis da Seção 3.5 não têm DELETE em
-- CONTRATO, PAGAMENTO e DESPESA, e a FK RESTRICT protege a matrícula que tem presença ou
-- trancamento); o aluno é "excluído" logicamente (INATIVO).
-- [RNF02] O passo 3 é a rastreabilidade exigida pela LGPD.

-- D01 — Eliminar o pré-cadastro de um interessado que desistiu.
-- Atende: RNF02 (LGPD: dado que não tem mais finalidade é eliminado; interessado não
--         convertido sai após o encerramento) e RO03 (só sai quem está ENCERRADO).

-- Passo 1: conferir (ID_ALUNO tem que vir NULL, ou seja, ninguém aponta para ele)
SELECT i.ID_INTERESSADO, i.NM_INTERESSADO, i.TP_STATUS, a.ID_ALUNO
FROM INTERESSADO i
LEFT JOIN ALUNO a ON a.ID_INTERESSADO = i.ID_INTERESSADO
WHERE i.ID_INTERESSADO = 2;

-- Passo 2: excluir. As travas garantem que só sai se estiver ENCERRADO e sem aluno ligado.
-- Mesmo sem a trava, a FK FK_ALUNO_INTERESSADO (RESTRICT) impediria apagar um convertido.
DELETE FROM INTERESSADO
WHERE ID_INTERESSADO = 2
  AND TP_STATUS = 'ENCERRADO'
  AND NOT EXISTS (SELECT 1 FROM ALUNO a WHERE a.ID_INTERESSADO = INTERESSADO.ID_INTERESSADO);

-- Passo 3: registrar no log de acesso
INSERT INTO LOG_ACESSO (NM_USUARIO, TP_PERFIL, DT_ACESSO, TP_OPERACAO, NM_TABELA, ID_REGISTRO, NM_CAMPO)
VALUES ('admin.gestor', 'ADMINISTRACAO', '2026-11-01 09:00:00', 'EXCLUSAO', 'INTERESSADO', 2, NULL);

-- D02 — Remover um telefone que a aluna Beatriz Barbosa Ramos pediu para tirar do cadastro.
-- Atende: RF01 (múltiplos contatos). O telefone é multivalorado (1,n): o aluno precisa
-- continuar com pelo menos um.
-- Passo 1: conferir quantos telefones o aluno tem (precisa ser 2 ou mais)
SELECT ID_ALUNO, COUNT(*) AS QT_TELEFONES
FROM TELEFONE_ALUNO
WHERE ID_ALUNO = 1
GROUP BY ID_ALUNO;

-- Passo 2: excluir pela PK composta (telefone + aluno)
DELETE FROM TELEFONE_ALUNO
WHERE NR_TELEFONE = '1124778764'
  AND ID_ALUNO    = 1;

-- D03 — O que a integridade referencial IMPEDE (exemplo comentado para não parar o script).
-- Atende: RE06 (preservação do histórico) e RNF04 (integridade referencial do InnoDB).
-- Tentar apagar uma modalidade que tem professor, turmas e contratos:
--
--   DELETE FROM MODALIDADE WHERE ID_MODALIDADE = 4;
--
-- Resultado no MySQL:
--   Error Code: 1451. Cannot delete or update a parent row: a foreign key constraint fails
--   (... CONSTRAINT `FK_PROFESSOR_MODALIDADE` FOREIGN KEY (`ID_MODALIDADE`) REFERENCES `MODALIDADE` ...)
--
-- O caminho correto para "tirar" uma modalidade de oferta é a exclusão lógica:
--   UPDATE MODALIDADE SET TP_SITUACAO_MODALIDADE = 'INATIVA' WHERE ID_MODALIDADE = 4;
-- O histórico de turmas, aulas, graduações e pagamentos continua preservado.
--
-- Já nas tabelas de apoio o ON DELETE CASCADE age sozinho: se um professor fosse excluído
-- (sem turmas, aulas nem despesas ligadas a ele), seus e-mails, telefones, especializações,
-- níveis e qualificações seriam apagados junto, sem deixar registros "órfãos".


-- =====================================================================================
-- 8. CONSULTAS GERENCIAIS                                        [RF03, RF04, RF05]
-- =====================================================================================
-- Respondem a perguntas de decisão do gestor. Mês de referência: outubro/2026
-- (@DT_INICIO_MES a @DT_FIM_MES), último mês fechado da massa de dados.

-- G01 — Qual o faturamento recebido por modalidade no mês de referência?
-- Atende: P6 (apoio ao repasse e à margem por modalidade) [RF04, RO01: rateio das modalidades do contrato]
-- Regime de caixa (data em que o dinheiro entrou). Um contrato pode cobrir mais de uma
-- modalidade (tabela PARTICIPA); para não contar a mesma parcela duas vezes, o valor é
-- dividido igualmente entre as modalidades do contrato (rateio). A subconsulta QM conta
-- quantas modalidades cada contrato tem.
SELECT mo.NM_MODALIDADE,
       COUNT(pg.ID_PAGAMENTO)                       AS QT_PARCELAS_RECEBIDAS,
       ROUND(SUM(pg.VL_PAGO / qm.QT_MODALIDADES), 2) AS VL_RECEITA_RATEADA
FROM PAGAMENTO pg
INNER JOIN PARTICIPA pa  ON pa.ID_CONTRATO   = pg.ID_CONTRATO
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = pa.ID_MODALIDADE
INNER JOIN (SELECT ID_CONTRATO, COUNT(*) AS QT_MODALIDADES
            FROM PARTICIPA
            GROUP BY ID_CONTRATO) qm ON qm.ID_CONTRATO = pg.ID_CONTRATO
WHERE pg.TP_STATUS_PAGAMENTO = 'PAGO'
  AND pg.DT_PAGAMENTO BETWEEN @DT_INICIO_MES AND @DT_FIM_MES
GROUP BY mo.NM_MODALIDADE
ORDER BY VL_RECEITA_RATEADA DESC;

-- G02 — Como evoluiu a receita mês a mês: quanto era previsto, quanto entrou e quanto ficou em aberto?
-- Atende: P2 (previsto x recebido por mês; KPI02 em reais) [RF04, RO02: uma parcela por mês]
-- Regime de competência: agrupa pelo mês de vencimento da parcela.
SELECT DATE_FORMAT(DT_VENCIMENTO, '%Y-%m')                                       AS MES_COMPETENCIA,
       COUNT(*)                                                                  AS QT_PARCELAS,
       SUM(VL_DEVIDO)                                                            AS VL_PREVISTO,
       SUM(CASE WHEN TP_STATUS_PAGAMENTO = 'PAGO' THEN VL_PAGO ELSE 0 END)      AS VL_RECEBIDO,
       SUM(CASE WHEN TP_STATUS_PAGAMENTO <> 'PAGO' THEN VL_DEVIDO ELSE 0 END)   AS VL_EM_ABERTO
FROM PAGAMENTO
GROUP BY DATE_FORMAT(DT_VENCIMENTO, '%Y-%m')
ORDER BY MES_COMPETENCIA;

-- G03 — Qual a taxa de inadimplência de cada mês?
-- Atende: P2 e KPI02 (taxa de inadimplência) [RF04, RE07: inadimplência derivada das parcelas]
-- Considera só parcelas já vencidas na data de referência; inadimplente = vencida e não paga.
-- O 100.0 (com casa decimal) força divisão decimal.
SELECT DATE_FORMAT(DT_VENCIMENTO, '%Y-%m')                                       AS MES_COMPETENCIA,
       COUNT(*)                                                                  AS QT_PARCELAS_VENCIDAS,
       SUM(CASE WHEN TP_STATUS_PAGAMENTO <> 'PAGO' THEN 1 ELSE 0 END)           AS QT_NAO_PAGAS,
       ROUND(100.0 * SUM(CASE WHEN TP_STATUS_PAGAMENTO <> 'PAGO' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                                      AS PC_INADIMPLENCIA,
       SUM(CASE WHEN TP_STATUS_PAGAMENTO <> 'PAGO' THEN VL_DEVIDO ELSE 0 END)   AS VL_INADIMPLENTE
FROM PAGAMENTO
WHERE DT_VENCIMENTO < @DT_REF
GROUP BY DATE_FORMAT(DT_VENCIMENTO, '%Y-%m')
ORDER BY MES_COMPETENCIA;

-- G04 — Quem são os inadimplentes hoje, quanto devem e há quantos dias?
-- Atende: P2 (lista de cobrança e de bloqueio na recepção/catraca) [RF04, RE07, RNF01, RNF03]
-- Usa o índice IX_PAGAMENTO_VENC_STATUS (consulta crítica do RNF03).
-- O telefone vem por subconsulta para não multiplicar as linhas (o aluno pode ter 2 telefones,
-- e um JOIN direto dobraria a soma das parcelas).
SELECT a.ID_ALUNO,
       a.NM_COMPLETO                                              AS NM_TITULAR,
       (SELECT MIN(te.NR_TELEFONE) FROM TELEFONE_ALUNO te
         WHERE te.ID_ALUNO = a.ID_ALUNO)                          AS NR_TELEFONE,
       c.ID_CONTRATO,
       CASE WHEN c.DT_CANCELAMENTO IS NULL THEN 'VIGENTE' ELSE 'CANCELADO' END AS TP_CONTRATO,
       COUNT(pg.ID_PAGAMENTO)                                     AS QT_PARCELAS_EM_ABERTO,
       SUM(pg.VL_DEVIDO)                                          AS VL_TOTAL_DEVIDO,
       DATEDIFF(@DT_REF, MIN(pg.DT_VENCIMENTO))                   AS QT_DIAS_ATRASO
FROM PAGAMENTO pg
INNER JOIN CONTRATO c ON c.ID_CONTRATO = pg.ID_CONTRATO
INNER JOIN ALUNO a    ON a.ID_ALUNO    = c.ID_ALUNO
WHERE pg.TP_STATUS_PAGAMENTO <> 'PAGO'
  AND pg.DT_VENCIMENTO < @DT_REF
GROUP BY a.ID_ALUNO, a.NM_COMPLETO, c.ID_CONTRATO, c.DT_CANCELAMENTO
ORDER BY QT_DIAS_ATRASO DESC, VL_TOTAL_DEVIDO DESC;

-- G05 — Quais modalidades são as mais procuradas (alunos ativos e ocupação das turmas)?
-- Atende: P5 e KPI07 (ocupação das vagas; abrir ou fechar turmas) [RF03, RE01, RE02]
-- LEFT JOIN a partir de MODALIDADE para que nenhuma modalidade suma do relatório,
-- mesmo que não tenha matrícula ativa. A ocupação compara matrículas ativas com as vagas.
SELECT mo.NM_MODALIDADE,
       COUNT(DISTINCT t.ID_TURMA)                                AS QT_TURMAS,
       COUNT(DISTINCT m.ID_ALUNO)                                AS QT_ALUNOS_ATIVOS,
       COUNT(m.ID_MATRICULA)                                     AS QT_MATRICULAS_ATIVAS,
       ROUND(100.0 * COUNT(m.ID_MATRICULA) / (COUNT(DISTINCT t.ID_TURMA) * 30), 1) AS PC_OCUPACAO_VAGAS
FROM MODALIDADE mo
LEFT JOIN TURMA t     ON t.ID_MODALIDADE = mo.ID_MODALIDADE
LEFT JOIN MATRICULA m ON m.ID_TURMA = t.ID_TURMA
                     AND m.TP_SITUACAO_MATRICULA = 'ATIVA'
GROUP BY mo.ID_MODALIDADE, mo.NM_MODALIDADE
ORDER BY QT_ALUNOS_ATIVOS DESC;

-- G06 — Quantas aulas experimentais viram matrícula, por modalidade?
-- Atende: P7 (conversão da aula experimental por modalidade; KPI09 mensal na G18) [RF01, RO03]
-- NULLIF evita divisão por zero quando a modalidade ainda não teve interessados.
SELECT mo.NM_MODALIDADE,
       COUNT(i.ID_INTERESSADO)                                            AS QT_INTERESSADOS,
       SUM(CASE WHEN i.TP_STATUS = 'CONVERTIDO' THEN 1 ELSE 0 END)        AS QT_CONVERTIDOS,
       SUM(CASE WHEN i.TP_STATUS = 'ENCERRADO'  THEN 1 ELSE 0 END)        AS QT_DESISTENTES,
       SUM(CASE WHEN i.TP_STATUS = 'PENDENTE'   THEN 1 ELSE 0 END)        AS QT_PENDENTES,
       ROUND(100.0 * SUM(CASE WHEN i.TP_STATUS = 'CONVERTIDO' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(i.ID_INTERESSADO), 0), 1)                     AS PC_CONVERSAO
FROM MODALIDADE mo
LEFT JOIN INTERESSADO i ON i.ID_MODALIDADE = mo.ID_MODALIDADE
GROUP BY mo.ID_MODALIDADE, mo.NM_MODALIDADE
ORDER BY PC_CONVERSAO DESC;

-- G07 — Quanto deve ser repassado a cada professor pelas aulas dadas no mês de referência?
-- Atende: P6 (apuração do repasse: aulas ministradas x valor por aula; base do KPI08) [RF05, RO07]
-- Conta as aulas pelo professor que DE FATO ministrou (AULA.ID_PROFESSOR), inclusive
-- substituições e reposições. O resultado é a base do lançamento em DESPESA, pago no
-- 5º dia útil do mês seguinte. Pela RO07 só os 5 prestadores recebem: o VL_POR_AULA do
-- gestor é 0 (PN11), então a linha dele mostra as aulas que deu, com repasse zero, e não
-- vira despesa.
SELECT p.ID_PROFESSOR,
       p.NM_COMPLETO                        AS NM_PROFESSOR,
       mo.NM_MODALIDADE,
       COUNT(au.ID_AULA)                    AS QT_AULAS_MINISTRADAS,
       p.VL_POR_AULA,
       COUNT(au.ID_AULA) * p.VL_POR_AULA    AS VL_REPASSE
FROM PROFESSOR p
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = p.ID_MODALIDADE
LEFT JOIN AULA au        ON au.ID_PROFESSOR = p.ID_PROFESSOR
                        AND au.DT_AULA BETWEEN @DT_INICIO_MES AND @DT_FIM_MES
GROUP BY p.ID_PROFESSOR, p.NM_COMPLETO, mo.NM_MODALIDADE, p.VL_POR_AULA
ORDER BY VL_REPASSE DESC;

-- G08 — Qual o resultado financeiro (entradas - saídas) de cada mês?
-- Atende: KPI10 (resultado mensal e margem, em regime de caixa) [RF04]
-- UNION ALL empilha as entradas (PAGAMENTO) e as saídas (DESPESA) numa única lista de
-- movimentos; depois o GROUP BY soma por mês. Só entra o que foi efetivamente pago.
SELECT MOV.MES,
       SUM(MOV.VL_ENTRADA)                     AS VL_ENTRADAS,
       SUM(MOV.VL_SAIDA)                       AS VL_SAIDAS,
       SUM(MOV.VL_ENTRADA) - SUM(MOV.VL_SAIDA) AS VL_RESULTADO,
       ROUND(100.0 * (SUM(MOV.VL_ENTRADA) - SUM(MOV.VL_SAIDA)) / SUM(MOV.VL_ENTRADA), 1) AS PC_MARGEM
FROM (SELECT DATE_FORMAT(DT_PAGAMENTO, '%Y-%m') AS MES, VL_PAGO AS VL_ENTRADA, 0 AS VL_SAIDA
      FROM PAGAMENTO
      WHERE TP_STATUS_PAGAMENTO = 'PAGO'
      UNION ALL
      SELECT DATE_FORMAT(DT_PAGAMENTO, '%Y-%m'), 0, VL_PAGO
      FROM DESPESA
      WHERE TP_SITUACAO_DESPESA = 'PAGO') MOV
WHERE MOV.MES BETWEEN '2026-08' AND '2026-10'
GROUP BY MOV.MES
ORDER BY MOV.MES;

-- G09 — Quais alunos estão com frequência abaixo de 50% em alguma modalidade no mês (risco de evasão)?
-- Atende: P4 (lista de alunos em risco; KPI05 na G14) [RF05, RO05, RNF03]
-- A frequência é contada POR MODALIDADE, como pedem o P4 e o PN08: o exame de faixa é de uma
-- modalidade, e quem treina duas pode estar assíduo numa e faltando na outra. A mesma conta
-- embasa a liberação para o exame de faixa (RO05).
-- Frequência = presenças / aulas registradas para o aluno na modalidade no mês, somando as
-- turmas dela. Só entram as modalidades em que o aluno tem pelo menos 4 aulas registradas:
-- quem se matriculou no fim do mês ou foi bloqueado por atraso tem poucas aulas na lista, e a
-- porcentagem ficaria distorcida.
SELECT a.ID_ALUNO,
       a.NM_COMPLETO                                                     AS NM_ALUNO,
       mo.NM_MODALIDADE,
       COUNT(DISTINCT m.ID_TURMA)                                        AS QT_TURMAS,
       COUNT(*)                                                          AS QT_AULAS,
       SUM(CASE WHEN pr.IN_PRESENTE = TRUE THEN 1 ELSE 0 END)            AS QT_PRESENCAS,
       ROUND(100.0 * SUM(CASE WHEN pr.IN_PRESENTE = TRUE THEN 1 ELSE 0 END) / COUNT(*), 1) AS PC_FREQUENCIA
FROM PRESENCA pr
INNER JOIN AULA au       ON au.ID_AULA       = pr.ID_AULA
INNER JOIN TURMA t       ON t.ID_TURMA       = au.ID_TURMA
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = t.ID_MODALIDADE
INNER JOIN MATRICULA m   ON m.ID_MATRICULA   = pr.ID_MATRICULA
INNER JOIN ALUNO a       ON a.ID_ALUNO       = m.ID_ALUNO
WHERE au.DT_AULA BETWEEN @DT_INICIO_MES AND @DT_FIM_MES
GROUP BY a.ID_ALUNO, a.NM_COMPLETO, mo.ID_MODALIDADE, mo.NM_MODALIDADE
HAVING COUNT(*) >= 4
   AND 100.0 * SUM(CASE WHEN pr.IN_PRESENTE = TRUE THEN 1 ELSE 0 END) / COUNT(*) < 50
ORDER BY PC_FREQUENCIA, a.NM_COMPLETO;

-- G10 — Como os alunos preferem pagar (participação de cada forma de pagamento)?
-- Atende: P2 (formas de pagamento: negociação de taxas e incentivo ao Pix) [RF04]
SELECT TP_FORMA_PAGAMENTO,
       COUNT(*)                                                     AS QT_PAGAMENTOS,
       SUM(VL_PAGO)                                                 AS VL_RECEBIDO,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM PAGAMENTO
                                 WHERE TP_STATUS_PAGAMENTO = 'PAGO'), 1) AS PC_PARTICIPACAO
FROM PAGAMENTO
WHERE TP_STATUS_PAGAMENTO = 'PAGO'
GROUP BY TP_FORMA_PAGAMENTO
ORDER BY QT_PAGAMENTOS DESC;

-- G11 — Quais planos têm mais contratos vigentes e quanto cada um gera por mês?
-- Atende: P3 e KPI04 (MRR por plano) [RF04, RO01]
-- LEFT JOIN mostra também o plano que ainda não vendeu nenhum contrato.
-- A condição de vigência fica no ON (e não no WHERE) para não eliminar o plano sem contrato.
SELECT pl.NM_PLANO,
       pl.QT_DURACAO_MESES,
       pl.PC_DESCONTO,
       COUNT(c.ID_CONTRATO)                                                   AS QT_CONTRATOS_VIGENTES,
       COALESCE(SUM(c.VL_MENSAL_ACORDADO + COALESCE(c.VL_ACRESCIMO_MODALIDADE, 0)), 0) AS VL_RECEITA_MENSAL
FROM PLANO pl
LEFT JOIN CONTRATO c ON c.ID_PLANO = pl.ID_PLANO
                    AND c.DT_CANCELAMENTO IS NULL
GROUP BY pl.ID_PLANO, pl.NM_PLANO, pl.QT_DURACAO_MESES, pl.PC_DESCONTO
ORDER BY QT_CONTRATOS_VIGENTES DESC, pl.ID_PLANO;

-- G12 — Qual a completude do cadastro digital dos alunos atuais (sem fichas de papel incompletas)?
-- Atende: P1 (fichas de papel e risco de perda de dados) e KPI01 [RF01, RE03]
-- Aluno atual = ATIVO ou TRANCADO. Pendência = sem telefone, sem e-mail ou sem registro de
-- saúde (atributos (1,n) do DER), menor de 18 anos sem responsável ou sem atestado (RE03).
-- NOT EXISTS procura a ausência de linha nas tabelas de apoio; a lista de quem tem pendência
-- é a A05 (atestado e responsável).
SELECT COUNT(*)                                                       AS QT_ALUNOS_ATUAIS,
       SUM(CASE WHEN X.IN_PENDENCIA = 1 THEN 1 ELSE 0 END)            AS QT_COM_PENDENCIA,
       ROUND(100.0 * SUM(CASE WHEN X.IN_PENDENCIA = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS PC_COMPLETUDE
FROM (SELECT a.ID_ALUNO,
             CASE WHEN NOT EXISTS (SELECT 1 FROM TELEFONE_ALUNO t WHERE t.ID_ALUNO = a.ID_ALUNO)
                    OR NOT EXISTS (SELECT 1 FROM EMAIL_ALUNO e WHERE e.ID_ALUNO = a.ID_ALUNO)
                    OR NOT EXISTS (SELECT 1 FROM PROBLEMA_SAUDE_ALUNO s WHERE s.ID_ALUNO = a.ID_ALUNO)
                    OR (TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF) < 18 AND a.ID_RESPONSAVEL IS NULL)
                    OR a.DT_ENTREGA_ATESTADO IS NULL
                  THEN 1 ELSE 0 END AS IN_PENDENCIA
      FROM ALUNO a
      WHERE a.TP_STATUS_ALUNO IN ('ATIVO', 'TRANCADO')) X;

-- G13 — Qual a taxa de cancelamento de contratos em cada mês?
-- Atende: P3 (planos e multas acertados de boca) e KPI03 [RF04, RO04]
-- Taxa = contratos cancelados no mês ÷ contratos vigentes no 1º dia do mês. Vigente no 1º dia =
-- já iniciado e sem cancelamento até aquela data. QT_COM_MULTA mostra quantos cancelamentos
-- antecipados de plano de fidelidade tiveram a multa rescisória lançada (A08 lista os que não tiveram).
SELECT M.MES,
       (SELECT COUNT(*) FROM CONTRATO c
         WHERE c.DT_INICIO < M.DT_PRIMEIRO_DIA
           AND (c.DT_CANCELAMENTO IS NULL OR c.DT_CANCELAMENTO >= M.DT_PRIMEIRO_DIA)) AS QT_VIGENTES_NO_INICIO,
       (SELECT COUNT(*) FROM CONTRATO c
         WHERE c.DT_CANCELAMENTO >= M.DT_PRIMEIRO_DIA
           AND c.DT_CANCELAMENTO <  DATE_ADD(M.DT_PRIMEIRO_DIA, INTERVAL 1 MONTH))   AS QT_CANCELADOS,
       (SELECT COUNT(*) FROM CONTRATO c
         WHERE c.DT_CANCELAMENTO >= M.DT_PRIMEIRO_DIA
           AND c.DT_CANCELAMENTO <  DATE_ADD(M.DT_PRIMEIRO_DIA, INTERVAL 1 MONTH)
           AND c.VL_MULTA_RESCISORIA IS NOT NULL)                                    AS QT_COM_MULTA,
       ROUND(100.0 *
         (SELECT COUNT(*) FROM CONTRATO c
           WHERE c.DT_CANCELAMENTO >= M.DT_PRIMEIRO_DIA
             AND c.DT_CANCELAMENTO <  DATE_ADD(M.DT_PRIMEIRO_DIA, INTERVAL 1 MONTH))
         / NULLIF((SELECT COUNT(*) FROM CONTRATO c
                    WHERE c.DT_INICIO < M.DT_PRIMEIRO_DIA
                      AND (c.DT_CANCELAMENTO IS NULL OR c.DT_CANCELAMENTO >= M.DT_PRIMEIRO_DIA)), 0), 1) AS PC_CANCELAMENTO
FROM (SELECT '2026-08' AS MES, DATE('2026-08-01') AS DT_PRIMEIRO_DIA
      UNION ALL SELECT '2026-09', DATE('2026-09-01')
      UNION ALL SELECT '2026-10', DATE('2026-10-01')) M
ORDER BY M.MES;

-- G14 — Qual a frequência média do mês e quantos alunos estão em risco de evasão, por modalidade?
-- Atende: P4 (graduação sem comprovação de frequência) e KPI05 [RF05, RO05]
-- A unidade é o aluno NA MODALIDADE (P4 e PN08), com pelo menos 4 aulas registradas no mês: a
-- mesma regra da G09, que lista quem está em risco. Frequência média = presenças ÷ aulas
-- registradas; em risco = frequência abaixo de 50%.
-- WITH cria a tabela temporária F (frequência de cada aluno em cada modalidade), usada duas
-- vezes: por modalidade e na linha TOTAL do UNION ALL, onde o aluno de duas modalidades conta
-- uma vez em cada uma.
WITH F AS (
    SELECT m.ID_ALUNO,
           t.ID_MODALIDADE,
           COUNT(*)                                                 AS QT_AULAS,
           SUM(CASE WHEN pr.IN_PRESENTE = TRUE THEN 1 ELSE 0 END)   AS QT_PRESENCAS
    FROM PRESENCA pr
    INNER JOIN AULA au     ON au.ID_AULA     = pr.ID_AULA
    INNER JOIN TURMA t     ON t.ID_TURMA     = au.ID_TURMA
    INNER JOIN MATRICULA m ON m.ID_MATRICULA = pr.ID_MATRICULA
    WHERE au.DT_AULA BETWEEN @DT_INICIO_MES AND @DT_FIM_MES
    GROUP BY m.ID_ALUNO, t.ID_MODALIDADE
    HAVING COUNT(*) >= 4
)
SELECT mo.NM_MODALIDADE,
       COUNT(*)                                                       AS QT_ALUNOS_AVALIADOS,
       ROUND(100.0 * SUM(F.QT_PRESENCAS) / SUM(F.QT_AULAS), 1)        AS PC_FREQUENCIA_MEDIA,
       SUM(CASE WHEN 100.0 * F.QT_PRESENCAS / F.QT_AULAS < 50 THEN 1 ELSE 0 END) AS QT_EM_RISCO,
       ROUND(100.0 * SUM(CASE WHEN 100.0 * F.QT_PRESENCAS / F.QT_AULAS < 50 THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                           AS PC_EM_RISCO
FROM F
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = F.ID_MODALIDADE
GROUP BY mo.ID_MODALIDADE, mo.NM_MODALIDADE
UNION ALL
SELECT 'TOTAL',
       COUNT(*),
       ROUND(100.0 * SUM(F.QT_PRESENCAS) / SUM(F.QT_AULAS), 1),
       SUM(CASE WHEN 100.0 * F.QT_PRESENCAS / F.QT_AULAS < 50 THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN 100.0 * F.QT_PRESENCAS / F.QT_AULAS < 50 THEN 1 ELSE 0 END)
             / COUNT(*), 1)
FROM F
ORDER BY NM_MODALIDADE = 'TOTAL', NM_MODALIDADE;

-- G15 — Os alunos chegaram preparados ao exame? Qual era a frequência de cada um, na modalidade
--       do exame, nos 90 dias antes?
-- Atende: P4 (graduação sem comprovação de frequência) [RF06, RO05]
-- Para cada exame de faixa (a análise técnica do Boxe não tem faixa), mostra o resultado e a
-- frequência do aluno nos 90 dias anteriores, contando só as aulas da MODALIDADE do exame
-- (P4 e PN08): presença em outra modalidade não prepara para esta faixa. A subconsulta F traz
-- cada presença com o aluno e a modalidade da aula; o LEFT JOIN mantém o exame mesmo que o
-- aluno não tenha aula registrada na janela (na massa, a chamada começa em outubro/2026).
SELECT g.ID_GRADUACAO,
       a.NM_COMPLETO                                              AS NM_ALUNO,
       mo.NM_MODALIDADE,
       g.TP_NIVEL_FAIXA,
       g.DT_GRADUACAO,
       g.TP_RESULTADO,
       g.DS_MOTIVO_REPROVACAO,
       COUNT(F.ID_AULA)                                           AS QT_AULAS_90_DIAS,
       ROUND(100.0 * SUM(CASE WHEN F.IN_PRESENTE = TRUE THEN 1 ELSE 0 END)
             / NULLIF(COUNT(F.ID_AULA), 0), 1)                    AS PC_FREQUENCIA_90_DIAS
FROM GRADUACAO g
INNER JOIN ALUNO a       ON a.ID_ALUNO       = g.ID_ALUNO
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = g.ID_MODALIDADE
LEFT JOIN (SELECT m.ID_ALUNO, t.ID_MODALIDADE, au.ID_AULA, au.DT_AULA, pr.IN_PRESENTE
           FROM PRESENCA pr
           INNER JOIN AULA au     ON au.ID_AULA     = pr.ID_AULA
           INNER JOIN TURMA t     ON t.ID_TURMA     = au.ID_TURMA
           INNER JOIN MATRICULA m ON m.ID_MATRICULA = pr.ID_MATRICULA) F
       ON  F.ID_ALUNO      = g.ID_ALUNO
       AND F.ID_MODALIDADE = g.ID_MODALIDADE
       AND F.DT_AULA      >= DATE_SUB(g.DT_GRADUACAO, INTERVAL 90 DAY)
       AND F.DT_AULA      <  g.DT_GRADUACAO
WHERE g.TP_AVALIACAO = 'EXAME_FAIXA'
GROUP BY g.ID_GRADUACAO, a.NM_COMPLETO, mo.NM_MODALIDADE, g.TP_NIVEL_FAIXA,
         g.DT_GRADUACAO, g.TP_RESULTADO, g.DS_MOTIVO_REPROVACAO
ORDER BY g.DT_GRADUACAO DESC, a.NM_COMPLETO;

-- G16 — Qual a taxa de aprovação nas avaliações de graduação, por modalidade e no total?
-- Atende: P4 (graduação sem comprovação de frequência) e KPI06 [RF06, RO05, RO06]
-- Janela de 12 meses até a data de referência. Entram o exame de faixa e a análise técnica do Boxe.
SELECT mo.NM_MODALIDADE,
       COUNT(*)                                                       AS QT_AVALIADOS,
       SUM(CASE WHEN g.TP_RESULTADO = 'APROVADO' THEN 1 ELSE 0 END)   AS QT_APROVADOS,
       ROUND(100.0 * SUM(CASE WHEN g.TP_RESULTADO = 'APROVADO' THEN 1 ELSE 0 END) / COUNT(*), 1) AS PC_APROVACAO
FROM GRADUACAO g
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = g.ID_MODALIDADE
WHERE g.DT_GRADUACAO >  DATE_SUB(@DT_REF, INTERVAL 12 MONTH)
  AND g.DT_GRADUACAO <= @DT_REF
GROUP BY mo.ID_MODALIDADE, mo.NM_MODALIDADE
UNION ALL
SELECT 'TOTAL',
       COUNT(*),
       SUM(CASE WHEN g.TP_RESULTADO = 'APROVADO' THEN 1 ELSE 0 END),
       ROUND(100.0 * SUM(CASE WHEN g.TP_RESULTADO = 'APROVADO' THEN 1 ELSE 0 END) / COUNT(*), 1)
FROM GRADUACAO g
WHERE g.DT_GRADUACAO >  DATE_SUB(@DT_REF, INTERVAL 12 MONTH)
  AND g.DT_GRADUACAO <= @DT_REF;

-- G17 — Quanto da receita de cada mês vai para o repasse aos professores?
-- Atende: P6 (repasse aos professores calculado de memória) e KPI08 [RF04, RO07]
-- Repasse = despesas pagas que têm professor; receita = parcelas pagas no mês (regime de caixa).
-- Cada total é somado na sua própria subconsulta (R, E e G), agrupada pelo mês, e as três são
-- ligadas pelo mês: assim nenhuma coluna fica fora do GROUP BY (ONLY_FULL_GROUP_BY do MySQL 8).
-- As duas últimas colunas simulam o custo se as aulas do gestor (o professor com VL_POR_AULA
-- = 0, que não recebe por aula) fossem pagas ao valor médio dos prestadores (G07 mostra as
-- aulas de cada um).
SELECT R.MES,
       R.VL_REPASSE,
       E.VL_RECEITA,
       ROUND(100.0 * R.VL_REPASSE / E.VL_RECEITA, 1)                  AS PC_CUSTO_DOCENTE,
       COALESCE(G.QT_AULAS_GESTOR, 0)                                 AS QT_AULAS_GESTOR,
       ROUND(100.0 * (R.VL_REPASSE + COALESCE(G.QT_AULAS_GESTOR, 0) * V.VL_MEDIO_PRESTADOR)
             / E.VL_RECEITA, 1)                                       AS PC_CUSTO_SE_GESTOR_FOSSE_PAGO
FROM (SELECT DATE_FORMAT(d.DT_PAGAMENTO, '%Y-%m') AS MES,
             SUM(d.VL_PAGO)                       AS VL_REPASSE
      FROM DESPESA d
      WHERE d.ID_PROFESSOR IS NOT NULL
        AND d.TP_SITUACAO_DESPESA = 'PAGO'
      GROUP BY DATE_FORMAT(d.DT_PAGAMENTO, '%Y-%m')) R
INNER JOIN (SELECT DATE_FORMAT(p.DT_PAGAMENTO, '%Y-%m') AS MES,
                   SUM(p.VL_PAGO)                       AS VL_RECEITA
            FROM PAGAMENTO p
            WHERE p.TP_STATUS_PAGAMENTO = 'PAGO'
            GROUP BY DATE_FORMAT(p.DT_PAGAMENTO, '%Y-%m')) E ON E.MES = R.MES
LEFT JOIN (SELECT DATE_FORMAT(au.DT_AULA, '%Y-%m') AS MES,
                  COUNT(*)                         AS QT_AULAS_GESTOR
           FROM AULA au
           INNER JOIN PROFESSOR p ON p.ID_PROFESSOR = au.ID_PROFESSOR
           WHERE p.VL_POR_AULA = 0
           GROUP BY DATE_FORMAT(au.DT_AULA, '%Y-%m')) G ON G.MES = R.MES
CROSS JOIN (SELECT AVG(VL_POR_AULA) AS VL_MEDIO_PRESTADOR
            FROM PROFESSOR
            WHERE VL_POR_AULA > 0) V
WHERE R.MES BETWEEN '2026-08' AND '2026-10'
ORDER BY R.MES;

-- G18 — Quantas aulas experimentais já realizadas viraram matrícula em cada mês?
-- Atende: P7 (contatos de aula experimental perdidos) e KPI09 [RF01, RO03]
-- Só entram aulas já realizadas (DT_AULA antes da data de referência). O interessado PENDENTE
-- ainda não decidiu e fica no denominador; por isso a taxa do mês corrente pode subir. G06 mostra
-- a mesma conversão por modalidade.
SELECT DATE_FORMAT(i.DT_AULA, '%Y-%m')                                AS MES_AULA,
       COUNT(*)                                                       AS QT_AULAS_REALIZADAS,
       SUM(CASE WHEN i.TP_STATUS = 'CONVERTIDO' THEN 1 ELSE 0 END)    AS QT_CONVERTIDOS,
       SUM(CASE WHEN i.TP_STATUS = 'ENCERRADO'  THEN 1 ELSE 0 END)    AS QT_DESISTENTES,
       SUM(CASE WHEN i.TP_STATUS = 'PENDENTE'   THEN 1 ELSE 0 END)    AS QT_SEM_DECISAO,
       ROUND(100.0 * SUM(CASE WHEN i.TP_STATUS = 'CONVERTIDO' THEN 1 ELSE 0 END) / COUNT(*), 1) AS PC_CONVERSAO
FROM INTERESSADO i
WHERE i.DT_AULA < @DT_REF
GROUP BY DATE_FORMAT(i.DT_AULA, '%Y-%m')
ORDER BY MES_AULA;


-- =====================================================================================
-- 9. CONSULTAS DE AUDITORIA
-- =====================================================================================
-- Verificam regras de negócio que o banco NÃO consegue garantir sozinho com PK, FK ou
-- CHECK (regras que dependem da data de hoje ou que cruzam tabelas). Resultado vazio =
-- regra cumprida; cada linha retornada é uma inconsistência para a administração tratar.
-- A massa de dados tem um caso proposital para cada uma (listados na Seção 4), para que
-- a demonstração não volte vazia. Os códigos RO/RE seguem as Regras de Negócio do README e o
-- dicionário de dados; PN é o processo de negócio do README.
-- A11 a A13 conferem regras que poderiam virar constraint em outro SGBD, mas que no MySQL
-- cruzam tabelas ou contam linhas: modalidade da matrícula contra o contrato, contrato
-- único vigente e multa por atraso nos planos de fidelidade.

-- A01 — Existem matrículas ativas sem nenhum registro de pagamento associado?
-- Verifica: RF04 / RO02 (toda matrícula ativa deve possuir histórico financeiro: o contrato gera
--           uma parcela por mês com vencimento no 5º dia útil; a 1ª já nasce na assinatura,
--           com vencimento no 5º dia útil seguinte, PN02)
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       m.ID_MATRICULA,
       m.ID_TURMA,
       m.DT_MATRICULA
FROM MATRICULA m
INNER JOIN ALUNO a ON a.ID_ALUNO = m.ID_ALUNO
WHERE m.TP_SITUACAO_MATRICULA = 'ATIVA'
  -- não tem parcela em contrato próprio (vale também para o Plano Família)
  AND NOT EXISTS (SELECT 1
                  FROM CONTRATO c
                  INNER JOIN PAGAMENTO pg ON pg.ID_CONTRATO = c.ID_CONTRATO
                  WHERE c.ID_ALUNO = a.ID_ALUNO);

-- A02 — Algum aluno teve presença registrada enquanto estava bloqueado por parcela em atraso?
-- Verifica: RE07 (passado o 5º dia útil sem pagamento, o aluno fica bloqueado a partir do
--           6º dia útil e não tem presença registrada)
-- Bloqueio = aula depois do vencimento e (parcela ainda ATRASADO ou paga só depois da aula).
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       au.ID_AULA,
       au.DT_AULA,
       pg.ID_PAGAMENTO,
       pg.DT_VENCIMENTO,
       pg.TP_STATUS_PAGAMENTO,
       pg.DT_PAGAMENTO
FROM PRESENCA pr
INNER JOIN AULA au      ON au.ID_AULA      = pr.ID_AULA
INNER JOIN MATRICULA m  ON m.ID_MATRICULA  = pr.ID_MATRICULA
INNER JOIN ALUNO a      ON a.ID_ALUNO      = m.ID_ALUNO
INNER JOIN CONTRATO c   ON c.ID_ALUNO      = a.ID_ALUNO
INNER JOIN PAGAMENTO pg ON pg.ID_CONTRATO  = c.ID_CONTRATO
WHERE au.DT_AULA > pg.DT_VENCIMENTO
  AND (    pg.TP_STATUS_PAGAMENTO = 'ATRASADO'
       OR (pg.TP_STATUS_PAGAMENTO = 'PAGO' AND pg.DT_PAGAMENTO > au.DT_AULA))
ORDER BY au.DT_AULA;

-- A03 — Algum aluno teve presença registrada durante um trancamento?
-- Verifica: RE04 / RE07 (matrícula trancada fica suspensa e não registra presença)
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       tr.ID_TRANCAMENTO,
       tr.DT_INICIO,
       tr.DT_RETORNO_EFETIVA,
       au.ID_AULA,
       au.DT_AULA,
       pr.IN_PRESENTE
FROM PRESENCA pr
INNER JOIN AULA au        ON au.ID_AULA       = pr.ID_AULA
INNER JOIN TRANCAMENTO tr ON tr.ID_MATRICULA  = pr.ID_MATRICULA
INNER JOIN MATRICULA m    ON m.ID_MATRICULA   = pr.ID_MATRICULA
INNER JOIN ALUNO a        ON a.ID_ALUNO       = m.ID_ALUNO
WHERE au.DT_AULA >= tr.DT_INICIO
  AND (tr.DT_RETORNO_EFETIVA IS NULL OR au.DT_AULA < tr.DT_RETORNO_EFETIVA);

-- A04 — Alguma turma, aula ou graduação está com professor de outra modalidade?
-- Verifica: RE05 (o professor só pode ser alocado a turmas, aulas e avaliações de graduação
--           da modalidade a que está vinculado)
-- Três verificações empilhadas com UNION ALL: o professor responsável pela TURMA, o
-- professor que de fato deu cada AULA e o professor que avaliou cada GRADUACAO.
SELECT 'TURMA'           AS TP_REGISTRO,
       t.ID_TURMA        AS ID_REGISTRO,
       NULL              AS DT_AULA,
       mt.NM_MODALIDADE  AS NM_MODALIDADE_TURMA,
       p.NM_COMPLETO     AS NM_PROFESSOR,
       mp.NM_MODALIDADE  AS NM_MODALIDADE_PROFESSOR
FROM TURMA t
INNER JOIN PROFESSOR p   ON p.ID_PROFESSOR   = t.ID_PROFESSOR
INNER JOIN MODALIDADE mt ON mt.ID_MODALIDADE = t.ID_MODALIDADE
INNER JOIN MODALIDADE mp ON mp.ID_MODALIDADE = p.ID_MODALIDADE
WHERE p.ID_MODALIDADE <> t.ID_MODALIDADE
UNION ALL
SELECT 'AULA', au.ID_AULA, au.DT_AULA, mt.NM_MODALIDADE, p.NM_COMPLETO, mp.NM_MODALIDADE
FROM AULA au
INNER JOIN TURMA t       ON t.ID_TURMA       = au.ID_TURMA
INNER JOIN PROFESSOR p   ON p.ID_PROFESSOR   = au.ID_PROFESSOR
INNER JOIN MODALIDADE mt ON mt.ID_MODALIDADE = t.ID_MODALIDADE
INNER JOIN MODALIDADE mp ON mp.ID_MODALIDADE = p.ID_MODALIDADE
WHERE p.ID_MODALIDADE <> t.ID_MODALIDADE
UNION ALL
SELECT 'GRADUACAO', g.ID_GRADUACAO, g.DT_GRADUACAO, mg.NM_MODALIDADE, p.NM_COMPLETO, mp.NM_MODALIDADE
FROM GRADUACAO g
INNER JOIN PROFESSOR p   ON p.ID_PROFESSOR   = g.ID_PROFESSOR
INNER JOIN MODALIDADE mg ON mg.ID_MODALIDADE = g.ID_MODALIDADE
INNER JOIN MODALIDADE mp ON mp.ID_MODALIDADE = p.ID_MODALIDADE
WHERE p.ID_MODALIDADE <> g.ID_MODALIDADE;

-- A05 — Existe aluno ativo ou trancado sem atestado de aptidão física entregue, ou menor de
--       18 anos sem responsável legal?
-- Verifica: RE03 (o atestado vale para todos os alunos, adultos e menores, e o menor de
--           idade precisa de responsável legal)
-- Não dá para ser CHECK: a idade depende da data de hoje, e o atestado pode ficar em branco
-- até a entrega. Aluno INATIVO não entra, porque já saiu da academia.
-- O LEFT JOIN traz a data da 1ª matrícula, para mostrar há quantos dias o atestado está pendente.
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       a.TP_STATUS_ALUNO,
       TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF)  AS QT_IDADE,
       a.ID_RESPONSAVEL,
       a.DT_ENTREGA_ATESTADO,
       pm.DT_PRIMEIRA_MATRICULA,
       DATEDIFF(@DT_REF, pm.DT_PRIMEIRA_MATRICULA)    AS QT_DIAS_DESDE_MATRICULA,
       CASE WHEN TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF) < 18
                 AND a.ID_RESPONSAVEL IS NULL AND a.DT_ENTREGA_ATESTADO IS NULL
                 THEN 'MENOR SEM RESPONSÁVEL E SEM ATESTADO'
            WHEN TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF) < 18
                 AND a.ID_RESPONSAVEL IS NULL
                 THEN 'MENOR SEM RESPONSÁVEL'
            ELSE 'SEM ATESTADO' END                   AS DS_PENDENCIA
FROM ALUNO a
LEFT JOIN (SELECT ID_ALUNO, MIN(DT_MATRICULA) AS DT_PRIMEIRA_MATRICULA
           FROM MATRICULA
           GROUP BY ID_ALUNO) pm ON pm.ID_ALUNO = a.ID_ALUNO
WHERE a.TP_STATUS_ALUNO <> 'INATIVO'
  AND (   a.DT_ENTREGA_ATESTADO IS NULL
       OR (TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF) < 18 AND a.ID_RESPONSAVEL IS NULL))
ORDER BY pm.DT_PRIMEIRA_MATRICULA, a.ID_ALUNO;

-- A06 — Alguma turma está acima da capacidade ou abaixo do quórum mínimo da modalidade?
-- Verifica: RE01 (máximo de 30 alunos ativos por turma) e RE02 (alerta de quórum mínimo,
--           sem bloquear a aula)
-- HAVING filtra depois da contagem (o WHERE não enxerga o resultado do COUNT).
SELECT t.ID_TURMA,
       mo.NM_MODALIDADE,
       t.DS_DIA_SEMANA,
       t.HR_INICIO,
       COUNT(m.ID_MATRICULA)  AS QT_MATRICULAS_ATIVAS,
       t.QT_CAPACIDADE_MAXIMA,
       mo.QT_MINIMA_REFERENCIA,
       CASE WHEN COUNT(m.ID_MATRICULA) > t.QT_CAPACIDADE_MAXIMA THEN 'ACIMA DA CAPACIDADE (RE01)'
            ELSE 'ABAIXO DO QUÓRUM MÍNIMO' END AS DS_ALERTA
FROM TURMA t
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = t.ID_MODALIDADE
LEFT JOIN MATRICULA m    ON m.ID_TURMA = t.ID_TURMA
                        AND m.TP_SITUACAO_MATRICULA = 'ATIVA'
GROUP BY t.ID_TURMA, mo.NM_MODALIDADE, t.DS_DIA_SEMANA, t.HR_INICIO,
         t.QT_CAPACIDADE_MAXIMA, mo.QT_MINIMA_REFERENCIA
HAVING COUNT(m.ID_MATRICULA) > t.QT_CAPACIDADE_MAXIMA
    OR COUNT(m.ID_MATRICULA) < mo.QT_MINIMA_REFERENCIA
ORDER BY t.ID_TURMA;

-- A07 — Existe parcela com a situação desatualizada (PENDENTE já vencida ou ATRASADO ainda a vencer)?
-- Verifica: RO02 / RE07 (passado o vencimento no 5º dia útil, a parcela deve ficar ATRASADO
--           e o aluno ser bloqueado). Parcela vencida marcada como PENDENTE deixa o
--           inadimplente treinar sem bloqueio.
SELECT pg.ID_PAGAMENTO,
       pg.ID_CONTRATO,
       a.NM_COMPLETO                              AS NM_TITULAR,
       pg.DT_VENCIMENTO,
       pg.TP_STATUS_PAGAMENTO,
       DATEDIFF(@DT_REF, pg.DT_VENCIMENTO)        AS QT_DIAS_DESDE_VENCIMENTO
FROM PAGAMENTO pg
INNER JOIN CONTRATO c ON c.ID_CONTRATO = pg.ID_CONTRATO
INNER JOIN ALUNO a    ON a.ID_ALUNO    = c.ID_ALUNO
WHERE (pg.TP_STATUS_PAGAMENTO = 'PENDENTE' AND pg.DT_VENCIMENTO < @DT_REF)
   OR (pg.TP_STATUS_PAGAMENTO = 'ATRASADO' AND pg.DT_VENCIMENTO >= @DT_REF);

-- A08 — Algum cancelamento descumpriu a regra da multa rescisória?
-- Verifica: RO04 e PN05 (o cancelamento antecipado de plano de mais de 1 mês gera multa,
--           calculada pelos meses que faltam para o fim do ciclo; o plano de 1 mês cancela
--           sem multa)
-- A subconsulta X calcula, para cada cancelamento, os meses completos que faltavam até o fim
-- do ciclo (TIMESTAMPDIFF; GREATEST evita número negativo se o cancelamento for depois do fim)
-- e a multa esperada, com o percentual ilustrativo de 20% sobre a mensalidade (o mesmo do
-- DS_CONDICAO dos planos; o valor real é confidencial). Aponta multa ausente, multa diferente
-- da calculada e multa no plano mensal.
SELECT c.ID_CONTRATO,
       a.NM_COMPLETO              AS NM_TITULAR,
       pl.NM_PLANO,
       c.DT_CANCELAMENTO,
       c.DT_FIM                   AS DT_FIM_CICLO,
       X.QT_MESES_RESTANTES,
       X.VL_MULTA_ESPERADA,
       c.VL_MULTA_RESCISORIA,
       CASE WHEN pl.QT_DURACAO_MESES = 1       THEN 'PLANO MENSAL COM MULTA INDEVIDA'
            WHEN c.VL_MULTA_RESCISORIA IS NULL THEN 'CANCELAMENTO ANTECIPADO SEM MULTA'
            ELSE 'MULTA DIFERENTE DA CALCULADA' END AS DS_INCONSISTENCIA
FROM CONTRATO c
INNER JOIN PLANO pl ON pl.ID_PLANO = c.ID_PLANO
INNER JOIN ALUNO a  ON a.ID_ALUNO  = c.ID_ALUNO
INNER JOIN (SELECT ID_CONTRATO,
                   GREATEST(TIMESTAMPDIFF(MONTH, DT_CANCELAMENTO, DT_FIM), 0) AS QT_MESES_RESTANTES,
                   ROUND(0.20 * (VL_MENSAL_ACORDADO + COALESCE(VL_ACRESCIMO_MODALIDADE, 0))
                         * GREATEST(TIMESTAMPDIFF(MONTH, DT_CANCELAMENTO, DT_FIM), 0), 2) AS VL_MULTA_ESPERADA
            FROM CONTRATO
            WHERE DT_CANCELAMENTO IS NOT NULL) X ON X.ID_CONTRATO = c.ID_CONTRATO
WHERE (pl.QT_DURACAO_MESES = 1 AND c.VL_MULTA_RESCISORIA IS NOT NULL)
   OR (pl.QT_DURACAO_MESES > 1 AND COALESCE(c.VL_MULTA_RESCISORIA, 0) <> X.VL_MULTA_ESPERADA);

-- A09 — A situação dos interessados bate com o cadastro de alunos?
-- Verifica: RO03 (aula experimental: CONVERTIDO deve ter aluno ligado; ENCERRADO ou
--           PENDENTE não podem ter)
SELECT i.ID_INTERESSADO,
       i.NM_INTERESSADO,
       i.TP_STATUS,
       a.ID_ALUNO,
       CASE WHEN a.ID_ALUNO IS NULL THEN 'CONVERTIDO SEM ALUNO CADASTRADO'
            ELSE 'ALUNO LIGADO A INTERESSADO NÃO CONVERTIDO' END AS DS_INCONSISTENCIA
FROM INTERESSADO i
LEFT JOIN ALUNO a ON a.ID_INTERESSADO = i.ID_INTERESSADO
WHERE (i.TP_STATUS = 'CONVERTIDO'  AND a.ID_ALUNO IS NULL)
   OR (i.TP_STATUS <> 'CONVERTIDO' AND a.ID_ALUNO IS NOT NULL);

-- A10 — Alguma parcela foi quitada com valor diferente do devido + multa + taxa de exame?
-- Verifica: RO01 (o desconto é do plano, nunca concedido ao aluno isoladamente); o valor
--           esperado inclui a multa moratória (RO04) e a taxa de exame de faixa (RO06)
SELECT pg.ID_PAGAMENTO,
       pg.ID_CONTRATO,
       a.NM_COMPLETO                                                         AS NM_TITULAR,
       pg.DT_PAGAMENTO,
       pg.VL_DEVIDO,
       COALESCE(pg.VL_MULTA, 0)                                              AS VL_MULTA,
       COALESCE(pg.VL_TAXA_GRADUACAO, 0)                                     AS VL_TAXA_GRADUACAO,
       pg.VL_DEVIDO + COALESCE(pg.VL_MULTA, 0) + COALESCE(pg.VL_TAXA_GRADUACAO, 0) AS VL_ESPERADO,
       pg.VL_PAGO,
       pg.VL_PAGO - (pg.VL_DEVIDO + COALESCE(pg.VL_MULTA, 0) + COALESCE(pg.VL_TAXA_GRADUACAO, 0)) AS VL_DIFERENCA
FROM PAGAMENTO pg
INNER JOIN CONTRATO c ON c.ID_CONTRATO = pg.ID_CONTRATO
INNER JOIN ALUNO a    ON a.ID_ALUNO    = c.ID_ALUNO
WHERE pg.TP_STATUS_PAGAMENTO = 'PAGO'
  AND pg.VL_PAGO <> pg.VL_DEVIDO + COALESCE(pg.VL_MULTA, 0) + COALESCE(pg.VL_TAXA_GRADUACAO, 0);

-- A11 — Algum aluno treina numa modalidade que o contrato vigente dele não cobre?
-- Verifica: RO01 e PN03 (o contrato lista as modalidades cobertas em PARTICIPA; cada
--           modalidade extra entra no mesmo contrato como acréscimo). Matrícula ativa em
--           modalidade fora de PARTICIPA é aula dada sem cobrança.
-- O aluno sem nenhum contrato vigente fica de fora: esse caso é a A01.
-- Vigente na data de referência = já começou e não foi cancelado até ela.
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       m.ID_MATRICULA,
       m.DT_MATRICULA,
       t.ID_TURMA,
       mo.NM_MODALIDADE          AS NM_MODALIDADE_TURMA
FROM MATRICULA m
INNER JOIN ALUNO a       ON a.ID_ALUNO       = m.ID_ALUNO
INNER JOIN TURMA t       ON t.ID_TURMA       = m.ID_TURMA
INNER JOIN MODALIDADE mo ON mo.ID_MODALIDADE = t.ID_MODALIDADE
WHERE m.TP_SITUACAO_MATRICULA = 'ATIVA'
  AND EXISTS (SELECT 1
              FROM CONTRATO c
              WHERE c.ID_ALUNO = m.ID_ALUNO
                AND c.DT_INICIO <= @DT_REF
                AND (c.DT_CANCELAMENTO IS NULL OR c.DT_CANCELAMENTO > @DT_REF))
  AND NOT EXISTS (SELECT 1
                  FROM CONTRATO c
                  INNER JOIN PARTICIPA pa ON pa.ID_CONTRATO = c.ID_CONTRATO
                  WHERE c.ID_ALUNO = m.ID_ALUNO
                    AND c.DT_INICIO <= @DT_REF
                    AND (c.DT_CANCELAMENTO IS NULL OR c.DT_CANCELAMENTO > @DT_REF)
                    AND pa.ID_MODALIDADE = t.ID_MODALIDADE)
ORDER BY a.ID_ALUNO, m.ID_MATRICULA;

-- A12 — Algum aluno tem mais de um contrato vigente?
-- Verifica: RO01, PN02 e PN03 (cada aluno tem um único contrato vigente; no Plano Família,
--           cada familiar tem o seu; modalidade extra é acréscimo nesse contrato, e não um
--           contrato novo). Dois contratos vigentes cobram duas mensalidades cheias do aluno.
-- GROUP_CONCAT junta numa só célula os números dos contratos do aluno.
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       COUNT(*)                                                           AS QT_CONTRATOS_VIGENTES,
       GROUP_CONCAT(c.ID_CONTRATO ORDER BY c.ID_CONTRATO SEPARATOR ', ')  AS DS_CONTRATOS,
       SUM(c.VL_MENSAL_ACORDADO + COALESCE(c.VL_ACRESCIMO_MODALIDADE, 0)) AS VL_MENSAL_COBRADO
FROM CONTRATO c
INNER JOIN ALUNO a ON a.ID_ALUNO = c.ID_ALUNO
WHERE c.DT_INICIO <= @DT_REF
  AND (c.DT_CANCELAMENTO IS NULL OR c.DT_CANCELAMENTO > @DT_REF)
GROUP BY a.ID_ALUNO, a.NM_COMPLETO
HAVING COUNT(*) > 1;

-- A13 — Alguma parcela paga com atraso ficou sem multa num plano de fidelidade, ou teve multa
--       no plano mensal?
-- Verifica: RO04 e PN04 (nos planos Trimestral, Semestral e Anual, inclusive Família, o atraso
--           gera multa além do bloqueio; no Mensal há só o bloqueio, sem multa)
-- A parcela ainda em aberto (ATRASADO) não entra: a multa é lançada na baixa (UPDATE U01).
SELECT pg.ID_PAGAMENTO,
       pg.ID_CONTRATO,
       a.NM_COMPLETO                                  AS NM_TITULAR,
       pl.NM_PLANO,
       pg.DT_VENCIMENTO,
       pg.DT_PAGAMENTO,
       DATEDIFF(pg.DT_PAGAMENTO, pg.DT_VENCIMENTO)    AS QT_DIAS_ATRASO,
       pg.VL_MULTA,
       CASE WHEN pl.QT_DURACAO_MESES > 1 THEN 'PAGA COM ATRASO SEM MULTA'
            ELSE 'MULTA EM PLANO MENSAL' END          AS DS_INCONSISTENCIA
FROM PAGAMENTO pg
INNER JOIN CONTRATO c ON c.ID_CONTRATO = pg.ID_CONTRATO
INNER JOIN PLANO pl   ON pl.ID_PLANO   = c.ID_PLANO
INNER JOIN ALUNO a    ON a.ID_ALUNO    = c.ID_ALUNO
WHERE pg.TP_STATUS_PAGAMENTO = 'PAGO'
  AND (   (pl.QT_DURACAO_MESES > 1 AND pg.DT_PAGAMENTO > pg.DT_VENCIMENTO AND COALESCE(pg.VL_MULTA, 0) = 0)
       OR (pl.QT_DURACAO_MESES = 1 AND COALESCE(pg.VL_MULTA, 0) > 0))
ORDER BY pg.DT_VENCIMENTO, pg.ID_CONTRATO;

-- =====================================================================================
-- FIM DO SCRIPT
-- =====================================================================================
