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

### Natureza Jurídica e Atuação

Empresa privada com fins lucrativos, atuante na prestação de serviços esportivos, condicionamento físico e ensino de artes marciais.

### Quadro de Pessoal e Recursos Humanos

* **Administração e Atendimento:** 1 recepcionista fixa responsável pelo atendimento presencial, cadastro em balcão e conferência de comprovantes.

* **Corpo Docente e Gestão:** 1 gestor geral (CEO) que também ministra as turmas de Muay Thai, somado a 5 professores contratados como prestadores de serviços terceirizados para as demais modalidades (Boxe, Jiu-Jitsu, Kickboxing, No-Gi e Capoeira).

* **Corpo de Apoio:** Instrutores auxiliares rotativos (alunos avançados/graduados que prestam suporte técnico sem vínculo empregatício formal).

### Estrutura de Modalidades e Grade de Horários

* **Modalidades Ofertadas:** 6 artes marciais ativas (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi).   

* **Grade Semanal:** 18 turmas regulares distribuídas de segunda a sábado nos períodos matutino, vespertino e noturno.   

* **Capacidade Física:** Limite estrito de segurança de até 30 alunos por turma simultaneamente no tatame.   

* **Quantidade Mínima por Modalidade:** Parâmetro para abertura formal de horários: Muay Thai (4 alunos), Boxe (6 alunos), Jiu-Jitsu/Kickboxing/No-Gi (8 alunos) e Capoeira (10 alunos).

### Volumetria Operacional Estimada (Base para a Massa de Dados):

* **Alunos Ativos:** Faixa estimada entre 80 e 100 praticantes matriculados, considerando a distribuição dos alunos nas turmas regulares acima do quantidade mínima operacional de cada modalidade.

* **Contratos:** Estimativa de 70 a 85 contratos ativos. O número de contratos é inferior ao total de alunos matriculados devido à adesão ao Plano Família, modalidade na qual um único contrato e responsável financeiro englobam dois ou mais dependentes/parentes com desconto progressivo.

* **Movimentação Financeira Mensal:** Emissão recorrente de 70 a 85 faturas de mensalidade por mês (uma para cada contrato vigente, com vencimento no 5º dia útil), gerando no banco um histórico de liquidações pontuais, pagamentos com acréscimo de juros e registros de inadimplência para testes das consultas gerenciais.  

* **Aulas Experimentais:** Média observada de 2 a 4 atendimentos semanais de novos interessados para testes gratuitos (cerca de 8 a 16 por mês), que hoje dependem unicamente da memória dos instrutores.   

* **Rotina de Compras e Despesas:** Reposição presencial semanal de insumos de higiene/limpeza realizada pelo gestor, além do lançamento mensal das despesas fixas da academia (locação, água, luz e pagamento de docentes). 

## 1.3 Problemas e necessidades identificados
  
A Academia Base Forte Leste enfrenta atualmente uma crise operacional decorrente da dependência exclusiva de fichas impressas de papel e do controle informal de tratativas via WhatsApp, sem a integração de um sistema   informatizado central. A administração da unidade apoia-se na memória individual dos funcionários e em anotações descentralizadas, gerando descontinuidade de dados, insegurança jurídica, vulnerabilidades financeiras e falhas no planejamento das aulas.

Para solucionar esses gargalos e atender formalmente aos requisitos da disciplina, os problemas de gestão de informação foram catalogados e numerados de P1 a P7, conectando as rotinas operacionais observadas em campo às soluções estruturadas no banco de dados relacional:

### P1 - Vulnerabilidade no armazenamento manual em fichas físicas e risco de perda de dados

**O que acontece na prática:** O cadastro de novos alunos é realizado exclusivamente à mão em formulários impressos de papel preenchidos no balcão da recepção. Essas folhas reúnem dados cadastrais, telefones de emergência, identificação de pais ou responsáveis no caso de praticantes menores de idade e anotações sobre problemas de saúde preexistentes, ficando arquivadas em pastas físicas abertas sobre a bancada de atendimento.

