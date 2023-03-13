USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_HOME_OFFICE', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_HOME_OFFICE]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_HOME_OFFICE 
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 05/10/2022	
	*	DATA ATUALIZACAO.........: 25/11/2022	
	*	DESCRIÇÃO................: Procedure consulta da escala de home office e update na tabela de ramais da fastway
	***************************************************************************************************************************************************************************************/	
	DECLARE @TB_HOME_OFFICE											TABLE(	
																		 ID_USUARIO 		BIGINT DEFAULT 0
																		,RAMAL_INT			BIGINT DEFAULT 0
																		,RAMAL_EXT			BIGINT DEFAULT 0
																		,DSEMANA			BIGINT DEFAULT 0
																		,FLAG		 		BIGINT DEFAULT 0
																	);
	DECLARE @TB_RET_RAMAL											TABLE(
																		RAMAL_FAST BIGINT
																	);	
																	
	DECLARE @TB_RAMAL_FAST											TABLE(
																		RAMAL_PROTOCOLO VARCHAR(50)
																		,RAMAL_SH VARCHAR(10)
																		,RAMAL_FAST BIGINT
																		,RAMAL_NAT VARCHAR(10)
																		,RAMAL_ATIVO INT
																		,FLAG_RAMAL INT
																	);																	
	/**************************************************************************************************************************************************************************************/	
	DECLARE @ID_USUARIO												BIGINT = 0;
	DECLARE @RAMAL_INT												BIGINT = 0;	
	DECLARE @RAMAL_EXT												BIGINT = 0;
	DECLARE @RAMAL_ATIVO											INT = 0;
	DECLARE @HORA_ATUAL												TIME = GETDATE();
	DECLARE @DATEPART_DIA_SEMANA									INT = DATEPART(DW,GETDATE());
	DECLARE @DATEPART_HORA											INT = DATEPART(HOUR, GETDATE());
	DECLARE @FLAG_RAMAL												INT = 0;
	DECLARE @COUNT													INT = 0;
	/**************************************************************************************************************************************************************************************/	
	DECLARE @SQL_EXEC												VARCHAR(MAX);
	/**************************************************************************************************************************************************************************************
	*	- VARIAVEL ENVIO EMAIL
	***************************************************************************************************************************************************************************************/
	DECLARE @SUBJECT											VARCHAR(200) = 'Alteração de Ramais.';
	DECLARE @BODY_CABECALHO_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @BODY_CORPO_HTML									NVARCHAR(MAX) = '' ;
	DECLARE @BODY_RODAPE_HTML									NVARCHAR(MAX) = '' ;
	DECLARE @BODY_ENVIO_HTML									NVARCHAR(MAX) = '' ;	
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
	/**************************************************************************************************************************************************************************************
	*	- EXCLUIR A O DELETE/INSERT APOS O EXCEL ESTAR CONFIGURADO PARA O NOVO BANCO.
	***************************************************************************************************************************************************************************************/
		DELETE FROM [Homolog].[dbo].[TB_HOME_OFFICE]
		INSERT INTO [Homolog].[dbo].[TB_HOME_OFFICE]
		SELECT TOP (1000) [TBHOME_OFFICE_ID_USUARIO]
			  ,[TBHOME_OFFICE_RAMAL_INT]
			  ,[TBHOME_OFFICE_RAMAL_EXT]
			  ,[TBHOME_OFFICE_DSEMANA_1]
			  ,[TBHOME_OFFICE_DSEMANA_2]
			  ,[TBHOME_OFFICE_DSEMANA_3]
			  ,[TBHOME_OFFICE_DSEMANA_4]
			  ,[TBHOME_OFFICE_DSEMANA_5]
			  ,[TBHOME_OFFICE_DSEMANA_6]
			  ,[TBHOME_OFFICE_OBS]
			  ,TBHOME_OFFICE_ID_ANYDESK
		FROM [Homolog].[dbo].[_TBHOME_OFFICE]
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/	
		SET @SQL_EXEC  = '';
		SET @SQL_EXEC += ' SELECT ';
		SET @SQL_EXEC += '	DB_EQUI.NM_EQUIPE';
		SET @SQL_EXEC += '	,ISNULL((';
		SET @SQL_EXEC += '		SELECT ';
		SET @SQL_EXEC += '			DB_TURN.NM_TURNO + '': '' + CONVERT(VARCHAR(8), CONVERT(TIME,DB_TURN.DT_HORA_INICIAL ), 108) + '' - ''  + CONVERT(VARCHAR(8), CONVERT(TIME,DB_TURN.DT_HORA_FINAL ), 108)+ ''; ''  ';
		SET @SQL_EXEC += '		FROM ';
		SET @SQL_EXEC += '			[Homolog].[dbo].[TB_TURNO_EQUIPE]						DB_TUEQ  ';
		SET @SQL_EXEC += '			JOIN [Homolog].[dbo].[TB_TURNO]						DB_TURN ON DB_TUEQ.ID_TURNO = DB_TURN.ID_TURNO  ';
		SET @SQL_EXEC += '		WHERE ';
		SET @SQL_EXEC += '			DB_TURN.DIA_DE = 2 AND (DB_TURN.DIA_ATE = 5 OR DB_TURN.DIA_ATE = 6) ';
		SET @SQL_EXEC += '			AND DB_EQUI.ID_EQUIPE = DB_TUEQ.ID_EQUIPE), '''') ';
		SET @SQL_EXEC += '	+ ';
		SET @SQL_EXEC += '	ISNULL((';
		SET @SQL_EXEC += '		SELECT ';
		SET @SQL_EXEC += '			DB_TURN.NM_TURNO + '': '' + CONVERT(VARCHAR(8), CONVERT(TIME,DB_TURN.DT_HORA_INICIAL ), 108) + '' - ''  + CONVERT(VARCHAR(8), CONVERT(TIME,DB_TURN.DT_HORA_FINAL ), 108)+ ''; ''  ';
		SET @SQL_EXEC += '		FROM ';
		SET @SQL_EXEC += '			[Homolog].[dbo].[TB_TURNO_EQUIPE]						DB_TUEQ  ';
		SET @SQL_EXEC += '			JOIN [Homolog].[dbo].[TB_TURNO]						DB_TURN ON DB_TUEQ.ID_TURNO = DB_TURN.ID_TURNO  ';
		SET @SQL_EXEC += '		WHERE ';
		SET @SQL_EXEC += '			 DB_TURN.DIA_ATE = 6 ';
		SET @SQL_EXEC += '			AND DB_EQUI.ID_EQUIPE = DB_TUEQ.ID_EQUIPE), '''') ';
		SET @SQL_EXEC += '	+ ';
		SET @SQL_EXEC += '	ISNULL((';
		SET @SQL_EXEC += '		SELECT ';
		SET @SQL_EXEC += '			DB_TURN.NM_TURNO + '': '' + CONVERT(VARCHAR(8), CONVERT(TIME,DB_TURN.DT_HORA_INICIAL ), 108) + '' - ''  + CONVERT(VARCHAR(8), CONVERT(TIME,DB_TURN.DT_HORA_FINAL ), 108)+ ''; ''  ';
		SET @SQL_EXEC += '		FROM ';
		SET @SQL_EXEC += '			[Homolog].[dbo].[TB_TURNO_EQUIPE]						DB_TUEQ  ';
		SET @SQL_EXEC += '			JOIN [Homolog].[dbo].[TB_TURNO]						DB_TURN ON DB_TUEQ.ID_TURNO = DB_TURN.ID_TURNO  ';
		SET @SQL_EXEC += '		WHERE ';
		SET @SQL_EXEC += '			 DB_TURN.DIA_ATE = 7 ';
		SET @SQL_EXEC += '			AND DB_EQUI.ID_EQUIPE = DB_TUEQ.ID_EQUIPE), '''')  AS ''TP_TURNO''';
		SET @SQL_EXEC += '	,DB_USUA.ID_USUARIO';
		SET @SQL_EXEC += '	,DB_USUA.NM_LOGIN';
		SET @SQL_EXEC += '	,DB_HOOF.ID_ANYDESK';
		SET @SQL_EXEC += '	,DB_HOOF.RAMAL_INT';
		SET @SQL_EXEC += '	,DB_HOOF.RAMAL_EXT';
		SET @SQL_EXEC += '	,DB_HOOF.DSEMANA_1';
		SET @SQL_EXEC += '	,DB_HOOF.DSEMANA_2';
		SET @SQL_EXEC += '	,DB_HOOF.DSEMANA_3';
		SET @SQL_EXEC += '	,DB_HOOF.DSEMANA_4';
		SET @SQL_EXEC += '	,DB_HOOF.DSEMANA_5';
		SET @SQL_EXEC += '	,DB_HOOF.DSEMANA_6';
		SET @SQL_EXEC += '	,DB_HOOF.OBS';
		SET @SQL_EXEC += ' FROM';
		SET @SQL_EXEC += '	[Homolog].[dbo].[TB_HOME_OFFICE]									DB_HOOF';
		SET @SQL_EXEC += ' 	JOIN [Homolog].[dbo].[TB_USUARIO]								DB_USUA ON DB_HOOF.ID_USUARIO = DB_USUA.ID_USUARIO';
		SET @SQL_EXEC += '	JOIN [Homolog].[dbo].[TB_EQUIPE]								DB_EQUI ON DB_USUA.ID_EQUIPE = DB_EQUI.ID_EQUIPE';
		SET @SQL_EXEC += ' ORDER BY';
		SET @SQL_EXEC += '	DB_USUA.ID_EQUIPE, DB_USUA.ID_USUARIO';

		--EXEC(@SQL_EXEC);
	/***************************************************************************************************************************************************************************************
	*	- EXCLUIR OS USUARIOS QUE ESTAO BLOQUEADOS.
	***************************************************************************************************************************************************************************************/
		DELETE FROM 
			[Homolog].[dbo].[TB_HOME_OFFICE]
		WHERE
			ID_USUARIO IN (
				SELECT
					DB_HOOF.ID_USUARIO
				FROM 
					[Homolog].[dbo].[TB_HOME_OFFICE]										DB_HOOF
					JOIN [Homolog].[dbo].[TB_USUARIO]									DB_USUA ON DB_HOOF.ID_USUARIO = DB_USUA.ID_USUARIO
				WHERE
					DB_USUA.TP_BLOQUEIO = 1
					AND DB_USUA.NM_INFORMACAO_ADICIONAL IS NULL
			);		
	/***************************************************************************************************************************************************************************************
	*	INSERTE USUARIOS CADASTRADOS NOVOS
	***************************************************************************************************************************************************************************************/
		INSERT INTO [Homolog].[dbo].[TB_HOME_OFFICE](
			ID_USUARIO
		)
		SELECT
			DB_USUA.ID_USUARIO
		FROM 
			[Homolog].[dbo].[TB_USUARIO]										DB_USUA
		WHERE 
			DB_USUA.TP_BLOQUEIO = 0
			AND DB_USUA.NM_LOGIN_CEDENTE IS NOT NULL
			AND DB_USUA.ID_USUARIO NOT IN (SELECT ID_USUARIO  FROM [Homolog].[dbo].[TB_HOME_OFFICE])
			AND DB_USUA.ID_USUARIO NOT IN (1939, 2179);
	/***************************************************************************************************************************************************************************************
	*	- RECUPERA AS INFORMAÇÕES DO OPERADOR CONFORME O DIA DA SEMANA.
	*	@DIA_SEMANA = 2; Segunda-Feira	- DSEMANA_1
	*	@DIA_SEMANA = 3; Terça-Feira	- DSEMANA_2 
	*	@DIA_SEMANA = 4; Quarta-Feira	- DSEMANA_3
	*	@DIA_SEMANA = 5; Quinta-Feira	- DSEMANA_4
	*	@DIA_SEMANA = 6; Sexta-Feira	- DSEMANA_5
	*	@DIA_SEMANA = 7; Sábado			- DSEMANA_6
	*	DSEMANA = 0; NAO ESTA DE HOME
	*	DSEMANA = 1; ESTA DE HOME
	***************************************************************************************************************************************************************************************/
		--SET @HORA_ATUAL= '14:00:00';
		--SET @DATEPART_HORA = 14;	
		--SET @DATEPART_DIA_SEMANA = 7;	
		
		INSERT INTO @TB_HOME_OFFICE(
			ID_USUARIO
			,RAMAL_INT
			,RAMAL_EXT
			,DSEMANA
		)
		SELECT 
			 ID_USUARIO
			,RAMAL_INT
			,RAMAL_EXT
			,(CASE 
				WHEN(	
					CASE
						WHEN @DATEPART_DIA_SEMANA = 2 THEN DSEMANA_1
						WHEN @DATEPART_DIA_SEMANA = 3 THEN DSEMANA_2
						WHEN @DATEPART_DIA_SEMANA = 4 THEN DSEMANA_3
						WHEN @DATEPART_DIA_SEMANA = 5 THEN DSEMANA_4
						WHEN @DATEPART_DIA_SEMANA = 6 THEN DSEMANA_5
						WHEN @DATEPART_DIA_SEMANA = 7 THEN DSEMANA_6
						END
					) = 'S' THEN 1
				ELSE 0
				END
			)
		FROM
			TB_HOME_OFFICE;		
	/***************************************************************************************************************************************************************************************
	*	- @TIPO_ID = 0; Ativa ou desativa os ramais conforme a escala da tabela TB_HOME_OFFICE.
	***************************************************************************************************************************************************************************************/	
		SELECT 
			 @COUNT = COUNT(ID_TURNO)		
		FROM 
			[Homolog].[dbo].[TB_TURNO]
		WHERE 
			@DATEPART_DIA_SEMANA BETWEEN DIA_DE AND DIA_ATE 
			AND 1 = (
				CASE 
					WHEN @DATEPART_HORA < 8 AND DATEPART(HOUR, DT_HORA_INICIAL) -1 = @DATEPART_HORA THEN 1
					WHEN @DATEPART_HORA >= 8 AND DATEPART(HOUR, DT_HORA_INICIAL) = @DATEPART_HORA THEN 1
					END	
			)
			AND 1 = (
				CASE
					WHEN @DATEPART_HORA < 8 AND @HORA_ATUAL BETWEEN CONVERT(TIME, DATEADD(hh, @DATEPART_HORA, DATEADD(mi, 30, DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) AND CONVERT(TIME,DATEADD(hh, @DATEPART_HORA + 1, DATEADD(mi, DATEPART(MINUTE,DT_HORA_INICIAL) + 5, DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) THEN 1
					WHEN @DATEPART_HORA >= 8 AND @HORA_ATUAL BETWEEN CONVERT(TIME, DATEADD(hh, @DATEPART_HORA, DATEADD(mi, DATEPART(MINUTE, DT_HORA_INICIAL), DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) AND CONVERT(TIME,DATEADD(hh, @DATEPART_HORA , DATEADD(mi, DATEPART(MINUTE,DT_HORA_INICIAL) + 5, DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) THEN 1
					END
			);

		IF(@COUNT > 0)BEGIN	
		/***************************************************************************************************************************************************************************************
		*	Retorna os ramais da fastway
		***************************************************************************************************************************************************************************************/
			SET @SQL_EXEC = ' SELECT'; 
			SET @SQL_EXEC += '		 rm.protocolo';
			SET @SQL_EXEC += '		,rm.asterisk_secret';
			SET @SQL_EXEC += '		,rm.ramal_final';
			SET @SQL_EXEC += '		,rm.nat';
			SET @SQL_EXEC += '		,rm.ativo';
			SET @SQL_EXEC += '		,0';
			SET @SQL_EXEC += ' FROM';
			SET @SQL_EXEC += '		public.ramal rm';
			SET @SQL_EXEC += ' WHERE';
			SET @SQL_EXEC += '	mod not in (''''*'''')';
			SET @SQL_EXEC += '	AND rm.protocolo in (''''SIP'''', ''''IAX2'''')';
			SET @SQL_EXEC += '	AND rm.ramal_final between 6100 and 6399';
			SET @SQL_EXEC += '	order by rm.ramal_final';

			INSERT INTO @TB_RAMAL_FAST
			EXEC [__EXEC_OPENROWSET] @CONSULTA_SQL = 'SELECT * ', @CONSULTA_OPENROWSET = @SQL_EXEC, @TIPO = 1 ;
		/***************************************************************************************************************************************************************************************
		*	
		***************************************************************************************************************************************************************************************/
			WHILE(EXISTS(SELECT TOP 1 RAMAL_FAST FROM @TB_RAMAL_FAST WHERE FLAG_RAMAL = 0))BEGIN
				SELECT TOP 1  @RAMAL_INT =  RAMAL_FAST, @RAMAL_ATIVO = RAMAL_ATIVO FROM @TB_RAMAL_FAST WHERE FLAG_RAMAL = 0;
				SET @SQL_EXEC = '';
			/***************************************************************************************************************************************************************************************
			*	- @FLAG_RAMAL = 1; HABILITA RAMAL
			*	- @FLAG_RAMAL = 2; DESABILITA RAMAL
			***************************************************************************************************************************************************************************************/
				SET @FLAG_RAMAL = 2;
			/***************************************************************************************************************************************************************************************
			*	- VERIFICA SE EXISTE ALGUM USUARIO VINCULADO AO RAMAL
			***************************************************************************************************************************************************************************************/
				SELECT 
					@COUNT = COUNT(ID_USUARIO) 
				FROM 
					@TB_HOME_OFFICE 
				WHERE 
					1 = (
						CASE 
							WHEN RAMAL_INT = @RAMAL_INT THEN 1
							WHEN RAMAL_EXT = @RAMAL_INT THEN 1
							ELSE 0
							END
					);
			/***************************************************************************************************************************************************************************************
			*	- SE TIVER RAMAL VINCUADO ATIVA OU INATIVA CONFORME A ESCALA
			***************************************************************************************************************************************************************************************/
				IF(@COUNT > 0) BEGIN

					SELECT TOP 1
						@FLAG_RAMAL = (
							CASE								
							/***************************************************************************************************************************************************************************************
							*	- INTERNO.
							***************************************************************************************************************************************************************************************/
								/*
								*	- Se (DB_HOOF.DSEMANA = 0 e ramal interno(RAMAL_INT = @RAMAL_INT) e ramal ativo(@RAMAL_ATIVO = 1) não faz nada(FLAG_RAMAL = -1) e hora final turno maior que hora atual (DATEPART(HOUR, DT_HORA_FINAL) > @DATEPART_HORA).
								*/
								WHEN DB_HOOF.DSEMANA = 0 AND RAMAL_INT = @RAMAL_INT AND @RAMAL_ATIVO = 1 THEN -1
								/*
								*	- Se DB_HOOF.DSEMANA = 0 e ramal interno(RAMAL_INT = @RAMAL_INT) e ramal inativo(@RAMAL_ATIVO = 0) ativa o ramal(FLAG_RAMAL = 1).
								*/
								WHEN DB_HOOF.DSEMANA = 0 AND RAMAL_INT = @RAMAL_INT AND @RAMAL_ATIVO = 0 THEN 1
								/*
								*	- Se DB_HOOF.DSEMANA = 1 e ramal interno(RAMAL_INT = @RAMAL_INT) e ramal inativo(@RAMAL_ATIVO = 0)  não faz nada(FLAG_RAMAL = -1).
								*/
								WHEN DB_HOOF.DSEMANA = 1 AND RAMAL_INT = @RAMAL_INT AND @RAMAL_ATIVO = 0 THEN -1
								/*
								*	- Se DB_HOOF.DSEMANA = 1 e ramal interno(RAMAL_INT = @RAMAL_INT) e ramal ativo(@RAMAL_ATIVO = 1)  inativa o ramal(FLAG_RAMAL = -1).
								*/
								WHEN DB_HOOF.DSEMANA = 1 AND RAMAL_INT = @RAMAL_INT AND @RAMAL_ATIVO = 1 THEN 2
							/***************************************************************************************************************************************************************************************
							*	- EXTERNO.
							***************************************************************************************************************************************************************************************/
								/*
								*	- Se DB_HOOF.DSEMANA = 1 e ramal externo(RAMAL_EXT = @RAMAL_INT) e ramal ativo(@RAMAL_ATIVO = 1) não faz nada(FLAG_RAMAL = -1).
								*/
								WHEN DB_HOOF.DSEMANA = 1 AND RAMAL_EXT = @RAMAL_INT AND @RAMAL_ATIVO = 1 THEN -1
								/*
								*	- Se DB_HOOF.DSEMANA = 1 e ramal externo(RAMAL_EXT = @RAMAL_INT) e ramal inativo(@RAMAL_ATIVO = 1) ativa o ramal(@FLAG_RAMAL = 1).
								*/
								WHEN DB_HOOF.DSEMANA = 1 AND RAMAL_EXT = @RAMAL_INT AND @RAMAL_ATIVO = 0 THEN 1
								/*
								*	- Se DB_HOOF.DSEMANA = 0 e ramal externo(RAMAL_EXT = @RAMAL_INT) e ramal inativo(@RAMAL_ATIVO = 1) não faz nada(FLAG_RAMAL = -1).
								*/
								WHEN DB_HOOF.DSEMANA = 0 AND RAMAL_EXT = @RAMAL_INT AND @RAMAL_ATIVO = 0 THEN -1
								/*
								*	- Se DB_HOOF.DSEMANA = 0 e ramal externo(RAMAL_EXT = @RAMAL_INT) e ramal inativo(@RAMAL_ATIVO = 1) não faz nada(FLAG_RAMAL = -1).
								*/
								WHEN DB_HOOF.DSEMANA = 0 AND RAMAL_EXT = @RAMAL_INT AND @RAMAL_ATIVO = 1 THEN 2
								ELSE 2
								END
						)
					FROM 
						@TB_HOME_OFFICE										DB_HOOF 
						JOIN [Homolog].[dbo].[TB_USUARIO]				DB_USUA ON DB_HOOF.ID_USUARIO = DB_USUA.ID_USUARIO
						JOIN [Homolog].[dbo].[TB_EQUIPE]				DB_EQUI ON DB_USUA.ID_EQUIPE = DB_EQUI.ID_EQUIPE
						JOIN [Homolog].[dbo].[TB_TURNO_EQUIPE]		DB_TUEQ ON DB_EQUI.ID_EQUIPE = DB_TUEQ.ID_EQUIPE
						JOIN [Homolog].[dbo].[TB_TURNO]				DB_TURN ON DB_TUEQ.ID_TURNO = DB_TURN.ID_TURNO
					WHERE 
						1 = (
							CASE 
								WHEN RAMAL_INT = @RAMAL_INT THEN 1
								WHEN RAMAL_EXT = @RAMAL_INT THEN 1
								ELSE 0
								END
							)
						AND @DATEPART_DIA_SEMANA BETWEEN DB_TURN.DIA_DE AND DB_TURN.DIA_ATE 
						AND 1 = (
							CASE
								WHEN 
									@DATEPART_HORA < 8 
									AND @HORA_ATUAL BETWEEN 
														CONVERT(TIME, DATEADD(hh, @DATEPART_HORA, DATEADD(mi, 30, DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) 
														AND CONVERT(TIME, DATEADD(hh, DATEPART(HOUR,DT_HORA_FINAL) -1, DATEADD(mi, 59, DATEADD(ss, 59, DATEDIFF(dd, 0, DT_HORA_FINAL))))) 
								THEN 1
								WHEN 
									@DATEPART_HORA >= 8 
									AND @HORA_ATUAL BETWEEN 
														CONVERT(TIME, DATEADD(hh, DATEPART(HOUR,DT_HORA_INICIAL), DATEADD(mi, DATEPART(MINUTE, DT_HORA_INICIAL), DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) 
														AND CONVERT(TIME, DATEADD(hh, DATEPART(HOUR,DT_HORA_FINAL) -1, DATEADD(mi, 59, DATEADD(ss, 59, DATEDIFF(dd, 0, DT_HORA_FINAL))))) THEN 1
								END
						);	

					/*SELECT TOP 1
						DB_HOOF.*
						,DB_TURN.*
						,CONVERT(TIME, DATEADD(hh, @DATEPART_HORA, DATEADD(mi, 30, DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL)))))
					FROM 
						@TB_HOME_OFFICE										DB_HOOF 
						JOIN [Homolog].[dbo].[TB_USUARIO]				DB_USUA ON DB_HOOF.ID_USUARIO = DB_USUA.ID_USUARIO
						JOIN [Homolog].[dbo].[TB_EQUIPE]				DB_EQUI ON DB_USUA.ID_EQUIPE = DB_EQUI.ID_EQUIPE
						JOIN [Homolog].[dbo].[TB_TURNO_EQUIPE]		DB_TUEQ ON DB_EQUI.ID_EQUIPE = DB_TUEQ.ID_EQUIPE
						JOIN [Homolog].[dbo].[TB_TURNO]				DB_TURN ON DB_TUEQ.ID_TURNO = DB_TURN.ID_TURNO
					WHERE 
						1 = (
							CASE 
								WHEN RAMAL_INT = @RAMAL_INT THEN 1
								WHEN RAMAL_EXT = @RAMAL_INT THEN 1
								ELSE 0
								END
							)
						AND @DATEPART_DIA_SEMANA BETWEEN DB_TURN.DIA_DE AND DB_TURN.DIA_ATE 
						AND 1 = (
							CASE
								WHEN 
									@DATEPART_HORA < 8 
									AND @HORA_ATUAL BETWEEN 
														CONVERT(TIME, DATEADD(hh, @DATEPART_HORA, DATEADD(mi, 30, DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) 
														AND CONVERT(TIME, DATEADD(hh, DATEPART(HOUR,DT_HORA_FINAL) -1, DATEADD(mi, 59, DATEADD(ss, 59, DATEDIFF(dd, 0, DT_HORA_FINAL))))) 
								THEN 1
								WHEN 
									@DATEPART_HORA >= 8 
									AND @HORA_ATUAL BETWEEN 
														CONVERT(TIME, DATEADD(hh, DATEPART(HOUR,DT_HORA_INICIAL), DATEADD(mi, DATEPART(MINUTE, DT_HORA_INICIAL), DATEADD(ss, 00, DATEDIFF(dd, 0, DT_HORA_INICIAL))))) 
														AND CONVERT(TIME, DATEADD(hh, DATEPART(HOUR,DT_HORA_FINAL) -1, DATEADD(mi, 59, DATEADD(ss, 59, DATEDIFF(dd, 0, DT_HORA_FINAL))))) THEN 1
								END
						);	*/
				END;
				IF(@FLAG_RAMAL = 2 AND @RAMAL_ATIVO = 0) BEGIN
					SET @FLAG_RAMAL = -1;
				END

				IF(@FLAG_RAMAL > 0) BEGIN
					SET @SQL_EXEC = 'SELECT _fnc_ramal_escala(' + CONVERT(VARCHAR(10), @RAMAL_INT) + ',' + CONVERT(VARCHAR(10), @FLAG_RAMAL) + ')';
				END;				

				IF(LEN(LTRIM(RTRIM(@SQL_EXEC))) > 0)BEGIN
					INSERT INTO @TB_RET_RAMAL 
					EXEC [__EXEC_OPENROWSET] @CONSULTA_SQL = 'SELECT * ', @CONSULTA_OPENROWSET = @SQL_EXEC, @TIPO = 1 ;
					SELECT @SQL_EXEC
				END

				UPDATE @TB_RAMAL_FAST SET FLAG_RAMAL = @FLAG_RAMAL WHERE RAMAL_FAST = @RAMAL_INT;
			END;

			IF((SELECT COUNT(RAMAL_FAST) FROM @TB_RAMAL_FAST WHERE FLAG_RAMAL > 0) > 0)BEGIN

				SET @BODY_CABECALHO_HTML = N'<H2 style="text-align:center;width: 1400px;"> Resumo de alteração de ramal </H2>';
				SET @BODY_CORPO_HTML = ''
				SET @BODY_CORPO_HTML += ' <table> ';
				SET @BODY_CORPO_HTML += '     <caption><H3>Ramais alterados.</H3></caption> ';
				SET @BODY_CORPO_HTML += '     <thead> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <th>Ramal</th> ';
				SET @BODY_CORPO_HTML += '             <th>Status</th> ';
				SET @BODY_CORPO_HTML += '             <th>ID Usuario</th> ';
				SET @BODY_CORPO_HTML += '             <th>Nome Usuario</th> ';
				SET @BODY_CORPO_HTML += '             <th>Equipe</th> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </thead> ';
				SET @BODY_CORPO_HTML += '     <tbody> ';
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT
													td = DB_RAMA.RAMAL_FAST, '',
													td = (CASE WHEN DB_RAMA.FLAG_RAMAL = 1 THEN 'ATIVO' WHEN DB_RAMA.FLAG_RAMAL = 2 THEN 'INATIVO' ELSE '' END), '',
													td = DB_USUA.ID_USUARIO, '',
													td = DB_USUA.NM_USUARIO, '',
													td = DB_EQUI.NM_EQUIPE, ''
												FROM 
													@TB_HOME_OFFICE										DB_HOOF 
													JOIN [Homolog].[dbo].[TB_USUARIO]				DB_USUA ON DB_HOOF.ID_USUARIO = DB_USUA.ID_USUARIO
													JOIN [Homolog].[dbo].[TB_EQUIPE]				DB_EQUI ON DB_USUA.ID_EQUIPE = DB_EQUI.ID_EQUIPE
													,@TB_RAMAL_FAST										DB_RAMA 
												WHERE 
													DB_RAMA.FLAG_RAMAL > 0
													AND (DB_HOOF.RAMAL_INT = DB_RAMA.RAMAL_FAST OR DB_HOOF.RAMAL_EXT = DB_RAMA.RAMAL_FAST)
												ORDER BY
													DB_RAMA.RAMAL_FAST
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);		
				SET @BODY_CORPO_HTML += '     </tbody> ';
				SET @BODY_CORPO_HTML += ' </table> ';
				SET @BODY_CORPO_HTML += ' <br/><br/> ';		
		
				IF(LEN(LTRIM(RTRIM(@BODY_CORPO_HTML))) > 0) BEGIN
					SET @BODY_ENVIO_HTML =  @BODY_CABECALHO_HTML + @BODY_CORPO_HTML ;			
				END;	
				IF(LEN(LTRIM(RTRIM(@BODY_ENVIO_HTML))) > 0) BEGIN
			
					INSERT INTO  TB_EMAIL_ENVIO(
						EMAIL_ENVIO_PROFILE_NAME
						,EMAIL_ENVIO_RECIPIENTES
						,EMAIL_ENVIO_CP_RECIPIENTES
						,EMAIL_ENVIO_SUBJECT
						,EMAIL_ENVIO_BODY
						,EMAIL_ENVIO_BODY_FORMAT
						,EMAIL_ENVIO_IMPORTANCE
					)
					SELECT
						'EmailHomolog'
						,'suporte@Homolog.com.br'
						,'wanderlei.silva@Homolog.com.br;anderson.andrade@Homolog.com.br;'
						--,'anderson.andrade@Homolog.com.br;'
						,@SUBJECT
						,@BODY_ENVIO_HTML
						,'HTML'
						,'High'
				END;		
				EXEC [dbo].[_PROC_ENVIO_EMAIL];
			END;
		END;		
		EXEC(@SQL_EXEC);

	END TRY 
	BEGIN CATCH  
		SELECT 
			@ERROR_NUMBER_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_NUMBER()), '')
			,@ERROR_SEVERITY_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_SEVERITY()), '')
			,@ERROR_STATE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_STATE()), '')
			,@ERROR_PROCEDURE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_PROCEDURE()), '')
			,@ERROR_LINE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_LINE()), '')
			,@ERROR_MESSAGE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_MESSAGE()), '');
	
		EXEC [dbo].[__PROC_SQL_ERROR_EMAIL]
			@ERROR_NUMBER = @ERROR_NUMBER_AUX
			,@ERROR_SEVERITY = @ERROR_SEVERITY_AUX
			,@ERROR_STATE = @ERROR_STATE_AUX
			,@ERROR_PROCEDURE = @ERROR_PROCEDURE_AUX
			,@ERROR_LINE = @ERROR_LINE_AUX
			,@ERROR_MESSAGE = @ERROR_MESSAGE_AUX;
		EXEC [dbo].[_PROC_ENVIO_EMAIL];
	END CATCH; 
END;