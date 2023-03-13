USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_MOVE_ARQUIVO', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_MOVE_ARQUIVO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_MOVE_ARQUIVO
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 29/12/2022
	*	DATA.....................: 04/01/2023
	*	DESCRIÇÃO................: Procedure para mover os arquivos de carga para as pastas do Homolog.
	***************************************************************************************************************************************************************************************/
	DECLARE @TB_DIRETORIO										TABLE(
																	DIRETORIO_NS					BIGINT
																	,DIRETORIO_NM					VARCHAR(250)
																	,DIRETORIO_DS					VARCHAR(1000)
																	,DIRETORIO_ORIGEM				VARCHAR(MAX)
																	,DIRETORIO_DESTINIO				VARCHAR(MAX)
																	,DIRETORIO_PROCESSADO			VARCHAR(MAX)	
																	,DIRETORIO_TP_ARQ				VARCHAR(200)
																	,DIRETORIO_ID_TAREFA			BIGINT
																);	
	DECLARE @RET_ARQ											TABLE(
																	RET_ARQ							VARCHAR(MAX)
																);
	DECLARE @TB_EMAIL											TABLE(
																	DIRETORIO_NM					VARCHAR(250)
																	,ARQUIVO_NS						BIGINT
																	,ARQUIVO_NM						VARCHAR(MAX)
																	,ARQUIVO_DT						DATETIME
																	,ARQUIVO_FLAG					BIGINT
																);
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @DIRETORIO_NS										BIGINT
	DECLARE @DIRETORIO_NM										VARCHAR(250)
	DECLARE @DIRETORIO_DS										VARCHAR(1000)
	DECLARE @DIRETORIO_ORIGEM									VARCHAR(MAX)
	DECLARE @DIRETORIO_DESTINIO									VARCHAR(MAX)
	DECLARE @DIRETORIO_PROCESSADO								VARCHAR(MAX)	
	DECLARE @DIRETORIO_TP_ARQ									VARCHAR(200)
	DECLARE @DIRETORIO_ID_TAREFA								BIGINT;	
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ARQUIVO_NS											BIGINT;
	DECLARE @ARQUIVO_NS_AUX										BIGINT;
	DECLARE @ARQUIVO_NOME										VARCHAR(MAX);
	DECLARE @ARQUIVO_NOME_AUX									VARCHAR(MAX);
	DECLARE @ARQ_NOME_AUX										VARCHAR(500) = '';
	DECLARE @ARQUIVO_TP											VARCHAR(MAX);
	DECLARE @ARQUIVO_DT											DATETIME;
	DECLARE @ARQUIVO_TAMANHO									BIGINT;
	DECLARE @COUNT												BIGINT;
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/	
	DECLARE @TP_STATUS											BIGINT;
	DECLARE @NU_RETORNO											BIGINT;
	DECLARE @ID_CARGA											BIGINT;
	DECLARE @TP_ENVIO_EMAIL										BIGINT;
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @TP_HABILITADO										BIGINT;
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
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
	DECLARE @AVISO												VARCHAR(MAX) = '';
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
	/**************************************************************************************************************************************************************************************/
		IF (Object_ID('tempDB..##TB_ARQUIVO_SEMPARAR','U') is not null)BEGIN
			DROP TABLE ##TB_ARQUIVO_SEMPARAR;
		END;
		CREATE TABLE ##TB_ARQUIVO_SEMPARAR (
			  ARQUIVO_NS					INT IDENTITY(1, 1)
			 ,ARQUIVO_NM					VARCHAR(MAX)
			 ,ARQUIVO_TAMANHO				BIGINT
			 ,ARQUIVO_DT					DATETIME
			 ,ARQUIVO_TP					VARCHAR(10)
			 ,ARQUIVO_PATHNAME				VARCHAR(MAX)
			 ,ARQUIVO_FLAG					BIGINT DEFAULT 0			 
		);	
	/***************************************************************************************************************************************************************************************
	*	- RECUPERA INFORMAÇÕES DA TABELA DIRETORIO
	***************************************************************************************************************************************************************************************/
		INSERT INTO @TB_DIRETORIO		
		SELECT
			DB_DIRE.DIRETORIO_NS
			,DB_DIRE.DIRETORIO_NM
			,DB_DIRE.DIRETORIO_DS
			,DB_DIRE.DIRETORIO_ORIGEM
			,DB_DIRE.DIRETORIO_DESTINIO
			,DB_DIRE.DIRETORIO_PROCESSADO
			,DB_DIRE.DIRETORIO_TP_ARQ
			,DB_DIRE.DIRETORIO_ID_TAREFA
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
			DB_DIRE.DIRETORIO_NS;		
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 DIRETORIO_NS FROM @TB_DIRETORIO))BEGIN
			SELECT TOP 1 
				@DIRETORIO_NS = DIRETORIO_NS 
				,@DIRETORIO_NM = DIRETORIO_NM
				,@DIRETORIO_DS = DIRETORIO_DS
				,@DIRETORIO_ORIGEM = DIRETORIO_ORIGEM
				,@DIRETORIO_DESTINIO = DIRETORIO_DESTINIO 
				,@DIRETORIO_PROCESSADO = DIRETORIO_PROCESSADO
				,@DIRETORIO_TP_ARQ = DIRETORIO_TP_ARQ
				,@DIRETORIO_ID_TAREFA = DIRETORIO_ID_TAREFA
			FROM 
				@TB_DIRETORIO;
		/***************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/				
			DELETE FROM ##TB_ARQUIVO_IMP;
			EXEC [__PROC_CMDSHELL] @PATHNAME_CMDSHELL = @DIRETORIO_ORIGEM, @TABELA_NOME = '##TB_ARQUIVO_IMP';

			WHILE(EXISTS(SELECT TOP 1 ARQUIVO_NS FROM ##TB_ARQUIVO_IMP))BEGIN
				SELECT TOP 1 @ARQUIVO_NS = ARQUIVO_NS FROM ##TB_ARQUIVO_IMP 
			/***************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				SET @ARQUIVO_NOME = ''
				SET @ARQUIVO_TP = ''
				SET @COUNT = 0;
				SET @SQL_QUERY_DESTINO = '';
				SET @ID_CARGA = 0;
				SET @TP_STATUS = 0;
				SET @NU_RETORNO = 0;
				SET @TP_HABILITADO = -1;
			/***************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				SELECT 
					@ARQUIVO_NOME = ARQUIVO_NM
					,@ARQUIVO_TP = ARQUIVO_TP 
					,@ARQUIVO_DT = ARQUIVO_DT
				FROM 
					##TB_ARQUIVO_IMP						DB_ARQU
				WHERE
					1 = (
						CASE
							WHEN (CHARINDEX('_', @DIRETORIO_TP_ARQ)) > 0 THEN(
																			CASE
																				WHEN (CHARINDEX(REPLACE(@DIRETORIO_TP_ARQ, 'CARGA_', ''), UPPER(DB_ARQU.ARQUIVO_NM))) > 0 THEN 1 
																				WHEN (CHARINDEX('SEMPARAR', UPPER(@DIRETORIO_TP_ARQ))) > 0  THEN 1 
																				ELSE 0
																			END
																		)
							ELSE 1
						END				
					)
					AND ARQUIVO_NS = @ARQUIVO_NS
				ORDER BY
					ARQUIVO_DT;
			/***************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF(LEN(LTRIM(RTRIM(@ARQUIVO_NOME)))> 0) BEGIN
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
					SET @ARQUIVO_NOME_AUX = SUBSTRING(@ARQUIVO_NOME, 1, LEN(LTRIM(RTRIM(@ARQUIVO_NOME))) - CHARINDEX('.', REVERSE(@ARQUIVO_NOME))) 
					SELECT TOP 1
						@ID_CARGA = ISNULL(ID_CARGA, 0)
						,@TP_STATUS = ISNULL(TP_STATUS, 0)
						,@NU_RETORNO = ISNULL(NU_RETORNO, 0)	
						,@TP_ENVIO_EMAIL = ISNULL(TP_ENVIO_EMAIL, 0)
					FROM
						TB_PROCESSO_EXECUCAO
					WHERE
						SUBSTRING(NM_ARQUIVO, 1, LEN(LTRIM(RTRIM(NM_ARQUIVO))) - CHARINDEX('.', REVERSE(NM_ARQUIVO))) = @ARQUIVO_NOME_AUX
						AND CONVERT(DATE, DT_INICIO) = CONVERT(DATE, GETDATE())
						AND TP_ENVIO_EMAIL >= 1
					ORDER BY
						ID_EXECUCAO DESC;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
					
				/***************************************************************************************************************************************************************************************
				*	- SE O ARQUIVO AINDA NAO FOI IMPORTADO
				***************************************************************************************************************************************************************************************/
					IF((@ID_CARGA = 0) AND (@TP_STATUS = 0) AND (@NU_RETORNO = 0)) BEGIN
						DELETE FROM @RET_ARQ;
						--SELECT @DIRETORIO_NM, @ARQUIVO_NOME, @ARQUIVO_TP;

						SET @SQL_QUERY_ARQ_EXIST = 'IF EXIST "';
						SET @SQL_QUERY_ARQ_EXIST += + @DIRETORIO_DESTINIO + '\*.';
						SET @SQL_QUERY_ARQ_EXIST += (CASE WHEN (CHARINDEX('SEMPARAR', UPPER(@DIRETORIO_TP_ARQ))) > 0 THEN 'txt' ELSE @ARQUIVO_TP END) 
						SET @SQL_QUERY_ARQ_EXIST += '" ( echo 1 ) ELSE ( echo 0 )';

						INSERT INTO @RET_ARQ
						EXEC master..xp_cmdshell @command_string = @SQL_QUERY_ARQ_EXIST;
					/***************************************************************************************************************************************************************************************
					*	- 
					***************************************************************************************************************************************************************************************/			
						IF((SELECT TOP 1 CONVERT(BIGINT, RET_ARQ) FROM @RET_ARQ WHERE RET_ARQ IS NOT NULL) = 0)BEGIN
							IF((CHARINDEX('SEMPARAR', UPPER(@DIRETORIO_TP_ARQ))) > 0 AND @ARQUIVO_TP = 'zip')BEGIN

								SET @ARQ_NOME_AUX = @DIRETORIO_ORIGEM + '\' + @ARQUIVO_NOME;

								EXEC [dbo].[__ZIP_ARQUIVO]  @FULLPATHNAME = @DIRETORIO_DESTINIO, @ARQ_NOME = @ARQ_NOME_AUX, @TIPO = 2;

							END ELSE BEGIN
								SET @SQL_QUERY_DESTINO = 'copy /Y "' + @DIRETORIO_ORIGEM + '\' + @ARQUIVO_NOME + '" "' + @DIRETORIO_DESTINIO + '\"';
							END;
							INSERT INTO @TB_EMAIL
							SELECT
								@DIRETORIO_NM
								,@ARQUIVO_NS
								,@ARQUIVO_NOME
								,@ARQUIVO_DT
								,0
							SET @TP_HABILITADO = 1;
						END;
					/***************************************************************************************************************************************************************************************
					*	- 
					***************************************************************************************************************************************************************************************/
						SELECT TOP 1 @ARQUIVO_NS_AUX = ISNULL(ARQUIVO_NS, 0)FROM @TB_EMAIL WHERE DIRETORIO_NM = 'SEMPARAR' AND ARQUIVO_FLAG IN (0, 3);
						IF((CHARINDEX('SEMPARAR', UPPER(@DIRETORIO_TP_ARQ))) > 0 AND @ARQUIVO_NS_AUX > 0) BEGIN
							DELETE FROM ##TB_ARQUIVO_SEMPARAR;
							EXEC [__PROC_CMDSHELL] @PATHNAME_CMDSHELL = @DIRETORIO_DESTINIO, @TABELA_NOME = '##TB_ARQUIVO_SEMPARAR';							

							SELECT @ARQUIVO_TAMANHO = ARQUIVO_TAMANHO FROM ##TB_ARQUIVO_SEMPARAR;	
							SET @TP_HABILITADO = 0;
						/***************************************************************************************************************************************************************************************
						*	- 
						***************************************************************************************************************************************************************************************/
							IF((CHARINDEX('_BATIMENTO', UPPER(@DIRETORIO_TP_ARQ))) = 0 AND @ARQUIVO_TAMANHO < 2000000 ) BEGIN
								SET @TP_HABILITADO = 1;
								UPDATE @TB_EMAIL SET ARQUIVO_FLAG = 1 WHERE ARQUIVO_NS = @ARQUIVO_NS_AUX;
							END;
						/***************************************************************************************************************************************************************************************
						*	- 
						***************************************************************************************************************************************************************************************/
							IF((CHARINDEX('_BATIMENTO', UPPER(@DIRETORIO_TP_ARQ))) > 0 AND @ARQUIVO_TAMANHO > 30000000 ) BEGIN
								SET @TP_HABILITADO = 1;								
								UPDATE @TB_EMAIL SET ARQUIVO_FLAG = 2 WHERE ARQUIVO_NS = @ARQUIVO_NS_AUX;
							END;
						/***************************************************************************************************************************************************************************************
						*	- 
						***************************************************************************************************************************************************************************************/
							IF((CHARINDEX('_BATIMENTO', UPPER(@DIRETORIO_TP_ARQ))) = 0 AND @ARQUIVO_TAMANHO BETWEEN 2000000 AND 30000000) BEGIN							
								UPDATE @TB_EMAIL SET ARQUIVO_FLAG = 3 WHERE ARQUIVO_NS = @ARQUIVO_NS_AUX;
							END;
						END;												--
					END;
				/***************************************************************************************************************************************************************************************
				*	- SE O ARQUIVO AINDA JA FOI IMPORTADO
				***************************************************************************************************************************************************************************************/
					IF((@ID_CARGA > 0) AND (@TP_STATUS = 2) AND (@NU_RETORNO = 0) AND (@TP_ENVIO_EMAIL = 1)) BEGIN
						IF(@DIRETORIO_TP_ARQ = 'POSICIONAL')BEGIN
							SET @SQL_QUERY_DESTINO = 'del /f "' + @DIRETORIO_ORIGEM + '\' + @ARQUIVO_NOME + '" ';
						END ELSE BEGIN						
							SET @SQL_QUERY_DESTINO = 'move /Y "' + @DIRETORIO_ORIGEM + '\' + @ARQUIVO_NOME + '" "' + @DIRETORIO_PROCESSADO + '\"';
						END;
						SET @TP_HABILITADO = 0;
					END;
				END;
			/***************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF(LEN(LTRIM(RTRIM(@SQL_QUERY_DESTINO)))> 0) BEGIN
					EXEC master..xp_cmdshell @command_string = @SQL_QUERY_DESTINO;					
					--select @SQL_QUERY_DESTINO	
				END;
				IF(@TP_HABILITADO >= 0)BEGIN
					UPDATE [Homolog].[dbo].[TB_TAREFA] SET TP_HABILITADO = @TP_HABILITADO WHERE ID_TAREFA = @DIRETORIO_ID_TAREFA;		
				END;
				DELETE FROM ##TB_ARQUIVO_IMP WHERE ARQUIVO_NS = @ARQUIVO_NS;
			END;
		/***************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			DELETE FROM @TB_DIRETORIO WHERE DIRETORIO_NS = @DIRETORIO_NS;
		END;

		IF((SELECT COUNT(@ARQUIVO_NOME) FROM @TB_EMAIL) > 0) BEGIN

			SET @AVISO = '';
			IF((SELECT COUNT(ARQUIVO_NS) FROM @TB_EMAIL WHERE ARQUIVO_FLAG = 2) > 0)BEGIN
				SET @AVISO = N' <H4 style="color:#f5b7b1">ARQUIVO DE BATIMENTO</H4>';
			END;
			IF((SELECT COUNT(ARQUIVO_NS) FROM @TB_EMAIL WHERE ARQUIVO_FLAG = 3) > 0)BEGIN
				SET @AVISO = N' <H4 style="color:#f5b7b1">VERIFICAR SE O ARQUIVO É DE BATIMENTO</H4>';
			END;

			SET @BODY_CORPO_HTML = ''
			SET @BODY_CORPO_HTML += ' <table> ';
			SET @BODY_CORPO_HTML += '     <caption><H3>Arquivo</H3> ' + @AVISO + ' </caption> ';
			SET @BODY_CORPO_HTML += '     <thead> ';
			SET @BODY_CORPO_HTML += '         <tr> ';
			SET @BODY_CORPO_HTML += '             <th>Origem</th> ';
			SET @BODY_CORPO_HTML += '             <th>Nome</th> ';
			SET @BODY_CORPO_HTML += '             <th>Data</th> ';
			SET @BODY_CORPO_HTML += '         </tr> ';
			SET @BODY_CORPO_HTML += '     </thead> ';
			SET @BODY_CORPO_HTML += '     <tbody> ';
			SET @BODY_CORPO_HTML += CAST ( 
											(SELECT
												td = DIRETORIO_NM, '',
												td = ARQUIVO_NM, '',
												td = CONVERT(VARCHAR(8), ARQUIVO_DT, 108) + ' ' + CONVERT(VARCHAR(10), ARQUIVO_DT, 103), ''
											FROM 
												@TB_EMAIL		
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
	END TRY 
	BEGIN CATCH  
		SELECT 
			@ERROR_NUMBER_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_NUMBER()), '')
			,@ERROR_SEVERITY_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_SEVERITY()), '')
			,@ERROR_STATE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_STATE()), '')
			,@ERROR_PROCEDURE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_PROCEDURE()), '')
			,@ERROR_LINE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_LINE()), '')
			,@ERROR_MESSAGE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_MESSAGE()), '');
		
		--SELECT @ERROR_NUMBER_AUX, @ERROR_SEVERITY_AUX ,@ERROR_STATE_AUX ,@ERROR_PROCEDURE_AUX ,@ERROR_LINE_AUX ,@ERROR_MESSAGE_AUX 
	
		EXEC [dbo].[__PROC_SQL_ERROR_EMAIL]
			@ERROR_NUMBER = @ERROR_NUMBER_AUX
			,@ERROR_SEVERITY = @ERROR_SEVERITY_AUX
			,@ERROR_STATE = @ERROR_STATE_AUX
			,@ERROR_PROCEDURE = @ERROR_PROCEDURE_AUX
			,@ERROR_LINE = @ERROR_LINE_AUX
			,@ERROR_MESSAGE = @ERROR_MESSAGE_AUX;

		EXEC [dbo].[_PROC_ENVIO_EMAIL];
	END CATCH; 
END;