**Por que é um problema:** Os papéis estão sujeitos à degradação física e a riscos constantes de extravio, rasuras e umidade durante o expediente. Além da perda física das informações, manter pastas de formulários expostas sobre o balcão deixa registros de saúde e dados pessoais vulneráveis à visualização de terceiros, infringindo os requisitos de sigilo da LGPD. Qualquer atualização cadastral ou consulta de contato exige folhear fichas manualmente, tornando o atendimento lento e propenso a inconsistências.

**Como o banco de dados resolve:** Substitui o uso do papel pelo armazenamento digital seguro nas tabelas ALUNO e RESPONSAVEL. Cada praticante recebe um identificador primário exclusivo (Id_Aluno), garantindo a preservação dos dados de saúde, eliminando o risco de perda física de cadastros e permitindo a recuperação instantânea das informações do aluno.

### P2 - Inadimplência oculta e falta de controle sobre pagamentos de mensalidades

**O que acontece na prática:** As mensalidades de todas as modalidades vencem rigidamente no 5º dia útil de cada mês. Todavia, o controle de quitação baseia-se em trocas informais de mensagens pelo WhatsApp, onde a administração apenas marca em conversas a data em que o comprovante foi encaminhado ou em que o valor foi pago no balcão.

**Por que é um problema:** A gestão não possui visibilidade em tempo real sobre quais alunos estão em atraso, qual é o saldo inadimplente total acumulado e deixa de aplicar as penalidades de juros e multas previstas. Diversos praticantes permanecem com acesso liberado aos treinos mesmo com pendências financeiras prolongadas, devido à carência de rotinas automáticas de auditoria e cobrança.

**Como o banco de dados resolve:** Estrutura a tabela PAGAMENTO, registrando o valor nominal devido, a data efetiva de liquidação, o montante liquidado, acréscimos moratórios (Valor_Multa_Juros) e os estados do título (Pendente, Pago, Atrasado), viabilizando relatórios imediatos de fluxo de caixa e inadimplência.

### P3 - Acordos verbais na contratação de planos e descontrole no cálculo de multas rescisórias

**O que acontece na prática:** O estabelecimento oferece planos nas modalidades Mensal, Trimestral, Anual e Familiar (com descontos progressivos a partir de dois membros com vínculo de parentesco), além de aplicar cobranças complementares caso o aluno queira ter acesso a mais de uma luta da grade. Todos esses termos são formalizados por acertos verbais no balcão.

**Por que é um problema:** Na ocorrência de cancelamentos antecipados de pacotes com duração trimestral ou anual, a empresa não tem suporte em registros formais de vigência para cobrar as multas rescisórias devidas. Esse vácuo gera contestações por parte dos alunos e provoca perdas de receita previamente planejadas.

**Como o banco de dados resolve:** Interliga as entidades PLANO e CONTRATO, assegurando o registro do período de vigência, do valor mensal fixado no ato da venda, das taxas de acréscimo de multimodalidade e dos parâmetros objetivos de cálculo de multa por rescisão antecipada.

### P4 - Troca de faixas e graduação sem comprovação de frequência mínima nas aulas

**O que acontece na prática:** Para progredir de graduação nas modalidades estruturadas por faixas (Muay Thai, Jiu-Jitsu, Kickboxing e Capoeira), o praticante deve cumprir um período de prática e uma assiduidade mínima comprovada. No entanto, a academia não mantém nenhum tipo de lista de chamada, caderno de presenças ou catraca eletrônica.

**Por que é um problema:** A permissão para que o aluno se inscreva no exame de graduação apoia-se unicamente na memória dos instrutores, sem embasamento em dados históricos reais. Esse critério subjetivo compromete o rigor pedagógico e o nivelamento técnico esperado pela academia.

**Como o banco de dados resolve:** Integra as tabelas AULA, MATRICULA e GRADUACAO, computando a assiduidade diária por modalidade e viabilizando consultas que atestam com precisão se a meta mínima de presença foi alcançada antes da emissão do certificado de faixa.

### P5 - Superlotação, descontrole de vagas por trancamento e transferências informais de modalidade

**O que acontece na prática:** Os horários são programados para suportar um teto de segurança de até 30 alunos por turma. Contudo, tanto as solicitações de trancamento de plano por lesão médica quanto os pedidos de troca definitiva de arte marcial (por exemplo, transferência do Boxe para o Muay Thai) ocorrem por mensagens no WhatsApp ou de boca no balcão.

