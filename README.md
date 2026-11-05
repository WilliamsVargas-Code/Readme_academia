# 2ª Entrega (Adição de Sistema Conceitual, Lógico e SQL) 

## 1. Relatório Técnico Final

## Metadados

| Nome completo do aluno | RGM | Usuário do GitHub |
| :-- | :-- | :-- |
| Nickolas Henrique Bezerra | 47685778 | Nickolashbezerra |
| Pedro Henrique Ruola Coiado | 47589124 | PedroCoiado |
| Raphaela Gonçalves Neves | 47656166 | RaphaelaSeven |
| Williams Vargas Neves Paoli dos Santos | 47336820 | WilliamsVargas-Code |

**Professor/Disciplina:** Cid Rodrigues De Andrade — Modelagem de Banco de Dados

## Artefatos do repositório
 
| Artefato | Local |
| :-- | :-- |
| Levantamento de requisitos (texto do grupo) | [levantamento/levantamento.md](levantamento/levantamento.md)|
| DER conceitual revisado | [diagrama_er.png](diagrama_er.png) |
| Modelo lógico | [modelo_logico.png](<img/Modelo Logico V6.png>) |
| Dicionário de dados (HTML) | [index.html](index.html) · [GitHub Pages](https://williamsvargas-code.github.io/Readme_academia/) |
| Script SQL e Massa de Dados | [docs/academia_base_forte_leste.sql](docs/academia_base_forte_leste.sql) |
| Slides do pitch | [slides/apresentacao.pdf](slides/apresentacao.pdf) [PENDENTE: criar] |

---

 ## Modelagem e Implementação de Banco de Dados Relacional para o Sistema de Gestão da Academia Base Forte Leste

## Introdução
A academia de artes marciais Base Forte Leste enfrenta atualmente uma crise operacional decorrente da ausência de um sistema informatizado de gestão. Todo o controle administrativo é feito por meio de fichas de papel preenchidas manualmente no ato da matrícula e por tratativas informais via WhatsApp, sem qualquer padronização ou centralização das informações. Essa fragilidade estrutural gera problemas críticos para o negócio: atrasos recorrentes no pagamento das mensalidades, que vencem todo 5º dia útil sem que a inadimplência seja formalmente registrada ou monitorada; total ausência de controle sobre a frequência dos alunos nas aulas, o que impede qualquer análise objetiva de assiduidade e dificulta o rastreamento do tempo real de treino de cada aluno, informação essencial para embasar a concessão de exames de faixa, hoje decidida apenas pela percepção visual do professor. Diante disso, evidencia-se a necessidade de estruturar um banco de dados relacional capaz de organizar e integrar essas informações.

## Desenvolvimento
O objetivo geral deste projeto é fornecer a modelagem conceitual, lógica e a implementação física do banco de dados relacional para a Academia Base Forte Leste, 
estruturando os fluxos operacionais da instituição em um sistema normalizado e consistente.

#### Os objetivos específicos incluem:

* Modelar os cadastros de alunos, os vínculos com responsáveis legais e o registro de condições médicas e restritivas;

* Integrar a gestão de planos, contratos, aditivos de multi-modalidade e a geração de faturas financeiras de mensalidades;

* Gerenciar as turmas, a grade de horários e o registro das aulas efetivamente ministradas pelo corpo docente;

* Computar a assiduidade diária dos alunos — dado fundamental para a elegibilidade aos exames de graduação — e apurar o cálculo de honorários devidos aos professores por aula;

* Entregar os artefatos de modelagem (conceitual e lógico), o script DDL/DML para o SGBD MySQL e um conjunto de consultas SQL gerenciais e de auditoria para suporte à tomada de decisão.

Delimitação de Escopo: O projeto limita-se estritamente à arquitetura do banco de dados relacional e às suas consultas analíticas. Não contempla o desenvolvimento de interfaces visuais (aplicativos ou sistemas web), módulos comerciais para venda de artigos esportivos, nem a operação direta de hardware (como catracas de reconhecimento facial); Embora a independência da arquitetura proposta permita o acoplamento futuro de tais recursos sem a necessidade de alteração estrutural nas tabelas.

## 1.1 Revisão do Modelo Conceitual

# Revisão dos Processos de Negócio: apontamentos da Entrega 1
 
### Apontamentos da correção sobre Processos de Negócio (Critério 5)
 
| Apontamento da correção da E1 | O que mudou no trabalho | Por quê |
| :---- | :---- | :---- |
| Três processos descritos só no estado atual (ficha de papel, WhatsApp), sem fluxo | Cada processo passou a ter a mesma estrutura: **Hoje (AS-IS)**, **No sistema (TO-BE)** em passos numerados com o responsável, **Dados registrados**, **Regras** e **Integração** | O AS-IS mostra o problema; o TO-BE mostra o fluxo que o banco precisa suportar. Os "Dados registrados" de cada processo são a origem dos atributos do DER e do dicionário |
| Processos sem integração entre si | Cada processo tem o item **Integração** e foi criada a tabela **Integração entre os processos** (origem, destino, o que passa, efeito) | A integração mostra quais entidades se ligam: por exemplo, Contratação → Cobrança vira o relacionamento CONTRATO–PAGAMENTO, e Frequência → Pagamento dos Professores vira PROFESSOR–AULA |
| Captação / aula experimental  **ausente** | Criado o **PN01 – Captação e Aula Experimental**, com pré-cadastro, verificação de aula já realizada e resultado (convertido ou encerrado) | Confirmado na 2ª visita (13/10/2026, Q1.1–1.2): a aula é gratuita, só pode ser feita uma vez e hoje depende da memória dos professores. Sem registro, a regra "uma por interessado" não pode ser verificada |
| Contratação de plano  **parcial** | Criado o **PN03 – Contratação de Planos**: duração (Mensal, Trimestral, **Semestral**, Anual), abrangência (modalidade extra com acréscimo), Plano Família (de 2 a 5 familiares, cada um com o seu próprio contrato e o desconto do plano), cálculo da mensalidade e renovação no fim do ciclo | Na E1 o plano contratado só aparecia através do pagamento. O processo justifica a entidade CONTRATO sugerida na correção do DER. O plano Semestral e as regras do Família vieram da 2ª visita (Q2.1–2.2) |
| Cobrança e recebimento  coberto, mas o DER não tinha data de pagamento nem valor | **PN04** detalha o que cada mensalidade registra: competência, vencimento, data de pagamento, forma de pagamento, valor, multa por atraso, taxa de exame, situação e recibo; e o bloqueio a partir do 6º dia útil | A inadimplência (problema mais citado pelo CEO) só pode ser medida comparando vencimento com data de pagamento. Sem esses dados o RF de cobrança não é atendível |
| Trancamento e cancelamento  **parcial (só nas regras)** | Criado o **PN05**, dividido em 5.1 Trancamento por lesão, 5.2 Troca de modalidade e 5.3 Cancelamento | Cada caso tem efeito diferente nos dados: o trancamento suspende cobrança e ajusta o fim do ciclo; a troca encerra uma matrícula e cria outra sem mexer na cobrança; o cancelamento encerra o contrato e pode gerar multa rescisória |
| Montagem de turmas e horários **parcial (só no RF03)** | Criado o **PN06**: turma com modalidade, professor, dia e horário; validação professor × modalidade; limite de 30; quórum de referência por modalidade (só alerta) | Corrige também o DER, em que TURMA não se ligava a MODALIDADE. O quórum veio da 2ª visita (Q3.3) |
| Compra de equipamentos e materiais  **ausente** | Criado o **PN10 – Compras**, em quatro grupos (treino, higiene e limpeza, proteção, água), com nota/comprovante e fornecedor anotado a cada compra | 2ª visita (Q4.1–4.2): o CEO compra de memória, sem registro. Não há fornecedor fixo, por isso o fornecedor é um atributo da compra e não uma entidade |
| Contas a pagar  **ausente** | Criado o **PN12 – Contas a Pagar**: uma despesa por vencimento, com categoria, credor, valor, vencimento, pagamento e situação | 2ª visita (Q5.1): despesas e vencimentos são controlados de memória. Compras e pagamento de professores alimentam esta tabela |
| Gestão e pagamento dos professores  **parcial** | Criado o **PN11**: cadastro com qualificações e apuração do valor por **aulas ministradas**, pago no 5º dia útil por Pix | 2ª visita (Q5.3): professores são prestadores pagos por aula. O valor só é confiável se a aula ministrada for registrada (PN07) |
| Controle de frequência  coberto | **PN07** separa a **aula ministrada** (turma, data, professor) da **presença** (aula, matrícula, presente/ausente) e passa a registrar a **reposição** | A aula serve ao pagamento do professor; a presença serve à graduação. A reposição era só verbal (Q5.3) |
| Graduação / exames de faixa  coberto | **PN08** inclui tempo mínimo por faixa, taxa de exame por faixa, reprovação com motivo e o Boxe sem faixa (análise técnica) | O Boxe sem faixa justifica a cardinalidade (0,n) de do lado de GRADUAÇÃO no relacionamento MODALIDADE–GRADUAÇÃO, apontada na correção do DER |
| Cadastro e matrícula  coberto | **PN02** passou a incluir vários telefones, endereço composto, menor de idade (responsável legal), atestado de aptidão física para todos os alunos, autorização de uso de imagem, troca de turma registrada e regras de LGPD | Cobre regras dadas como ausentes no Critério 8 (menores, atestado) e o item de LGPD do Critério 9 (base legal, acesso por perfil, guarda) |
| Nenhum processo tem fluxo descrito / processos prováveis não cobertos | Criada a tabela **Processos não incluídos e justificativa** (venda de produtos, folha de pagamento, estoque, empréstimo de equipamentos, instrutor auxiliar, marketing) | O esqueleto da E2 exige justificar processos típicos de academia que ficaram de fora |
| Porte sem número de alunos ou funcionários (Critério 4) | Papéis e porte informados no início da seção: 80 a 100 alunos, 1 contratado (CEO), 5 professores prestadores, 6 modalidades, 4 turmas por dia, até 30 alunos por turma | O porte justifica o volume da massa de dados (seção 4) |

### Mudanças que vieram da entrevista, e não da correção
 
| O que estava na E1 / no levantamento | O que mudou | Por quê |
| :---- | :---- | :---- |
| Trancamento "mediante atestado médico" (RE02 da E1) | Trancamento por lesão sem laudo formal | Resposta do CEO na 2ª visita (Q2.4) |
| CEO tratou a troca de modalidade como um tipo de trancamento (Q2.4) | A troca virou processo próprio (5.2), separado do trancamento | Não suspende cobrança nem contagem do contrato; tratar como trancamento geraria dados errados |
| Instrutor auxiliar como papel na turma (RO04 da E1, Q3.3–3.4 da 1ª visita) | Não é registrado no sistema | Não é funcionário, não é escolhido por regra e não gera pagamento |
| Questionário de 13/10 (Q5.2 e Q6.1): 4 professores e 1 colaborador na recepção | 5 professores prestadores (inclusive Capoeira) e nenhum recepcionista; o CEO faz a recepção | Corrigido com o CEO depois da visita — ver "Esclarecimentos posteriores" no levantamento |
| Planos Mensal, Trimestral, Anual e Família | Inclui Semestral; Família existe em todas as durações | 2ª visita (Q2.1) |

### Apontamentos da correção sobre Requisitos (Critério 7)

| Apontamento da correção da E1 | O que mudou no trabalho | Por quê |
| :---- | :---- | :---- |
| 4 dos 6 RNF eram regras de negócio (RNF03 vencimento no 5o dia útil, RNF04 limite de 30 alunos, RNF05 professor só na sua modalidade, RNF06 trancamento com atestado), repetidas na Seção 4 | Os quatro saíram dos RNF e ficam só em Regras de Negócio: **RO02** (vencimento no 5o dia útil), **RE01** (limite de 30 por turma), **RE05** (professor só na sua modalidade) e **RE04** (trancamento). Os 5 RNF atuais são de qualidade: RNF01 independência arquitetural, RNF02 segurança e LGPD, RNF03 desempenho, RNF04 integridade e codificação, RNF05 disponibilidade e backup | RNF descreve **como** o sistema deve se comportar (desempenho, segurança, backup). O que a academia exige do negócio é regra de negócio, e cada coisa fica em um lugar só |

### Apontamentos da correção sobre Regras de Negócio (Critério 8)

| Apontamento da correção da E1 | O que mudou no trabalho | Por quê |
| :---- | :---- | :---- |
| Multa e juros por atraso ausentes | **RO04**: multa por atraso nos contratos Trimestral, Semestral e Anual, guardada na parcela (`VL_MULTA` em PAGAMENTO). O plano Mensal não tem multa. O PN04 descreve o fluxo | A multa é o que a academia cobra de fato, por isso vai para o banco. Juros ficam de fora porque o CEO informou que não os cobra |
| Fidelidade e cancelamento de planos longos ausentes | **RO04**: multa rescisória no contrato (`VL_MULTA_RESCISORIA`, `DT_CANCELAMENTO`). O cancelamento é o PN05.3 | O cancelamento antecipado de um plano longo gera multa. Sem esses campos o banco não registra o cancelamento nem a multa |
| Menor de idade com autorização do responsável ausente | **RE03**: aluno menor de 18 anos exige responsável legal cadastrado (RESPONSAVEL, `ID_RESPONSAVEL`) e consentimento para dados e imagem (Art. 14 da LGPD) | Sem o responsável cadastrado, não há quem autorize a matrícula do menor. A FK é opcional porque o maior de idade não tem responsável |
| Atestado de aptidão física para matrícula ausente | **RE03**: atestado exigido de todos os alunos, com a data de entrega em `DT_ENTREGA_ATESTADO` (ALUNO) | A academia exige o atestado de todos, e a data permite saber quem está sem ele |
| Quem tem direito ao Plano Família / desconto **parcial** | **RO01** e PN03: mínimo de 2 e máximo de 5 alunos da mesma família, em todas as durações. Cada familiar tem o **seu próprio `CONTRATO`** no plano Família (`PLANO.QT_MINIMA_PESSOAS` ≥ 2 e `PC_DESCONTO` do plano), com as suas parcelas. O parentesco é conferido pelo CEO no RG e não é guardado | Com um contrato por aluno, cada familiar tem a sua cobrança e o seu bloqueio por inadimplência (RE07), sem exceções na auditoria A01. Limitação assumida: o banco não liga os contratos da mesma família, então o limite de 2 a 5 pessoas é conferido pelo CEO (seção 1.5, decisão 11) |
| LGPD para dados de saúde parcial (RNF02) | **RNF02** com a tabela `LOG_ACESSO` (quem leu CPF e `DS_PROBLEMA_SAUDE`) e, no dicionário, base legal e prazo de retenção por categoria de dado (Seção 7) | Dado de saúde é sensível: precisa de base legal, prazo de guarda e rastro de quem acessa |

### Apontamentos da correção sobre a Justificativa Técnica (Critério 11)

| Apontamento da correção da E1 | O que mudou no trabalho | Por quê |
| :---- | :---- | :---- |
| Só uma decisão defendida (PRESENÇA separada de ALUNO); não discute MATRÍCULA, PLANO, GRADUAÇÃO nem as cardinalidades | A seção 1.5 passou a justificar as chaves primárias, cada chave estrangeira (inclusive `MATRICULA`, `CONTRATO` → `PLANO` e `GRADUACAO`), cada restrição com o código da regra (`RO`/`RE`) e 11 decisões gerais. Entre elas: histórico de matrículas (decisão 4), contrato entre ALUNO e PLANO (decisão 2) e a leitura das cardinalidades, Look-Across (decisão 10) | A nota pede justificar o **porquê** de cada decisão, e não só descrevê-la. Cada FK e cada restrição aponta para o processo, o problema ou a regra que a exige |

## Apontamentos da correção sobre o Dicionário de Dados (Critério 9)

| Apontamento da correção da E1 | O que mudou no trabalho | Por quê |
| :---- | :---- | :---- |
| Faltam cardinalidades mínimas (só 1:N / N:1) | A Seção 1 traz **(mín,máx)** nos 20 relacionamentos, lidos pelo lado oposto (Look-Across), com nota para cada mínimo em zero. As cardinalidades são as mesmas do DER | É a mesma convenção do DER no brModelo Web. Os zeros têm razão de negócio: histórico de matrículas encerradas (TURMA–MATRÍCULA), Boxe sem faixas (MODALIDADE–GRADUAÇÃO, RO06), aluno maior de idade sem responsável (RE03), aluno cadastrado sem aula experimental e despesa sem professor |
| Faltam SGBD, mecanismo de armazenamento e collation (o texto adiava a escolha) | A Seção 3 define **MySQL 8.0, InnoDB e utf8mb4 / utf8mb4_unicode_ci**. Valores monetários ficam em DECIMAL(10,2) e percentuais em DECIMAL(5,2) | InnoDB dá transação e chave estrangeira, e utf8mb4 cobre os acentos do português. A escolha é a mesma do RNF04. DECIMAL guarda o valor exato, sem o erro de arredondamento do ponto flutuante |
| Falta a data da versão | A Seção 3 tem a linha de versão (**v2.5 — 02/11/2026**), e o histórico de versões registra de v1.0 a v2.5 | Mostra o que mudou em cada rodada e por quê |
| Falta log de acesso | A Seção 6 descreve a tabela **LOG_ACESSO**: usuário, perfil, data, operação, tabela, registro e campo sensível acessado. Só o sistema grava e só a Administração lê. A tabela também existe no modelo lógico; não aparece no DER, assim como as chaves estrangeiras | Atende o RNF02, que exige rastrear quem lê CPF e DS_PROBLEMA_SAUDE e quem escreve. O log guarda o ID do registro, não o dado sensível |
| Falta tabela de papéis por operação | A Seção 5 traz a matriz CRUD de **Administração e Professor** para todas as entidades. Não há exclusão em CONTRATO, PAGAMENTO e DESPESA | Só existem dois perfis porque o CEO faz a recepção. O professor lê apenas o necessário do aluno (nome, situação e restrições de saúde). A exclusão fica bloqueada por retenção fiscal |
| LGPD só como nota, sem base legal nem retenção | A Seção 7 traz uma tabela por categoria (cadastrais, financeiros, saúde, imagem, aulas, log) com **base legal e prazo de retenção**. Também trata menores (art. 14) e a rotação de backup | Os prazos seguem o RNF05 (5 anos fiscais, backup de 30 dias). Bases legais e prazos são propostas do grupo, a validar com orientação jurídica |
| (Critério 10, mas depende do dicionário) TURMA sem ligação com MODALIDADE; PAGAMENTO sem data de pagamento e valor; plano só aparecia através do pagamento | MODALIDADE (1,1)·TURMA (0,n). PAGAMENTO tem DT_VENCIMENTO, DT_PAGAMENTO, VL_DEVIDO e VL_PAGO. CONTRATO é entidade entre ALUNO, PLANO e PAGAMENTO | O dicionário e o RF03 já diziam que a turma pertence a uma modalidade. Sem data de pagamento não se mede a inadimplência (RF04). O contrato justifica a entidade CONTRATO sugerida na correção do DER |

Itens que a correção já aprovava e foram mantidos: tabela conceitual, MATRÍCULA como entidade associativa, definições, fluxo de dados, notação, prefixos, expressões com leitura, tipos físicos e índices.

###  Detalhamento das Mudanças (1º DER para o 2º DER)

Em resposta à avaliação da Entrega 01 e à segunda entrevista de campo (13/10/2026), o modelo evoluiu de **9 para 14 entidades**, corrigindo todas as pendências estruturais:

| Escopo / Item | Como estava antes (Entrega 01) | Como ficou na Entrega 02 (DER, Lógico e SQL) | Motivo e Justificativa Técnica |
| :--- | :--- | :--- | :--- |
| **Escopo e Entidades** | 9 entidades iniciais (55% de cobertura dos processos). | **14 entidades** principais, além de **`PRESENCA`** e **`PARTICIPA`** como tabelas associativas. Novas entidades: `Contrato`, `Aula`, `Trancamento`, `Responsavel`, `Interessado` e `Despesa`. | Reescrita sobre o MER e o DER atualizados para atingir 100% de cobertura operacional (captação, aulas, contratos, LGPD e contas a pagar). |
| **Leitura de Cardinalidades** | Cardinalidades lidas pela convenção invertida, apenas com `1,1` e `1,n`. | Convenção **Look-Across** padronizada com parênteses e mínimos opcionais `(0,1)` e `(0,n)`. | Segue a convenção nativa do DER no **brModelo Web** e corrige restrições rígidas da Entrega 01. |
| **Turma e Modalidade** | Sem ligação direta entre `Turma` e `Modalidade`. | Criado o relacionamento **`Oferece`** `(1,1) --- (1,n)`. | Corrige apontamento da E1: identifica qual arte marcial é lecionada em cada turma. |
| **Contrato e Pagamento** | `Pagamento` ligava-se direto a `Aluno` e `Plano`, contendo apenas vencimento e status. | Criada a entidade **`Contrato`** (entre `Aluno`, `Plano` e `Modalidade`). `Pagamento` passa a ser parcela do `Contrato`, com `DT_PAGAMENTO`, `VL_DEVIDO`, `VL_PAGO`, `TP_FORMA_PAGAMENTO`, `VL_MULTA` e `VL_TAXA_GRADUACAO`. | O plano contratado passa a existir como acordo formal (3FN, congelando o valor acordado) e permite auditar a inadimplência após o 5º dia útil. |
| **Presença e Aulas** | `Presença` ligada apenas a `Matrícula`. | Nova entidade **`Aula`** ligada a `Turma`, `Professor` e `Matrícula` (com `PRESENCA` associativa). | Permite apurar aulas efetivamente dadas por professor terceirizado e controlar reposições (`ID_AULA_ORIGEM`). |
| **Lotação de Turma** | Possuía o campo calculável `Vagas_Ocupadas`. | Substituído por **`QT_CAPACIDADE_MAXIMA`** (teto de 30). | Adequação à 3FN: as vagas ocupadas são apuradas dinamicamente via `COUNT(*)`. |
| **Trancamento e Troca de Turma** | Era um atributo em `Matrícula` e aceitava trancamento por lesão **ou** troca de modalidade. | Nova entidade **`Trancamento`** restrita a **lesão ou razão médica**. A troca de turma encerra a matrícula antiga (`ENCERRADA`) e cria outra. | Alinhado ao Processo 5 do README: preserva o histórico de presença na turma anterior e isola os afastamentos médicos. |
| **Graduação** | Ligada apenas a `Aluno` e `Modalidade`. | Ligada a `Professor` (`Avalia`), com `TP_AVALIACAO`, `TP_RESULTADO` e `DS_MOTIVO_REPROVACAO`. | Audita qual professor aplicou o exame, separa análise técnica (Boxe) e registra reprovações. |
| **LGPD e Menores** | Sem responsável legal, termos ou prazos consolidados (continha frase *"a definir com o CEO"*). | Nova entidade **`Responsavel`**, campos de imagem/atestado em `Aluno`, tabela **`LOG_ACESSO`** e prazos de guarda definidos pelo grupo (5 anos para dados financeiros — RNF05). | Atende ao Art. 14 da LGPD para menores de 18 anos e consolida a governança de retenção sem pendências em aberto. |
| **Atributos Multivalorados (1FN)** | Mapeados apenas na etapa física preliminar. | Desmembrados em **8 tabelas de apoio** com chave primária composta já no Modelo Lógico. | Garante total aderência à 1ª Forma Normal (1FN) entre o Modelo Lógico e o script SQL. |
| **Limpeza e Padronização de Colunas** | Continha `NM_RESPONSAVEL_PLANO`, `TP_DOC_PARENTESCO`, `DT_CONFERENCIA_PARENTESCO`, `NM_ATESTADO_POR`, `QT_TEMPO_MINIMO_FAIXA`, `DS_OBSERVACAO`, `VL_MULTA_ATRASO` e `VL_TAXA_EXAME`. | Atributos excedentes removidos. Nomes padronizados para **`VL_MULTA`** e **`VL_TAXA_GRADUACAO`** (nome definitivo do projeto). | Alinhamento estrito entre MER, DER, Modelo Lógico e Dicionário de Dados, eliminando colunas que não constavam no modelo lógico. |
| **Tipagem de Dados Físicos** | Valores monetários como `real/numeric` e documentos em `varchar` de tamanhos variados. | Monetários em **`DECIMAL`**; `CPF` padronizado em **`CHAR(11)`** e `NR_CEP` em **`CHAR(8)`** (apenas dígitos) em `ALUNO`, `RESPONSAVEL` e `PROFESSOR`. | Evita erros de arredondamento financeiro e permite comparar CPFs entre tabelas com índice único sem divergência de pontuação ou tamanho. |

 

# Caracterização da Organização

## Nome e natureza da organização

Base Forte Leste - Academia de Artes Marciais (Gerida pelo CEO Adalberto). É uma organização com fins lucrativos voltada para a prestação de serviços esportivos e ensino de lutas.
  
## Contexto e porte

### Natureza Jurídica e Atuação

Empresa privada com fins lucrativos, atuante na prestação de serviços esportivos, condicionamento físico e ensino de artes marciais.

### Quadro de Pessoal 

* **Corpo Docente e Gestão:** 1 gestor geral (CEO) que também ministra as turmas de Muay Thai, somado a 5 professores contratados como prestadores de serviços terceirizados para as demais modalidades (Boxe, Jiu-Jitsu, Kickboxing, No-Gi e Capoeira).

* **Corpo de Apoio:** Instrutores auxiliares rotativos (alunos avançados/graduados que prestam suporte técnico sem vínculo empregatício formal).

### Estrutura de Modalidades e Grade de Horários

* **Modalidades Ofertadas:** 6 artes marciais ativas (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi).   

* **Grade Semanal:** 21 turmas regulares distribuídas de segunda a sábado nos períodos matutino, vespertino e noturno.   

* **Capacidade Física:** Limite estrito de segurança de até 30 alunos por turma simultaneamente no tatame.   

* **Quantidade Mínima por Modalidade:** Parâmetro para abertura formal de horários: Muay Thai (4 alunos), Boxe (6 alunos), Jiu-Jitsu/Kickboxing/No-Gi (8 alunos) e Capoeira (10 alunos).

### Volumetria Operacional Estimada (Base para a Massa de Dados):

* **Alunos Ativos:** Faixa estimada entre 80 e 100 praticantes matriculados, considerando a distribuição dos alunos nas turmas regulares acima do quantidade mínima operacional de cada modalidade.

* **Contratos:** Um contrato vigente por aluno ativo ou trancado, ou seja, de 80 a 100 contratos. No Plano Família, cada familiar matriculado tem o seu próprio contrato, com desconto progressivo.

* **Movimentação Financeira Mensal:** Emissão recorrente de 80 a 100 faturas de mensalidade por mês (uma para cada contrato vigente, com vencimento no 5º dia útil), gerando no banco um histórico de liquidações pontuais, pagamentos com acréscimo de uma multa (planos Trimestral, Semestral e Anual)  

* **Aulas Experimentais:** Média observada de 2 a 4 atendimentos semanais de novos interessados para testes gratuitos (cerca de 8 a 16 por mês), que hoje dependem unicamente da memória do CEO e dos professores.   

* **Rotina de Compras e Despesas:** Reposição presencial semanal de insumos de higiene/limpeza realizada pelo gestor, além do lançamento mensal das despesas fixas da academia (locação, água, luz e pagamento de docentes). 

## Problemas e necessidades identificados
  
A Academia Base Forte Leste enfrenta atualmente uma crise operacional decorrente da dependência exclusiva de fichas impressas de papel e do controle informal de tratativas via WhatsApp, sem a integração de um sistema informatizado central. A administração da unidade apoia-se na memória individual dos funcionários e em anotações descentralizadas, gerando descontinuidade de dados, insegurança jurídica, vulnerabilidades financeiras e falhas no planejamento das aulas.

Para solucionar esses gargalos e atender formalmente aos requisitos da disciplina, os problemas de gestão de informação foram catalogados e numerados de P1 a P7, conectando as rotinas operacionais observadas em campo às soluções estruturadas no banco de dados relacional:

### P1 - Vulnerabilidade no armazenamento manual em fichas físicas e risco de perda de dados

**O que acontece na prática:** O cadastro de novos alunos é realizado exclusivamente à mão em formulários impressos de papel preenchidos no balcão de atendimento. Essas folhas reúnem dados cadastrais, telefones de emergência, identificação de pais ou responsáveis no caso de praticantes menores de idade e anotações sobre problemas de saúde preexistentes, ficando arquivadas em pastas físicas abertas sobre a bancada de atendimento.

**Por que é um problema:** Os papéis estão sujeitos à degradação física e a riscos constantes de extravio, rasuras e umidade durante o expediente. Além da perda física das informações, manter pastas de formulários expostas sobre o balcão deixa registros de saúde e dados pessoais vulneráveis à visualização de terceiros, infringindo os requisitos de sigilo da LGPD. Qualquer atualização cadastral ou consulta de contato exige folhear fichas manualmente, tornando o atendimento lento e propenso a inconsistências.

**Como o banco de dados resolve:** Substitui o uso do papel pelo armazenamento digital seguro nas tabelas `ALUNO` e `RESPONSAVEL`. Cada praticante recebe um identificador primário exclusivo (`Id_Aluno`), garantindo a preservação dos dados de saúde, eliminando o risco de perda física de cadastros e permitindo a recuperação instantânea das informações do aluno.

### P2 - Inadimplência oculta e falta de controle sobre pagamentos de mensalidades

**O que acontece na prática:** As mensalidades de todas as modalidades vencem rigidamente no 5º dia útil de cada mês. Todavia, o controle de quitação baseia-se em trocas informais de mensagens pelo WhatsApp, onde a administração apenas marca em conversas a data em que o comprovante foi encaminhado ou em que o valor foi pago no balcão.

**Por que é um problema:** A gestão não possui visibilidade em tempo real sobre quais alunos estão em atraso, qual é o saldo inadimplente total acumulado e deixa de aplicar as penalidades de multas previstas. Diversos praticantes permanecem com acesso liberado aos treinos mesmo com pendências financeiras prolongadas, devido à carência de rotinas automáticas de auditoria e cobrança.

**Como o banco de dados resolve:** Estrutura a tabela `PAGAMENTO`, registrando o valor nominal devido, a data efetiva de liquidação, o montante liquidado, a multa por atraso (`Valor_Multa`) e os estados do título (`Pendente, Pago, Atrasado`), viabilizando relatórios imediatos de fluxo de caixa e inadimplência.

### P3 - Acordos verbais na contratação de planos e descontrole no cálculo de multas rescisórias

**O que acontece na prática:** O estabelecimento oferece planos nas modalidades Mensal, Semestral, Trimestral, Anual e Familiar (com descontos progressivos a partir de dois alunos com vínculo de parentesco), além de aplicar cobranças complementares caso o aluno queira ter acesso a mais de uma luta da grade. Todos esses termos são formalizados por acertos verbais no balcão.

**Por que é um problema:** Na ocorrência de cancelamentos antecipados de pacotes com duração trimestral ou anual, a empresa não tem suporte em registros formais de vigência para cobrar as multas rescisórias devidas. Esse vácuo gera contestações por parte dos alunos e provoca perdas de receita previamente planejadas.

**Como o banco de dados resolve:** Interliga as entidades `PLANO` e `CONTRATO`, assegurando o registro do período de vigência, do valor mensal fixado no ato da venda, das taxas de acréscimo de multi-modalidade e dos parâmetros objetivos de cálculo de multa por rescisão antecipada.

### P4 - Troca de faixas e graduação sem comprovação de frequência mínima nas aulas

**O que acontece na prática:** Para progredir de graduação nas modalidades estruturadas por faixas (Muay Thai, No-Gi, Jiu-Jitsu, Kickboxing e Capoeira), o praticante deve cumprir um período de prática e uma assiduidade mínima comprovada. No entanto, a academia não mantém nenhum tipo de lista de chamada, caderno de presenças ou catraca eletrônica.

**Por que é um problema:** A permissão para que o aluno se inscreva no exame de graduação apoia-se unicamente na memória dos professores, sem embasamento em dados históricos reais. Esse critério subjetivo compromete o rigor pedagógico e o nivelamento técnico esperado pela academia.

**Como o banco de dados resolve:** Integra as tabelas `AULA`, `MATRICULA` e `GRADUACAO`, computando a assiduidade diária por modalidade e viabilizando consultas que atestam com precisão se a meta mínima de presença foi alcançada antes da emissão do certificado de faixa.

### P5 - Superlotação, descontrole de vagas por trancamento e transferências informais de modalidade

**O que acontece na prática:** Os horários são programados para suportar um teto de segurança de até 30 alunos por turma. Contudo, tanto as solicitações de trancamento de plano por lesão médica quanto os pedidos de troca definitiva de arte marcial (por exemplo, transferência do Boxe para o Muay Thai) ocorrem por mensagens no WhatsApp ou de boca no balcão.

**Por que é um problema:** A ausência de sincronização no sistema impede que o CEO saiba quantas vagas reais estão preenchidas nos horários. Autorizar transferências entre artes marciais sem conferência de dados pode provocar a superlotação do tatame acima de 30 alunos na modalidade de destino, além de manter indevidamente bloqueadas as vagas de quem já se afastou por questões médicas.

**Como o banco de dados resolve:** Integra as tabelas `TURMA`, `MATRICULA` e a entidade `TRANCAMENTO`, mantendo o histórico de transferências, o registro formal do afastamento por lesão (TP_TRANCAMENTO, DS_MOTIVO, DT_INICIO, DT_RETORNO_PREVISTA) e permitindo o cálculo dinâmico da ocupação das turmas em tempo real.

### P6 - Dificuldade no cálculo do repasse financeiro e controle das aulas lecionadas pelos professores

**O que acontece na prática:** A organização oferta 6 modalidades esportivas (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi), operando com um quadro de 6 professores. O CEO ministra exclusivamente as aulas de Muay Thai, ao passo que os outros 5 profissionais trabalham sob o regime de prestação de serviços, recebendo a remuneração com base na quantidade de aulas efetivamente dadas no mês.

**Por que é um problema:** Não há registro sistêmico sobre quais aulas foram ministradas, quais professores compareceram e como ocorreram as reposições de horários. Ao final do mês, a apuração dos valores a serem repassados aos docentes depende de negociações verbais e memória, gerando risco de erros contábeis e atritos operacionais.

**Como o banco de dados resolve:** Relaciona PROFESSOR e AULA (cada aula guarda o professor que a ministrou, e o valor por aula fica em PROFESSOR.VL_POR_AULA) e lança o pagamento em DESPESA, permitindo a geração automática de folhas de repasse com base nas aulas de fato lecionadas por cada docente.

### P7 - Desperdício de contatos e falta de acompanhamento de aulas experimentais

**O que acontece na prática:** A academia disponibiliza uma aula experimental gratuita para interessados que desejam experimentar uma modalidade antes de efetivar o vínculo. No entanto, nenhum dado de identificação ou contato desse participante é registrado no momento do agendamento.

**Por que é um problema:** O histórico desse primeiro contato fica restrito à lembrança pontual dos professores e do CEO. Quando o visitante não formaliza a adesão no mesmo dia da aula, a academia perde os dados de contato, impedindo que o CEO faça ações de retorno e converta potenciais alunos em matrículas ativas.

**Como o banco de dados resolve:** Cria a entidade `INTERESSADO`, capturando o nome, telefone, data do atendimento e o retorno da visita (`Resultado_Interesse`), fornecendo métricas sobre o índice de conversão de aulas experimentais em novos contratos.

### Conclusão 

A implantação de um banco de dados relacional é indispensável para substituir as fichas de papel e centralizar o controle hoje dividido entre fichas de papel, memória e mensagens de WhatsApp. O sistema unifica os dados cadastrais, financeiros e pedagógicos em uma base sólida e auditável. Paralelamente, o anseio da academia pela instalação futura de uma catraca com reconhecimento facial na entrada atua apenas como um hardware externo de consumo de dados: essa automação não interfere na modelagem do banco de dados, que opera de forma independente e estruturalmente pronta para fornecer suporte a essa integração no futuro.

## Justificativa da escolha:

A escolha desta academia fundamenta-se em sua expressiva relevância comunitária na promoção da saúde e no ensino de defesa pessoal. A viabilidade e o aprofundamento dessa seleção decorrem do fato de um dos integrantes da equipe, Nickolas, ser aluno da instituição. Tal condição proporcionou acesso privilegiado à administração, permitindo uma análise precisa dos desafios vivenciados no controle discente, na gestão contratual e no acompanhamento da frequência. O desenvolvimento de um banco de dados mostra-se uma medida imprescindível para assegurar o armazenamento centralizado e seguro das informações, sanando as vulnerabilidades atuais.

  
## Evidências da organização

- Endereço completo: Rua Itinguçu, 2345A, Vila Ré, São Paulo – SP
- Responsável: Adalberto (CEO)
- Telefone: (11) 98495-5601 
- E-mail: basefortelesteacademia@gmail.com
- Rede social: Instagram @basefortelesteacademia

### Relato da Entrevista
- **Quem:** Entrevista conduzida presencialmente pelo aluno Nickolas Henrique Bezerra com o CEO e gestor técnico do espaço, Adalberto.

- **Quando e Onde:** Realizada nas instalações da academia Base Forte Leste. Ocorreu em uma primeira fase no dia 01/09/2026 (diagnóstico inicial) e em uma segunda visita presencial no dia 13/10/2026 (refinamento da Regras de Negócio).

- **Comprovação:** Fotografia da visita presencial anexada ao repositório.

- **O que foi levantado (Resumo do Levantamento):** O documento completo com todas as perguntas e respostas encontra-se no repositório em [levantamento/levantamento.md](levantamento/levantamento.md). Abaixo, destacam-se os principais achados, rigorosamente separados entre as declarações do entrevistado e as constatações visuais da equipe no local:

  - **Respostas do Entrevistado (Gestor Adalberto):** Confirmou que a inadimplência mensal é o problema operacional mais recorrente. Relatou que não há controle formal de presenças e que as aprovações nos exames de faixa dependem exclusivamente da sua análise de técnica e tempo de treino estimado. Esclareceu que conta com 5 professores terceirizados e instrutores auxiliares informais.
  
  - **Observações no Local (Equipe do Projeto):** Constatou-se fisicamente que o registro de novos alunos e seus dados médicos fica restrito a fichas de papel, guardadas de maneira vulnerável no balcão de atendimento, o que evidencia riscos de perda e falta de conformidade com a LGPD. Verificou-se a inexistência de catracas eletrônicas para controle de acesso. Observou-se, ainda, que o fluxo contínuo de alunos sobrecarrega o atendimento informal presencial, justificando a perda histórica do controle de transferências e trancamentos.



---

## Processos de Negócio
 
### PN01. Captação e Aula Experimental
 
**Hoje (AS-IS):** a academia não tem recepcionista. Quem recebe o interessado, combina o horário e acompanha a aula experimental é o CEO, que também faz a recepção durante as aulas das demais modalidades. O interessado agenda a aula presencialmente ou pelo WhatsApp. A academia prefere horários de menor movimento (sextas-feiras e turmas matutinas), mas não é regra rígida. Nada é registrado: se a pessoa já fez a aula experimental depende da memória dos professores e da gestão (P7).
 
**No sistema (TO-BE):**
 
1. O interessado combina dia e horário com a academia, presencialmente ou pelo WhatsApp. (interessado e CEO)
2. O CEO ou o professor responsável pela modalidade registra o pré-cadastro. O registro pode ser feito antes da aula, no agendamento, que é a forma mais eficiente. O professor controla se a turma tem vaga.
3. O sistema confere se o interessado já fez aula experimental, pelo ID, pelo nome e pelo telefone. Se já fez, não permite novo registro, porque a aula é gratuita e só pode ser feita uma vez.
4. A aula é realizada com o professor da modalidade.
5. O interessado decide e o resultado do interesse é registrado:
   - **Segue:** vai para Cadastro e Matrícula. Os dados são digitados novamente: nome, telefones, CPF, histórico de treino, e-mail, problemas de saúde, data de nascimento, endereço (CEP, rua, número e bairro) e situação. A autorização de uso de imagem é perguntada nessa etapa. O pré-cadastro fica registrado como convertido.
   - **Não segue:** o pré-cadastro fica registrado como encerrado.
**Dados registrados:** identificador (ID), nome, telefone, data do primeiro contato, modalidade, data e horário da aula, professor, resultado do interesse.
 
**Regras:** aula gratuita; apenas uma por interessado.
 
**Integração:** envia o interessado para Cadastro e Matrícula.
 
---
 
### PN02. Cadastro e Matrícula
 
**Hoje (AS-IS):** como a academia não tem recepcionista, o CEO faz o cadastro e a matrícula dos alunos novos presencialmente. O aluno preenche uma ficha de papel guardada em pasta física no balcão, com risco de extravio e deterioração (P1). A data da matrícula é anotada na ficha. Não existe número de matrícula: o aluno é identificado por nome ou CPF. A troca de turma não é registrada.
 
**No sistema (TO-BE):**
 
1. O aluno informa seus dados: CPF, nome completo, data de nascimento, endereço (CEP, rua, número e bairro), e-mail, problemas de saúde, esportes já praticados, por quanto tempo treinou e se já é graduado. Informa também quantos telefones forem necessários (principal, reserva, emergência). (aluno e CEO)
2. O sistema confere a idade. Se o aluno tem menos de 18 anos, exige os dados do responsável legal (nome, CPF, telefone e parentesco). De todos os alunos, de qualquer idade, exige o atestado de aptidão física. A data de entrega é registrada quando o atestado é apresentado e fica em branco até lá.
3. O CEO confirma o cadastro. O sistema gera o identificador único do aluno, que já fica com a situação Ativo.
4. O aluno escolhe o plano (processo 3).
5. O aluno escolhe a modalidade e a turma. O sistema cria a matrícula (aluno + turma) com data e situação e confere o limite de 30 alunos ativos. Se a turma estiver lotada, o aluno escolhe outra turma.
6. A primeira mensalidade é gerada já com o valor integral, sem cálculo proporcional, e vence no 5º dia útil seguinte.
**Troca de turma:** passa a ser registrada. A matrícula antiga é encerrada e uma nova é criada; a antiga nunca é apagada e fica no histórico. O histórico de treino do aluno é guardado no cadastro.
 
**Autorização de uso de imagem:** quando o interessado vira aluno, o CEO pergunta se a academia pode usar a imagem dele em vídeos do Instagram. O sistema registra a resposta (autoriza ou não autoriza) e a data. Se o aluno tem menos de 18 anos, a resposta é dada pelo responsável legal.
 
**Proteção de dados pessoais (LGPD):** o cadastro reúne dados pessoais comuns (CPF, endereço, telefones, e-mail) e dados pessoais sensíveis (problemas de saúde). Por isso o sistema segue estas regras:
 
- **Finalidade e base legal:** os dados cadastrais são tratados para executar o contrato de prestação do serviço (matrícula, cobrança, controle de frequência e graduação). Os problemas de saúde são coletados com o consentimento do aluno, para que o professor conheça as restrições dele durante o treino. O uso de imagem é uma autorização separada, opcional e revogável a qualquer momento, e não condiciona a matrícula.
- **Menores de idade:** o consentimento e a autorização de imagem são dados pelo responsável legal, cujos dados também são registrados.
- **Minimização:** só se coleta o que o processo usa. Por isso o sistema não guarda documentos de familiares do Plano Família nem dados bancários de credores.
- **Acesso por perfil:** o CEO acessa todos os dados. O professor acessa apenas os dados necessários para a aula (nome, turma, presença e restrições de saúde informadas). Os dados financeiros do aluno ficam restritos ao CEO.
- **Guarda e eliminação:** os dados são mantidos enquanto o aluno tiver contrato e, depois, por 5 anos, para o histórico de matrículas, pagamentos e graduações. Após esse prazo, ou a pedido do titular quando não houver obrigação de guarda, os dados são eliminados ou anonimizados.
- **Direitos do titular:** o aluno (ou o responsável legal) pode pedir ao CEO a confirmação do tratamento, o acesso, a correção e a eliminação dos seus dados, e revogar a autorização de imagem.
- **Fim do papel:** as fichas físicas deixam de existir, o que elimina a exposição dos dados no balcão.
**Dados registrados:** os do cadastro acima; telefones (vários por aluno); endereço (CEP, rua, número e bairro); responsável legal (nome, CPF, telefone, parentesco), quando menor; data de entrega do atestado de aptidão física (todos os alunos; em branco até a entrega); autorização de uso de imagem (sim ou não) e data da resposta; na matrícula, aluno, turma, data da matrícula e situação (Ativa, Cancelada, Trancada e Encerrada, esta usada na troca de turma).
 
**Regras:** situação do aluno restrita a Ativo (contrato vigente), Inativo (contrato terminado) ou Trancado (trancamento em curso); um aluno pode ter várias matrículas (várias modalidades) e um único contrato vigente (no Plano Família, cada aluno tem o seu); menor de 18 anos exige responsável legal; todo aluno, adulto ou menor, deve entregar o atestado de aptidão física, e a data de entrega fica em branco até ele ser apresentado; CPF único; problemas de saúde são dados sensíveis e o CPF é dado pessoal comum, tratados conforme a regra de LGPD acima; a autorização de uso de imagem é opcional e fica registrada com a data; matrícula encerrada nunca é apagada.
 
**Integração:** recebe de Aula Experimental; envia para Contratação de Planos, Frequência e Graduação.
 
---
 
### PN03. Contratação de Planos
 
**Hoje (AS-IS):** a academia trabalha com planos de diferentes durações, sem registro formal do que cada aluno contratou além da data de pagamento anotada no WhatsApp (P3).
 
**No sistema (TO-BE):**
 
1. O aluno escolhe a duração: Mensal, Trimestral, Semestral ou Anual. Cada duração tem uma faixa de desconto progressivo (percentuais confidenciais).
2. O aluno escolhe a abrangência. O plano regular cobre uma única modalidade. Para mais de uma modalidade ou livre acesso a todas, aplica-se um acréscimo proporcional, mantida a tabela de desconto do ciclo. Cada aluno tem um único contrato (no Plano Família, cada familiar tem o seu, com o desconto do plano), que lista as modalidades cobertas; cada modalidade extra entra nesse mesmo contrato como um acréscimo.
3. **Plano Família:** exige no mínimo dois alunos matriculados da mesma família e existe em todas as durações, cada uma com seu desconto. O grupo pode ter até 5 alunos (um aluno e até 4 familiares). Cada aluno do grupo tem o seu próprio contrato, com o desconto do Plano Família. O sistema não registra parentesco nem documento. Se um familiar paga pelos demais, isso é tratado fora do sistema: cada contrato continua registrado e cobrado individualmente.
4. O sistema  calcula a mensalidade (valor base + acréscimos por modalidadeextra - desconto).
5. O contrato é registrado e o sistema gera as mensalidades (processo 4). Pagamento: os planos Trimestral, Semestral e Anual definem apenas o ciclo e o desconto. O pagamento é sempre em parcelas mensais, vencendo no 5º dia útil. Não existe quitação antecipada. Um plano anual gera 12 mensalidades.
**Renovação:** o contrato não termina sozinho. No fim do ciclo, o aluno é contatado e avisado de possíveis alterações no desconto do seu plano. Se aceita, o contrato continua; se recusa, o contrato é cancelado e o aluno passa a Inativo.
 
**Dados registrados (contrato):** aluno, plano, modalidades cobertas, data de início, data de fim do ciclo, valor da mensalidade, percentual de desconto, acréscimos por modalidade extra (quando houver), data do cancelamento e valor da multa rescisória (quando houver).
 
**Regras:** vencimento fixo no 5º dia útil; multa rescisória só em planos de maior duração (processo 5); contrato só termina por cancelamento.
 
**Integração:** recebe de Cadastro e Matrícula; envia para Cobrança e para Trancamento e Cancelamento.
 
---
 
### PN04. Cobrança e Recebimento de Mensalidades
 
**Hoje (AS-IS):** o controle é feito pelo WhatsApp e registra apenas a data em que o aluno pagou. Atrasos não são registrados. A inadimplência é o problema mais frequente da academia (P2).
 
**No sistema (TO-BE):**
 
1. O sistema gera uma mensalidade por mês de vigência do contrato, com vencimento no 5º dia útil, para todos os planos. A geração é mensal, e não de uma só vez, para acompanhar qualquer alteração no contrato (trancamento, cancelamento). Meses de trancamento por lesão não geram mensalidade.
2. O aluno paga por Pix, cartão de crédito ou cartão de débito. O CEO registra o pagamento no sistema.
3. O sistema registra a data de pagamento e muda a situação para Paga.
4. Se o 5º dia útil passa sem pagamento, a situação vira Atrasada e, a partir do 6º dia útil, o aluno fica bloqueado: não participa das aulas e o sistema impede o registro de presença. Com a catraca de reconhecimento facial, o bloqueio passa a valer na entrada.
5. **Multa por atraso:** nos planos Trimestral, Semestral e Anual (inclusive Família dessas durações), além do bloqueio há multa, de valor confidencial, calculada por cada mês de atraso. No Mensal (inclusive Família mensal) há só o bloqueio, sem multa. Não há juros.
6. Ao regularizar, o CEO registra o pagamento e o aluno é desbloqueado.
7. O sistema registra o recibo de cada pagamento: o recibo é emitido ao aluno e também guardado no sistema.
**Dados registrados (mensalidade):** contrato, competência (mês de referência), data de vencimento, data de pagamento, forma de pagamento, valor, valor da multa por atraso (quando houver), valor da taxa de exame (quando houver), situação (Paga, Atrasada, Pendente); e o recibo.
 
**Regras:** vencimento no 5º dia útil independente da data de matrícula; bloqueio a partir do 6º dia útil, para todos os planos; a situação em dia ou bloqueado do aluno é derivada das mensalidades.
 
**Integração:** recebe de Contratação de Planos, de Trancamento (suspende a geração) e de Graduação (taxa de exame cobrada junto com a mensalidade); envia o bloqueio para Frequência.
 
---
 
### PN05. Trancamento, Troca de Modalidade e Cancelamento
 
**Hoje (AS-IS):** trancamentos e cancelamentos são tratados só pelo WhatsApp, sem registro (P5 P3).
 
**No sistema (TO-BE):**
 
**5.1 Trancamento por lesão ou razão médica**
 
1. O aluno apresenta a justificativa pelo WhatsApp ou presencialmente. Não precisa de laudo médico formal.
2. O CEO registra o trancamento com motivo, data de início e data combinada de retorno. Não há prazo máximo: cabe ao CEO controlar os trancamentos e decidir o que fazer em cada caso.
3. Durante o trancamento, a cobrança e a contagem de tempo do plano ficam suspensas e não há multa. A data de fim do ciclo do contrato é ajustada.
4. Na data de retorno combinada, a matrícula volta a ficar ativa.
**5.2 Troca de modalidade (não é trancamento)**
 
1. O aluno pede a troca. O CEO confirma se há vaga na nova modalidade.
2. Não há taxa, encargo, cobrança adicional nem suspensão de cobrança.
3. A matrícula antiga é encerrada e a nova é criada. Se for só troca, o contrato continua o mesmo e não há valor adicional. Se o aluno acrescentar uma modalidade ao que já treina, o contrato continua o mesmo, com um acréscimo para essa modalidade.
**5.3 Cancelamento**
 
1. O aluno comunica o cancelamento presencialmente ou pelo WhatsApp. O acesso termina na data do pedido.
2. **Plano Mensal** (inclusive Família mensal): cancela a qualquer momento, sem multa rescisória.
3. **Trimestral, Semestral e Anual** (inclusive Família): o cancelamento antecipado gera multa rescisória, calculada pelos meses que faltam para o fim do ciclo (fórmula e valores confidenciais). A multa é cobrada depois do cancelamento.
4. O contrato registra a data do cancelamento e o valor da multa. Quando o contrato termina, o aluno passa à situação Inativo.
**Dados registrados:** no trancamento, aluno, motivo, data de início, data de retorno combinada; no cancelamento, data e valor da multa (no contrato).
 
**Regras:** a multa rescisória é diferente da multa por atraso; trancamento por lesão isenta multas; troca de modalidade não suspende cobrança; adicionar modalidade gera um acréscimo no contrato existente.
 
**Integração:** recebe de Contratação de Planos; suspende ou encerra a geração de mensalidades (Cobrança).
 
---
 
### PN06. Montagem de Turmas e Horários
 
**Hoje (AS-IS):** as turmas são organizadas por cronograma de aulas, com horários definidos de acordo com a modalidade. Não há controle formal das vagas.
 
**No sistema (TO-BE):**
 
1. O CEO cria a turma com modalidade, professor responsável, dia da semana, horário de início e horário de fim. Há 4 turmas por dia, em horários diferentes. Aos sábados só há turma de Capoeira, que tem uma única turma.
2. O sistema só aceita o professor se ele ensina a modalidade da turma (cada professor tem uma única modalidade).
3. O aluno entra na turma pela matrícula. Ao chegar a 30 alunos ativos, o sistema bloqueia novas matrículas.
4. Regra de referência para abrir horário: Muay Thai 4 alunos (turma do CEO), Boxe 6, Jiu-Jitsu, Kickboxing e No-Gi 8, Capoeira 10. O sistema só alerta quando a turma tem menos alunos, porque na prática o professor pode dar o treino assim mesmo.
5. **Instrutor auxiliar:** o professor responsável pela modalidade pode escolher o aluno mais graduado para auxiliar, mas isso não é regra e não é marcado no sistema. Quando o CEO está dando sua aula de Muay Thai e precisa receber alunos novos, ele deixa um aluno mais graduado conduzindo o treino. Esse aluno é um instrutor auxiliar eventual, que não é funcionário nem é registrado, e a aula continua registrada em nome do professor responsável da turma.
**Dados registrados:** turma (modalidade, professor, dia, horário de início e fim) e quórum por modalidade.
 
**Integração:** fornece as turmas para Matrícula e Frequência.
 
---
 
### PN07. Controle de Frequência
 
**Hoje (AS-IS):** a presença não é registrada de forma alguma. A liberação para exame depende da percepção visual do professor (P4 P6).
 
**No sistema (TO-BE):**
 
1. Na aula, o professor abre a aula ministrada da turma: turma, data, horário e professor que a deu. No futuro, a catraca com reconhecimento facial registra a turma e o horário em que o aluno entrou.
2. O sistema lista os alunos com matrícula ativa. Alunos trancados ou bloqueados por atraso não têm presença registrada.
3. O professor marca presença ou falta de cada aluno.
4. O histórico fica guardado por matrícula. Cada professor consulta quais alunos já têm a frequência que ele exige para o exame.
**Reposição de aula (sem registro de presença)**
 
1. Quando o professor titular falta, o aluno tem direito a uma aula de reposição, na mesma modalidade ou em outra.
2. O professor confirma se há vaga na turma escolhida.
3. O aluno comparece e apenas assiste à aula: não é registrada presença para ele, porque não é matriculado nessa turma. No sistema fica registrada apenas a aula de reposição, ligada à aula perdida; quem usou a concessão não é registrado, e esse controle fica com o professor. A vaga ocupada por ele conta no limite de 30 da turma nessa aula.
**Funções do registro:** embasar a liberação para graduação e comprovar as aulas dadas, base do pagamento dos professores.
 
**Dados registrados:** aula (turma, data, hora de início e fim, professor); presença (aula, matrícula, presente ou ausente); reposição (aula de reposição ligada à aula perdida), sem presença e sem registro do aluno.
 
**Regras:** a frequência mínima para exame é definida por cada professor, não pela academia; aluno bloqueado não registra presença.
 
**Integração:** recebe de Matrícula, Turmas e Cobrança (bloqueio); envia para Graduação e para Pagamento dos Professores.
 
---
 
### PN08. Graduação e Exames de Faixa
 
**Hoje (AS-IS):** a evolução considera tempo de treino, técnica e resistência, mas depende da percepção visual do professor. A data da mudança de faixa fica só no certificado (P3 P4).
 
**No sistema (TO-BE):**
 
1. O professor consulta a frequência e o tempo de treino do aluno na modalidade e decide quem está apto. O professor também avalia se o aluno tem tempo de treino suficiente na faixa atual.
2. O aluno apto paga a taxa de exame, com valor diferente por faixa (as primeiras são mais baratas). A taxa é registrada no sistema (valores confidenciais) e cobrada junto com a mensalidade, paga por Pix, crédito ou débito.
3. O exame acontece. Muay Thai, Jiu-Jitsu, Kickboxing, No-Gi e Capoeira têm exame de faixa.
4. O professor registra o resultado do exame. A reprovação também é registrada, com o motivo em palavras-chave (por exemplo, condicionamento físico, técnica), para o professor entender por que os alunos estão reprovando.
5. **Boxe:** não há exame. A evolução é registrada como análise técnica do professor, com observação e data, sem faixa.
**Dados registrados:** aluno, modalidade, faixa ou nível avaliado (vazio no Boxe), data, resultado (aprovado ou reprovado), observações e motivo da reprovação, em palavras-chave; taxa de exame (valor, cobrada junto com a mensalidade).
 
**Regras:** apenas modalidades com sistema de faixas têm faixa; o aluno só faz exame com a frequência exigida pelo professor e o tempo de treino que o professor exige; reprovação fica no histórico.
 
**Integração:** recebe de Frequência e de Matrícula (tempo de treino); a taxa de exame vai para Cobrança e é cobrada junto com a mensalidade.
 
---
 
### PN09. Equipamentos da Academia
 
**Hoje (AS-IS):** a academia tem luvas, capacetes, caneleiras e materiais de treino funcional, usados por todos os alunos durante as aulas. Não há registro nem cobrança.
 
**No sistema (TO-BE):** não há processo de empréstimo. O aluno recém-matriculado pode treinar em qualquer modalidade sem equipamento próprio. Os equipamentos entram no sistema apenas pela compra (processo 10).
 
---
 
### PN10. Compras
 
**Hoje (AS-IS):** o CEO faz as compras de memória, sem inventário nem registro 
 
**No sistema (TO-BE):**
 
1. O CEO compra, em quatro grupos: materiais de treino (saco de pancada, cordas, pneus), sob demanda e conforme o desgaste; higiene e limpeza (álcool, descartáveis, sanitizantes, papel higiênico), semanal e presencial; equipamentos de proteção para os alunos (luvas, capacetes, caneleiras); e água para consumo, semanal, fornecida gratuitamente a todos.
2. O CEO registra cada compra no sistema e guarda a nota ou o comprovante. A academia não tem fornecedor fixo: o fornecedor muda de uma compra para outra.
3. Cada compra gera uma despesa em Contas a Pagar.
**Dados registrados:** data, grupo da compra, descrição, quantidade, valor total, forma de pagamento, nota ou comprovante guardado e fornecedor (o nome é anotado em cada compra, sem cadastro fixo).
 
**Regras:** sem controle de estoque nem de durabilidade (justificado na tabela de exclusões).
 
**Integração:** envia para Contas a Pagar.
 
---
 
### PN11. Gestão e Pagamento dos Professores
 
**Hoje (AS-IS):** o CEO é professor de Muay Thai. Os demais 5 professores são prestadores de serviço, não assalariados, um por modalidade (6 professores no total). Reposições e acordos são verbais, sem registro. As aulas ministradas não são registradas, então o pagamento por aula não tem base confiável (P6). A qualificação (tempo de treino, faixa, mestres anteriores) é só conversada.
 
**No sistema (TO-BE):**
 
1. O professor é cadastrado com CPF, nome, data de nascimento, endereço, e-mail, telefone, modalidade de atuação, nível de experiência e qualificações (tempo de treino, faixa, mestres anteriores).
2. A cada período, o CEO apura o valor devido a cada professor pelas aulas ministradas, a partir do registro de frequência. O valor por aula fica guardado no cadastro de cada professor prestador (VL_POR_AULA); o do CEO é 0, porque ele não recebe por aula.
3. O CEO paga o professor no 5º dia útil, por Pix.
4. O pagamento gera uma despesa em Contas a Pagar.
**Dados registrados:** professor, período de apuração, aulas ministradas, valor por aula, valor total, data de pagamento, forma de pagamento.
 
**Regras:** o pagamento depende do registro confiável das aulas ministradas; um professor só leciona a modalidade em que é especialista.
 
**Integração:** recebe de Frequência (aulas ministradas); envia para Contas a Pagar.
 
---
 
### PN12. Contas a Pagar
 
**Hoje (AS-IS):** não há controle sistematizado. O CEO guarda de memória os valores e as datas de vencimento 
 
**No sistema (TO-BE):**
 
1. O CEO registra todo mês cada despesa, uma por vencimento: aluguel, contas de consumo (água, luz etc.), manutenção, pagamento de professores e compras. O sistema registra o nome do credor (locador, concessionária, fornecedor), sem dados bancários.
2. O sistema mostra as despesas a vencer e as vencidas.
3. Ao pagar, o CEO registra a data de pagamento e a situação muda para Paga.
**Dados registrados:** descrição, categoria, credor, valor, data de vencimento, data de pagamento, situação.
 
**Integração:** recebe de Compras e de Pagamento dos Professores.
 
---
 
### Integração entre os processos
 
| Origem | Destino | O que passa | Efeito |
|---|---|---|---|
| Aula Experimental | Cadastro e Matrícula | Dados do interessado | Pré-cadastro vira aluno |
| Cadastro e Matrícula | Contratação de Planos | Aluno | Contrato é criado |
| Contratação de Planos | Cobrança | Contrato, valor, vigência | Geração mensal das mensalidades |
| Trancamento | Cobrança e Contrato | Período de trancamento | Suspende mensalidades e ajusta a data de fim |
| Cancelamento | Contrato e Cobrança | Data e multa rescisória | Encerra mensalidades |
| Cobrança | Frequência | Mensalidade atrasada | Aluno bloqueado, sem presença |
| Turmas e Matrícula | Frequência | Alunos ativos da turma | Lista de presença |
| Frequência (reposição) | Frequência | Aula perdida e aula de reposição | Reposição registrada, sem presença |
| Frequência | Graduação | Presenças por matrícula | Aptidão para exame |
| Graduação | Cobrança | Taxa de exame | Somada à mensalidade |
| Frequência | Pagamento dos Professores | Aulas ministradas | Valor a pagar |
| Compras e Pagamento dos Professores | Contas a Pagar | Valor e vencimento | Despesa registrada |
| Contratação de Planos | Contrato e Cancelamento | Fim do ciclo: aviso ao aluno e resposta | Contrato continua ou é cancelado e o aluno fica Inativo |

  ### Processos não incluídos e justificativa
 
| Processo comum em academias | Situação | Justificativa |
|---|---|---|
| Venda de produtos e suplementos | Não incluído | Não faz parte da demanda da academia; descartado no levantamento. |
| Folha de pagamento com encargos trabalhistas | Não incluído | O único contratado é o CEO e os demais professores são prestadores pagos por aula (processo 11). O CEO retira seu ganho das mensalidades e das taxas de exame, sem salário, então não há folha de pagamento. |
| Controle de estoque e durabilidade de equipamentos | Não incluído | A academia compra sob demanda e não tem esse controle; o registro de compras cobre o necessário. |
| Empréstimo de equipamentos | Não incluído | Os equipamentos são de uso livre nas aulas, sem registro nem cobrança. |
| Registro do instrutor auxiliar | Não incluído | O professor escolhe o aluno informalmente, sem regra fixa; não há necessidade de dado. |
| Marketing e divulgação | Não incluído | A divulgação é feita no Instagram, com vídeos produzidos sem custo e sem fluxo formal. Não há despesa, contrato ou pagamento a registrar. A aula experimental entra como processo (pré-cadastro) e preserva o primeiro contato do interessado. |
 
---
 

---

##  Requisitos do Sistema

###  Requisitos funcionais

* **RF01 - Gestão de Alunos, Responsáveis e Interessados:**


  > O sistema deve permitir o registro e a manutenção dos dados de interessados (aulas experimentais), alunos e responsáveis legais (obrigatório para menores de 18 anos), armazenando dados civis, endereço completo, múltiplos contatos, problemas de saúde, histórico de treino, data de entrega do atestado de aptidão física, autorização de uso de imagem e situação cadastral (Ativo, Inativo ou Trancado).
  
* **RF02 - Gestão e Qualificação de Professores:**

  > O sistema deve permitir o registro dos professores prestadores de serviço e do gestor técnico, vinculando cada docente à sua modalidade de atuação e registrando o valor de honorários por aula (VL_POR_AULA), especializações, nível de experiência e qualificações.

* **RF03 - Estruturação de Modalidades, Turmas e Matrículas:**

  > O sistema deve gerenciar o catálogo das seis modalidades esportivas (indicando o quórum mínimo de referência e a presença de sistema de faixas), a grade de turmas por dia e horário (respeitando o limite físico de 30 alunos ativos) e o histórico de matrículas e transferências de turma.

* **RF04 - Gestão de Planos, Contratos, Mensalidades e Despesas:**

  > O sistema deve formalizar contratos vinculados aos planos comerciais (Mensal, Trimestral, Semestral, Anual e Família), gerenciar as modalidades cobertas (PARTICIPA), gerar parcelas mensais em PAGAMENTO (com vencimento no 5.º dia útil, controle de atrasos, multas e taxas de exame) e escriturar as contas a pagar e repasses docentes na entidade DESPESA. O Plano Família existe como desconto aplicado aos contratos individuais de alunos da mesma família.

* **RF05 - Controle de Aulas Ministradas, Reposições e Presenças:**

  > O sistema deve registrar cada ocorrência datada de treino (AULA), identificando o professor efetivo, eventuais reposições (ID_AULA_ORIGEM) e a lista de chamada por matrícula ativa (PRESENCA), servindo de base para o cálculo de assiduidade e de honorários docentes.

* **RF06 - Registro de Exames de Graduação e Trancamentos:**

  > O sistema deve documentar o histórico de avaliações técnicas e exames de faixa em GRADUACAO (incluindo aprovações, reprovações e motivos), bem como controlar os períodos de afastamento médico em TRANCAMENTO, suspendendo o faturamento e ajustando o ciclo contratual.

###  Requisitos Não Funcionais

* **RNF01 - Independência Arquitetural e Escalabilidade Biométrica:**

  > A base de dados deve operar de forma desacoplada da camada de aplicação, mantendo chaves e índices preparados para integração futura com hardware de catraca eletrônica por reconhecimento facial.

* **RNF02 - Segurança, Privacidade e Conformidade com a LGPD:**

  > O sistema deve assegurar o controle de acesso baseado em perfis (Administração e Professor), a minimização de dados pessoais e sensíveis e a rastreabilidade de operações e consultas a CPF e DS_PROBLEMA_SAUDE por meio da tabela de auditoria LOG_ACESSO.

* **RNF03 - Desempenho e Tempo de Resposta em Consultas Críticas:**

  > A estrutura de indexação secundária e composta deve garantir que a apuração de frequência acumulada por matrícula e a listagem de alunos inadimplentes sejam processadas em tempo inferior a 2 segundos.

* **RNF04 - Integridade Transacional e Padronização de Codificação:**

  > A implementação física deve utilizar o SGBD MySQL 8.0 sob o motor de armazenamento InnoDB (assegurando suporte transacional ACID e integridade referencial por chaves estrangeiras) e codificação utf8mb4 / utf8mb4_unicode_ci.

* **RNF05 - Disponibilidade, Retenção e Cópias de Segurança (Backup):**

  > A arquitetura de armazenamento deve contemplar rotinas automatizadas de backup diário com rotação em ciclos de até 30 dias, preservando a retenção fiscal de 5 anos para registros contratuais e financeiros.

##  Regras de Negócio (Restrições e Diretrizes Operacionais)

*(Numeração estritamente sincronizada com as referências cruzadas do Dicionário de Dados v2.1)*

###  Regras Operacionais

*(Condições e processos de funcionamento estipulados pela administração da academia)*

* **RO01 - Estrutura de Planos, Abrangência e Plano Família**

  > A academia comercializa planos nas durações Mensal, Trimestral, Semestral e Anual, aplicando descontos progressivos exclusivos do plano (nunca individuais). O plano regular contempla uma modalidade, permitindo a adição de modalidades extras no mesmo contrato (PARTICIPA) mediante acréscimo financeiro. O Plano Família aplica-se a qualquer duração para grupos de dois a cinco alunos da mesma família (um aluno e até 4 familiares), cada um com o seu contrato.

* **RO02 - Padronização do Vencimento no 5.º Dia Útil**

  > Independentemente da data de assinatura da matrícula ou da duração do plano, todas as mensalidades são geradas mês a mês com valor integral (sem cálculo proporcional na adesão) e vencimento fixo no 5.º dia útil de cada mês.

* **RO03 - Concessão Única de Aula Experimental Gratuita**

  > Cada interessado tem direito a realizar apenas uma aula experimental gratuita, agendada previamente e validada pela combinação única de nome e telefone (NM_INTERESSADO, NR_TELEFONE), ficando o registro classificado como Pendente, Convertido ou Encerrado.

* **RO04 - Multa Rescisória e Multa Moratória em Planos de Fidelidade**

  > O cancelamento antecipado ou o atraso mensal em contratos Trimestrais, Semestrais ou Anuais (inclusive na modalidade Família) acarreta a cobrança de multa contratual proporcional (VL_MULTA_RESCISORIA no contrato ou VL_MULTA na parcela). Os planos de ciclo Mensal estão isentos de multas rescisórias e moratórias, sofrendo apenas bloqueio operacional em caso de atraso.

* **RO05 - Critério de Assiduidade e Tempo Mínimo para Exames de Graduação**

  > A aptidão do aluno para prestar exame de faixa condiciona-se ao tempo de treino na faixa atual e à frequência mínima comprovada nos registros da tabela PRESENCA, segundo o critério pedagógico do professor titular da modalidade.

* **RO06 - Exceção Avaliativa da Modalidade Boxe**

  > Nas modalidades com sistema de graduação formal (Muay Thai, Jiu-Jitsu, Kickboxing, Capoeira e No-Gi), a progressão ocorre via exame de faixa (TP_EXAME_FAIXA) mediante pagamento de taxa de exame integrada na mensalidade. Na modalidade de Boxe (IN_POSSUI_SISTEMA_FAIXAS = false), não há faixas nem cobrança de taxa, sendo a evolução registrada como análise técnica (TP_ANALISE_TECNICA).

* **RO07 - Apuração de Repasse Docente e Papel do Instrutor Auxiliar**

  > Os cinco professores prestadores de serviço recebem valor fixo por aula efetivamente ministrada (VL_POR_AULA), apurado a partir das ocorrências registradas na entidade AULA e liquidado no 5.º dia útil via lançamento em DESPESA. O apoio eventual de alunos mais graduados como instrutores auxiliares durante os treinos não gera vínculo formal, remuneração nem registro próprio no sistema.

###  Restrições Organizacionais e de Integridade

*(Limitações físicas, jurídicas e lógicas que impõem barreiras ao modelo de dados)*

* **RE01 - Capacidade Física Máxima de 30 Alunos por Turma**

  > Cada turma possui limite operacional estrito de 30 matrículas ativas simultâneas (QT_CAPACIDADE_MAXIMA = 30). O sistema deve impedir novas matrículas na turma quando esse teto for atingido e contabilizar eventuais alunos em reposição de aula dentro do limite físico do tatame.

* **RE02 - Quórum Mínimo de Referência por Modalidade**

  > A abertura e manutenção de horários observa o parâmetro mínimo de referência de cada modalidade (QT_MINIMA_REFERENCIA: Muay Thai = 4; Boxe = 6; Jiu-Jitsu, Kickboxing e No-Gi = 8; Capoeira = 10). Quando a ocupação ativa for inferior ao parâmetro, o sistema emite um alerta gerencial, sem bloquear a realização da aula.

* **RE03 - Obrigatoriedade de Responsável Legal para Menores de 18 Anos e de Atestado para Todos os Alunos**

  > Para o registro de alunos com idade inferior a 18 anos (calculada a partir de DT_NASCIMENTO), o sistema exige obrigatoriamente a vinculação a um registro válido na entidade RESPONSAVEL (ID_RESPONSAVEL) e o consentimento formal do responsável para tratamento de dados e uso de imagem (Art. 14.º da LGPD). O atestado de aptidão física é exigido de todos os alunos, adultos e menores; a coluna DT_ENTREGA_ATESTADO é opcional e fica em branco até a entrega.

* **RE04 - Condicionalidade para Trancamento de Matrícula**

  > O trancamento de matrícula (TRANCAMENTO) é permitido exclusivamente por motivo de lesão esportiva ou razão médica (TP_LESAO | TP_RAZAO_MEDICA), comunicado presencialmente ou via WhatsApp sem exigência de laudo formal obrigatório. Durante a vigência do trancamento, suspendem-se a geração de mensalidades e a contagem de prazo do contrato, ajustando-se a data de término (DT_FIM).

* **RE05 - Exclusividade de Especialização Docente por Modalidade**

  > Cada professor atua exclusivamente numa única modalidade esportiva (ID_MODALIDADE em PROFESSOR). O sistema deve validar a compatibilidade referencial de modo que o docente só possa ser alocado a turmas, aulas e avaliações de graduação pertencentes à sua modalidade de especialização.

* **RE06 - Domínio de Situação Cadastral e Preservação de Histórico**

  > O estado cadastral do aluno restringe-se a TP_ATIVO (contrato vigente), TP_INATIVO (contrato encerrado/cancelado) ou TP_TRANCADO (afastamento médico em curso). Na entidade MATRICULA, o estado admite TP_ATIVA, TP_TRANCADA, TP_ENCERRADA (utilizada na transferência de turma/modalidade) e TP_CANCELADA. Registros de matrículas encerradas, contratos, pagamentos e despesas nunca sofrem exclusão física, preservando a rastreabilidade histórica e fiscal.

* **RE07 - Bloqueio Operacional e de Frequência por Inadimplência**

  > A inadimplência é derivada das parcelas em PAGAMENTO. Caso a fatura não seja liquidada até o 5.º dia útil, o título assume o estado TP_ATRASADO e, a partir do 6.º dia útil, o aluno fica bloqueado operacionalmente, impedindo a inserção de registros de presença na tabela PRESENCA até a regularização financeira.

---
### **Requisitos e regras prováveis não incluídos (Justificativas)**

* **Módulo Comercial (Venda de Artigos Esportivos e Cantina):** É uma regra de negócio comum em academias o controle de vendas de uniformes, faixas, luvas e suplementos. O escopo deste projeto, no entanto, foi estritamente delimitado para sanar a crise operacional prioritária da instituição: o controle de matrículas, frequência e inadimplência. A inclusão de um módulo de vendas exigiria entidades de estoque, fornecedores e fluxo de caixa paralelo, o que inflaria o modelo e desviaria o foco do problema principal.


* **Operação Direta de Controle de Acesso (Catracas/Biometria):** Sistemas de academias frequentemente incluem o controle direto de hardware para bloqueio de inadimplentes. O projeto não contempla a operação direta de hardware ou o software da catraca. A regra não foi incluída porque o banco de dados atua apenas como fornecedor da informação (situação financeira do aluno); a arquitetura foi preparada para o consumo desses dados no futuro (RNF01), sem assumir a responsabilidade pela execução do bloqueio físico.


* **Gestão de Planos Familiares e Dependentes:** Muitos sistemas esportivos possuem regras comerciais para agrupar múltiplos alunos sob um único contrato familiar com desconto. Atributos relacionados a parentesco e responsáveis por planos foram deliberadamente removidos nesta versão (v2.1 e v2.3). Optou-se por manter a relação de cobrança simplificada, onde o responsável legal está vinculado ao cadastro do menor para fins da LGPD, mas os contratos (CONTRATO) e pagamentos (PAGAMENTO) permanecem individualizados por aluno, adiando a complexidade de faturamentos agrupados para escopos futuros. O Plano Família existe como desconto aplicado a contratos individuais de alunos da mesma família; a cobrança conjunta ao responsável, quando houver, é tratada fora do sistema (seção 1.5, item 11).


* **Tabela de Autenticação e Usuários do Sistema:** É requisito comum o cadastro de usuários com login e senha criptografada. Como o foco da entrega é a modelagem dos processos de negócio da academia, a criação de uma entidade de gestão de usuários foi abstraída. A rastreabilidade exigida pela LGPD foi atendida de forma simplificada na tabela `LOG_ACESSO`, que registra o nome do usuário em formato de texto livre, dispensando uma chave estrangeira complexa para uma tabela de credenciais que não seria utilizada nas consultas analíticas.


* **Agendamento de Reposições Via Aplicativo:** Regras sobre limite de reagendamentos e interface para o aluno marcar aulas não foram incluídas. O escopo restringe-se ao backend de dados. A modelagem resolve a reposição apenas no nível do banco (via auto-relacionamento na tabela AULA) para registro histórico e cálculo de honorários, assumindo que a validação de vagas nessas aulas será feita pela camada de aplicação, e não por restrições do banco.
---

##  Dicionário de Dados Conceitual

Abaixo está o dicionário de dados completo em uma imagem **clicável**, com todas as entidades e atributos que constam no Diagrama:

[![Website Preview Screenshot](img/img_preview_dicionario.png)](https://williamsvargas-code.github.io/Readme_academia/)


---

##  Diagrama Entidade-Relacionamento (DER) e Evolução do Modelo

###   Diagrama Entidade-Relacionamento (DER)

O Diagrama Entidade-Relacionamento (DER) conceitual consolida a totalidade dos processos operacionais, pedagógicos e administrativos da Academia Base Forte Leste, estruturado a partir das entrevistas de campo e das correções apontadas na Entrega 01. O modelo adota a notação clássica de Peter Chen com especificação de cardinalidades mínimas e máximas (mín, máx) em ambas as extremidades das relações. Em estrita conformidade com as diretrizes teóricas de modelagem conceitual, o diagrama não contém chaves estrangeiras (FKs), as quais são derivadas formalmente apenas na etapa lógica. O esquema integra 14 entidades interdependentes, garantindo a rastreabilidade de aulas, frequência diária, contratos, controle de capacidade por turma (teto de 30 alunos), afastamentos médicos e salvaguardas da LGPD para menores de idade.

<img width="2082" height="1485" alt="diagrama_er" src="./img/Diagrama Entidade Relacionamento.png" />

**Legenda:** O Diagrama Entidade-Relacionamento (DER) conceitual deste projeto foi elaborado e estruturado por meio da ferramenta brModelo Web (https://app.brmodeloweb.com/publicview/6ae6fb2559aaf5bef87df443).


---

### 1.2 Conversão do Modelo Conceitual para o Modelo Lógico

A conversão partiu do DER revisado (criado no **brModelo Web**, seção 1.1) e usou o conversor da própria ferramenta, seguido de ajustes manuais no modelo lógico (tipos de dados, nomes e restrições). O resultado são **25 tabelas**: 14 vindas de entidades, 2 de relacionamentos N:N, 8 de atributos multivalorados e 1 tabela de auditoria independente do DER (`LOG_ACESSO`).

Os nomes foram padronizados em maiúsculas, sem acentos e sem espaços (`MATRICULA`, `GRADUACAO`, `PRESENCA`). As colunas seguem os prefixos do dicionário de dados: `ID_` (identificador), `NM_` (nome), `DT_` (data), `HR_` (horário), `DS_` (descrição, texto livre ou domínio textual como `DS_DIA_SEMANA`), `NR_` (número que não sofre operação matemática), `QT_` (quantidade), `VL_` (valor monetário), `PC_` (percentual), `TP_` (tipo ou situação) e `IN_` (indicador booleano). As colunas FK têm o mesmo nome da PK que referenciam (ex.: `MATRICULA.ID_ALUNO` referencia `ALUNO.ID_ALUNO`). A única exceção é `AULA.ID_AULA_ORIGEM`, que referencia a própria tabela `AULA` e por isso tem nome distinto da PK.

* **Entidades → Tabelas:**
  * Cada uma das 14 entidades do DER virou uma tabela com **PK sintética própria** (`INT AUTO_INCREMENT`): `ALUNO`, `RESPONSAVEL`, `INTERESSADO`, `MODALIDADE`, `PROFESSOR`, `TURMA`, `MATRICULA`, `TRANCAMENTO`, `AULA`, `GRADUACAO`, `PLANO`, `CONTRATO`, `PAGAMENTO` e `DESPESA`.
  * `RESPONSAVEL`, `MODALIDADE` e `PLANO` não recebem nenhuma FK. As demais tabelas carregam FKs para as tabelas das quais dependem (seção 1.3).
  * Nenhuma entidade é fraca no sentido formal, porque todas têm identificador próprio. A dependência entre elas aparece apenas nas FKs.
  * `MATRICULA` resolve a relação entre `ALUNO` e `TURMA` (um aluno pode estar em várias turmas e uma turma tem vários alunos). Ela virou tabela própria, e não apenas tabela associativa, porque tem atributos (`DT_MATRICULA`, `TP_SITUACAO_MATRICULA`) e se relaciona com outras tabelas (`TRANCAMENTO` e `PRESENCA`).
  * Os 2 relacionamentos N:N viraram as tabelas associativas `PRESENCA` e `PARTICIPA`.
  * Os atributos multivalorados viraram 8 tabelas dedicadas (ver abaixo).
  * `LOG_ACESSO` não vem de nenhuma entidade do DER: é a tabela de auditoria que registra quem leu ou alterou dados pessoais (**RNF02**). Ela não tem FK para as demais tabelas (justificativa na seção 1.5) e não entra nas contagens de entidades e relacionamentos.

* **Atributos → Colunas:**
  * Atributos simples viraram colunas com os tipos do brModelo Web: `INT`, `VARCHAR`, `CHAR`, `DATE`, `TIME`, `TIMESTAMP`, `BOOLEAN`, `DECIMAL` e `ENUM`. Os valores monetários (`VL_`) e o percentual `PC_DESCONTO` usam `DECIMAL`, que guarda o valor exato, sem o erro de arredondamento do `FLOAT`. O dicionário de dados define a precisão (`DECIMAL(10,2)` para valores monetários e `DECIMAL(5,2)` para o percentual), os tamanhos de `VARCHAR`/`CHAR` e os valores dos `ENUM`. Os três campos de texto longo (`DS_HISTORICO_TREINO`, `DS_MOTIVO` e `DS_CONDICAO`) são `TEXT` no dicionário.
  * **Atributo composto:** `Endereco` foi desmembrado nas colunas `DS_RUA`, `NR_LOGRADOURO`, `NM_BAIRRO` e `NR_CEP` em `ALUNO` e em `PROFESSOR`. `RESPONSAVEL` não guarda endereço.
  * **Atributos multivalorados:** cada um virou uma tabela própria, com PK composta formada pela FK do dono e pelo valor:

    | Dono | Atributo no DER | Tabela | Coluna do valor |
    | --- | --- | --- | --- |
    | `ALUNO` | Problema_Saude | `PROBLEMA_SAUDE_ALUNO` | `DS_PROBLEMA_SAUDE` |
    | `ALUNO` | Email | `EMAIL_ALUNO` | `DS_EMAIL` |
    | `ALUNO` | Telefone | `TELEFONE_ALUNO` | `NR_TELEFONE` |
    | `PROFESSOR` | Registro_Qualificacoes | `REGISTRO_QUALIFICACOES` | `DS_REGISTRO_QUALIFICACOES` |
    | `PROFESSOR` | Especializacao | `ESPECIALIZACAO` | `DS_ESPECIALIZACAO` |
    | `PROFESSOR` | Nivel_De_Experiencia | `NIVEL_DE_EXPERIENCIA` | `DS_NIVEL_EXPERIENCIA` |
    | `PROFESSOR` | Email | `EMAIL_PROFESSOR` | `DS_EMAIL` |
    | `PROFESSOR` | Telefone | `TELEFONE_PROFESSOR` | `NR_TELEFONE` |

    O problema de saúde existe apenas para o aluno: o MER não o prevê para o professor, e por isso não há tabela equivalente para ele.
  * **Atributo de relacionamento:** `Presenca` pertence ao relacionamento Aula–Matrícula, e por isso fica na tabela associativa `PRESENCA`, na coluna `IN_PRESENTE`.
  * **Atributo derivado:** as vagas ocupadas de uma turma não são armazenadas. A ocupação é calculada por contagem das matrículas ativas.
  * **Identificadores:** cada atributo identificador do DER virou a PK da tabela. O `CPF` não é PK: ele é chave alternativa (`UNIQUE`) em `ALUNO`, `PROFESSOR` e `RESPONSAVEL`.
  * **Colunas de conformidade e auditoria:** `IN_ACEITE_USO_IMAGEM`, `DT_AUTORIZACAO_IMAGEM`, `DT_ENTREGA_ATESTADO`, `ID_AULA_ORIGEM`, `TP_RESULTADO`, `DS_MOTIVO_REPROVACAO`, `DT_INICIO`, `DT_RETORNO_PREVISTA` e `DT_RETORNO_EFETIVA`.

* **Relacionamentos → Chaves:**
  * **1:N:** a PK do lado "1" é propagada como FK para a tabela do lado "N".
  * **1:1:** a PK de uma das entidades vira FK na outra, com restrição `UNIQUE`.
  * **N:N:** é criada uma tabela associativa, cuja PK composta é formada pelas FKs das duas entidades.
  * As cardinalidades são lidas na convenção *Look-Across*, adotada pelo brModelo Web e pela disciplina. Na revisão do DER, 10 relações estavam com os rótulos trocados de lado e foram corrigidas. Sem essa correção, o conversor teria colocado as FKs na tabela errada.

  | Relacionamento no DER | Cardinalidade | FK criada |
  | --- | --- | --- |
  | Responsável Legal (`RESPONSAVEL`–`ALUNO`) | 1:N, opcional | `ALUNO.ID_RESPONSAVEL` |
  | Torna-se (`INTERESSADO`–`ALUNO`) | 1:1, opcional | `ALUNO.ID_INTERESSADO` (+ `UNIQUE`) |
  | Escolhe (`MODALIDADE`–`INTERESSADO`) | 1:N | `INTERESSADO.ID_MODALIDADE` |
  | Domina (`MODALIDADE`–`PROFESSOR`) | 1:N | `PROFESSOR.ID_MODALIDADE` |
  | Oferece (`MODALIDADE`–`TURMA`) | 1:N | `TURMA.ID_MODALIDADE` |
  | Leciona (`PROFESSOR`–`TURMA`) | 1:N | `TURMA.ID_PROFESSOR` |
  | Realiza (`ALUNO`–`MATRICULA`) | 1:N | `MATRICULA.ID_ALUNO` |
  | Vincula (`TURMA`–`MATRICULA`) | 1:N | `MATRICULA.ID_TURMA` |
  | Trancamento (`MATRICULA`–`TRANCAMENTO`) | 1:N | `TRANCAMENTO.ID_MATRICULA` |
  | Realiza (`TURMA`–`AULA`) | 1:N | `AULA.ID_TURMA` |
  | Ministra (`PROFESSOR`–`AULA`) | 1:N | `AULA.ID_PROFESSOR` |
  | Obtém (`ALUNO`–`GRADUACAO`) | 1:N | `GRADUACAO.ID_ALUNO` |
  | Avalia (`PROFESSOR`–`GRADUACAO`) | 1:N | `GRADUACAO.ID_PROFESSOR` |
  | Referencia (`MODALIDADE`–`GRADUACAO`) | 1:N | `GRADUACAO.ID_MODALIDADE` |
  | Possui (`ALUNO`–`CONTRATO`) | 1:N | `CONTRATO.ID_ALUNO` |
  | Define (`PLANO`–`CONTRATO`) | 1:N | `CONTRATO.ID_PLANO` |
  | Gera (`CONTRATO`–`PAGAMENTO`) | 1:N | `PAGAMENTO.ID_CONTRATO` |
  | Gera (`PROFESSOR`–`DESPESA`) | 1:N, opcional | `DESPESA.ID_PROFESSOR` |
  | Reposição (`AULA`–`AULA`, auto-relacionamento) | 1:N, opcional | `AULA.ID_AULA_ORIGEM` |
  | Registra Presença (`AULA`–`MATRICULA`) | N:N | tabela `PRESENCA` |
  | Participa (`CONTRATO`–`MODALIDADE`) | N:N | tabela `PARTICIPA` |

* **Cardinalidades:**
  * **1:1 (`ALUNO`–`INTERESSADO`):** a FK `ID_INTERESSADO` fica em `ALUNO`, é opcional e tem `UNIQUE`. Nem todo interessado vira aluno, e nem todo aluno passou por aula experimental. A FK fica em `ALUNO` porque o aluno é criado depois da conversão do interessado.
  * **1:N (18 relações, tabela acima):** a FK fica sempre na tabela do lado "N". Exemplos: `MATRICULA.ID_ALUNO`, `AULA.ID_TURMA`, `PAGAMENTO.ID_CONTRATO`. A opcionalidade da FK segue a cardinalidade mínima: `(0, …)` gera coluna sem `NOT NULL` e `(1, …)` gera coluna `NOT NULL`.
  * **N:N (2 relações):** `PRESENCA` (`ID_AULA` + `ID_MATRICULA`, com o atributo `IN_PRESENTE`) e `PARTICIPA` (`ID_MODALIDADE` + `ID_CONTRATO`, que permite várias modalidades em um único contrato).
  * `ALUNO`–`RESPONSAVEL` **não** é N:N: um responsável pode responder por vários alunos, mas cada aluno tem no máximo um responsável (aluno maior de idade não tem). Por isso a FK fica em `ALUNO`.
  * `TRANCAMENTO`–`MATRICULA` também é 1:N: uma matrícula pode ter vários trancamentos ao longo do tempo.
  * `AULA`–`AULA` (reposição) é um auto-relacionamento 1:N opcional: no DER a aula de origem é o atributo `Aula_Origem`, e no modelo lógico ele virou a FK `ID_AULA_ORIGEM`, que aponta para a aula original que a reposição repõe. A aula regular fica com a coluna nula.

* **Generalização/especialização:**
  * O DER não utiliza generalização/especialização.
  * **Estratégia adotada:** uma tabela por entidade independente.
  * **Justificativa:** `ALUNO`, `PROFESSOR` e `RESPONSAVEL` têm papéis jurídicos, ciclos de vida, fluxos financeiros e atributos distintos. Uni-los em uma tabela genérica geraria colunas nulas em excesso e violaria o princípio de minimização de dados da LGPD (**RNF02**).

Representatividade em imagem do modelo lógico:

<img alt="diagrama_log" src="./img/Modelo Logico V6.png" />

**Legenda**: O Modelo Lógico deste projeto foi elaborado e estruturado por meio da ferramenta brModelo Web ([https://app.brmodeloweb.com/publicview/6ae6fb2559aaf5bef87df443).](https://app.brmodeloweb.com/publicview/6ae6fb2559aaf5bef87df443)

---

### 1.3 Definição de Chaves Primárias e Estrangeiras

Listagem das PKs e FKs das **25 tabelas** do modelo lógico. Total: 25 PKs e 31 colunas FK (19 de relacionamentos 1:N e 1:1, incluindo o auto-relacionamento de `AULA`, 4 das tabelas N:N e 8 dos multivalorados). `LOG_ACESSO` não tem FK.

| # | Tabela | Chave Primária (PK) | Chave Estrangeira (FK) | Origem da FK |
| --- | --- | --- | --- | --- |
| 1 | `ALUNO` | `ID_ALUNO` | `ID_RESPONSAVEL` *(opcional)*<br>`ID_INTERESSADO` *(opcional, `UNIQUE`)* | `RESPONSAVEL(ID_RESPONSAVEL)`<br>`INTERESSADO(ID_INTERESSADO)` |
| 2 | `RESPONSAVEL` | `ID_RESPONSAVEL` | *Nenhuma* | — |
| 3 | `INTERESSADO` | `ID_INTERESSADO` | `ID_MODALIDADE` | `MODALIDADE(ID_MODALIDADE)` |
| 4 | `MODALIDADE` | `ID_MODALIDADE` | *Nenhuma* | — |
| 5 | `PROFESSOR` | `ID_PROFESSOR` | `ID_MODALIDADE` | `MODALIDADE(ID_MODALIDADE)` |
| 6 | `TURMA` | `ID_TURMA` | `ID_MODALIDADE`<br>`ID_PROFESSOR` | `MODALIDADE(ID_MODALIDADE)`<br>`PROFESSOR(ID_PROFESSOR)` |
| 7 | `MATRICULA` | `ID_MATRICULA` | `ID_ALUNO`<br>`ID_TURMA` | `ALUNO(ID_ALUNO)`<br>`TURMA(ID_TURMA)` |
| 8 | `TRANCAMENTO` | `ID_TRANCAMENTO` | `ID_MATRICULA` | `MATRICULA(ID_MATRICULA)` |
| 9 | `AULA` | `ID_AULA` | `ID_PROFESSOR`<br>`ID_TURMA`<br>`ID_AULA_ORIGEM` *(opcional)* | `PROFESSOR(ID_PROFESSOR)`<br>`TURMA(ID_TURMA)`<br>`AULA(ID_AULA)` |
| 10 | `GRADUACAO` | `ID_GRADUACAO` | `ID_ALUNO`<br>`ID_PROFESSOR`<br>`ID_MODALIDADE` | `ALUNO(ID_ALUNO)`<br>`PROFESSOR(ID_PROFESSOR)`<br>`MODALIDADE(ID_MODALIDADE)` |
| 11 | `PLANO` | `ID_PLANO` | *Nenhuma* | — |
| 12 | `CONTRATO` | `ID_CONTRATO` | `ID_ALUNO`<br>`ID_PLANO` | `ALUNO(ID_ALUNO)`<br>`PLANO(ID_PLANO)` |
| 13 | `PAGAMENTO` | `ID_PAGAMENTO` | `ID_CONTRATO` | `CONTRATO(ID_CONTRATO)` |
| 14 | `DESPESA` | `ID_DESPESA` | `ID_PROFESSOR` *(opcional)* | `PROFESSOR(ID_PROFESSOR)` |
| 15 | `PRESENCA` | `ID_AULA`, `ID_MATRICULA` *(composta)* | `ID_AULA`<br>`ID_MATRICULA` | `AULA(ID_AULA)`<br>`MATRICULA(ID_MATRICULA)` |
| 16 | `PARTICIPA` | `ID_MODALIDADE`, `ID_CONTRATO` *(composta)* | `ID_MODALIDADE`<br>`ID_CONTRATO` | `MODALIDADE(ID_MODALIDADE)`<br>`CONTRATO(ID_CONTRATO)` |
| 17 | `PROBLEMA_SAUDE_ALUNO` | `ID_ALUNO`, `DS_PROBLEMA_SAUDE` *(composta)* | `ID_ALUNO` | `ALUNO(ID_ALUNO)` |
| 18 | `EMAIL_ALUNO` | `ID_ALUNO`, `DS_EMAIL` *(composta)* | `ID_ALUNO` | `ALUNO(ID_ALUNO)` |
| 19 | `TELEFONE_ALUNO` | `ID_ALUNO`, `NR_TELEFONE` *(composta)* | `ID_ALUNO` | `ALUNO(ID_ALUNO)` |
| 20 | `REGISTRO_QUALIFICACOES` | `ID_PROFESSOR`, `DS_REGISTRO_QUALIFICACOES` *(composta)* | `ID_PROFESSOR` | `PROFESSOR(ID_PROFESSOR)` |
| 21 | `ESPECIALIZACAO` | `ID_PROFESSOR`, `DS_ESPECIALIZACAO` *(composta)* | `ID_PROFESSOR` | `PROFESSOR(ID_PROFESSOR)` |
| 22 | `NIVEL_DE_EXPERIENCIA` | `ID_PROFESSOR`, `DS_NIVEL_EXPERIENCIA` *(composta)* | `ID_PROFESSOR` | `PROFESSOR(ID_PROFESSOR)` |
| 23 | `EMAIL_PROFESSOR` | `ID_PROFESSOR`, `DS_EMAIL` *(composta)* | `ID_PROFESSOR` | `PROFESSOR(ID_PROFESSOR)` |
| 24 | `TELEFONE_PROFESSOR` | `ID_PROFESSOR`, `NR_TELEFONE` *(composta)* | `ID_PROFESSOR` | `PROFESSOR(ID_PROFESSOR)` |
| 25 | `LOG_ACESSO` | `ID_LOG` | *Nenhuma* | — |

---

### 1.4 Processo de Normalização (1FN, 2FN e 3FN)

O modelo relacional foi submetido às três primeiras Formas Normais para eliminar redundâncias e evitar anomalias de inclusão, alteração e exclusão.

* **1FN (Primeira Forma Normal — Atomicidade e Eliminação de Repetições):**
  * Todos os atributos guardam valores atômicos.
  * O atributo composto `Endereco` foi desmembrado em `DS_RUA`, `NR_LOGRADOURO`, `NM_BAIRRO` e `NR_CEP`.
  * Os atributos multivalorados (telefones, e-mails e problemas de saúde dos alunos; telefones, e-mails, qualificações, especializações e níveis de experiência dos professores) foram isolados em 8 tabelas próprias. Assim não há colunas repetidas como `Telefone1` e `Telefone2`, e não há limite artificial de quantidade.
  * As relações N:N (frequência por aula e modalidades por contrato) foram isoladas em `PRESENCA` e `PARTICIPA`.

* **2FN (Segunda Forma Normal — Dependência Funcional Total):**
  * O modelo está na 1FN, e nenhum atributo não-chave depende de apenas parte da PK.
  * As 14 tabelas de entidade e `LOG_ACESSO` têm PK de uma única coluna, o que elimina por construção a possibilidade de dependência parcial.
  * Nas tabelas de PK composta, a verificação foi feita uma a uma:
    * `PRESENCA`: `IN_PRESENTE` só existe para o par `(ID_AULA, ID_MATRICULA)`. Saber se o aluno estava presente exige as duas informações.
    * `PARTICIPA`: não tem atributos além da chave.
    * As 8 tabelas de multivalorados têm apenas a FK do dono e o valor, ambos na chave.

* **3FN (Terceira Forma Normal — Eliminação de Dependências Transitivas):**
  * O modelo está na 2FN e, exceto pelas três dependências residuais mantidas de propósito (descritas abaixo), nenhum atributo não-chave depende de outro atributo não-chave. Pontos tratados:
    * **Modalidade em `MATRICULA`:** no DER antigo, a matrícula guardava o esporte praticado. Esse dado depende da turma, não da matrícula. O atributo foi removido, e a modalidade é obtida por `MATRICULA → TURMA → MODALIDADE`.
    * **Vagas ocupadas em `TURMA`:** é um dado derivado, calculado por contagem de matrículas ativas. Foi substituído por `QT_CAPACIDADE_MAXIMA`, que é um limite fixo.
    * **Valor do contrato:** `VL_MENSAL_ACORDADO` fica em `CONTRATO`. Ele é um fato do contrato, definido na assinatura, e não pode ser recalculado a partir de `PLANO.VL_MENSALIDADE`. Assim, reajustes futuros no plano não alteram contratos nem parcelas já geradas em `PAGAMENTO`.
    * **Valor da taxa de graduação:** `PAGAMENTO.VL_TAXA_GRADUACAO` guarda o valor cobrado naquele pagamento, sem depender de tabelas de preços posteriores.
    * **Remuneração docente:** `VL_POR_AULA` fica somente em `PROFESSOR`. `TURMA` e `AULA` guardam apenas `ID_PROFESSOR`, evitando que o valor varie por registro.
  * **Dependência transitiva residual, mantida de forma deliberada:** como cada professor atua em uma única modalidade (`PROFESSOR.ID_MODALIDADE`), a modalidade de uma `TURMA` e a de uma `GRADUACAO` poderiam ser deduzidas a partir do `ID_PROFESSOR` (regra **RE05**). As colunas `TURMA.ID_MODALIDADE` e `GRADUACAO.ID_MODALIDADE` foram mantidas porque:
    * a modalidade define a grade de turmas e o histórico de faixas, e esses relacionamentos pertencem ao domínio por si mesmos, e não só como consequência do professor;
    * as consultas por modalidade ficam diretas, sem junção adicional com `PROFESSOR`;
    * a consistência entre as duas informações será verificada por consulta de auditoria no script SQL (seção 3).
  * **Dependência residual do CEP, também deliberada:** em `ALUNO` e `PROFESSOR`, `NR_CEP` determinaria rua e bairro (`DS_RUA`, `NM_BAIRRO`). As três colunas foram mantidas porque o endereço é digitado no cadastro (processo 2), a academia não dispõe de uma base de logradouros para consultar e um CEP pode cobrir vários endereços (CEP geral de bairro ou cidade), o que impede deduzir a rua com segurança.
  * **Dependência residual em `LOG_ACESSO`, também deliberada:** `TP_PERFIL` poderia ser deduzido de `NM_USUARIO`, mas o log guarda o perfil usado em cada acesso (um retrato do momento), e esta versão não tem tabela de usuários. `NM_TABELA` e `ID_REGISTRO` formam uma referência lógica, não uma FK.

* **Justificativa do Processo:**
  * **1FN:** sem ela, o cadastro de um aluno com vários telefones ou e-mails exigiria colunas fixas ou texto concatenado, o que impede buscas e validações.
  * **2FN:** garante que a frequência (`PRESENCA`) e a participação em modalidades (`PARTICIPA`) sejam registradas sempre pelo par de chaves completo, sem informação solta.
  * **3FN:** os dados financeiros e contratuais precisam ser alterados em um único ponto e nunca retroativamente (reajuste de plano, taxa de graduação, honorários). Isso assegura a auditabilidade exigida pela gestão da academia.

---

### 1.5 Justificativas Técnicas das Decisões

#### 1. Justificativa das Chaves Primárias (PKs)

* As 14 tabelas de entidade e `LOG_ACESSO` usam **chaves primárias sintéticas** do tipo `INT AUTO_INCREMENT`.
  * **Motivo técnico:** inteiros curtos tornam os índices e as junções mais rápidos e ocupam menos espaço do que chaves naturais.
  * **Motivo de privacidade:** o `CPF` não foi usado como PK porque ele seria copiado para todas as tabelas filhas como FK, espalhando um dado pessoal pelo banco e contrariando a minimização de dados da LGPD (**RNF02**). Ele permanece como chave alternativa (`UNIQUE`).
* As tabelas de N:N (`PRESENCA`, `PARTICIPA`) e as 8 de atributos multivalorados usam **PK composta** formada pelas FKs ou pelo valor. A própria combinação identifica o registro e impede duplicidade (o mesmo aluno não é registrado duas vezes na mesma aula, o mesmo e-mail não é repetido para o mesmo aluno).

#### 2. Justificativa das Chaves Estrangeiras (FKs) e Relacionamentos

* **`ALUNO` → `RESPONSAVEL` (`ID_RESPONSAVEL`, opcional):** vincula o aluno menor de idade ao responsável legal, conforme o Art. 14 da LGPD. É opcional porque o aluno maior de idade não tem responsável.
* **`ALUNO` → `INTERESSADO` (`ID_INTERESSADO`, opcional, `UNIQUE`):** registra a origem do aluno que fez aula experimental e permite medir a conversão. É opcional para permitir cadastro direto, sem aula experimental (**P7**, **RF01**).
* **`INTERESSADO` → `MODALIDADE`:** cada aula experimental é agendada para uma única modalidade.
* **`PROFESSOR` → `MODALIDADE`:** cada professor atua em uma única modalidade, e uma modalidade tem um ou mais docentes.
* **`TURMA` → `MODALIDADE` e `PROFESSOR`:** cada turma pertence a uma modalidade e tem um professor titular responsável.
* **`MATRICULA` → `ALUNO` e `TURMA`:** a relação 1:N entre aluno e matrícula preserva o histórico, pois o aluno pode ter várias matrículas ao longo do tempo (definido na visita de 13/10). A FK para a turma impõe o limite de capacidade (**RE01**).
* **`TRANCAMENTO` → `MATRICULA`:** uma matrícula pode ter vários trancamentos históricos (**RE04**, **P5**).
* **`AULA` → `TURMA` e `PROFESSOR`:** cada aula pertence a uma turma e guarda o professor que de fato a conduziu, o que permite calcular honorários e rastrear reposições (**Processo 7**).
* **`AULA` → `AULA` (`ID_AULA_ORIGEM`, opcional, auto-relacionamento):** a aula de reposição aponta para a aula original que ela repõe, e a aula regular fica com a coluna nula (**Processo 7**, **P6**). Foi modelada como FK, e não como `ENUM` (regular ou reposição), por três motivos:
  * o `ENUM` diria apenas que a aula é uma reposição, sem dizer de qual aula, e esse vínculo é o que permite rastrear a reposição;
  * o tipo da aula já se deduz da própria FK (`ID_AULA_ORIGEM` nulo é aula regular), então um `ENUM` guardaria a mesma informação duas vezes e poderia ficar em desacordo com ela;
  * a integridade referencial garante que a aula de origem exista.
  * O vínculo é entre aulas, e não entre alunos: a concessão individual de reposição ao aluno é regra de negócio e não gera presença (Processo 7). Por isso a vaga que esse aluno ocupa na aula de reposição (contada no limite de 30, **RE01**) é controlada pela aplicação, e não pelo banco: é uma limitação assumida do modelo.
* **`PRESENCA` → `AULA` e `MATRICULA`:** liga o aluno matriculado a cada sessão de treino, base para a frequência exigida nos exames de faixa (**P4**, **RO05**).
* **`GRADUACAO` → `ALUNO`, `PROFESSOR` e `MODALIDADE`:** cada exame pertence a um aluno, é avaliado por um professor e se refere a uma modalidade (**Processo 8**).
* **`CONTRATO` → `ALUNO` e `PLANO`:** o contrato pertence a um aluno e é baseado em um único plano (no Plano Família, cada familiar tem o seu). Que os alunos do Plano Família são da mesma família é conferido pelo CEO, e não pelo banco (limitação assumida do modelo). Ele fixa a vigência e as condições comerciais pactuadas (**P3**, **RO01**).
* **FKs das 8 tabelas de multivalorados (`ID_ALUNO` ou `ID_PROFESSOR`):** cada valor (e-mail, telefone, problema de saúde, especialização, nível de experiência, qualificação) pertence a um único aluno ou professor e não existe sem ele. A FK faz parte da PK composta, o que impede valor órfão e repetição do mesmo valor para o mesmo dono (**RF01**, **RF02**).
* **`PARTICIPA` → `CONTRATO` e `MODALIDADE`:** permite que um único contrato cubra mais de uma modalidade.
* **`PAGAMENTO` → `CONTRATO`:** cada parcela pertence a um contrato, o que torna possível gerar as cobranças e apurar inadimplência por contrato (**P2**, **RO01**).
* **`DESPESA` → `PROFESSOR` (opcional):** liga os honorários dos professores prestadores de serviço à despesa. É opcional porque aluguel, contas de consumo e suprimentos não têm professor (**P6**, **Processo 11**).
* **`LOG_ACESSO` (sem FK, de propósito):** `NM_TABELA` e `ID_REGISTRO` apontam para qualquer tabela do banco, e uma FK só referencia uma tabela. Além disso, o log precisa sobreviver à eliminação ou à anonimização do registro acessado (prevista na LGPD): com FK, apagar um aluno apagaria ou bloquearia o seu histórico de acessos. `NM_USUARIO` guarda o login como texto porque ainda não há tabela de usuários; se ela for criada, vira `ID_USUARIO` com FK (**RNF02**).

#### 3. Justificativa das Restrições Aplicadas (Mapeamento de Regras de Negócio)

Em `NOT NULL` e `UNIQUE`, o modelo lógico do brModelo já traz as restrições. Os valores permitidos (`ENUM`) e as verificações (`CHECK`) são definidos no script SQL e documentados no dicionário de dados.

| Restrição | Onde | Regra de negócio | Justificativa |
| --- | --- | --- | --- |
| `UNIQUE` em `CPF` | `ALUNO`, `PROFESSOR`, `RESPONSAVEL` | **P1**, **RF01** | Garante identificação civil única para contratos e cobranças e impede cadastros duplicados. |
| `UNIQUE` em `ID_INTERESSADO` | `ALUNO` | **P7**, **RF01** | Relação 1:1: cada interessado origina no máximo um aluno. |
| `UNIQUE` composto em (`NM_INTERESSADO`, `NR_TELEFONE`) | `INTERESSADO` | **RO03**, **P7** | Garante uma única aula experimental gratuita por pessoa, conferida por nome e telefone. |
| `UNIQUE` em `NM_MODALIDADE` e `NM_PLANO` | `MODALIDADE`, `PLANO` | — | Impede catálogo duplicado. |
| `NOT NULL` em nome, CPF, data de nascimento e endereço | `ALUNO`, `PROFESSOR` (e `RESPONSAVEL`, nos campos de contato) | **P1**, **RF01** | Cadastro mínimo exigido para contrato, cobrança e contato. |
| `NOT NULL` em `VL_POR_AULA` e `ID_MODALIDADE` | `PROFESSOR` | — | Sem valor da aula não há honorário a apurar (o do CEO é 0, porque ele não recebe por aula), e todo professor atua em uma modalidade. |
| `NOT NULL` em `IN_ACEITE_USO_IMAGEM` e `DT_AUTORIZACAO_IMAGEM` | `ALUNO` | **RNF02**, **Processo 2 (LGPD)** | O consentimento (sim ou não) e a data da resposta precisam estar sempre registrados. O aceite é opcional para o aluno e revogável, e não condiciona a matrícula. |
| `NOT NULL` nas FKs de dependência | `MATRICULA`, `AULA`, `TURMA`, `GRADUACAO`, `CONTRATO`, `PAGAMENTO`, `TRANCAMENTO`, `INTERESSADO.ID_MODALIDADE` | — | Cada registro depende do pai: não existe matrícula sem aluno e turma, nem pagamento sem contrato. |
| `NOT NULL` em `IN_POSSUI_SISTEMA_FAIXAS` | `MODALIDADE` | **RO06**, **Processo 8** | Isola a regra do Boxe, que não tem graduação por faixas, e habilita o módulo de exames só para modalidades com faixas. |
| `NOT NULL` em `IN_PRESENTE` | `PRESENCA` | **P4**, **RO05** | Cada registro precisa dizer se o aluno esteve presente ou não, para o controle da frequência exigida nos exames. |
| `NOT NULL` em `DT_VENCIMENTO`, `VL_DEVIDO` e `TP_STATUS_PAGAMENTO` | `PAGAMENTO` | **RO02**, **RE07**, **P2** | Toda parcela tem vencimento padronizado (5º dia útil), valor e estado, necessários para o bloqueio por inadimplência. |
| `NOT NULL` em `TP_TRANCAMENTO`, `DS_MOTIVO`, `DT_INICIO` e `DT_RETORNO_PREVISTA` | `TRANCAMENTO` | **P5**, **RE04**, **Processo 5.1** | Regula a suspensão do plano. Sem tipo, motivo, início e previsão de retorno não há como congelar a cobrança nem ajustar o fim do contrato. |
| `NOT NULL` em `TP_AVALIACAO`, `DT_GRADUACAO` e `TP_RESULTADO` | `GRADUACAO` | **Processo 8** | Todo exame ou análise técnica precisa ter tipo, data e resultado (aprovado ou reprovado). |
| `NOT NULL` em `QT_CAPACIDADE_MAXIMA` | `TURMA` | **P5**, **RE01** | Base do bloqueio ao atingir o limite de alunos no tatame. |
| Coluna **sem** `NOT NULL` em `ID_RESPONSAVEL` | `ALUNO` | **Art. 14 da LGPD** | Aluno maior de idade não tem responsável. |
| Coluna sem `NOT NULL` em `ID_INTERESSADO` | `ALUNO` | **P7**, **RF01** | Aluno cadastrado direto, sem aula experimental. |
| Coluna sem `NOT NULL` em `ID_PROFESSOR` | `DESPESA` | **P6**, **Processo 11** | Despesas como aluguel, consumo e suprimentos não têm professor. |
| Colunas sem `NOT NULL` em `DT_CANCELAMENTO` e `VL_MULTA_RESCISORIA` | `CONTRATO` | **RO04** | Ficam nulas enquanto o contrato está vigente. A multa rescisória só existe nos planos mais longos. |
| Colunas sem `NOT NULL` em `DT_PAGAMENTO`, `VL_PAGO` e `TP_FORMA_PAGAMENTO` | `PAGAMENTO` | **P2** | Ficam nulas até a quitação da parcela. |
| Colunas sem `NOT NULL` em `VL_MULTA` e `VL_TAXA_GRADUACAO` | `PAGAMENTO` | **RO04, RO06** | `VL_MULTA` (multa por atraso) só existe nos planos de maior duração, e `VL_TAXA_GRADUACAO` só quando a parcela inclui a taxa do exame de faixa. |
| Coluna sem `NOT NULL` em `DT_RETORNO_EFETIVA` | `TRANCAMENTO` | **RE04**, **P5** | O retorno efetivo só é preenchido depois que ocorre; até lá o trancamento segue em curso. |
| Coluna sem `NOT NULL` em `DS_MOTIVO_REPROVACAO` | `GRADUACAO` | **Processo 8** | Preenchida somente quando o resultado é reprovado. |
| `ENUM` em colunas de situação | `TP_STATUS_ALUNO` (`ALUNO`), `TP_SITUACAO_MATRICULA` (`MATRICULA`), `TP_STATUS_PAGAMENTO` (`PAGAMENTO`), `TP_SITUACAO_DESPESA` (`DESPESA`), `TP_SITUACAO_MODALIDADE` (`MODALIDADE`) | **P2**, **RE04**, **RE06**, **RE07**, **RO02**, **RF01** | Restringe os estados aos valores válidos: `ALUNO` (`Ativo`, `Inativo`, `Trancado`), `MATRICULA` (`Ativa`, `Trancada`, `Encerrada`, `Cancelada`), `PAGAMENTO` (`Pendente`, `Pago`, `Atrasado`), `DESPESA` (`Pendente`, `Pago`, `Atrasado`) e `MODALIDADE` (`Ativa`, `Inativa`). A inadimplência não é um estado do aluno: é derivada dos pagamentos em atraso. |
| `ENUM` em `TP_TRANCAMENTO` | `TRANCAMENTO` | **RE04**, **Processo 5.1** | Dois tipos: lesão e razão médica. A troca de modalidade não é trancamento: a matrícula antiga é encerrada e uma nova é criada. |
| `ENUM` em `TP_AVALIACAO`, `TP_RESULTADO`, `TP_STATUS`, `DS_DIA_SEMANA`, `TP_FORMA_PAGAMENTO` e `TP_OPERACAO` | `GRADUACAO`, `INTERESSADO`, `TURMA`, `PAGAMENTO`, `LOG_ACESSO` | **Processo 8**, **RNF02** | Domínios fechados (exame de faixa ou análise técnica; `Aprovado`/`Reprovado`; `Convertido`/`Encerrado`/`Pendente`; dias da semana; Pix, cartão de crédito ou cartão de débito; operação registrada no log: criação, leitura, atualização ou exclusão). |
| Coluna sem `NOT NULL` em `ID_AULA_ORIGEM` | `AULA` | **Processo 7** | Só é preenchida na aula de reposição, que aponta para a aula original; a aula regular fica com a coluna nula. A reposição em si não gera presença para o aluno que apenas assiste. |
| `CHECK` em `QT_CAPACIDADE_MAXIMA` (entre 1 e 30) | `TURMA` | **P5**, **RE01** | Teto físico do tatame, aplicado pelo próprio banco. |
| `CHECK` em valores numéricos | `VL_MENSALIDADE`, `VL_MENSAL_ACORDADO`, `VL_DEVIDO`, `VL_DESPESA`, `QT_DURACAO_MESES` (> 0); `VL_POR_AULA` (≥ 0); `PC_DESCONTO` (0 a 100); `QT_MINIMA_PESSOAS` em `PLANO` (≥ 1); `QT_MINIMA_REFERENCIA` em `MODALIDADE` (≥ 1) | **RE02** (quórum), demais sem regra própria | Impede valores negativos ou sem sentido nas regras financeiras e comerciais.  |
| Coluna sem NOT NULL em DT_ENTREGA_ATESTADO | ALUNO | RE03, Processo 2 | Fica vazia até o aluno apresentar o atestado. |

#### 4. Justificativa de Decisões Arquiteturais Gerais

1. **Controle diário de frequência (`PRESENCA`):**
   * *Decisão:* a presença é registrada por sessão de `AULA` vinculada à `MATRICULA`, e não direto ao aluno.
   * *Justificativa:* a aula conhece a turma e, portanto, a modalidade. Isso permite o controle da frequência exigida para liberar exames de faixa (**P4**, **RO05**) e o cálculo da remuneração dos professores por aula ministrada.

2. **Contrato entre `ALUNO` e `PLANO`; cobrança em `PAGAMENTO`:**
   * *Decisão:* o contrato guarda as condições pactuadas e gera as parcelas individuais em `PAGAMENTO`.
   * *Justificativa:* reajustes na tabela de planos não alteram contratos nem faturas passadas. O modelo suporta o vencimento padronizado no 5º dia útil (**RO02**), o bloqueio por inadimplência e a suspensão de parcelas em períodos de trancamento (**P5**).

3. **Multimodalidade por tabela associativa (`PARTICIPA`):**
   * *Decisão:* relação N:N entre `CONTRATO` e `MODALIDADE`.
   * *Justificativa:* o aluno mantém um único contrato mesmo praticando mais de uma arte marcial.

4. **Histórico de matrículas e trancamentos:**
   * *Decisão:* `ALUNO` 1:N `MATRICULA` e `MATRICULA` 1:N `TRANCAMENTO`.
   * *Justificativa:* preserva o histórico completo do aluno na academia, incluindo mudanças de turma e afastamentos médicos, sem apagar registros anteriores.

5. **Atributos multivalorados em tabelas próprias:**
   * *Decisão:* telefones, e-mails, problemas de saúde do aluno e dados profissionais do professor ficam em 8 tabelas separadas.
   * *Justificativa:* não limita a quantidade de contatos por pessoa, permite consultar e validar cada valor e mantém o modelo em 1FN.

6. **Separação entre `INTERESSADO` e `ALUNO`:**
   * *Decisão:* o visitante que faz a aula experimental é registrado em `INTERESSADO`, e a conversão é ligada por `ALUNO.ID_INTERESSADO`.
   * *Justificativa:* mantém o contato dos visitantes que não se matriculam e permite medir a taxa de conversão em matrículas definitivas.

7. **`DESPESA` como tabela única das saídas financeiras:**
   * *Decisão:* despesas operacionais e honorários de professores ficam na mesma tabela, com o professor opcional.
   * *Justificativa:* centraliza as contas a pagar da academia e dispensa uma tabela separada de repasses.

8. **Dados derivados não armazenados:**
   * *Decisão:* vagas ocupadas por turma e outros totais são calculados por consulta (`COUNT`, `SUM`), e não gravados.
   * *Justificativa:* evita valores desatualizados em relação às matrículas e aos pagamentos.

9. **Prontidão para integração biométrica (RNF01):**
   * *Decisão:* a situação financeira do aluno pode ser consultada em tempo real pelo `ID_ALUNO`, a partir de `CONTRATO`, `PAGAMENTO` e `ALUNO.TP_STATUS_ALUNO`.
   * *Justificativa:* fornece resposta imediata para liberar ou bloquear a catraca biométrica.

10. **Notação das cardinalidades (Look-Across):**
    * *Decisão:* todas as cardinalidades do DER foram padronizadas na convenção Look-Across, em que o rótulo ao lado de uma entidade indica quantas dela se relacionam com uma da outra.
    * *Justificativa:* é a convenção do brModelo Web e da disciplina. O conversor usa essa leitura para decidir em qual tabela fica cada FK. Misturar convenções num mesmo DER inverte as chaves no modelo lógico.
    
11. **Plano Família com contratos individuais:**
    * *Decisão:* cada aluno do Plano Família tem o seu próprio `CONTRATO`, com o desconto do plano. Não existe contrato compartilhado entre um titular e seus dependentes.
    * *Justificativa:* mantém a regra de um único contrato vigente por aluno e preserva matrícula, presença, graduação e bloqueio por inadimplência individuais. Evita também uma tabela de cobertura ou um auto-relacionamento em `ALUNO`, o que complicaria o modelo sem ganho para as consultas do projeto. A academia não exige comprovação de parentesco, e a conferência de que os alunos são da mesma família é feita pelo CEO, e não pelo banco.
    * *Limitação assumida:* o banco registra uma mensalidade por contrato. Se um responsável decide pagar por todos os familiares, a soma e a cobrança conjunta são tratadas fora do sistema, e as parcelas continuam registradas em cada contrato. Uma evolução futura seria um vínculo opcional entre aluno e titular (`ALUNO.ID_ALUNO_TITULAR`).


---

## 1.6 Proposta de Arquitetura Analítica para BI e IA



O banco operacional (seção 3) registra o dia a dia da academia; esta seção mostra como esses mesmos dados viram informação para decidir. Todos os indicadores abaixo são calculados por uma consulta gerencial do script ([docs/academia_base_forte_leste.sql](docs/academia_base_forte_leste.sql), seção 8), e cada problema P1 a P7 tem ao menos uma consulta que o responde (tabela de rastreabilidade no fim da seção). As consultas G12 a G18 foram criadas nesta etapa para cobrir os problemas e KPIs que ainda não tinham consulta, e a G08 ganhou a coluna de margem.
 
Os valores citados vêm da massa de dados **fictícia** (data de referência 01/11/2026; último mês fechado: outubro/2026), com o script executado do zero no MySQL 8.0. Eles demonstram que cada consulta funciona e devolve resultado; não representam o desempenho real da Base Forte Leste.
 
### 1.6.1 Arquitetura proposta
 
```text
            CEO e professores registram o dia a dia (cadastro, contratos,
            pagamentos, aulas, chamada, graduações)
                                  │
                                  ▼
            ┌────────────────────────────────────────────┐
            │ MySQL 8.0 - ACADEMIA_BFL                   │
            │ 25 tabelas normalizadas (fonte da verdade) │
            └────────────────────────────────────────────┘
                    │                                   │
                    ▼                                   ▼
  ┌─────────────────────────────────┐     ┌─────────────────────────────────┐
  │ Consultas do script             │     │ Camada analítica                │
  │ G01-G18 e A01-A10               │     │ views em esquema estrela        │
  │ (KPIs e conferência de regras)  │     │ (usuário MySQL só de leitura)   │
  └─────────────────────────────────┘     └─────────────────────────────────┘
                                               │                       │
                                               ▼                       ▼
                                 ┌────────────────────┐      ┌────────────────────┐
                                 │ Power BI           │      │ IA (Python)        │
                                 │ painéis por perfil │      │ risco por aluno    │
                                 └────────────────────┘      └────────────────────┘
                                           │
                                           ▼
                       Decisões: cobrança, turmas, retenção e exames
```
 
| Camada | Função | Onde fica | Atualização |
| :-- | :-- | :-- | :-- |
| Fonte (OLTP) | Registra a operação e garante a integridade (PK, FK, CHECK, ENUM). É a única fonte da verdade | MySQL 8.0, banco `ACADEMIA_BFL` | Em tempo real |
| Consultas | Calculam KPIs (G01–G18) e conferem regras (A01–A10) | Script SQL, seções 8 e 9 | A cada execução |
| Camada analítica | Views que reorganizam as tabelas normalizadas em fatos e dimensões, sem alterar o banco. Acesso por um usuário MySQL só de leitura (`GRANT SELECT` nas views, como os perfis da seção 3.5 do script) | Views no próprio MySQL | Diária |
| Consumo | Painéis e alertas; segurança em nível de linha (RLS) para o professor ver só a própria modalidade (RE05, RNF02) | Power BI Desktop, modo importação | Diária |
| IA | Modelos que estimam risco a partir do histórico | Python (pandas, scikit-learn) | Retreino mensal |
 
Para o porte da academia (cerca de 2 mil linhas na massa e de 80 a 100 parcelas por mês), um data warehouse separado não se justifica: views no próprio MySQL bastam. O banco operacional continua normalizado (seção 1.4), que é o melhor formato para gravar sem anomalias; as views apenas juntam as tabelas para leitura.
 
### 1.6.2 Informações estratégicas
 
| Pergunta de gestão | Decisão que apoia | Consultas | O que a massa (fictícia) mostra |
| :-- | :-- | :-- | :-- |
| Quanto deixou de entrar e de quem cobrar hoje? | Cobrança e bloqueio do 6º dia útil (RE07) | G02, G03, G04 | Out/2026: 10,7% das parcelas vencidas em aberto (R$ 1.506,00); 9 alunos na lista de cobrança |
| Quais modalidades sustentam a academia depois do repasse ao professor? | Investir, rever turmas ou o valor por aula | G01 + G07 | Boxe fica com 44% da própria receita depois do repasse; as demais, de 58% a 67%. Muay Thai fica com 100% porque o gestor não recebe por aula |
| Quanto a margem depende do gestor dar aula sem repasse? | Planejar contratação ou substituição do gestor nas aulas | G07, G17 | Custo docente de out/2026: 30,5%. Se as 18 aulas que o gestor deu em outubro fossem pagas como as dos prestadores (R$ 1.440,00), o custo do mês iria para cerca de 40,5% |
| Onde há vaga ociosa ou risco de lotação? | Abrir, juntar ou fechar horários | G05, A06 | 172 matrículas ativas para 630 vagas (27,3%); a turma de Capoeira de sábado está sem alunos; nenhuma turma passa de 30 |
| Quem está deixando de vir antes de cancelar? | Contato preventivo (retenção) | G09, G14 | Out/2026: 5 alunos abaixo de 50% de frequência (7,2% dos avaliados) |
| A aula experimental traz alunos? Em qual modalidade? | Horários e modalidades que recebem as aulas experimentais e a divulgação | G06, G18 | Conversão de 57,1% em setembro e 50,0% em outubro; Boxe converte 75% e Jiu-Jitsu, 20% |
| Os planos de fidelidade seguram o aluno e as multas são cobradas? | Política de desconto por ciclo e de rescisão (RO01, RO04) | G11, G13 | 57% da receita recorrente vem de planos de 3 meses ou mais; de ago a out, 2 cancelamentos antecipados de fidelidade e só 1 com multa lançada |
| Os alunos chegam ao exame preparados? | Critério de liberação para o exame (RO05) e foco das aulas | G15, G16 | 82,1% de aprovação em 12 meses; uma das reprovações teve como motivo "frequência abaixo da exigida" |
 
### 1.6.3 Indicadores e métricas gerenciais (KPIs)
 
**Como foram escolhidos.** O grupo pesquisou os indicadores usados por academias e escolas de artes marciais (fontes no fim da seção) e manteve só os que as tabelas do modelo conseguem calcular e que têm consulta no script. Cancelamento e frequência entram porque a evasão é o maior risco do setor: nas academias brasileiras, a evasão média anual fica entre 40% e 60% [8]. A meta vem de uma referência de mercado quando ela existe [1–7]; quando não existe, vem de uma regra da própria academia ou é proposta do grupo, e isso está indicado em cada linha. Como a frequência exigida para o exame é de cada professor (RO05), as metas pedagógicas são propostas a validar com os professores e com o CEO.
 
| Código | KPI | Fórmula | Período | Meta (origem) | Consulta | Valor na massa |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| KPI01 | Completude do cadastro digital (P1) | cadastros sem pendência ÷ alunos atuais (ativos e trancados) × 100. Pendência: sem telefone, e-mail ou registro de saúde, ou menor sem responsável, ou aluno sem atestado | Mensal (posição na data de referência) | 100% (regra: RE03 e atributos (1,n) do DER) | G12 | 98,8% (1 menor sem atestado) |
| KPI02 | Taxa de inadimplência (P2) | parcelas vencidas e não pagas ÷ parcelas vencidas × 100, por mês de vencimento | Mensal | ≤ 5%; alerta acima de 10% (referência de mercado [6][7]) | G03 (em reais: G02; lista: G04) | Ago 0,0% · set 4,1% · out 10,7% |
| KPI03 | Taxa de cancelamento de contratos (P3) | contratos cancelados no mês ÷ contratos vigentes no 1º dia do mês × 100 | Mensal | ≤ 3%, nível das melhores escolas de artes marciais; alerta acima de 6%, a média do setor [1] | G13 | Ago 2,8% · set 4,3% · out 0,0% |
| KPI04 | Receita recorrente mensal contratada, MRR (P3) |  (`VL_MENSAL_ACORDADO` + `VL_ACRESCIMO_MODALIDADE`) dos contratos vigentes, por plano | Mensal (posição na data de referência) | MRR ≥ saídas do último mês fechado (G08): ponto de equilíbrio (proposta do grupo) | G11 | R$ 15.003,00 em 85 contratos, contra R$ 10.034,06 de saídas em outubro |
| KPI05 | Frequência média e alunos em risco (P4) | presenças ÷ aulas registradas dos alunos com pelo menos 4 aulas no mês; em risco = frequência abaixo de 50% | Mensal | Frequência ≥ 75% e no máximo 5% dos alunos em risco (proposta do grupo) | G14 (lista: G09) | Out: 79,5% · 5 alunos em risco (7,2%) |
| KPI06 | Taxa de aprovação nas avaliações de graduação (P4) | aprovados ÷ avaliados × 100, por modalidade e no total | Janela de 12 meses, revista a cada rodada trimestral de exames | ≥ 80% (proposta do grupo: o aluno só vai ao exame com a frequência e o tempo exigidos, RO05) | G16 (aptidão: G15) | 82,1% (23 de 28); menor taxa: Boxe, 66,7% |
| KPI07 | Ocupação das vagas (P5) | matrículas ativas ÷ (turmas × 30) × 100, por modalidade | Mensal (posição na data de referência) | De 33% a 67%, ou 10 a 20 alunos por turma: acima do maior quórum (RE02), dentro do tamanho de turma de referência do setor [1] e com folga para reposição (RE01) | G05 (alerta por turma: A06) | Jiu-Jitsu 41,7% · Muay Thai 35,8% · Capoeira 31,7% · Boxe 30,0% · Kickboxing 27,8% · No-Gi 13,3% |
| KPI08 | Custo docente sobre a receita (P6) | repasse pago aos professores no mês ÷ receita recebida no mês × 100 | Mensal (regime de caixa) | ≤ 30%; alerta a partir de 40% (referências do setor [2][4][5]) | G17 (apuração: G07) | Ago 32,5% · set 31,8% · out 30,5% |
| KPI09 | Taxa de conversão da aula experimental (P7) | convertidos ÷ aulas experimentais já realizadas no mês × 100 | Mensal (mês da aula) | ≥ 55%; alerta abaixo de 40% (média do setor [1][3]) | G18 (por modalidade: G06) | Set 57,1% · out 50,0% (3 ainda sem decisão) |
| KPI10 | Resultado mensal e margem (P2 e P6) | entradas − saídas pagas no mês; margem = resultado ÷ entradas × 100 | Mensal (regime de caixa) | Margem ≥ 15% [2]. Atenção: a margem ainda remunera o gestor, que não tem retirada lançada em `DESPESA` | G08 | Ago 24,6% · set 28,5% · out 30,3% |
 
**KPIs comuns em academias que ficaram de fora**
 
| KPI | Por que não entrou |
| :-- | :-- |
| NPS (satisfação e recomendação) | O banco não registra pesquisa de satisfação, e a academia não faz esse processo |
| CAC (custo de aquisição de aluno) | A divulgação é feita no Instagram, sem custo (processo excluído na seção 1.1); não há despesa de marketing a dividir |
| LTV (receita do aluno durante o tempo de casa) | Depende do tempo médio de permanência; a massa cobre ago–nov/2026 e tem 6 cancelamentos. Com 12 meses de operação, pode ser calculado a partir de `CONTRATO` e `PAGAMENTO` |
| Ticket médio por aluno | É a MRR da G11 dividida pelos alunos ativos. Pode aparecer no painel, mas não tem consulta própria, por isso não foi listado como KPI |
| Taxa de renovação do ciclo | A renovação não gera registro: o contrato só termina por cancelamento (PN03). Seria preciso guardar o aceite de cada renovação |
| Pico de ocupação por horário | Depende do registro de entrada pela catraca, que está fora do escopo (RNF01) |
 
### 1.6.4 Potencial dos dados para BI
 
**Por que o modelo já serve ao BI**
 
- Todo fato tem data: `DT_VENCIMENTO` e `DT_PAGAMENTO` (parcelas), `DT_AULA` (aulas e aulas experimentais), `DT_MATRICULA`, `DT_CANCELAMENTO` e `DT_GRADUACAO`. Isso dá um eixo de tempo comum a todos os painéis.
- As chaves estrangeiras já são os caminhos de análise: `PAGAMENTO → CONTRATO → PLANO / ALUNO` e `PRESENCA → AULA → TURMA → MODALIDADE / PROFESSOR`.
- Os domínios fechados (`ENUM` e `CHECK`) dão categorias limpas para filtros: situação da parcela, forma de pagamento, categoria de despesa, tipo de avaliação. Não há "Pix" e "pix" misturados.
- Nada é apagado (RE06): matrícula encerrada, contrato cancelado e parcela paga continuam no banco, e por isso as séries históricas são confiáveis.
- Os valores derivados não são gravados (vagas ocupadas, inadimplência): o painel calcula sempre pela mesma regra das consultas.
- As chaves são inteiros estáveis (RNF01): painéis e modelos usam `ID_ALUNO` como pseudônimo, sem expor nome ou CPF.
**Esquema estrela da camada analítica**
 
| Tabela analítica | Tipo | Uma linha é | Medidas e atributos | Vem de |
| :-- | :-- | :-- | :-- | :-- |
| `FATO_PARCELA` | Fato | uma mensalidade | valor devido, pago, multa e taxa de exame; dias após o vencimento; inadimplente (0/1) | `PAGAMENTO`, `CONTRATO` |
| `FATO_PRESENCA` | Fato | um aluno em uma aula | presente (0/1) | `PRESENCA`, `AULA`, `MATRICULA` |
| `FATO_AULA` | Fato | uma aula ministrada | custo (`VL_POR_AULA`), substituição de professor (0/1), reposição (0/1) | `AULA`, `TURMA`, `PROFESSOR` |
| `FATO_CONTRATO` | Fato | um contrato | MRR, multa rescisória, cancelado (0/1), meses de casa | `CONTRATO`, `PARTICIPA` |
| `FATO_GRADUACAO` | Fato | uma avaliação | aprovado (0/1), motivo da reprovação | `GRADUACAO` |
| `FATO_INTERESSE` | Fato | uma aula experimental | convertido (0/1) | `INTERESSADO`, `ALUNO` |
| `FATO_DESPESA` | Fato | uma conta a pagar | valor, valor pago, atrasada (0/1) | `DESPESA` |
| `DIM_CALENDARIO` | Dimensão | um dia | mês, trimestre, dia da semana, dia útil e 5º dia útil, com feriados | Gerada no Power BI (não existe no banco) |
| `DIM_ALUNO` | Dimensão | um aluno | faixa etária, situação, menor de idade, veio da aula experimental, tempo de casa. Sem nome, CPF ou dado de saúde | `ALUNO` |
| `DIM_MODALIDADE`, `DIM_TURMA`, `DIM_PROFESSOR`, `DIM_PLANO` | Dimensão | um registro | quórum e sistema de faixas; dia, horário e capacidade; modalidade e valor por aula; duração, Família e desconto | Tabelas de mesmo nome |
 
Exemplo de view da camada analítica (testada no MySQL 8.0; não faz parte do script de entrega). Diferente do `CHECK`, uma view pode usar `CURDATE()`, então a inadimplência fica sempre atualizada:
 
```sql
CREATE VIEW VW_FATO_PARCELA AS
SELECT pg.ID_PAGAMENTO,
       c.ID_ALUNO,                    -- só o ID: o painel não recebe nome nem CPF (RNF02)
       c.ID_PLANO,
       pg.DT_VENCIMENTO,
       pg.DT_PAGAMENTO,
       pg.VL_DEVIDO,
       COALESCE(pg.VL_PAGO, 0)  AS VL_PAGO,
       COALESCE(pg.VL_MULTA, 0) AS VL_MULTA,
       pg.TP_FORMA_PAGAMENTO,
       pg.TP_STATUS_PAGAMENTO,
       CASE WHEN pg.TP_STATUS_PAGAMENTO <> 'PAGO' AND pg.DT_VENCIMENTO < CURDATE()
            THEN 1 ELSE 0 END                                            AS IN_INADIMPLENTE,
       DATEDIFF(COALESCE(pg.DT_PAGAMENTO, CURDATE()), pg.DT_VENCIMENTO) AS QT_DIAS_APOS_VENCIMENTO
FROM PAGAMENTO pg
INNER JOIN CONTRATO c ON c.ID_CONTRATO = pg.ID_CONTRATO;
 
-- GRANT SELECT ON ACADEMIA_BFL.VW_FATO_PARCELA TO 'bi_leitura'@'%';
```
 
**Painéis propostos**
 
| Painel | Quem vê | O que mostra | Consultas |
| :-- | :-- | :-- | :-- |
| Financeiro | CEO (perfil Administração) | inadimplência do mês e tendência, lista de cobrança do dia, previsto × recebido, resultado e margem, MRR por plano, formas de pagamento, custo docente | G02, G03, G04, G08, G10, G11, G17 |
| Comercial e retenção | CEO | funil da aula experimental por mês e por modalidade, cancelamentos e multas, alunos em risco | G06, G18, G13, G14, G09 |
| Turmas e professores | CEO | ocupação por modalidade e alerta por turma, repasse por professor, receita × repasse por modalidade | G05, A06, G07, G01 |
| Pedagógico | Professor (RLS: só a própria modalidade) | quem atinge a frequência exigida, tempo na faixa, aprovação e motivos de reprovação | G15, G16, G14 |
| Conformidade | CEO | completude do cadastro, auditorias A01–A10 como semáforo (vazio = regra cumprida) e acessos a dados sensíveis registrados em `LOG_ACESSO` | G12, A01–A10 |
 
**Limites do modelo atual para o BI**
 
- `ALUNO.TP_STATUS_ALUNO` guarda só a situação de hoje. A série de alunos ativos por mês precisa vir da vigência dos contratos ou de um retrato mensal gravado pela camada analítica.
- O valor do `PLANO` e a capacidade da `TURMA` são sobrescritos quando mudam. Para comparar períodos, a camada analítica deve guardar as versões (dimensão de mudança lenta do tipo 2).
- O mês a que o repasse se refere está só no texto de `DESPESA.DS_DESCRICAO`; por isso o KPI08 usa regime de caixa e não de competência.
- Na massa, a chamada (`PRESENCA`) começa em outubro/2026. A tendência de frequência só aparece depois de alguns meses de operação.
### 1.6.5 Aplicações analíticas e de IA
 
| Aplicação | Pergunta | Dados de entrada | O que o modelo aprende | Técnica sugerida | Uso na decisão |
| :-- | :-- | :-- | :-- | :-- | :-- |
| Previsão de cancelamento | Quem tende a cancelar nos próximos 60 dias? | frequência das últimas semanas e sua tendência (`PRESENCA`, `AULA`); atrasos (`PAGAMENTO`); plano e tempo de casa (`CONTRATO`, `PLANO`); modalidades (`PARTICIPA`); trocas de turma (`MATRICULA`); reprovação recente (`GRADUACAO`) | `CONTRATO.DT_CANCELAMENTO` preenchida no período | Regressão logística ou árvore de decisão, que explicam o motivo de cada alerta | Lista semanal de contato para o CEO. Até haver histórico, a G09 faz isso por regra |
| Risco de atraso da próxima parcela | Quem deve atrasar a mensalidade deste mês? | histórico de pagamento do contrato (dias de atraso, multas), forma de pagamento e plano (`PAGAMENTO`, `CONTRATO`, `PLANO`) | parcela paga depois do vencimento ou não paga | Regressão logística | Lembrete antes do 5º dia útil só para quem tem risco |
| Prontidão para o exame | Quem tem perfil de aprovação no próximo exame? | frequência desde a última faixa e meses na faixa (G15); resultados e motivos anteriores (`GRADUACAO`) | `TP_RESULTADO` | Árvore de decisão; contagem das palavras-chave de `DS_MOTIVO_REPROVACAO` | Sugestão ao professor, que continua decidindo (RO05) |
| Demanda por turma | Quantos alunos cada horário terá nos próximos meses? | presenças por aula, dia e horário (`PRESENCA`, `AULA`, `TURMA`); matrículas e aulas experimentais por modalidade (`MATRICULA`, `INTERESSADO`) | presenças por aula | Séries temporais simples (média móvel com sazonalidade) | Abrir, juntar ou fechar horário antes de passar de 30 alunos ou de cair abaixo do quórum (RE01, RE02) |
| Modalidade extra | Qual segunda modalidade oferecer a cada aluno? | combinações de modalidades nos contratos (`PARTICIPA`) | modalidades contratadas juntas com frequência | Regras de associação (algoritmo Apriori) | Oferta do acréscimo de modalidade (RO01) |
| Catraca com reconhecimento facial (futuro) | O aluno pode entrar agora? | situação da parcela (G04) e da matrícula | reconhecimento do rosto, feito pelo equipamento do fornecedor | Visão computacional do fornecedor; o banco só responde liberado ou bloqueado | Registraria a presença sozinha. Biometria é dado sensível (LGPD, art. 11) e exige consentimento específico; está fora do escopo atual |
 
**Condições e limites**
 
- **Volume:** 92 alunos, 6 cancelamentos e 4 meses de parcelas não bastam para treinar um modelo confiável. A proposta começa pelas regras que já estão no script (G09, G04) e treina os modelos depois de pelo menos 12 meses de operação, com técnicas simples que o CEO consegue entender.
- **Sinais antecipados:** quem cancela costuma mostrar queda de engajamento de 6 a 8 semanas antes do pedido [9]. Por isso a frequência das últimas semanas é a principal entrada do modelo de cancelamento.
- **LGPD:** painéis e modelos usam `ID_ALUNO`, nunca nome ou CPF. Os dados de saúde (`PROBLEMA_SAUDE_ALUNO` e o motivo do `TRANCAMENTO`) ficam fora dos modelos, porque foram coletados para a segurança no treino, e não para prever comportamento (princípio da finalidade, art. 6º). Os 14 alunos menores pedem cuidado adicional (art. 14). Nenhum risco calculado bloqueia o aluno sozinho: o CEO decide, e o titular pode pedir revisão de decisão automatizada (art. 20).
- **Viés de registro:** o modelo aprende só com o que ficou gravado. A exclusão D01 elimina o interessado que desistiu, como a LGPD prevê para o dado que perdeu a finalidade, mas isso deixa a conversão otimista: na própria massa, setembro passa de 50,0% para 57,1% depois da exclusão. Antes de eliminar, a camada analítica deve guardar o total do mês, sem dado pessoal.
### 1.6.6 Rastreabilidade
 
| Problema ou KPI | Tabelas envolvidas | Consulta no script |
| :-- | :-- | :-- |
| P1 — fichas de papel e risco de perda de dados | `ALUNO`, `TELEFONE_ALUNO`, `EMAIL_ALUNO`, `PROBLEMA_SAUDE_ALUNO` | G12 (auditoria: A05) |
| P2 — inadimplência oculta | `PAGAMENTO`, `CONTRATO`, `ALUNO`, `TELEFONE_ALUNO` | G03, G02, G04, G10 (auditoria: A02, A07) |
| P3 — planos e multas acertados de boca | `CONTRATO`, `PLANO`, `PAGAMENTO` | G13, G11 (auditoria: A08, A10) |
| P4 — graduação sem comprovação de frequência | `PRESENCA`, `AULA`, `MATRICULA`, `TURMA`, `GRADUACAO`, `MODALIDADE`, `PROFESSOR` | G14, G15, G16, G09 (auditoria: A03) |
| P5 — superlotação e vagas sem controle | `TURMA`, `MATRICULA`, `MODALIDADE` | G05 (auditoria: A06) |
| P6 — repasse aos professores calculado de memória | `AULA`, `PROFESSOR`, `DESPESA`, `PAGAMENTO`, `PARTICIPA` | G07, G17, G01 (auditoria: A04) |
| P7 — contatos de aula experimental perdidos | `INTERESSADO`, `MODALIDADE`, `ALUNO` | G18, G06 (auditoria: A09) |
| KPI01 Completude do cadastro digital | `ALUNO`, `TELEFONE_ALUNO`, `EMAIL_ALUNO`, `PROBLEMA_SAUDE_ALUNO` | G12 |
| KPI02 Taxa de inadimplência | `PAGAMENTO` | G03 |
| KPI03 Taxa de cancelamento de contratos | `CONTRATO`, `PLANO`, `PAGAMENTO` | G13 |
| KPI04 MRR por plano | `PLANO`, `CONTRATO` | G11 |
| KPI05 Frequência média e alunos em risco | `PRESENCA`, `AULA`, `MATRICULA` | G14 |
| KPI06 Taxa de aprovação nas avaliações | `GRADUACAO`, `MODALIDADE` | G16 |
| KPI07 Ocupação das vagas | `MODALIDADE`, `TURMA`, `MATRICULA` | G05 |
| KPI08 Custo docente sobre a receita | `PAGAMENTO`, `DESPESA` | G17 |
| KPI09 Taxa de conversão da aula experimental | `INTERESSADO` | G18 |
| KPI10 Resultado mensal e margem | `PAGAMENTO`, `DESPESA` | G08 |
 
**Fontes consultadas para os KPIs e as metas** (referências de mercado, não normas; o uso de IA nesta pesquisa está registrado na seção de Uso de Inteligência Artificial)
 
1. GRIPMODE — *7 KPIs Every Martial Arts School Owner Should Track* (cancelamento mensal abaixo de 3% é excelente e de 4% a 6% é a média; conversão da aula experimental de 40% a 60% em média; turmas de 8 a 20 alunos). https://gripmode-site.pages.dev/blog/7-kpis-every-martial-arts-school-owner-should-track/
2. GRIPMODE — *Financial Reporting for Martial Arts Schools* (folha de instrutores entre 20% e 30% da receita; margem líquida de 15% a 25%). https://gripmode-site.pages.dev/blog/martial-arts-school-financial-reporting-what-to-track/
3. SchedulingKit — *45 Martial Arts Industry Statistics* (conversão média da aula experimental: 55%). https://schedulingkit.com/statistics/martial-arts-statistics
4. Gymdesk — *Martial Arts Instructor Pay Calculator* (folha de instrutores entre 15% e 25% da receita bruta). https://gymdesk.com/tools/martial-arts-instructor-pay-calculator
5. Wodify — *Jiu-Jitsu School Owners Benchmark Report*, noticiado pela 01net (escolas que gastam 40% ou mais da receita com folha têm dificuldade de lucro). https://www.01net.it/wodify-publishes-first-ever-jiu-jitsu-school-owners-benchmark-report/
6. Activesoft — inadimplência escolar (o ideal é até 5%; acima de 10% é preocupante). https://activesoft.com.br/?p=17390
7. Omie — gestão de cobranças (taxa aceitável costuma ficar abaixo de 5%). https://www.omie.com.br/blog/como-fazer-gestao-de-cobrancas-e-reduzir-a-inadimplencia-2/
8. Estado de Minas, com dados da ACAD Brasil — evasão média anual das academias entre 40% e 60%. https://www.em.com.br/networking-e-negocios/2026/07/7469486-retencao-de-alunos-vira-novo-campo-de-batalha-das-academias-no-brasil.html
9. Rework — *Framework de Redução de Churn em Academias* (sinais de desengajamento de 6 a 8 semanas antes do cancelamento). https://resources.rework.com/pt/libraries/gym-fitness-growth/gym-churn-reduction




---

## 2 Modelo Lógico Relacional

**Software utilizado:** o modelo lógico foi criado no **brModelo Web** ([abrir o modelo publicado](https://app.brmodeloweb.com/publicview/6ae6fb2559aaf5bef87df443)), a partir do DER (modelo conceitual) feito na mesma ferramenta, usando o conversor conceitual → lógico e ajustes manuais posteriores.
 
<img alt="Modelo Lógico Relacional - Base Forte Leste (brModelo Web)" src="./img/Modelo Logico V6.png" />

**Legenda:** modelo lógico com 25 tabelas, na notação visual do brModelo para o modelo lógico.
 
#### Como ler o diagrama
 
| Elemento | Como aparece | Exemplo neste modelo |
| --- | --- | --- |
| Tabela | Retângulo com o nome da tabela no topo e uma linha por coluna | `ALUNO`, `TURMA`, `PAGAMENTO` |
| Coluna | Nome da coluna à esquerda, tipo de dado à direita | `NM_COMPLETO` — `VARCHAR` |
| Chave primária | Marca **PK** ao lado do tipo | `ID_ALUNO` — **PK** `INT`, em `ALUNO`; `ID_AULA` + `ID_MATRICULA` — **PK** (chave composta), em `PRESENCA` |
| Chave estrangeira | Marca **FK** ao lado do tipo | `ID_TURMA` — **FK** `INT`, em `MATRICULA` |
| Coluna que é PK e FK | Marcas **PK, FK** | `ID_ALUNO` — **PK, FK** `INT`, em `EMAIL_ALUNO` |
| Ligação entre tabelas | Linha entre a tabela da FK e a tabela referenciada, com a cardinalidade (mín, máx) em cada ponta | `PLANO` — `CONTRATO`: **(1, 1)** e **(0, n)** |
 
O diagrama apresenta: as 25 tabelas, as colunas com seus tipos de dados, as chaves primárias, as chaves estrangeiras e as cardinalidades já convertidas.
 
#### Cardinalidades representadas no diagrama
 
As cardinalidades seguem a convenção *Look-Across* (seção 1.5, item 10). Em cada ligação, o primeiro par fica na ponta da tabela referenciada (lado "1") e o segundo, na ponta da tabela que recebe a FK.
 
| Tabela referenciada | Tabela com a FK | Ponta do lado "1" | Ponta da FK |
| --- | --- | --- | --- |
| `RESPONSAVEL` | `ALUNO` | (1, 1) | (0, n) |
| `INTERESSADO` | `ALUNO` | (1, 1) | (0, 1) |
| `MODALIDADE` | `INTERESSADO`, `PROFESSOR`, `TURMA`, `GRADUACAO` | (1, 1) | (0, n) |
| `PROFESSOR` | `TURMA`, `AULA`, `GRADUACAO`, `DESPESA` | (1, 1) | (0, n) |
| `ALUNO` | `MATRICULA`, `GRADUACAO`, `CONTRATO` | (1, 1) | (0, n) |
| `TURMA` | `MATRICULA`, `AULA` | (1, 1) | (0, n) |
| `MATRICULA` | `TRANCAMENTO` | (1, 1) | (0, n) |
| `PLANO` | `CONTRATO` | (1, 1) | (0, n) |
| `CONTRATO` | `PAGAMENTO` | (1, 1) | (0, n) |
| `AULA`, `MATRICULA` | `PRESENCA` (N:N) | (1, 1) | (0, n) |
| `MODALIDADE`, `CONTRATO` | `PARTICIPA` (N:N) | (1, 1) | (0, n) |
| `ALUNO` | `EMAIL_ALUNO`, `TELEFONE_ALUNO`, `PROBLEMA_SAUDE_ALUNO` | (1, 1) | (0, n) |
| `PROFESSOR` | `EMAIL_PROFESSOR`, `TELEFONE_PROFESSOR`, `REGISTRO_QUALIFICACOES`, `ESPECIALIZACAO`, `NIVEL_DE_EXPERIENCIA` | (1, 1) | (0, n) |
 
Observações sobre o diagrama:
 
* `LOG_ACESSO` aparece isolada, sem ligação com as demais tabelas (justificativa na seção 1.5).
* O auto-relacionamento de reposição (`AULA`–`AULA`) não pode ser desenhado no brModelo Web. Ele aparece apenas como a coluna `ID_AULA_ORIGEM` (FK) na tabela `AULA`.
* O diagrama mostra a cardinalidade gerada pelo conversor do brModelo. A opcionalidade das FKs `ALUNO.ID_RESPONSAVEL`, `ALUNO.ID_INTERESSADO` e `DESPESA.ID_PROFESSOR` não é representada pelo desenho: ela é aplicada pelo `NULL` / `NOT NULL` da coluna no modelo físico (seção 3) e documentada no dicionário de dados (seção 5).
#### Restrições que não aparecem no diagrama
 
O brModelo representa apenas tabelas, colunas, tipos, PK, FK e cardinalidades. As demais restrições de integridade são documentadas no **dicionário de dados (seção 5)** e implementadas no **script SQL (seção 3)**:
 
* obrigatoriedade (`NOT NULL`);
* unicidade (`UNIQUE`);
* valores permitidos (`CHECK` e `ENUM`);
* valores padrão (`DEFAULT`).







---

## 3 Implementação em SQL e Massa de Dados Fictícia

O código completo de criação das tabelas (`CREATE TABLE`), restrições e inserção de dados (`INSERT INTO`) está no ficheiro [docs/academia_base_forte_leste.sql](academia_base_forte_leste.sql).

### 3.1 Dados 100% Fictícios (Conformidade com a LGPD)
Todos os dados pessoais e financeiros inseridos no script são **estritamente fictícios**:
* Nomes sorteados aleatoriamente, CPFs com dígitos verificadores inválidos, telefones e moradas inventados e e-mails com o domínio reservado `@example.com`.
* Os valores de mensalidades, multas, despesas e pagamentos por aula são simulados para preservar o sigilo comercial da organização.

### 3.2 Justificativa da Quantidade de Registos (Proporção Real)
Embora os dados individuais sejam fictícios, a **quantidade de registos** em cada tabela (total de **2.073 linhas**, com data de referência em `01/11/2026`) foi dimensionada para refletir o porte operacional da academia levantado nas entrevistas:

| Tabela | Qtd. Fictícia | Como o porte da academia justifica essa quantidade |
| :--- | :---: | :--- |
| **`MODALIDADE`** | **6** | Representa as 6 artes marciais ensinadas no espaço (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi). |
| **`PROFESSOR`** | **6** | Simula o quadro real de docentes: 1 gestor (que leciona Muay Thai) + 5 professores prestadores de serviço. |
| **`TURMA`** | **21** | Reproduz as 21 turmas semanais de segunda a sábado que funcionam na academia. |
| **`PLANO`** | **8** | Simula os 4 ciclos de planos (Mensal, Trimestral, Semestral e Anual) nas modalidades Individual e Família. |
| **`ALUNO`** | **92** | Quantidade fictícia dimensionada dentro da faixa informada pelo CEO (80 a 100 alunos), sendo 83 ativos, 6 inativos e 3 trancados. |
| **`RESPONSAVEL`** | **11** | Responsáveis fictícios para cobrir os 14 alunos menores de idade (irmãos partilham o mesmo responsável). |
| **`CONTRATO`** | **91** | Um contrato por aluno: 85 vigentes (ativos e trancados) + 6 cancelados = 91. O aluno 92, matriculado sem contrato, é o caso proposital da auditoria A01. No Plano Família, cada familiar tem o seu contrato (ver seção 1.5, item 11). |
| **`PARTICIPA`** | **103** | Vincula cada contrato a pelo menos 1 modalidade (91), mais as modalidades extras contratadas por alguns alunos. |
| **`MATRICULA`** | **190** | Simula cada aluno a treinar em 1 a 3 turmas da sua modalidade (média de 10 alunos por turma, respeitando o limite de 30 vagas). |
| **`TRANCAMENTO`** | **6** | Simula afastamentos por lesão ou razão médica ao longo de 2026 (3 encerrados e 3 em curso). |
| **`PAGAMENTO`** | **325** | Simula de 79 a 83 mensalidades geradas por mês, uma por contrato vigente, durante 4 meses (agosto a novembro de 2026). |
| **`INTERESSADO`** | **24** | Simula a média de 2 a 4 aulas experimentais por semana acumuladas ao longo de 2 meses. |
| **`AULA` e `PRESENCA`** | **74 / 654** | Simula todas as aulas dadas pelas 21 turmas em outubro/2026 e a lista de chamada diária dos alunos matriculados. |
| **`GRADUACAO`** | **28** | Simula o histórico dos exames de faixa trimestrais e análises técnicas de Boxe (aprovados e reprovados). |
| **`DESPESA`** | **50** | Simula as contas fixas mensais, compras semanais de limpeza e o repasse mensal aos 5 professores terceirizados. |
| **`LOG_ACESSO` e Apoio 1FN** | **387** | 20 registos de auditoria de acesso + 367 registos de e-mails, telefones, qualificações e fichas de saúde separados na 1ª Forma Normal. |



---

## 4 Justificativa Técnica
### Premissa do Modelo e Evolução da 1.ª para a 2.ª Entrega

#### * Na concepção inicial do projeto (1.ª Entrega), a modelagem concentrou-se nas entidades nucleares de cadastro, matrícula, presença e pagamento. Contudo, a partir da devolutiva docente e da segunda etapa de levantamento de campo realizada em 13/10/2026 junto ao gestor Adalberto, constatou-se a necessidade de expandir a arquitetura de 9 para **14 entidades**, contando também com a adição de 2 tabelas associativas `PRESENCA` e `PARTICIPA`, 8 tabelas de atributos multivalorados em 1FN e mais 1 da estrutura de auditoria `LOG_ACESSO`. Essa evolução permitiu cobrir integralmente o ciclo de vida operacional da Base Forte Leste: desde a captação em aulas experimentais (`INTERESSADO`) até à escrituração de despesas e folha de repasse dos instrutores (`DESPESA`). 

### Decisões de Modelagem e Normalização

1. **Separação entre `TURMA`, `AULA` e `PRESENCA` (Rastreabilidade Pedagógica e Financeira):**

   > Em vez de vincular a presença diretamente ao aluno ou à turma abstrata, modelou-se a entidade `AULA` para representar cada sessão real e datada de treino ministrada por um professor específico. A tabela associativa `PRESENCA` (`AULA` × `MATRICULA`) registra o comparecimento individual em cada treino. Essa decisão resolve simultaneamente dois problemas críticos: fornece o histórico exato de assiduidade por modalidade para validar a aptidão nos exames de `GRADUACAO` e comprova a quantidade exata de aulas lecionadas por cada professor para o cálculo de honorários em `DESPESA`.

2. **Desacoplamento entre `PLANO`, `CONTRATO` e `PAGAMENTO`:**

   > Na versão preliminar, o pagamento relacionava-se diretamente com o aluno e o plano. A introdução da entidade `CONTRATO` (e da associativa `PARTICIPA` para multimodalidade) garante que o valor acordado no ato da contratação (`VL_MENSAL_ACORDADO`) permaneça congelado durante a vigência, impedindo que reajustes futuros na tabela `PLANO` corrompam o histórico financeiro de parcelas já emitidas em `PAGAMENTO`, além de acomodar a regra do Plano Família e o cálculo de multas rescisórias.

3. **Decomposição de Atributos Compostos e Multivalorados (1.ª Forma Normal):**

   > Para assegurar a atomicidade exigida pela 1FN no modelo lógico, o atributo composto `ENDERECO` foi decomposto em colunas atômicas (`DS_RUA`, `NR_LOGRADOURO`, `NM_BAIRRO`, `NR_CEP`), e os atributos multivalorados de `ALUNO` e `PROFESSOR` (e-mails, telefones, problemas de saúde, especializações, níveis de experiência e qualificações) foram isolados em 8 tabelas de apoio com chave primária composta.

 ---
## 5 Uso de Inteligência Artificial

*(Documentação obrigatória sobre o uso da IA para organizar o trabalho)*.

| Ferramenta e Etapa | Motivação | Prompt(s) Utilizados / Resposta | Fontes Consultadas | Trechos Rejeitados / Corrigidos | Justificativa da Escolha Final | Reflexão Crítica |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **ChatGPT**<br><br>Organização do README. | Estruturar os dados brutos da entrevista de campo no formato do template exigido. | *"Ajuste o template com base no questionário da academia..."* | Questionário de Levantamento de Requisitos (versão do grupo). | Foram removidas sugestões automáticas da IA que envolviam módulos complexos de vendas de produtos (como suplementos), focando apenas no que o CEO pediu (presença e mensalidade). | Mantivemos a estrutura simples para atender estritamente o escopo pedido pelo professor sem complicar a entrega do grupo iniciante. | A IA ajudou a converter as respostas da entrevista em requisitos formais rapidamente, mas a validação humana foi necessária para manter o projeto realista. |
| **Claude**<br><br>Revisão do Dicionário de Dados (Seção 5). | Verificar se a tabela do README seguia as convenções ensinadas (tipagem, prefixos) antes de formatar a entrega final. | **Prompt:** *"Claude, sobre o dicionário do item 5 no README.md. O esqueleto da entrega redireciona para o pdf da construção de dicionário de dados. Linkei tanto o item E quanto o item F. O que está sendo pedido nos pdfs da construção de dados que poderia estar errado no README.md?"*<br><br>**Resposta:** a IA apontou os erros do dicionário, que na época ainda estava dentro do README e não em arquivo separado, comparando-o com o que os PDFs pedem: coluna de tipo, prefixos `NM_`/`DT_`/`ID_`/`TP_`/`IN_` e padronização do CPF entre entidades. | Slides/apostilas da disciplina (02-03e/f) sobre Dicionário de Dados e o README com o dicionário ainda dentro dele. | Nenhuma sugestão foi descartada nessa etapa — todas viraram base para a reformulação seguinte (coluna de tipo, prefixos `NM_`/`DT_`/`ID_`/`TP_`/`IN_`, padronização do CPF entre entidades). | O grupo decidiu montar o dicionário definitivo em HTML já incorporando essas correções. | A IA identificou lacunas técnicas comparando os documentos, mas sem o exemplo oficial (02-03g), a primeira versão não seguia o padrão exato do professor e precisou ser refeita. |
| **Claude**<br><br>Geração do HTML do Dicionário de Dados (Seção 5). | O esqueleto da entrega exige o dicionário em HTML anexado ao repositório (não markdown no README). O grupo só percebeu isso quando o professor comentou a estrutura em HTML. Um colega também comentou sobre o dicionário de outro grupo, e ao olhá-lo o grupo viu que ele seguia o documento-base (02-03g). | **Prompt 1:** *"O professor pareceu não comentar sobre os tipos de dados ou qualquer uma das instruções em si. Mas sim sobre algo de a tabela estar ou não estar estruturada em HTML? Não entendi muito bem o ponto dele em relação a isso."*<br>**Resposta:** a IA explicou que o primeiro documento analisado dizia que o dicionário devia estar em HTML e perguntou se o grupo queria que ela o criasse.<br><br>**Prompt 2:** *"Ok pode montar, deixe-me ver como ficaria."*<br>**Resposta:** uma primeira versão do dicionário em HTML, ainda primitiva, porque não seguia os arquivos que deviam servir de estrutura.<br><br>**Prompt 3:** *"Claude, perdão. Segue mais dois arquivos que eu não tinha visto. O esqueleto diz para usar como exemplo 02-03g_Exemplo_Dicionario_Dados.pdf. Podemos reformular o HTML inteiro para o estilo ficar próximo do pdf?"* A mensagem também trazia o README atualizado e um texto de uma colega do grupo explicando os relacionamentos e as cardinalidades (professor–modalidade, professor–turma, matrícula como tabela ponte entre aluno e turma, presença, pagamento, plano e graduação), e oferecia o DER em SVG e um HTML de outro grupo como exemplo.<br>**Resposta:** um dicionário em HTML no estilo do 02-03g, bem mais próximo do que era pedido, mas ainda com itens faltando. Eles resultaram na nota parcial do Critério 9 na Entrega 1. | Exemplo oficial em PDF (02-03g), README atualizado e texto de uma colega do grupo sobre relacionamentos e cardinalidades. | A primeira versão do HTML (layout livre, com cores) foi descartada.<br><br>**Ajustes de modelo:** PLANO virou entidade própria; PRESENÇA passou a referenciar MATRÍCULA; PROFESSOR passou a ter FK para MODALIDADE. | Mantivemos as correções por resolverem melhor as regras da Seção 4, e o layout fiel ao exemplo pedido (notação formal, tabela por entidade, índices, camada física de tipos e tamanhos). | Ao revisar o material, confirmou-se que a camada física era explicitamente necessária. Ela foi incluída no HTML final para atender integralmente ao que foi solicitado. Mesmo seguindo o 02-03g, o dicionário da Entrega 1 ficou incompleto (faltaram cardinalidades mínimas, SGBD, log de acesso, papéis por operação e LGPD completa), o que só ficou claro na correção. |
| **Claude**<br><br>Texto de introdução e desenvolvimento (1º Texto). | Criar um texto formal com base nas crises operacionais seguindo os passos do escopo do professor. | *"Preciso que você faça um texto de introdução sobre meu trabalho de modelagem de banco de dados seguindo o levantamento de requisitos, use esses parâmetros: Problema, objetivos e delimitação."* | Levantamento de requisitos e "esqueleto_de_entrega" oficial. | O texto gerado identificava erroneamente o "instrutor" como uma entidade. O texto foi reformulado deixando apenas o **Professor** como entidade, conforme nosso levantamento. | O grupo optou por um texto mais formal, seguindo estritamente as regras do levantamento de requisitos. | A IA ajudou com a formalidade do texto, e o próprio erro ao sugerir "instrutor" como entidade ajudou o grupo a identificar e corrigir incoerências no trabalho. |
| **Claude**<br><br>Levantamento de requisitos e Processos do negócio. Eu dividi a resposta em duas partes, essa eu irei explicar o levantamento de requisitos. | A motivação para o uso de ia, foi para garantir que qualquer processo que o professor apontou não esteja faltando, dei instruções para Claude. | O modelo foi instruído a simular uma revisão técnica sobre a modelagem de dados da academia, cruzando o feedback docente com os documentos do projeto (DER e requisitos) para estruturar um instrumento de coleta de dados (roteiro de perguntas) voltado à correção das pendências identificadas.   Resposta: ele criou uma listas de perguntas para eu fazer ao Ceo da academia | Readme, levantamento de requisitos1 e  apontamentos do professor | teve alguns trechos que o ele fez que tratava dados pessoais, como "valor de avaliações", "valor das multas" como se trata de dados pessoais recusei todos eles | Utilizei esse prompt para garantir que a revisão do meu trabalho acadêmico atingisse o mais alto nível de rigor técnico e acadêmico antes da entrega final. Ao instruir o modelo a assumir o papel de um professor especialista, rígido e detalhista, busquei simular uma avaliação crítica e sem concessões, antecipando falhas conceituais e estruturais na modelagem da academia de artes marciais. |Uso de IA para analisar os artefatos da primeira entrega (DER, requisitos e repositório) e o feedback docente, gerando um roteiro estruturado de perguntas para refinamento dos requisitos da academia de artes marciais na segunda entrega.
| **Claude**<br><br> Processos de negócio | Teve inúmeros apontamentos do professor sobre o nosso processos de negócio, tive que reformular porquê, ficou faltando processos, fluxo e a integrações sobre eles. | Atue como um analista no meu trabalho de modelagem de banco de dados, use os dois levantamentos de requisitos e faça os textos seguindo a risca, os apontamentos do professor   Reposta: Ele criou um Pdf com 11 novos processos e criou o fluxo e as integrações dos processos | Levantamento de requisitos1, levantamento de requisitos2 e avaliação do professor Sid | Com base na memória os textos ficaram bons, entretanto as ligações ficaram confusas tive que fazer algumas correções | Optei por utilizar o Claude nessa etapa porque os apontamentos do professor foram contundentes a respeito da fragilidade, da ausência e da falta de integração dos nossos processos de negócio. Em modelagem de banco de dados, falhas no mapeamento do fluxo de processos geram impactos diretos na modelagem lógica e relacional. Portanto, solicitei que o modelo atuasse como um analista de requisitos rigoroso, encarregado de consolidar os dois levantamentos anteriores e sanar integralmente o feedback recebido.  | A utilização do Claude acelerou a documentação e expandiu o escopo com 11 novos processos detalhados, corrigindo as lacunas apontadas pelo professor. No entanto, o modelo falhou na coerência das integrações e gerou dependências confusas entre os fluxos, além de inflar a arquitetura com etapas excessivamente burocráticas. A IA atuou como uma base preliminar eficiente, mas exigiu intervenção humana direta para reorganizar as conexões lógicas e manter a viabilidade real do sistema.
| **Claude**<br><br>Reescrita dos processos de negócio (seção 1.1) | A correção disse que os processos só descreviam o estado atual, sem fluxo nem integração, com cobertura de 55%. | **Prompt:** "Atue como um analista no meu trabalho de modelagem de banco de dados, use os dois levantamentos de requisitos e faça os textos seguindo à risca os apontamentos do professor."<br><br>**Resposta:** processos com AS-IS, TO-BE em passos, dados registrados, regras e integração, além de uma tabela de integração entre eles. | Os dois questionários, avaliação da E1, esqueleto da E2 | As ligações entre os processos ficaram confusas e havia etapas burocráticas demais reorganizei as integrações e simplifiquei os passos. Corrigi regras que não batiam com o que o CEO disse (por exemplo, trancamento sem laudo e troca de modalidade como processo separado). | Mantive a estrutura AS-IS / TO-BE / dados / regras / integração, porque responde ao "sem fluxo nem integração" da correção, e reescrevi o conteúdo com as respostas reais do CEO. | A IA acelerou a organização, mas inventou ligações e detalhes que a academia não tem. Tudo precisou ser conferido com o levantamento antes de entrar no README. |
| Claude<br><br>Seção 1.6 (arquitetura analítica para BI e IA) e consultas G12 a G18 do script | O esqueleto exige que cada KPI tenha fórmula, período, meta e uma consulta no script, e que cada problema (P1 a P7) tenha ao menos uma consulta. O script não tinha consulta gerencial para P1, P3 e P4, e as consultas que já se chamavam "KPI" não tinham meta. | Prompt: "Claude faça a seção 1.6 de arquitetura analitica BI e IA. analise o que o professor pediu e entregue o que ele quer, uso o meu script SQL e minha massa de dados que esta no github, por favor"<br><br>Resposta: a IA executou o script do repositório do zero no MySQL 8.0, pesquisou KPIs usados por academias e escolas de artes marciais e manteve só os que o banco calcula. Propôs 10 KPIs (KPI01 a KPI10) ligados a P1–P7, escreveu as consultas G12 a G18 e a coluna PC_MARGEM da G08, atualizou o cabeçalho "Atende" das consultas G01 a G11 e redigiu a seção 1.6 (arquitetura, informações estratégicas, KPIs, potencial para BI, aplicações de IA e rastreabilidade). | Script e massa de dados do repositório (branch main); referências de mercado citadas no fim da seção 1.6 (GRIPMODE, SchedulingKit, Gymdesk, Wodify, Activesoft, Omie, ACAD Brasil/Estado de Minas e Rework). EU abri toodos os links e conferi as informações | A IA acelerou a pesquisa de KPIs e a escrita das consultas, mas apresentou erros e limites que o grupo teve de corrigir. A primeira versão da seção afirmava que todo KPI tinha consulta no script, o que não era verdade: faltavam consultas gerenciais para P1, P3 e P4, e só a execução do script revelou isso. A IA também sugeriu Python e scikit-learn por conta própria, sem que o professor ou o CEO tivessem pedido, e o grupo decidiu aceitar. As metas vêm de blogs e relatórios comerciais, em sua maioria de academias de outros países, e não de dados da Base Forte Leste. Por isso servem só como referência, e as metas "proposta do grupo" não foram validadas com o CEO. Os valores calculados saem de uma massa fictícia e demonstram apenas que as consultas funcionam, não o desempenho real da academia. A exclusão de interessados (D01) deixa a taxa de conversão otimista. O diagrama gerado em Mermaid não renderizou no GitHub e foi trocado por um desenho em texto. Ao cruzar a seção com o resto do README | Mantivemos a estrutura da seção porque ela segue o que o esqueleto da Entrega 2 pede: informações estratégicas, KPIs com fórmula, período e meta, potencial para BI, aplicações de IA e tabela de rastreabilidade. Adotamos só os KPIs que o nosso banco consegue calcular e que têm consulta no script, e por isso criamos as consultas G12 a G18 para os problemas P1, P3 e P4, que não tinham nenhuma. As consultas novas foram executadas do zero no MySQL 8.0, sem erro. Aceitamos o Python e o Power BI como ferramentas sugeridas porque o grupo já os usa, mas ficam como proposta futura, fora do escopo implementado. As metas marcadas como "proposta do grupo" ficaram assim porque não havia referência de mercado para elas, e ainda precisam ser confirmadas com o CEO. | A IA acelerou a pesquisa de KPIs e a escrita das consultas, mas apresentou erros e limites que o grupo teve de corrigir. A primeira versão da seção afirmava que todo KPI tinha consulta no script, o que não era verdade: faltavam consultas gerenciais para P1, P3 e P4, e só a execução do script revelou isso. A IA também sugeriu Python e scikit-learn por conta própria, sem que o professor ou o CEO tivessem pedido, e o grupo decidiu aceitar. As metas vêm de blogs e relatórios comerciais, em sua maioria de academias de outros países, e não de dados da Base Forte Leste. Por isso servem só como referência, e as metas "proposta do grupo" não foram validadas com o CEO. Os valores calculados saem de uma massa fictícia e demonstram apenas que as consultas funcionam, não o desempenho real da academia. |
| **Claude**<br><br>Dicionário de Dados: conferência com as Regras e os Processos atualizados (v1.3, 14/10/2026). | O docx de Regras de Negócio e o PDF de Processos foram renumerados e atualizados. O grupo precisava saber o que do dicionário continuava válido e o que dependia de decisão. | **Prompt 1:** *"Recebi mais dois arquivos atualizados aqui (Regra de Negócios e Processos de Negócios). Podemos compara-los e ver o que será necessário adicionar ao HTML?"*<br><br>**Prompt 2:** *"Veja este arquivo. É um novo levantamento de requisitos. Há alguma informação valiosa aqui?"*<br><br>**Resposta:** lista de divergências, seguida de um vaivém longo sobre quais informações estavam corretas e quais precisavam mudar. Entre as regras confirmadas: o proprietário faz a recepção, os professores são prestadores pagos por aula, o limite de 30 alunos por turma vem da restrição física do tatame, o plano mensal não tem multa nem juros, a matrícula é 1:N com o aluno e a venda de equipamentos fica fora do escopo. Os códigos de regra foram renumerados.<br><br>**Prompt 3:** *"Vamos voltar apenas ao HTML já que o grupo está fazendo por partes novamente, não temos os arquivos prontos, então não posso te dizer ao certo, mas tudo vai ser concertado. Para essa v1.3, vamos só aplicar o que foi confirmado e que temos 100% de certeza. Tudo que for decisão ou ainda precisa confirmar, deixaremos de fora no momento."*<br><br>**Prompt 4:** *"Alias, vi que você compactou a conversa para continuar o chat, mas pode fazer um texto simples sobre as mudanças que fizemos em cada versão? Pode ser um arquivo de texto tratando da primeira versão até a ultima que nesse caso seria a 1.3"*<br><br>**Resposta final:** o `index.html` v1.3, com as mudanças baseadas nos arquivos enviados, e um arquivo de texto com as mudanças de cada versão, da primeira até a v1.3. O que dependia de decisão foi listado no histórico de versões. | Docx de Regras (renumerado), PDF de Processos, questionário da visita de 13/10 ao proprietário, `Reunião Importante.md` e `Perguntas.md`. | Conselhos anteriores da IA que a entrevista refutou, como a justificativa do contrato baseada em "livre acesso às modalidades". Os itens que dependiam de decisão (por exemplo, Capoeira gratuita e atestado no trancamento) não foram aplicados. | O grupo definiu o critério no Prompt 3: aplicar só o que estava confirmado, com 100% de certeza, na entrevista e nos documentos, e deixar o resto para decisão e para confirmação com o proprietário. | A IA tinha construído justificativas a partir de suposições. Só a entrevista no local as corrigiu, então conselho da IA sem fonte primária não deve virar regra do modelo. |
| **Claude**<br><br>Conferência de README, modelo lógico, MER e DER com o dicionário (v2.0, 25/10/2026). | O grupo recebeu o README novo, o modelo lógico (feito com o Gemini Flash Alto), o MER e o DER atualizados. Era preciso saber se eram coerentes entre si e com o dicionário, já que o Gemini declarava 100% de aderência ao README. | **Prompt 1:** *"Ok, tenho atualizações grandes do projeto. Fiz o documento do modelo lógico junto ao gemini no modo alto flash. Fizemos passo a passo e ele disse que o projeto está batendo 100% com o que temos no README mais recente. Talvez consigamos fazer uma versão mais definitiva do dicionário de dados agora."*<br><br>**Resposta 1:** o arquivo `conferencia_modelo_v2.md`, com os achados e 8 decisões pendentes (item E). Achados: as Seções 3, 4 e 6 do README ainda descreviam 9 entidades; a FK de Professor–Modalidade estava no lado errado; os multivalorados ficaram sem tabela; Trancamento e Responsável estavam como N:N, contra o MER; havia status inventados; Despesa estava obrigatoriamente ligada a professor; as convenções de cardinalidade estavam misturadas; o README pedia atributos que o MER e o DER não têm.<br><br>**Prompt 2:** *"Ok, em relação as decisões que você lista no item E do markdown: 1. Lado oposto (Look-Across), pois o brModelo só consegue passar as FKs certas para as tabelas certas se for usado essa convenção. 2. Não consigo exatamente responder, pois pode se tratar de várias especializações que o professor pode ter, mas óbviamente o mesmo pode dar só aula na modalidade que for atribuída a ele. 3. As numerações do docx são as mais atualizadas, o README ainda tem seções que não foram atualizadas (Erro meu de não citar isso). 4. As opções aqui foram mais ou menos o que o Gemini me propos a colocar no brModelo, então tente seguir os docs e não o md aonde houver discrepância. 5. Vamos deixar esse de lado por enquanto. 6. Deixe como regra, estamos tentando não criar mais nenhuma entidade para não ficar confuso depois. 7. Do modo que se apresenta no DER, acredito que seria vínculo. 8. Atributo pelo mesmo motivo do item 6 na lista."*<br><br>**Resposta 2:** a v2.0 do `index.html`, com mudanças de estrutura, multivalorados e cardinalidades atualizados. Foi aqui que o dicionário passou de 9 para 14 entidades. | README, modelo lógico, MER (docx), DER (imagem) e `index.html`. | O "100% de aderência" do Gemini não se confirmou. Também foi corrigida uma afirmação anterior da própria IA: o trancamento é só por lesão ou razão médica, e a troca de modalidade encerra a matrícula antiga e cria outra (README, Processo 5). Atributos pedidos pelo README e ausentes do MER e do DER ficaram de fora do dicionário. | O grupo decidiu: (1) cardinalidade pelo lado oposto (Look-Across); (2) sem resposta fechada, pois o professor pode ter várias especializações, mas dá aula só na modalidade que lhe for atribuída; (3) numeração de regras do docx, porque o README ainda tem seções desatualizadas; (4) documentos oficiais acima do modelo lógico e do `.md` onde houver discrepância; (5) dependentes do Plano Família para depois; (6) reposição do aluno como regra, sem criar entidade nova; (7) Despesa com vínculo opcional ao professor, sem entidade de apuração separada; (8) Faixa como atributo, sem entidade própria. | Comparar texto com imagem de DER está sujeito a erro. Por isso cada divergência foi listada com a evidência e decidida pelo grupo, em vez de aceitar um "bate" sem prova. |
| **Claude**<br><br>Tipos e restrições do modelo lógico e conferência do MER e do DER novos de outro integrante (seções 1.3 a 1.5). | Definir tipo, obrigatoriedade e restrições de cada coluna dentro do que o brModelo permite e conferir o MER e o DER novos de outro integrante. | **Prompt A:** *"Ok, aqui está o DER e o modelo lógico depois da conversão feita do DER. Os valores ainda não foram mudados, quero que você os liste um a um aqui. Vou listar os tipos do brModelo aqui em baixo como fiz com o Gemini no prompt a seguir:"* e a lista do brModelo: tipos (DATE, DATETIME, TIME, INT, BOOLEAN, FLOAT (pode ser DECIMAL, vai ser modificado no modelo físico), VARCHAR, CHAR, JSON, ENUM, SET), verificações para INT (igual, diferente, maior que, menor que, entre, maior ou igual, menor ou igual), verificações para os outros tipos (é, não é, contém, não contém, começa com, termina com) e restrições (PK, FK, NOT NULL, UNIQUE, AUTO INCREMENT).<br>**Resposta:** uma tabela, coluna por coluna, com tipo, restrições, verificações e valores dos `ENUM`, dentro das opções do brModelo, para o grupo aplicar no lógico. Entre as sugestões, mover a presença da Aula para `Registra_Presenca`.<br><br>**Prompt B:** *"Apliquei muitas das mudanças que você listou e coloquei os valores. Também vou deixar aqui um novo MER e DER feito por outro integrante que deve estar um pouco mais completo."*<br>**Resposta:** começou com *"Não use o DER do colega para converter. Ele não é mais completo que o seu, é uma versão anterior com alguns atributos novos. O seu lógico, por outro lado, está quase todo certo."* e apontou mais alguns pontos. A IA também comentou o SQL exportado pelo brModelo, que é básico. | DER, modelo lógico convertido, MER e DER novos de outro integrante e a lista de tipos, verificações e restrições do brModelo. | O DER do outro integrante não foi usado como base: o Claude aconselhou não converter a partir dele, por ser uma versão anterior com alguns atributos novos, e o grupo seguiu o conselho e voltou ao DER em que as cardinalidades e as FKs tinham sido corrigidas. O SQL exportado pelo brModelo, por ser básico, não foi aproveitado. A presença ficou como atributo do relacionamento Aula–Matrícula no dicionário, o que diverge do DER (presença como atributo de Aula) e foi registrado no histórico como ponto a ajustar no DER. | O grupo seguiu os tipos que o brModelo permite e refinou o resto no modelo físico (por exemplo, `FLOAT` vira `DECIMAL`). Manteve `Responsavel_Pelo_Plano`, porque quem paga pode ser diferente do aluno. | O brModelo limita os tipos, e o SQL que ele exporta é primitivo. A IA acertou ao desaconselhar o DER mais antigo, mas a decisão de qual versão usar foi do grupo. |
| **Claude**<br><br>Redação das seções 1.2 a 1.5 (conversão, chaves, normalização e justificativas) em `DocumentacaoModeloLogico`. | Escrever a documentação que o esqueleto exige. O grupo já tinha boa parte em um arquivo `.md`, mas o modelo mudou muito depois disso, e o integrante queria fechar essa parte antes de focar em outro projeto. A redação foi feita logo depois da v2.1 do dicionário. | **Prompt 1:** *"Preciso também ter a documentação do Modelo Lógico aqui atualizada. Devo mandar a estrutura da divisão para você saber exatamente como deve ser feito ou daqui você consegue seguir normal pelo número de informações que já tem?"* O grupo então entregou o esqueleto da Entrega 2 e pediu a redação.<br><br>**Prompt 2:** *"Prefiro terminar agora para tratar das coisas pequenas amanhã, já que também temos um projeto de front para entregar e focar nele amanhã depois de seguir com essa parte aqui seria ótimo pra mim. A minha parte aqui é justamente o 1.2 da conversão até o 1.5 da Parte 02. Eu já tinha maior parte dele feito no arquivo md aqui, mas óbvio que ocorreu diversas mudanças. Você consegue reescrever as partes dele? Se conseguir seguir as regras que são aplicadas na divisão eu ficaria grato também."*<br><br>**Resposta:** um arquivo `.md` para colocar no README, na divisão exata da Parte 02 (esqueleto da Entrega 2), com 25 tabelas (14 entidades, 2 associativas, 8 multivaloradas e `LOG_ACESSO`) e 31 FKs, conferido contra o SQL, e alguns apontamentos leves do que checar, porque o SQL do brModelo veio estranho. O grupo fez pequenos ajustes ao longo da conversa, porque ainda mudava informações do modelo. | O arquivo `.md` anterior do grupo com as seções 1.2 a 1.5, o esqueleto da Entrega 2 (PDF), o SQL do brModelo, as regras do README e o dicionário. | A primeira versão do texto não batia com o README. Os problemas identificados na parte de Processos de Negócio do README, mantida por outro integrante, estavam levemente errados, e isso passou para o documento: `Aluno.Situacao` com "Inadimplente" e `Despesa.Situacao` com "Cancelado", que o README não prevê; `CPF UNIQUE` citando RE04, que trata do status do aluno; `Valor_Taxa_Exame` no lugar de `Valor_Taxa_Graduacao`; faltavam `Responsavel_Pelo_Plano`, a multa por atraso em Pagamento e `Nivel_Faixa` vazio no Boxe. A IA também tinha dito que Pagamento talvez não precisasse de coluna de multa, o que estava errado: o Processo 4 prevê multa por atraso, sem juros, nos planos trimestral, semestral e anual. | O grupo corrigiu o texto para ficar igual ao README e ao dicionário, mantendo a multa de atraso em Pagamento separada da multa rescisória de Contrato. | A IA repetiu valores e códigos de regra sem conferir o README e, no caso da multa em Pagamento, errou por conta própria. A conferência contra o README foi o que pegou as divergências, e a origem da maioria estava na parte de Processos do README, e não na redação do grupo. |
| **Claude**<br><br>Conferência das seções 1.2 a 1.5 contra o esqueleto e cruzamento com o README. | Verificar se o documento cobria tudo o que o esqueleto pede e se as regras citadas existiam no README. | **Prompt:** *"O texto do arquivo está batendo com o que se pede no esqueleto na seção 1.2 a 1.5?"*<br><br>**Resposta:** a IA respondeu que o conteúdo estava correto e batia com o esqueleto, com as contagens fechando (25 tabelas e 31 FKs). Seguiu-se um vaivém de ajustes, conforme o grupo mudava informações, até o `.md` final para copiar no README. Pontos levantados: contradição na 3FN (a modalidade de `TURMA` e `GRADUACAO` depende do professor), o CEP como dependência transitiva não mencionada, códigos de regra citados no texto, justificativa das FKs dos multivalorados faltando e o prefixo de `DS_DIA_SEMANA`. Divergências com o README: citações de RNF03, RNF04 e RNF06 com significado errado ou inexistente, P1–P9 contra P1–P7, contagem de entidades diferente entre as Seções 6 e 12 e menções a "juros" contra a regra de que não há juros. | Esqueleto (PDF), README (Seções 1.3, 2, 4, 6 e 12), dicionário e histórico de versões. | Foram removidas as citações RNF03, RNF04 e RNF06, e a 3FN e o CEP foram reescritos (RE05). Entraram a justificativa das FKs dos multivalorados, o `UNIQUE` composto de `INTERESSADO` (RO03) e o `CHECK` de `QT_MINIMA_REFERENCIA` (RE02). Erros da própria IA: trocou "reunião de 14/10" por "visita de 13/10" (o histórico mostrava que foi uma reunião interna do grupo), e chamou de nome duplicado duas colunas diferentes, `QT_MINIMA_PESSOAS` (PLANO) e `QT_MINIMA_REFERENCIA` (MODALIDADE). Os dois erros foram desfeitos. | O esqueleto pede que cada restrição cite o código da regra que ela implementa (seção 1.5). Por isso ficaram as citações que o README sustenta e saíram as que não existiam. | A IA corrigiu o texto, mas errou ao "corrigir" uma data sem conferir a fonte. Ficam pendentes no README, na parte mantida por outro integrante: renumerar P1–P9 para P1–P7, acertar a contagem de entidades e trocar as menções a juros. |
| **Claude**<br><br>Conferência do modelo lógico com o `index.html` e atualização da documentação do lógico (v2.1 e v2.2, 27/10 a 02/11/2026). | Garantir que nada do modelo lógico ficasse de fora do dicionário e que os nomes de tabelas e colunas fossem os mesmos nos dois. | **Prompt (v2.1):** *"Cheque para mim as nomenclaturas no modelo lógico e veja se elas batem exatamente com o que tem no HTML (qualquer informação com númericos só vai ser adicionada no modelo físico), se houver alguma informação nova no modelo lógico, adicione-a ao HTML. Também registre a mudança no histórico de versões."* Foram enviados dois documentos: o modelo lógico e o HTML que receberia as informações.<br><br>**Resposta (v2.1):** o `index.html` v2.1. Na Seção 3, uma tabela com os nomes e as chaves primárias compostas das 8 tabelas de apoio dos multivalorados (`EMAIL_ALUNO`, `TELEFONE_ALUNO`, `PROBLEMA_SAUDE_ALUNO`, `EMAIL_PROFESSOR`, `TELEFONE_PROFESSOR`, `ESPECIALIZACAO`, `NIVEL_DE_EXPERIENCIA` e `REGISTRO_QUALIFICACOES`), e o texto deixou de dizer que o mapeamento é só do modelo físico. Em CONTRATO, o atributo opcional `NM_RESPONSAVEL_PLANO`, que existia no lógico, com definição e obrigatoriedade escritas pelo dicionário e a confirmar com o grupo. Em PAGAMENTO, `VL_MULTA_ATRASO` virou `VL_MULTA` e `VL_TAXA_EXAME` virou `VL_TAXA_GRADUACAO`, conforme o MER, o DER e o modelo lógico. A mudança entrou no histórico de versões.<br><br>**Também registrado na conversa ‡** (confirmar de qual prompt ou versão vêm): remoção de `QT_TEMPO_MINIMO_FAIXA` e `DS_OBSERVACAO`; `PROBLEMA_SAUDE_PROFESSOR` fora do lógico; `LOG_ACESSO` sem FK, porque aponta para várias tabelas e precisa sobreviver à eliminação de registros (LGPD); `ID_AULA_ORIGEM` como FK para `AULA`, e não `ENUM`. | Imagem do modelo lógico, MER (`MER_ATUALIZADO2.docx`), DER e `index.html`. | `NM_RESPONSAVEL_PLANO` constava no lógico, mas não no MER. O grupo pediu ao Claude que checasse se ele estava no MER; a IA disse que não, e o grupo o removeu do lógico e do dicionário na v2.2. O `ENUM` de `ID_AULA_ORIGEM` foi trocado por FK. Uma interrupção por limite de uso deixou uma linha da tabela de restrições ainda tratando `ID_AULA_ORIGEM` como `ENUM`, e a IA a corrigiu depois. | Decisões do grupo: os `TP_STATUS_*` ficam como `ENUM` no lógico, com os valores do HTML listados no físico; `NM_RESPONSAVEL` e `VL_ACRESCIMO_MODALIDADE` são os nomes certos; `VL_MULTA_RESCISORIA` é a multa rescisória, apesar de o DER dizer `Valor_Multa`; informações numéricas, como tamanhos de campo, ficam só no modelo físico. | A IA escreveu a definição e a obrigatoriedade de um atributo que o MER não tinha, e só a checagem contra o MER, pedida pelo grupo, resolveu. Alterações interrompidas por limite de uso podem ficar incompletas e precisam ser conferidas no arquivo final. |
| **Claude**<br><br>Dicionário de Dados: comparação de versões, padronização de CPF e NR_CEP em `CHAR`, histórico v2.2 a v2.5 e revisão do Critério 9 (02/11/2026). | Fechar o dicionário: achar inconsistências de tipo entre as entidades, registrar as mudanças no histórico e preparar, no formato da revisão dos Processos de Negócio, a resposta ao Critério 9 da correção. | **Prompts (exatos):**<br>*"Compare para mim as diferenças entre os dois MDs, o maisnovo é o mais atualizado no momento."*<br>*"Ok, você consegue verificar pra mim os campos que tem CHAR em uma entidade mas na outra não tem?"*<br>*"Adicione esses valores no HTML e adicione a alteração no histórico txt aqui."*<br>*"Você consegue uma revisão igual a que já se tem sobre processo de negócios mas com esse dicionário usando a Correção da entrega 1 e o changelog? É possível?"*<br><br>**Resposta:** a comparação correta (`ultimoV1` e `ultimoV2`) teve uma única diferença, a data e a descrição de um encontro. A auditoria mostrou que só ALUNO usava `CHAR` (CPF `char(14)`, NR_CEP `char(9)`), enquanto RESPONSÁVEL e PROFESSOR usavam `VARCHAR` de tamanhos diferentes, e propôs `CHAR(11)` e `CHAR(8)` só com dígitos. A IA aplicou isso no `index.html` e escreveu as entradas v2.2, v2.4 e v2.5 do histórico, além de `revisao_dicionario_dados.md`. | `index.html`, `historico_versoes_dicionario_final.txt`, `README_apontado.md`, `CorreçãoEntrega1.md` e versões de `DocumentacaoModeloLogico`. | O primeiro pedido comparou o par de arquivos errado, e o grupo refez com o par certo. Correções do grupo à IA: `LOG_ACESSO` existe no modelo lógico (não aparece no DER, como as FKs); o preview do dicionário no README não mudou, pois só mostra o cabeçalho; a v2.3 foi conferida com o modelo lógico, e não com o DER. A IA sugeriu rever os mínimos (1,n) de TURMA–AULA e semelhantes, e o grupo confirmou que o DER tem esses valores e os manteve. | O grupo adotou `CHAR(11)` e `CHAR(8)` só com dígitos para poder comparar o mesmo CPF entre tabelas com índice único. Registrou a v2.2, que não estava no histórico, e removeu a pendência de definir o prazo de guarda com o CEO, para não aumentar o projeto. | A IA só viu os arquivos enviados e não abriu as imagens do DER e do lógico. Toda comparação com elas veio do histórico escrito pelo grupo, e foi o grupo que apontou os erros listados ao lado. |
**Gemini**<br><br>Implementação SQL e Resolução de Erros | Resolver o erro de foreign key (`Error Code: 1005 errno: 150`) que impedia a criação da tabela `ALUNO`. | *"esta dando problema ao criar a tabela:" + [Imagem do erro no MySQL]*<br><br>**Resposta:** A IA explicou que o erro ocorria porque a tabela tentava referenciar `RESPONSAVEL` e `INTERESSADO` antes de elas existirem no script. | Conhecimento interno da IA sobre a documentação do MySQL 8.0 e engine InnoDB. | A sugestão da IA de usar `ALTER TABLE` no final do script foi preterida. | O grupo optou por reorganizar a ordem dos `CREATE TABLE` no script (tabelas pai primeiro), mantendo a integridade referencial logo na criação, conforme boas práticas. | A IA foi rápida e precisa na leitura do print de erro, ajudando o grupo a compreender que a ordem de execução do DDL afeta diretamente as amarrações lógicas. |
| **Gemini**<br><br>Revisão do Dicionário de Dados e Defesa Técnica | Obter argumentação técnica baseada em literatura de banco de dados para defender as decisões de modelagem (como o salto de 8 para 14 entidades). | *"tem como avaliar diante ao meu trabalho o que vc fez esta certo e o que? e o porque alterou? para mim ter argumentação"*<br><br>**Resposta:** A IA listou defesas técnicas focadas no desacoplamento do módulo financeiro (Contrato) e na rastreabilidade pedagógica (Entidade Aula). | Livro "Introdução a Sistemas de Bancos de Dados" (C. J. Date) para basear os conceitos de normalização (1FN) e anomalias de atualização. | A linguagem altamente acadêmica sugerida pela IA foi suavizada para se adequar ao perfil do negócio (academia) e facilitar a apresentação oral na banca. | Manter a justificativa focada nos problemas reais (ex: calcular pagamento de professores terceirizados) para comprovar que a normalização resolveu dores do negócio. | A IA funcionou como um mentor, não apenas gerando textos, mas explicando o conceito teórico por trás da decomposição de atributos compostos e tabelas associativas. |
| **Gemini**<br><br>Formatação do Relatório Técnico Final | O texto do trabalho estava de alta qualidade, mas a estrutura e a numeração não seguiam estritamente o template exigido na rubrica da Entrega 2. | *"poderia deixar esse readme.md com a mesma formatação que o professor Cid pede em sua entrega 2, sem alterar nenhum dado..."*<br><br>**Resposta:** A IA reorganizou o texto movendo as seções de Processos e Regras para dentro do item "1.1 Revisão do Modelo Conceitual". | Arquivo "00-d_Esqueleto_Entrega_2.md" e Dicionário Aurélio (para gramática). | A IA sugeriu formatar os requisitos como blocos de código (` ``` `). O grupo rejeitou e instruiu o uso de *blockquotes* (`>`). | A formatação em *blockquote* garante a quebra automática de linha no GitHub, facilitando a leitura e a responsividade em dispositivos móveis. | O uso da IA evitou perda de nota por falha estrutural. Além de arrumar os tópicos, a IA notou ativamente que faltava a "Justificativa de requisitos não incluídos" (exigida na rubrica) e a redigiu. |
| **Gemini**<br><br>Preparação da Apresentação Corporativa (Pitch) | Resumir o extenso trabalho técnico em tópicos impactantes para os slides corporativos (tempo de 8 minutos). | *"preciso elaborar um google apresentações com esse trabalho, poderia me ajudar?"*<br><br>**Resposta:** A IA gerou um slide deck executivo (HTML), extraindo os principais "Antes vs. Depois" e apontando onde inserir os diagramas. | O próprio `README.md` já revisado e consolidado nas etapas anteriores. | A IA sugeriu explicações de SQL nos slides, que foram rejeitadas para não poluir a apresentação (já que a leitura em tela é proibida na regra). | Focar em slides apenas com palavras-chave e diagramas (DER e Lógico), deixando o detalhamento técnico para a argumentação oral. | O poder de sumarização da IA economizou tempo vital na etapa final, garantindo que o grupo não estourasse os 8 minutos regulamentares do pitch. |
