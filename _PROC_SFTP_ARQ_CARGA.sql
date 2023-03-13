USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_SFTP_ARQ_CARGA', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_SFTP_ARQ_CARGA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_SFTP_ARQ_CARGA
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 20/10/2022	
	*	DESCRIÇÃO.: Procedure para mover os arquivos de carga do sftp para as pastas do Homolog.
	***************************************************************************************************************************************************************************************/
	DECLARE @TB_DIRETORIO										TABLE(
																	DIRETORIO_NS BIGINT
																	,DIRETORIO_NM VARCHAR(250)
																	,DIRETORIO_ORIGEM VARCHAR(MAX)
																	,DIRETORIO_DESTINIO VARCHAR(MAX)
																	,DIRETORIO_TP_NS BIGINT
																	,DIRETORIO_TP_ARQ  VARCHAR(200)
																);	
	DECLARE @RET_ARQ											TABLE(
																	RET_ARQ VARCHAR(MAX)
																);	
	/**************************************************************************************************************************************************************************************/
	DECLARE @DIRETORIO_NS										BIGINT = 0;
	DECLARE @DIRETORIO_NM										VARCHAR(MAX) = '';
	DECLARE @DIRETORIO_ORIGEM									VARCHAR(MAX) = '';
	DECLARE @DIRETORIO_DESTINIO									VARCHAR(MAX) = '';
	DECLARE @DIRETORIO_TP_ARQ									VARCHAR(200) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @ARQUIVO_NS											BIGINT = 0;
	DECLARE @ARQUIVO_NOME										VARCHAR(MAX);
	DECLARE @ARQUIVO_NOME_AUX									VARCHAR(MAX);
	DECLARE @ARQUIVO_TP											VARCHAR(MAX);	
	DECLARE @ARQUIVO_DT											DATETIME
	DECLARE @FLAG_ARQUIVO_TP									BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_QUERY_DESTINO									NVARCHAR(800);	
	DECLARE @SQL_QUERY_ARQ_EXIST								NVARCHAR(800) = '';	
	/**************************************************************************************************************************************************************************************
	*	- VARIAVEL ENVIO EMAIL
	***************************************************************************************************************************************************************************************/
	DECLARE @SUBJECT											VARCHAR(200) = 'Arquivo para importação';
	DECLARE @BODY_CABECALHO_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @BODY_CORPO_HTML									NVARCHAR(MAX) = '' ;
	DECLARE @BODY_RODAPE_HTML									NVARCHAR(MAX) = '' ;
	DECLARE @BODY_ENVIO_HTML									NVARCHAR(MAX) = '' ;	
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
	*	- CRIA TABELA TEMPORARIA
	***************************************************************************************************************************************************************************************/
		IF (Object_ID('tempDB..##TB_ARQUIVO_IMP','U') is not null)BEGIN
			DROP TABLE ##TB_ARQUIVO_IMP;
		END;
		CREATE TABLE ##TB_ARQUIVO_IMP (
			  ARQUIVO_NS					INT IDENTITY(1, 1)
			 ,ARQUIVO_NM					VARCHAR(MAX)
			 ,ARQUIVO_TAMANHO				BIGINT
			 ,ARQUIVO_DT					DATETIME
			 ,ARQUIVO_TP					VARCHAR(10)
			 ,ARQUIVO_PATHNAME				VARCHAR(MAX)
			 ,ARQUIVO_FLAG					BIGINT DEFAULT 0			 
		);
	/***************************************************************************************************************************************************************************************
	*	Recupera as informações dos diretorios a serem verificados se tem arquivo de carga
	***************************************************************************************************************************************************************************************/
		INSERT INTO @TB_DIRETORIO		
		SELECT
			DB_DIRE.DIRETORIO_NS
			,DB_DIRE.DIRETORIO_NM
			,DB_DIRE.DIRETORIO_ORIGEM
			,DB_DIRE.DIRETORIO_DESTINIO
			,DB_DIRE.DIRETORIO_TP_NS
			,DB_DIRE.DIRETORIO_TP_ARQ
		FROM
			TB_DIRETORIO									DB_DIRE
		WHERE
			1 = (
				CASE
					WHEN DB_DIRE.DIRETORIO_INA IS NULL THEN 1
					WHEN DB_DIRE.DIRETORIO_INA > CONVERT(DATE, GETDATE()) THEN 1
					ELSE 0
					END
			)
		ORDER BY
			DB_DIRE.DIRETORIO_TP_NS, DB_DIRE.DIRETORIO_NM;
	/***************************************************************************************************************************************************************************************
	*	Rortina para validar or dados e mover os aquivos.
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 DIRETORIO_NS FROM @TB_DIRETORIO WHERE DIRETORIO_TP_NS = 1))BEGIN		
			SELECT TOP 1 
				@DIRETORIO_NS = DIRETORIO_NS 
				,@DIRETORIO_ORIGEM = DIRETORIO_ORIGEM
				,@DIRETORIO_DESTINIO = DIRETORIO_DESTINIO
				,@DIRETORIO_TP_ARQ = DIRETORIO_TP_ARQ
			FROM 
				@TB_DIRETORIO 
			WHERE
				DIRETORIO_TP_NS = 1;
		/***************************************************************************************************************************************************************************************
		*	
		***************************************************************************************************************************************************************************************/
			SELECT * FROM @TB_DIRETORIO WHERE DIRETORIO_NS = @DIRETORIO_NS
			SET @ARQUIVO_NOME = '';
			SET @SQL_QUERY_DESTINO = '';
			DELETE FROM ##TB_ARQUIVO_IMP;
			EXEC [__PROC_CMDSHELL] @PATHNAME_CMDSHELL = @DIRETORIO_ORIGEM, @TABELA_NOME = '##TB_ARQUIVO_IMP';

			SELECT 
				 @ARQUIVO_NOME = ARQUIVO_NM
				,@ARQUIVO_TP = ARQUIVO_TP 
			FROM 
				##TB_ARQUIVO_IMP						DB_ARQU
			WHERE
				1 = (
					CASE
						WHEN LEN(LTRIM(RTRIM(@DIRETORIO_TP_ARQ))) > 0 THEN (
																			CASE
																				WHEN (CHARINDEX(@DIRETORIO_TP_ARQ, UPPER(DB_ARQU.ARQUIVO_NM))) > 0 THEN 1
																				ELSE 0
																			END
																		)
						WHEN LEN(LTRIM(RTRIM(@DIRETORIO_TP_ARQ))) = 0 THEN 1
						END				
				);
			IF(LEN(LTRIM(RTRIM(@ARQUIVO_NOME)))> 0) BEGIN
				DELETE FROM @RET_ARQ
				SET @SQL_QUERY_ARQ_EXIST = 'IF EXIST "' + @DIRETORIO_DESTINIO + '\' + @ARQUIVO_NOME + '" ( echo 1 ) ELSE ( echo 0 )';
			
				INSERT INTO @RET_ARQ
				EXEC master..xp_cmdshell @command_string = @SQL_QUERY_ARQ_EXIST;					

				IF((SELECT TOP 1 CONVERT(BIGINT, RET_ARQ) FROM @RET_ARQ WHERE RET_ARQ IS NOT NULL) = 0)BEGIN
					SET @SQL_QUERY_DESTINO = 'copy /Y "' + @DIRETORIO_ORIGEM + '\' + @ARQUIVO_NOME + '" "' + @DIRETORIO_DESTINIO + '\"';
				END;
			END;
			IF(LEN(LTRIM(RTRIM(@SQL_QUERY_DESTINO)))> 0) BEGIN
				EXEC master..xp_cmdshell @command_string = @SQL_QUERY_DESTINO;					
				--select @SQL_QUERY_DESTINO
				SET @FLAG_ARQUIVO_TP = 1;
			END;

			DELETE FROM @TB_DIRETORIO WHERE DIRETORIO_NS = @DIRETORIO_NS;
		END;
	/***************************************************************************************************************************************************************************************
	*	
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 DIRETORIO_NS FROM @TB_DIRETORIO WHERE DIRETORIO_TP_NS = 2))BEGIN		
			SELECT TOP 1 
				@DIRETORIO_NS = DIRETORIO_NS 
				,@DIRETORIO_NM = DIRETORIO_NM
				,@DIRETORIO_ORIGEM = DIRETORIO_ORIGEM
				,@DIRETORIO_DESTINIO = DIRETORIO_DESTINIO
				,@DIRETORIO_TP_ARQ = DIRETORIO_TP_ARQ
			FROM 
				@TB_DIRETORIO 
			WHERE 
				DIRETORIO_TP_NS = 2;	
			SET @FLAG_ARQUIVO_TP = 0;
		/***************************************************************************************************************************************************************************************
		*	
		***************************************************************************************************************************************************************************************/				
			SELECT * FROM @TB_DIRETORIO WHERE DIRETORIO_NS = @DIRETORIO_NS
			SET @ARQUIVO_NOME = '';
			SET @SQL_QUERY_DESTINO = '';
			SET @ARQUIVO_DT = '';
			DELETE FROM ##TB_ARQUIVO_IMP;
			EXEC [__PROC_CMDSHELL] @PATHNAME_CMDSHELL = @DIRETORIO_ORIGEM, @TABELA_NOME = '##TB_ARQUIVO_IMP';

			SELECT 
				 @ARQUIVO_NOME = ARQUIVO_NM
				,@ARQUIVO_TP = ARQUIVO_TP 
				,@ARQUIVO_DT = ARQUIVO_DT
			FROM 
				##TB_ARQUIVO_IMP						DB_ARQU
			WHERE
				1 = (
					CASE
						WHEN LEN(LTRIM(RTRIM(@DIRETORIO_TP_ARQ))) > 0 THEN (
																			CASE
																				WHEN (CHARINDEX(@DIRETORIO_TP_ARQ, UPPER(DB_ARQU.ARQUIVO_NM))) > 0 THEN 1
																				ELSE 0
																			END
																		)
						WHEN LEN(LTRIM(RTRIM(@DIRETORIO_TP_ARQ))) = 0  THEN 1
						END				
				);
				IF(LEN(LTRIM(RTRIM(@ARQUIVO_NOME)))> 0) BEGIN
					SET @SQL_QUERY_DESTINO = 'move /Y "' + @DIRETORIO_ORIGEM + '\' + @ARQUIVO_NOME + '" "' + @DIRETORIO_DESTINIO + '\"';
				END;

			IF(LEN(LTRIM(RTRIM(@SQL_QUERY_DESTINO)))> 0) BEGIN
				EXEC master..xp_cmdshell @command_string = @SQL_QUERY_DESTINO;					
				--select @SQL_QUERY_DESTINO
				SET @FLAG_ARQUIVO_TP = 1;
			END;

		/***************************************************************************************************************************************************************************************
		*	
		***************************************************************************************************************************************************************************************/
			UPDATE 
				@TB_DIRETORIO  
			SET 
				DIRETORIO_TP_NS = @FLAG_ARQUIVO_TP
				, DIRETORIO_ORIGEM = @ARQUIVO_NOME
				, DIRETORIO_DESTINIO = CONVERT(VARCHAR(8),@ARQUIVO_DT, 108) + ' ' + CONVERT(VARCHAR(10), @ARQUIVO_DT, 103)
			WHERE 
				DIRETORIO_NS = @DIRETORIO_NS;
		END;	
		
		IF ((SELECT COUNT(DIRETORIO_NS) FROM @TB_DIRETORIO WHERE DIRETORIO_TP_NS = 1) > 0) BEGIN

			SET @BODY_CORPO_HTML = ''
			SET @BODY_CORPO_HTML += ' <table> ';
			SET @BODY_CORPO_HTML += '     <caption><H3>Arquivo</H3></caption> ';
			SET @BODY_CORPO_HTML += '     <thead> ';
			SET @BODY_CORPO_HTML += '         <tr> ';
			SET @BODY_CORPO_HTML += '             <th>Arquivo</th> ';
			SET @BODY_CORPO_HTML += '             <th>Tipo</th> ';
			SET @BODY_CORPO_HTML += '             <th>Data</th> ';
			SET @BODY_CORPO_HTML += '         </tr> ';
			SET @BODY_CORPO_HTML += '     </thead> ';
			SET @BODY_CORPO_HTML += '     <tbody> ';
			SET @BODY_CORPO_HTML += CAST ( 
											(SELECT
												td = DIRETORIO_ORIGEM, '',
												td = DIRETORIO_NM, '',
												td = DIRETORIO_DESTINIO, ''
											FROM 
												@TB_DIRETORIO 
											WHERE 
												DIRETORIO_TP_NS = 1			
											FOR XML PATH('tr'), TYPE   
											) AS NVARCHAR(MAX) 
			);		
			SET @BODY_CORPO_HTML += '     </tbody> ';
			SET @BODY_CORPO_HTML += ' </table> ';
			SET @BODY_CORPO_HTML += ' <br/><br/> ';		
		
			IF(LEN(LTRIM(RTRIM(@BODY_CORPO_HTML))) > 0) BEGIN
				SET @BODY_ENVIO_HTML =  @BODY_CABECALHO_HTML + @BODY_CORPO_HTML ;			
			END;
			IF(LEN(LTRIM(RTRIM(@BODY_ENVIO_HTML))) > 0) BEGIN
			
				INSERT INTO  TB_EMAIL_ENVIO(
					EMAIL_ENVIO_PROFILE_NAME
					,EMAIL_ENVIO_RECIPIENTES
					,EMAIL_ENVIO_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
				)
				SELECT
					'EmailHomolog'
					,'suporte@Homolog.com.br'
					,'wanderlei.silva@Homolog.com.br;anderson.andrade@Homolog.com.br;'
					--,'anderson.andrade@Homolog.com.br;'
					,@SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High'
			END;
		END;

		EXEC [dbo].[_PROC_ENVIO_EMAIL];
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

		EXEC [dbo].[_PROC_ENVIO_EMAIL];*/
	END CATCH; 
END;