**Por que é um problema:** A ausência de sincronização no sistema impede que a recepção saiba quantas vagas reais estão preenchidas nos horários. Autorizar transferências entre artes marciais sem conferência de dados pode provocar a superlotação do tatame acima de 30 alunos na modalidade de destino, além de manter indevidamente bloqueadas as vagas de quem já se afastou por questões médicas.

**Como o banco de dados resolve:** Integra as tabelas TURMA, MATRICULA e a entidade dependente TRANCAMENTO, mantendo o histórico de transferências, a comprovação formal de afastamento por lesão (Atestado_Por, Motivo) e permitindo o cálculo dinâmico da ocupação das turmas em tempo real.

### P6 - Dificuldade no cálculo do repasse financeiro e controle das aulas lecionadas pelos professores

**O que acontece na prática:** A organização oferta 6 modalidades esportivas (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira e No-Gi), operando com um quadro de 6 professores. O CEO ministra exclusivamente as aulas de Muay Thai, ao passo que os outros 5 profissionais trabalham sob o regime de prestação de serviços, recebendo a remuneração com base na quantidade de aulas efetivamente dadas no mês.

**Por que é um problema:** Não há registro sistêmico sobre quais aulas foram ministradas, quais professores compareceram e como ocorreram as reposições de horários. Ao final do mês, a apuração dos valores a serem repassados aos docentes depende de negociações verbais e memória, gerando risco de erros contábeis e atritos operacionais.

**Como o banco de dados resolve:** Modela o relacionamento entre as tabelas PROFESSOR e AULA (armazenando o atributo Valor_Por_Aula) em conjunto com a entidade DESPESA, permitindo a geração automática de folhas de repasse com base nas aulas de fato lecionadas por cada docente.

### P7 - Desperdício de contatos e falta de acompanhamento de aulas experimentais

**O que acontece na prática:** A academia disponibiliza uma aula experimental gratuita para interessados que desejam experimentar uma modalidade antes de efetivar o vínculo. No entanto, nenhum dado de identificação ou contato desse participante é registrado no momento do agendamento.

**Por que é um problema:** O histórico desse primeiro contato fica restrito à lembrança pontual dos professores e gestores. Quando o visitante não formaliza a adesão no mesmo dia da aula, a academia perde os dados de contato, impedindo que a recepção faça ações de retorno e converta potenciais alunos em matrículas ativas.

**Como o banco de dados resolve:** Cria a entidade INTERESSADO, capturando o nome, telefone, data do atendimento e o retorno da visita (Resultado_Interesse), fornecendo métricas sobre o índice de conversão de aulas experimentais em novos contratos.

### Conclusão 

A implantação de um banco de dados relacional é indispensável para substituir as fichas de papel e centralizar o controle hoje dividido com planilhas e mensagens informais. O sistema unifica os dados cadastrais, financeiros e pedagógicos em uma base sólida e auditável. Paralelamente, o anseio da academia pela instalação futura de uma catraca com reconhecimento facial na entrada atua apenas como um hardware externo de consumo de dados: essa automação não interfere na modelagem do banco de dados, que opera de forma independente e pronta para fornecer

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

## 2. Processos de Negócio
 
Os processos abaixo foram mapeados a partir das entrevistas de 01/09/2026 e 13/10/2026 com o CEO Adalberto e dos esclarecimentos do grupo. Cada processo segue a mesma estrutura: Hoje (AS-IS), No sistema (TO-BE) em passos numerados com o responsável por cada um, Dados registrados, Regras e Integração com os outros processos.
 
**Valores confidenciais:** mensalidades, percentuais de desconto, acréscimo por modalidade extra, multas, fórmula da multa rescisória e taxas de exame existem na academia, mas são dados confidenciais do negócio e não são divulgados neste documento. O sistema tem os campos para guardá-los, e a massa de dados usa valores fictícios.
 
**Papéis:** CEO (Adalberto, gestor, professor de Muay Thai e único contratado; a academia não tem recepcionista, então ele também faz a recepção); professores (5 prestadores de serviço, um responsável por modalidade); aluno; interessado (quem ainda não é aluno); responsável legal (de aluno menor de idade).
 
**Porte:** cerca de 30 a 40 alunos, 6 modalidades (Muay Thai, Kickboxing, Jiu-Jitsu, Boxe, Capoeira, No-Gi), 4 turmas por dia em horários diferentes, turmas de até 30 alunos.
 
