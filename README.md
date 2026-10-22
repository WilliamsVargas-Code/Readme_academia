# Entrega 1 - Modelo Conceitual (DER)

## Metadados

* **Nome do Aluno 1:** Nickolas Henrique Bezerra - **RGM:** 47685778
* **Nome do Aluno 2:** Pedro Henrique Ruola Coiado - **RGM:** 47589124
* **Nome do Aluno 3:** Raphaela Gonçalves Neves - **RGM:** 47656166
* **Nome do Aluno 4:** Williams Vargas Neves Paoli dos Santos - **RGM:** 47336820
* **Professor/Disciplina:** Cid Rodrigues De Andrade - Modelagem de Banco de Dados

---

# Título 
Modelagem de Banco de Dados Relacional para o Sistema de Gestão da Academia Base Forte Leste.

## Introdução
A academia de artes marciais Base Forte Leste enfrenta atualmente uma crise operacional decorrente da ausência de um sistema informatizado de gestão. Todo o controle administrativo é feito por meio de fichas de papel preenchidas manualmente no ato da matrícula e por tratativas informais via WhatsApp, sem qualquer padronização ou centralização das informações. Essa fragilidade estrutural gera três problemas críticos para o negócio: atrasos recorrentes no pagamento das mensalidades, que vencem todo 5º dia útil sem que a inadimplência seja formalmente registrada ou monitorada; total ausência de controle sobre a frequência dos alunos nas aulas, o que impede qualquer análise objetiva de assiduidade e dificuldade em rastrear o tempo real de treino de cada aluno, informação essencial para embasar a concessão de exames de faixa, hoje decidida apenas pela percepção visual do professor. Diante disso, evidencia-se a necessidade de estruturar um banco de dados relacional capaz de organizar e integrar essas informações.

## Desenvolvimento
O objetivo geral deste trabalho é desenvolver o modelo conceitual (DER) de um banco de dados relacional para dar suporte à gestão administrativa e pedagógica da academia Base Forte Leste, centralizando os dados hoje dispersos entre fichas físicas e conversas informais.

Como objetivos específicos, o grupo busca:

Modelar o cadastro de alunos, contemplando dados pessoais, problema de saúde e situação cadastral (ativo, inativo ou trancado);
Modelar o cadastro de professores, vinculando-os às respectivas modalidades de ensino;
Estruturar o controle de turmas, respeitando o limite de 30 alunos por turma e a associação entre modalidade, horários e professor.
Registrar de forma sistemática os pagamentos de mensalidade, identificando plano contratado e data de pagamento, de modo a permitir o acompanhamento da inadimplência
Viabilizar o registro diário de frequência dos alunos, criando a base de dados necessária para subsidiar decisões de graduação;
Registrar o histórico de graduações e exames de faixa realizados por cada aluno.
Este trabalho delimita-se à modelagem conceitual do banco de dados, não contemplando sua implementação física nem o desenvolvimento de uma aplicação de software. O escopo abrange exclusivamente os processos de cadastro de alunos, professores e turmas, controle de mensalidades, registro de frequência e histórico de graduação, por serem os pontos críticos apontados pelo CEO Adalberto na entrevista de campo. Ficam fora do escopo desta entrega questões como a integração futura com sistemas de catraca por reconhecimento facial (prevista apenas como requisito não funcional de compatibilidade futura) e qualquer módulo de venda de produtos ou suplementos, tema descartado ainda na fase de levantamento de requisitos por não fazer parte da demanda original da academia.


# 1. Caracterização da Organização

## 1.1 Nome e natureza da organização

Base Forte Leste - Academia de Artes Marciais (Gerida pelo CEO Adalberto). É uma organização com fins lucrativos voltada para a prestação de serviços esportivos e ensino de lutas.
  
## 1.2 Contexto e porte

Organização de pequeno porte. A academia oferece 6 modalidades (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi). As turmas são divididas por horários e possuem um limite de até 30 alunos por turma.
  
## 1.3 Problemas e necessidades identificados
  
A Academia Base Forte Leste enfrenta atualmente uma crise operacional decorrente da dependência exclusiva de fichas impressas de papel e do controle informal de tratativas via WhatsApp, sem a integração de um sistema   informatizado central. A administração da unidade apoia-se na memória individual dos funcionários e em anotações descentralizadas, gerando descontinuidade de dados, insegurança jurídica, vulnerabilidades financeiras e falhas no planejamento das aulas.

Para solucionar esses gargalos e atender formalmente aos requisitos da disciplina, os problemas de gestão de informação foram catalogados e numerados de P1 a P7, conectando as rotinas operacionais observadas em campo às soluções estruturadas no banco de dados relacional:

**P1 - Vulnerabilidade no armazenamento manual em fichas físicas e risco de perda de dados**

**O que acontece na prática:** O cadastro de novos alunos é realizado exclusivamente à mão em formulários impressos de papel preenchidos no balcão da recepção. Essas folhas reúnem dados cadastrais, telefones de emergência, identificação de pais ou responsáveis no caso de praticantes menores de idade e anotações sobre problemas de saúde preexistentes, ficando arquivadas em pastas físicas abertas sobre a bancada de atendimento.

