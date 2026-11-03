-- =====================================================================================
--  SISTEMA DE GESTÃO — ACADEMIA DE ARTES MARCIAIS BASE FORTE LESTE
--  Script completo de implementação física (MySQL 8.0)
-- -------------------------------------------------------------------------------------
--  Disciplina : Modelagem de Banco de Dados — Prof. Cid Rodrigues De Andrade
--  Base       : Modelo Lógico (DER) + Dicionário de Dados v2.3 + Requisitos do Sistema
--  Grupo      : (preencher com os integrantes)
--  SGBD       : MySQL 8.0.16 ou superior (é a versão a partir da qual o CHECK é validado)
--  Motor      : InnoDB (transações e chaves estrangeiras)                        [RNF04]
--  Charset    : utf8mb4 / utf8mb4_unicode_ci (acentos do português)              [RNF04]
-- -------------------------------------------------------------------------------------
--  COMO EXECUTAR
--  Rode o arquivo inteiro de uma vez (no MySQL Workbench: Query > Execute All, ou o
--  raio sem cursor). O script apaga e recria o banco, então pode ser executado
--  várias vezes a partir do zero.
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
--   8. Consultas gerenciais (G01, G02...)
--   9. Consultas de auditoria (A01, A02...)
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
--   Cada bloco do script traz entre colchetes o requisito ou a regra que ele atende:
--   RF = requisito funcional, RNF = requisito não funcional, RO = regra operacional,
--   RE = restrição organizacional e de integridade (numeração do documento de Requisitos).
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
--       ESTRUTURA: PROFESSOR com FK obrigatória para MODALIDADE e VL_POR_AULA (> 0);
--       ESPECIALIZACAO, NIVEL_DE_EXPERIENCIA e REGISTRO_QUALIFICACOES como tabelas de apoio.
--  RF03 Modalidades, turmas e matrículas
--       ESTRUTURA: MODALIDADE (quórum e sistema de faixas), TURMA (dia, horário e
--       capacidade até 30), MATRICULA (histórico: a troca de turma encerra a antiga e cria
--       uma nova). Consultas J01, G05 e A06.
--  RF04 Planos, contratos, mensalidades e despesas
--       ESTRUTURA: PLANO, CONTRATO, PARTICIPA, PAGAMENTO e DESPESA, com CHECKs de valores e
--       de coerência da liquidação. Consultas G01 a G04, G08, G10 e G11; UPDATE U01.
--  RF05 Aulas, reposições e presenças
--       ESTRUTURA: AULA com o professor efetivo e autorrelacionamento ID_AULA_ORIGEM
--       (reposição); PRESENCA com PK composta (sem chamada duplicada). Consultas G07 e G09.
--  RF06 Graduações e trancamentos
--       ESTRUTURA: GRADUACAO (aprovação, reprovação e motivo) e TRANCAMENTO (períodos de
--       afastamento). Consulta J02; UPDATE U02 (retorno que reativa a cobrança e prorroga
--       o contrato).
--
--  REQUISITOS NÃO FUNCIONAIS
--  RNF01 Independência arquitetural e preparo para catraca facial
--       ESTRUTURA: o banco não depende da aplicação (nenhuma trigger ou procedure; todas
--       as regras ficam em constraints e consultas SQL padrão). Chaves substitutas INT
--       (ID_ALUNO) estáveis, que um equipamento futuro pode usar como identificador, e
--       índice IX_PAGAMENTO_VENC_STATUS para a catraca consultar o bloqueio (RE07) na hora.
--       O cadastro biométrico em si fica para uma versão futura (fora do escopo atual).
--  RNF02 Segurança, privacidade e LGPD
--       ESTRUTURA: LOG_ACESSO (quem leu ou alterou CPF e DS_PROBLEMA_SAUDE) com perfis
--       limitados por CHECK; dados de saúde isolados em PROBLEMA_SAUDE_ALUNO e
--       TRANCAMENTO.DS_MOTIVO; DESPESA sem dados bancários (minimização).
--       FORA DO SQL: as permissões por perfil (Administração e Professor) são aplicadas
--       com usuários e GRANT do MySQL na implantação — exemplo comentado na Seção 3.5.
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
--       impedem apagar contratos, pagamentos e despesas que tenham histórico ligado.
--
--  REGRAS OPERACIONAIS
--  RO01 Planos, modalidades extras e Plano Família
--       ESTRUTURA: desconto gravado no PLANO (PC_DESCONTO entre 0 e 100), nunca no aluno;
--       QT_MINIMA_PESSOAS >= 2 no Família; modalidades do contrato em PARTICIPA e
--       acréscimo em CONTRATO.VL_ACRESCIMO_MODALIDADE. AUDITORIA: A10 (desconto dado ao
--       aluno fora do plano). O teto de 4 dependentes é controlado pela aplicação.
--  RO02 Vencimento no 5º dia útil, sem valor proporcional
--       ESTRUTURA: PAGAMENTO.DT_VENCIMENTO obrigatório; a massa usa sempre o 5º dia útil
--       e o valor integral. AUDITORIA: A01 (matrícula sem parcela) e A07 (parcela vencida
--       sem mudar para ATRASADO). O arquivo de operações gera as parcelas do mês.
--  RO03 Uma única aula experimental por pessoa
--       ESTRUTURA: UK_INTERESSADO_PESSOA (NM_INTERESSADO + NR_TELEFONE) recusa o segundo
--       agendamento; situação em ENUM ('PENDENTE','CONVERTIDO','ENCERRADO').
--       AUDITORIA: A09 (situação incoerente com o cadastro de alunos).
--  RO04 Multa rescisória e moratória só nos planos de fidelidade
--       ESTRUTURA: CK_CONTRATO_MULTA (multa rescisória só existe se houve cancelamento) e
--       VL_MULTA (> 0) na parcela. AUDITORIA: A08. UPDATE U01 aplica a multa de 2%.
--  RO05 Assiduidade para exame de faixa
--       ESTRUTURA: PRESENCA guarda a frequência que fundamenta a decisão. A decisão é
--       pedagógica (critério do professor), por isso não é bloqueada pelo banco; a
--       consulta de frequência fica no arquivo de operações e na G09.
--  RO06 Boxe sem faixa e sem taxa de exame
--       ESTRUTURA: MODALIDADE.IN_POSSUI_SISTEMA_FAIXAS e CK_GRADUACAO_FAIXA (exame de
--       faixa exige faixa; análise técnica não pode ter faixa). A taxa de exame entra na
--       parcela (VL_TAXA_GRADUACAO) só para exames de faixa.
--  RO07 Repasse por aula ministrada; instrutor auxiliar sem registro
--       ESTRUTURA: AULA.ID_PROFESSOR registra quem DE FATO deu a aula e DESPESA.ID_PROFESSOR
--       registra o repasse; G07 apura aulas x VL_POR_AULA. Os 5 prestadores recebem; o
--       gestor não. O instrutor auxiliar, por decisão de negócio, não tem tabela.
--
--  RESTRIÇÕES ORGANIZACIONAIS E DE INTEGRIDADE
--  RE01 Máximo de 30 alunos ativos por turma
--       ESTRUTURA: QT_CAPACIDADE_MAXIMA DEFAULT 30 com CK (1 a 30). Contar matrículas
--       ativas exige olhar outras linhas, o que o CHECK não faz: AUDITORIA A06 e, no
--       arquivo de operações, o INSERT de matrícula que só grava se houver vaga.
--  RE02 Quórum mínimo de referência (alerta, sem bloqueio)
--       ESTRUTURA: MODALIDADE.QT_MINIMA_REFERENCIA (> 0). AUDITORIA/ALERTA: A06.
--  RE03 Menor de 18 anos: responsável e atestado
--       ESTRUTURA: FK ALUNO → RESPONSAVEL e coluna DT_ENTREGA_ATESTADO. A idade muda com a
--       data de hoje (CURDATE não é aceito em CHECK): AUDITORIA A05; consulta J03.
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
--  RE07 Bloqueio por inadimplência
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
--  • ENUM nas colunas de situação/tipo com lista fechada de valores (como no DER):
--    o banco recusa qualquer valor fora da lista [RE06].
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
-- VL_POR_AULA é a base do repasse por aula ministrada [RO07].
CREATE TABLE PROFESSOR (
    ID_PROFESSOR     INT            NOT NULL AUTO_INCREMENT,
    ID_MODALIDADE    INT            NOT NULL,                        -- leciona uma única modalidade (RE05)
    CPF              CHAR(11)       NOT NULL,
    NM_COMPLETO      VARCHAR(150)   NOT NULL,
    DT_NASCIMENTO    DATE           NOT NULL,
    VL_POR_AULA      DECIMAL(10,2)  NOT NULL,                        -- base do repasse
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
-- ID_RESPONSAVEL e DT_ENTREGA_ATESTADO aceitam NULL porque só o menor de idade precisa
-- deles; a exigência para o menor é conferida pela auditoria A05 [RE03].
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
    DT_ENTREGA_ATESTADO     DATE          NULL,                       -- exigido do menor de 18 anos
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
-- a leitura e registrar cada acesso em LOG_ACESSO. Sem problema de saúde, registra-se 'nenhum'.
CREATE TABLE PROBLEMA_SAUDE_ALUNO (
    DS_PROBLEMA_SAUDE  VARCHAR(200) NOT NULL,
    ID_ALUNO           INT          NOT NULL,
    CONSTRAINT PK_PROBLEMA_SAUDE_ALUNO PRIMARY KEY (DS_PROBLEMA_SAUDE, ID_ALUNO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.6 TURMA — dia e horário fixos de uma modalidade                     [RF03, RE01, RE05]
-- -------------------------------------------------------------------------------------
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
-- aula esta reposição substitui [RF05].
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
-- É a fonte da frequência usada para liberar o exame de faixa [RO05]. Aluno bloqueado
-- ou trancado não recebe linha de presença [RE07, RE04].
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
-- 2.12 CONTRATO — acordo do aluno titular com a academia                [RF04, RO01, RO04, RE04]
-- -------------------------------------------------------------------------------------
-- VL_MENSAL_ACORDADO é congelado: reajuste no PLANO não muda contratos já firmados.
-- VL_ACRESCIMO_MODALIDADE cobra as modalidades extras [RO01].
-- VL_MULTA_RESCISORIA só existe no cancelamento antecipado de plano de fidelidade [RO04].
-- DT_FIM é prorrogado pelo tempo de trancamento [RE04].
CREATE TABLE CONTRATO (
    ID_CONTRATO               INT            NOT NULL AUTO_INCREMENT,
    ID_ALUNO                  INT            NOT NULL,               -- titular (responsável financeiro)
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
-- Uma linha por mês, sempre com vencimento no 5º dia útil e valor integral [RO02].
-- VL_MULTA = multa moratória dos planos de fidelidade [RO04].
-- VL_TAXA_GRADUACAO = taxa do exame de faixa, cobrada junto da mensalidade [RO06].
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
    VL_TAXA_GRADUACAO      DECIMAL(10,2)  NULL,                      -- taxa do exame de faixa
    TP_STATUS_PAGAMENTO    ENUM('PAGO','ATRASADO','PENDENTE') NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT PK_PAGAMENTO PRIMARY KEY (ID_PAGAMENTO)
) ENGINE = InnoDB;

-- -------------------------------------------------------------------------------------
-- 2.15 GRADUACAO — exame de faixa ou análise técnica                    [RF06, RO05, RO06, RE05]
-- -------------------------------------------------------------------------------------
-- TP_AVALIACAO separa exame de faixa e análise técnica do Boxe; TP_NIVEL_FAIXA fica
-- vazio na análise técnica [RO06]. A reprovação fica no histórico com o motivo [RF06].
CREATE TABLE GRADUACAO (
    ID_GRADUACAO           INT           NOT NULL AUTO_INCREMENT,
    ID_ALUNO               INT           NOT NULL,
    ID_PROFESSOR           INT           NOT NULL,                   -- quem avaliou
    ID_MODALIDADE          INT           NOT NULL,
    DS_MOTIVO_REPROVACAO   VARCHAR(100)  NULL,                       -- palavras-chave, só na reprovação
    DT_GRADUACAO           DATE          NOT NULL,
    TP_NIVEL_FAIXA         VARCHAR(30)   NULL,                       -- vazio na análise técnica
    TP_AVALIACAO           VARCHAR(20)   NOT NULL,                   -- EXAME_FAIXA ou ANALISE_TECNICA
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
-- copiar o dado sensível para o log (só o ID do registro e o nome do campo).
-- Sem FK em ID_REGISTRO de propósito: ele aponta para tabelas diferentes conforme
-- NM_TABELA, e o log precisa continuar existindo mesmo depois que o registro é excluído.
CREATE TABLE LOG_ACESSO (
    ID_LOG         INT          NOT NULL AUTO_INCREMENT,
    NM_USUARIO     VARCHAR(50)  NOT NULL,
    TP_PERFIL      VARCHAR(20)  NOT NULL,
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
--   3.4 CHECK — regras de valor (dinheiro positivo, datas coerentes, formatos)
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
--    ser da modalidade da turma" [RE05] e "no máximo 30 matrículas ativas" [RE01] também
--    viram auditoria (A04 e A06).
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

-- [RF02, RO07] Valor por aula positivo: base do repasse
ALTER TABLE PROFESSOR
    ADD CONSTRAINT CK_PROFESSOR_CPF         CHECK (CPF REGEXP '^[0-9]{11}$'),
    ADD CONSTRAINT CK_PROFESSOR_CEP         CHECK (NR_CEP REGEXP '^[0-9]{8}$'),
    ADD CONSTRAINT CK_PROFESSOR_NASCIMENTO  CHECK (DT_NASCIMENTO >= '1920-01-01'),
    ADD CONSTRAINT CK_PROFESSOR_VL_POR_AULA CHECK (VL_POR_AULA > 0);

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

-- [RO01] Ciclos comercializados (1, 3, 6 e 12 meses), valores positivos, desconto entre
-- 0% e 100% e Plano Família a partir de 2 pessoas
ALTER TABLE PLANO
    ADD CONSTRAINT CK_PLANO_DURACAO       CHECK (QT_DURACAO_MESES IN (1, 3, 6, 12)),
    ADD CONSTRAINT CK_PLANO_VL_MENSALIDADE CHECK (VL_MENSALIDADE > 0),
    ADD CONSTRAINT CK_PLANO_PC_DESCONTO   CHECK (PC_DESCONTO BETWEEN 0 AND 100),
    ADD CONSTRAINT CK_PLANO_QT_PESSOAS    CHECK (QT_MINIMA_PESSOAS IS NULL OR QT_MINIMA_PESSOAS >= 2);

-- [RF04, RO01, RO04] Vigência coerente, valores positivos e multa rescisória só quando
-- houve cancelamento
ALTER TABLE CONTRATO
    ADD CONSTRAINT CK_CONTRATO_VIGENCIA     CHECK (DT_FIM > DT_INICIO),
    ADD CONSTRAINT CK_CONTRATO_VL_MENSAL    CHECK (VL_MENSAL_ACORDADO > 0),
    ADD CONSTRAINT CK_CONTRATO_VL_ACRESCIMO CHECK (VL_ACRESCIMO_MODALIDADE IS NULL OR VL_ACRESCIMO_MODALIDADE > 0),
    ADD CONSTRAINT CK_CONTRATO_CANCELAMENTO CHECK (DT_CANCELAMENTO IS NULL OR DT_CANCELAMENTO >= DT_INICIO),
    ADD CONSTRAINT CK_CONTRATO_MULTA        CHECK (VL_MULTA_RESCISORIA IS NULL
                                                   OR (VL_MULTA_RESCISORIA > 0 AND DT_CANCELAMENTO IS NOT NULL));

-- [RF04, RO04, RO06, RE07] Valores positivos e coerência entre a situação e os dados da
-- liquidação: parcela PAGO precisa ter data, valor e forma; parcela não paga não pode
-- ter nenhum deles. Assim a situação usada no bloqueio (RE07) nunca contradiz os valores.
ALTER TABLE PAGAMENTO
    ADD CONSTRAINT CK_PAGAMENTO_VL_DEVIDO CHECK (VL_DEVIDO > 0),
    ADD CONSTRAINT CK_PAGAMENTO_VL_PAGO   CHECK (VL_PAGO IS NULL OR VL_PAGO > 0),
    ADD CONSTRAINT CK_PAGAMENTO_VL_MULTA  CHECK (VL_MULTA IS NULL OR VL_MULTA > 0),
    ADD CONSTRAINT CK_PAGAMENTO_VL_TAXA   CHECK (VL_TAXA_GRADUACAO IS NULL OR VL_TAXA_GRADUACAO > 0),
    ADD CONSTRAINT CK_PAGAMENTO_LIQUIDACAO CHECK (
           (TP_STATUS_PAGAMENTO = 'PAGO'
              AND DT_PAGAMENTO IS NOT NULL AND VL_PAGO IS NOT NULL AND TP_FORMA_PAGAMENTO IS NOT NULL)
        OR (TP_STATUS_PAGAMENTO <> 'PAGO'
              AND DT_PAGAMENTO IS NULL AND VL_PAGO IS NULL AND TP_FORMA_PAGAMENTO IS NULL));

-- [RF06, RO06] Faixa só no exame de faixa (o Boxe tem análise técnica, sem faixa) e
-- motivo só na reprovação
ALTER TABLE GRADUACAO
    ADD CONSTRAINT CK_GRADUACAO_TP_AVALIACAO CHECK (TP_AVALIACAO IN ('EXAME_FAIXA','ANALISE_TECNICA')),
    ADD CONSTRAINT CK_GRADUACAO_FAIXA CHECK (
           (TP_AVALIACAO = 'EXAME_FAIXA'     AND TP_NIVEL_FAIXA IS NOT NULL)
        OR (TP_AVALIACAO = 'ANALISE_TECNICA' AND TP_NIVEL_FAIXA IS NULL)),
    ADD CONSTRAINT CK_GRADUACAO_MOTIVO CHECK (
           (TP_RESULTADO = 'REPROVADO' AND DS_MOTIVO_REPROVACAO IS NOT NULL)
        OR (TP_RESULTADO = 'APROVADO'  AND DS_MOTIVO_REPROVACAO IS NULL));

-- [RF04, RO07] Categorias de despesa, valores positivos e coerência da liquidação
ALTER TABLE DESPESA
    ADD CONSTRAINT CK_DESPESA_CATEGORIA CHECK (DS_CATEGORIA IN
        ('ALUGUEL','CONSUMO','MANUTENCAO','COMPRAS','PROFESSORES')),
    ADD CONSTRAINT CK_DESPESA_VL_DESPESA CHECK (VL_DESPESA > 0),
    ADD CONSTRAINT CK_DESPESA_VL_PAGO    CHECK (VL_PAGO IS NULL OR VL_PAGO > 0),
    ADD CONSTRAINT CK_DESPESA_LIQUIDACAO CHECK (
           (TP_SITUACAO_DESPESA = 'PAGO'  AND DT_PAGAMENTO IS NOT NULL AND VL_PAGO IS NOT NULL)
        OR (TP_SITUACAO_DESPESA <> 'PAGO' AND DT_PAGAMENTO IS NULL     AND VL_PAGO IS NULL));

-- [RNF02] Só os dois perfis de acesso previstos podem aparecer no log
ALTER TABLE LOG_ACESSO
    ADD CONSTRAINT CK_LOG_ACESSO_PERFIL CHECK (TP_PERFIL IN ('ADMINISTRACAO','PROFESSOR'));

-- -------------------------------------------------------------------------------------
-- 3.5 PERFIS DE ACESSO (exemplo comentado — aplicado na implantação)    [RNF02]
-- -------------------------------------------------------------------------------------
-- O controle de acesso por perfil é feito com usuários do MySQL e GRANT. Fica comentado
-- porque criar usuários exige privilégio de administrador do servidor e senhas reais.
--
--   CREATE USER 'administracao'@'%' IDENTIFIED BY '<senha forte>';
--   GRANT SELECT, INSERT, UPDATE, DELETE ON ACADEMIA_BFL.* TO 'administracao'@'%';
--
--   CREATE USER 'professor'@'%' IDENTIFIED BY '<senha forte>';
--   GRANT SELECT ON ACADEMIA_BFL.TURMA     TO 'professor'@'%';
--   GRANT SELECT ON ACADEMIA_BFL.MATRICULA TO 'professor'@'%';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.AULA        TO 'professor'@'%';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.PRESENCA    TO 'professor'@'%';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.GRADUACAO   TO 'professor'@'%';
--   GRANT SELECT, INSERT, UPDATE ON ACADEMIA_BFL.INTERESSADO TO 'professor'@'%';
--   -- sem acesso a CONTRATO, PAGAMENTO, DESPESA e RESPONSAVEL (dicionário, Seção 5)


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
-- fixo: tabelas de domínio têm o tamanho real (6 modalidades, 18 turmas) e as tabelas de
-- movimento cobrem um período curto e completo (ago a nov/2026), o suficiente para as
-- consultas por mês terem o que comparar sem inflar o banco artificialmente.
--
--   Tabela                Qtde  Justificativa
--   MODALIDADE               6  6 artes marciais ativas (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira, No-Gi)
--   PROFESSOR                6  1 gestor que dá aula de Muay Thai + 5 professores terceirizados
--   TURMA                   18  18 turmas regulares de segunda a sábado (grade semanal informada)
--   PLANO                    8  4 ciclos (mensal, trimestral, semestral, anual) x versão individual e Família
--   ALUNO                   92  faixa de 80 a 100 alunos; 83 ativos + inativos e trancados
--   RESPONSAVEL             11  14 alunos menores; irmãos dividem o mesmo responsável
--   CONTRATO                83  77 vigentes (faixa de 70 a 85) + 6 cancelados; menos contratos
--                               que alunos porque 8 dependentes estão no contrato do titular (Plano Família)
--   PARTICIPA              100  cada contrato cobre 1 modalidade; alguns têm modalidade extra
--   MATRICULA              190  aluno treina em 1 a 3 turmas da modalidade (média de 10 ativos por
--                               turma, a maioria acima do quórum mínimo, como no levantamento) + histórico
--   TRANCAMENTO              6  afastamentos por lesão/razão médica ao longo de 2026
--   PAGAMENTO              293  70 a 85 faturas por mês x 4 meses (ago, set, out e nov/2026)
--   INTERESSADO             24  2 a 4 aulas experimentais por semana (8 a 16 por mês) x ~2 meses
--   AULA                    74  18 turmas x ~4 semanas de outubro (menos o feriado de 12/10) + 1 reposição
--   PRESENCA               654  uma linha por matrícula ativa em cada aula de outubro
--   GRADUACAO               28  exames de faixa trimestrais (dez/2025 a out/2026) + análises de Boxe
--   DESPESA                 50  fixas mensais + compras semanais de limpeza + repasse a 5 professores
--   LOG_ACESSO              20  amostra de 1 mês de acessos a dados pessoais
--   EMAIL_ALUNO            100  pelo menos 1 por aluno (1,n)
--   TELEFONE_ALUNO         123  pelo menos 1 por aluno; menores com o telefone do responsável
--   PROBLEMA_SAUDE_ALUNO    94  pelo menos 1 por aluno ('nenhum' quando não há)
--   Apoio do professor      50  e-mails, telefones, especializações, níveis e qualificações (1,n)
--   TOTAL                 2030  registros
--
-- VARIEDADE PARA OS TESTES (situações reais, não só o caso comum)
--   • Alunos ATIVO, INATIVO (contrato cancelado) e TRANCADO; menores com responsável;
--     dependentes de Plano Família; alunos que vieram da aula experimental.
--   • Contratos de todos os planos, com e sem modalidade extra; cancelamentos com e sem
--     multa; um plano (Família Anual) sem nenhuma venda.
--   • Parcelas pagas em dia, pagas com atraso (com multa nos planos longos), em atraso,
--     a vencer, pagas antecipadamente, parcelas de adesão e com taxa de exame de faixa;
--     pagamentos por Pix, crédito e débito; um contrato cancelado deixando dívida.
--   • Matrículas ATIVA, TRANCADA, ENCERRADA (troca de turma) e CANCELADA; uma turma
--     recém-aberta sem alunos e turmas abaixo do quórum.
--   • Aulas com substituição de professor e com reposição; alunos com frequência baixa.
--   • Graduações aprovadas e reprovadas, exame de faixa e análise técnica (Boxe).
--   • Interessados convertidos, desistentes e pendentes; despesas pagas, a vencer e atrasada.
--
-- CASOS PROPOSITAIS PARA AS CONSULTAS DE AUDITORIA (Seção 9)
-- São erros que acontecem na rotina e que nenhuma constraint consegue barrar. Estão
-- descritos no cabeçalho de cada tabela abaixo:
--   A01 aluno matriculado sem contrato (RO02)      A06 turma abaixo do quórum (RE02)
--   A02 presença de aluno bloqueado (RE07)         A07 parcela vencida ainda PENDENTE (RE07)
--   A03 presença durante trancamento (RE04)        A08 cancelamento sem multa (RO04)
--   A04 aula com professor de outra mod. (RE05)    A09 convertido sem aluno (RO03)
--   A05 menor sem atestado (RE03)                  A10 desconto de balcão (RO01)
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
-- O professor 1 representa o gestor (CEO), que também dá as aulas de Muay Thai;
-- os outros 5 são prestadores de serviço. Todos recebem o mesmo valor por aula.
-- Nomes, CPFs, telefones e endereços são fictícios.
-- -------------------------------------------------------------------------------------
INSERT INTO PROFESSOR (ID_PROFESSOR, ID_MODALIDADE, CPF, NM_COMPLETO, DT_NASCIMENTO, VL_POR_AULA, NR_CEP, DS_RUA, NR_LOGRADOURO, NM_BAIRRO) VALUES
    (1, 1, '63074003192', 'Lucas Batista Gomes', '1979-04-18', 80.00, '08230935', 'Rua das Acácias', '533', 'Cangaíba'),
    (2, 2, '94825696908', 'Carolina Nunes Carvalho', '1988-09-02', 80.00, '08082932', 'Rua Tangará', '842', 'Vila Carrão'),
    (3, 3, '53240316759', 'Fábio Macedo Freitas', '1985-01-27', 80.00, '08765458', 'Rua das Camélias', '232', 'Guaianases'),
    (4, 4, '80480851817', 'Jonas Mendes Nunes', '1990-06-11', 80.00, '08700062', 'Avenida dos Jasmins', '1522', 'Vila Matilde'),
    (5, 5, '66651861008', 'Igor Machado Cardoso', '1983-11-30', 80.00, '03099465', 'Avenida Cerejeira', '487', 'Água Rasa'),
    (6, 6, '87843089050', 'Gabriela Vieira Rodrigues', '1994-03-08', 80.00, '08826508', 'Rua das Acácias', '1850', 'Vila Matilde');

INSERT INTO EMAIL_PROFESSOR (DS_EMAIL, ID_PROFESSOR) VALUES
    ('lucas.gomes@example.com', 1),
    ('lucas.gomes.prof@example.com', 1),
    ('carolina.carvalho@example.com', 2),
    ('fabio.freitas@example.com', 3),
    ('fabio.freitas.prof@example.com', 3),
    ('jonas.nunes@example.com', 4),
    ('igor.cardoso@example.com', 5),
    ('gabriela.rodrigues@example.com', 6);

INSERT INTO TELEFONE_PROFESSOR (NR_TELEFONE, ID_PROFESSOR) VALUES
    ('11932271681', 1),
    ('1125920472', 1),
    ('11943804605', 2),
    ('11955885616', 3),
    ('11961558957', 4),
    ('11961886490', 5),
    ('1122243241', 5),
    ('11941980860', 6);

INSERT INTO ESPECIALIZACAO (DS_ESPECIALIZACAO, ID_PROFESSOR) VALUES
    ('Muay Thai', 1),
    ('Kickboxing', 1),
    ('Defesa pessoal', 1),
    ('Kickboxing', 2),
    ('Condicionamento físico', 2),
    ('Jiu-Jitsu', 3),
    ('No-Gi', 3),
    ('Jiu-Jitsu infantil', 3),
    ('Boxe', 4),
    ('Preparação física', 4),
    ('Capoeira Angola', 5),
    ('Capoeira Regional', 5),
    ('Capoeira infantil', 5),
    ('No-Gi', 6),
    ('Jiu-Jitsu', 6),
    ('Wrestling', 6);

INSERT INTO NIVEL_DE_EXPERIENCIA (DS_NIVEL_EXPERIENCIA, ID_PROFESSOR) VALUES
    ('Kru - Prajied Preto', 1),
    ('22 anos de prática', 1),
    ('Faixa preta 2º dan', 2),
    ('Faixa preta 3º grau', 3),
    ('Ex-atleta amador - 15 anos de treino', 4),
    ('Contramestre', 5),
    ('Faixa marrom de Jiu-Jitsu', 6);

INSERT INTO REGISTRO_QUALIFICACOES (DS_REGISTRO_QUALIFICACOES, ID_PROFESSOR) VALUES
    ('Curso de arbitragem de Muay Thai pela federação estadual (2016)', 1),
    ('Curso de primeiros socorros (2025)', 1),
    ('Graduada em Educação Física (2011)', 2),
    ('Atleta de competições estaduais de 2008 a 2016', 2),
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
-- Nos contratos do Plano Família, o responsável é o próprio titular do contrato, que também é aluno:
-- por isso o CPF do responsável é igual ao CPF do aluno titular. É esse CPF que liga o dependente
-- ao contrato da família na consulta de auditoria A01.
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
-- CONVERTIDO = virou aluno | ENCERRADO = desistiu | PENDENTE = ainda vai decidir ou a aula já está agendada.
-- Cenário de auditoria: o interessado 19 está CONVERTIDO, mas não tem aluno vinculado (A09).
-- -------------------------------------------------------------------------------------
INSERT INTO INTERESSADO (ID_INTERESSADO, ID_MODALIDADE, NM_INTERESSADO, TP_STATUS, NR_TELEFONE, DT_AULA, HR_AULA) VALUES
    (1, 4, 'Daniel Vieira Queiroz', 'CONVERTIDO', '11951341935', '2026-09-01', '18:00:00'),
    (2, 5, 'Beatriz Ferreira Almeida', 'ENCERRADO', '11988983743', '2026-09-02', '15:00:00'),
    (3, 4, 'Carolina Freitas Machado', 'CONVERTIDO', '11904838041', '2026-09-08', '18:00:00'),
    (4, 5, 'Tatiane Mendes Dias', 'CONVERTIDO', '11933669288', '2026-09-19', '14:00:00'),
    (5, 1, 'Samuel Campos Macedo', 'ENCERRADO', '11977770387', '2026-09-21', '07:00:00'),
    (6, 6, 'Vitor Araújo Lima', 'ENCERRADO', '11934099404', '2026-09-24', '20:00:00'),
    (7, 2, 'Priscila Macedo Oliveira', 'ENCERRADO', '11951863907', '2026-09-25', '18:00:00'),
    (8, 1, 'Eduardo Pereira Rodrigues', 'CONVERTIDO', '11983541274', '2026-09-26', '09:00:00'),
    (9, 4, 'Viviane Oliveira Costa', 'ENCERRADO', '11902641388', '2026-10-01', '18:00:00'),
    (10, 6, 'Fernanda Brandão Rodrigues', 'CONVERTIDO', '11977475313', '2026-10-01', '20:00:00'),
    (11, 3, 'Aline Campos Tavares', 'CONVERTIDO', '11937219453', '2026-10-02', '19:30:00'),
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
-- 14 alunos são menores de idade e têm responsável; 8 deles são dependentes de um Plano Família.
-- 10 alunos vieram da aula experimental (ID_INTERESSADO preenchido).
-- Cenários de auditoria: aluno 53 é menor e ainda não entregou o atestado (A05);
-- aluno 92 foi matriculado em 28/10 sem contrato (A01).
-- Os dependentes usam o telefone e o e-mail do responsável: a PK composta (valor + ID_ALUNO)
-- permite o mesmo telefone em alunos diferentes, mas não repetido no mesmo aluno.
-- -------------------------------------------------------------------------------------
INSERT INTO ALUNO (ID_ALUNO, ID_RESPONSAVEL, ID_INTERESSADO, DT_AUTORIZACAO_IMAGEM, CPF, NM_COMPLETO, DT_NASCIMENTO, DS_HISTORICO_TREINO, IN_ACEITE_USO_IMAGEM, TP_STATUS_ALUNO, DT_ENTREGA_ATESTADO, NR_CEP, NR_LOGRADOURO, DS_RUA, NM_BAIRRO) VALUES
    (1, NULL, NULL, '2024-04-03', '20742934398', 'Beatriz Barbosa Ramos', '2001-09-26', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', NULL, '03284345', '609', 'Rua Manacá', 'Ermelino Matarazzo'),
    (2, NULL, NULL, '2024-06-07', '77697705354', 'Larissa Freitas Brandão', '1976-02-25', 'Ex-praticante de karatê (faixa verde).', TRUE, 'ATIVO', NULL, '03180113', '161', 'Rua Manacá', 'Itaquera'),
    (3, NULL, NULL, '2024-07-12', '71832122578', 'Ricardo Silva Moura', '1972-09-10', 'Fez capoeira na escola por 3 anos.', FALSE, 'ATIVO', NULL, '08621794', '698', 'Avenida dos Jasmins', 'Vila Formosa'),
    (4, NULL, NULL, '2024-08-05', '67759336244', 'Renato Lopes Mendes', '1990-07-02', 'Nunca treinou; procurou a academia para defesa pessoal.', FALSE, 'ATIVO', NULL, '03099660', '1131', 'Rua Quaresmeira', 'Aricanduva'),
    (5, NULL, NULL, '2024-10-04', '90322409849', 'Gabriela Santos Carvalho', '1988-10-09', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', NULL, '08074437', '499', 'Rua Manacá', 'Vila Matilde'),
    (6, NULL, NULL, '2024-10-25', '56691475866', 'Daniela Correia Costa', '2002-04-22', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', NULL, '08395582', '776', 'Rua Beija-flor', 'Penha'),
    (7, NULL, NULL, '2024-11-12', '89890624959', 'Murilo Barbosa Costa', '1994-08-30', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', NULL, '03401683', '988', 'Rua das Violetas', 'Cidade Patriarca'),
    (8, NULL, NULL, '2024-11-24', '65743830410', 'Lucas Ferreira Cavalcanti', '1989-06-26', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', NULL, '08778837', '330', 'Rua Jequitibá', 'Guaianases'),
    (9, NULL, NULL, '2024-11-28', '83043033911', 'Vinícius Lopes Almeida', '1974-09-18', 'Faixa azul de Jiu-Jitsu em outra academia; parado há 2 anos.', TRUE, 'ATIVO', NULL, '08232031', '116', 'Rua Beija-flor', 'Água Rasa'),
    (10, NULL, NULL, '2024-12-16', '99538026517', 'Murilo Vieira Ramos', '1992-03-17', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', NULL, '08631085', '211', 'Rua Beija-flor', 'Cidade Patriarca'),
    (11, NULL, NULL, '2024-12-20', '21576968933', 'Larissa Cardoso Queiroz', '1999-06-14', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '03140389', '892', 'Travessa das Orquídeas', 'Água Rasa'),
    (12, NULL, NULL, '2024-12-22', '49813312204', 'Camila Lima Vieira', '1992-05-01', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', NULL, '08804282', '1229', 'Avenida Cerejeira', 'Aricanduva'),
    (13, NULL, NULL, '2025-01-02', '94879025344', 'Bruno Cardoso Moura', '1993-02-24', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', NULL, '08638769', '386', 'Rua dos Cravos', 'Vila Carrão'),
    (14, NULL, NULL, '2025-01-02', '19252676324', 'Carolina Souza Costa', '1978-07-03', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '03272120', '103', 'Rua Sete Copas', 'Vila Formosa'),
    (15, NULL, NULL, '2025-01-07', '14357742595', 'Gabriela Costa Queiroz', '1982-03-05', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'TRANCADO', NULL, '08171580', '1794', 'Rua Tangará', 'Itaquera'),
    (16, NULL, NULL, '2025-02-19', '05832381199', 'Vanessa Macedo Cardoso', '1992-09-18', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'TRANCADO', NULL, '03874942', '1620', 'Rua Tangará', 'Aricanduva'),
    (17, NULL, NULL, '2025-02-21', '07250193934', 'Sérgio Batista Mendes', '1999-01-18', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', NULL, '08160293', '1902', 'Rua Aroeira', 'Itaquera'),
    (18, NULL, NULL, '2025-03-10', '32218340669', 'Leonardo Queiroz Gomes', '1983-10-23', 'Ex-praticante de karatê (faixa verde).', TRUE, 'ATIVO', NULL, '03476245', '576', 'Rua das Acácias', 'Artur Alvim'),
    (19, 1, NULL, '2025-03-10', '82432854564', 'Benício Vieira Gomes', '2017-03-20', 'Fez natação por 1 ano.', TRUE, 'ATIVO', '2025-03-05', '03978393', '585', 'Avenida Cerejeira', 'Guaianases'),
    (20, 1, NULL, '2025-03-10', '58293739055', 'Valentina Cardoso Gomes', '2012-10-16', 'Joga futsal na escola.', TRUE, 'ATIVO', '2025-03-05', '03432813', '1502', 'Rua Beija-flor', 'Água Rasa'),
    (21, NULL, NULL, '2025-03-13', '29006094815', 'Rodrigo Correia Campos', '1977-11-13', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', NULL, '08536473', '928', 'Travessa das Orquídeas', 'São Mateus'),
    (22, NULL, NULL, '2025-04-11', '62139568619', 'Leonardo Souza Nascimento', '1996-09-07', 'Nunca praticou artes marciais; sedentário há 3 anos.', FALSE, 'ATIVO', NULL, '08896891', '784', 'Rua das Violetas', 'Vila Formosa'),
    (23, NULL, NULL, '2025-04-12', '75946200856', 'Raquel Santos Queiroz', '2001-11-14', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', NULL, '08261040', '656', 'Rua das Camélias', 'Cangaíba'),
    (24, 2, NULL, '2025-04-14', '97979078018', 'Eduardo Batista Pereira', '2009-03-30', 'Nunca treinou; procurou a academia para defesa pessoal.', FALSE, 'ATIVO', '2025-04-12', '08193521', '174', 'Avenida dos Jasmins', 'Ermelino Matarazzo'),
    (25, NULL, NULL, '2025-04-16', '36281572472', 'Jonas Ramos Campos', '2003-05-18', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', NULL, '03206961', '1498', 'Rua Flamboyant', 'Penha'),
    (26, 3, NULL, '2025-04-30', '95071296745', 'Bernardo Queiroz Rocha', '2014-05-04', 'Nunca praticou esportes.', FALSE, 'ATIVO', '2025-04-24', '08231001', '213', 'Rua Quaresmeira', 'Tatuapé'),
    (27, NULL, NULL, '2025-05-26', '53222719855', 'Jéssica Nunes Moura', '1983-07-13', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', NULL, '03639796', '667', 'Avenida dos Jasmins', 'Penha'),
    (28, NULL, NULL, '2025-06-02', '40109147169', 'Ricardo Macedo Pinto', '1980-12-13', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'INATIVO', NULL, '03925842', '525', 'Avenida dos Jasmins', 'Belém'),
    (29, NULL, NULL, '2025-06-14', '09148600678', 'Vanessa Mendes Ramos', '1975-10-14', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', NULL, '08321884', '1387', 'Rua Aroeira', 'Vila Formosa'),
    (30, NULL, NULL, '2025-06-21', '19880436819', 'Sabrina Lopes Oliveira', '1983-10-29', 'Pratica musculação há 4 anos; nunca treinou luta.', TRUE, 'ATIVO', NULL, '08454309', '1402', 'Rua das Violetas', 'Vila Matilde'),
    (31, NULL, NULL, '2025-06-23', '57237053368', 'Rafael Barbosa Silva', '1985-04-07', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', NULL, '03096911', '1313', 'Rua Quaresmeira', 'São Mateus'),
    (32, NULL, NULL, '2025-07-13', '63210126128', 'Thiago Siqueira Correia', '1979-12-09', 'Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'ATIVO', NULL, '03044756', '56', 'Rua Quaresmeira', 'Artur Alvim'),
    (33, NULL, NULL, '2025-07-22', '11859434457', 'André Araújo Nunes', '1979-04-27', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', NULL, '03492733', '541', 'Rua Tangará', 'Tatuapé'),
    (34, NULL, NULL, '2025-07-22', '84078500787', 'Ana Ribeiro Araújo', '1992-09-17', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', NULL, '03772820', '1863', 'Rua Aroeira', 'Cangaíba'),
    (35, NULL, NULL, '2025-07-28', '90985631482', 'Matheus Farias Lima', '2005-02-24', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '08907684', '1394', 'Rua das Camélias', 'Aricanduva'),
    (36, NULL, NULL, '2025-08-04', '00552788823', 'Vitor Cavalcanti Farias', '1984-01-13', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', NULL, '08822463', '619', 'Travessa das Orquídeas', 'Penha'),
    (37, 4, NULL, '2025-08-04', '62201523499', 'Lorenzo Teixeira Farias', '2015-05-16', 'Joga futsal na escola.', TRUE, 'ATIVO', '2025-08-03', '08215779', '607', 'Rua Flamboyant', 'Penha'),
    (38, 4, NULL, '2025-08-04', '15430338779', 'Miguel Cavalcanti Farias', '2013-10-13', 'Primeira atividade esportiva.', TRUE, 'ATIVO', '2025-08-02', '03192858', '1282', 'Rua Flamboyant', 'Penha'),
    (39, NULL, NULL, '2025-08-16', '52280478891', 'Cláudia Moreira Ramos', '2003-03-31', 'Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', NULL, '08334010', '61', 'Rua das Acácias', 'Vila Matilde'),
    (40, NULL, NULL, '2025-09-01', '63243278213', 'Hugo Cavalcanti Barbosa', '1974-11-06', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', NULL, '03801196', '1166', 'Rua Flamboyant', 'Água Rasa'),
    (41, NULL, NULL, '2025-09-18', '65886174949', 'Renato Teixeira Tavares', '1976-01-22', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', NULL, '03291422', '505', 'Rua Aroeira', 'Tatuapé'),
    (42, NULL, NULL, '2025-10-10', '95671357822', 'Gabriel Nunes Gomes', '2003-01-17', 'Ex-praticante de karatê (faixa verde).', TRUE, 'ATIVO', NULL, '08878690', '227', 'Rua Sete Copas', 'Itaquera'),
    (43, NULL, NULL, '2025-10-12', '69252669706', 'Sabrina Macedo Pinto', '2005-11-30', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', NULL, '08607924', '1881', 'Rua Manacá', 'Ermelino Matarazzo'),
    (44, NULL, NULL, '2025-10-23', '56663382128', 'Larissa Queiroz Lopes', '1978-11-07', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', NULL, '03834950', '1495', 'Rua Pau-Brasil', 'Vila Esperança'),
    (45, NULL, NULL, '2025-11-03', '17368456956', 'Camila Almeida Freitas', '1989-03-18', 'Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'INATIVO', NULL, '08689054', '1342', 'Rua Beija-flor', 'Penha'),
    (46, NULL, NULL, '2025-12-05', '35670349312', 'Samuel Rocha Oliveira', '1973-07-31', 'Fez capoeira na escola por 3 anos.', FALSE, 'ATIVO', NULL, '03381173', '1241', 'Rua Ipê Roxo', 'Artur Alvim'),
    (47, NULL, NULL, '2025-12-10', '14183037366', 'Isabela Almeida Vieira', '2004-04-10', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', NULL, '08879837', '1815', 'Rua Pau-Brasil', 'Água Rasa'),
    (48, NULL, NULL, '2025-12-16', '73316445888', 'Elaine Monteiro Queiroz', '1977-04-10', 'Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', NULL, '03750030', '1707', 'Rua Jequitibá', 'Vila Esperança'),
    (49, NULL, NULL, '2025-12-30', '43274914905', 'Carolina Vieira Pereira', '1991-05-16', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', NULL, '03522033', '1826', 'Avenida Cerejeira', 'Belém'),
    (50, 5, NULL, '2026-01-02', '15968244668', 'Raquel Moura Correia', '2012-11-27', 'Ex-praticante de karatê (faixa verde).', FALSE, 'ATIVO', '2026-01-02', '03590556', '1100', 'Rua Pau-Brasil', 'Artur Alvim'),
    (51, NULL, NULL, '2026-01-05', '88713017126', 'Juliana Oliveira Ferreira', '1992-07-22', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'INATIVO', NULL, '03835708', '579', 'Rua Tangará', 'Itaquera'),
    (52, NULL, NULL, '2026-01-05', '36671601625', 'Priscila Barbosa Macedo', '1982-10-03', 'Pratica musculação há 4 anos; nunca treinou luta.', FALSE, 'ATIVO', NULL, '03277310', '1905', 'Rua Sabiá', 'Vila Matilde'),
    (53, 6, NULL, '2026-01-25', '73696066399', 'Patrícia Dias Macedo', '2013-06-06', 'Jogou futebol amador por 10 anos; iniciante em lutas.', FALSE, 'ATIVO', NULL, '03078966', '431', 'Rua Quaresmeira', 'Penha'),
    (54, NULL, NULL, '2026-02-02', '01146676432', 'Débora Nascimento Macedo', '1985-06-26', 'Pratica natação; quer melhorar o condicionamento.', FALSE, 'ATIVO', NULL, '03844533', '628', 'Rua Aroeira', 'Tatuapé'),
    (55, 7, NULL, '2026-02-02', '08024920854', 'Théo Ribeiro Macedo', '2011-11-27', 'Nunca praticou esportes.', FALSE, 'ATIVO', '2026-01-25', '03358809', '1008', 'Rua Jequitibá', 'Tatuapé'),
    (56, 7, NULL, '2026-02-02', '91422291069', 'Sofia Gomes Macedo', '2014-12-14', 'Fez balé por 2 anos.', FALSE, 'ATIVO', '2026-01-28', '08699798', '65', 'Rua Sete Copas', 'São Mateus'),
    (57, NULL, NULL, '2026-02-08', '23124360883', 'Patrícia Ribeiro Costa', '1997-12-18', 'Pratica natação; quer melhorar o condicionamento.', TRUE, 'ATIVO', NULL, '08276054', '1845', 'Rua Pau-Brasil', 'Cidade Patriarca'),
    (58, NULL, NULL, '2026-02-09', '88808225489', 'Daniela Monteiro Ferreira', '1988-07-23', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', NULL, '08188023', '1969', 'Rua Flamboyant', 'Belém'),
    (59, NULL, NULL, '2026-02-10', '01259506553', 'Letícia Cardoso Santos', '1999-08-23', 'Pratica musculação há 4 anos; nunca treinou luta.', FALSE, 'ATIVO', NULL, '03060507', '1442', 'Rua Sabiá', 'Cidade Patriarca'),
    (60, NULL, NULL, '2026-03-09', '71463007478', 'Yasmin Mendes Oliveira', '1976-09-07', 'Pratica musculação há 4 anos; nunca treinou luta.', TRUE, 'INATIVO', NULL, '03058800', '304', 'Rua Manacá', 'Vila Carrão');
INSERT INTO ALUNO (ID_ALUNO, ID_RESPONSAVEL, ID_INTERESSADO, DT_AUTORIZACAO_IMAGEM, CPF, NM_COMPLETO, DT_NASCIMENTO, DS_HISTORICO_TREINO, IN_ACEITE_USO_IMAGEM, TP_STATUS_ALUNO, DT_ENTREGA_ATESTADO, NR_CEP, NR_LOGRADOURO, DS_RUA, NM_BAIRRO) VALUES
    (61, NULL, NULL, '2026-03-21', '48996801757', 'Yasmin Vieira Monteiro', '2000-04-22', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', NULL, '03243180', '1201', 'Rua Ipê Roxo', 'Belém'),
    (62, NULL, NULL, '2026-03-28', '89217740555', 'Hugo Vieira Lima', '2002-06-08', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', NULL, '08091414', '55', 'Rua Ipê Roxo', 'Guaianases'),
    (63, NULL, NULL, '2026-03-31', '29406570654', 'Otávio Dias Ribeiro', '1991-06-14', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '03823026', '738', 'Avenida das Hortênsias', 'Cangaíba'),
    (64, NULL, NULL, '2026-04-08', '30915308854', 'Isabela Souza Martins', '1984-12-11', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'TRANCADO', NULL, '03072518', '251', 'Rua dos Cravos', 'Vila Formosa'),
    (65, 8, NULL, '2026-04-09', '63487301510', 'Manuela Almeida Nascimento', '2014-06-22', 'Fez natação por 1 ano.', TRUE, 'ATIVO', '2026-04-08', '08968400', '462', 'Rua Jequitibá', 'Cangaíba'),
    (66, NULL, NULL, '2026-04-11', '54868236472', 'Marcelo Nascimento Rodrigues', '1994-06-10', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', NULL, '03901455', '1643', 'Rua Tangará', 'Aricanduva'),
    (67, NULL, NULL, '2026-04-16', '00862569492', 'Aline Lopes Moreira', '2005-07-26', 'Jogou futebol amador por 10 anos; iniciante em lutas.', TRUE, 'ATIVO', NULL, '03835723', '1891', 'Rua Sabiá', 'Vila Esperança'),
    (68, NULL, NULL, '2026-04-21', '49605189397', 'Otávio Batista Teixeira', '1973-04-03', 'Treinou boxe por 1 ano em projeto social.', TRUE, 'ATIVO', NULL, '03400072', '1612', 'Rua Sabiá', 'Vila Formosa'),
    (69, NULL, NULL, '2026-04-26', '31836802439', 'Bianca Costa Machado', '1994-07-13', 'Fez capoeira na escola por 3 anos.', TRUE, 'ATIVO', NULL, '08413620', '1256', 'Rua dos Cravos', 'Itaquera'),
    (70, NULL, NULL, '2026-05-04', '51898758960', 'Leonardo Oliveira Freitas', '1981-09-20', 'Pratica natação; quer melhorar o condicionamento.', FALSE, 'INATIVO', NULL, '08624800', '30', 'Travessa das Orquídeas', 'Ermelino Matarazzo'),
    (71, NULL, NULL, '2026-05-11', '90143028568', 'Viviane Correia Moura', '1978-08-03', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', NULL, '03311218', '895', 'Travessa das Orquídeas', 'Cangaíba'),
    (72, 9, NULL, '2026-05-11', '10590882124', 'Laura Ramos Moura', '2018-11-09', 'Fez balé por 2 anos.', TRUE, 'ATIVO', '2026-05-01', '08498644', '621', 'Rua Quaresmeira', 'Vila Formosa'),
    (73, NULL, NULL, '2026-06-01', '48437064875', 'Murilo Pinto Martins', '1975-04-05', 'Ex-praticante de karatê (faixa verde).', TRUE, 'INATIVO', NULL, '08352534', '1338', 'Rua das Camélias', 'São Mateus'),
    (74, 10, NULL, '2026-06-03', '17119168249', 'Aline Silva Siqueira', '2012-12-26', 'Treinou boxe por 1 ano em projeto social.', FALSE, 'ATIVO', '2026-05-29', '08937527', '1511', 'Rua dos Cravos', 'Tatuapé'),
    (75, NULL, NULL, '2026-06-11', '66243238213', 'Viviane Gomes Ramos', '1992-12-04', 'Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', NULL, '08450899', '871', 'Rua das Acácias', 'Artur Alvim'),
    (76, NULL, NULL, '2026-06-13', '88553229807', 'Gabriela Machado Cavalcanti', '1988-03-27', 'Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', NULL, '08978398', '1331', 'Rua Tangará', 'Água Rasa'),
    (77, NULL, NULL, '2026-07-06', '75510711460', 'Vanessa Rodrigues Cavalcanti', '1980-05-04', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', NULL, '03823526', '1896', 'Rua Quaresmeira', 'Artur Alvim'),
    (78, 11, NULL, '2026-07-06', '83296066586', 'Théo Monteiro Cavalcanti', '2017-09-20', 'Fez balé por 2 anos.', FALSE, 'ATIVO', '2026-07-05', '08298077', '176', 'Rua Bem-te-vi', 'Vila Formosa'),
    (79, NULL, NULL, '2026-07-15', '00958677994', 'Priscila Monteiro Ribeiro', '1978-08-19', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', FALSE, 'ATIVO', NULL, '03879348', '1460', 'Avenida Cerejeira', 'Penha'),
    (80, NULL, NULL, '2026-07-26', '86601347849', 'Carolina Ferreira Carvalho', '2001-07-12', 'Corredor de rua (provas de 10 km); iniciante em lutas.', TRUE, 'ATIVO', NULL, '03009001', '1756', 'Rua Beija-flor', 'Penha'),
    (81, NULL, NULL, '2026-08-23', '27552234514', 'Leonardo Batista Pereira', '2007-01-05', 'Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '03882518', '1318', 'Rua Jequitibá', 'Penha'),
    (82, NULL, 1, '2026-09-03', '45628674121', 'Daniel Vieira Queiroz', '1987-10-28', 'Fez a aula experimental na academia. Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '03125168', '984', 'Rua Manacá', 'Vila Esperança'),
    (83, NULL, 3, '2026-09-11', '52611654533', 'Carolina Freitas Machado', '1977-02-18', 'Fez a aula experimental na academia. Treinou Muay Thai por 6 meses em 2021.', TRUE, 'ATIVO', NULL, '08127162', '298', 'Rua das Acácias', 'Cangaíba'),
    (84, NULL, 4, '2026-09-21', '18371275341', 'Tatiane Mendes Dias', '1976-03-19', 'Fez a aula experimental na academia. Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '08989621', '1707', 'Avenida das Hortênsias', 'Belém'),
    (85, NULL, 8, '2026-09-27', '13312141917', 'Eduardo Pereira Rodrigues', '1986-09-17', 'Fez a aula experimental na academia. Pratica musculação há 4 anos; nunca treinou luta.', FALSE, 'ATIVO', NULL, '08042457', '912', 'Rua Jequitibá', 'Vila Formosa'),
    (86, NULL, 11, '2026-10-06', '36971498622', 'Aline Campos Tavares', '1984-09-03', 'Fez a aula experimental na academia. Fez capoeira na escola por 3 anos.', FALSE, 'ATIVO', NULL, '03139721', '760', 'Rua Sete Copas', 'Belém'),
    (87, NULL, 10, '2026-10-07', '47325601954', 'Fernanda Brandão Rodrigues', '1987-06-11', 'Fez a aula experimental na academia. Treinou judô na infância (faixa amarela); parado há 12 anos.', TRUE, 'ATIVO', NULL, '03048550', '1857', 'Rua das Violetas', 'Vila Esperança'),
    (88, NULL, 13, '2026-10-07', '88623682562', 'Viviane Teixeira Macedo', '1981-04-04', 'Fez a aula experimental na academia. Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'ATIVO', NULL, '03961132', '1292', 'Rua Bem-te-vi', 'Vila Formosa'),
    (89, NULL, 14, '2026-10-11', '56232627922', 'Beatriz Batista Costa', '1982-03-24', 'Fez a aula experimental na academia. Nunca praticou artes marciais; sedentário há 3 anos.', TRUE, 'ATIVO', NULL, '03168900', '1604', 'Rua das Camélias', 'Penha'),
    (90, NULL, 17, '2026-10-15', '80257653917', 'Alexandre Almeida Freitas', '1981-08-12', 'Fez a aula experimental na academia. Pratica natação; quer melhorar o condicionamento.', FALSE, 'ATIVO', NULL, '08042724', '948', 'Travessa das Orquídeas', 'Guaianases'),
    (91, NULL, 15, '2026-10-15', '07934933944', 'Cláudia Nascimento Teixeira', '1996-09-01', 'Fez a aula experimental na academia. Nunca treinou; procurou a academia para defesa pessoal.', TRUE, 'ATIVO', NULL, '08993350', '1255', 'Avenida Cerejeira', 'Penha'),
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
    ('11961192076', 1),
    ('1124778764', 1),
    ('11947005659', 2),
    ('11962728058', 3),
    ('11966007570', 4),
    ('11946740353', 5),
    ('11971308404', 5),
    ('11976095933', 6),
    ('11978578133', 7),
    ('11948224498', 8),
    ('1129448786', 8),
    ('11999509279', 9),
    ('11985057394', 10),
    ('11990139409', 11),
    ('11967557097', 11),
    ('11976768916', 12),
    ('11937535808', 13),
    ('1123543173', 13),
    ('11986084778', 14),
    ('11979749034', 15),
    ('11966964215', 16),
    ('11951948697', 17),
    ('11937896565', 18),
    ('11937896565', 19),
    ('11937896565', 20),
    ('11985833213', 21),
    ('11931831981', 22),
    ('1124207069', 22),
    ('11972150545', 23),
    ('11902850460', 24),
    ('11992169474', 24),
    ('1129864014', 24),
    ('11954425261', 25),
    ('11972573947', 26),
    ('11963237251', 26),
    ('11905762184', 27),
    ('11946456786', 28),
    ('11939505091', 29),
    ('11923456564', 30),
    ('11991383297', 31),
    ('11945211323', 32),
    ('11927800997', 33),
    ('11969445228', 34),
    ('11972850277', 35),
    ('11946935394', 36),
    ('1121109043', 36),
    ('11946935394', 37),
    ('11946935394', 38),
    ('11960758039', 39),
    ('11984319033', 39),
    ('11906328714', 40),
    ('1123085795', 40),
    ('11922103069', 41),
    ('11975746605', 42),
    ('1125382880', 42),
    ('11904156238', 43),
    ('11927822749', 44),
    ('1124630956', 44),
    ('11941961804', 45),
    ('11902773001', 45);
INSERT INTO TELEFONE_ALUNO (NR_TELEFONE, ID_ALUNO) VALUES
    ('11963459372', 46),
    ('11967103206', 47),
    ('11990667882', 48),
    ('11944333443', 49),
    ('11947425454', 50),
    ('11996862136', 50),
    ('11945194292', 51),
    ('1129248988', 51),
    ('11976595062', 52),
    ('11982220291', 53),
    ('11982717797', 53),
    ('11956276427', 54),
    ('1127309078', 54),
    ('11956276427', 55),
    ('11956276427', 56),
    ('11982056892', 57),
    ('11914003983', 58),
    ('11905075137', 59),
    ('1122299361', 59),
    ('11942459653', 60),
    ('11931376612', 61),
    ('11990985756', 62),
    ('1122015725', 62),
    ('11930330233', 63),
    ('11916593856', 64),
    ('11921563398', 65),
    ('11934183216', 65),
    ('11968883702', 66),
    ('11981875164', 67),
    ('1128570282', 67),
    ('11986987460', 68),
    ('11912289571', 69),
    ('11996352101', 70),
    ('1126269438', 70),
    ('11963520220', 71),
    ('11963520220', 72),
    ('11935625857', 73),
    ('11953706412', 74),
    ('11992239891', 74),
    ('11934470177', 74),
    ('11933842123', 75),
    ('11983158430', 76),
    ('11960555531', 77),
    ('11960555531', 78),
    ('11977404936', 79),
    ('11968312936', 80),
    ('11906108533', 80),
    ('11928204113', 81),
    ('11951341935', 82),
    ('1120351613', 82),
    ('11904838041', 83),
    ('11950519150', 83),
    ('11933669288', 84),
    ('11983541274', 85),
    ('11937219453', 86),
    ('11977475313', 87),
    ('11997878922', 87),
    ('11907884745', 88),
    ('11977276268', 89),
    ('1125875561', 89);
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
    ('Hérnia de disco lombar - evitar quedas sem orientação', 30),
    ('Diabetes tipo 1', 30),
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
-- 4.6 TURMA (18) [RF03, RE01, RE02, RE05]
-- Grade semanal de segunda a sábado, nos períodos matutino, vespertino e noturno.
-- A turma 18 (No-Gi, sábado 08:00) acabou de abrir e ainda não tem alunos: serve para mostrar
-- o LEFT JOIN e o alerta de turma abaixo do quórum.
-- -------------------------------------------------------------------------------------
INSERT INTO TURMA (ID_TURMA, ID_MODALIDADE, ID_PROFESSOR, DS_DIA_SEMANA, HR_INICIO, QT_CAPACIDADE_MAXIMA, HR_FIM) VALUES
    (1, 1, 1, 'SEGUNDA', '07:00:00', 30, '08:00:00'),
    (2, 1, 1, 'TERCA', '19:00:00', 30, '20:00:00'),
    (3, 1, 1, 'QUINTA', '19:00:00', 30, '20:00:00'),
    (4, 1, 1, 'SABADO', '09:00:00', 30, '10:30:00'),
    (5, 2, 2, 'SEGUNDA', '19:00:00', 30, '20:00:00'),
    (6, 2, 2, 'QUARTA', '19:00:00', 30, '20:00:00'),
    (7, 2, 2, 'SEXTA', '18:00:00', 30, '19:00:00'),
    (8, 3, 3, 'SEGUNDA', '20:00:00', 30, '21:30:00'),
    (9, 3, 3, 'TERCA', '07:00:00', 30, '08:30:00'),
    (10, 3, 3, 'QUARTA', '20:00:00', 30, '21:30:00'),
    (11, 3, 3, 'SEXTA', '19:30:00', 30, '21:00:00'),
    (12, 4, 4, 'TERCA', '18:00:00', 30, '19:00:00'),
    (13, 4, 4, 'QUINTA', '18:00:00', 30, '19:00:00'),
    (14, 4, 4, 'SABADO', '10:30:00', 30, '11:30:00'),
    (15, 5, 5, 'QUARTA', '15:00:00', 30, '16:30:00'),
    (16, 5, 5, 'SABADO', '14:00:00', 30, '15:30:00'),
    (17, 6, 6, 'QUINTA', '20:00:00', 30, '21:30:00'),
    (18, 6, 6, 'SABADO', '08:00:00', 30, '09:30:00');

-- -------------------------------------------------------------------------------------
-- 4.7 MATRICULA (190) [RF03, RE06]
-- Cada aluno treina em 1 a 3 turmas da sua modalidade (uma matrícula por turma).
-- 171 ATIVA, 3 TRANCADA, 3 ENCERRADA (troca de turma), 13 CANCELADA.
-- Na troca de turma a matrícula antiga fica ENCERRADA e uma nova é criada (o histórico não é apagado).
-- -------------------------------------------------------------------------------------
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (1, 1, 2, '2024-04-03', 'ATIVA'),
    (2, 1, 4, '2024-04-03', 'ATIVA'),
    (3, 2, 2, '2024-06-07', 'ATIVA'),
    (4, 3, 5, '2024-07-12', 'ATIVA'),
    (5, 3, 9, '2024-07-12', 'ATIVA'),
    (6, 3, 10, '2024-07-12', 'ATIVA'),
    (7, 4, 17, '2024-08-05', 'ATIVA'),
    (8, 5, 3, '2024-10-04', 'ATIVA'),
    (9, 5, 4, '2024-10-04', 'ATIVA'),
    (10, 6, 14, '2024-10-25', 'ATIVA'),
    (11, 7, 6, '2024-11-12', 'ATIVA'),
    (12, 7, 7, '2024-11-12', 'ATIVA'),
    (13, 8, 1, '2024-11-24', 'ATIVA'),
    (14, 8, 2, '2024-11-24', 'ATIVA'),
    (15, 8, 3, '2024-11-24', 'ATIVA'),
    (16, 9, 12, '2024-11-28', 'ATIVA'),
    (17, 9, 13, '2024-11-28', 'ATIVA'),
    (18, 9, 14, '2024-11-28', 'ATIVA'),
    (19, 10, 9, '2024-12-16', 'ATIVA'),
    (20, 10, 11, '2024-12-16', 'ATIVA'),
    (21, 11, 5, '2024-12-20', 'ATIVA'),
    (22, 11, 15, '2024-12-20', 'ATIVA'),
    (23, 12, 1, '2024-12-22', 'ATIVA'),
    (24, 12, 3, '2024-12-22', 'ATIVA'),
    (25, 13, 13, '2025-01-02', 'ATIVA'),
    (26, 13, 14, '2025-01-02', 'ENCERRADA'),
    (27, 14, 8, '2025-01-02', 'ATIVA'),
    (28, 15, 2, '2025-01-07', 'TRANCADA'),
    (29, 16, 9, '2025-02-19', 'TRANCADA'),
    (30, 17, 6, '2025-02-21', 'ATIVA'),
    (31, 17, 7, '2025-02-21', 'ATIVA'),
    (32, 18, 8, '2025-03-10', 'ATIVA'),
    (33, 18, 10, '2025-03-10', 'ATIVA'),
    (34, 18, 11, '2025-03-10', 'ATIVA'),
    (35, 19, 15, '2025-03-10', 'ATIVA'),
    (36, 20, 15, '2025-03-10', 'ATIVA'),
    (37, 20, 16, '2025-03-10', 'ATIVA'),
    (38, 21, 5, '2025-03-13', 'ATIVA'),
    (39, 21, 7, '2025-03-13', 'ATIVA'),
    (40, 22, 1, '2025-04-11', 'ATIVA'),
    (41, 22, 2, '2025-04-11', 'ATIVA'),
    (42, 22, 4, '2025-04-11', 'ATIVA'),
    (43, 23, 15, '2025-04-12', 'ATIVA'),
    (44, 23, 16, '2025-04-12', 'ATIVA'),
    (45, 24, 2, '2025-04-14', 'ATIVA'),
    (46, 24, 3, '2025-04-14', 'ATIVA'),
    (47, 25, 1, '2025-04-16', 'ATIVA'),
    (48, 25, 4, '2025-04-16', 'ATIVA'),
    (49, 26, 9, '2025-04-30', 'ATIVA'),
    (50, 26, 10, '2025-04-30', 'ATIVA'),
    (51, 27, 16, '2025-05-26', 'ATIVA'),
    (52, 27, 17, '2025-05-26', 'ATIVA'),
    (53, 28, 15, '2025-06-02', 'CANCELADA'),
    (54, 28, 16, '2025-06-02', 'CANCELADA'),
    (55, 29, 12, '2025-06-14', 'ATIVA'),
    (56, 29, 16, '2025-06-14', 'ATIVA'),
    (57, 30, 17, '2025-06-21', 'ATIVA'),
    (58, 31, 5, '2025-06-23', 'ATIVA'),
    (59, 31, 6, '2025-06-23', 'ATIVA'),
    (60, 32, 8, '2025-07-13', 'ATIVA');
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (61, 32, 10, '2025-07-13', 'ATIVA'),
    (62, 32, 11, '2025-07-13', 'ATIVA'),
    (63, 33, 3, '2025-07-22', 'ATIVA'),
    (64, 33, 6, '2025-07-22', 'ATIVA'),
    (65, 34, 9, '2025-07-22', 'ATIVA'),
    (66, 34, 11, '2025-07-22', 'ATIVA'),
    (67, 35, 8, '2025-07-28', 'ATIVA'),
    (68, 35, 10, '2025-07-28', 'ATIVA'),
    (69, 35, 11, '2025-07-28', 'ATIVA'),
    (70, 36, 6, '2025-08-04', 'ATIVA'),
    (71, 36, 7, '2025-08-04', 'ATIVA'),
    (72, 37, 8, '2025-08-04', 'ATIVA'),
    (73, 37, 9, '2025-08-04', 'ATIVA'),
    (74, 38, 9, '2025-08-04', 'ATIVA'),
    (75, 38, 10, '2025-08-04', 'ATIVA'),
    (76, 38, 11, '2025-08-04', 'ATIVA'),
    (77, 39, 8, '2025-08-16', 'ATIVA'),
    (78, 39, 11, '2025-08-16', 'ATIVA'),
    (79, 40, 5, '2025-09-01', 'ATIVA'),
    (80, 40, 7, '2025-09-01', 'ATIVA'),
    (81, 41, 8, '2025-09-18', 'ATIVA'),
    (82, 41, 10, '2025-09-18', 'ATIVA'),
    (83, 42, 9, '2025-10-10', 'ATIVA'),
    (84, 42, 10, '2025-10-10', 'ATIVA'),
    (85, 42, 15, '2025-10-10', 'ATIVA'),
    (86, 43, 8, '2025-10-12', 'ATIVA'),
    (87, 43, 9, '2025-10-12', 'ATIVA'),
    (88, 43, 11, '2025-10-12', 'ATIVA'),
    (89, 44, 12, '2025-10-23', 'ATIVA'),
    (90, 44, 13, '2025-10-23', 'ATIVA'),
    (91, 44, 14, '2025-10-23', 'ATIVA'),
    (92, 45, 15, '2025-11-03', 'CANCELADA'),
    (93, 45, 16, '2025-11-03', 'CANCELADA'),
    (94, 46, 1, '2025-12-05', 'ATIVA'),
    (95, 47, 15, '2025-12-10', 'ATIVA'),
    (96, 47, 16, '2025-12-10', 'ATIVA'),
    (97, 48, 12, '2025-12-16', 'ATIVA'),
    (98, 48, 13, '2025-12-16', 'ENCERRADA'),
    (99, 48, 17, '2025-12-16', 'ATIVA'),
    (100, 49, 1, '2025-12-30', 'ATIVA'),
    (101, 49, 2, '2025-12-30', 'ATIVA'),
    (102, 50, 15, '2026-01-02', 'ATIVA'),
    (103, 50, 16, '2026-01-02', 'ATIVA'),
    (104, 51, 5, '2026-01-05', 'CANCELADA'),
    (105, 51, 6, '2026-01-05', 'CANCELADA'),
    (106, 51, 7, '2026-01-05', 'CANCELADA'),
    (107, 52, 3, '2026-01-05', 'ATIVA'),
    (108, 52, 4, '2026-01-05', 'ATIVA'),
    (109, 53, 9, '2026-01-25', 'ATIVA'),
    (110, 54, 12, '2026-02-02', 'ATIVA'),
    (111, 54, 13, '2026-02-02', 'ATIVA'),
    (112, 54, 14, '2026-02-02', 'ATIVA'),
    (113, 55, 16, '2026-02-02', 'ATIVA'),
    (114, 56, 15, '2026-02-02', 'ATIVA'),
    (115, 56, 16, '2026-02-02', 'ATIVA'),
    (116, 57, 8, '2026-02-08', 'ATIVA'),
    (117, 57, 10, '2026-02-08', 'ATIVA'),
    (118, 57, 11, '2026-02-08', 'ATIVA'),
    (119, 58, 8, '2026-02-09', 'ATIVA'),
    (120, 58, 14, '2026-02-09', 'ATIVA');
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (121, 59, 5, '2026-02-10', 'ATIVA'),
    (122, 59, 6, '2026-02-10', 'ATIVA'),
    (123, 59, 7, '2026-02-10', 'ATIVA'),
    (124, 60, 6, '2026-03-09', 'CANCELADA'),
    (125, 60, 7, '2026-03-09', 'CANCELADA'),
    (126, 61, 1, '2026-03-21', 'ENCERRADA'),
    (127, 61, 4, '2026-03-21', 'ATIVA'),
    (128, 61, 13, '2026-03-21', 'ATIVA'),
    (129, 62, 12, '2026-03-28', 'ATIVA'),
    (130, 62, 14, '2026-03-28', 'ATIVA'),
    (131, 63, 2, '2026-03-31', 'ATIVA'),
    (132, 63, 4, '2026-03-31', 'ATIVA'),
    (133, 64, 10, '2026-04-08', 'TRANCADA'),
    (134, 65, 2, '2026-04-09', 'ATIVA'),
    (135, 65, 3, '2026-04-09', 'ATIVA'),
    (136, 65, 4, '2026-04-09', 'ATIVA'),
    (137, 66, 5, '2026-04-11', 'ATIVA'),
    (138, 67, 9, '2026-04-16', 'ATIVA'),
    (139, 67, 11, '2026-04-16', 'ATIVA'),
    (140, 68, 2, '2026-04-21', 'ATIVA'),
    (141, 68, 3, '2026-04-21', 'ATIVA'),
    (142, 68, 17, '2026-04-21', 'ATIVA'),
    (143, 69, 1, '2026-04-26', 'ATIVA'),
    (144, 69, 4, '2026-04-26', 'ATIVA'),
    (145, 70, 15, '2026-05-04', 'CANCELADA'),
    (146, 70, 16, '2026-05-04', 'CANCELADA'),
    (147, 71, 17, '2026-05-11', 'ATIVA'),
    (148, 72, 15, '2026-05-11', 'ATIVA'),
    (149, 72, 16, '2026-05-11', 'ATIVA'),
    (150, 73, 1, '2026-06-01', 'CANCELADA'),
    (151, 73, 3, '2026-06-01', 'CANCELADA'),
    (152, 74, 9, '2026-06-03', 'ATIVA'),
    (153, 74, 10, '2026-06-03', 'ATIVA'),
    (154, 75, 8, '2026-06-11', 'ATIVA'),
    (155, 75, 11, '2026-06-11', 'ATIVA'),
    (156, 76, 6, '2026-06-13', 'ATIVA'),
    (157, 76, 8, '2026-06-13', 'ATIVA'),
    (158, 61, 3, '2026-07-03', 'ATIVA'),
    (159, 77, 1, '2026-07-06', 'ATIVA'),
    (160, 77, 2, '2026-07-06', 'ATIVA'),
    (161, 77, 4, '2026-07-06', 'ATIVA'),
    (162, 78, 11, '2026-07-06', 'ATIVA'),
    (163, 79, 1, '2026-07-15', 'ATIVA'),
    (164, 79, 12, '2026-07-15', 'ATIVA'),
    (165, 79, 13, '2026-07-15', 'ATIVA'),
    (166, 13, 12, '2026-07-22', 'ATIVA'),
    (167, 80, 1, '2026-07-26', 'ATIVA'),
    (168, 80, 2, '2026-07-26', 'ATIVA'),
    (169, 80, 3, '2026-07-26', 'ATIVA'),
    (170, 48, 14, '2026-08-12', 'ATIVA'),
    (171, 81, 8, '2026-08-23', 'ATIVA'),
    (172, 81, 10, '2026-08-23', 'ATIVA'),
    (173, 82, 12, '2026-09-03', 'ATIVA'),
    (174, 82, 13, '2026-09-03', 'ATIVA'),
    (175, 82, 14, '2026-09-03', 'ATIVA'),
    (176, 83, 13, '2026-09-11', 'ATIVA'),
    (177, 84, 16, '2026-09-21', 'ATIVA'),
    (178, 85, 3, '2026-09-27', 'ATIVA'),
    (179, 85, 4, '2026-09-27', 'ATIVA'),
    (180, 86, 10, '2026-10-06', 'ATIVA');
INSERT INTO MATRICULA (ID_MATRICULA, ID_ALUNO, ID_TURMA, DT_MATRICULA, TP_SITUACAO_MATRICULA) VALUES
    (181, 87, 17, '2026-10-07', 'ATIVA'),
    (182, 88, 5, '2026-10-07', 'ATIVA'),
    (183, 88, 6, '2026-10-07', 'ATIVA'),
    (184, 88, 7, '2026-10-07', 'ATIVA'),
    (185, 89, 17, '2026-10-11', 'ATIVA'),
    (186, 90, 12, '2026-10-15', 'ATIVA'),
    (187, 90, 14, '2026-10-15', 'ATIVA'),
    (188, 91, 6, '2026-10-15', 'ATIVA'),
    (189, 91, 7, '2026-10-15', 'ATIVA'),
    (190, 92, 9, '2026-10-28', 'ATIVA');

-- -------------------------------------------------------------------------------------
-- 4.8 TRANCAMENTO (6) [RF06, RE04]
-- 3 trancamentos já encerrados (aluno voltou) e 3 em curso (DT_RETORNO_EFETIVA vazia).
-- -------------------------------------------------------------------------------------
INSERT INTO TRANCAMENTO (ID_TRANCAMENTO, ID_MATRICULA, TP_TRANCAMENTO, DT_RETORNO_EFETIVA, DS_MOTIVO, DT_RETORNO_PREVISTA, DT_INICIO) VALUES
    (1, 23, 'LESAO', '2026-04-13', 'Fratura no dedo da mão direita em treino; tala por 5 semanas.', '2026-04-06', '2026-03-02'),
    (2, 97, 'RAZAO_MEDICA', '2026-06-08', 'Pneumonia; repouso por recomendação médica.', '2026-06-04', '2026-05-04'),
    (3, 1, 'LESAO', '2026-08-20', 'Estiramento muscular na coxa; fisioterapia.', '2026-08-17', '2026-07-10'),
    (4, 133, 'LESAO', NULL, 'Entorse grave no tornozelo esquerdo durante jogo de futebol; imobilização por 8 semanas.', '2026-12-15', '2026-09-15'),
    (5, 28, 'RAZAO_MEDICA', NULL, 'Cirurgia de vesícula agendada; afastamento recomendado pelo médico.', '2026-11-30', '2026-10-05'),
    (6, 29, 'LESAO', NULL, 'Ruptura parcial do ligamento do ombro direito; fisioterapia.', '2027-01-20', '2026-10-20');

-- -------------------------------------------------------------------------------------
-- 4.9 AULA (74) [RF05, RO07]
-- Todas as aulas de outubro/2026: cada turma ocorre uma vez por semana; 12/10 foi feriado (sem aula).
-- Aula 56 é a reposição (ID_AULA_ORIGEM = 44) da aula de Boxe de 20/10, interrompida por queda de energia.
-- Cenário de auditoria: a aula 30 (Kickboxing, 14/10) foi dada pelo professor de Muay Thai (A04).
-- -------------------------------------------------------------------------------------
INSERT INTO AULA (ID_AULA, ID_PROFESSOR, ID_TURMA, DT_AULA, HR_INICIO, ID_AULA_ORIGEM) VALUES
    (1, 4, 13, '2026-10-01', '18:00:00', NULL),
    (2, 1, 3, '2026-10-01', '19:00:00', NULL),
    (3, 6, 17, '2026-10-01', '20:00:00', NULL),
    (4, 2, 7, '2026-10-02', '18:00:00', NULL),
    (5, 3, 11, '2026-10-02', '19:30:00', NULL),
    (6, 1, 4, '2026-10-03', '09:00:00', NULL),
    (7, 4, 14, '2026-10-03', '10:30:00', NULL),
    (8, 5, 16, '2026-10-03', '14:00:00', NULL),
    (9, 1, 1, '2026-10-05', '07:00:00', NULL),
    (10, 2, 5, '2026-10-05', '19:00:00', NULL),
    (11, 3, 8, '2026-10-05', '20:00:00', NULL),
    (12, 3, 9, '2026-10-06', '07:00:00', NULL),
    (13, 4, 12, '2026-10-06', '18:00:00', NULL),
    (14, 1, 2, '2026-10-06', '19:00:00', NULL),
    (15, 5, 15, '2026-10-07', '15:00:00', NULL),
    (16, 2, 6, '2026-10-07', '19:00:00', NULL),
    (17, 3, 10, '2026-10-07', '20:00:00', NULL),
    (18, 4, 13, '2026-10-08', '18:00:00', NULL),
    (19, 1, 3, '2026-10-08', '19:00:00', NULL),
    (20, 6, 17, '2026-10-08', '20:00:00', NULL),
    (21, 2, 7, '2026-10-09', '18:00:00', NULL),
    (22, 3, 11, '2026-10-09', '19:30:00', NULL),
    (23, 1, 4, '2026-10-10', '09:00:00', NULL),
    (24, 4, 14, '2026-10-10', '10:30:00', NULL),
    (25, 5, 16, '2026-10-10', '14:00:00', NULL),
    (26, 3, 9, '2026-10-13', '07:00:00', NULL),
    (27, 4, 12, '2026-10-13', '18:00:00', NULL),
    (28, 1, 2, '2026-10-13', '19:00:00', NULL),
    (29, 5, 15, '2026-10-14', '15:00:00', NULL),
    (30, 1, 6, '2026-10-14', '19:00:00', NULL),
    (31, 3, 10, '2026-10-14', '20:00:00', NULL),
    (32, 4, 13, '2026-10-15', '18:00:00', NULL),
    (33, 1, 3, '2026-10-15', '19:00:00', NULL),
    (34, 6, 17, '2026-10-15', '20:00:00', NULL),
    (35, 2, 7, '2026-10-16', '18:00:00', NULL),
    (36, 3, 11, '2026-10-16', '19:30:00', NULL),
    (37, 1, 4, '2026-10-17', '09:00:00', NULL),
    (38, 4, 14, '2026-10-17', '10:30:00', NULL),
    (39, 5, 16, '2026-10-17', '14:00:00', NULL),
    (40, 1, 1, '2026-10-19', '07:00:00', NULL),
    (41, 2, 5, '2026-10-19', '19:00:00', NULL),
    (42, 3, 8, '2026-10-19', '20:00:00', NULL),
    (43, 3, 9, '2026-10-20', '07:00:00', NULL),
    (44, 4, 12, '2026-10-20', '18:00:00', NULL),
    (45, 1, 2, '2026-10-20', '19:00:00', NULL),
    (46, 5, 15, '2026-10-21', '15:00:00', NULL),
    (47, 2, 6, '2026-10-21', '19:00:00', NULL),
    (48, 3, 10, '2026-10-21', '20:00:00', NULL),
    (49, 4, 13, '2026-10-22', '18:00:00', NULL),
    (50, 1, 3, '2026-10-22', '19:00:00', NULL),
    (51, 6, 17, '2026-10-22', '20:00:00', NULL),
    (52, 2, 7, '2026-10-23', '18:00:00', NULL),
    (53, 3, 11, '2026-10-23', '19:30:00', NULL),
    (54, 1, 4, '2026-10-24', '09:00:00', NULL),
    (55, 4, 14, '2026-10-24', '10:30:00', NULL),
    (56, 4, 12, '2026-10-24', '12:00:00', 44),
    (57, 5, 16, '2026-10-24', '14:00:00', NULL),
    (58, 1, 1, '2026-10-26', '07:00:00', NULL),
    (59, 2, 5, '2026-10-26', '19:00:00', NULL),
    (60, 3, 8, '2026-10-26', '20:00:00', NULL);
INSERT INTO AULA (ID_AULA, ID_PROFESSOR, ID_TURMA, DT_AULA, HR_INICIO, ID_AULA_ORIGEM) VALUES
    (61, 3, 9, '2026-10-27', '07:00:00', NULL),
    (62, 4, 12, '2026-10-27', '18:00:00', NULL),
    (63, 1, 2, '2026-10-27', '19:00:00', NULL),
    (64, 5, 15, '2026-10-28', '15:00:00', NULL),
    (65, 2, 6, '2026-10-28', '19:00:00', NULL),
    (66, 3, 10, '2026-10-28', '20:00:00', NULL),
    (67, 4, 13, '2026-10-29', '18:00:00', NULL),
    (68, 1, 3, '2026-10-29', '19:00:00', NULL),
    (69, 6, 17, '2026-10-29', '20:00:00', NULL),
    (70, 2, 7, '2026-10-30', '18:00:00', NULL),
    (71, 3, 11, '2026-10-30', '19:30:00', NULL),
    (72, 1, 4, '2026-10-31', '09:00:00', NULL),
    (73, 4, 14, '2026-10-31', '10:30:00', NULL),
    (74, 5, 16, '2026-10-31', '14:00:00', NULL);

-- -------------------------------------------------------------------------------------
-- 4.10 PRESENCA (654) [RF05, RO05, RE04, RE07]
-- Uma linha por matrícula ativa em cada aula de outubro. Não há linha para quem estava trancado
-- ou bloqueado por parcela em atraso (RE07). Alguns alunos têm frequência baixa de propósito
-- (risco de evasão, consulta G09).
-- Cenários de auditoria: presença do aluno 34 na aula 26, já bloqueado por atraso (A02);
-- presença do aluno 15 na aula 14, durante o trancamento (A03).
-- -------------------------------------------------------------------------------------
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (1, 17, TRUE),
    (1, 25, TRUE),
    (1, 90, TRUE),
    (1, 111, TRUE),
    (1, 128, FALSE),
    (1, 165, TRUE),
    (1, 174, TRUE),
    (1, 176, TRUE),
    (2, 8, TRUE),
    (2, 15, TRUE),
    (2, 24, FALSE),
    (2, 46, TRUE),
    (2, 63, TRUE),
    (2, 107, TRUE),
    (2, 135, TRUE),
    (2, 141, FALSE),
    (2, 158, FALSE),
    (2, 169, TRUE),
    (2, 178, TRUE),
    (3, 7, TRUE),
    (3, 52, TRUE),
    (3, 57, TRUE),
    (3, 99, TRUE),
    (3, 142, TRUE),
    (3, 147, TRUE),
    (4, 12, TRUE),
    (4, 31, TRUE),
    (4, 39, TRUE),
    (4, 71, TRUE),
    (4, 80, TRUE),
    (4, 123, TRUE),
    (5, 20, TRUE),
    (5, 34, TRUE),
    (5, 62, FALSE),
    (5, 66, FALSE),
    (5, 69, TRUE),
    (5, 76, TRUE),
    (5, 78, TRUE),
    (5, 88, FALSE),
    (5, 118, TRUE),
    (5, 139, TRUE),
    (5, 155, TRUE),
    (5, 162, TRUE),
    (6, 2, FALSE),
    (6, 9, TRUE),
    (6, 42, TRUE),
    (6, 48, TRUE),
    (6, 108, FALSE),
    (6, 127, TRUE),
    (6, 132, TRUE),
    (6, 136, TRUE),
    (6, 144, FALSE),
    (6, 161, TRUE),
    (6, 179, TRUE),
    (7, 10, TRUE),
    (7, 18, FALSE),
    (7, 91, TRUE),
    (7, 112, TRUE),
    (7, 120, FALSE),
    (7, 130, TRUE),
    (7, 170, TRUE),
    (7, 175, TRUE),
    (8, 37, FALSE),
    (8, 51, TRUE),
    (8, 56, TRUE),
    (8, 96, TRUE),
    (8, 103, TRUE),
    (8, 113, TRUE),
    (8, 115, TRUE),
    (8, 149, TRUE),
    (8, 177, FALSE),
    (9, 13, TRUE),
    (9, 23, FALSE),
    (9, 40, FALSE),
    (9, 47, FALSE),
    (9, 94, TRUE),
    (9, 100, TRUE),
    (9, 143, FALSE),
    (9, 159, TRUE),
    (9, 163, TRUE),
    (9, 167, FALSE),
    (10, 4, TRUE),
    (10, 21, TRUE),
    (10, 38, TRUE),
    (10, 79, FALSE),
    (10, 121, TRUE),
    (10, 137, TRUE),
    (11, 27, TRUE),
    (11, 32, FALSE),
    (11, 60, TRUE),
    (11, 67, FALSE),
    (11, 72, FALSE),
    (11, 77, FALSE),
    (11, 81, TRUE),
    (11, 86, TRUE),
    (11, 116, TRUE),
    (11, 119, FALSE),
    (11, 154, TRUE),
    (11, 157, TRUE),
    (11, 171, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (12, 5, FALSE),
    (12, 19, TRUE),
    (12, 29, FALSE),
    (12, 49, TRUE),
    (12, 65, FALSE),
    (12, 73, TRUE),
    (12, 74, TRUE),
    (12, 83, TRUE),
    (12, 87, TRUE),
    (12, 109, TRUE),
    (12, 138, TRUE),
    (12, 152, TRUE),
    (13, 16, TRUE),
    (13, 55, TRUE),
    (13, 89, FALSE),
    (13, 97, TRUE),
    (13, 110, TRUE),
    (13, 129, TRUE),
    (13, 164, TRUE),
    (13, 166, TRUE),
    (13, 173, TRUE),
    (14, 1, FALSE),
    (14, 3, FALSE),
    (14, 14, FALSE),
    (14, 28, TRUE),
    (14, 41, FALSE),
    (14, 45, TRUE),
    (14, 101, TRUE),
    (14, 131, FALSE),
    (14, 134, TRUE),
    (14, 140, FALSE),
    (14, 160, FALSE),
    (14, 168, TRUE),
    (15, 22, TRUE),
    (15, 35, TRUE),
    (15, 36, TRUE),
    (15, 85, TRUE),
    (15, 95, TRUE),
    (15, 102, TRUE),
    (15, 114, TRUE),
    (15, 148, TRUE),
    (16, 11, FALSE),
    (16, 30, FALSE),
    (16, 64, FALSE),
    (16, 70, TRUE),
    (16, 122, TRUE),
    (16, 156, TRUE),
    (16, 183, TRUE),
    (17, 6, FALSE),
    (17, 33, TRUE),
    (17, 50, TRUE),
    (17, 61, TRUE),
    (17, 68, FALSE),
    (17, 75, TRUE),
    (17, 82, TRUE),
    (17, 84, TRUE),
    (17, 117, TRUE),
    (17, 153, TRUE),
    (17, 172, TRUE),
    (17, 180, FALSE),
    (18, 17, TRUE),
    (18, 25, TRUE),
    (18, 90, TRUE),
    (18, 111, FALSE),
    (18, 128, FALSE),
    (18, 165, TRUE),
    (18, 174, TRUE),
    (18, 176, TRUE),
    (19, 24, TRUE),
    (19, 46, TRUE),
    (19, 107, TRUE),
    (19, 141, TRUE),
    (19, 158, TRUE),
    (20, 52, TRUE),
    (20, 99, TRUE),
    (20, 142, TRUE),
    (20, 147, TRUE),
    (20, 181, TRUE),
    (21, 12, TRUE),
    (21, 31, TRUE),
    (21, 39, TRUE),
    (21, 71, TRUE),
    (21, 80, FALSE),
    (21, 184, FALSE),
    (22, 20, TRUE),
    (22, 34, TRUE),
    (22, 62, TRUE),
    (22, 69, TRUE),
    (22, 76, TRUE),
    (22, 78, TRUE),
    (22, 88, TRUE),
    (22, 118, TRUE),
    (22, 139, TRUE),
    (22, 155, TRUE),
    (22, 162, TRUE),
    (23, 2, TRUE),
    (23, 42, TRUE),
    (23, 48, TRUE),
    (23, 108, TRUE),
    (23, 127, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (23, 144, FALSE),
    (23, 161, TRUE),
    (24, 18, FALSE),
    (24, 91, TRUE),
    (24, 112, TRUE),
    (24, 130, TRUE),
    (24, 170, TRUE),
    (24, 175, TRUE),
    (25, 37, FALSE),
    (25, 51, TRUE),
    (25, 56, TRUE),
    (25, 96, TRUE),
    (25, 113, TRUE),
    (25, 115, TRUE),
    (25, 149, TRUE),
    (26, 5, TRUE),
    (26, 19, TRUE),
    (26, 29, TRUE),
    (26, 49, FALSE),
    (26, 65, TRUE),
    (26, 73, TRUE),
    (26, 74, TRUE),
    (26, 83, TRUE),
    (26, 87, TRUE),
    (26, 109, FALSE),
    (26, 138, TRUE),
    (26, 152, TRUE),
    (27, 16, TRUE),
    (27, 55, TRUE),
    (27, 89, TRUE),
    (27, 97, TRUE),
    (27, 110, TRUE),
    (27, 129, TRUE),
    (27, 164, TRUE),
    (27, 166, TRUE),
    (27, 173, TRUE),
    (28, 1, TRUE),
    (28, 41, TRUE),
    (28, 45, TRUE),
    (28, 101, TRUE),
    (28, 134, TRUE),
    (28, 140, FALSE),
    (28, 160, TRUE),
    (29, 22, TRUE),
    (29, 35, TRUE),
    (29, 36, TRUE),
    (29, 85, FALSE),
    (29, 95, TRUE),
    (29, 114, TRUE),
    (29, 148, TRUE),
    (30, 11, TRUE),
    (30, 30, TRUE),
    (30, 70, TRUE),
    (30, 183, TRUE),
    (31, 6, TRUE),
    (31, 33, TRUE),
    (31, 50, TRUE),
    (31, 61, TRUE),
    (31, 68, TRUE),
    (31, 75, TRUE),
    (31, 82, FALSE),
    (31, 84, TRUE),
    (31, 117, TRUE),
    (31, 153, FALSE),
    (31, 172, TRUE),
    (31, 180, FALSE),
    (32, 17, TRUE),
    (32, 25, TRUE),
    (32, 90, TRUE),
    (32, 111, TRUE),
    (32, 128, FALSE),
    (32, 165, TRUE),
    (32, 174, TRUE),
    (32, 176, TRUE),
    (33, 8, FALSE),
    (33, 24, TRUE),
    (33, 46, TRUE),
    (33, 63, TRUE),
    (33, 107, TRUE),
    (33, 135, FALSE),
    (33, 141, TRUE),
    (33, 158, TRUE),
    (33, 178, TRUE),
    (34, 7, TRUE),
    (34, 52, TRUE),
    (34, 99, TRUE),
    (34, 142, FALSE),
    (34, 147, TRUE),
    (34, 181, TRUE),
    (34, 185, TRUE),
    (35, 12, TRUE),
    (35, 31, TRUE),
    (35, 39, TRUE),
    (35, 71, TRUE),
    (35, 80, TRUE),
    (35, 123, TRUE),
    (35, 184, TRUE),
    (35, 189, TRUE),
    (36, 20, TRUE),
    (36, 34, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (36, 62, TRUE),
    (36, 69, FALSE),
    (36, 76, TRUE),
    (36, 78, TRUE),
    (36, 88, TRUE),
    (36, 118, TRUE),
    (36, 139, TRUE),
    (36, 155, FALSE),
    (36, 162, TRUE),
    (37, 2, FALSE),
    (37, 9, TRUE),
    (37, 42, TRUE),
    (37, 48, FALSE),
    (37, 108, TRUE),
    (37, 127, TRUE),
    (37, 136, FALSE),
    (37, 144, FALSE),
    (37, 161, TRUE),
    (37, 179, TRUE),
    (38, 10, TRUE),
    (38, 18, TRUE),
    (38, 91, TRUE),
    (38, 112, TRUE),
    (38, 130, TRUE),
    (38, 170, TRUE),
    (38, 175, FALSE),
    (38, 187, TRUE),
    (39, 37, TRUE),
    (39, 51, FALSE),
    (39, 56, TRUE),
    (39, 96, TRUE),
    (39, 103, TRUE),
    (39, 113, TRUE),
    (39, 115, TRUE),
    (39, 149, FALSE),
    (39, 177, TRUE),
    (40, 13, FALSE),
    (40, 23, TRUE),
    (40, 40, TRUE),
    (40, 47, TRUE),
    (40, 94, TRUE),
    (40, 100, TRUE),
    (40, 143, FALSE),
    (40, 159, TRUE),
    (40, 163, TRUE),
    (41, 4, TRUE),
    (41, 21, TRUE),
    (41, 38, FALSE),
    (41, 79, TRUE),
    (41, 121, TRUE),
    (41, 137, TRUE),
    (41, 182, FALSE),
    (42, 27, TRUE),
    (42, 32, TRUE),
    (42, 60, TRUE),
    (42, 67, TRUE),
    (42, 72, TRUE),
    (42, 77, FALSE),
    (42, 81, TRUE),
    (42, 86, TRUE),
    (42, 116, TRUE),
    (42, 154, TRUE),
    (42, 171, TRUE),
    (43, 5, TRUE),
    (43, 19, TRUE),
    (43, 49, TRUE),
    (43, 73, TRUE),
    (43, 74, TRUE),
    (43, 83, FALSE),
    (43, 87, TRUE),
    (43, 109, TRUE),
    (43, 138, TRUE),
    (43, 152, TRUE),
    (44, 16, TRUE),
    (44, 55, TRUE),
    (44, 89, TRUE),
    (44, 97, TRUE),
    (44, 110, TRUE),
    (44, 129, TRUE),
    (44, 164, TRUE),
    (44, 166, TRUE),
    (44, 173, FALSE),
    (44, 186, TRUE),
    (45, 1, FALSE),
    (45, 3, TRUE),
    (45, 14, TRUE),
    (45, 41, TRUE),
    (45, 45, TRUE),
    (45, 101, TRUE),
    (45, 134, TRUE),
    (45, 140, TRUE),
    (45, 160, TRUE),
    (46, 22, FALSE),
    (46, 35, FALSE),
    (46, 36, TRUE),
    (46, 85, TRUE),
    (46, 95, TRUE),
    (46, 102, TRUE),
    (46, 114, TRUE),
    (46, 148, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (47, 11, TRUE),
    (47, 30, TRUE),
    (47, 64, FALSE),
    (47, 70, TRUE),
    (47, 122, TRUE),
    (47, 183, TRUE),
    (47, 188, TRUE),
    (48, 6, TRUE),
    (48, 33, TRUE),
    (48, 50, TRUE),
    (48, 61, TRUE),
    (48, 68, FALSE),
    (48, 75, TRUE),
    (48, 82, FALSE),
    (48, 84, TRUE),
    (48, 117, TRUE),
    (48, 153, TRUE),
    (48, 172, FALSE),
    (48, 180, TRUE),
    (49, 17, TRUE),
    (49, 25, TRUE),
    (49, 90, TRUE),
    (49, 111, TRUE),
    (49, 128, TRUE),
    (49, 165, TRUE),
    (49, 174, TRUE),
    (49, 176, TRUE),
    (50, 8, TRUE),
    (50, 15, TRUE),
    (50, 24, TRUE),
    (50, 46, TRUE),
    (50, 63, FALSE),
    (50, 107, TRUE),
    (50, 135, TRUE),
    (50, 141, TRUE),
    (50, 158, FALSE),
    (50, 178, TRUE),
    (51, 7, TRUE),
    (51, 52, TRUE),
    (51, 99, TRUE),
    (51, 142, TRUE),
    (51, 147, TRUE),
    (51, 181, FALSE),
    (51, 185, FALSE),
    (52, 12, TRUE),
    (52, 31, TRUE),
    (52, 39, TRUE),
    (52, 71, TRUE),
    (52, 80, TRUE),
    (52, 123, TRUE),
    (52, 184, TRUE),
    (52, 189, TRUE),
    (53, 20, TRUE),
    (53, 34, TRUE),
    (53, 62, TRUE),
    (53, 69, FALSE),
    (53, 76, TRUE),
    (53, 78, TRUE),
    (53, 88, TRUE),
    (53, 118, TRUE),
    (53, 139, TRUE),
    (53, 155, FALSE),
    (53, 162, TRUE),
    (54, 2, FALSE),
    (54, 9, FALSE),
    (54, 42, TRUE),
    (54, 48, TRUE),
    (54, 108, TRUE),
    (54, 127, FALSE),
    (54, 136, TRUE),
    (54, 144, FALSE),
    (54, 161, TRUE),
    (54, 179, TRUE),
    (55, 10, TRUE),
    (55, 18, FALSE),
    (55, 91, FALSE),
    (55, 112, TRUE),
    (55, 130, TRUE),
    (55, 170, TRUE),
    (55, 175, TRUE),
    (55, 187, TRUE),
    (56, 16, TRUE),
    (56, 55, FALSE),
    (56, 89, TRUE),
    (56, 97, TRUE),
    (56, 110, FALSE),
    (56, 129, TRUE),
    (56, 164, FALSE),
    (56, 166, TRUE),
    (56, 173, TRUE),
    (56, 186, TRUE),
    (57, 37, FALSE),
    (57, 51, TRUE),
    (57, 56, TRUE),
    (57, 96, TRUE),
    (57, 103, TRUE),
    (57, 113, TRUE),
    (57, 115, TRUE),
    (57, 149, TRUE),
    (57, 177, TRUE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (58, 13, TRUE),
    (58, 23, FALSE),
    (58, 40, TRUE),
    (58, 47, TRUE),
    (58, 94, TRUE),
    (58, 100, TRUE),
    (58, 143, TRUE),
    (58, 159, TRUE),
    (58, 163, FALSE),
    (59, 4, TRUE),
    (59, 21, TRUE),
    (59, 38, TRUE),
    (59, 79, TRUE),
    (59, 121, FALSE),
    (59, 137, TRUE),
    (59, 182, TRUE),
    (60, 27, TRUE),
    (60, 32, TRUE),
    (60, 60, TRUE),
    (60, 67, FALSE),
    (60, 72, TRUE),
    (60, 77, TRUE),
    (60, 81, TRUE),
    (60, 86, TRUE),
    (60, 116, FALSE),
    (60, 154, TRUE),
    (60, 171, TRUE),
    (61, 5, TRUE),
    (61, 19, TRUE),
    (61, 49, TRUE),
    (61, 73, TRUE),
    (61, 74, TRUE),
    (61, 83, TRUE),
    (61, 87, TRUE),
    (61, 109, TRUE),
    (61, 138, TRUE),
    (61, 152, TRUE),
    (62, 16, TRUE),
    (62, 55, FALSE),
    (62, 89, TRUE),
    (62, 97, TRUE),
    (62, 110, FALSE),
    (62, 129, TRUE),
    (62, 164, TRUE),
    (62, 166, TRUE),
    (62, 173, FALSE),
    (62, 186, FALSE),
    (63, 1, TRUE),
    (63, 3, TRUE),
    (63, 14, TRUE),
    (63, 41, TRUE),
    (63, 45, TRUE),
    (63, 101, FALSE),
    (63, 134, TRUE),
    (63, 140, FALSE),
    (63, 160, FALSE),
    (64, 22, TRUE),
    (64, 35, TRUE),
    (64, 36, TRUE),
    (64, 85, TRUE),
    (64, 95, TRUE),
    (64, 102, FALSE),
    (64, 114, TRUE),
    (64, 148, FALSE),
    (65, 11, TRUE),
    (65, 30, TRUE),
    (65, 64, TRUE),
    (65, 70, TRUE),
    (65, 122, TRUE),
    (65, 183, TRUE),
    (65, 188, TRUE),
    (66, 6, TRUE),
    (66, 33, FALSE),
    (66, 50, TRUE),
    (66, 61, TRUE),
    (66, 68, FALSE),
    (66, 75, TRUE),
    (66, 82, FALSE),
    (66, 84, FALSE),
    (66, 117, TRUE),
    (66, 153, TRUE),
    (66, 172, TRUE),
    (66, 180, TRUE),
    (67, 17, FALSE),
    (67, 25, TRUE),
    (67, 90, TRUE),
    (67, 111, TRUE),
    (67, 128, FALSE),
    (67, 165, TRUE),
    (67, 174, FALSE),
    (67, 176, TRUE),
    (68, 8, TRUE),
    (68, 15, TRUE),
    (68, 24, TRUE),
    (68, 46, TRUE),
    (68, 63, FALSE),
    (68, 107, TRUE),
    (68, 135, TRUE),
    (68, 141, TRUE),
    (68, 158, FALSE);
INSERT INTO PRESENCA (ID_AULA, ID_MATRICULA, IN_PRESENTE) VALUES
    (68, 178, TRUE),
    (69, 7, FALSE),
    (69, 52, TRUE),
    (69, 99, FALSE),
    (69, 142, TRUE),
    (69, 147, FALSE),
    (69, 181, TRUE),
    (69, 185, TRUE),
    (70, 12, TRUE),
    (70, 31, TRUE),
    (70, 39, FALSE),
    (70, 71, FALSE),
    (70, 80, TRUE),
    (70, 123, TRUE),
    (70, 184, TRUE),
    (70, 189, TRUE),
    (71, 20, TRUE),
    (71, 34, TRUE),
    (71, 62, TRUE),
    (71, 69, FALSE),
    (71, 76, TRUE),
    (71, 78, TRUE),
    (71, 88, TRUE),
    (71, 118, FALSE),
    (71, 139, TRUE),
    (71, 155, TRUE),
    (71, 162, TRUE),
    (72, 2, FALSE),
    (72, 9, TRUE),
    (72, 42, TRUE),
    (72, 48, FALSE),
    (72, 108, TRUE),
    (72, 127, TRUE),
    (72, 136, TRUE),
    (72, 144, FALSE),
    (72, 161, TRUE),
    (72, 179, TRUE),
    (73, 10, TRUE),
    (73, 18, FALSE),
    (73, 91, TRUE),
    (73, 112, TRUE),
    (73, 130, TRUE),
    (73, 170, TRUE),
    (73, 175, TRUE),
    (73, 187, TRUE),
    (74, 37, FALSE),
    (74, 51, TRUE),
    (74, 56, TRUE),
    (74, 96, FALSE),
    (74, 103, TRUE),
    (74, 113, FALSE),
    (74, 115, TRUE),
    (74, 149, TRUE),
    (74, 177, FALSE);

-- -------------------------------------------------------------------------------------
-- 4.11 PLANO (8) [RF04, RO01]
-- 4 ciclos (mensal, trimestral, semestral e anual) nas versões individual e Família.
-- O Família Anual ainda não tem nenhum contrato (cenário de plano sem venda).
-- -------------------------------------------------------------------------------------
INSERT INTO PLANO (ID_PLANO, NM_PLANO, QT_DURACAO_MESES, VL_MENSALIDADE, PC_DESCONTO, QT_MINIMA_PESSOAS, DS_CONDICAO) VALUES
    (1, 'Mensal', 1, 180.00, 0.00, NULL, 'Sem fidelidade; cancelamento a qualquer momento, sem multa. Atraso gera apenas bloqueio de acesso.'),
    (2, 'Trimestral', 3, 180.00, 5.00, NULL, 'Fidelidade de 3 meses. Multa de 2% por atraso. Cancelamento antecipado: multa de 20% sobre as mensalidades restantes.'),
    (3, 'Semestral', 6, 180.00, 10.00, NULL, 'Fidelidade de 6 meses. Multa de 2% por atraso. Cancelamento antecipado: multa de 20% sobre as mensalidades restantes.'),
    (4, 'Anual', 12, 180.00, 15.00, NULL, 'Fidelidade de 12 meses. Multa de 2% por atraso. Cancelamento antecipado: multa de 20% sobre as mensalidades restantes.'),
    (5, 'Família Mensal', 1, 180.00, 10.00, 2, 'Valor por pessoa; titular e dependentes no mesmo contrato. Sem fidelidade.'),
    (6, 'Família Trimestral', 3, 180.00, 15.00, 2, 'Valor por pessoa; fidelidade de 3 meses. Mesmas regras de multa do plano Trimestral.'),
    (7, 'Família Semestral', 6, 180.00, 20.00, 2, 'Valor por pessoa; fidelidade de 6 meses. Mesmas regras de multa do plano Semestral.'),
    (8, 'Família Anual', 12, 180.00, 25.00, 2, 'Valor por pessoa; fidelidade de 12 meses. Mesmas regras de multa do plano Anual.');

-- -------------------------------------------------------------------------------------
-- 4.12 CONTRATO (83) e PARTICIPA [RF04, RO01, RO04, RE04]
-- 77 contratos vigentes + 6 cancelados. VL_MENSAL_ACORDADO = valor do plano com desconto
-- (no Família, multiplicado pelo número de pessoas). Modalidade extra gera VL_ACRESCIMO_MODALIDADE (R$ 60,00 cada).
-- DT_FIM é o fim do ciclo atual: o contrato renova sozinho e só termina por cancelamento; quem já voltou
-- de trancamento teve o DT_FIM prorrogado pelos dias de afastamento (RE04).
-- Cenário de auditoria: o contrato 66 (Trimestral) foi cancelado antes do fim do ciclo sem multa (A08).
-- -------------------------------------------------------------------------------------
INSERT INTO CONTRATO (ID_CONTRATO, ID_ALUNO, ID_PLANO, DT_INICIO, DT_FIM, VL_MENSAL_ACORDADO, VL_ACRESCIMO_MODALIDADE, DT_CANCELAMENTO, VL_MULTA_RESCISORIA) VALUES
    (1, 1, 2, '2024-04-03', '2027-02-13', 171.00, NULL, NULL, NULL),
    (2, 2, 3, '2024-06-07', '2026-12-07', 162.00, NULL, NULL, NULL),
    (3, 3, 2, '2024-07-12', '2027-01-12', 171.00, 60.00, NULL, NULL),
    (4, 4, 3, '2024-08-05', '2027-02-05', 162.00, NULL, NULL, NULL),
    (5, 5, 2, '2024-10-04', '2027-01-04', 171.00, NULL, NULL, NULL),
    (6, 6, 3, '2024-10-25', '2027-04-25', 162.00, NULL, NULL, NULL),
    (7, 7, 2, '2024-11-12', '2026-11-12', 171.00, NULL, NULL, NULL),
    (8, 8, 3, '2024-11-24', '2026-11-24', 162.00, NULL, NULL, NULL),
    (9, 9, 3, '2024-11-28', '2026-11-28', 162.00, NULL, NULL, NULL),
    (10, 10, 1, '2024-12-16', '2026-11-16', 180.00, NULL, NULL, NULL),
    (11, 11, 1, '2024-12-20', '2026-11-20', 180.00, 60.00, NULL, NULL),
    (12, 12, 3, '2024-12-22', '2027-02-02', 162.00, NULL, NULL, NULL),
    (13, 13, 1, '2025-01-02', '2026-11-02', 180.00, NULL, NULL, NULL),
    (14, 14, 4, '2025-01-02', '2027-01-02', 153.00, NULL, NULL, NULL),
    (15, 15, 3, '2025-01-07', '2027-01-07', 162.00, NULL, NULL, NULL),
    (16, 16, 1, '2025-02-19', '2026-11-19', 180.00, NULL, NULL, NULL),
    (17, 17, 4, '2025-02-21', '2027-02-21', 153.00, NULL, NULL, NULL),
    (18, 18, 5, '2025-03-10', '2026-11-10', 486.00, NULL, NULL, NULL),
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
    (30, 32, 2, '2025-07-13', '2027-01-13', 171.00, NULL, NULL, NULL),
    (31, 33, 3, '2025-07-22', '2027-01-22', 162.00, 60.00, NULL, NULL),
    (32, 34, 1, '2025-07-22', '2026-11-22', 180.00, NULL, NULL, NULL),
    (33, 35, 3, '2025-07-28', '2027-01-28', 162.00, NULL, NULL, NULL),
    (34, 36, 6, '2025-08-04', '2026-11-04', 459.00, NULL, NULL, NULL),
    (35, 39, 1, '2025-08-16', '2026-11-16', 180.00, NULL, NULL, NULL),
    (36, 40, 2, '2025-09-01', '2026-12-01', 171.00, NULL, NULL, NULL),
    (37, 41, 4, '2025-09-18', '2027-09-18', 153.00, NULL, NULL, NULL),
    (38, 42, 2, '2025-10-10', '2027-01-10', 171.00, 60.00, NULL, NULL),
    (39, 43, 1, '2025-10-12', '2026-11-12', 180.00, NULL, NULL, NULL),
    (40, 44, 4, '2025-10-23', '2027-10-23', 153.00, NULL, NULL, NULL),
    (41, 45, 1, '2025-11-03', '2026-09-03', 180.00, NULL, '2026-08-20', NULL),
    (42, 46, 2, '2025-12-05', '2026-12-05', 171.00, NULL, NULL, NULL),
    (43, 47, 1, '2025-12-10', '2026-11-10', 180.00, NULL, NULL, NULL),
    (44, 48, 3, '2025-12-16', '2027-01-20', 162.00, 60.00, NULL, NULL),
    (45, 49, 2, '2025-12-30', '2026-12-30', 171.00, NULL, NULL, NULL),
    (46, 50, 1, '2026-01-02', '2026-11-02', 180.00, NULL, NULL, NULL),
    (47, 51, 4, '2026-01-05', '2027-01-05', 153.00, NULL, '2026-07-30', 214.20),
    (48, 52, 1, '2026-01-05', '2026-11-05', 180.00, NULL, NULL, NULL),
    (49, 53, 1, '2026-01-25', '2026-11-25', 180.00, NULL, NULL, NULL),
    (50, 54, 7, '2026-02-02', '2027-02-02', 432.00, NULL, NULL, NULL),
    (51, 57, 3, '2026-02-08', '2027-02-08', 162.00, NULL, NULL, NULL),
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
    (63, 69, 1, '2026-04-26', '2026-11-26', 180.00, NULL, NULL, NULL),
    (64, 70, 3, '2026-05-04', '2026-11-04', 162.00, NULL, '2026-09-03', 64.80),
    (65, 71, 5, '2026-05-11', '2026-11-11', 324.00, NULL, NULL, NULL),
    (66, 73, 2, '2026-06-01', '2026-09-01', 171.00, NULL, '2026-08-14', NULL),
    (67, 74, 1, '2026-06-03', '2026-11-03', 180.00, NULL, NULL, NULL),
    (68, 75, 1, '2026-06-11', '2026-11-11', 180.00, NULL, NULL, NULL),
    (69, 76, 2, '2026-06-13', '2026-12-13', 171.00, 60.00, NULL, NULL),
    (70, 77, 6, '2026-07-06', '2027-01-06', 306.00, NULL, NULL, NULL),
    (71, 79, 1, '2026-07-15', '2026-11-15', 180.00, 60.00, NULL, NULL),
    (72, 80, 1, '2026-07-26', '2026-11-26', 180.00, NULL, NULL, NULL),
    (73, 81, 1, '2026-08-23', '2026-11-23', 180.00, NULL, NULL, NULL),
    (74, 82, 4, '2026-09-03', '2027-09-03', 153.00, NULL, NULL, NULL),
    (75, 83, 2, '2026-09-11', '2026-12-11', 171.00, NULL, NULL, NULL),
    (76, 84, 1, '2026-09-21', '2026-11-21', 180.00, NULL, NULL, NULL),
    (77, 85, 4, '2026-09-27', '2027-09-27', 153.00, NULL, NULL, NULL),
    (78, 86, 1, '2026-10-06', '2026-11-06', 180.00, NULL, NULL, NULL),
    (79, 87, 1, '2026-10-07', '2026-11-07', 180.00, NULL, NULL, NULL),
    (80, 88, 4, '2026-10-07', '2027-10-07', 153.00, NULL, NULL, NULL),
    (81, 89, 1, '2026-10-11', '2026-11-11', 180.00, NULL, NULL, NULL),
    (82, 90, 3, '2026-10-15', '2027-04-15', 162.00, NULL, NULL, NULL),
    (83, 91, 1, '2026-10-15', '2026-11-15', 180.00, NULL, NULL, NULL);

INSERT INTO PARTICIPA (ID_MODALIDADE, ID_CONTRATO) VALUES
    (1, 1),
    (1, 2),
    (2, 3),
    (3, 3),
    (6, 4),
    (1, 5),
    (4, 6),
    (2, 7),
    (1, 8),
    (4, 9),
    (3, 10),
    (2, 11),
    (5, 11),
    (1, 12),
    (4, 13),
    (3, 14),
    (1, 15),
    (3, 16),
    (2, 17),
    (3, 18),
    (5, 18),
    (2, 19),
    (1, 20),
    (5, 21),
    (1, 22),
    (1, 23),
    (3, 24),
    (5, 25),
    (6, 25),
    (5, 26),
    (4, 27),
    (5, 27),
    (6, 28),
    (2, 29),
    (3, 30),
    (1, 31),
    (2, 31),
    (3, 32),
    (3, 33),
    (2, 34),
    (3, 34),
    (3, 35),
    (2, 36),
    (3, 37),
    (3, 38),
    (5, 38),
    (3, 39),
    (4, 40),
    (5, 41),
    (1, 42),
    (5, 43),
    (4, 44),
    (6, 44),
    (1, 45),
    (5, 46),
    (2, 47),
    (1, 48),
    (3, 49),
    (4, 50),
    (5, 50),
    (3, 51),
    (3, 52),
    (4, 52),
    (2, 53),
    (2, 54),
    (1, 55),
    (4, 55),
    (4, 56),
    (1, 57),
    (3, 58),
    (1, 59),
    (2, 60),
    (3, 61),
    (1, 62),
    (6, 62),
    (1, 63),
    (5, 64),
    (5, 65),
    (6, 65),
    (1, 66),
    (3, 67),
    (3, 68),
    (2, 69),
    (3, 69),
    (1, 70),
    (3, 70),
    (1, 71),
    (4, 71),
    (1, 72),
    (3, 73),
    (4, 74),
    (4, 75),
    (5, 76),
    (1, 77),
    (3, 78),
    (6, 79),
    (2, 80),
    (6, 81),
    (4, 82),
    (2, 83);

-- -------------------------------------------------------------------------------------
-- 4.13 PAGAMENTO (293) [RF04, RO02, RO04, RO06, RE07]
-- Parcelas de ago/2026 a nov/2026 (os 3 últimos meses fechados + o mês corrente), vencimento no 5º dia útil:
-- 07/08, 08/09, 07/10 e 09/11 (RO02). Quem assina depois do vencimento do mês paga a 1ª parcela, com valor
-- integral e o mesmo vencimento do 5º dia útil, no ato da assinatura (DT_PAGAMENTO = data do contrato).
-- Meses em que o aluno estava trancado não geram parcela. Multa de 2% só nos planos de mais de 1 mês.
-- 213 PAGO, 11 ATRASADO, 69 PENDENTE (quase todas de novembro, que ainda vai vencer).
-- Formas de pagamento: Pix, crédito e débito. Taxa de exame de faixa (R$ 60,00) cobrada na parcela seguinte ao exame.
-- Cenários de auditoria: parcela de outubro do contrato 14 ainda PENDENTE depois de vencida (A07);
-- parcela de setembro do contrato 3 paga com R$ 20,00 a menos (A10).
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
    (16, 17, '2026-08-07', '2026-08-03', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (17, 18, '2026-08-07', '2026-08-05', 486.00, 486.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (18, 19, '2026-08-07', '2026-08-06', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (19, 20, '2026-08-07', '2026-08-01', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (20, 21, '2026-08-07', '2026-08-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (21, 22, '2026-08-07', '2026-08-03', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (22, 23, '2026-08-07', '2026-08-03', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (23, 24, '2026-08-07', '2026-08-04', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (24, 25, '2026-08-07', '2026-08-07', 231.00, 231.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (25, 26, '2026-08-07', '2026-08-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (26, 27, '2026-08-07', '2026-08-05', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (27, 28, '2026-08-07', '2026-08-01', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (28, 29, '2026-08-07', '2026-08-02', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (29, 30, '2026-08-07', '2026-08-02', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (30, 31, '2026-08-07', '2026-08-01', 222.00, 222.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (31, 32, '2026-08-07', '2026-08-02', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (32, 33, '2026-08-07', '2026-08-14', 162.00, 165.24, 'DEBITO', 3.24, NULL, 'PAGO'),
    (33, 34, '2026-08-07', '2026-08-05', 459.00, 459.00, 'DEBITO', NULL, NULL, 'PAGO'),
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
    (48, 50, '2026-08-07', '2026-08-02', 432.00, 432.00, 'PIX', NULL, NULL, 'PAGO'),
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
    (60, 62, '2026-08-07', '2026-08-09', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (61, 63, '2026-08-07', '2026-08-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (62, 64, '2026-08-07', '2026-08-02', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (63, 65, '2026-08-07', '2026-08-01', 324.00, 324.00, 'PIX', NULL, NULL, 'PAGO'),
    (64, 66, '2026-08-07', '2026-08-01', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (65, 67, '2026-08-07', '2026-08-09', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (66, 68, '2026-08-07', '2026-08-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (67, 69, '2026-08-07', '2026-08-15', 231.00, 235.62, 'PIX', 4.62, NULL, 'PAGO'),
    (68, 70, '2026-08-07', '2026-08-01', 306.00, 306.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (69, 71, '2026-08-07', '2026-08-13', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (70, 72, '2026-08-07', '2026-08-04', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (71, 73, '2026-08-07', '2026-08-23', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (72, 1, '2026-09-08', '2026-09-03', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (73, 2, '2026-09-08', '2026-09-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (74, 3, '2026-09-08', '2026-09-06', 231.00, 211.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (75, 4, '2026-09-08', '2026-09-04', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (76, 5, '2026-09-08', '2026-09-05', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (77, 6, '2026-09-08', '2026-09-03', 162.00, 162.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (78, 7, '2026-09-08', '2026-09-02', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (79, 8, '2026-09-08', '2026-09-17', 162.00, 165.24, 'CREDITO', 3.24, NULL, 'PAGO'),
    (80, 9, '2026-09-08', '2026-09-04', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO');
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (81, 10, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (82, 11, '2026-09-08', '2026-09-08', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (83, 12, '2026-09-08', '2026-09-08', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (84, 13, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (85, 14, '2026-09-08', '2026-09-07', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (86, 15, '2026-09-08', '2026-09-14', 162.00, 165.24, 'PIX', 3.24, NULL, 'PAGO'),
    (87, 16, '2026-09-08', '2026-09-16', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (88, 17, '2026-09-08', '2026-09-03', 153.00, 213.00, 'PIX', NULL, 60.00, 'PAGO'),
    (89, 18, '2026-09-08', '2026-09-04', 486.00, 486.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (90, 19, '2026-09-08', '2026-09-07', 180.00, 240.00, 'CREDITO', NULL, 60.00, 'PAGO'),
    (91, 20, '2026-09-08', '2026-09-15', 153.00, 156.06, 'PIX', 3.06, NULL, 'PAGO'),
    (92, 21, '2026-09-08', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (93, 22, '2026-09-08', '2026-09-02', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (94, 23, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (95, 24, '2026-09-08', '2026-09-07', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (96, 25, '2026-09-08', '2026-09-06', 231.00, 291.00, 'DEBITO', NULL, 60.00, 'PAGO'),
    (97, 26, '2026-09-08', '2026-09-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (98, 27, '2026-09-08', '2026-09-03', 231.00, 291.00, 'PIX', NULL, 60.00, 'PAGO'),
    (99, 28, '2026-09-08', '2026-09-02', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (100, 29, '2026-09-08', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (101, 30, '2026-09-08', '2026-09-08', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (102, 31, '2026-09-08', '2026-09-03', 222.00, 222.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (103, 32, '2026-09-08', '2026-09-07', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (104, 33, '2026-09-08', '2026-09-08', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (105, 34, '2026-09-08', '2026-09-05', 459.00, 459.00, 'PIX', NULL, NULL, 'PAGO'),
    (106, 35, '2026-09-08', '2026-09-09', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (107, 36, '2026-09-08', '2026-09-04', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (108, 37, '2026-09-08', '2026-09-03', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (109, 38, '2026-09-08', '2026-09-06', 231.00, 231.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (110, 39, '2026-09-08', '2026-09-08', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (111, 40, '2026-09-08', '2026-09-04', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (112, 42, '2026-09-08', '2026-09-07', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (113, 43, '2026-09-08', '2026-09-11', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (114, 44, '2026-09-08', '2026-09-05', 222.00, 222.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (115, 45, '2026-09-08', '2026-09-07', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (116, 46, '2026-09-08', '2026-09-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (117, 48, '2026-09-08', '2026-09-03', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (118, 49, '2026-09-08', '2026-09-08', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (119, 50, '2026-09-08', '2026-09-07', 432.00, 432.00, 'PIX', NULL, NULL, 'PAGO'),
    (120, 51, '2026-09-08', '2026-09-08', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (121, 52, '2026-09-08', '2026-09-07', 222.00, 222.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (122, 53, '2026-09-08', '2026-09-08', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (123, 54, '2026-09-08', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (124, 55, '2026-09-08', '2026-09-04', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (125, 56, '2026-09-08', '2026-09-07', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (126, 57, '2026-09-08', '2026-09-11', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (127, 58, '2026-09-08', '2026-09-04', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (128, 59, '2026-09-08', '2026-09-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (129, 60, '2026-09-08', '2026-09-05', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (130, 61, '2026-09-08', '2026-09-07', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (131, 62, '2026-09-08', '2026-09-07', 240.00, 300.00, 'DEBITO', NULL, 60.00, 'PAGO'),
    (132, 63, '2026-09-08', '2026-09-04', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (133, 65, '2026-09-08', '2026-09-03', 324.00, 324.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (134, 67, '2026-09-08', '2026-09-06', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (135, 68, '2026-09-08', '2026-09-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (136, 69, '2026-09-08', '2026-09-05', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (137, 70, '2026-09-08', '2026-09-06', 306.00, 306.00, 'PIX', NULL, NULL, 'PAGO'),
    (138, 71, '2026-09-08', '2026-09-02', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (139, 72, '2026-09-08', '2026-09-11', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (140, 73, '2026-09-08', '2026-09-04', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (141, 74, '2026-09-08', '2026-09-08', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (142, 75, '2026-09-08', '2026-09-11', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (143, 76, '2026-09-08', '2026-09-21', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (144, 77, '2026-09-08', '2026-09-27', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (145, 1, '2026-10-07', '2026-10-03', 171.00, 231.00, 'CREDITO', NULL, 60.00, 'PAGO'),
    (146, 2, '2026-10-07', '2026-10-15', 162.00, 165.24, 'DEBITO', 3.24, NULL, 'PAGO'),
    (147, 3, '2026-10-07', '2026-10-03', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (148, 4, '2026-10-07', '2026-10-12', 162.00, 165.24, 'PIX', 3.24, NULL, 'PAGO'),
    (149, 5, '2026-10-07', '2026-10-11', 171.00, 174.42, 'PIX', 3.42, NULL, 'PAGO'),
    (150, 6, '2026-10-07', '2026-10-15', 162.00, 165.24, 'PIX', 3.24, NULL, 'PAGO'),
    (151, 7, '2026-10-07', '2026-10-05', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (152, 8, '2026-10-07', '2026-10-16', 162.00, 165.24, 'DEBITO', 3.24, NULL, 'PAGO'),
    (153, 9, '2026-10-07', '2026-10-06', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (154, 10, '2026-10-07', '2026-10-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (155, 11, '2026-10-07', '2026-10-01', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (156, 12, '2026-10-07', '2026-10-05', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (157, 13, '2026-10-07', '2026-10-04', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (158, 14, '2026-10-07', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (159, 16, '2026-10-07', '2026-10-07', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (160, 17, '2026-10-07', '2026-10-02', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO');
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (161, 18, '2026-10-07', '2026-10-04', 486.00, 486.00, 'PIX', NULL, NULL, 'PAGO'),
    (162, 19, '2026-10-07', '2026-10-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (163, 20, '2026-10-07', '2026-10-04', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (164, 21, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (165, 22, '2026-10-07', '2026-10-02', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (166, 23, '2026-10-07', '2026-10-01', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (167, 24, '2026-10-07', '2026-10-07', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (168, 25, '2026-10-07', '2026-10-01', 231.00, 351.00, 'CREDITO', NULL, 120.00, 'PAGO'),
    (169, 27, '2026-10-07', '2026-10-06', 231.00, 231.00, 'PIX', NULL, NULL, 'PAGO'),
    (170, 28, '2026-10-07', NULL, 153.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (171, 29, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (172, 30, '2026-10-07', '2026-10-06', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (173, 31, '2026-10-07', '2026-10-15', 222.00, 226.44, 'PIX', 4.44, NULL, 'PAGO'),
    (174, 32, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (175, 33, '2026-10-07', '2026-10-07', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (176, 34, '2026-10-07', '2026-10-02', 459.00, 519.00, 'PIX', NULL, 60.00, 'PAGO'),
    (177, 35, '2026-10-07', '2026-10-06', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (178, 36, '2026-10-07', '2026-10-01', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (179, 37, '2026-10-07', '2026-10-07', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (180, 38, '2026-10-07', '2026-10-03', 231.00, 291.00, 'PIX', NULL, 60.00, 'PAGO'),
    (181, 39, '2026-10-07', '2026-10-05', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (182, 40, '2026-10-07', '2026-10-03', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (183, 42, '2026-10-07', '2026-10-03', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (184, 43, '2026-10-07', '2026-10-02', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (185, 44, '2026-10-07', '2026-10-02', 222.00, 222.00, 'PIX', NULL, NULL, 'PAGO'),
    (186, 45, '2026-10-07', '2026-10-06', 171.00, 171.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (187, 46, '2026-10-07', '2026-10-16', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (188, 48, '2026-10-07', '2026-10-07', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (189, 49, '2026-10-07', '2026-10-01', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (190, 50, '2026-10-07', '2026-10-02', 432.00, 432.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (191, 51, '2026-10-07', '2026-10-05', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (192, 52, '2026-10-07', NULL, 222.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (193, 53, '2026-10-07', '2026-10-15', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (194, 55, '2026-10-07', '2026-10-05', 231.00, 231.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (195, 56, '2026-10-07', '2026-10-01', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (196, 57, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (197, 59, '2026-10-07', '2026-10-13', 180.00, 180.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (198, 60, '2026-10-07', '2026-10-04', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (199, 61, '2026-10-07', '2026-10-03', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (200, 62, '2026-10-07', '2026-10-01', 240.00, 240.00, 'PIX', NULL, NULL, 'PAGO'),
    (201, 63, '2026-10-07', '2026-10-06', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (202, 65, '2026-10-07', '2026-10-04', 324.00, 324.00, 'PIX', NULL, NULL, 'PAGO'),
    (203, 67, '2026-10-07', '2026-10-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (204, 68, '2026-10-07', '2026-10-06', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (205, 69, '2026-10-07', NULL, 231.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (206, 70, '2026-10-07', '2026-10-03', 306.00, 306.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (207, 71, '2026-10-07', '2026-10-04', 240.00, 240.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (208, 72, '2026-10-07', NULL, 180.00, NULL, NULL, NULL, NULL, 'ATRASADO'),
    (209, 73, '2026-10-07', '2026-10-05', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (210, 74, '2026-10-07', '2026-10-07', 153.00, 153.00, 'DEBITO', NULL, NULL, 'PAGO'),
    (211, 75, '2026-10-07', '2026-10-01', 171.00, 171.00, 'PIX', NULL, NULL, 'PAGO'),
    (212, 76, '2026-10-07', '2026-10-16', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (213, 77, '2026-10-07', '2026-10-15', 153.00, 156.06, 'PIX', 3.06, NULL, 'PAGO'),
    (214, 78, '2026-10-07', '2026-10-02', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (215, 79, '2026-10-07', '2026-10-03', 180.00, 180.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (216, 80, '2026-10-07', '2026-10-02', 153.00, 153.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (217, 81, '2026-10-07', '2026-10-11', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (218, 82, '2026-10-07', '2026-10-15', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (219, 83, '2026-10-07', '2026-10-15', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (220, 1, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (221, 2, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (222, 3, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (223, 4, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (224, 5, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (225, 6, '2026-11-09', '2026-10-31', 162.00, 162.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (226, 7, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (227, 8, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (228, 9, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (229, 10, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (230, 11, '2026-11-09', NULL, 240.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (231, 12, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (232, 13, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (233, 14, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (234, 17, '2026-11-09', '2026-10-29', 153.00, 153.00, 'PIX', NULL, NULL, 'PAGO'),
    (235, 18, '2026-11-09', NULL, 486.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (236, 19, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (237, 20, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (238, 21, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (239, 22, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (240, 23, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE');
INSERT INTO PAGAMENTO (ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_PAGO, TP_FORMA_PAGAMENTO, VL_MULTA, VL_TAXA_GRADUACAO, TP_STATUS_PAGAMENTO) VALUES
    (241, 24, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (242, 25, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (243, 27, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (244, 28, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (245, 29, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (246, 30, '2026-11-09', '2026-10-29', 171.00, 171.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (247, 31, '2026-11-09', NULL, 222.00, NULL, NULL, NULL, 60.00, 'PENDENTE'),
    (248, 32, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (249, 33, '2026-11-09', '2026-10-29', 162.00, 162.00, 'PIX', NULL, NULL, 'PAGO'),
    (250, 34, '2026-11-09', NULL, 459.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (251, 35, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (252, 36, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (253, 37, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (254, 38, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, 60.00, 'PENDENTE'),
    (255, 39, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (256, 40, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (257, 42, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (258, 43, '2026-11-09', '2026-10-30', 180.00, 180.00, 'PIX', NULL, NULL, 'PAGO'),
    (259, 44, '2026-11-09', NULL, 222.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (260, 45, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (261, 46, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (262, 48, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (263, 49, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (264, 50, '2026-11-09', NULL, 432.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (265, 51, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, 60.00, 'PENDENTE'),
    (266, 52, '2026-11-09', NULL, 222.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (267, 53, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (268, 55, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (269, 56, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (270, 57, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (271, 59, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, 60.00, 'PENDENTE'),
    (272, 60, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (273, 61, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (274, 62, '2026-11-09', '2026-10-28', 240.00, 240.00, 'CREDITO', NULL, NULL, 'PAGO'),
    (275, 63, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (276, 65, '2026-11-09', NULL, 324.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (277, 67, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (278, 68, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (279, 69, '2026-11-09', NULL, 231.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (280, 70, '2026-11-09', NULL, 306.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (281, 71, '2026-11-09', NULL, 240.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (282, 72, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (283, 73, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (284, 74, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (285, 75, '2026-11-09', NULL, 171.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (286, 76, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (287, 77, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (288, 78, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (289, 79, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (290, 80, '2026-11-09', NULL, 153.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (291, 81, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (292, 82, '2026-11-09', NULL, 162.00, NULL, NULL, NULL, NULL, 'PENDENTE'),
    (293, 83, '2026-11-09', NULL, 180.00, NULL, NULL, NULL, NULL, 'PENDENTE');

-- -------------------------------------------------------------------------------------
-- 4.14 GRADUACAO (28) [RF06, RO05, RO06]
-- Exames de faixa trimestrais (dez/2025 a out/2026) e análises técnicas de Boxe, com aprovações e reprovações.
-- 1 aluno(s) reprovado(s) em junho refizeram o exame em setembro e foram aprovados.
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
    (14, 21, 2, 2, NULL, '2026-08-22', 'Faixa Amarela', 'EXAME_FAIXA', 'APROVADO'),
    (15, 27, 5, 5, NULL, '2026-08-22', 'Corda Crua', 'EXAME_FAIXA', 'APROVADO'),
    (16, 29, 5, 5, NULL, '2026-08-22', 'Corda Crua', 'EXAME_FAIXA', 'APROVADO'),
    (17, 68, 6, 6, NULL, '2026-08-22', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (18, 54, 4, 4, 'condicionamento', '2026-08-29', NULL, 'ANALISE_TECNICA', 'REPROVADO'),
    (19, 1, 1, 1, NULL, '2026-09-19', 'Prajied Branco', 'EXAME_FAIXA', 'APROVADO'),
    (20, 27, 6, 6, NULL, '2026-09-19', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (21, 27, 6, 6, NULL, '2026-09-19', 'Faixa Branca 4º grau', 'EXAME_FAIXA', 'APROVADO'),
    (22, 36, 2, 2, NULL, '2026-09-19', 'Faixa Amarela', 'EXAME_FAIXA', 'APROVADO'),
    (23, 42, 5, 5, NULL, '2026-09-19', 'Corda Crua', 'EXAME_FAIXA', 'APROVADO'),
    (24, 33, 1, 1, NULL, '2026-10-17', 'Prajied Branco', 'EXAME_FAIXA', 'APROVADO'),
    (25, 42, 3, 3, NULL, '2026-10-17', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (26, 57, 3, 3, NULL, '2026-10-17', 'Faixa Branca 2º grau', 'EXAME_FAIXA', 'APROVADO'),
    (27, 65, 1, 1, 'controle de distância', '2026-10-17', 'Prajied Branco', 'EXAME_FAIXA', 'REPROVADO'),
    (28, 61, 4, 4, NULL, '2026-10-24', NULL, 'ANALISE_TECNICA', 'APROVADO');

-- -------------------------------------------------------------------------------------
-- 4.15 DESPESA (50) [RF04, RO07]
-- Despesas fixas mensais (aluguel, água, luz, internet), compras semanais de higiene/limpeza feitas pelo gestor,
-- compras de equipamento, manutenção e o repasse aos 5 professores prestadores de serviço (aulas x R$ 80,00),
-- pago no 5º dia útil do mês seguinte (RO07). O gestor não recebe repasse. O repasse de outubro bate com as
-- aulas registradas na tabela AULA.
-- Há uma despesa ATRASADO (manutenção do ar-condicionado) e as de novembro estão PENDENTE.
-- -------------------------------------------------------------------------------------
INSERT INTO DESPESA (ID_DESPESA, ID_PROFESSOR, DS_CATEGORIA, VL_DESPESA, DT_VENCIMENTO, DT_PAGAMENTO, VL_PAGO, DS_DESCRICAO, NM_CREDOR, TP_SITUACAO_DESPESA) VALUES
    (1, NULL, 'COMPRAS', 234.19, '2026-08-04', '2026-08-04', 234.19, 'Reposição semanal de higiene e limpeza (1ª semana de ago)', 'Atacadão Limpa Bem', 'PAGO'),
    (2, 2, 'PROFESSORES', 1120.00, '2026-08-07', '2026-08-07', 1120.00, 'Repasse de 14 aulas ministradas em jul/2026', 'Carolina Nunes Carvalho', 'PAGO'),
    (3, 3, 'PROFESSORES', 1440.00, '2026-08-07', '2026-08-07', 1440.00, 'Repasse de 18 aulas ministradas em jul/2026', 'Fábio Macedo Freitas', 'PAGO'),
    (4, 4, 'PROFESSORES', 960.00, '2026-08-07', '2026-08-07', 960.00, 'Repasse de 12 aulas ministradas em jul/2026', 'Jonas Mendes Nunes', 'PAGO'),
    (5, 5, 'PROFESSORES', 720.00, '2026-08-07', '2026-08-07', 720.00, 'Repasse de 9 aulas ministradas em jul/2026', 'Igor Machado Cardoso', 'PAGO'),
    (6, 6, 'PROFESSORES', 320.00, '2026-08-07', '2026-08-07', 320.00, 'Repasse de 4 aulas ministradas em jul/2026', 'Gabriela Vieira Rodrigues', 'PAGO'),
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
    (17, 3, 'PROFESSORES', 1360.00, '2026-09-08', '2026-09-08', 1360.00, 'Repasse de 17 aulas ministradas em ago/2026', 'Fábio Macedo Freitas', 'PAGO'),
    (18, 4, 'PROFESSORES', 1040.00, '2026-09-08', '2026-09-08', 1040.00, 'Repasse de 13 aulas ministradas em ago/2026', 'Jonas Mendes Nunes', 'PAGO'),
    (19, 5, 'PROFESSORES', 720.00, '2026-09-08', '2026-09-08', 720.00, 'Repasse de 9 aulas ministradas em ago/2026', 'Igor Machado Cardoso', 'PAGO'),
    (20, 6, 'PROFESSORES', 320.00, '2026-09-08', '2026-09-08', 320.00, 'Repasse de 4 aulas ministradas em ago/2026', 'Gabriela Vieira Rodrigues', 'PAGO'),
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
    (32, 3, 'PROFESSORES', 1360.00, '2026-10-07', '2026-10-07', 1360.00, 'Repasse de 17 aulas ministradas em set/2026', 'Fábio Macedo Freitas', 'PAGO'),
    (33, 4, 'PROFESSORES', 1040.00, '2026-10-07', '2026-10-07', 1040.00, 'Repasse de 13 aulas ministradas em set/2026', 'Jonas Mendes Nunes', 'PAGO'),
    (34, 5, 'PROFESSORES', 720.00, '2026-10-07', '2026-10-07', 720.00, 'Repasse de 9 aulas ministradas em set/2026', 'Igor Machado Cardoso', 'PAGO'),
    (35, 6, 'PROFESSORES', 320.00, '2026-10-07', '2026-10-07', 320.00, 'Repasse de 4 aulas ministradas em set/2026', 'Gabriela Vieira Rodrigues', 'PAGO'),
    (36, NULL, 'ALUGUEL', 3500.00, '2026-10-10', '2026-10-10', 3500.00, 'Aluguel do galpão - out/2026', 'Imobiliária Horizonte Leste Ltda', 'PAGO'),
    (37, NULL, 'CONSUMO', 119.90, '2026-10-12', '2026-10-12', 119.90, 'Internet e telefone - out/2026', 'Provedor NetLeste', 'PAGO'),
    (38, NULL, 'COMPRAS', 243.35, '2026-10-13', '2026-10-13', 243.35, 'Reposição semanal de higiene e limpeza (2ª semana de out)', 'Mercado Bom Preço', 'PAGO'),
    (39, NULL, 'CONSUMO', 198.44, '2026-10-15', '2026-10-13', 198.44, 'Conta de água - out/2026', 'Companhia de Saneamento', 'PAGO'),
    (40, NULL, 'COMPRAS', 206.64, '2026-10-20', '2026-10-20', 206.64, 'Reposição semanal de higiene e limpeza (3ª semana de out)', 'Atacadão Limpa Bem', 'PAGO'),
    (41, NULL, 'CONSUMO', 449.61, '2026-10-20', '2026-10-20', 449.61, 'Conta de energia elétrica - out/2026', 'Distribuidora de Energia', 'PAGO'),
    (42, NULL, 'MANUTENCAO', 380.00, '2026-10-25', NULL, NULL, 'Manutenção preventiva do ar-condicionado', 'Clima Frio Refrigeração', 'ATRASADO'),
    (43, NULL, 'COMPRAS', 156.88, '2026-10-27', '2026-10-27', 156.88, 'Reposição semanal de higiene e limpeza (4ª semana de out)', 'Mercado Bom Preço', 'PAGO'),
    (44, 2, 'PROFESSORES', 880.00, '2026-11-09', NULL, NULL, 'Repasse de 11 aulas ministradas em out/2026', 'Carolina Nunes Carvalho', 'PENDENTE'),
    (45, 3, 'PROFESSORES', 1280.00, '2026-11-09', NULL, NULL, 'Repasse de 16 aulas ministradas em out/2026', 'Fábio Macedo Freitas', 'PENDENTE'),
    (46, 4, 'PROFESSORES', 1200.00, '2026-11-09', NULL, NULL, 'Repasse de 15 aulas ministradas em out/2026', 'Jonas Mendes Nunes', 'PENDENTE'),
    (47, 5, 'PROFESSORES', 720.00, '2026-11-09', NULL, NULL, 'Repasse de 9 aulas ministradas em out/2026', 'Igor Machado Cardoso', 'PENDENTE'),
    (48, 6, 'PROFESSORES', 400.00, '2026-11-09', NULL, NULL, 'Repasse de 5 aulas ministradas em out/2026', 'Gabriela Vieira Rodrigues', 'PENDENTE'),
    (49, NULL, 'ALUGUEL', 3500.00, '2026-11-10', NULL, NULL, 'Aluguel do galpão - nov/2026', 'Imobiliária Horizonte Leste Ltda', 'PENDENTE'),
    (50, NULL, 'CONSUMO', 119.90, '2026-11-12', NULL, NULL, 'Internet e telefone - nov/2026', 'Provedor NetLeste', 'PENDENTE');

-- -------------------------------------------------------------------------------------
-- 4.16 LOG_ACESSO (20) [RNF02]
-- Amostra de acessos de outubro: leitura de CPF e de problema de saúde, criações e atualizações.
-- Em produção quem grava o log é a aplicação; aqui os registros são inseridos manualmente.
-- -------------------------------------------------------------------------------------
INSERT INTO LOG_ACESSO (ID_LOG, NM_USUARIO, TP_PERFIL, DT_ACESSO, TP_OPERACAO, NM_TABELA, ID_REGISTRO, NM_CAMPO) VALUES
    (1, 'admin.gestor', 'ADMINISTRACAO', '2026-10-01 08:12:40', 'CRIACAO', 'PAGAMENTO', 145, NULL),
    (2, 'admin.gestor', 'ADMINISTRACAO', '2026-10-02 18:40:05', 'LEITURA', 'ALUNO', 80, 'CPF'),
    (3, 'admin.gestor', 'ADMINISTRACAO', '2026-10-05 10:03:18', 'CRIACAO', 'TRANCAMENTO', 5, NULL),
    (4, 'prof.jiujitsu', 'PROFESSOR', '2026-10-05 19:55:31', 'LEITURA', 'PROBLEMA_SAUDE_ALUNO', 81, 'DS_PROBLEMA_SAUDE'),
    (5, 'admin.gestor', 'ADMINISTRACAO', '2026-10-08 09:20:11', 'ATUALIZACAO', 'PAGAMENTO', 146, 'TP_STATUS_PAGAMENTO'),
    (6, 'prof.kickboxing', 'PROFESSOR', '2026-10-09 18:05:47', 'CRIACAO', 'AULA', 21, NULL),
    (7, 'prof.capoeira', 'PROFESSOR', '2026-10-10 14:02:09', 'CRIACAO', 'INTERESSADO', 12, NULL),
    (8, 'admin.gestor', 'ADMINISTRACAO', '2026-10-13 11:45:00', 'LEITURA', 'ALUNO', 40, 'CPF'),
    (9, 'prof.boxe', 'PROFESSOR', '2026-10-15 18:10:22', 'LEITURA', 'PROBLEMA_SAUDE_ALUNO', 11, 'DS_PROBLEMA_SAUDE'),
    (10, 'admin.gestor', 'ADMINISTRACAO', '2026-10-17 12:30:54', 'CRIACAO', 'GRADUACAO', 24, NULL),
    (11, 'admin.gestor', 'ADMINISTRACAO', '2026-10-19 08:58:13', 'ATUALIZACAO', 'ALUNO', 8, 'NM_BAIRRO'),
    (12, 'prof.muaythai', 'PROFESSOR', '2026-10-20 07:05:39', 'CRIACAO', 'AULA', 43, NULL),
    (13, 'admin.gestor', 'ADMINISTRACAO', '2026-10-20 16:21:07', 'CRIACAO', 'TRANCAMENTO', 6, NULL),
    (14, 'admin.gestor', 'ADMINISTRACAO', '2026-10-22 10:14:28', 'LEITURA', 'RESPONSAVEL', 1, 'CPF'),
    (15, 'prof.nogi', 'PROFESSOR', '2026-10-22 20:07:51', 'ATUALIZACAO', 'PRESENCA', 49, 'IN_PRESENTE'),
    (16, 'admin.gestor', 'ADMINISTRACAO', '2026-10-26 09:33:02', 'ATUALIZACAO', 'CONTRATO', 3, 'VL_ACRESCIMO_MODALIDADE'),
    (17, 'admin.gestor', 'ADMINISTRACAO', '2026-10-28 17:48:36', 'CRIACAO', 'ALUNO', 92, NULL),
    (18, 'admin.gestor', 'ADMINISTRACAO', '2026-10-28 17:52:10', 'CRIACAO', 'MATRICULA', 190, NULL),
    (19, 'admin.gestor', 'ADMINISTRACAO', '2026-10-30 08:40:44', 'LEITURA', 'PROBLEMA_SAUDE_ALUNO', 45, 'DS_PROBLEMA_SAUDE'),
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
-- Atende: RF01 e RE03 (menor de 18 anos com responsável e atestado)
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
-- Regra: planos de fidelidade (mais de 1 mês) pagam multa moratória de 2% [RO04];
-- o plano mensal não teria multa, só o bloqueio.
-- Consequência: a parcela sai de ATRASADO e o aluno é desbloqueado [RE07]
-- (as consultas G04 e A02 mudam).

-- Antes
SELECT ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, VL_DEVIDO, VL_MULTA, VL_PAGO, TP_STATUS_PAGAMENTO
FROM PAGAMENTO
WHERE ID_PAGAMENTO = 170;

UPDATE PAGAMENTO
SET TP_STATUS_PAGAMENTO = 'PAGO',
    DT_PAGAMENTO        = @DT_REF,
    TP_FORMA_PAGAMENTO  = 'PIX',
    VL_MULTA            = ROUND(VL_DEVIDO * 0.02, 2),
    VL_PAGO             = VL_DEVIDO + ROUND(VL_DEVIDO * 0.02, 2) + COALESCE(VL_TAXA_GRADUACAO, 0)
WHERE ID_PAGAMENTO = 170
  AND TP_STATUS_PAGAMENTO = 'ATRASADO';

-- Depois
SELECT ID_PAGAMENTO, ID_CONTRATO, DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO, VL_MULTA, VL_PAGO,
       TP_FORMA_PAGAMENTO, TP_STATUS_PAGAMENTO
FROM PAGAMENTO
WHERE ID_PAGAMENTO = 170;

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
WHERE ID_MATRICULA = 133
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
--   3) registrar a operação no log (sem trigger: quem grava é a aplicação).
-- [RE06, RNF05] Matrículas encerradas, CONTRATO, PAGAMENTO e DESPESA nunca são excluídos
-- (histórico e retenção fiscal de 5 anos); o aluno é "excluído" logicamente (INATIVO).
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
-- Atende: KPI de Receita por Modalidade [RF04, RO01: rateio das modalidades do contrato]
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
-- Atende: KPI de Receita Mensal (previsto x realizado) [RF04, RO02: uma parcela por mês]
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
-- Atende: KPI de Taxa de Inadimplência [RF04, RE07: inadimplência derivada das parcelas]
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
-- Atende: Lista de cobrança e de bloqueio na recepção/catraca [RF04, RE07, RNF01, RNF03]
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
-- Atende: KPI de Demanda por Modalidade (abrir ou fechar turmas) [RF03, RE01, RE02]
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
-- Atende: KPI de Taxa de Conversão da Aula Experimental [RF01, RO03]
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
-- Atende: Apuração do repasse (aulas ministradas x valor por aula) [RF05, RO07]
-- Conta as aulas pelo professor que DE FATO ministrou (AULA.ID_PROFESSOR), inclusive
-- substituições e reposições. O resultado é a base do lançamento em DESPESA, pago no
-- 5º dia útil do mês seguinte. Pela RO07 só os 5 prestadores recebem: a linha do gestor
-- (professor 1) serve apenas para mostrar quantas aulas ele deu e não é lançada em DESPESA.
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
-- Atende: KPI de Resultado Mensal (fluxo de caixa) [RF04]
-- UNION ALL empilha as entradas (PAGAMENTO) e as saídas (DESPESA) numa única lista de
-- movimentos; depois o GROUP BY soma por mês. Só entra o que foi efetivamente pago.
SELECT MOV.MES,
       SUM(MOV.VL_ENTRADA)                     AS VL_ENTRADAS,
       SUM(MOV.VL_SAIDA)                       AS VL_SAIDAS,
       SUM(MOV.VL_ENTRADA) - SUM(MOV.VL_SAIDA) AS VL_RESULTADO
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

-- G09 — Quais alunos estão com frequência abaixo de 50% no mês (risco de evasão)?
-- Atende: KPI de Retenção / ação preventiva de contato [RF05, RO05, RNF03]
-- A mesma conta de frequência embasa a liberação para exame de faixa (RO05).
-- Frequência = presenças / aulas registradas para o aluno no mês, somando todas as suas turmas.
-- Só entram alunos com pelo menos 4 aulas registradas: quem se matriculou no fim do mês ou
-- foi bloqueado por atraso tem poucas aulas na lista, e a porcentagem ficaria distorcida.
SELECT a.ID_ALUNO,
       a.NM_COMPLETO                                                     AS NM_ALUNO,
       COUNT(DISTINCT m.ID_TURMA)                                        AS QT_TURMAS,
       COUNT(*)                                                          AS QT_AULAS,
       SUM(CASE WHEN pr.IN_PRESENTE = TRUE THEN 1 ELSE 0 END)            AS QT_PRESENCAS,
       ROUND(100.0 * SUM(CASE WHEN pr.IN_PRESENTE = TRUE THEN 1 ELSE 0 END) / COUNT(*), 1) AS PC_FREQUENCIA
FROM PRESENCA pr
INNER JOIN AULA au     ON au.ID_AULA     = pr.ID_AULA
INNER JOIN MATRICULA m ON m.ID_MATRICULA = pr.ID_MATRICULA
INNER JOIN ALUNO a     ON a.ID_ALUNO     = m.ID_ALUNO
WHERE au.DT_AULA BETWEEN @DT_INICIO_MES AND @DT_FIM_MES
GROUP BY a.ID_ALUNO, a.NM_COMPLETO
HAVING COUNT(*) >= 4
   AND 100.0 * SUM(CASE WHEN pr.IN_PRESENTE = TRUE THEN 1 ELSE 0 END) / COUNT(*) < 50
ORDER BY PC_FREQUENCIA, a.NM_COMPLETO;

-- G10 — Como os alunos preferem pagar (participação de cada forma de pagamento)?
-- Atende: Negociação de taxas com a maquininha e incentivo ao Pix [RF04]
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
-- Atende: KPI de Receita Recorrente Mensal por Plano (mix de planos) [RF04, RO01]
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


-- =====================================================================================
-- 9. CONSULTAS DE AUDITORIA
-- =====================================================================================
-- Verificam regras de negócio que o banco NÃO consegue garantir sozinho com PK, FK ou
-- CHECK (regras que dependem da data de hoje ou que cruzam tabelas). Resultado vazio =
-- regra cumprida; cada linha retornada é uma inconsistência para a administração tratar.
-- A massa de dados tem um caso proposital para cada uma (listados na Seção 4), para que
-- a demonstração não volte vazia. Os códigos RE/RO seguem o documento de Requisitos do Sistema.

-- A01 — Existem matrículas ativas sem nenhum registro de pagamento associado?
-- Verifica: RF04 / RO02 (toda matrícula ativa deve possuir histórico financeiro: o contrato gera
--           uma parcela por mês com vencimento no 5º dia útil)
-- Exceção legítima: dependente do Plano Família, cujas parcelas estão no contrato do titular.
-- O modelo não tem FK do dependente para o contrato; a ligação é feita pelo CPF do
-- responsável, que no Plano Família é o próprio titular (ver observação na Seção 4.3).
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       m.ID_MATRICULA,
       m.ID_TURMA,
       m.DT_MATRICULA
FROM MATRICULA m
INNER JOIN ALUNO a ON a.ID_ALUNO = m.ID_ALUNO
WHERE m.TP_SITUACAO_MATRICULA = 'ATIVA'
  -- não tem parcela em contrato próprio
  AND NOT EXISTS (SELECT 1
                  FROM CONTRATO c
                  INNER JOIN PAGAMENTO pg ON pg.ID_CONTRATO = c.ID_CONTRATO
                  WHERE c.ID_ALUNO = a.ID_ALUNO)
  -- e também não é dependente de um contrato Família vigente
  AND NOT EXISTS (SELECT 1
                  FROM RESPONSAVEL r
                  INNER JOIN ALUNO tit    ON tit.CPF      = r.CPF
                  INNER JOIN CONTRATO c   ON c.ID_ALUNO   = tit.ID_ALUNO
                  INNER JOIN PLANO pl     ON pl.ID_PLANO  = c.ID_PLANO
                  WHERE r.ID_RESPONSAVEL = a.ID_RESPONSAVEL
                    AND pl.QT_MINIMA_PESSOAS IS NOT NULL
                    AND c.DT_CANCELAMENTO IS NULL);

-- A02 — Algum aluno teve presença registrada enquanto estava bloqueado por parcela em atraso?
-- Verifica: RE07 (a partir do dia seguinte ao vencimento sem pagamento, o aluno é bloqueado
--           e não tem presença registrada)
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

-- A05 — Existe aluno menor de 18 anos sem responsável legal ou sem atestado entregue?
-- Verifica: RE03 (menor de idade precisa de responsável e de atestado de aptidão física)
-- Não dá para ser CHECK porque a idade depende da data de hoje.
SELECT a.ID_ALUNO,
       a.NM_COMPLETO,
       TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF) AS QT_IDADE,
       a.ID_RESPONSAVEL,
       a.DT_ENTREGA_ATESTADO,
       CASE WHEN a.ID_RESPONSAVEL IS NULL THEN 'SEM RESPONSÁVEL'
            ELSE 'SEM ATESTADO' END                   AS DS_PENDENCIA
FROM ALUNO a
WHERE TIMESTAMPDIFF(YEAR, a.DT_NASCIMENTO, @DT_REF) < 18
  AND a.TP_STATUS_ALUNO <> 'INATIVO'
  AND (a.ID_RESPONSAVEL IS NULL OR a.DT_ENTREGA_ATESTADO IS NULL);

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
-- Verifica: RO04 (cancelamento antecipado de plano de mais de 1 mês gera multa;
--           plano de 1 mês cancela sem multa)
SELECT c.ID_CONTRATO,
       a.NM_COMPLETO              AS NM_TITULAR,
       pl.NM_PLANO,
       pl.QT_DURACAO_MESES,
       c.DT_CANCELAMENTO,
       c.DT_FIM                   AS DT_FIM_CICLO,
       c.VL_MULTA_RESCISORIA,
       CASE WHEN pl.QT_DURACAO_MESES > 1 THEN 'CANCELAMENTO ANTECIPADO SEM MULTA'
            ELSE 'PLANO MENSAL COM MULTA INDEVIDA' END AS DS_INCONSISTENCIA
FROM CONTRATO c
INNER JOIN PLANO pl ON pl.ID_PLANO = c.ID_PLANO
INNER JOIN ALUNO a  ON a.ID_ALUNO  = c.ID_ALUNO
WHERE c.DT_CANCELAMENTO IS NOT NULL
  AND (   (pl.QT_DURACAO_MESES > 1 AND c.DT_CANCELAMENTO < c.DT_FIM AND c.VL_MULTA_RESCISORIA IS NULL)
       OR (pl.QT_DURACAO_MESES = 1 AND c.VL_MULTA_RESCISORIA IS NOT NULL));

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

-- =====================================================================================
-- FIM DO SCRIPT
-- =====================================================================================
