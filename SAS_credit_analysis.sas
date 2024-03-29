/***********************************  

Análise de Dados com SAS

************************************/

libname USER '/user/dataanalysis/SAS_CODES/ALISON';

/Tabela B cadastro de cartões, tabela C clientes, tabela A Cliente x Cartão, tabela D faturas cartão/

/** CRIANDO AS TABELAS INICIAIS A,B,C e D ***/

/TABELA A/
DATA work.tabela_a;
	INFILE DATALINES DLM='	';
	INPUT 	id_cli : 10.  
			nr_cartao : $3. ;


DATALINES;
1	123
1	765
2	564
3	098
3	567
3	234
4	012
5	789
5	876
5	432
5	890
;
Run;

/TABELA B/
Data work.tabela_b;
INFILE DATALINES DLM='	';
input 
	nr_cartao: $3.	
	forma_pagto : 1.
	venc_fatura_cad: 8.
	;
Datalines;
123	1	1
765	1	10
564	1	10
098	1	15
567	1	1
234	2	1
012	2	20
789	2	20
876	1	15
432	1	15
890	1	10
;
run;


/TABELA C/
Data work.tabela_c;
INFILE DATALINES DLM='	';

input 
	id_cli: 3.	
	dt_nascimento: $8.
	sexo: $1.
	;
Datalines;
3	20011980	F
1	25101982	F
2	08021979	F
5	12111985	M
4	07101978	M
;
run;

/TABELA D/
Data work.tabela_d;
INFILE DATALINES DLM='	';
input 
	nr_cartao: $3.	
	valor_fatura: 8.2
	anomes_ref: $8.;
Datalines;
123	20.0	052023
123	125.5	072023
123	189.0	062023
564	66.0	012023
564	340.0	022023
564	87.9	032023
564	67.55	052023
564	97.0	042023
098	34.5	032023
098	78.9	042023
098	35.0	062023
098	22.0	052023
567	99.0	032023
567	125.5	022023
567	36.7	012023
234	230.0	062023
234	50.0	072023
789	88.0	052023
789	65.5	062023
876	34.9	052023
876	67.55	072023
876	34.5	062023
890	22.0	042023
890	125.5	052023
;
run;


/*Criando uma nova tabela chamada tab_exec_1 que deve conter os clientes, a soma e a média do 
Valor das faturas desses cliente nos últimos 90 dias*/

PROC SQL;
CREATE TABLE user.tab_exec_juncao AS
SELECT A.id_cli, D.nr_cartao, valor_fatura, anomes_ref FROM work.tabela_d D
LEFT JOIN work.tabela_a A
ON A.nr_cartao = D.nr_cartao
WHERE anomes_ref >= '052023'
ORDER BY id_cli ASC, anomes_ref DESC;

CREATE TABLE user.tab_exec_1 AS
SELECT id_cli, SUM(valor_fatura) AS soma_fatura, AVG(valor_fatura) AS media_fatura
FROM user.tab_exec_juncao
/WHERE anomes_ref >= '052023'/
GROUP BY 1;

QUIT;

/*Criação da tabela com a junção das outras que serão necessárias para os cálculos solicitados
e filtragem dos valores cuja data é maior que 052023, vide que a data_max é 072023*/


/*Realizando uma contagem de clientes com forma de pagamento = 1 e retorne o valor médio de todas as 
faturas existentes*/

/*PROC PRINT DATA=work.tabela_b;
RUN;*/
/contagem de clientes(total 5 na origem)/


/**TABELA ORIGEM**/
PROC SQL NOPRINT;
SELECT*
FROM work.tabela_A AS A
LEFT JOIN work.tabela_b AS B
ON A.nr_cartao = B.nr_cartao
LEFT JOIN work.tabela_d AS D
ON A.nr_cartao = D.nr_cartao
ORDER BY id_cli;
QUIT;