---
 
### 1. Captação e Aula Experimental
 
**Hoje (AS-IS):** a academia não tem recepcionista. Quem recebe o interessado, combina o horário e acompanha a aula experimental é o CEO, que também faz a recepção durante as aulas das demais modalidades. O interessado agenda a aula presencialmente ou pelo WhatsApp. A academia prefere horários de menor movimento (sextas-feiras e turmas matutinas), mas não é regra rígida. Nada é registrado: se a pessoa já fez a aula experimental depende da memória dos professores e da gestão (P8).
 
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
 
### 2. Cadastro e Matrícula
 
**Hoje (AS-IS):** como a academia não tem recepcionista, o CEO faz o cadastro e a matrícula dos alunos novos presencialmente. O aluno preenche uma ficha de papel guardada em pasta física no balcão, com risco de extravio e deterioração (P5). A data da matrícula é anotada na ficha. Não existe número de matrícula: o aluno é identificado por nome ou CPF. A troca de turma não é registrada.
 
**No sistema (TO-BE):**
 
1. O aluno informa seus dados: CPF, nome completo, data de nascimento, endereço (CEP, rua, número e bairro), e-mail, problemas de saúde, esportes já praticados, por quanto tempo treinou e se já é graduado. Informa também quantos telefones forem necessários (principal, reserva, emergência). (aluno e CEO)
2. O sistema confere a idade. Se o aluno tem menos de 18 anos, exige os dados do responsável legal (nome, CPF, telefone e parentesco) e o atestado de aptidão física, entregue antes da matrícula. O sistema registra a data de entrega do atestado.
3. O CEO confirma o cadastro. O sistema gera o identificador único do aluno, que já fica com a situação Ativo.
4. O aluno escolhe o plano (processo 3).
5. O aluno escolhe a modalidade e a turma. O sistema cria a matrícula (aluno + turma) com data e situação e confere o limite de 30 alunos ativos. Se a turma estiver lotada, o aluno escolhe outra turma.
6. A primeira mensalidade é gerada já com o valor integral, sem cálculo proporcional, e vence no 5º dia útil seguinte.
**Troca de turma:** passa a ser registrada. A matrícula antiga é encerrada e uma nova é criada; a antiga nunca é apagada e fica no histórico. O tempo de treino é guardado por aluno em cada modalidade.
 
**Autorização de uso de imagem:** quando o interessado vira aluno, o CEO pergunta se a academia pode usar a imagem dele em vídeos do Instagram. O sistema registra a resposta (autoriza ou não autoriza) e a data. Se o aluno tem menos de 18 anos, a resposta é dada pelo responsável legal.
 
**Proteção de dados pessoais (LGPD):** o cadastro reúne dados pessoais comuns (CPF, endereço, telefones, e-mail) e dados pessoais sensíveis (problemas de saúde). Por isso o sistema segue estas regras:
 
- **Finalidade e base legal:** os dados cadastrais são tratados para executar o contrato de prestação do serviço (matrícula, cobrança, controle de frequência e graduação). Os problemas de saúde são coletados com o consentimento do aluno, para que o professor conheça as restrições dele durante o treino. O uso de imagem é uma autorização separada, opcional e revogável a qualquer momento, e não condiciona a matrícula.
- **Menores de idade:** o consentimento e a autorização de imagem são dados pelo responsável legal, cujos dados também são registrados.
- **Minimização:** só se coleta o que o processo usa. Por isso o sistema não guarda o número do RG do Plano Família (só o tipo de documento e a data da conferência) nem dados bancários de credores.
- **Acesso por perfil:** o CEO acessa todos os dados. O professor acessa apenas os dados necessários para a aula (nome, turma, presença e restrições de saúde informadas). Os dados financeiros do aluno ficam restritos ao CEO.
- **Guarda e eliminação:** os dados são mantidos enquanto o aluno tiver contrato e, depois, pelo prazo necessário para o histórico de matrículas, pagamentos e graduações [prazo a definir com o CEO]. Após esse prazo, ou a pedido do titular quando não houver obrigação de guarda, os dados são eliminados ou anonimizados.
- **Direitos do titular:** o aluno (ou o responsável legal) pode pedir ao CEO a confirmação do tratamento, o acesso, a correção e a eliminação dos seus dados, e revogar a autorização de imagem.
- **Fim do papel:** as fichas físicas deixam de existir, o que elimina a exposição dos dados no balcão (P5).
**Dados registrados:** os do cadastro acima; telefones (vários por aluno); endereço (CEP, rua, número e bairro); responsável legal (nome, CPF, telefone, parentesco) e data de entrega do atestado, quando menor; autorização de uso de imagem (sim ou não) e data da resposta; na matrícula, aluno, turma, data da matrícula e situação (Ativa, Cancelada, Trancada e Encerrada, esta usada na troca de turma).
 
