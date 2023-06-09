USE [Homolog]
GO

IF OBJECT_ID('dbo.__EXEC_BCP', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__EXEC_BCP]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[__EXEC_BCP] (
	 @SQL_CONSULTA											VARCHAR(MAX) = ''
	,@DIRETORIO												VARCHAR(MAX) = ''
	,@DIRETORIO_LOG											VARCHAR(MAX) = ''
	,@DELIMITADOR											VARCHAR(MAX) = ''
	,@ARQ_TIPO												VARCHAR(MAX) = 'csv'
) AS 
	/********************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 19/10/2020	
	*	DESCRIÇÃO.: 
	*********************************************************************************************/
	DECLARE @EXEC_BCP										VARCHAR(4000) = '';
	/********************************************************************************************/
BEGIN 	
	BEGIN TRY
		SET @EXEC_BCP  = 'BCP '
		SET @EXEC_BCP += '"' + @SQL_CONSULTA + '"';

		IF(UPPER(@ARQ_TIPO) = 'TXT')BEGIN
			SET @EXEC_BCP += ' QUERYOUT "' + @DIRETORIO  + '.' + @ARQ_TIPO + '"  -o "'+ @DIRETORIO_LOG + '_LOG.log" -c -C 1252 -k -U"Homolog" -P"sql@Homolog@)!(" ';

		END
		ELSE BEGIN
			SET @EXEC_BCP += ' QUERYOUT "' + @DIRETORIO  + '.' + @ARQ_TIPO + '"  -o "'+ @DIRETORIO_LOG + '_LOG.log" -w -t"' + @DELIMITADOR + '" -k -U"Homolog" -P"sql@Homolog@)!(" -C';
		END;
		--select @EXEC_BCP
		EXEC xp_cmdshell @EXEC_BCP;
	END TRY
	BEGIN CATCH
		INSERT INTO __TBRELTEMP(
			TBRELTEMP_NM_PROC
			,TBRELTEMP_VCHAR01
			,TBRELTEMP_VCHAR02
			,TBRELTEMP_VCHAR03
			,TBRELTEMP_VCHAR04
		)VALUES(
			'__EXEC_BCP'
			,'ERRO'
			,CONVERT(VARCHAR(MAX), ERROR_NUMBER())
			,CONVERT(VARCHAR(MAX), ERROR_MESSAGE())
			,@EXEC_BCP
		)

	END CATCH
END;
