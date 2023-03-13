USE [Homolog]
GO

IF OBJECT_ID('dbo.__ZIP_ARQUIVO', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__ZIP_ARQUIVO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE __ZIP_ARQUIVO (
    @FULLPATHNAME					VARCHAR(500) = '',
    @ARQ_NOME						VARCHAR(500) = '',
    @ARQ_FILTRO						VARCHAR(MAX) = '',
    @SENHA_ARQ						VARCHAR(100) = NULL,
	@TIPO							INT = 0
)
AS 
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 12/08/2022		
	*	DATA ATUALIZACAO.........: 14/12/2022	
	*	DESCRIÇÃO................: Procedure para compactar arquivos
	*	@TIPO = 1; Compacta arquivo, @TIPO = 2; descompacta arquivo.
	***************************************************************************************************************************************************************************************/
	DECLARE @CAMINHO_7ZA										VARCHAR(255) = 'C:\Program Files\7-Zip\7z.exe';	
    DECLARE @NIVEL_COMPAC										INT = 9;	
    DECLARE @RECURSIVO											BIT = 0;
	DECLARE @EXEC_CMDSHEL										VARCHAR(8000) = '';
	DECLARE @ARQ_COMPACT										VARCHAR(500) = '';
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
		*	@@ARQ_FILTRO; se informado o mesmo e ira compactar ou descompactar apenas o arquivo informado.
		***************************************************************************************************************************************************************************************/
		IF(@TIPO > 0 AND LEN(LTRIM(RTRIM(@FULLPATHNAME))) > 0) BEGIN
		/***************************************************************************************************************************************************************************************
		*	@TIPO = 1; Compacta arquivo.
		***************************************************************************************************************************************************************************************/
			IF(@TIPO = 1) BEGIN				
				SET @ARQ_COMPACT = (CASE WHEN LEN(LTRIM(RTRIM(@ARQ_FILTRO))) > 0 THEN @FULLPATHNAME + @ARQ_FILTRO ELSE @FULLPATHNAME END);

				SET @EXEC_CMDSHEL = 'call';
				SET @EXEC_CMDSHEL += ' "' + @CAMINHO_7ZA + '" ';
				SET @EXEC_CMDSHEL += 'a -tzip -mx';
				SET @EXEC_CMDSHEL += CAST(@NIVEL_COMPAC AS VARCHAR(2));
				SET @EXEC_CMDSHEL += ' "' + @FULLPATHNAME + @ARQ_NOME + '.zip"';
				SET @EXEC_CMDSHEL += (CASE WHEN @RECURSIVO = 1 THEN ' -r' ELSE '' END);
				SET @EXEC_CMDSHEL += (CASE WHEN NULLIF(LTRIM(RTRIM(@SENHA_ARQ)), '') IS NOT NULL THEN ' -p' + @SENHA_ARQ ELSE '' END) ;
				SET @EXEC_CMDSHEL += ' "' + @ARQ_COMPACT + '" -mmt';
			END;
		/***************************************************************************************************************************************************************************************
		*	@TIPO = 2; Descompacta arquivo.
		***************************************************************************************************************************************************************************************/
			IF(@TIPO = 2) BEGIN

				SET @EXEC_CMDSHEL = 'call';
				SET @EXEC_CMDSHEL += ' "' + @CAMINHO_7ZA + '" ';				
				SET @EXEC_CMDSHEL += 'e';
				SET @EXEC_CMDSHEL += ' "' + @ARQ_NOME + '" ';
				SET @EXEC_CMDSHEL += '-aoa  -r  -o';
				SET @EXEC_CMDSHEL += '"' + @FULLPATHNAME + '" ';
				SET @EXEC_CMDSHEL += ' -mmt ';
			END;

			IF(LEN(LTRIM(RTRIM(@EXEC_CMDSHEL))) > 0)BEGIN
				select @EXEC_CMDSHEL
				EXEC master..xp_cmdshell @EXEC_CMDSHEL;
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
	
		/*EXEC [dbo].[__PROC_SQL_ERROR_EMAIL]
			@ERROR_NUMBER = @ERROR_NUMBER_AUX
			,@ERROR_SEVERITY = @ERROR_SEVERITY_AUX
			,@ERROR_STATE = @ERROR_STATE_AUX
			,@ERROR_PROCEDURE = @ERROR_PROCEDURE_AUX
			,@ERROR_LINE = @ERROR_LINE_AUX
			,@ERROR_MESSAGE = @ERROR_MESSAGE_AUX;
		--EXEC [dbo].[_PROC_ENVIO_EMAIL];*/
	END CATCH; 
END;