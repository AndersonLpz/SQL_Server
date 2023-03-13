USE [Homolog]
GO
--Exclui procedure
IF OBJECT_ID('dbo.__EXEC_CMDSHELL_DIR', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__EXEC_CMDSHELL_DIR]
GO
/****** Object:  StoredProcedure [dbo].[__EXEC_BCP]    Script Date: 03/09/2021 13:13:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[__EXEC_CMDSHELL_DIR] (
	 @FULLPATHNAME											VARCHAR(MAX) = ''
) AS 
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 03/09/2021	
	*	DESCRIÇÃO.: Procedure para teronar os arquivos contido em um diretorio.
	***************************************************************************************************************************************************************************************/	
	DECLARE @TB_CMD										TABLE(NS_CMD INT IDENTITY(1, 1), DS_CMD VARCHAR(MAX));	
	DECLARE @TB_ARQUIVO									TABLE(NS_ARQUIVO INT IDENTITY(1, 1), DT_ARQUIVO DATETIME, TM_ARQUIVO INT, DS_ARQUIVO VARCHAR(255));
	DECLARE @DS_CMD										VARCHAR(MAX);
	DECLARE @FLAG_ARQ									INT = 0;
	DECLARE @EXEC_CMDSHELL								VARCHAR(4000) = '';
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY
		IF(LEN(LTRIM(RTRIM(@FULLPATHNAME))) > 0)BEGIN
			DELETE FROM [Homolog].[dbo].[__TBCMDDIR_TEMP] WHERE TBCMDDIR_TEMP_PATHNAME = @FULLPATHNAME;
			SET @EXEC_CMDSHELL = 'dir/ -C /4 /N "' + @FULLPATHNAME + '"';

 			INSERT INTO @TB_CMD	EXEC master.dbo.xp_cmdshell @command_string = @EXEC_CMDSHELL; 		
	
			SELECT @DS_CMD = LTRIM(RTRIM(DS_CMD)) FROM @TB_CMD WHERE UPPER(DS_CMD) LIKE '%ARQUIVO(S)%';	
			SELECT @FLAG_ARQ = CONVERT(INT, LTRIM(RTRIM(SUBSTRING(@DS_CMD, 1, CHARINDEX('ARQUIVO(S)', UPPER(@DS_CMD)) -1))));

			IF(@FLAG_ARQ > 0) BEGIN
				INSERT INTO @TB_ARQUIVO(DT_ARQUIVO, TM_ARQUIVO, DS_ARQUIVO)
				SELECT 
					CONVERT(DATETIME, LEFT(DS_CMD, 17), 103) AS Dt_Criacao,
					LTRIM(SUBSTRING(LTRIM(DS_CMD), 18, 19)) AS Qt_Tamanho,
					SUBSTRING(DS_CMD, CHARINDEX(LTRIM(SUBSTRING(LTRIM(DS_CMD), 18, 19)), DS_CMD, 18) + LEN(LTRIM(SUBSTRING(LTRIM(DS_CMD), 18, 19))) + 1, LEN(DS_CMD)) AS Ds_Arquivo
				FROM 
					@TB_CMD
				WHERE 
					DS_CMD IS NOT NULL
					AND NS_CMD >= 6
					AND NS_CMD < (SELECT MAX(NS_CMD) FROM @TB_CMD) - 2
					AND DS_CMD NOT LIKE '%<DIR>%'
					--AND SUBSTRING(CMD_RESULT, CHARINDEX(LTRIM(SUBSTRING(LTRIM(CMD_RESULT), 18, 19)), CMD_RESULT, 18) + LEN(LTRIM(SUBSTRING(LTRIM(CMD_RESULT), 18, 19))) + 1, LEN(CMD_RESULT)) NOT IN ('_Modelo_Baixa_Suspensao.csv')
				ORDER BY
					Dt_Criacao;

				INSERT INTO __TBCMDDIR_TEMP(
					 TBCMDDIR_TEMP_NS
					,TBCMDDIR_TEMP_PATHNAME
					,TBCMDDIR_TEMP_NAME
					,TBCMDDIR_TEMP_TP
					,TBCMDDIR_TEMP_TAM
					,TBCMDDIR_TEMP_DT_CRIACAO
				)
				SELECT 
					 NS_ARQUIVO
					,@FULLPATHNAME
					,DS_ARQUIVO 
					,(
						CASE
							WHEN CHARINDEX('.txt', DS_ARQUIVO) > 0 THEN 'txt'
							WHEN CHARINDEX('.xlsx', DS_ARQUIVO) > 0 THEN 'xlsx'
							WHEN CHARINDEX('.csv', DS_ARQUIVO) > 0 THEN 'csv'
							WHEN CHARINDEX('.zip', DS_ARQUIVO) > 0 THEN 'zip'
							WHEN CHARINDEX('.log', DS_ARQUIVO) > 0 THEN 'log'
							ELSE NULL
						END
					)
					,TM_ARQUIVO
					,DT_ARQUIVO
				FROM 
					@TB_ARQUIVO;
			END;
		END;

	END TRY
	BEGIN CATCH
		INSERT INTO __TBRELTEMP(
			TBRELTEMP_NM_PROC
			,TBRELTEMP_VCHAR01
			,TBRELTEMP_VCHAR02
			,TBRELTEMP_VCHAR03
			,TBRELTEMP_VCHAR04
		)VALUES(
			'__EXEC_CMDSHELL_DIR'
			,'ERRO'
			,CONVERT(VARCHAR(MAX), ERROR_NUMBER())
			,CONVERT(VARCHAR(MAX), ERROR_MESSAGE())
			,@EXEC_CMDSHELL
		)

	END CATCH
END;