**Regras:** situação do aluno restrita a Ativo (contrato vigente), Inativo (contrato terminado) ou Trancado (trancamento em curso); um aluno pode ter várias matrículas (várias modalidades) e um único contrato; menor de 18 anos exige responsável legal e atestado de aptidão física; CPF único; problemas de saúde e CPF são dados sensíveis, tratados conforme a regra de LGPD acima; a autorização de uso de imagem é opcional e fica registrada com a data; matrícula encerrada nunca é apagada.
 
**Integração:** recebe de Aula Experimental; envia para Contratação de Planos, Frequência e Graduação.
 
---
 
### 3. Contratação de Planos
 
**Hoje (AS-IS):** a academia trabalha com planos de diferentes durações, sem registro formal do que cada aluno contratou além da data de pagamento anotada no WhatsApp (P9).
 
**No sistema (TO-BE):**
 
1. O aluno escolhe a duração: Mensal, Trimestral, Semestral ou Anual. Cada duração tem uma faixa de desconto progressivo (percentuais confidenciais).
2. O aluno escolhe a abrangência. O plano regular cobre uma única modalidade. Para mais de uma modalidade ou livre acesso a todas, aplica-se um acréscimo proporcional, mantida a tabela de desconto do ciclo. Cada aluno tem um único contrato (no Plano Família, o contrato é do titular e cobre os dependentes), que lista as modalidades cobertas; cada modalidade extra entra nesse mesmo contrato como um acréscimo.
3. **Plano Família:** exige no mínimo duas pessoas com parentesco comprovado e existe em todas as durações, cada uma com seu desconto. O plano tem um responsável (titular) e pode ter até 4 dependentes. O titular tem um contrato único, que cobre os dependentes. A prova de parentesco exige, no mínimo, o RG: o sistema registra o tipo de documento apresentado e a data da conferência, sem guardar o número do RG.
4. O sistema calcula a mensalidade (valor base + acréscimos por modalidade extra - desconto).
5. O contrato é registrado e o sistema gera as mensalidades (processo 4). Pagamento: os planos Trimestral, Semestral e Anual definem apenas o ciclo e o desconto. O pagamento é sempre em parcelas mensais, vencendo no 5º dia útil. Não existe quitação antecipada. Um plano anual gera 12 mensalidades.
**Renovação:** o contrato não termina sozinho. No fim do ciclo, o aluno é contatado e avisado de possíveis alterações no desconto do seu plano. Se aceita, o contrato continua; se recusa, o contrato é cancelado e o aluno passa a Inativo.
 
**Dados registrados (contrato):** aluno, plano, modalidades cobertas, data de início, data de fim do ciclo, valor da mensalidade, percentual de desconto, acréscimos por modalidade extra (quando houver), data do cancelamento e valor da multa rescisória (quando houver). No Plano Família, também o titular, os dependentes e o documento de parentesco apresentado.
 
**Regras:** vencimento fixo no 5º dia útil; multa rescisória só em planos de maior duração (processo 5); contrato só termina por cancelamento.
 
**Integração:** recebe de Cadastro e Matrícula; envia para Cobrança e para Trancamento e Cancelamento.
 
---
 
### 4. Cobrança e Recebimento de Mensalidades
 
**Hoje (AS-IS):** o controle é feito pelo WhatsApp e registra apenas a data em que o aluno pagou. Atrasos não são registrados. A inadimplência é o problema mais frequente da academia (P1).
 
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
 
### 5. Trancamento, Troca de Modalidade e Cancelamento
 
