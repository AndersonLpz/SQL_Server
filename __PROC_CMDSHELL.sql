USE [Homolog]
GO
--Exclui procedure
IF OBJECT_ID('dbo.__PROC_CMDSHELL', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__PROC_CMDSHELL]
GO
/****** Object:  StoredProcedure [dbo].[__EXEC_BCP]    Script Date: 03/09/2021 13:13:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[__PROC_CMDSHELL] (
	 @PATHNAME_CMDSHELL											VARCHAR(MAX) = ''
	 ,@TABELA_NOME												VARCHAR(MAX) = ''
) AS 
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 08/11/2022
	*	DESCRIÇÃO.: Procedure para Reronar os arquivos contido em um diretorio.
	***************************************************************************************************************************************************************************************/	
	DECLARE @ERROR_MESSAGE										VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @TB_CMD												TABLE(NS_CMD INT IDENTITY(1, 1), DS_CMD VARCHAR(MAX));	
	DECLARE @TB_ARQUIVO											TABLE(
																	ARQUIVO_NS INT IDENTITY(1, 1),
																	ARQUIVO_NM VARCHAR(MAX),
																	ARQUIVO_TAMANHO BIGINT,
																	ARQUIVO_DT DATETIME,
																	ARQUIVO_TP VARCHAR(10),
																	ARQUIVO_PATHNAME VARCHAR(MAX)
																);
	DECLARE @DS_CMD												VARCHAR(MAX);
	DECLARE @FLAG_ARQ											INT = 0;
	DECLARE @EXEC_CMDSHELL										VARCHAR(4000) = '';
	DECLARE @EXEC												VARCHAR(4000) = '';
	DECLARE @ARQUIVO_NS											BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY
		IF(LEN(LTRIM(RTRIM(@PATHNAME_CMDSHELL))) > 0)BEGIN
			DELETE FROM [Homolog].[dbo].[__TBCMDDIR_TEMP] WHERE TBCMDDIR_TEMP_PATHNAME = @PATHNAME_CMDSHELL;
			SET @EXEC_CMDSHELL = 'dir/ -C /4 /N "' + @PATHNAME_CMDSHELL + '"';

 			INSERT INTO @TB_CMD	EXEC master.dbo.xp_cmdshell @command_string = @EXEC_CMDSHELL; 		
	
			SELECT @DS_CMD = LTRIM(RTRIM(DS_CMD)) FROM @TB_CMD WHERE UPPER(DS_CMD) LIKE '%ARQUIVO(S)%';	
			SELECT @FLAG_ARQ = CONVERT(INT, LTRIM(RTRIM(SUBSTRING(@DS_CMD, 1, CHARINDEX('ARQUIVO(S)', UPPER(@DS_CMD)) -1))));

			IF(@FLAG_ARQ > 0) BEGIN
				INSERT INTO @TB_ARQUIVO(ARQUIVO_NM, ARQUIVO_TAMANHO, ARQUIVO_DT, ARQUIVO_TP, ARQUIVO_PATHNAME)
				SELECT 
					SUBSTRING(DS_CMD, CHARINDEX(LTRIM(SUBSTRING(LTRIM(DS_CMD), 18, 19)), DS_CMD, 18) + LEN(LTRIM(SUBSTRING(LTRIM(DS_CMD), 18, 19))) + 1, LEN(DS_CMD)) AS 'ARQUIVO_NM'
					,LTRIM(SUBSTRING(LTRIM(DS_CMD), 18, 19)) AS 'ARQUIVO_TAMANHO'
					,CONVERT(DATETIME, LEFT(DS_CMD, 17), 103) AS 'ARQUIVO_DT'
					,(
						CASE
							WHEN CHARINDEX('.txt', DS_CMD) > 0 THEN 'txt'
							WHEN CHARINDEX('.xlsx', DS_CMD) > 0 THEN 'xlsx'
							WHEN CHARINDEX('.csv', DS_CMD) > 0 THEN 'csv'
							WHEN CHARINDEX('.zip', DS_CMD) > 0 THEN 'zip'
							WHEN CHARINDEX('.log', DS_CMD) > 0 THEN 'log'
							ELSE NULL
						END
					) AS 'ARQUIVO_TP'
					,@PATHNAME_CMDSHELL
				FROM 
					@TB_CMD
				WHERE 
					DS_CMD IS NOT NULL
					AND NS_CMD >= 6
					AND NS_CMD < (SELECT MAX(NS_CMD) FROM @TB_CMD) - 2
					AND DS_CMD NOT LIKE '%<DIR>%'
				ORDER BY
					ARQUIVO_DT;
			END;
		END;

		IF(LEN(LTRIM(RTRIM(@TABELA_NOME))) > 0 AND (Object_ID('tempDB..' + @TABELA_NOME ,'U') is not null))BEGIN
			WHILE(EXISTS(SELECT TOP 1 ARQUIVO_NS FROM @TB_ARQUIVO))BEGIN
				SELECT TOP 1 @ARQUIVO_NS = ARQUIVO_NS FROM @TB_ARQUIVO				
				SET @EXEC = ''
				SET @EXEC += ' INSERT INTO ' + @TABELA_NOME;
				SET @EXEC += ' SELECT ';
				SET @EXEC += '  ''' + CONVERT(VARCHAR(MAX), (SELECT ARQUIVO_NM FROM @TB_ARQUIVO WHERE ARQUIVO_NS = @ARQUIVO_NS)) + '''';
				SET @EXEC += '  ,' + CONVERT(VARCHAR(20), (SELECT ARQUIVO_TAMANHO FROM @TB_ARQUIVO WHERE ARQUIVO_NS = @ARQUIVO_NS));
				SET @EXEC += '  ,''' + CONVERT(VARCHAR(20), (SELECT ARQUIVO_DT FROM @TB_ARQUIVO WHERE ARQUIVO_NS = @ARQUIVO_NS)) + '''';
				SET @EXEC += '  ,''' + CONVERT(VARCHAR(10), (SELECT ARQUIVO_TP FROM @TB_ARQUIVO WHERE ARQUIVO_NS = @ARQUIVO_NS)) + '''';
				SET @EXEC += '  ,''' + CONVERT(VARCHAR(MAX), (SELECT ARQUIVO_PATHNAME FROM @TB_ARQUIVO WHERE ARQUIVO_NS = @ARQUIVO_NS)) + '''';
				SET @EXEC += '  , 0';

				EXEC (@EXEC);

				DELETE FROM @TB_ARQUIVO WHERE ARQUIVO_NS = @ARQUIVO_NS;
			END;

		END ELSE BEGIN
			SELECT * FROM @TB_ARQUIVO;
		END;

	END TRY
	BEGIN CATCH		
		SELECT @ERROR_MESSAGE += 'ErrorNumber: ' + CONVERT(VARCHAR(500), ERROR_NUMBER());
		SELECT @ERROR_MESSAGE += 'ErrorSeverity: ' + CONVERT(VARCHAR(500), ERROR_SEVERITY());
		SELECT @ERROR_MESSAGE += 'ErrorState: ' + CONVERT(VARCHAR(500), ERROR_STATE());
		SELECT @ERROR_MESSAGE += 'ErrorProcedure: ' + CONVERT(VARCHAR(500), ERROR_PROCEDURE());
		SELECT @ERROR_MESSAGE += 'ErrorLine: ' + CONVERT(VARCHAR(500), ERROR_LINE());
		SELECT @ERROR_MESSAGE += 'ErrorMessage: ' + CONVERT(VARCHAR(500), ERROR_MESSAGE());
		SELECT @ERROR_MESSAGE;
	END CATCH
END;
