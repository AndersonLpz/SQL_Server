USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_LIMP_DETALHE_CONTRATO', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_LIMP_DETALHE_CONTRATO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_LIMP_DETALHE_CONTRATO
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 18/08/2022	
	*	DESCRIÇÃO.: Procedure para exluir registros duplicados do detalhe contrato.
	***************************************************************************************************************************************************************************************/
	DECLARE @TB_CONTRATO_DETALHE_AUX							TABLE(ID_CONTRATO BIGINT, NU_SEQUENCIAL BIGINT, ID_DETALHE BIGINT, NM_DETALHE_VALOR VARCHAR(500), FLAG INT);	
	DECLARE @ID_CONTRATO BIGINT
	DECLARE @NU_SEQUENCIAL BIGINT
	DECLARE @ID_DETALHE BIGINT
	DECLARE @NM_DETALHE_VALOR VARCHAR(500);	
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY 			
	/**************************************************************************************************************************************************************************************/	
		INSERT INTO 
			@TB_CONTRATO_DETALHE_AUX
		SELECT TOP 1000
			ID_CONTRATO
			,NU_SEQUENCIAL
			,ID_DETALHE
			,NM_DETALHE_VALOR
			,0
		FROM
			[Homolog].[dbo].TB_CONTRATO_DETALHE									DB_CODE

		WHERE
			1 = (
				CASE
					WHEN (
						SELECT 
							COUNT (DB_CODE_AUX.NU_SEQUENCIAL)
						FROM 
							[Homolog].[dbo].TB_CONTRATO_DETALHE DB_CODE_AUX 
						WHERE 
							DB_CODE_AUX.ID_CONTRATO = DB_CODE.ID_CONTRATO 
							AND DB_CODE_AUX.ID_DETALHE = DB_CODE.ID_DETALHE
							AND REPLACE(UPPER(DB_CODE_AUX.NM_DETALHE_VALOR), ' ', '') = REPLACE(UPPER(DB_CODE.NM_DETALHE_VALOR), ' ', '')) > 1 THEN 1
					ELSE 0
					END
		);
	/**************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 NU_SEQUENCIAL FROM @TB_CONTRATO_DETALHE_AUX WHERE FLAG = 0)) BEGIN
			SELECT 
				@ID_CONTRATO = ID_CONTRATO
				,@NU_SEQUENCIAL = NU_SEQUENCIAL
				,@ID_DETALHE = ID_DETALHE
				,@NM_DETALHE_VALOR = NM_DETALHE_VALOR
			FROM
				@TB_CONTRATO_DETALHE_AUX 
			WHERE 
				FLAG = 0;
			
			UPDATE @TB_CONTRATO_DETALHE_AUX
			SET FLAG = 99
			WHERE
				NU_SEQUENCIAL IN(
			SELECT 
				NU_SEQUENCIAL
			FROM
				@TB_CONTRATO_DETALHE_AUX
			WHERE
				ID_CONTRATO = @ID_CONTRATO
				AND ID_DETALHE = @ID_DETALHE
				AND NU_SEQUENCIAL != @NU_SEQUENCIAL
				AND REPLACE(UPPER(NM_DETALHE_VALOR), ' ', '') = REPLACE(UPPER(@NM_DETALHE_VALOR), ' ', ''))
				AND FLAG = 0;

			UPDATE @TB_CONTRATO_DETALHE_AUX SET FLAG = 1 WHERE NU_SEQUENCIAL = @NU_SEQUENCIAL
		END

		IF((SELECT COUNT(NU_SEQUENCIAL) FROM @TB_CONTRATO_DETALHE_AUX WHERE FLAG = 99) > 0)BEGIN
			DELETE FROM 
				[Homolog].[dbo].TB_CONTRATO_DETALHE 
			WHERE 
				NU_SEQUENCIAL IN( SELECT NU_SEQUENCIAL FROM @TB_CONTRATO_DETALHE_AUX WHERE FLAG = 99)
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