USE [Homolog]
GO

IF OBJECT_ID('dbo.PROC_REPLACE_TO_CHAR', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[PROC_REPLACE_TO_CHAR]
GO

/****** Object:  StoredProcedure [dbo].[_PCD_BAIXA_SUP_AC]    Script Date: 31/08/2021 11:08:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PROC_REPLACE_TO_CHAR] (
	 @TEXTO										VARCHAR(MAX) = ''
	,@LEN										INT = 0
	,@TIPO_FUNC									CHAR(3) = 'REP'
	,@LADO										CHAR(1) = 'R'
	,@RETORNO									VARCHAR(MAX) = '' OUTPUT 
) AS 
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 13/10/2021	
	*	DESCRIÇÃO.: Procedure para dar replace na string para o arquivo posicional    1898152

	***************************************************************************************************************************************************************************************/
	DECLARE @SQL_EXEC										NVARCHAR(600);
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN
	SET @SQL_EXEC = '';
	SET @SQL_EXEC += 'SELECT @RETORNO = ';
	SET @SQL_EXEC += ' CONVERT(';
	SET @SQL_EXEC += ' CHAR(' + CONVERT(VARCHAR(10), @LEN) + ')';

	SET @TIPO_FUNC = UPPER(@TIPO_FUNC);
	SET @LADO = UPPER(@LADO);

	IF(@TIPO_FUNC = 'REP')BEGIN
		IF(@LADO = 'R') BEGIN	
			SET @SQL_EXEC += ', REPLICATE(''0'', ' + CONVERT(VARCHAR(10), @LEN) + ' - LEN('''+ @TEXTO + ''')) + ''' + @TEXTO + '''';
		END;
		IF(@LADO = 'L') BEGIN	
			SET @SQL_EXEC += ', '''+ @TEXTO + ''' + REPLICATE(''0'', ' + CONVERT(VARCHAR(10), @LEN) + ' - LEN('''+ @TEXTO + '''))';
		END;
	END;	
	IF(@TIPO_FUNC = 'SPA')BEGIN
		IF(@LADO = 'R') BEGIN	
			SET @SQL_EXEC += ', SPACE(' + CONVERT(VARCHAR(10), @LEN) +  ' - LEN('''+ @TEXTO + '''))+ ''' + @TEXTO + '''';
		END;		
		IF(@LADO = 'L') BEGIN	
			SET @SQL_EXEC += ', ''' + @TEXTO + ''' + SPACE(' + CONVERT(VARCHAR(10), @LEN) +  ' - LEN('''+ @TEXTO + '''))';
		END;
	END;
	SET @SQL_EXEC += ')';

	IF((@TIPO_FUNC != 'REP' AND @TIPO_FUNC != 'SPA') OR @LEN < 1 OR LEN(LTRIM(RTRIM(@TEXTO))) < 1)BEGIN
		SET @SQL_EXEC = '';
	END;

	IF(LEN(LTRIM(RTRIM(@SQL_EXEC))) > 1)BEGIN		
		EXEC sp_executesql @SQL_EXEC,N'@RETORNO VARCHAR(60) OUT',@RETORNO output	
	END;

END