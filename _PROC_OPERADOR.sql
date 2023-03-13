USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_OPERADOR', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_OPERADOR]
GO

/****** Object:  StoredProcedure [dbo].[_PCD_BAIXA_SUP_AC]    Script Date: 31/08/2021 11:08:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_OPERADOR(
	@TIPO_ID							BIGINT = 0
	,@DATA								DATE = ''
) 
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR..........: ANDERSON LOPEZ
	*	DATA...........: 05/10/2022..........ANDERSON LOPEZ
	*	DATA...........: 17/11/2022..........ANDERSON LOPEZ
	*	DESCRIÇÃO......: Procedure consulta da escala de home office e update na tabela de ramais da fastway
	***************************************************************************************************************************************************************************************/
	DECLARE @SQL_FAST										VARCHAR(MAX);
	DECLARE @SQL_FAST_RET									VARCHAR(MAX) = 'SELECT *';
	/**************************************************************************************************************************************************************************************/
	DECLARE @TB_OPERADOR_FAST								TABLE(id BIGINT, logon VARCHAR(250), hora_ping DATETIME, login_inicio_dia DATETIME, ramal VARCHAR(10));
	DECLARE @TB_OPERADOR_LOGIN_FAST							TABLE(
																LOGIN_FAST_NS 					BIGINT ,
																LOGIN_FAST_ID					BIGINT NOT NULL DEFAULT 0,
																LOGIN_FAST_LOGON				VARCHAR(50) NOT NULL DEFAULT '',
																LOGIN_FAST_DT_INI				DATETIME DEFAULT NULL,
																LOGIN_FAST_DT_PNG				DATETIME DEFAULT NULL,
																LOGIN_FAST_RAMAL				VARCHAR(10) NOT NULL DEFAULT ''
															);
	/**************************************************************************************************************************************************************************************/	
	DECLARE @LOGIN_FAST_NS									BIGINT = 0;
	DECLARE @LOGIN_FAST_ID									BIGINT = 0;
	DECLARE @LOGIN_FAST_LOGON								VARCHAR(50) = '';
	DECLARE @LOGIN_FAST_DT_INI								DATETIME;
	DECLARE @LOGIN_FAST_DT_PNG								DATETIME;
	DECLARE @LOGIN_FAST_RAMAL								VARCHAR(50) = '';
	DECLARE @DATEDIFF_SECOND								BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @DT_HORA										VARCHAR(8) = '';
	DECLARE @AUX_INT										BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_ERROR										VARCHAR(MAX) = ''; 
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY 
		IF(@DATA = '1900-01-01')BEGIN
			SET @DATA= GETDATE();
		END;
	/***************************************************************************************************************************************************************************************
	*	PEGA AS INFORMAÇÕES DO OPERADOR NA FASTWAY
	***************************************************************************************************************************************************************************************/
		IF(@TIPO_ID = 0)BEGIN
		/***************************************************************************************************************************************************************************************
		*	PEGA AS INFORMAÇÕES DO LOGIN DO OPERADOR
		***************************************************************************************************************************************************************************************/	
			SET @SQL_FAST  = '';
			SET @SQL_FAST += ' SELECT ';
			SET @SQL_FAST += '	 db_oper.id';
			SET @SQL_FAST += '	,db_oper.logon';
			SET @SQL_FAST += '	,db_oper.hora_ping';
			SET @SQL_FAST += '	,db_oper.login_inicio_dia';
			SET @SQL_FAST += '	,db_oper.ramal';
			SET @SQL_FAST += ' FROM';
			SET @SQL_FAST += '	public.operador db_oper';
			SET @SQL_FAST += ' WHERE';
			SET @SQL_FAST += '	db_oper.mod = ''''W''''';
			SET @SQL_FAST += '	AND db_oper.situacao_administrativa = ''''Ativo''''';
			SET @SQL_FAST += '	AND db_oper.perfil = ''''O''''';
			SET @SQL_FAST += '	AND DATE(db_oper.login_inicio_dia) = ''''' + CONVERT(VARCHAR(10), @DATA) + '''''';

			INSERT INTO @TB_OPERADOR_FAST EXEC [__EXEC_OPENROWSET] @CONSULTA_SQL = @SQL_FAST_RET, @CONSULTA_OPENROWSET = @SQL_FAST, @TIPO = 1 ;

			WHILE(EXISTS(SELECT TOP 1 id FROM @TB_OPERADOR_FAST ))BEGIN
				SELECT TOP 1 
					 @LOGIN_FAST_ID = id 
					,@LOGIN_FAST_LOGON = logon
					,@LOGIN_FAST_DT_INI = login_inicio_dia
					,@LOGIN_FAST_DT_PNG = hora_ping
					,@LOGIN_FAST_RAMAL = ramal 
				FROM 
					@TB_OPERADOR_FAST;

				IF((SELECT COUNT(LOGIN_FAST_NS) FROM TB_OPERADOR_LOGIN_FAST WHERE LOGIN_FAST_ID = @LOGIN_FAST_ID AND CONVERT(DATE, LOGIN_FAST_DT_INI) = CONVERT(DATE, @LOGIN_FAST_DT_INI)) = 0)BEGIN
					INSERT INTO TB_OPERADOR_LOGIN_FAST(
						LOGIN_FAST_ID
						,LOGIN_FAST_LOGON
						,LOGIN_FAST_DT_INI
						,LOGIN_FAST_DT_PNG
						,LOGIN_FAST_RAMAL
					)
					SELECT
						@LOGIN_FAST_ID
						,@LOGIN_FAST_LOGON
						,@LOGIN_FAST_DT_INI
						,@LOGIN_FAST_DT_INI
						,@LOGIN_FAST_RAMAL
				END ELSE BEGIN
					SELECT 
						@LOGIN_FAST_NS = LOGIN_FAST_NS
					FROM 
						TB_OPERADOR_LOGIN_FAST 
					WHERE 
						LOGIN_FAST_ID = @LOGIN_FAST_ID 
						AND CONVERT(DATE, LOGIN_FAST_DT_INI) = CONVERT(DATE, @LOGIN_FAST_DT_INI)

					SET @DATEDIFF_SECOND = (datediff(SECOND, CONVERT(DATETIME, MIN(@LOGIN_FAST_DT_INI) , 103), CONVERT(DATETIME, MAX(@LOGIN_FAST_DT_PNG) , 103)));

					SELECT @AUX_INT = CONVERT(INT, (@DATEDIFF_SECOND / 60 / 60));

					IF(@AUX_INT < 10)BEGIN
						SET @DT_HORA = '0' + CONVERT(VARCHAR(2), @AUX_INT);
					END ELSE BEGIN
						SET @DT_HORA = CONVERT(VARCHAR(2), @AUX_INT);
					END;
				
					SELECT @AUX_INT = CONVERT(INT, (@DATEDIFF_SECOND / 60 % 60));
					IF(@AUX_INT < 10)BEGIN
						SET @DT_HORA += ':0' + CONVERT(VARCHAR(2), @AUX_INT);
					END ELSE BEGIN
						SET @DT_HORA += ':' + CONVERT(VARCHAR(2), @AUX_INT);
					END;

					SELECT @AUX_INT = CONVERT(INT, (@DATEDIFF_SECOND % 60));
					IF(@AUX_INT < 10)BEGIN
						SET @DT_HORA += ':0' + CONVERT(VARCHAR(2), @AUX_INT);
					END ELSE BEGIN
						SET @DT_HORA += ':' + CONVERT(VARCHAR(2), @AUX_INT);
					END;
					
					UPDATE 
						TB_OPERADOR_LOGIN_FAST
					SET
						LOGIN_FAST_DT_PNG = @LOGIN_FAST_DT_PNG
						,LOGIN_FAST_HR_TRAB = @DT_HORA
						,LOGIN_FAST_SEG_TRAB = @DATEDIFF_SECOND
					WHERE
						LOGIN_FAST_NS = @LOGIN_FAST_NS
						AND LOGIN_FAST_ID = @LOGIN_FAST_ID
						AND CONVERT(DATE, @LOGIN_FAST_DT_INI) = @DATA;
				END;							
				DELETE FROM @TB_OPERADOR_FAST WHERE id = @LOGIN_FAST_ID;
			END;	
		END;
		IF(@TIPO_ID = 1)BEGIN
			SELECT 
				 DB_OPDA.DAYLING_DATA																												AS 'Data'
				,ISNULL(CONVERT(VARCHAR(10), DB_OPDA.DAYLING_HORA, 108), '')																		AS 'Hora'			
				,DB_EQUI.NM_EQUIPE																													AS 'Equipe'
				,DB_USUA.NM_USUARIO																													AS 'Usuário'
				,DB_OPER.LOGIN_FAST_RAMAL																											AS 'Ramal'
				,ISNULL(CONVERT(VARCHAR(10), DB_OPER.LOGIN_FAST_DT_INI, 108) + ' ' + CONVERT(VARCHAR(10), DB_OPER.LOGIN_FAST_DT_INI, 103), '') 		AS 'Login Inicio'
				,ISNULL(CONVERT(VARCHAR(10), DB_OPER.LOGIN_FAST_DT_PNG, 108) + ' ' + CONVERT(VARCHAR(10), DB_OPER.LOGIN_FAST_DT_PNG, 103), '')		AS 'Login Atual'
				,ISNULL(CONVERT(VARCHAR(10), DB_OPER.LOGIN_FAST_HR_TRAB, 108), '')																	AS 'T. Logado'
				,(SELECT dbo.Convert_SS_To_HHMMSS_108((DB_OPER.LOGIN_FAST_SEG_TRAB) - (
					SELECT 
						SUM(DAYLING_QTD_TEMPO_PAUSA) + SUM(DAYLING_QTD_TEMPO_CONT)
					FROM 
						TB_OPERADOR_DAYLING DB_OPDA1 
					WHERE 
						DB_OPDA1.LOGIN_FAST_ID = DB_OPDA.LOGIN_FAST_ID 
						AND DB_OPDA1.DAYLING_DATA = DB_OPDA.DAYLING_DATA
				)))																																	AS 'T. Trab.'
				,DB_OPDA.DAYLING_QTD_CLIE_TRAB																										AS 'QTD Cliente Trab.'
				,CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( DB_OPDA.DAYLING_VLR_CLIE_TRAB)))							AS 'VLR Cliente Trab.'
				,DB_OPDA.DAYLING_QTD_LIG																											AS 'QTD Ligação'
				,DB_OPDA.DAYLING_QTD_ALO																											AS 'QTD ALO'
				,DB_OPDA.DAYLING_QTD_CPC																											AS 'QTD CPC'
				,DB_OPDA.DAYLING_QTD_CPCA																											AS 'QTD CPA'
				,DB_OPDA.DAYLING_QTD_ACORDO																											AS 'QTD Acordo'
				,CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( DB_OPDA.DAYLING_VLR_ACORDO)))								AS 'VLR Acordo'
				,DB_OPDA.DAYLING_QTD_ACORDO_PGTO																									AS 'QTD Acordo PGTO'
				,CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( DB_OPDA.DAYLING_VLR_ACORDO_PGTO)))							AS 'VLR Acordo PGTO'	
				,(SELECT dbo.Convert_SS_To_HHMMSS_108(DB_OPDA.DAYLING_QTD_ACW))																		AS 'QTD ACW'
				,(SELECT dbo.Convert_SS_To_HHMMSS_108(DB_OPDA.DAYLING_QTD_TEMPO_FALADO))															AS 'QTD T. Falado'
				,(SELECT dbo.Convert_SS_To_HHMMSS_108(DB_OPDA.DAYLING_QTD_TEMPO_PAUSA))																AS 'QTD T. Pausa'
				,(SELECT dbo.Convert_SS_To_HHMMSS_108(DB_OPDA.DAYLING_QTD_TEMPO_CONT))																AS 'QTD T. Pausa Contratual'
				,(SELECT dbo.Convert_SS_To_HHMMSS_108(DB_OPDA.DAYLING_QTD_TEMPO_AVAIL))																AS 'QTD T. AVAIL'
				,(SELECT dbo.Convert_SS_To_HHMMSS_108(DB_OPDA.DAYLING_MEDIA_CHAMADAS))																AS 'Media Chamadas'
				,(SELECT dbo.Convert_SS_To_HHMMSS_108(DB_OPDA.DAYLING_TMA))																			AS 'TMA'			
				--,DB_OPDA.DAYLING_AM_EMAIL
				--,DB_OPDA.DAYLING_AM_BOLETO
				,DB_OPDA.DAYLING_AA_NUMERO_N_EXISTE
				,DB_OPDA.DAYLING_AA_CAIXA_POSTAL
				,DB_OPDA.DAYLING_AA_LIGACAO_MUDA
				--,DB_OPDA.DAYLING_AA_SINAL_FAX
				,DB_OPDA.DAYLING_AA_N_ATENDEU
				,DB_OPDA.DAYLING_AA_HANGUP
				,DB_OPDA.DAYLING_AA_OCUPADO
			FROM 
				TB_OPERADOR_LOGIN_FAST										DB_OPER
				JOIN [Homolog].[dbo].[TB_USUARIO]						DB_USUA ON CONVERT(VARCHAR(20), DB_OPER.LOGIN_FAST_ID) = DB_USUA.NM_LOGIN_DISCADOR
				JOIN [Homolog].[dbo].[TB_EQUIPE]						DB_EQUI ON DB_USUA.ID_EQUIPE = DB_EQUI.ID_EQUIPE
				JOIN TB_OPERADOR_DAYLING									DB_OPDA ON DB_OPER.LOGIN_FAST_ID = DB_OPDA.LOGIN_FAST_ID
			WHERE
				CONVERT(DATE, DB_OPER.LOGIN_FAST_DT_INI) = @DATA
				AND CONVERT(DATE, DB_OPER.LOGIN_FAST_DT_INI) = DB_OPDA.DAYLING_DATA
				AND DATEPART(HOUR, DB_OPDA.DAYLING_HORA) >= DATEPART(HOUR, LOGIN_FAST_DT_INI)			
			ORDER BY
				DB_EQUI.NM_EQUIPE, DB_USUA.NM_USUARIO, DB_OPDA.DAYLING_HORA
		END;
	END TRY 
	BEGIN CATCH  
		SET @SQL_ERROR = '';
		SET @SQL_ERROR += 'ErrorNumber: ' + (SELECT CONVERT(VARCHAR(500), ERROR_NUMBER())) + ';';
		SET @SQL_ERROR += 'ErrorSeverity: ' + (SELECT CONVERT(VARCHAR(500), ERROR_SEVERITY())) + ';';
		SET @SQL_ERROR += 'ErrorState: ' + (SELECT CONVERT(VARCHAR(500), ERROR_STATE())) + ';';
		SET @SQL_ERROR += 'ErrorProcedure: ' + (SELECT CONVERT(VARCHAR(500), ERROR_PROCEDURE())) + ';';
		SET @SQL_ERROR += 'ErrorLine: ' + (SELECT CONVERT(VARCHAR(500), ERROR_LINE())) + ';';
		SET @SQL_ERROR += 'ErrorMessage: ' + (SELECT CONVERT(VARCHAR(500), ERROR_MESSAGE())) + ';';
		
		SELECT @SQL_ERROR;
	END CATCH; 
END;