**Por que é um problema:** Os papéis estão sujeitos à degradação física e a riscos constantes de extravio, rasuras e umidade durante o expediente. Além da perda física das informações, manter pastas de formulários expostas sobre o balcão deixa registros de saúde e dados pessoais vulneráveis à visualização de terceiros, infringindo os requisitos de sigilo da LGPD. Qualquer atualização cadastral ou consulta de contato exige folhear fichas manualmente, tornando o atendimento lento e propenso a inconsistências.

**Como o banco de dados resolve:** Substitui o uso do papel pelo armazenamento digital seguro nas tabelas ALUNO e RESPONSAVEL. Cada praticante recebe um identificador primário exclusivo (Id_Aluno), garantindo a preservação dos dados de saúde, eliminando o risco de perda física de cadastros e permitindo a recuperação instantânea das informações do aluno.

**P2 - Inadimplência oculta e falta de controle sobre pagamentos de mensalidades**

**O que acontece na prática:** As mensalidades de todas as modalidades vencem rigidamente no 5º dia útil de cada mês. Todavia, o controle de quitação baseia-se em trocas informais de mensagens pelo WhatsApp, onde a administração apenas marca em conversas a data em que o comprovante foi encaminhado ou em que o valor foi pago no balcão.

**Por que é um problema:** A gestão não possui visibilidade em tempo real sobre quais alunos estão em atraso, qual é o saldo inadimplente total acumulado e deixa de aplicar as penalidades de juros e multas previstas. Diversos praticantes permanecem com acesso liberado aos treinos mesmo com pendências financeiras prolongadas, devido à carência de rotinas automáticas de auditoria e cobrança.

**Como o banco de dados resolve:** Estrutura a tabela PAGAMENTO, registrando o valor nominal devido, a data efetiva de liquidação, o montante liquidado, acréscimos moratórios (Valor_Multa_Juros) e os estados do título (Pendente, Pago, Atrasado), viabilizando relatórios imediatos de fluxo de caixa e inadimplência.

**P3 - Acordos verbais na contratação de planos e descontrole no cálculo de multas rescisórias**

**O que acontece na prática:** O estabelecimento oferece planos nas modalidades Mensal, Trimestral, Anual e Familiar (com descontos progressivos a partir de dois membros com vínculo de parentesco), além de aplicar cobranças complementares caso o aluno queira ter acesso a mais de uma luta da grade. Todos esses termos são formalizados por acertos verbais no balcão.

**Por que é um problema:** Na ocorrência de cancelamentos antecipados de pacotes com duração trimestral ou anual, a empresa não tem suporte em registros formais de vigência para cobrar as multas rescisórias devidas. Esse vácuo gera contestações por parte dos alunos e provoca perdas de receita previamente planejadas.

**Como o banco de dados resolve:** Interliga as entidades PLANO e CONTRATO, assegurando o registro do período de vigência, do valor mensal fixado no ato da venda, das taxas de acréscimo de multimodalidade e dos parâmetros objetivos de cálculo de multa por rescisão antecipada.

**P4 - Troca de faixas e graduação sem comprovação de frequência mínima nas aulas**

**O que acontece na prática:** Para progredir de graduação nas modalidades estruturadas por faixas (Muay Thai, Jiu-Jitsu, Kickboxing e Capoeira), o praticante deve cumprir um período de prática e uma assiduidade mínima comprovada. No entanto, a academia não mantém nenhum tipo de lista de chamada, caderno de presenças ou catraca eletrônica.

**Por que é um problema:** A permissão para que o aluno se inscreva no exame de graduação apoia-se unicamente na memória dos instrutores, sem embasamento em dados históricos reais. Esse critério subjetivo compromete o rigor pedagógico e o nivelamento técnico esperado pela academia.

**Como o banco de dados resolve:** Integra as tabelas AULA, MATRICULA e GRADUACAO, computando a assiduidade diária por modalidade e viabilizando consultas que atestam com precisão se a meta mínima de presença foi alcançada antes da emissão do certificado de faixa.

**P5 - Superlotação, descontrole de vagas por trancamento e transferências informais de modalidade**

**O que acontece na prática:** Os horários são programados para suportar um teto de segurança de até 30 alunos por turma. Contudo, tanto as solicitações de trancamento de plano por lesão médica quanto os pedidos de troca definitiva de arte marcial (por exemplo, transferência do Boxe para o Muay Thai) ocorrem por mensagens no WhatsApp ou de boca no balcão.

**Por que é um problema:** A ausência de sincronização no sistema impede que a recepção saiba quantas vagas reais estão preenchidas nos horários. Autorizar transferências entre artes marciais sem conferência de dados pode provocar a superlotação do tatame acima de 30 alunos na modalidade de destino, além de manter indevidamente bloqueadas as vagas de quem já se afastou por questões médicas.

**Como o banco de dados resolve:** Integra as tabelas TURMA, MATRICULA e a entidade dependente TRANCAMENTO, mantendo o histórico de transferências, a comprovação formal de afastamento por lesão (Atestado_Por, Motivo) e permitindo o cálculo dinâmico da ocupação das turmas em tempo real.

**P6 - Dificuldade no cálculo do repasse financeiro e controle das aulas lecionadas pelos professores**

