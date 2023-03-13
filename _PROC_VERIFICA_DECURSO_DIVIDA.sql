USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_VERIFICA_DECURSO_DIVIDA', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_VERIFICA_DECURSO_DIVIDA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_VERIFICA_DECURSO_DIVIDA
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 10/08/2022	
	*	DATA......: 06/10/2022	
	*	DESCRIÇÃO.: Procedure para verificar o decurso das dividas que estao para expirar
	***************************************************************************************************************************************************************************************/
	IF Object_ID('tempDB..##TB_DECURSO_DIVIDA','U') IS NOT NULL				DROP TABLE ##TB_DECURSO_DIVIDA;	
	/**************************************************************************************************************************************************************************************/	
	DECLARE @DIRETORIO										VARCHAR(100)= 'F:\DECURSO_DIVIDA\';	
	DECLARE @SQL_CONSULTA									VARCHAR(MAX) = '';	
	DECLARE @SQL_QUERY										VARCHAR(8000) = '';	
	DECLARE @DIRETORIO_BCP									VARCHAR(4000) = '';
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/


	IF Object_ID('tempDB..#TB_CEDENTE_AUX','U') is not null			DROP TABLE #TB_CEDENTE_AUX;	
	/**************************************************************************************************************************************************************************************/
	DECLARE @CEDENTE_DIAS_DEV										INT = 0;
	DECLARE @QTD_DIAS_ALERTA										INT = 10; /*	Quantidade de dias para avisar antes da expiração	*/
	/**************************************************************************************************************************************************************************************/
	DECLARE @ID_CEDENTE												BIGINT = 0;
	DECLARE @CEDENTE_GRUPO											BIGINT = 0;
	DECLARE @CEDENTE_GRUPO_NM										VARCHAR(250) = '';
	DECLARE @CEDENTE_GRUPO_IN										VARCHAR(250) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @EXEC_BCP												VARCHAR(4000) = '';	
	DECLARE @NM_ARQUIVO												VARCHAR(100)= '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @TBCMDDIR_TEMP_PATHNAME									VARCHAR(MAX) = '';
	DECLARE @TBCMDDIR_TEMP_NAME										VARCHAR(MAX) = '';
	DECLARE @TBCMDDIR_TEMP_TP										VARCHAR(5) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @EXEC_SQL_CMDSHELL										VARCHAR(8000) = '';	
	/**************************************************************************************************************************************************************************************/
	DECLARE @EMAIL_FILE												VARCHAR(250) = '';
	DECLARE @EMAIL_RECIPIENTS										VARCHAR(500) = '';
	DECLARE @EMAIL_CP_RECIPIENTS									VARCHAR(500) = '';
	DECLARE @EMAIL_BLIND_RECIPIENTS									VARCHAR(500) = '';
	DECLARE @EMAIL_SUBJECT											VARCHAR(500) = '';
	DECLARE @BODY_ENVIO_HTML										NVARCHAR(MAX) = '' ;
	/**************************************************************************************************************************************************************************************/
	DECLARE @EMAIL_ENVIO_NS											BIGINT = 0;
	DECLARE @EMAIL_ENVIO_PROFILE_NAME 								VARCHAR(250) = '';
	DECLARE @EMAIL_ENVIO_RECIPIENTES								VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_CP_RECIPIENTES								VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_BLIND_CP_RECIPIENTES						VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_FROM_ADDRESS								VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_REPLY_TO									VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_SUBJECT									VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_BODY									    NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO_BODY_FORMAT								VARCHAR(100) = '';
	DECLARE @EMAIL_ENVIO_IMPORTANCE									VARCHAR(100) = '';
	DECLARE @EMAIL_ENVIO_SENSITIVITY								VARCHAR(100) = '';
	DECLARE @EMAIL_ENVIO_FILE_ATT									VARCHAR(2000) = '';
	DECLARE @EMAIL_ENVIO_QUERY										NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO_EXEC_QUERY_DB								NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO_ATT_QUERY_RESULT							NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO											INT = 0;
	DECLARE @EMAIL_ENVIO_MAILITEM_ID								BIGINT = 0;
	/**************************************************************************************************************************************************************************************/	
	DECLARE @COUNT													BIGINT = 0;
	/***************************************************************************************************************************************************************************************
	*	1 = SAÚDE
	*	2 = DANOS
	*	3 = DÉBITO
	*	4 = EDUCACIONAL
	*	5 = ALLCARE
	***************************************************************************************************************************************************************************************/	
	/**************************************************************************************************************************************************************************************/	
	DECLARE @ERROR_NUMBER_AUX									VARCHAR(500)
	DECLARE @ERROR_SEVERITY_AUX									VARCHAR(500)
	DECLARE @ERROR_STATE_AUX									VARCHAR(500)
	DECLARE @ERROR_PROCEDURE_AUX								VARCHAR(500)
	DECLARE @ERROR_LINE_AUX										VARCHAR(500)
	DECLARE @ERROR_MESSAGE_AUX									VARCHAR(500)
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY 	
	/***************************************************************************************************************************************************************************************
	*	TABELA DECURSO DIVIDA
	***************************************************************************************************************************************************************************************/		
		CREATE TABLE ##TB_DECURSO_DIVIDA(
			 CEDENTE_GRUPO_NS										BIGINT  NOT NULL DEFAULT 0
			,CEDENTE_NM_FANTASIA									VARCHAR(250) NOT NULL DEFAULT ''
			,ID_CLIENTE  											VARCHAR(50) NOT NULL DEFAULT ''
			,NM_NOME	  											VARCHAR(50) NOT NULL DEFAULT ''
			,NU_CPF_CNPJ  											VARCHAR(50) NOT NULL DEFAULT ''
			,ID_CONTRATO  											VARCHAR(50) NOT NULL DEFAULT ''
			,NM_CONTRATO_CEDENTE									VARCHAR(50) NOT NULL DEFAULT ''
			,NM_PRODUTO												VARCHAR(50) NOT NULL DEFAULT ''
			,DT_EXPIRACAO											VARCHAR(50) NOT NULL DEFAULT ''
			,ID_DIVIDA												VARCHAR(50) NOT NULL DEFAULT ''
			,NM_DIVIDA_CEDENTE										VARCHAR(50) NOT NULL DEFAULT ''
			,VL_DIVIDA												VARCHAR(50) NOT NULL DEFAULT ''
			,DT_INCLUSAO											VARCHAR(50) NOT NULL DEFAULT ''
			,DT_VENCIMENTO											VARCHAR(50) NOT NULL DEFAULT ''
			,QTD_ACAO												VARCHAR(50) NOT NULL DEFAULT ''
			,NM_ULTIMA_ACAO											VARCHAR(500) NOT NULL DEFAULT ''
			,DS_ACAO												VARCHAR(3000) NOT NULL DEFAULT ''
			,DT_ACAO												VARCHAR(50) NOT NULL DEFAULT ''
			,QTD_DIA_EC												VARCHAR(50) NOT NULL DEFAULT ''
			,QTD_DIA_ATRASO											VARCHAR(50) NOT NULL DEFAULT ''
			,CEDENTE_DIAS_DEV										VARCHAR(50) NOT NULL DEFAULT ''
			,CEDENTE_FASE											VARCHAR(50) NOT NULL DEFAULT ''
			,CEDENTE_FASE_NS										BIGINT DEFAULT 0
			,SEGMENTO												VARCHAR(250) NOT NULL DEFAULT ''
			,FLAG													BIGINT DEFAULT 0
		);
	/***************************************************************************************************************************************************************************************
	*	CEDENTES
	***************************************************************************************************************************************************************************************/
		SELECT DISTINCT
			 DB_CEDE.ID_CEDENTE
			 ,DB_PRDE.NM_DETALHE_VALOR
			,0 AS 'FLAG_CEDENTE'
		INTO
			#TB_CEDENTE_AUX
		FROM 
			[easycollector].[dbo].[TB_CEDENTE]										DB_CEDE
			JOIN [easycollector].[dbo].[TB_PRODUTO]									DB_PROD ON DB_CEDE.ID_CEDENTE = DB_PROD.ID_CEDENTE 
			JOIN [easycollector].[dbo].[TB_PRODUTO_DETALHE]							DB_PRDE ON DB_PROD.ID_PRODUTO = DB_PRDE.ID_PRODUTO
		WHERE
			DB_CEDE.ID_CEDENTE NOT IN(1, 13, 55, 68,85)
			AND DB_PRDE.ID_DETALHE = 727
		ORDER BY
			DB_CEDE.ID_CEDENTE;				
	/***************************************************************************************************************************************************************************************
	*	DECURSO
	***************************************************************************************************************************************************************************************/	
		WHILE(EXISTS(SELECT TOP 1 ID_CEDENTE FROM #TB_CEDENTE_AUX WHERE FLAG_CEDENTE = 0))BEGIN
			SELECT TOP 1 @ID_CEDENTE = ID_CEDENTE, @CEDENTE_GRUPO_NM = NM_DETALHE_VALOR FROM #TB_CEDENTE_AUX WHERE FLAG_CEDENTE = 0;
			
		/***************************************************************************************************************************************************************************************
		*	SEGMENTO
		***************************************************************************************************************************************************************************************/
			SELECT @CEDENTE_GRUPO = (
				CASE
					WHEN @CEDENTE_GRUPO_NM = 'SAÚDE' THEN 1
					WHEN @CEDENTE_GRUPO_NM = 'SAUDE' THEN 1
					WHEN @CEDENTE_GRUPO_NM = 'DANOS' THEN 2
					WHEN @CEDENTE_GRUPO_NM = 'DÉBITO' THEN 3
					WHEN @CEDENTE_GRUPO_NM = 'DEBITO' THEN 3
					WHEN @CEDENTE_GRUPO_NM = 'EDUCACIONAL' THEN 4
					WHEN @CEDENTE_GRUPO_NM = 'ALLCARE' THEN 5
					ELSE 0
					END		
			);			
		/***************************************************************************************************************************************************************************************
		*	CABEÇALHO DE CADA SEGMENTO
		***************************************************************************************************************************************************************************************/
			IF ((SELECT COUNT(CEDENTE_GRUPO_NS) FROM ##TB_DECURSO_DIVIDA WHERE CEDENTE_GRUPO_NS = @CEDENTE_GRUPO AND CEDENTE_NM_FANTASIA = '_CEDENTE') = 0)BEGIN
				INSERT INTO ##TB_DECURSO_DIVIDA
				SELECT
					@CEDENTE_GRUPO			-- CEDENTE_GRUPO_NS
					,'_CEDENTE'				-- CEDENTE_NM_FANTASIA
					,'Cliente E.C.'			-- ID_CLIENTE
					,'Nome'					-- NM_NOME
					,'CPF/CNPJ'				-- NU_CPF_CNPJ
					,'Contrato E.C.'		-- ID_CONTRATO
					,'Contrato'				-- NM_CONTRATO_CEDENTE
					,'Produto'				-- NM_PRODUTO
					,'Data expiração'		-- DT_EXPIRACAO
					,'Dívida E.C.'			-- ID_DIVIDA
					,'Dívida'				-- NM_DIVIDA_CEDENTE
					,'Valor'				-- VL_DIVIDA
					,'Data inclusão'		-- DT_INCLUSAO
					,'Data vencimento'		-- DT_VENCIMENTO
					,'QTD acionamento'		-- QTD_ACAO
					,'Ultima ação'			-- NM_ULTIMA_ACAO
					,'Descrição ação'		-- DS_ACAO
					,'Data ação'			-- DT_ACAO
					,'QTD dias E.C.'		-- QTD_DIA_EC
					,'QTD dias atraso'		-- QTD_DIA_ATRASO
					,'QTD dias devolução'	-- CEDENTE_DIAS_DEV
					,'Fase'					-- CEDENTE_FASE
					,0						-- CEDENTE_FASE_NS
					,'Segmento'				-- SEGMENTO
					,0
			END;
		/***************************************************************************************************************************************************************************************
		*	INFORMAÇÕES DE CADA DIVIDA
		***************************************************************************************************************************************************************************************/
			INSERT INTO ##TB_DECURSO_DIVIDA
			SELECT 
				 @CEDENTE_GRUPO
				,DB_CEDE.NM_CEDENTE
				,CONVERT(VARCHAR(20), DB_CLIE.ID_CLIENTE)
				,DB_CLIE.NM_NOME
				,CONVERT(VARCHAR(20), DB_CLIE.NU_CPF_CNPJ)
				,CONVERT(VARCHAR(20), DB_CONT.ID_CONTRATO)
				,DB_CONT.NM_CONTRATO_CEDENTE
				,DB_PROD.NM_PRODUTO
				,ISNULL(CONVERT(VARCHAR(10), DB_CONT.DT_EXPIRACAO, 103), '')
				,CONVERT(VARCHAR(20), DB_DIVI.ID_DIVIDA)
				,DB_DIVI.NM_DIVIDA_CEDENTE
				,CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( DB_DIVI.VL_DIVIDA)))
				,ISNULL(CONVERT(VARCHAR(10), DB_DIVI.DT_INCLUSAO, 103), '')
				,ISNULL(CONVERT(VARCHAR(10), DB_DIVI.DT_VENCIMENTO, 103), '')
				,CONVERT(VARCHAR(20), (SELECT COUNT(DB_CLAC.ID_ACAO) FROM [easycollector].[dbo].[TB_CLIENTE_ACAO] DB_CLAC WHERE DB_CLAC.ID_CLIENTE = DB_CLIE.ID_CLIENTE AND ISNULL(DB_CLAC.TP_EXCLUIDO, 0) = 0))
				,ISNULL((
					SELECT TOP 1
						DB_ACAO.NM_ACAO
					FROM 
						[easycollector].[dbo].[TB_CLIENTE_ACAO] DB_CLAC 
						JOIN [easycollector].[dbo].[TB_ACAO] DB_ACAO ON DB_CLAC.ID_ACAO = DB_ACAO.ID_ACAO
					WHERE 
						DB_CLAC.ID_CLIENTE = DB_CLIE.ID_CLIENTE
						AND ISNULL(DB_CLAC.TP_EXCLUIDO, 0) = 0
					ORDER BY
						DB_CLAC.DT_ACAO DESC

				), '')
				,ISNULL((
					SELECT TOP 1
							REPLACE(REPLACE(REPLACE(REPLACE(DB_CLAC.DS_ACAO, '\n', ''), '\t', ''),CHAR(13) + Char(10) ,''), CHAR(10), '')
					FROM 
						[easycollector].[dbo].[TB_CLIENTE_ACAO] DB_CLAC 
						JOIN [easycollector].[dbo].[TB_ACAO] DB_ACAO ON DB_CLAC.ID_ACAO = DB_ACAO.ID_ACAO
					WHERE 
						DB_CLAC.ID_CLIENTE = DB_CLIE.ID_CLIENTE
						AND ISNULL(DB_CLAC.TP_EXCLUIDO, 0) = 0
					ORDER BY
						DB_CLAC.DT_ACAO DESC

				),'') 
				,ISNULL((
					SELECT TOP 1
						CONVERT(VARCHAR(10), DB_CLAC.DT_ACAO, 103)
					FROM 
						[easycollector].[dbo].[TB_CLIENTE_ACAO] DB_CLAC 
						JOIN [easycollector].[dbo].[TB_ACAO] DB_ACAO ON DB_CLAC.ID_ACAO = DB_ACAO.ID_ACAO
					WHERE 
						DB_CLAC.ID_CLIENTE = DB_CLIE.ID_CLIENTE
						AND ISNULL(DB_CLAC.TP_EXCLUIDO, 0) = 0
					ORDER BY
						DB_CLAC.DT_ACAO DESC

				),'') 
				,CONVERT(VARCHAR(20), DATEDIFF(DAY, DB_DIVI.DT_INCLUSAO, GETDATE()))
				,CONVERT(VARCHAR(20), DATEDIFF(DAY, DB_DIVI.DT_VENCIMENTO, GETDATE()))
				,DB_PRDE.NM_DETALHE_VALOR				
				,(
					CASE 
						WHEN DB_FASE.NU_ATRASO_DE IS NOT NULL AND DB_FASE.NU_ATRASO_ATE  IS NOT NULL THEN (CONVERT(VARCHAR(20), DB_FASE.NU_ATRASO_DE )  + ' - ' + CONVERT(VARCHAR(20), DB_FASE.NU_ATRASO_ATE ))
						ELSE ''
						END)
				,ISNULL(DB_FASE.NU_ATRASO_DE,0)
				,@CEDENTE_GRUPO_NM
				,0
			FROM
				[easycollector].[dbo].[TB_CEDENTE]										DB_CEDE
				JOIN [easycollector].[dbo].[TB_CLIENTE]									DB_CLIE ON DB_CEDE.ID_CEDENTE = DB_CLIE.ID_CEDENTE
				JOIN [easycollector].[dbo].[TB_CONTRATO]								DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
				JOIN [easycollector].[dbo].[TB_PRODUTO]									DB_PROD ON DB_CONT.ID_PRODUTO = DB_PROD.ID_PRODUTO	
				JOIN [easycollector].[dbo].[TB_PRODUTO_DETALHE]							DB_PRDE ON DB_PROD.ID_PRODUTO = DB_PRDE.ID_PRODUTO							
				JOIN [easycollector].[dbo].[TB_DIVIDA]									DB_DIVI ON DB_CONT.ID_CONTRATO = DB_DIVI.ID_CONTRATO
				LEFT JOIN [easycollector].[dbo].[TB_FASE]								DB_FASE ON DB_CEDE.ID_CEDENTE = DB_FASE.ID_CEDENTE
			WHERE
				DB_CEDE.ID_CEDENTE = @ID_CEDENTE
				AND CONVERT(DATE, DB_CONT.DT_EXPIRACAO) > CONVERT(DATE, GETDATE())					
				AND DB_PRDE.ID_DETALHE = 728	
				AND DATEDIFF(DAY, DB_DIVI.DT_VENCIMENTO, GETDATE()) BETWEEN DB_FASE.NU_ATRASO_DE AND DB_FASE.NU_ATRASO_ATE 				
				AND CONVERT(DATE, GETDATE()) >= DATEADD(DAY, (CONVERT(INT, DB_PRDE.NM_DETALHE_VALOR)) - @QTD_DIAS_ALERTA, CONVERT(DATE, DB_DIVI.DT_INCLUSAO))
				AND DB_DIVI.ID_DIVIDA NOT IN(
					SELECT	
						DB_DIBL.ID_DIVIDA
					FROM
						[easycollector].[dbo].[TB_DIVIDA_BLOQUEIO] DB_DIBL
					WHERE
						DB_DIBL.ID_CONTRATO = DB_CONT.ID_CONTRATO
						AND DB_DIBL.ID_DIVIDA = DB_DIVI.ID_DIVIDA						
						AND DB_DIBL.DT_DESBLOQUEIO IS NULL
				);

			UPDATE #TB_CEDENTE_AUX SET FLAG_CEDENTE = 1 WHERE ID_CEDENTE = @ID_CEDENTE;
		END;
	/***************************************************************************************************************************************************************************************
	*	EXPORTAR PARA .CSV
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 CEDENTE_GRUPO_NS FROM ##TB_DECURSO_DIVIDA WHERE FLAG = 0 AND CEDENTE_NM_FANTASIA != '_CEDENTE'))BEGIN
			SELECT TOP 1 @CEDENTE_GRUPO = CEDENTE_GRUPO_NS, @CEDENTE_GRUPO_NM = SEGMENTO FROM ##TB_DECURSO_DIVIDA WHERE FLAG = 0 AND CEDENTE_NM_FANTASIA != '_CEDENTE';

			IF((SELECT COUNT(CEDENTE_GRUPO_NS) FROM ##TB_DECURSO_DIVIDA WHERE CEDENTE_GRUPO_NS = @CEDENTE_GRUPO) > 1) BEGIN		
			
				SET @NM_ARQUIVO = CONVERT(CHAR(8), GETDATE(),112) + '_' + @CEDENTE_GRUPO_NM;
				SET @DIRETORIO_BCP =  @DIRETORIO + @NM_ARQUIVO;
				
				SET @SQL_CONSULTA  = ' SELECT ';
				SET @SQL_CONSULTA += '	CEDENTE_NM_FANTASIA';
				SET @SQL_CONSULTA += '	,ID_CLIENTE ';
				SET @SQL_CONSULTA += '	,NM_NOME ';
				SET @SQL_CONSULTA += '	,NU_CPF_CNPJ ';
				SET @SQL_CONSULTA += '	,ID_CONTRATO ';
				SET @SQL_CONSULTA += '	,NM_CONTRATO_CEDENTE ';
				SET @SQL_CONSULTA += '	,NM_PRODUTO ';
				SET @SQL_CONSULTA += '	,DT_EXPIRACAO ';
				SET @SQL_CONSULTA += '	,ID_DIVIDA ';
				SET @SQL_CONSULTA += '	,NM_DIVIDA_CEDENTE ';
				SET @SQL_CONSULTA += '	,VL_DIVIDA ';
				SET @SQL_CONSULTA += '	,DT_INCLUSAO ';
				SET @SQL_CONSULTA += '	,DT_VENCIMENTO ';
				SET @SQL_CONSULTA += '	,QTD_ACAO ';
				SET @SQL_CONSULTA += '	,NM_ULTIMA_ACAO ';
				SET @SQL_CONSULTA += '	,DS_ACAO ';
				SET @SQL_CONSULTA += '	,DT_ACAO ';
				SET @SQL_CONSULTA += '	,QTD_DIA_EC ';
				SET @SQL_CONSULTA += '	,QTD_DIA_ATRASO ';
				SET @SQL_CONSULTA += '	,CEDENTE_DIAS_DEV ';
				SET @SQL_CONSULTA += '	,CEDENTE_FASE ';
				SET @SQL_CONSULTA += '	,SEGMENTO ';
				SET @SQL_CONSULTA += ' FROM ';
				SET @SQL_CONSULTA += '	##TB_DECURSO_DIVIDA ';
				SET @SQL_CONSULTA += ' WHERE ';
				SET @SQL_CONSULTA += '	CEDENTE_GRUPO_NS = ' + CONVERT(VARCHAR(10),@CEDENTE_GRUPO);	
				SET @SQL_CONSULTA += ' ORDER BY ';	
				SET @SQL_CONSULTA += '	CEDENTE_GRUPO_NS, CEDENTE_NM_FANTASIA, CEDENTE_FASE_NS';	

				EXEC [dbo].[__EXEC_BCP] @SQL_CONSULTA = @SQL_CONSULTA, @DIRETORIO = @DIRETORIO_BCP, @DIRETORIO_LOG = @DIRETORIO_BCP, @DELIMITADOR =';';

				SET @NM_ARQUIVO += '.csv';
				EXEC [dbo].[_PROC_COMPACTA_ARQ] @FULLPATHNAME = @DIRETORIO, @ARQ_FILTRO = @NM_ARQUIVO;
			END;			
			UPDATE ##TB_DECURSO_DIVIDA SET FLAG = 1 WHERE  CEDENTE_GRUPO_NS = @CEDENTE_GRUPO;
		END;
	/***************************************************************************************************************************************************************************************
	*	ENVIO EMAIL
	***************************************************************************************************************************************************************************************/	
		EXEC [dbo].[__EXEC_CMDSHELL_DIR] @FULLPATHNAME = @DIRETORIO;

		DELETE FROM [Homolog].[dbo].[__TBCMDDIR_TEMP] WHERE CONVERT(DATE, TBCMDDIR_TEMP_DT_CRIACAO) != CONVERT(DATE, GETDATE());

		WHILE(EXISTS(SELECT TOP 1 CEDENTE_GRUPO_NS FROM ##TB_DECURSO_DIVIDA WHERE FLAG = 1 AND CEDENTE_NM_FANTASIA != '_CEDENTE'))BEGIN
			SELECT TOP 1 @CEDENTE_GRUPO = CEDENTE_GRUPO_NS, @CEDENTE_GRUPO_NM = SEGMENTO FROM ##TB_DECURSO_DIVIDA WHERE FLAG = 1 AND CEDENTE_NM_FANTASIA != '_CEDENTE';
			SET @EMAIL_ENVIO_NS = 0;
		/***************************************************************************************************************************************************************************************
		*	RESETA OS VALORES DAS VARIAVEIS
		***************************************************************************************************************************************************************************************/
			SET @EMAIL_ENVIO_RECIPIENTES = '';
			SET @NM_ARQUIVO = CONVERT(CHAR(8), GETDATE(),112) + '_' + @CEDENTE_GRUPO_NM;
			SET @EMAIL_ENVIO_FILE_ATT = '';			
			SET @EMAIL_SUBJECT = 'Decurso das Carteira ';

			SELECT
				@EMAIL_ENVIO_FILE_ATT =  ISNULL(TBCMDDIR_TEMP_PATHNAME +  TBCMDDIR_TEMP_NAME, '')
			FROM 
				__TBCMDDIR_TEMP
			WHERE
				TBCMDDIR_TEMP_TP = 'zip'
				AND REPLACE(TBCMDDIR_TEMP_NAME, '.zip', '') = @NM_ARQUIVO;
				

			IF(LEN(LTRIM(RTRIM(@EMAIL_ENVIO_FILE_ATT))) > 0 AND @CEDENTE_GRUPO = 1)BEGIN
				SET @EMAIL_ENVIO_SUBJECT = @EMAIL_SUBJECT + ' Saúde';
				SET @EMAIL_ENVIO_NS = 1;	
			END;

			IF(LEN(LTRIM(RTRIM(@EMAIL_ENVIO_FILE_ATT))) > 0 AND @CEDENTE_GRUPO = 2)BEGIN
				SET @EMAIL_ENVIO_SUBJECT = @EMAIL_SUBJECT + ' Danos ao Patrimonio';
				SET @EMAIL_CP_RECIPIENTS += 'paula.costa@Homolog.com.br;';
				SET @EMAIL_ENVIO_NS = 1;
			END;

			IF(LEN(LTRIM(RTRIM(@EMAIL_ENVIO_FILE_ATT))) > 0 AND @CEDENTE_GRUPO = 3)BEGIN
				SET @EMAIL_ENVIO_SUBJECT = @EMAIL_SUBJECT + ' Débito';	
				SET @EMAIL_ENVIO_NS = 1;
			END;
			
			IF(LEN(LTRIM(RTRIM(@EMAIL_ENVIO_FILE_ATT))) > 0 AND @CEDENTE_GRUPO = 4)BEGIN									
				SET @EMAIL_ENVIO_SUBJECT = @EMAIL_SUBJECT + ' Educacional';	
				SET @EMAIL_ENVIO_NS = 1;													
			END;

			IF(@EMAIL_ENVIO_NS = 1)BEGIN

				SET @EMAIL_FILE = '';
				SET @EMAIL_CP_RECIPIENTS = 'graciele.santos@Homolog.com.br;';
				SET @EMAIL_BLIND_RECIPIENTS = 'wanderlei.silva@Homolog.com.br;anderson.andrade@Homolog.com.br;';
				--SET @EMAIL_BLIND_RECIPIENTS = 'anderson.andrade@Homolog.com.br;';
				SET @EMAIL_ENVIO_RECIPIENTES = 'vitoria.neves@Homolog.com.br;angela.ferreira@Homolog.com.br;aryane.luz@Homolog.com.br;';

				SET @BODY_ENVIO_HTML = '';
				SET @BODY_ENVIO_HTML += N'<p>Prezados.</p>';
				SET @BODY_ENVIO_HTML += N'<p>Segue a relação das dividas que estão em nossa base onde o decurso das mesmas estao proximo de expirar.</p>';
				SET @BODY_ENVIO_HTML += N'<br/> ';

				SET @BODY_ENVIO_HTML += ' <table> ';
				SET @BODY_ENVIO_HTML += '     <caption><H3>Resumo do decurso</caption> ';
				SET @BODY_ENVIO_HTML += '     <thead> ';
				SET @BODY_ENVIO_HTML += '         <tr> ';
				SET @BODY_ENVIO_HTML += '             <th>Cedente</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Total Registros</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Total Valor</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Fase</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Segmento</th> ';
				SET @BODY_ENVIO_HTML += '     </thead> ';
				SET @BODY_ENVIO_HTML += '     <tbody> ';
				SET @BODY_ENVIO_HTML += CAST ( 
												(SELECT 
													td = CEDENTE_NM_FANTASIA, '',
													td = COUNT(CEDENTE_GRUPO_NS), '',
													td = CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( SUM(CONVERT(NUMERIC(10,2), RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(VL_DIVIDA, 'R$', ''), '.', ''), ',', '.')))))))), '',
													td = CEDENTE_FASE, '',
													td = SEGMENTO, ''
												FROM 
													##TB_DECURSO_DIVIDA		
												WHERE 
													CEDENTE_NM_FANTASIA != '_CEDENTE'
													AND CEDENTE_GRUPO_NS = @CEDENTE_GRUPO
												GROUP BY
													CEDENTE_NM_FANTASIA
													,CEDENTE_FASE
													,CEDENTE_FASE_NS
													,SEGMENTO
												ORDER BY			
													CEDENTE_NM_FANTASIA 
													,CEDENTE_FASE_NS
													FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);
				SET @BODY_ENVIO_HTML += '     </tbody> ';
				SET @BODY_ENVIO_HTML += ' </table> ';
				SET @BODY_ENVIO_HTML += ' <br/><br/> ';

				SET @BODY_ENVIO_HTML += N'<br/> ';
				SET @BODY_ENVIO_HTML += N'<p><b>Obs.:</b></p>';
				SET @BODY_ENVIO_HTML += N'<p>1) Este email tem o intuito de notificar com 10 dias de antecedencia do decurso final de cada divida de sua respectiva carteira.</p>';
				SET @BODY_ENVIO_HTML += N'<p>2) Esta rotina é executada diariamente e de forma automatica pelo banco de dados.</p>';
				SET @BODY_ENVIO_HTML += N'<p>3) O arquivo em anexo esta compactado e em formato ".csv" e para formatar os dados seguir os seguintes passos:</p>';
				SET @BODY_ENVIO_HTML += N'<p>3.1) Salvar e descompactar o arquivo em uma pasta de sua escolha.</p>';
				SET @BODY_ENVIO_HTML += N'<p>3.2) Ao abrir o arquivo ".csv" selecionar a coluna com os dados.</p>';
				SET @BODY_ENVIO_HTML += N'<p>3.3) Clicar na aba "Dados"na parte superior.</p>';
				SET @BODY_ENVIO_HTML += N'<p>3.4) Clicar em textos para colunas.</p>';
				SET @BODY_ENVIO_HTML += N'<p>3.5) Selecionar a opção "delimintado" e clicar em avançar.</p>';
				SET @BODY_ENVIO_HTML += N'<p>3.6) Em delimitadores selecionar a opção "ponto e vírgula" e clicar em avançar.</p>';
				SET @BODY_ENVIO_HTML += N'<p>3.7) Clicar em concluir.</p>';
				SET @BODY_ENVIO_HTML += N'<br/> ';
				SET @BODY_ENVIO_HTML += N'<br/> ';	

				INSERT INTO  TB_EMAIL_ENVIO(
					EMAIL_ENVIO_PROFILE_NAME
					,EMAIL_ENVIO_RECIPIENTES
					,EMAIL_ENVIO_CP_RECIPIENTES
					,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
					,EMAIL_ENVIO_FILE_ATT
				)
				SELECT
					'EmailHomolog'
					,@EMAIL_ENVIO_RECIPIENTES
					,@EMAIL_CP_RECIPIENTS
					,@EMAIL_BLIND_RECIPIENTS
					,@EMAIL_ENVIO_SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High'
					, @EMAIL_ENVIO_FILE_ATT;
			END;
			DELETE FROM ##TB_DECURSO_DIVIDA WHERE  CEDENTE_GRUPO_NS = @CEDENTE_GRUPO;
		END;

		EXEC [dbo].[_PROC_ENVIO_EMAIL];

		WHILE(EXISTS(SELECT TOP 1 TBCMDDIR_TEMP_NS FROM __TBCMDDIR_TEMP ))BEGIN
			SELECT
				@TBCMDDIR_TEMP_PATHNAME = TBCMDDIR_TEMP_PATHNAME
				,@TBCMDDIR_TEMP_NAME = TBCMDDIR_TEMP_NAME
				,@TBCMDDIR_TEMP_TP = TBCMDDIR_TEMP_TP 
			FROM
				__TBCMDDIR_TEMP;				

			IF(@TBCMDDIR_TEMP_TP != 'zip' AND @NM_ARQUIVO = REPLACE(@TBCMDDIR_TEMP_NAME, '.zip', ''))BEGIN	
				SET @SQL_QUERY = 'del "' + @TBCMDDIR_TEMP_PATHNAME + @TBCMDDIR_TEMP_NAME+ '"';	
				EXEC master.dbo.xp_cmdshell @command_string = @SQL_QUERY;
			END;
	
			DELETE FROM __TBCMDDIR_TEMP WHERE TBCMDDIR_TEMP_PATHNAME = @TBCMDDIR_TEMP_PATHNAME AND TBCMDDIR_TEMP_NAME = @TBCMDDIR_TEMP_NAME;
		END;
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/	
	END TRY 
	BEGIN CATCH  
		SELECT 
			@ERROR_NUMBER_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_NUMBER()), '')
			,@ERROR_SEVERITY_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_SEVERITY()), '')
			,@ERROR_STATE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_STATE()), '')
			,@ERROR_PROCEDURE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_PROCEDURE()), '')
			,@ERROR_LINE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_LINE()), '')
			,@ERROR_MESSAGE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_MESSAGE()), '');
	
		EXEC [dbo].[__PROC_SQL_ERROR_EMAIL]
			@ERROR_NUMBER = @ERROR_NUMBER_AUX
			,@ERROR_SEVERITY = @ERROR_SEVERITY_AUX
			,@ERROR_STATE = @ERROR_STATE_AUX
			,@ERROR_PROCEDURE = @ERROR_PROCEDURE_AUX
			,@ERROR_LINE = @ERROR_LINE_AUX
			,@ERROR_MESSAGE = @ERROR_MESSAGE_AUX;		
	END CATCH; 
END;