PROC SQL;
SELECT COUNT(DISTINCT A.id_cli) AS contagem, 
AVG(D.valor_fatura) AS valor_medio
FROM work.tabela_A AS A
LEFT JOIN work.tabela_b AS B
ON A.nr_cartao = B.nr_cartao
LEFT JOIN work.tabela_d AS D
ON A.nr_cartao = D.nr_cartao
WHERE forma_pagto = 1
AND valor_fatura IS NOT NULL;
QUIT;


/Realização de contagem e filtragem, bem como o cálculo de valor médio/


/* Criando uma nova tabela chamada tab_exer_3 com: todos os clientes, acrescentando um novo campo dt_vencimento_fatura 
(dd/mm/aaaa - Que unifica a anomes_ref com o campo venc_fatura_cad, inclua o valor da soma das faturas com formato 
de 2 casas decimais */ 


PROC SQL;
CREATE TABLE user.tab_exer_3 AS
SELECT 
A.nr_cartao
,valor_fatura
,anomes_ref
,id_cli
,forma_pagto
,CATT(B.venc_fatura_cad,'-',SUBSTR(D.anomes_ref,1,2),'-',SUBSTR(D.anomes_ref, 3,4)) AS dt_vencimento_fatura
FROM work.tabela_a AS A
LEFT JOIN work.tabela_b AS B
ON A.nr_cartao = B.nr_cartao
LEFT JOIN work.tabela_D AS D
ON A.nr_cartao = D.nr_cartao
WHERE anomes_ref IS NOT NULL
ORDER BY A.id_cli;

SELECT id_cli,MAX(dt_vencimento_fatura) AS max_fatura,SUM(valor_fatura) AS soma_fatura FORMAT = 6.2
FROM user.tab_exer_3
GROUP BY 1;

QUIT;


/*PROC SORT DATA=user.tab_exer_3 NODUPKEY;
BY soma_faturas;
RUN;

/* Criando uma nova tabela chamada tab_exer_4, na visão cliente:
	-- Incluindo uma variável dummy(flag) que indica quais os clientes que tem entre 30 anos e 40 anos. 
	-- Incluindo uma variável com a idade dos clientes em 28/07/2023. 
	-- Incluindo uma variável com a quantidade de cartões distintos do cliente 
	-- Incluindo uma variável com a quantidade de cartões ativos do cliente
	
	

** CRITÉRIO CARTÃO ATIVO: Cartões com valor_fatura > 0 no anomes_ref anterior ao atual (M-1) ***/

/*PROC CONTENTS DATA=work.TABELA_D;
PROC PRINT DATA=work.TABELA_D;*/

PROC SQL;
SELECT *,
(SELECT COUNT(DISTINCT nr_cartao)
FROM work.tabela_d D2
WHERE D2.valor_fatura >0
AND D2.anomes_ref = PUT(INTNX('MONTH',INPUT('01'||'-'||SUBSTR(D1.anomes_ref,3,4)||'-'||SUBSTR(D1.anomes_ref,1,2),yymmn6.), -1),YYMMN6.)
AND D2.nr_cartao = D1.nr_cartao) AS teste
FROM work.tabela_d D1;
QUIT;

data user.tab_exer_4;
set work.tabela_c;
dt_nascimento_new= input(put(dt_nascimento, 8.), ddmmyy10.);
dt_calculo1 = '28/07/2023';
dt_calculo = input(put(dt_calculo1, 10.), ddmmyy10.);
format dt_nascimento_new  dt_calculo date9.;
	dif_ano=intck('year',dt_nascimento_new,today());
	dif_ano=ROUND(dif_day/365, .01);
	dif_date=intck('year',dt_nascimento_new,dt_calculo);
format dif_ano dif_date 6.2; 
	dif_cal=ROUND(dif_tes/365, .01);
drop dt_calculo1 dt_nascimento;
run;

/*proc contents DATA=user.tab_exer_4;
run;*/

/Formatação da dt_nascimento e criação de uma nova observação(coluna) chamada de dt_nascimento_new/