**O que acontece na prática:** A organização oferta 6 modalidades esportivas (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi), operando com um quadro de 6 professores. O CEO ministra exclusivamente as aulas de Muay Thai, ao passo que os outros 5 profissionais trabalham sob o regime de prestação de serviços, recebendo a remuneração com base na quantidade de aulas efetivamente dadas no mês.

**Por que é um problema:** Não há registro sistêmico sobre quais aulas foram ministradas, quais professores compareceram e como ocorreram as reposições de horários. Ao final do mês, a apuração dos valores a serem repassados aos docentes depende de negociações verbais e memória, gerando risco de erros contábeis e atritos operacionais.

**Como o banco de dados resolve:** Modela o relacionamento entre as tabelas PROFESSOR e AULA (armazenando o atributo Valor_Por_Aula) em conjunto com a entidade DESPESA, permitindo a geração automática de folhas de repasse com base nas aulas de fato lecionadas por cada docente.

**P7 - Desperdício de contatos e falta de acompanhamento de aulas experimentais**

**O que acontece na prática:** A academia disponibiliza uma aula experimental gratuita para interessados que desejam experimentar uma modalidade antes de efetivar o vínculo. No entanto, nenhum dado de identificação ou contato desse participante é registrado no momento do agendamento.

**Por que é um problema:** O histórico desse primeiro contato fica restrito à lembrança pontual dos professores e gestores. Quando o visitante não formaliza a adesão no mesmo dia da aula, a academia perde os dados de contato, impedindo que a recepção faça ações de retorno e converta potenciais alunos em matrículas ativas.

**Como o banco de dados resolve:** Cria a entidade INTERESSADO, capturando o nome, telefone, data do atendimento e o retorno da visita (Resultado_Interesse), fornecendo métricas sobre o índice de conversão de aulas experimentais em novos contratos.

## 1.4 Justificativa da escolha:

A escolha desta academia fundamenta-se em sua expressiva relevância comunitária na promoção da saúde e no ensino de defesa pessoal. A viabilidade e o aprofundamento dessa seleção decorrem do fato de um dos integrantes da equipe, Nickolas, ser aluno da instituição. Tal condição proporcionou acesso privilegiado à administração, permitindo uma análise precisa dos desafios vivenciados no controle discente, na gestão contratual e no acompanhamento da frequência. A pesquisa de campo, realizada por ele em conjunto com o gestor principal, Adalberto, evidenciou a dependência de formulários impressos para cadastro e a verificação de pagamentos via aplicativos de mensagens. Essa prática sujeita a operação a vulnerabilidades significativas, como a perda de dados essenciais e a ineficácia do controle financeiro. Portanto, o desenvolvimento de um banco de dados mostra-se uma medida imprescindível para assegurar o armazenamento centralizado e seguro das informações, além de prover a infraestrutura necessária para a futura automação do controle de acesso por catraca, conforme almejado pela direção.
  
## 1.5 Evidências da organização

- Endereço completo: Rua Itinguçu, 2345A, Vila Ré, São Paulo – SP
- Responsável: Adalberto (CEO)
- Telefone: (11) 98495-5601 
- E-mail: basefortelesteacademia@gmail.com
- Rede social: Instagram @basefortelesteacademia
- Levantamento de Requisitos feito pelo integrante Nickolas: [Levantamento de Requisitos](levantamento_requisitos.pdf)

  * *Entrevista de Campo:* Realizada presencialmente em 01/09/2026 pelo aluno Nickolas Henrique Bezerra com o CEO Adalberto.


  <a href="./visita.jpeg"><img src="visita.jpeg" alt="Visita á academia" width="250"></a> <a href="./panfleto.jpeg"><img src="panfleto.jpeg" alt="Panfleto comercial da academia" width="320"><a/> <a href="./linkinsta.jpeg"><img src="./linkinsta.jpeg" alt="Link do Instagram da Academia" width="300"></a>


---

## **2. Processos de Negócio**

Mapeamos os processos de funcionamento da academia com base nas entrevistas de 01/09/2026 e 13/10/2026 com o CEO Adalberto.

#### **Captação e Aula Experimental**

O interessado agenda a aula experimental presencialmente ou pelo WhatsApp, combinando dia e horário com a academia. A academia prioriza horários de menor movimento (sextas-feiras e turmas matutinas) para dar atenção individual ao iniciante, mas isso não é regra rígida: ele pode participar de qualquer horário. Na aula, o interessado conhece a modalidade e o professor antes de decidir pela matrícula. Se decidir continuar, o processo segue para Cadastro e Matrícula, caso contrário, o contato é encerrado.

Hoje nenhuma aula experimental é registrada: a informação depende da memória dos professores e da gestão. O sistema deve registrar cada aula experimental como um pré-cadastro, vale lembrar que a aula experimental é totalmente grátis podendo ser realizada apenas uma vez.

#### **Cadastro e Matrícula**

O aluno preenche hoje uma ficha de papel com CPF, nome completo, data de nascimento, endereço, e-mail, telefone (principal e de reserva), problemas de saúde, esportes já praticados e se já é graduado. A data da matrícula é anotada na ficha. Não existe número de matrícula, o aluno é identificado pelo nome ou CPF. As fichas ficam em pastas físicas no balcão, com risco reconhecido de extravio e deterioração.

Alunos menores de idade precisam se um responsável legal.