**Hoje (AS-IS):** trancamentos e cancelamentos são tratados só pelo WhatsApp, sem registro (P6).
 
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
 
### 6. Montagem de Turmas e Horários
 
**Hoje (AS-IS):** as turmas são organizadas por cronograma de aulas, com horários definidos de acordo com a modalidade. Não há controle formal das vagas.
 
**No sistema (TO-BE):**
 
1. O CEO cria a turma com modalidade, professor responsável, dia da semana, horário de início e horário de fim. Há 4 turmas por dia, em horários diferentes. Aos sábados só há turma de Capoeira, que tem uma única turma.
2. O sistema só aceita o professor se ele ensina a modalidade da turma (cada professor tem uma única modalidade).
3. O aluno entra na turma pela matrícula. Ao chegar a 30 alunos ativos, o sistema bloqueia novas matrículas.
4. Regra de referência para abrir horário: Muay Thai 4 alunos (turma do CEO), Boxe 6, Jiu-Jitsu, Kickboxing e No-Gi 8, Capoeira 10. O sistema só alerta quando a turma tem menos alunos, porque na prática o instrutor pode dar o treino assim mesmo.
5. **Instrutor auxiliar:** o professor responsável pela modalidade pode escolher o aluno mais graduado para auxiliar, mas isso não é regra e não é marcado no sistema. Quando o CEO está dando sua aula de Muay Thai e precisa receber alunos novos, ele deixa um aluno mais graduado conduzindo o treino. Esse aluno é um instrutor auxiliar eventual, que não é funcionário nem é registrado, e a aula continua registrada em nome do professor responsável da turma.
**Dados registrados:** turma (modalidade, professor, dia, horário de início e fim) e quórum por modalidade.
 
**Integração:** fornece as turmas para Matrícula e Frequência.
 
---
 
### 7. Controle de Frequência
 
**Hoje (AS-IS):** a presença não é registrada de forma alguma. A liberação para exame depende da percepção visual do professor (P2).
 
**No sistema (TO-BE):**
 
1. Na aula, o professor abre a aula ministrada da turma: turma, data, horário e professor que a deu. No futuro, a catraca com reconhecimento facial registra a turma e o horário em que o aluno entrou.
2. O sistema lista os alunos com matrícula ativa. Alunos trancados ou bloqueados por atraso não têm presença registrada.
3. O professor marca presença ou falta de cada aluno.
4. O histórico fica guardado por matrícula. Cada professor consulta quais alunos já têm a frequência que ele exige para o exame.
**Reposição de aula (sem registro de presença)**
 
1. Quando o professor titular falta, o aluno tem direito a uma aula de reposição, na mesma modalidade ou em outra.
2. O professor confirma se há vaga na turma escolhida.
3. O aluno comparece e apenas assiste à aula: não é registrada presença para ele, porque não é matriculado nessa turma. A reposição fica registrada no sistema só como concessão usada (aluno, aula perdida, turma e data da reposição). A vaga ocupada por ele conta no limite de 30 da turma nessa aula.
**Funções do registro:** embasar a liberação para graduação e comprovar as aulas dadas, base do pagamento dos professores.
 
**Dados registrados:** aula (turma, data, hora de início e fim, professor); presença (aula, matrícula, presente ou ausente); reposição (aluno, aula perdida, turma e data da reposição), sem presença.
 
**Regras:** a frequência mínima para exame é definida por cada professor, não pela academia; aluno bloqueado não registra presença.
 
**Integração:** recebe de Matrícula, Turmas e Cobrança (bloqueio); envia para Graduação e para Pagamento dos Professores.
 
---
 
### 8. Graduação e Exames de Faixa
 
**Hoje (AS-IS):** a evolução considera tempo de treino, técnica e resistência, mas depende da percepção visual do professor. A data da mudança de faixa fica só no certificado (P3).
 
**No sistema (TO-BE):**
 