/PROC PRINT data=USER.TAB_EXER4;/

PROC SQL;
CREATE TABLE user.tab_exer_4 AS
SELECT DISTINCT tab_exer_4. *,
	CASE 
		WHEN dif_ano BETWEEN 30 AND 40 THEN 1
		WHEN dif_date BETWEEN 30 AND 40 THEN 1
		ELSE 0
	END AS binarizacao,
COUNT(DISTINCT nr_cartao) AS dist_cartoes
FROM user.tab_exer_4 AS T
LEFT JOIN work.tabela_a AS A
ON T.id_cli = A.id_cli
GROUP BY 1;
QUIT;


PROC SQL;
CREATE TABLE user.juncao AS
SELECT *
FROM user.tab_exer_4 AS T
LEFT JOIN work.tabela_a AS A
ON T.id_cli = A.id_cli
LEFT JOIN work.tabela_d AS D
ON A.nr_cartao = D.nr_cartao
WHERE D.nr_cartao IS NOT NULL
ORDER BY A.id_cli;
QUIT;


data user.exer_4_teste;
set user.juncao_teste1;
today = today();
anomes_ref = SUBSTR(anomes_ref,1,2)||'/'||SUBSTR(anomes_ref,3,4);
format today MMYYs7.;
keep id_cli sexo dt_nascimento_new dt_calculo dif_ano dif_date nr_cartao valor_fatura anomes_ref today;
run;

PROC SQL;
CREATE TABLE user.juncao_data AS
SELECT *, datetime() format=datetime22. AS data 
	CASE 
		WHEN substr(anomes_ref,1,2) = 5 THEN 'MAY'
FROM user.juncao;
QUIT;

PROC SQL;
CREATE TABLE user.teste AS
SELECT 
	CASE
		WHEN data LIKE '%MAY%' THEN 5
	ELSE data
	END AS data1
FROM user.juncao_data;
QUIT;


PROC SQL;
CREATE TABLE USER.VIEW2 AS
SELECT T. *, D.teste
FROM user.tab_exer_4 T
LEFT JOIN
(
SELECT nr_cartao,
(SELECT COUNT(DISTINCT nr_cartao)
FROM work.tabela_d D2
WHERE D2.valor_fatura >0
AND D2.anomes_ref = PUT(INTNX('MONTH',INPUT('01'||'-'||SUBSTR(D1.anomes_ref,3,4)||'-'||SUBSTR(D1.anomes_ref,1,2),yymmn6.), -1),YYMMN6.)
AND D2.nr_cartao = D1.nr_cartao) AS teste
FROM work.tabela_d D1
) AS D
ON D1.nr_cartao = D2.nr_cartao;
QUIT;


/* Calculando o valor médio de faturas referente a cada anomes_ref e guarde estes valores em variáveis macro */


%MACRO media(var);
PROC MEANS DATA=work.tabela_d MEAN NONOBS NOLABELS MAXDEC=2 ;
var &var;
class anomes_ref;
output out=media mean=&var._media;
title "Valor Médio";
RUN;
%MEND;

%MEDIA(valor_fatura);

/**OK**/

/*PROC SQL;
SELECT AVG(valor_fatura) AS valor_médio FROM work.tabela_d;*/


/* Selecionando uma amostra aleatória de 3 registros da tabela B  e crie a tabela_f */

PROC SQL OUTOBS=3;
CREATE TABLE user.tabela_f AS
SELECT * FROM work.tabela_b
ORDER BY rand('normal',0,1);
QUIT;

DATA user.tabela_f;
SET user.tabela_f;
PUTLOG "PDV After SET Statement";
PUTLOG ALL;
RUN;