No sistema, o aluno recebe um identificador único e cada vínculo dele com uma turma gera uma **matrícula**, com data e situação. A situação do aluno é Ativo (mensalidade em dia), Inativo ou Trancado. O aluno pode praticar mais de uma modalidade, conforme a sua disponibilidade e seu plano, e a troca de turma, hoje não registrada, passa a ser registrada armazenando assim seu tempo de treino em cada modalidade.

#### **Contratação de Planos**

A academia oferece os planos Mensal, Trimestral, Semestral e Anual, e cada duração tem uma faixa de desconto progressivo própria. Na matrícula, o aluno escolhe o plano, que define o valor da mensalidade.

Os planos regulares cobrem uma única modalidade. Se o aluno quiser praticar mais de uma arte marcial ou ter livre acesso a todas, aplica-se um acréscimo proporcional sobre o valor contratado, mantida a tabela de desconto do ciclo escolhido.

O Plano Família exige no mínimo duas pessoas com vínculo de parentesco comprovado e existe em cada duração (mensal, trimestral, semestral e anual), cada uma com seu desconto.

O sistema registra o contrato com aluno, plano, data de início, data de fim, valor da mensalidade, percentual de desconto e acréscimo de multimodalidade, quando houver.

Forma de pagamento: Os planos Trimestral, Semestral e Anual definem apenas o ciclo de contratação e a faixa de desconto aplicada, e não alteram a forma de pagamento. Em todos eles, o aluno paga exclusivamente em parcelas mensais, com vencimento no 5º dia útil de cada mês. A academia não oferece a opção de quitação antecipada, isto é, o pagamento integral do plano em uma única parcela. Assim, um aluno com plano anual realiza 12 pagamentos mensais ao longo da vigência, e não um único pagamento no início.


#### **Cobrança e Recebimento de Mensalidades**

A mensalidade vence todo 5º dia útil do mês, independentemente da data de matrícula. Hoje o controle é feito pelo WhatsApp e registra apenas a data em que o aluno pagou, atrasos não são registrados. Por isso a inadimplência é o problema mais frequente da academia.

O sistema gera uma mensalidade por mês de vigência do contrato, cada uma com vencimento no 5º dia útil, independentemente do plano (inclusive Trimestral, Semestral e Anual). Cada registro guarda o contrato, a competência (mês de referência), a data de vencimento, a data de pagamento, o valor, a situação e, nos planos de maior duração, o valor da multa por atraso quando houver.

**Atraso e multas.**
O aluno com mensalidade vencida (após o 5º dia útil) tem a situação de pagamento marcada como atrasada e fica bloqueado de participar das aulas até regularizar o pagamento. Esse bloqueio vale para todos os planos e impede também o registro de presença; quando a catraca com reconhecimento facial for integrada, passa a ser aplicado automaticamente na entrada.

Nos planos Trimestral, Semestral e Anual (inclusive no Plano Família dessas durações), o atraso gera também multa por atraso, além do bloqueio. No plano Mensal (inclusive o Família mensal). O sistema registra, na mensalidade, o valor da multa por atraso, quando houver. 

A academia cobra ainda a multa rescisória, aplicada ao aluno de plano Trimestral, Semestral ou Anual (inclusive no Plano Família dessas durações) que cancela antes do fim do contrato. O valor é calculado de acordo com os meses que ainda faltam para o término do contrato na data do pedido. O plano Mensal, inclusive o Família mensal, não tem multa rescisória e pode ser cancelado a qualquer momento. O sistema registra no contrato a data do cancelamento e o valor da multa.

#### **Montagem de Turmas e Horários**

A turma é definida por uma modalidade, um professor responsável e um dia e horário, e os horários são fixados pela academia de acordo com a modalidade. O aluno entra na turma por meio da matrícula. Cada turma comporta no máximo 30 alunos o sistema deve bloquear novas matrículas ao atingir esse limite.

Cada modalidade tem uma regra criada pelos professores prestadores de serviço para abrir um novo horário: Muay Thai,  a partir de 4 alunos (turma do CEO); Boxe, 6; Jiu-Jitsu, Kickboxing e No-Gi, 8; Capoeira, 10. Na prática, o instrutor pode dar o treino mesmo com menos alunos. Além do professor, a turma costuma ter um instrutor auxiliar, que não é funcionário: é o aluno mais graduado ou com mais tempo de treino.

#### **Controle de Frequência**

Hoje a presença não é registrada de forma alguma. O sistema deve registrar cada aula ministrada (turma, data, horário e professor que a deu) e, para cada aula, a presença de cada aluno matriculado. Esse registro tem duas funções: embasar a elegibilidade do aluno para graduação e comprovar as aulas dadas para o pagamento dos professores.
A frequência fica guardada para que cada professor responsável pela modalidade tenha controle de quantos alunos podem ser graduados e de quais já estão no tempo de serem graduados.

#### **Graduação e Exames de Faixa**

Muay Thai, Jiu-Jitsu, Kickboxing, No-Gi e Capoeira têm exame de faixa. No Boxe não há exame: a evolução é medida por análise técnica do professor e estimativa do tempo de treino. A evolução considera tempo de treino, técnica e resistência, e a frequência influencia a liberação para o exame. Hoje a decisão depende da percepção visual do professor e a data da mudança de faixa fica só no certificado.