1. O professor consulta a frequência e o tempo de treino do aluno na modalidade e decide quem está apto. Cada faixa tem seu tempo mínimo, cadastrado em cada faixa, para o sistema alertar quem já pode ser avaliado.
2. O aluno apto paga a taxa de exame, com valor diferente por faixa (as primeiras são mais baratas). A taxa é registrada no sistema (valores confidenciais) e cobrada junto com a mensalidade, paga por Pix, crédito ou débito.
3. O exame acontece. Muay Thai, Jiu-Jitsu, Kickboxing, No-Gi e Capoeira têm exame de faixa.
4. O professor registra o resultado do exame. A reprovação também é registrada, com o motivo em palavras-chave (por exemplo, condicionamento físico, técnica), para o professor entender por que os alunos estão reprovando.
5. **Boxe:** não há exame. A evolução é registrada como análise técnica do professor, com observação e data, sem faixa.
**Dados registrados:** aluno, modalidade, faixa ou nível avaliado (vazio no Boxe), data, resultado (aprovado ou reprovado), observações e motivo da reprovação, em palavras-chave; taxa de exame (valor, cobrada junto com a mensalidade).
 
**Regras:** apenas modalidades com sistema de faixas têm faixa; o aluno só faz exame com a frequência exigida pelo professor e o tempo mínimo da faixa; reprovação fica no histórico.
 
**Integração:** recebe de Frequência e de Matrícula (tempo de treino); a taxa de exame vai para Cobrança e é cobrada junto com a mensalidade.
 
---
 
### 9. Equipamentos da Academia
 
**Hoje (AS-IS):** a academia tem luvas, capacetes, caneleiras e materiais de treino funcional, usados por todos os alunos durante as aulas. Não há registro nem cobrança.
 
**No sistema (TO-BE):** não há processo de empréstimo. O aluno recém-matriculado pode treinar em qualquer modalidade sem equipamento próprio. Os equipamentos entram no sistema apenas pela compra (processo 10).
 
---
 
### 10. Compras
 
**Hoje (AS-IS):** o CEO faz as compras de memória, sem inventário nem registro (P4).
 
**No sistema (TO-BE):**
 
1. O CEO compra, em quatro grupos: materiais de treino (saco de pancada, cordas, pneus), sob demanda e conforme o desgaste; higiene e limpeza (álcool, descartáveis, sanitizantes, papel higiênico), semanal e presencial; equipamentos de proteção para os alunos (luvas, capacetes, caneleiras); e água para consumo, semanal, fornecida gratuitamente a todos.
2. O CEO registra cada compra no sistema e guarda a nota ou o comprovante. A academia não tem fornecedor fixo: o fornecedor muda de uma compra para outra.
3. Cada compra gera uma despesa em Contas a Pagar.
**Dados registrados:** data, grupo da compra, descrição, quantidade, valor total, forma de pagamento, nota ou comprovante guardado e fornecedor (o nome é anotado em cada compra, sem cadastro fixo).
 
**Regras:** sem controle de estoque nem de durabilidade (justificado na tabela de exclusões).
 
**Integração:** envia para Contas a Pagar.
 
---
 
### 11. Gestão e Pagamento dos Professores
 
**Hoje (AS-IS):** o CEO é professor de Muay Thai. Os demais 5 professores são prestadores de serviço, não assalariados, um por modalidade (6 professores no total). Reposições e acordos são verbais, sem registro. As aulas ministradas não são registradas, então o pagamento por aula não tem base confiável (P7). A qualificação (tempo de treino, faixa, mestres anteriores) é só conversada.
 
**No sistema (TO-BE):**
 
1. O professor é cadastrado com CPF, nome, data de nascimento, endereço, e-mail, telefone, modalidade de atuação, nível de experiência e qualificações (tempo de treino, faixa, mestres anteriores).
2. A cada período, o CEO apura o valor devido a cada professor pelas aulas ministradas, a partir do registro de frequência. O valor por aula é igual para todos os professores.
3. O CEO paga o professor no 5º dia útil, por Pix.
4. O pagamento gera uma despesa em Contas a Pagar.
**Dados registrados:** professor, período de apuração, aulas ministradas, valor por aula, valor total, data de pagamento, forma de pagamento.
 
**Regras:** o pagamento depende do registro confiável das aulas ministradas; um professor só leciona a modalidade em que é especialista.
 
**Integração:** recebe de Frequência (aulas ministradas); envia para Contas a Pagar.
 
---
 
### 12. Contas a Pagar
 
**Hoje (AS-IS):** não há controle sistematizado. O CEO guarda de memória os valores e as datas de vencimento (P4).
 
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
 
---
 
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