/* Criando uma procedure para unificar todas as informações do cliente em uma tabela nomeada tabela_cli.

  Etapas necessárias:
	- verificar se as tabelas origem e destino existem
	- criar uma cópia da tabela_cli e nomea-la como tabela_cli_bkp, caso exista
	- limpar registros antigos da tabela atual
	- criar nova tabela_cli atualizada e enviar mensagem de conclusão do processo por e-mail. 
	- Importante que esse processo tenha uma variável controle data_criacao.

/PROC CONTENTS DATA=work.TABELA_D;/

/**TABELAS ORIGEM**/

PROC SQL;
SELECT * FROM work.tabela_a A
LEFT JOIN work.tabela_b B
ON A.nr_cartao = B.nr_cartao
LEFT JOIN work.tabela_c C
ON A.id_cli = C.id_cli
LEFT JOIN work.tabela_d D
ON A.nr_cartao = D.nr_cartao;
QUIT;

PROC SQL;
CREATE TABLE user.tabela_cli AS
SELECT A.id_cli
,A.nr_cartao
,B.forma_pagto
,B.venc_fatura_cad
,CATT(SUBSTR(C.dt_nascimento,5,4),'-',SUBSTR(C.dt_nascimento,3,2),'-',SUBSTR(C.dt_nascimento,1,2)) AS dt_nascimento_amd /amd= ano,mes,dia/
,C.sexo
,CASE 
WHEN D.anomes_ref NOT IS NULL THEN CATT(SUBSTR(D.anomes_ref,3,4),'-',SUBSTR(D.anomes_ref,1,2),'-01')
WHEN D.anomes_ref IS NULL THEN 'Atualize seus dados' 
END AS fatura_venc_amd
,CASE
WHEN valor_fatura IS NULL THEN 'Atualize seus dados'
ELSE input(valor_fatura, 6.2)
END AS valor_fatura*/
D.valor_fatura
FROM work.tabela_a A
LEFT JOIN work.tabela_b B
ON A.nr_cartao = B.nr_cartao
LEFT JOIN work.tabela_c C
ON A.id_cli = C.id_cli
LEFT JOIN work.tabela_d D
ON A.nr_cartao = D.nr_cartao
ORDER BY id_cli ASC;

ALTER TABLE user.tabela_cli 
ADD data_criacao NUMERIC FORMAT=datetime20.;
UPDATE user.tabela_cli
SET data_criacao = %sysfunc(datetime());/intnx('second', datetime(), 0, 'B')/

QUIT;

/**TABELAS DESTINO**/

PROC PRINT DATA=user.tabela_cli;
RUN;

/*proc contents data=user.tabela_cli;
run;*/

DATA user.tabela_cli_bkp;
SET user.tabela_cli;
RUN;

PROC SQL; 
ALTER TABLE user.tabela_cli
modify data_criacao date;
QUIT;
PROC SQL;
UPDATE user.tabela_cli
SET data_criacao = today();
QUIT;
PROC PRINT DATA=user.tabela_cli;
RUN;
%LET datahora=%sysfunc(datetime(),datetime20.);
%LET data=%substr(&datahora,1,10);
%LET hora=%substr(&datahora,12,8);
%LET data1=%sysfunc(date(), date9.);
%LET hora1=%sysfunc(time(),time8.);

PROC SQL;
DELETE FROM user.tabela_cli_cli
WHERE data_criacao < '26APR2023:13:48:48';
QUIT;

PROC SQL;
INSERT INTO user.tabela_cli
SELECT * FROM user.tabela_cli_bkp;

DELETE FROM user.tabela_cli
WHERE data_criacao > '02MAY2023:16:18:34'dt;
QUIT;


/*PROC CONTENTS DATA=work.TABELA_D;
RUN;*/


%LET processo=Exercício.SAS;
%LET data1=%sysfunc(date(), date9.);
%LET hora1=%sysfunc(time(),time8.);
%LET titulo= "Processo &processo";

filename mymail email 'alisonaraujo@live.com'
subject=&titulo
from='alisonaraujo@live.com'
to=('alisonaraujo736@gmail.com');

data null;
file mymail;
put "O processo &processo foi finalizado no dia &data1 às &hora1"; 
run;