O sistema deve registrar, para cada graduação, o aluno, a modalidade, a faixa ou nível, a data e as observações.

#### **Trancamento e Cancelamento**

O **trancamento** é concedido em duas situações:

- **Lesão ou razão médica:** basta justificativa apresentada pelo WhatsApp ou presencialmente, sem necessidade de laudo médico formal. O sistema registra o motivo, durante o trancamento, a cobrança e a contagem do tempo do plano ficam suspensas, e não há nenhuma cobrança, até a situação do aluno ser restabelecida.

- **Troca de modalidade:** o aluno troca de arte marcial sem taxa, encargo ou cobrança adicional. O CEO apenas confirma se há vaga na nova modalidade. Não há suspensão de cobrança.

O **cancelamento** de plano mensal pode ser feito a qualquer momento. Nos planos de maior duração (e também no Plano Família), o cancelamento antecipado gera **multa rescisória**, calculada conforme o mês em que o aluno pede a interrupção (por exemplo, no segundo ou terceiro mês de um trimestral) e comunicada presencialmente ou pelo WhatsApp. Hoje trancamentos e cancelamentos são tratados só pelo WhatsApp, sem registro, multa rescisória é diferente da multa por atraso (ver “Atraso, bloqueio e multas”).

#### **Equipamentos da academia**

A academia possui equipamentos próprios (luvas, capacetes, caneleiras e materiais de treino funcional), que podem ser usados por todos os alunos durante as aulas. Assim, o aluno recém-matriculado pode treinar em qualquer modalidade mesmo sem equipamento próprio. Não há registro de empréstimo nem cobrança.

#### **Compras**

As compras são feitas pelo CEO Adalberto, em quatro grupos:

- **Materiais de treino** (saco de pancada, cordas, pneus e similares): compra sob demanda, conforme o desgaste, sem periodicidade fixa e sem inventário.

- **Materiais de higiene e limpeza** (álcool, descartáveis, sanitizantes, papel higiênico): compra semanal e presencial, sem controle de estoque.

- **Equipamentos de proteção para iniciantes** (luvas, capacetes, caneleiras): comprados pela academia para o empréstimo descrito acima.

- **Água para consumo** (garrafas ou galões para alunos e professores): compra semanal, também feita pelo CEO, sem controle de estoque, é fornecida totalmente de graça para todos que frequentam a academia

#### **Gestão e Pagamento dos Professores**

O CEO Adalberto, além de gestor, é professor de Muay Thai. Os demais professores são prestadores de serviço, não assalariados, Cada uma das seis modalidades, inclusive a Capoeira, tem um professor responsável. e recebem por quantidade de aulas ministradas no período, o que depende do registro confiável das aulas (ver Controle de Frequência). O professor pode levar acessórios pessoais, mas a academia oferece toda a infraestrutura necessária.

Quando o professor titular falta, o aluno tem direito a uma aula de reposição (na mesma modalidade ou em outra modalidade). Hoje isso é combinado verbalmente, sem registro.

#### **Contas a Pagar**

A academia tem despesas fixas: aluguel, contas de consumo (água, luz etc.), manutenção, pagamento dos professores e compras de materiais. Hoje não há controle sistematizado: o CEO guarda de memória os valores e as datas de vencimento. O sistema deve registrar cada despesa com descrição, categoria, valor, data de vencimento, data de pagamento e situação.

### **Processos não incluídos e justificativa**

| **Processo comum em academias** | **Situação** | **Justificativa** |
| --- | --- | --- |
| Venda de produtos e suplementos | Não incluído | Não faz parte da demanda da academia; descartado no levantamento. |
| Folha de pagamento com encargos trabalhistas | Não incluído | Professores são prestadores pagos por aula.|
| Controle de inventário de durabilidade dos equipamentos | Não incluído | A academia compra sob demanda e não tem esse controle; o registro de compras cobre o necessário. |
| Marketing e divulgação | Não incluído | A academia divulga seus treinos no Instagram com vídeos produzidos por uma aluna, familiar do CEO, sem custo e sem fluxo formal de produção ou aprovação. Não há despesa a lançar em Contas a Pagar, nem contrato ou pagamento a registrar. Apesar de muitos sistemas do mercado oferecerem acompanhamento da jornada do contato, da consulta à matrícula, o levantamento não apontou a captação de alunos como problema de gestão. O primeiro contato do interessado já é preservado pelo registro da aula experimental como pré-cadastro. |

---

## 3\. Requisitos do Sistema

### 3.1 Requisitos funcionais

- RF01 - Gestão de Cadastro de Alunos: 

        O sistema deve permitir o cadastro e a manutenção dos dados dos alunos, armazenando o nome, CPF, 
        data de nascimento, problemas de saúde, histórico de treinos anteriores e o status de vínculo (Ativo, Inativo ou Trancado).

- RF02 - Cadastro e Especialização de Professores: 

        O sistema deve permitir o cadastro dos professores da academia, vinculando obrigatoriamente cada docente à sua respetiva modalidade de atuação.

- RF03 - Estruturação de Turmas e Horários: 

        O sistema deve permitir a criação de turmas, definindo a qual modalidade pertencem, 
        os dias e horários das aulas, e associando um professor responsável.

