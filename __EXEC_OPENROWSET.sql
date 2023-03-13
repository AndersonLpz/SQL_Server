USE [Homolog]
GO

IF OBJECT_ID('dbo.__EXEC_OPENROWSET', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__EXEC_OPENROWSET]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE __EXEC_OPENROWSET(
	 @CONSULTA_SQL										VARCHAR(MAX) = ''
	,@CONSULTA_OPENROWSET								VARCHAR(MAX) = ''
	,@FULLPATHNAME										VARCHAR(MAX) = ''
	,@TIPO												INT = 0
) 
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 30/08/2022
	*	DESCRIÇÃO.: Procedure para executar o OPENROWSET
	***************************************************************************************************************************************************************************************/
	/***************************************************************************************************************************************************************************************
	*	@TIPO.......: 1, PostgreSQL
	*	@TIPO.......: 2, EXCEL
	***************************************************************************************************************************************************************************************/	
	/**************************************************************************************************************************************************************************************/	
	DECLARE @PROVEDOR										VARCHAR(100);	
	DECLARE @DRIVER											VARCHAR(100);	
	DECLARE @STRING_CON										VARCHAR(200);
	/**************************************************************************************************************************************************************************************/
	DECLARE @EXEC_OPENROWSET								VARCHAR(MAX);
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY
		IF(@TIPO = 1)BEGIN
			SET @PROVEDOR = 'MSDASQL';
			SET @DRIVER = 'Driver={PostgreSQL UNICODE}; ';
			SET @STRING_CON = 'Server=192.168.3.9; Port=5432; Database=fastdialer; Uid=postgres; Pwd=postgres;';
		END;
		IF(@TIPO = 2)BEGIN
			SET @PROVEDOR = 'Microsoft.ACE.OLEDB.12.0';
			SET @DRIVER = 'Excel 12.0 Xml; ';
			SET @STRING_CON = 'Database=' + @FULLPATHNAME;
		END;

		IF(@TIPO != 0 AND LEN(LTRIM(RTRIM(@PROVEDOR))) > 0 AND LEN(LTRIM(RTRIM(@DRIVER))) > 0 AND LEN(LTRIM(RTRIM(@STRING_CON))) > 0 AND LEN(LTRIM(RTRIM(@CONSULTA_SQL))) > 0 AND LEN(LTRIM(RTRIM(@CONSULTA_OPENROWSET))) > 0 ) BEGIN

			SET  @EXEC_OPENROWSET  = '''(';
			SET  @EXEC_OPENROWSET += @CONSULTA_SQL
			SET  @EXEC_OPENROWSET += ' FROM'
			SET  @EXEC_OPENROWSET += ' OPENROWSET('''''+ @PROVEDOR + ''''',''''' + @DRIVER + @STRING_CON + ''''', ''''' + @CONSULTA_OPENROWSET + '''''))''';	
			SET @EXEC_OPENROWSET = @CONSULTA_SQL; 
			SET @EXEC_OPENROWSET += 'FROM OPENROWSET(''' + @PROVEDOR + ''',''' + @DRIVER + @STRING_CON + ''', '' ' + @CONSULTA_OPENROWSET + ''')';
			EXEC (@EXEC_OPENROWSET);
		END;

	END TRY 
	BEGIN CATCH  
		SELECT CONVERT(VARCHAR(500), ERROR_NUMBER()) AS 'ErrorNumber';
		SELECT CONVERT(VARCHAR(500), ERROR_SEVERITY()) AS 'ErrorSeverity';
		SELECT CONVERT(VARCHAR(500), ERROR_STATE()) AS 'ErrorState';
		SELECT CONVERT(VARCHAR(500), ERROR_PROCEDURE()) AS 'ErrorProcedure';
		SELECT CONVERT(VARCHAR(500), ERROR_LINE()) AS 'ErrorLine';
		SELECT CONVERT(VARCHAR(500), ERROR_MESSAGE()) AS 'ErrorMessage';
		SELECT @EXEC_OPENROWSET;			
	END CATCH; 
END;