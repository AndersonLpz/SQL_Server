USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_COMPACTA_ARQ', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_COMPACTA_ARQ]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_COMPACTA_ARQ (
    @FULLPATHNAME VARCHAR(500),
    @ARQ_FILTRO VARCHAR(500),
    @SENHA_ARQ VARCHAR(100) = NULL
)
AS 
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 12/08/2022	
	*	DESCRIÇÃO.: Procedure para compactar arquivos
	***************************************************************************************************************************************************************************************/
	DECLARE @CAMINHO_7ZA										VARCHAR(255) = 'C:\Binn\7za.exe';	
    DECLARE @NIVEL_COMPAC										INT = 9;	
    DECLARE @RECURSIVO											BIT = 0;
	DECLARE @EXEC_CMDSHEL										VARCHAR(8000) = '';
	DECLARE @ARQ_COMPACT										VARCHAR(500) = '';
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN
	SET @ARQ_COMPACT = @FULLPATHNAME + REPLACE(@ARQ_FILTRO, 'csv', 'zip');

	SET @EXEC_CMDSHEL = 'call';
	SET @EXEC_CMDSHEL += ' "' + @CAMINHO_7ZA + '" ';
	SET @EXEC_CMDSHEL += 'a -tzip -mx';
	SET @EXEC_CMDSHEL += CAST(@NIVEL_COMPAC AS VARCHAR(2));
	SET @EXEC_CMDSHEL += ' "' + @ARQ_COMPACT + '"';
	SET @EXEC_CMDSHEL += (CASE WHEN @RECURSIVO = 1 THEN ' -r' ELSE '' END);
	SET @EXEC_CMDSHEL += (CASE WHEN NULLIF(LTRIM(RTRIM(@SENHA_ARQ)), '') IS NOT NULL THEN ' -p' + @SENHA_ARQ ELSE '' END) ;
	SET @EXEC_CMDSHEL += ' "' + @FULLPATHNAME + @ARQ_FILTRO + '" -mmt';

	-- PRINT @Comando
    EXEC xp_cmdshell @EXEC_CMDSHEL;

END