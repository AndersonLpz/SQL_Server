USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_PROCESSO_EXECUCAO', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_PROCESSO_EXECUCAO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_PROCESSO_EXECUCAO
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 28/10/2022	
	*	DESCRIÇÃO................: Procedure para mover os arquivos de carga do sftp para as pastas do Homolog.
	***************************************************************************************************************************************************************************************/
	DECLARE @DATA_ATUAL										DATE = GETDATE();
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @TB_AUX									TABLE(
																ID_EXECUCAO					BIGINT
																,NM_EXECUCAO_GRUPO			VARCHAR(50)
																,TP_STATUS					BIGINT
																,TP_EXECUCAO				BIGINT
																,DT_INICIO					DATETIME
																,DT_FIM						DATETIME
																,NU_RETORNO					BIGINT
																,DS_RETORNO					VARCHAR(4000)
																,DS_STATUS					VARCHAR(MAX)
																,DS_LOG						VARCHAR(MAX)
																,ID_USUARIO					BIGINT
																,ID_PROCESSO				BIGINT
																,NM_PROCESSO				VARCHAR(50)
																,ID_TAREFA					BIGINT
															);
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @NM_EXECUCAO_GRUPO								VARCHAR(50);
	DECLARE @ID_EXECUCAO									BIGINT;
	DECLARE @TP_STATUS										BIGINT;
	DECLARE @TP_EXECUCAO									BIGINT;
	DECLARE @NU_RETORNO										BIGINT;
	DECLARE @DS_RETORNO										VARCHAR(4000);
	DECLARE @DS_STATUS										VARCHAR(MAX);
	DECLARE @DS_LOG											VARCHAR(MAX);
	DECLARE @NM_PROCESSO									VARCHAR(50);
	DECLARE @ID_USUARIO										BIGINT;
	DECLARE @ID_PROCESSO									BIGINT;
	DECLARE @ID_TAREFA										BIGINT;	
	DECLARE @DT_INICIO										DATETIME;
	DECLARE @DT_FIM											DATETIME;
	DECLARE @DT_INICIO_AUX									DATETIME;
	DECLARE @DT_FIM_AUX										DATETIME;
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ID_CARGA										BIGINT;
	
	DECLARE @DS_STATUS_PROCESSADO							VARCHAR(MAX);
	DECLARE @DS_STATUS_PROCESSADO_AUX						VARCHAR(MAX);
	DECLARE @NM_ARQUIVO										VARCHAR(500);
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ERROR_NUMBER_AUX								VARCHAR(500);
	DECLARE @ERROR_SEVERITY_AUX								VARCHAR(500);
	DECLARE @ERROR_STATE_AUX								VARCHAR(500);
	DECLARE @ERROR_PROCEDURE_AUX							VARCHAR(500);
	DECLARE @ERROR_LINE_AUX									VARCHAR(500);
	DECLARE @ERROR_MESSAGE_AUX								VARCHAR(500);
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY
		--SET @DATA_ATUAL = '20221228'
		--DELETE FROM [Homolog].[dbo].TB_PROCESSO_EXECUCAO
		--DBCC CHECKIDENT (TB_PROCESSO_EXECUCAO, RESEED, 0)
	/***************************************************************************************************************************************************************************************
	*	- CRIA TABELA TEMPORARIA
	***************************************************************************************************************************************************************************************/
		INSERT INTO @TB_AUX
		SELECT 
			DB_PREX.ID_EXECUCAO
			,DB_PREX.NM_EXECUCAO_GRUPO
			,DB_PREX.TP_STATUS
			,DB_PREX.TP_EXECUCAO
			,DB_PREX.DT_INICIO
			,DB_PREX.DT_FIM
			,DB_PREX.NU_RETORNO
			,DB_PREX.DS_RETORNO
			,DB_PREX.DS_STATUS
			,DB_PREX.DS_LOG
			,ISNULL(DB_PREX.ID_USUARIO, 0 ) AS 'ID_USUARIO'
			,DB_PROC.ID_PROCESSO
			,DB_PROC.NM_PROCESSO 
			,DB_TARE.ID_TAREFA
		FROM 
			[Homolog].[dbo].[TB_PROCESSO_EXECUCAO]							DB_PREX
			LEFT JOIN [Homolog].[dbo].[TB_PROCESSO]								DB_PROC ON DB_PREX.ID_PROCESSO = DB_PROC.ID_PROCESSO
			LEFT JOIN [Homolog].[dbo].[TB_TAREFA]									DB_TARE ON DB_PROC.ID_TAREFA = DB_TARE.ID_TAREFA		
		WHERE
			DB_PROC.NM_PROCESSO IN ('CARGA EXECUCAO', 'CARREGAR TEMPORARIAS', 'CARGA PADRAO')
			AND CONVERT(DATE, DB_PREX.DT_INICIO) = @DATA_ATUAL
			AND DB_PREX.DT_FIM IS NOT NULL
			AND NM_EXECUCAO_GRUPO NOT IN (
				SELECT	
					DB_PREX_1.NM_EXECUCAO_GRUPO
				FROM
					[Homolog].[dbo].[TB_PROCESSO_EXECUCAO] DB_PREX_1
				WHERE
					DB_PREX_1.NM_EXECUCAO_GRUPO = DB_PREX.NM_EXECUCAO_GRUPO
					AND CONVERT(DATE, DB_PREX_1.DT_INICIO) = @DATA_ATUAL 			
			)
		ORDER BY 
			DB_PREX.[ID_EXECUCAO] DESC;
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/		
		WHILE(EXISTS(SELECT TOP 1 ID_EXECUCAO FROM @TB_AUX))BEGIN
			SELECT TOP 1 @NM_EXECUCAO_GRUPO = NM_EXECUCAO_GRUPO FROM @TB_AUX ORDER BY ID_EXECUCAO;
		/***************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			SET @ID_CARGA = 0;
			SET @DS_STATUS_PROCESSADO_AUX = '';
			SET @DT_INICIO = '';
			SET @DT_FIM	= '';
			--SELECT * FROM @TB_AUX WHERE NM_EXECUCAO_GRUPO = @NM_EXECUCAO_GRUPO
			--SELECT '=============================='
		/***************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			WHILE(EXISTS(SELECT TOP 1 ID_EXECUCAO FROM @TB_AUX WHERE NM_EXECUCAO_GRUPO = @NM_EXECUCAO_GRUPO))BEGIN
				SELECT TOP 1 
					@ID_EXECUCAO = ID_EXECUCAO
					,@TP_STATUS = TP_STATUS
					,@TP_EXECUCAO =  TP_EXECUCAO
					,@NU_RETORNO = NU_RETORNO
					,@DS_RETORNO = DS_RETORNO
					,@DS_STATUS = DS_STATUS
					,@DS_LOG = ISNULL(DS_LOG, '')
					,@NM_PROCESSO = NM_PROCESSO
					,@ID_USUARIO = ID_USUARIO
					,@ID_PROCESSO = ID_PROCESSO
					,@ID_TAREFA = ID_TAREFA
					,@DT_INICIO_AUX = DT_INICIO
					,@DT_FIM_AUX = DT_FIM
				FROM 
					@TB_AUX 
				WHERE 
					NM_EXECUCAO_GRUPO = @NM_EXECUCAO_GRUPO 
				ORDER BY 
					ID_EXECUCAO;					
			/***************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF(@ID_CARGA = 0)BEGIN
					SELECT TOP 1
						@ID_CARGA = ISNULL(DB_CARG.ID_CARGA, 0)
						,@NM_ARQUIVO = DB_CARG.NM_ARQUIVO						
					FROM
						[Homolog].[dbo].[TB_CARGA]						DB_CARG
					WHERE
						1 = (
							CASE
								WHEN (CHARINDEX(UPPER(DB_CARG.NM_ARQUIVO), UPPER(@DS_STATUS)))> 0 THEN  (
																									CASE
																										WHEN @NM_PROCESSO = 'CARREGAR TEMPORARIAS' THEN 1
																										WHEN @NM_PROCESSO = 'CARGA PADRAO' AND @ID_CARGA = 0 THEN 1
																										WHEN @NM_PROCESSO = 'CARGA EXECUCAO' AND @ID_CARGA = 0 THEN 1
																									END						
																								)
								ELSE 0
							END
						)						 
					ORDER BY
						DB_CARG.DT_INICIO DESC;
						
			--SELECT '=============================='
				END;

				IF(@NM_PROCESSO = 'CARREGAR TEMPORARIAS') BEGIN
					IF(@NU_RETORNO !=0)BEGIN
						SET @DS_STATUS_PROCESSADO_AUX = (
							CASE
								WHEN @DS_RETORNO IS NOT NULL THEN @DS_RETORNO
								ELSE @DS_LOG
								END					
						)
					END;

					SET @DT_INICIO = @DT_INICIO_AUX;
					SET @DT_FIM = @DT_FIM_AUX;

				END;

				IF(@NM_PROCESSO = 'CARGA PADRAO') BEGIN
					IF(@NU_RETORNO !=0)BEGIN
						SET @DS_STATUS_PROCESSADO_AUX = @DS_RETORNO;
					END;
					IF(@DT_INICIO = '1900-01-01 00:00:00')BEGIN
						SET @DT_INICIO = @DT_INICIO_AUX;
					END;
					IF(@DT_FIM = '1900-01-01 00:00:00')BEGIN
						SET @DT_FIM = @DT_FIM_AUX;
					END;
				END;

				IF(@NM_PROCESSO = 'CARGA EXECUCAO') BEGIN
					IF(@DT_INICIO = '1900-01-01 00:00:00')BEGIN
						SET @DT_INICIO = @DT_INICIO_AUX;
					END;

					SET @DT_FIM = @DT_FIM_AUX;

				END;

				DELETE FROM @TB_AUX WHERE ID_EXECUCAO = @ID_EXECUCAO;

				IF((SELECT COUNT(ID_EXECUCAO) FROM @TB_AUX WHERE NM_EXECUCAO_GRUPO = @NM_EXECUCAO_GRUPO) = 0) BEGIN
				
					SET @DS_STATUS_PROCESSADO = (
						CASE
							WHEN @DS_RETORNO IS NOT NULL THEN @DS_RETORNO
							ELSE  @DS_STATUS + ' ' + @DS_STATUS_PROCESSADO_AUX
						END				
					);

					INSERT INTO  [Homolog].[dbo].[TB_PROCESSO_EXECUCAO](
						ID_EXECUCAO
						,NM_EXECUCAO_GRUPO
						,ID_CARGA
						,ID_USUARIO
						,ID_PROCESSO
						,ID_TAREFA
						,DT_INICIO
						,DT_FIM
						,TP_STATUS
						,TP_EXECUCAO
						,NU_RETORNO
						,DS_STATUS_PROCESSADO
						,DS_LOG
						,NM_ARQUIVO
					)
					SELECT 
						@ID_EXECUCAO					AS '@ID_EXECUCAO'
						,@NM_EXECUCAO_GRUPO				AS '@NM_EXECUCAO_GRUPO'
						,@ID_CARGA						AS '@ID_CARGA'
						,@ID_USUARIO					AS '@ID_USUARIO'
						,@ID_PROCESSO					AS '@ID_PROCESSO'
						,@ID_TAREFA						AS '@ID_TAREFA'
						,@DT_INICIO						AS '@DT_INICIO'
						,@DT_FIM						AS '@DT_FIM'
						,@TP_STATUS						AS '@TP_STATUS'
						,@TP_EXECUCAO					AS '@TP_EXECUCAO'
						,@NU_RETORNO					AS '@NU_RETORNO'
						,@DS_STATUS_PROCESSADO			AS '@DS_STATUS_PROCESSADO'
						,@DS_LOG						AS '@DS_LOG'
						,ISNULL(@NM_ARQUIVO, '')		AS '@NM_ARQUIVO'
						
					--SELECT '==============================';
				END;
			END;
			DELETE FROM @TB_AUX WHERE NM_EXECUCAO_GRUPO = @NM_EXECUCAO_GRUPO;
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

		EXEC [dbo].[_PROC_ENVIO_EMAIL];*/
	END CATCH; 
END;