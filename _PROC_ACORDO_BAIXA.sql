USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_ACORDO_BAIXA', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_ACORDO_BAIXA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_ACORDO_BAIXA(
	@EXECUCAO_ID							BIGINT = 0
)
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 24/08/2022
	*	DATA......: 23/12/2022
	*	DESCRIÇÃO.: Procedure para a geraçao do arquivo de acordo e baixa no sistema e geraçao do arquivo para inserçao dos acionamentos
	***************************************************************************************************************************************************************************************/
	DECLARE @RET_ARQ										TABLE(
																RET_ARQ VARCHAR(MAX)
															);	


	DECLARE @TB_AUX											TABLE(
																ID_EXECUCAO					BIGINT
																,ID_CARGA					BIGINT
																,ID_TAREFA					BIGINT
															);
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ID_EXECUCAO									BIGINT = 0;
	DECLARE @ID_CARGA										BIGINT = 0;
	DECLARE @ID_TAREFA										BIGINT = 0;
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @SEQUENCIAL										INT = 0;

	/**************************************************************************************************************************************************************************************/
	DECLARE @DATA_PROC										DATE = GETDATE();
	DECLARE @NM_ORGIEM										VARCHAR(5) = 'BAIXA';
	
	/**************************************************************************************************************************************************************************************/
	DECLARE @ARQ_POS_TP_CANCEL								INT = 81;
	DECLARE @ARQ_POS_TP_PGTO								INT = 71;
	DECLARE @ARQ_POS_TP_ACORDO								INT = 51;
	DECLARE @ARQ_POS										INT = 0;
	DECLARE @ARQ_POS_PGTO									INT = 0;
	DECLARE @ARQ_POS_ACORDO									INT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @ARQUIVO_POS_SEQ								BIGINT = 0;
	DECLARE @ARQUIVO_POS_NM									VARCHAR(150) = '';
	DECLARE @ARQUIVO_POS_TP_NS								BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @PATHNAME										VARCHAR(250) = 'D:\Homolog\arquivos\# Acordos_Baixas\# Arquivo_Posicional';	
	DECLARE @EXEC_SQL										VARCHAR(4000) = '';
	DECLARE @DIRETORIO_BCP									VARCHAR(4000) = '';
	DECLARE @DIRETORIO_BCP_log								VARCHAR(4000) = '';
	DECLARE @POWERSHELL_TEXT								NVARCHAR(500);	 
	DECLARE @SQL_QUERY_ARQ_EXIST							NVARCHAR(800) = '';	
	DECLARE @SQL_QUERY_DESTINO								NVARCHAR(800);	
	/**************************************************************************************************************************************************************************************/
	DECLARE @FLAG_ARQUIVO									BIGINT = 0	
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/	
	
	DECLARE @BODY_CABECALHO_HTML							NVARCHAR(MAX) = '' ;
	DECLARE @BODY_CORPO_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @BODY_RODAPE_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @BODY_ENVIO_HTML								NVARCHAR(MAX) = '' ;
	/**************************************************************************************************************************************************************************************/
	DECLARE @ERROR_NUMBER_AUX								VARCHAR(500)
	DECLARE @ERROR_SEVERITY_AUX								VARCHAR(500)
	DECLARE @ERROR_STATE_AUX								VARCHAR(500)
	DECLARE @ERROR_PROCEDURE_AUX							VARCHAR(500)
	DECLARE @ERROR_LINE_AUX									VARCHAR(500)
	DECLARE @ERROR_MESSAGE_AUX								VARCHAR(500)
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/	
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY	
	/***************************************************************************************************************************************************************************************
	*	-  VERIFICA SE A TABELA __TB_ARQUIVO_POS EXISTE, SE EXISTIR E FOR COM A DATA DE CRIAÇAO MENOS QUE A DATA ATUAL DELETA A TABELA E CRIA NOVAMENTE.
	***************************************************************************************************************************************************************************************/
		DELETE FROM __TB_ARQUIVO_POS;

		IF (Object_ID('tempDB..##TB_ARQUIVO_BAIXA','U') is not null)BEGIN
			DROP TABLE ##TB_ARQUIVO_BAIXA;
		END;
		CREATE TABLE ##TB_ARQUIVO_BAIXA (
			  ARQUIVO_NS					INT IDENTITY(1, 1)
			 ,ARQUIVO_NM					VARCHAR(MAX)
			 ,ARQUIVO_TAMANHO				BIGINT
			 ,ARQUIVO_DT					DATETIME
			 ,ARQUIVO_TP					VARCHAR(10)
			 ,ARQUIVO_PATHNAME				VARCHAR(MAX)
			 ,ARQUIVO_FLAG					BIGINT DEFAULT 0			 
		);
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
		SET @DATA_PROC = '20230216'
		INSERT INTO @TB_AUX
		SELECT TOP 1
			 DB_PREX.ID_EXECUCAO
			,DB_PREX.ID_CARGA
			,DB_PREX.ID_TAREFA
		FROM 
			TB_PROCESSO_EXECUCAO									DB_PREX
			JOIN [Homolog].[dbo].[TB_TAREFA]					DB_TARE ON DB_PREX.ID_TAREFA = DB_TARE.ID_TAREFA
		WHERE
			DB_PREX.TP_STATUS = 2
			AND NU_RETORNO = 0
			AND TP_ENVIO_EMAIL = 1
			AND 1 = (
				CASE	
					WHEN CHARINDEX('-',DB_TARE.NM_TAREFA ) > 0 AND LTRIM(RTRIM(SUBSTRING (DB_TARE.NM_TAREFA, 1, CHARINDEX('-',DB_TARE.NM_TAREFA ) -1))) = @NM_ORGIEM THEN 1
					ELSE 0
					END	
			)
			AND CONVERT(DATE, DB_PREX.DT_INICIO) = @DATA_PROC;
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 ID_EXECUCAO FROM @TB_AUX))BEGIN	
			SELECT TOP 1 
				@ID_EXECUCAO = ID_EXECUCAO 
				,@ID_CARGA = ID_CARGA
				,@ID_TAREFA = ID_TAREFA
			FROM 
				@TB_AUX;

			EXEC [dbo].[_PROC_ACORDO_BAIXA_POS] @ID_CARGA = @ID_CARGA,@SEQUENCIAL_IN = @SEQUENCIAL, @SEQUENCIAL_OUTPUT = @SEQUENCIAL OUTPUT;
		/***************************************************************************************************************************************************************************************
		*	-  SE SEQUENCIAL = -1; FAZ UPDATE NA TB_PROCESSO_EXECUCAO COM TP_ENVIO_EMAIL = 2;
		***************************************************************************************************************************************************************************************/			
			/*IF(@SEQUENCIAL = -1)BEGIN
				UPDATE TB_PROCESSO_EXECUCAO SET TP_ENVIO_EMAIL = 2 WHERE ID_EXECUCAO = @ID_EXECUCAO
				UPDATE [Homolog].[dbo].[TB_CARGA_DIVIDA] SET TP_STATUS = 2 WHERE ID_CARGA = @ID_CARGA
			END;*/
			DELETE FROM @TB_AUX WHERE ID_EXECUCAO = @ID_EXECUCAO
		END;	
	/***************************************************************************************************************************************************************************************
	*	- TOTAL DE REGISTROS PARA GERAR O ARQUIVO DE CANCELAMENTO DE ACORDOS 
	***************************************************************************************************************************************************************************************/
		SELECT
			@ARQ_POS = COUNT(ARQUIVO_POS_NS)
		FROM
			__TB_ARQUIVO_POS
		WHERE
			ARQUIVO_POS_TP_NM NOT IN ('1_HEADER', '3_TRAILLER')

	/***************************************************************************************************************************************************************************************
	*	- VERIFICA SE EXITE REGISTRO PRA GERAR O ARQUIVO DE CANCELAMENTO DE ACORDOS
	***************************************************************************************************************************************************************************************/
		IF(@ARQ_POS > 0) BEGIN
			SELECT TOP 1
				@ARQUIVO_POS_SEQ = ARQUIVO_POS_SEQ
				,@ARQUIVO_POS_NM = ARQUIVO_POS_NM
				,@ARQUIVO_POS_TP_NS = ARQUIVO_POS_TP_NS
			FROM
				__TB_ARQUIVO_POS
			WHERE
				ARQUIVO_POS_TP_FLAG = 0
				AND ARQUIVO_POS_TP_NM = '1_HEADER'
			ORDER BY
				ARQUIVO_POS_SEQ;
		END; 
	/***************************************************************************************************************************************************************************************
	*	- GERA O ARQUIVO POSICIONAL, REMOVE A ULTIMA LINHA EM BRANCO E MOVE PARA A PASTA DE IMPORTAÇÃO.
	***************************************************************************************************************************************************************************************/
		IF((@ARQUIVO_POS_SEQ > 0) AND (LEN(LTRIM(RTRIM(@ARQUIVO_POS_NM))) > 0) AND (@ARQUIVO_POS_TP_NS > 0))BEGIN

			/*SET @DIRETORIO_BCP = @PATHNAME + '\' + @ARQUIVO_POS_NM;
			SET @DIRETORIO_BCP_log = @PATHNAME + '\# Importacao\Log\' + @ARQUIVO_POS_NM;
	
			SET @EXEC_SQL  = ' SELECT ';
			SET @EXEC_SQL += '	ARQUIVO_POS_REG ';
			SET @EXEC_SQL += ' FROM ';
			SET @EXEC_SQL += '	[Homolog].[dbo].[__TB_ARQUIVO_POS] ';
			SET @EXEC_SQL += ' WHERE ';
			SET @EXEC_SQL += '	ARQUIVO_POS_SEQ = ' + CONVERT(VARCHAR(20), @ARQUIVO_POS_SEQ);
			SET @EXEC_SQL += '	AND ARQUIVO_POS_NM = ''' + CONVERT(VARCHAR(150), @ARQUIVO_POS_NM) + '''' ;
			SET @EXEC_SQL += '	AND ARQUIVO_POS_TP_NS = ' + CONVERT(VARCHAR(20), @ARQUIVO_POS_TP_NS);
			SET @EXEC_SQL += '	AND ARQUIVO_POS_TP_FLAG = 0';
			SET @EXEC_SQL += ' ORDER BY ';
			SET @EXEC_SQL += '	ARQUIVO_POS_NS ';*/

			--EXEC [dbo].[__EXEC_BCP] @SQL_CONSULTA = @EXEC_SQL, @DIRETORIO = @DIRETORIO_BCP, @DIRETORIO_LOG = @DIRETORIO_BCP_log, @DELIMITADOR ='|', @ARQ_TIPO = 'txt';
		/***************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			/*SET @POWERSHELL_TEXT  = N' $content = [System.IO.File]::ReadAllText("' + @PATHNAME + '\' + @ARQUIVO_POS_NM + '.txt"); ';
			SET @POWERSHELL_TEXT += N' $content = $content.Trim(); ';			
			SET @POWERSHELL_TEXT += N' [System.IO.File]::WriteAllText("' + @PATHNAME + '\' + @ARQUIVO_POS_NM + '.txt", $content) ';

			EXEC [dbo].[__FILE_SYSTEM] @STRING = @POWERSHELL_TEXT, @PATH = 'D:\Homolog\arquivos\# Acordos_Baixas\# Arq_PoweShell', @FILE_NAME = N'Remove_linha.ps1'

			--EXEC master..xp_cmdshell 'powershell.exe -File "D:\Homolog\arquivos\# Acordos_Baixas\# Arq_PoweShell\Remove_linha.ps1"';
		/***************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/*/
			SELECT *  FROM [Homolog].[dbo].[__TB_ARQUIVO_POS]

			SET @BODY_CABECALHO_HTML += N'<H2 style="text-align:center;width: 1400px;"> Resumo da importação.</H2>';


			INSERT INTO  TB_EMAIL_ENVIO(
				EMAIL_ENVIO_PROFILE_NAME
				,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
				,EMAIL_ENVIO_SUBJECT
				,EMAIL_ENVIO_BODY
				,EMAIL_ENVIO_BODY_FORMAT
				,EMAIL_ENVIO_IMPORTANCE
			)
			SELECT
				'EmailHomolog'				
				,'anderson.andrade@Homolog.com.br;'
				,'Arquivo Posicional: ' + @ARQUIVO_POS_NM
				,@BODY_ENVIO_HTML
				,'HTML'
				,'High'
		END;
	END TRY 
	BEGIN CATCH  		
		SELECT 
			@ERROR_NUMBER_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_NUMBER()), '')
			,@ERROR_SEVERITY_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_SEVERITY()), '')
			,@ERROR_STATE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_STATE()), '')
			,@ERROR_PROCEDURE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_PROCEDURE()), '')
			,@ERROR_LINE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_LINE()), '')
			,@ERROR_MESSAGE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_MESSAGE()), '');	

		SELECT @ERROR_NUMBER_AUX, @ERROR_SEVERITY_AUX ,@ERROR_STATE_AUX ,@ERROR_PROCEDURE_AUX ,@ERROR_LINE_AUX ,@ERROR_MESSAGE_AUX 
		/*EXEC [dbo].[__PROC_SQL_ERROR_EMAIL]
			@ERROR_NUMBER = @ERROR_NUMBER_AUX
			,@ERROR_SEVERITY = @ERROR_SEVERITY_AUX
			,@ERROR_STATE = @ERROR_STATE_AUX
			,@ERROR_PROCEDURE = @ERROR_PROCEDURE_AUX
			,@ERROR_LINE = @ERROR_LINE_AUX
			,@ERROR_MESSAGE = @ERROR_MESSAGE_AUX;
		EXEC [dbo].[_PROC_ENVIO_EMAIL];		*/	
	END CATCH; 
END;