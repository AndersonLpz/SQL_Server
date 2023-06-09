USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_ACORDO_BAIXA_EXC', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_ACORDO_BAIXA_EXC]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_ACORDO_BAIXA_EXC (
	 @TBCMDDIR_TEMP_NS					BIGINT = 0
)
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 24/08/2022
	*	DESCRIÇÃO.: Procedure para importar arquivo excel
	***************************************************************************************************************************************************************************************/		
	IF Object_ID('tempDB..##_TB_ACORDO_BAIXA_AC','U') is not null DROP TABLE ##_TB_ACORDO_BAIXA_AC;	
	/**************************************************************************************************************************************************************************************/
	DECLARE @FULLPATHNAME_AUX										VARCHAR(MAX) = '';	
	DECLARE @TBCMDDIR_TEMP_PATHNAME									VARCHAR(500) = '';	
	DECLARE @ARQ_NS													INT = 0;
	DECLARE @ARQ_NOME												VARCHAR(255);
	/**************************************************************************************************************************************************************************************/	
	DECLARE @ID_CEDENTE												BIGINT = 0;
	DECLARE @NM_BASE												VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQLString												NVARCHAR(500);  
	DECLARE @EXEC_OPENROWSET										VARCHAR(MAX) = '';	
	DECLARE @EXEC_PARAM												NVARCHAR(500);
	/**************************************************************************************************************************************************************************************/	
	DECLARE @SUBAAC_NM_CLIENTE_CEDENTE_TAB							VARCHAR(100) = ''
	DECLARE @SUBAAC_NU_CPF_CNPJ_TAB									VARCHAR(100) = '';
	DECLARE @SUBAAC_NM_CONTRATO_CEDENTE_TAB							VARCHAR(50) = '';
	DECLARE @SUBAAC_NM_DIVIDA_CEDENTE_TAB							VARCHAR(50) = '';	
	DECLARE @SUBAAC_DT_PGTO_TAB										VARCHAR(50) = '';
	DECLARE @SUBAAC_DESC_ACAO_TAB									VARCHAR(500) = '';
	/**************************************************************************************************************************************************************************************/	
	DECLARE @SUBAAC_NM_ARQ											VARCHAR(200) = '';
	DECLARE @SUBAAC_ID_CEDENTE										BIGINT = 0;
	DECLARE @SUBAAC_ID_CLIENTE										INT = 0;
	DECLARE @SUBAAC_NM_CLIENTE_CEDENTE								VARCHAR(50) = '';
	DECLARE @SUBAAC_NU_CPF_CNPJ										BIGINT = 0;
	DECLARE @SUBAAC_ID_CONTRATO										BIGINT = 0;
	DECLARE @SUBAAC_NM_CONTRATO_CEDENTE								VARCHAR(50) = '';
	DECLARE @SUBAAC_ID_DIVIDA										BIGINT = 0;
	DECLARE @SUBAAC_NM_DIVIDA_CEDENTE								VARCHAR(50) = '';
	DECLARE @SUBAAC_VL_DIVIDA										VARCHAR(50) = '';	
	DECLARE @SUBAAC_DT_PGTO											VARCHAR(20) = '';
	DECLARE @SUBAAC_DESC_ACAO										VARCHAR(500) = '';
	/**************************************************************************************************************************************************************************************/	
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY
		IF(@TBCMDDIR_TEMP_NS > 0) BEGIN
			SELECT TOP 1 
				 @ARQ_NOME = TBCMDDIR_TEMP_NAME 
				,@TBCMDDIR_TEMP_PATHNAME = ISNULL(TBCMDDIR_TEMP_PATHNAME, '')					
			FROM
				__TBCMDDIR_TEMP 
			WHERE   
				TBCMDDIR_TEMP_NS = @TBCMDDIR_TEMP_NS ;

			IF(CHARINDEX('VELOE', UPPER(@ARQ_NOME)) > 0)BEGIN
				SET @NM_BASE = '[BASE$]';
				SET @ID_CEDENTE = 68;
			END;

			IF((@ID_CEDENTE > 0) AND (LEN(LTRIM(RTRIM(@NM_BASE))) > 0)) BEGIN
			
				SET  @EXEC_OPENROWSET = ' SELECT '
				SET  @EXEC_OPENROWSET += '	* '
				SET  @EXEC_OPENROWSET += ' into ##_TB_ACORDO_BAIXA_AC'
				SET  @EXEC_OPENROWSET += ' FROM '
				SET  @EXEC_OPENROWSET += '	OPENROWSET( '
				SET  @EXEC_OPENROWSET += '''Microsoft.ACE.OLEDB.12.0'',''Excel 12.0 Xml;Database=' + @TBCMDDIR_TEMP_PATHNAME + '\' + @ARQ_NOME  +  ''', ''select * from ' + @NM_BASE + ''')'
				EXEC (@EXEC_OPENROWSET);
			END;

			IF(@ID_CEDENTE = 68) BEGIN
				SET @SUBAAC_NM_CLIENTE_CEDENTE_TAB = 'COD_CLIENTE';
				SET @SUBAAC_NU_CPF_CNPJ_TAB = 'CPF';
				SET @SUBAAC_NM_CONTRATO_CEDENTE_TAB  = 'FATURA';
				SET @SUBAAC_NM_DIVIDA_CEDENTE_TAB = 'FATURA';
				SET @SUBAAC_DT_PGTO_TAB = 'DATA_PGTO';
				SET @SUBAAC_DESC_ACAO_TAB = 'STATUS'
			END;

			WHILE(EXISTS(SELECT TOP 1 1 FROM ##_TB_ACORDO_BAIXA_AC ))BEGIN
				SET @SUBAAC_ID_CLIENTE = 0;
				SET @SUBAAC_NM_CLIENTE_CEDENTE = '';
				SET @SUBAAC_NU_CPF_CNPJ = 0;
				SET @SUBAAC_ID_CONTRATO = 0;
				SET @SUBAAC_NM_CONTRATO_CEDENTE = '';
				SET @SUBAAC_ID_DIVIDA = 0;
				SET @SUBAAC_NM_DIVIDA_CEDENTE = '';
				SET @SUBAAC_VL_DIVIDA = '';	
				SET @SUBAAC_DT_PGTO	= '';
				SET @SUBAAC_DESC_ACAO  = '';
						
				SET @SQLString  = N'SELECT TOP 1 '
				SET @SQLString += N'	 @AUX1_OUT = CAST(CAST(ISNULL(' + @SUBAAC_NM_CLIENTE_CEDENTE_TAB + ', 0)AS NUMERIC(38)) AS VARCHAR(50)) '
				SET @SQLString += N'	,@AUX2_OUT = CONVERT(BIGINT, ISNULL(' + @SUBAAC_NU_CPF_CNPJ_TAB + ', 0)) '
				SET @SQLString += N'	,@AUX3_OUT = CAST(CAST(ISNULL(' + @SUBAAC_NM_CONTRATO_CEDENTE_TAB + ', 0)AS NUMERIC(38)) AS VARCHAR(50)) '
				SET @SQLString += N'	,@AUX4_OUT = CAST(CAST(ISNULL(' + @SUBAAC_NM_DIVIDA_CEDENTE_TAB + ', 0) AS NUMERIC(38)) AS VARCHAR(50)) '
				SET @SQLString += N'	,@AUX5_OUT = CONVERT(VARCHAR(20), ISNULL(' + @SUBAAC_DT_PGTO_TAB + ', GETDATE()), 111) '
				SET @SQLString += N'	,@AUX6_OUT = CONVERT(VARCHAR(500), UPPER(ISNULL(' + @SUBAAC_DESC_ACAO_TAB + ', ''''))) '
				SET @SQLString += N'FROM '
				SET @SQLString += N'	##_TB_ACORDO_BAIXA_AC';

				SET @EXEC_PARAM  = N' @AUX1_OUT VARCHAR(50) OUTPUT'
				SET @EXEC_PARAM += N',@AUX2_OUT BIGINT OUTPUT'  
				SET @EXEC_PARAM += N',@AUX3_OUT VARCHAR(50) OUTPUT';
				SET @EXEC_PARAM += N',@AUX4_OUT VARCHAR(50) OUTPUT';
				SET @EXEC_PARAM += N',@AUX5_OUT VARCHAR(20) OUTPUT';
				SET @EXEC_PARAM += N',@AUX6_OUT VARCHAR(500) OUTPUT';

				EXECUTE sp_executesql 
					 @SQLString
					,@EXEC_PARAM
					,@AUX1_OUT = @SUBAAC_NM_CLIENTE_CEDENTE					OUTPUT
					,@AUX2_OUT = @SUBAAC_NU_CPF_CNPJ						OUTPUT
					,@AUX3_OUT = @SUBAAC_NM_CONTRATO_CEDENTE				OUTPUT
					,@AUX4_OUT = @SUBAAC_NM_DIVIDA_CEDENTE					OUTPUT
					,@AUX5_OUT = @SUBAAC_DT_PGTO							OUTPUT
					,@AUX6_OUT = @SUBAAC_DESC_ACAO							OUTPUT
							
				SET @SQLString  = N' DELETE FROM '
				SET @SQLString += N'	##_TB_ACORDO_BAIXA_AC '
				SET @SQLString += N' WHERE ' 
				SET @SQLString += N'	' + @SUBAAC_NM_DIVIDA_CEDENTE_TAB + ' = ' + CONVERT(VARCHAR(20), @SUBAAC_NM_DIVIDA_CEDENTE);
			/***************************************************************************************************************************************************************************************
			*	Procura as informações adicionais - INICIO
			***************************************************************************************************************************************************************************************/	
				SELECT
						@SUBAAC_ID_CLIENTE = ISNULL(DB_CLIE.ID_CLIENTE, 0)
				FROM
					[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
				WHERE
					DB_CLIE.ID_CEDENTE = @SUBAAC_ID_CEDENTE
					OR DB_CLIE.NM_CLIENTE_CEDENTE = @SUBAAC_NM_CLIENTE_CEDENTE 
					OR DB_CLIE.NU_CPF_CNPJ = @SUBAAC_NU_CPF_CNPJ;
						
				SELECT
					@SUBAAC_ID_CONTRATO = ISNULL(DB_CONT.ID_CONTRATO, 0)
				FROM
					[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
					JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
				WHERE
					DB_CLIE.ID_CEDENTE = @SUBAAC_ID_CEDENTE
					OR DB_CLIE.NM_CLIENTE_CEDENTE = @SUBAAC_NM_CLIENTE_CEDENTE 
					OR DB_CLIE.NU_CPF_CNPJ = @SUBAAC_NU_CPF_CNPJ
					AND DB_CONT.NM_CONTRATO_CEDENTE = @SUBAAC_NM_CONTRATO_CEDENTE;

				SELECT
					@SUBAAC_ID_DIVIDA = ISNULL(DB_DIVI.ID_DIVIDA, 0)
					,@SUBAAC_VL_DIVIDA = ISNULL(DB_DIVI.VL_DIVIDA, '')						
				FROM
					[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
					JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
					JOIN [Homolog].[dbo].[TB_DIVIDA]							DB_DIVI ON DB_CONT.ID_CONTRATO = DB_DIVI.ID_CONTRATO
				WHERE
					DB_CLIE.ID_CEDENTE = @SUBAAC_ID_CEDENTE
					OR DB_CLIE.NM_CLIENTE_CEDENTE = @SUBAAC_NM_CLIENTE_CEDENTE 
					OR DB_CLIE.NU_CPF_CNPJ = @SUBAAC_NU_CPF_CNPJ
					AND DB_CONT.NM_CONTRATO_CEDENTE = @SUBAAC_NM_CONTRATO_CEDENTE
					AND DB_DIVI.NM_DIVIDA_CEDENTE = @SUBAAC_NM_DIVIDA_CEDENTE;		

			/***************************************************************************************************************************************************************************************
			*	Procura as informações adicionais - FIM
			***************************************************************************************************************************************************************************************/			
				INSERT INTO [dbo].[_TBSUBAAC](
					 [SUBAAC_NM_ARQ]
					,[SUBAAC_ID_CEDENTE]
					,[SUBAAC_ID_CLIENTE]
					,[SUBAAC_NM_CLIENTE_CEDENTE]
					,[SUBAAC_NU_CPF_CNPJ]
					,[SUBAAC_ID_CONTRATO]
					,[SUBAAC_NM_CONTRATO_CEDENTE]
					,[SUBAAC_ID_DIVIDA]
					,[SUBAAC_NM_DIVIDA_CEDENTE]					
					,[SUBAAC_VL_DIVIDA]
					,[SUBAAC_DT_PGTO]
					,[SUBAAC_TP]
					,[SUBAAC_DESC_ACAO]
				) VALUES (
					 @ARQ_NOME
					,@ID_CEDENTE
					,@SUBAAC_ID_CLIENTE
					,@SUBAAC_NM_CLIENTE_CEDENTE
					,@SUBAAC_NU_CPF_CNPJ
					,@SUBAAC_ID_CONTRATO
					,@SUBAAC_NM_CONTRATO_CEDENTE
					,@SUBAAC_ID_DIVIDA
					,@SUBAAC_NM_DIVIDA_CEDENTE
					,@SUBAAC_VL_DIVIDA
					,@SUBAAC_DT_PGTO
					,0
					,@SUBAAC_DESC_ACAO
				)
				EXEC sp_executesql @SQLString;
			END;
		END;
	END TRY 
	BEGIN CATCH  
		SELECT CONVERT(VARCHAR(500), ERROR_NUMBER()) AS 'ErrorNumber';
		SELECT CONVERT(VARCHAR(500), ERROR_SEVERITY()) AS 'ErrorSeverity';
		SELECT CONVERT(VARCHAR(500), ERROR_STATE()) AS 'ErrorState';
		SELECT CONVERT(VARCHAR(500), ERROR_PROCEDURE()) AS 'ErrorProcedure';
		SELECT CONVERT(VARCHAR(500), ERROR_LINE()) AS 'ErrorLine';
		SELECT CONVERT(VARCHAR(500), ERROR_MESSAGE()) AS 'ErrorMessage';			
	END CATCH; 
END;