- RF04 - Gestão Financeira e Mensalidades: 

        O sistema deve registar a geração e o pagamento das faturas de mensalidade, identificando qual
        foi o plano contratado pelo aluno (Mensal, trimestral, anual ou família) e a data exata da liquidação.

- RF05 - Controle Diário de Presença:

        O sistema deve registar a frequência (presença) dos alunos de forma diária em cada aula que frequentam.

- RF06 - Registo Histórico de Graduação: 
        
        O sistema deve permitir documentar o avanço dos alunos através do registo do histórico de
        graduações e exames de faixa, guardando as datas de cada conquista.

### 3.2 Requisitos não funcionais:

- RNF01 - Integração Biométrica (Escalabilidade): 
        
        O banco de dados deve ser arquitetado de forma a suportar uma futura integração com hardware de
        catraca de acesso acionado por reconhecimento facial.

- RNF02 - Segurança e Privacidade (LGPD): 
    
        O sistema deve garantir o sigilo de dados sensíveis dos alunos (especificamente o CPF e os registos de problemas de saúde).

- RNF03 - Vencimento Fixo Padronizado:    
       
        Independentemente da data de matrícula, o motor financeiro deve padronizar o vencimento de todas as mensalidades
        para o quinto dia útil de cada mês.

- RNF04 - Limite Operacional de Alunos : 
    
        O sistema deve impedir tecnicamente que uma turma ultrapasse o teto máximo de 30 (trinta) alunos simultâneos.

- RNF05 - Exclusividade de Ensino do Professor : 
    
       Uma barreira sistémica deve garantir que um professor seja associado apenas a turmas da modalidade na qual é especialista.

- RNF06 - Regras Estritas de Trancamento : 
    
        O sistema só deve permitir a alteração do status do aluno para 'Trancado' mediante o preenchimento de uma
        justificativa médica (lesão), bloqueando a cobrança e a contagem de tempo do plano atual.
---

## 4\. Regras de Negócio (Restrições e regras de funcionamento)

### 4.1 Regras Operacionais
(Condições e processos de funcionamento estipulados pela administração da academia)

RO01 - Composição e Tipos de Planos Financeiros

    A academia de artes marciais oferece planos de adesão nas modalidades: Mensal, Trimestral, Anual e Familiar, 
    vinculados às aulas de artes marciais (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi.).

RO02 - Padronização do Vencimento de Mensalidades

    Para todos os alunos matriculados, o vencimento das mensalidades ocorre sempre no 5º dia útil do mês,
    garantindo uniformidade na cobrança e evitando datas variáveis de pagamento.

RO03 - Obrigatoriedade de Frequência para Graduação

    O aluno só poderá realizar exames de graduação (troca de faixa ou nível) se tiver frequência mínima comprovada nas aulas da modalidade, 
    registrada na tabela de presença, assegurando que a evolução técnica esteja alinhada ao tempo de prática.

RO04 - Papel do Instrutor Auxiliar (Sem Entidade Própria)

    Nas turmas de artes marciais, o instrutor auxiliar será sempre um aluno graduado que apoia o professor titular. 


RO05 - Exceção no Sistema de Avaliação (Regra do Boxe)

    Na modalidade de Boxe, não há exames de graduação por faixas. A evolução é medida por tempo de prática e avaliação técnica do professor. 

### 4.2 Restrições Organizacionais
(Limitações físicas, lógicas e políticas que impõem barreiras ao modelo de dados)

RE01 - Capacidade Máxima e Teto Operacional de Turmas

    Cada turma de artes marciais terá limite máximo de 30 alunos ativos, garantindo qualidade no ensino e segurança durante os treinos.
    O sistema deve bloquear novas matrículas quando esse limite for atingido.

RE02 - Condicionalidade Médica para Trancamento

    O aluno só poderá trancar sua matrícula em artes marciais mediante apresentação de atestado médico ou justificativa de lesão. 
    O sistema deve exigir o motivo registrado para validar o status "Trancado".

RE03 - Exclusividade de Especialização Docente

    Professores de artes marciais só poderão ser vinculados a turmas da modalidade em que possuem graduação reconhecida 
    (ex.: faixa preta em Jiu-Jitsu, instrutor certificado em Muay Thai). O sistema deve validar a correspondência entre professor e modalidade.

RE04 - Integridade do Domínio de Status Cadastral

    O vínculo do aluno com a academia de artes marciais deve estar restrito aos estados: Ativo (pagante regular), 
    Inativo (inadimplente ou cancelado) ou Trancado (afastado por lesão). O sistema deve impedir registros fora desses três valores.

RE05 - Bloqueio Automatizado de Catraca por Inadimplência

    O sistema de catraca da academia de artes marciais deve bloquear automaticamente o acesso do aluno inadimplente após o 5º dia útil do mês. 
    O cruzamento entre “ID_Aluno” e Pagamento devem retornar "Bloqueado" e impedir registro de presença.


---

## 5\. Dicionário de Dados Conceitual (Preliminar)

Abaixo está o dicionário de dados completo em uma imagem **clicável**, com todas as entidades e atributos que constam no Diagrama Entidade-Relacionamento (Seção 7):

[![Website Preview Screenshot](img_preview_dicionario.png)](https://williamsvargas-code.github.io/Readme_academia/)

---

## 6\. Modelagem Conceitual

### Entidades reconhecidas e justificativas:

* **ALUNO:** Armazena os dados pessoais, cadastrais e de saúde dos praticantes. 
* **PROFESSOR:** Registra os profissionais e suas respectivas especializações técnicas.
* **MODALIDADE:** Define as opções de luta oferecidas pela academia. 
* **TURMA:** Organiza o cronograma de horários e vincula o professor responsável.
* **MATRÍCULA:** Entidade associativa que gerencia a relação entre aluno e turma, controlando o status cadastral.
* **PLANO:** Agrupa as condições comerciais, preços e durações dos pacotes. 
* **PAGAMENTO:** Controla o histórico financeiro para mitigar a inadimplência. 
* **PRESENÇA:** Registra o comparecimento diário para embasar a evolução técnica e graduação.
* **GRADUAÇÃO:** Armazena o histórico de exames de faixa e o progresso dos alunos.   

### Atributos e Classificações:

* **ALUNO:** Contém o identificador principal Id_Aluno (PK), o CPF como chave alternativa, o Nome_Completo, a Data_Nascimento, um endereço estruturado composto por Rua, Numero, Bairro e CEP, além de Email, Telefone, o atributo multivalorado de Problema_Saude e o Status cadastral.
  
* **PROFESSOR:** É identificado por Id_Professor (PK), contendo também o CPF, Nome_Completo, Data_Nascimento, dados de endereço compostos por Rua, Numero, Bairro e CEP, Email, Telefone, Problema_Saude, além de Especialização, Nivel de Experiencia e Registro_Qualificacoes.
  
* **MODALIDADE:** Possui o Id_Modalidade (PK), o Nome_Modalidade, a Data_Inicio_Aulas e um indicador lógico de Possui_Sistema_Faixas. 

* **TURMA:** Agrupa o Id_Turma (PK), o Dia_Semana, os horários Horario_Inicio e Horario_Fim, e o controle de Vagas_Ocupadas.
  
* **MATRÍCULA:** Estruturada com o Id_Matricula (PK), a Data_Matricula, o campo de Esportes_Praticado, além do Status_Matricula e do Motivo_Trancamento. 
  
* **PLANO:** Contém o Id_Plano (PK), o Nome_Plano, o Preco, a Duracao_Meses e o Porcentual_Desconto.
  
* **PAGAMENTO:** Registrado pelo Id_Pagamento (PK), acompanhado da Data_Vencimento e do Status_Pagamento.
  
* **PRESENÇA:** Composta pelo Id_Presenca (PK), a Data_Aula, o Horario_Aula e o marcador de Presença.
  
* **GRADUAÇÃO:** Reúne o Id_Graduacao (PK), o Nivel_Faixa, a Data_Graduacao e o campo de Observacao.

### Relacionamentos Pertinentes:

* **Domina (Professor e Modalidade - 1:N / N:N):** Um professor possui uma ou mais especializações, e uma modalidade pode ser lecionada por múltiplos professores.

* **Leciona (Professor e Turma - 1:N):** Um professor é responsável por reger uma ou mais turmas, enquanto cada turma possui um único professor principal alocado. 

* **Vincula / Realiza (Aluno, Matrícula e Turma - 1:N e N:1):** Relacionamento associativo que modela a regra de que um aluno pode se matricular em várias turmas e uma turma comporta múltiplos alunos (limitados a 30 por turma).
  
* **Possui (Aluno e Pagamento - 1:N):** Um aluno gera múltiplos registros de pagamento ao longo de sua permanência na academia, mas cada pagamento individual pertence a apenas um aluno.

* **Refere (Pagamento e Plano - N:1):** Vários pagamentos referenciam um mesmo plano contratado, que dita as regras financeiras aplicadas. 

* **Comparece (Aluno e Presença - 1:N): ** Um aluno possui diversos registros de presença diária ao longo de suas aulas. 

* **Obtém (Aluno e Graduação - 1:N):** O aluno acumula ao longo da sua trajetória um histórico de graduações e exames de faixa aprovados.

* **Referência (Modalidade e Graduação - 1:N): ** Vincula a progressão de faixas à modalidade esportiva específica que adota sistema de graduação.

### Restrições e Políticas Organizacionais Aplicadas ao Modelo:

* **Restrição de Capacidade Física:** A entidade Turma interligada à Matrícula valida a restrição organizacional de limite máximo de 30 alunos por turma. 

* **Condicionalidade de Status de Trancamento:** O atributo Motivo_Trancamento na tabela Matrícula torna-se de preenchimento obrigatório sempre que o status for modificado para "Trancado", assegurando a política de que tal alteração só ocorre por motivo de lesão

* **Exclusividade de Especialização:** A integridade do modelo impede que um professor lecione turmas de modalidades para as quais não possua a devida qualificação registrada. 

* **Política de Vencimento Fixo:** A entidade Pagamento padroniza o vencimento para o quinto dia útil de cada mês, operando em conjunto com o bloqueio de frequência caso o Status_Pagamento esteja pendente.
    
---

## 7\. Diagrama Entidade-Relacionamento (DER)
<img width="2082" height="1485" alt="diagrama_er" src="diagrama_er.png" />




---

## 8\. Justificativa Técnica

Como o grupo é iniciante na disciplina, optamos por uma abordagem direta e focada nos problemas críticos relatados pelo CEO Adalberto: mensalidades e frequência. Criamos a entidade **PRESENCA** separada do **ALUNO** porque mapeamos que a frequência é o dado que o professor precisa para avaliar a troca de faixa. Se guardássemos apenas a "última presença" no cadastro do aluno, a academia continuaria sem o histórico necessário para os certificados de graduação. A separação das entidades garante que o banco de dados resolva a desorganização atual sem inflar a complexidade do modelo nesta primeira entrega.

---

## 9. Uso de Inteligência Artificial

*(Documentação obrigatória sobre o uso da IA para organizar o trabalho)*.

| Ferramenta e Etapa | Motivação | Prompt(s) Utilizados / Resposta | Fontes Consultadas | Trechos Rejeitados / Corrigidos | Justificativa da Escolha Final | Reflexão Crítica |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **ChatGPT**<br><br>Organização do README. | Estruturar os dados brutos da entrevista de campo no formato do template exigido. | *"Ajuste o template com base no questionário da academia..."* | Questionário de Levantamento de Requisitos (versão do grupo). | Foram removidas sugestões automáticas da IA que envolviam módulos complexos de vendas de produtos (como suplementos), focando apenas no que o CEO pediu (presença e mensalidade). | Mantivemos a estrutura simples para atender estritamente o escopo pedido pelo professor sem complicar a entrega do grupo iniciante. | A IA ajudou a converter as respostas da entrevista em requisitos formais rapidamente, mas a validação humana foi necessária para manter o projeto realista. |
| **Claude**<br><br>Revisão do Dicionário de Dados (Seção 5). | Verificar se a tabela do README seguia as convenções ensinadas (tipagem, prefixos) antes de formatar a entrega final. | *"O que está sendo pedido nos pdfs da construção de dados que poderia estar errado no README.md?"* | Slides/apostilas da disciplina (02-03e/f) sobre Dicionário de Dados. | Nenhuma sugestão foi descartada nessa etapa — todas viraram base para a reformulação seguinte (coluna de tipo, prefixos `NM_`/`DT_`/`ID_`/`TP_`/`IN_`, padronização do CPF entre entidades). | O grupo decidiu montar o dicionário definitivo em HTML já incorporando essas correções. | A IA identificou lacunas técnicas comparando os documentos, mas sem o exemplo oficial (02-03g), a primeira versão não seguia o padrão exato do professor e precisou ser refeita. |
| **Claude**<br><br>Geração do HTML do Dicionário de Dados (Seção 5). | O esqueleto da entrega exige o dicionário em HTML anexado ao repositório (não markdown no README). | *"Pode montar, deixe-me ver como ficaria"* <br><br>e depois:<br><br>*"Podemos reformular o HTML inteiro para o estilo ficar próximo do pdf [02-03g]?"* | Exemplo oficial em PDF (02-03g) e README atualizado. | A primeira versão do HTML (layout livre, com cores) foi descartada.<br><br>**Ajustes de modelo:** PLANO virou entidade própria; PRESENÇA passou a referenciar MATRÍCULA; PROFESSOR passou a ter FK para MODALIDADE. | Mantivemos as correções por resolverem melhor as regras da Seção 4, e o layout fiel ao exemplo pedido (notação formal, tabela por entidade, índices, camada física de tipos e tamanhos). | Ao revisar o material, confirmou-se que a camada física era explicitamente necessária. Ela foi incluída no HTML final para atender integralmente ao que foi solicitado. |
| **Claude**<br><br>Texto de introdução e desenvolvimento (1º Texto). | Criar um texto formal com base nas crises operacionais seguindo os passos do escopo do professor. | *"Preciso que você faça um texto de introdução sobre meu trabalho de modelagem de banco de dados seguindo o levantamento de requisitos, use esses parâmetros: Problema, objetivos e delimitação."* | Levantamento de requisitos e "esqueleto_de_entrega" oficial. | O texto gerado identificava erroneamente o "instrutor" como uma entidade. O texto foi reformulado deixando apenas o **Professor** como entidade, conforme nosso levantamento. | O grupo optou por um texto mais formal, seguindo estritamente as regras do levantamento de requisitos. | A IA ajudou com a formalidade do texto, e o próprio erro ao sugerir "instrutor" como entidade ajudou o grupo a identificar e corrigir incoerências no trabalho. |
| **Claude**<br><br>Levantamento de requisitos e Processos do negócio. Eu dividi a resposta em duas partes, essa eu irei explicar o levantamento de requisitos. | A motivação para o suo de ia, foi para garantir que qualquer processo que o professor apontou não esteja faltando, dei instruções para Claude. | Prompt: você é um professor, especialista da matéria modelagem de banco de dados do segundo semestre e irá instruir e ensinar, Sobre uma modelagem real de uma academia de artes marciais. rígido e detalhista Preciso que me ajude com um trabalho de faculdade. Para você entender melhor tenho duas entregas (Entrega1 e Entrega2) o professor recebeu e analisou nossa entrega1 e teve alguns apontamentos, preciso que você me ajude com perguntas para um novo levantamento de requisitos. Eu anexei os apontamentos do professor anexei o primeiro levantamento de requisito, coloquei o nosso DER e linkei o nosso repositório do github / Resposta: "ele criou um pdf 
