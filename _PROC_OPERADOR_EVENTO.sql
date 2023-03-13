USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_OPERADOR_EVENTO', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_OPERADOR_EVENTO]
GO

/****** Object:  StoredProcedure [dbo].[_PROC_OPERADOR_EVENTO]    Script Date: 31/08/2021 11:08:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_OPERADOR_EVENTO(
	@TIPO_ID							BIGINT = 0
	,@DATA								DATETIME = ''
) 
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 05/10/2022	
	*	DESCRIÇÃO.: Procedure consulta da escala de home office e update na tabela de ramais da fastway
	***************************************************************************************************************************************************************************************/	
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_FAST										VARCHAR(MAX);
	DECLARE @SQL_FAST_RET									VARCHAR(MAX) = 'SELECT *';
	/**************************************************************************************************************************************************************************************/
	DECLARE @TB_OPERADOR_LOGIN_FAST							TABLE(
																LOGIN_FAST_NS 					BIGINT ,
																LOGIN_FAST_ID					BIGINT NOT NULL DEFAULT 0,
																LOGIN_FAST_LOGON				VARCHAR(50) NOT NULL DEFAULT '',
																LOGIN_FAST_DT_INI				DATETIME DEFAULT NULL,
																LOGIN_FAST_DT_PNG				DATETIME DEFAULT NULL,
																LOGIN_FAST_RAMAL				VARCHAR(10) NOT NULL DEFAULT ''
															);
	DECLARE @TB_OPERADOR_EVENTO_FAST						TABLE(
																EVENTO_FAST_ID					BIGINT,
																EVENTO_FAST_OPER_ID				BIGINT ,
																EVENTO_FAST_EVENTO				VARCHAR(30),
																EVENTO_FAST_DT_INI				DATETIME DEFAULT NULL,
																EVENTO_FAST_DT_FIM				DATETIME DEFAULT NULL,
																EVENTO_FAST_DAC					VARCHAR(100),
																EVENTO_FAST_COMP				VARCHAR(100),
																EVENTO_FAST_SUB_EVENTO			VARCHAR(100),
																EVENTO_FAST_OPER_GRP_ID			BIGINT,
																EVENTO_FAST_PAUSA_ID			BIGINT,
																EVENTO_FAST_TABULACAO_ID		BIGINT 
															);
	/**************************************************************************************************************************************************************************************/
	DECLARE @LOGIN_FAST_ID									BIGINT = 0;
	DECLARE @LOGIN_FAST_LOGON						VARCHAR(50) = '';
	DECLARE @LOGIN_FAST_DT_INI						DATETIME;
	DECLARE @LOGIN_FAST_DT_PNG						DATETIME;
	DECLARE @LOGIN_FAST_RAMAL						VARCHAR(50) = '';
	DECLARE @ID_USUARIO										BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @DATEPART_HORA									INT = 0;
	DECLARE @AUX_INT										BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @OPERADOR_DAYLING_NS 							BIGINT = 0;
	DECLARE @DAYLING_HORA 									TIME = '';
	DECLARE @DAYLING_QTD_CLIE_TRAB 							BIGINT = 0;
	DECLARE @DAYLING_VLR_CLIE_TRAB 							NUMERIC(18,2) = 0;
	DECLARE @DAYLING_QTD_LIG		 						BIGINT = 0;
	DECLARE @DAYLING_QTD_ALO		 						BIGINT = 0;
	DECLARE @DAYLING_QTD_CPC		 						BIGINT = 0;
	DECLARE @DAYLING_QTD_CPCA	 							BIGINT = 0;
	DECLARE @DAYLING_QTD_ACORDO	 							BIGINT = 0;
	DECLARE @DAYLING_VLR_ACORDO 							NUMERIC(18,2) = 0;
	DECLARE @DAYLING_QTD_ACORDO_PGTO						BIGINT = 0;
	DECLARE @DAYLING_VLR_ACORDO_PGTO 						NUMERIC(18,2) = 0;
	DECLARE @DAYLING_QTD_ACW								BIGINT = 0;
	DECLARE @DAYLING_QTD_TEMPO_FALADO						BIGINT = 0;
	DECLARE @DAYLING_QTD_TEMPO_PAUSA						BIGINT = 0;
	DECLARE @DAYLING_QTD_TEMPO_CONT							BIGINT = 0; /* PAUSA CONTRATADA */
	DECLARE @DAYLING_QTD_TEMPO_AVAIL						BIGINT = 0;
	DECLARE @DAYLING_MEDIA_CHAMADAS							BIGINT = 0;
	DECLARE @DAYLING_TMA									BIGINT = 0; /* TEMPO MEDIO ATENDIMENTO*/
	DECLARE @DAYLING_AM_EMAIL								BIGINT = 0;
	DECLARE @DAYLING_AM_BOLETO								BIGINT = 0;
	DECLARE @DAYLING_AA_NUMERO_N_EXISTE						BIGINT = 0;
	DECLARE @DAYLING_AA_CAIXA_POSTAL						BIGINT = 0;
	DECLARE @DAYLING_AA_LIGACAO_MUDA						BIGINT = 0;
	DECLARE @DAYLING_AA_SINAL_FAX							BIGINT = 0;
	DECLARE @DAYLING_AA_N_ATENDEU							BIGINT = 0;
	DECLARE @DAYLING_AA_HANGUP								BIGINT = 0;
	DECLARE @DAYLING_AA_OCUPADO								BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_ERROR										VARCHAR(MAX) = ''; 
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY 	
	/***************************************************************************************************************************************************************************************
	*	- DATA E HORA; SETA OS PARAMETROS DE DATA E HORA
	***************************************************************************************************************************************************************************************/
		IF(@DATA = '1900-01-01 00:00:00.000')BEGIN
			SET @DATA= GETDATE();
		END;

		SET @DATEPART_HORA = DATEPART(HOUR, @DATA) - 1;		
		SET @DAYLING_HORA = DATEADD(hh, @DATEPART_HORA, DATEADD(mi, 00, DATEADD(ss, 00, DATEDIFF(dd, 0, @DATA))));
		--SELECT @DAYLING_HORA as '@DAYLING_HORA', @DATEPART_HORA as '@DATEPART_HORA', DATEADD(hh, @DATEPART_HORA, DATEADD(mi, 00, DATEADD(ss, 00, DATEDIFF(dd, 0, @DATA))));
	/***************************************************************************************************************************************************************************************
	*	- __TB_CALL_HISTORY; VERIFICA SE EXISTE REGISTRO NA TABELA
	***************************************************************************************************************************************************************************************/
		IF(@DATEPART_HORA = 8) BEGIN
			DELETE FROM __TB_CALL_HISTORY
		END ELSE BEGIN
			DELETE FROM __TB_CALL_HISTORY WHERE DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) <= (@DATEPART_HORA - 1);	
		END;
		SELECT
			@AUX_INT = COUNT(CALL_HISTORY_ID)
		FROM
			__TB_CALL_HISTORY
		WHERE
			(DATEPART(HOUR, CALL_HORA_ENCERRAMENTO)) = (@DATEPART_HORA);
	/***************************************************************************************************************************************************************************************
	*	PEGA AS INFORMAÇÕES DO OPERADOR NA FASTWAY
	***************************************************************************************************************************************************************************************/
		IF(@TIPO_ID = 0)BEGIN
			-- Ao finalizar a proc comentar a linha abaixo
			/*DELETE FROM [Homolog].[dbo].[TB_OPERADOR_DAYLING]
			DBCC CHECKIDENT (TB_OPERADOR_DAYLING, RESEED, 0)*/
		/***************************************************************************************************************************************************************************************
		*	PEGA AS INFORMAÇÕES DOS EVENTOS
		***************************************************************************************************************************************************************************************/
			SET @SQL_FAST  = '';
			SET @SQL_FAST += ' SELECT ';
			SET @SQL_FAST += '	 db_opev.id';
			SET @SQL_FAST += '	,db_opev.operador_id';
			SET @SQL_FAST += '	,db_opev.evento';
			SET @SQL_FAST += '	,db_opev.hora_evento';
			SET @SQL_FAST += '	,db_opev.hora_fim_evento';
			SET @SQL_FAST += '	,db_opev.dac_resultado';
			SET @SQL_FAST += '	,db_opev.complemento';
			SET @SQL_FAST += '	,db_opev.sub_evento';
			SET @SQL_FAST += '	,db_opev.grupo_operador_id';
			SET @SQL_FAST += '	,db_opev.pausa_id';
			SET @SQL_FAST += '	,db_opev.tabulacao_id';
			SET @SQL_FAST += ' FROM';
			SET @SQL_FAST += '	public.operador_evento db_opev';
			SET @SQL_FAST += ' WHERE';
			SET @SQL_FAST += '	DATE(db_opev.hora_evento) = ''''' + CONVERT(VARCHAR(10), CONVERT(DATE, @DATA)) + '''''';	
			SET @SQL_FAST += '	AND db_opev.hora_fim_evento IS NOT NULL';

			INSERT INTO @TB_OPERADOR_EVENTO_FAST 
			EXEC [__EXEC_OPENROWSET] @CONSULTA_SQL = @SQL_FAST_RET, @CONSULTA_OPENROWSET = @SQL_FAST, @TIPO = 1 ;
		/***************************************************************************************************************************************************************************************
		*	PEGA AS INFORMAÇÕES DOS EVENTOS
		***************************************************************************************************************************************************************************************/
			SET @SQL_FAST = ' SELECT ';
			SET @SQL_FAST += '	db_call.id';
			SET @SQL_FAST += '	,db_call.inicio';
			SET @SQL_FAST += '	,db_call.status';
			SET @SQL_FAST += '	,db_call.fone';
			SET @SQL_FAST += '	,db_call.dac_operador_id';
			SET @SQL_FAST += '	,db_call.hora_atendida';
			SET @SQL_FAST += '	,db_call.resultado';
			SET @SQL_FAST += '	,db_call.status_complemento';
			SET @SQL_FAST += '	,db_call.hora_encerramento';
			SET @SQL_FAST += '	,db_call.hora_espera';
			SET @SQL_FAST += '	,db_call.chave';
			SET @SQL_FAST += '	,db_call.hora_finalizacao';
			SET @SQL_FAST += '	,db_call.tabulacao_id';
			SET @SQL_FAST += '	,db_call.fone_cliente';
			SET @SQL_FAST += ' FROM ';
			SET @SQL_FAST += '	public.call_history db_call ';
			SET @SQL_FAST += ' WHERE '
			SET @SQL_FAST += '	 DATE(db_call.inicio)  = ''''' + CONVERT(VARCHAR(10), @DATA, 112) + '''''';	
			SET @SQL_FAST += '	 AND db_call.dac_operador_id IS NOT NULL';
			SET @SQL_FAST += '	 AND (EXTRACT (HOUR FROM db_call.hora_encerramento)) = ' + CONVERT(VARCHAR(2), @DATEPART_HORA);	
		
			IF(@AUX_INT = 0)BEGIN
				INSERT INTO __TB_CALL_HISTORY 
				EXEC [__EXEC_OPENROWSET] @CONSULTA_SQL = @SQL_FAST_RET, @CONSULTA_OPENROWSET = @SQL_FAST, @TIPO = 1 ;
			END;
		/***************************************************************************************************************************************************************************************
		*	PEGA AS INFORMAÇÕES DOS EVENTOS
		***************************************************************************************************************************************************************************************/
			INSERT INTO @TB_OPERADOR_LOGIN_FAST(
				LOGIN_FAST_NS
				,LOGIN_FAST_ID
			)
			SELECT
				LOGIN_FAST_NS
				,LOGIN_FAST_ID
			FROM
				TB_OPERADOR_LOGIN_FAST
			WHERE
				CONVERT(DATE, LOGIN_FAST_DT_INI) = CONVERT(DATE, @DATA)
				AND @DATEPART_HORA >= DATEPART(HOUR, LOGIN_FAST_DT_INI);
		/***************************************************************************************************************************************************************************************
		*	PEGA AS INFORMAÇÕES DOS EVENTOS
		***************************************************************************************************************************************************************************************/	
			WHILE(EXISTS(SELECT TOP 1 LOGIN_FAST_ID FROM @TB_OPERADOR_LOGIN_FAST ))BEGIN
				SELECT TOP 1 
					 @LOGIN_FAST_ID = LOGIN_FAST_ID 
					,@LOGIN_FAST_LOGON = LOGIN_FAST_LOGON
				FROM 
					@TB_OPERADOR_LOGIN_FAST;
		/***************************************************************************************************************************************************************************************
		*	- @ID_USUARIO: RECUPERA O ID DO USUARIO
		***************************************************************************************************************************************************************************************/
				SELECT 
					@ID_USUARIO = ISNULL(ID_USUARIO, 0)
				FROM
					[Homolog].[dbo].[TB_USUARIO]									DB_USUA
				WHERE
					DB_USUA.NM_LOGIN_DISCADOR = CONVERT(VARCHAR(20), @LOGIN_FAST_ID);
		/***************************************************************************************************************************************************************************************
		*	
		***************************************************************************************************************************************************************************************/
				IF(@ID_USUARIO > 0) BEGIN
				/***************************************************************************************************************************************************************************************
				*	- RECUPERA O NS DA TABELA DAYLING
				***************************************************************************************************************************************************************************************/
					SELECT 
						@OPERADOR_DAYLING_NS = ISNULL(OPERADOR_DAYLING_NS, 0) 
					FROM 
						TB_OPERADOR_DAYLING 
					WHERE 
						LOGIN_FAST_ID =  @LOGIN_FAST_ID 
						AND CONVERT(DATE, DAYLING_DATA) = CONVERT(DATE, @DATA)
						AND DAYLING_HORA = @DAYLING_HORA;		
				/***************************************************************************************************************************************************************************************
				*	- CLI_TRAB_QTD: Quantidade de registros trabalhados.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_QTD_CLIE_TRAB = ISNULL(COUNT(DB_CLAC.ID_CLIENTE_ACAO), 0)
					FROM 
						[Homolog].[dbo].[TB_CLIENTE_ACAO]									DB_CLAC
					WHERE					
						CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, @DATA)
						AND DATEPART(HOUR, DB_CLAC.DT_ACAO) = (@DATEPART_HORA)
						AND DB_CLAC.ID_USUARIO = @ID_USUARIO
						AND DB_CLAC.ID_CLIENTE NOT IN (SELECT CALL_CHAVE FROM __TB_CALL_HISTORY WHERE LEN(LTRIM(RTRIM(ISNULL(CALL_CHAVE, '')))) > 0 AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA));

					SELECT 
						@DAYLING_QTD_CLIE_TRAB += COUNT(CALL_CHAVE) 
					FROM 
						__TB_CALL_HISTORY 
					WHERE 
						LEN(LTRIM(RTRIM(ISNULL(CALL_CHAVE, '')))) > 0 
						AND CALL_OPERADOR_ID = @LOGIN_FAST_ID 
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);
				/***************************************************************************************************************************************************************************************
				*	- CLI_TRAB_VLR: Valor financeiro de registros trabalhados.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_VLR_CLIE_TRAB = ISNULL(SUM(DB_DIVI.VL_DIVIDA), 0)				
					FROM 
						[Homolog].[dbo].[TB_CLIENTE_ACAO]									DB_CLAC
						JOIN [Homolog].[dbo].[TB_CONTRATO]								DB_CONT ON DB_CLAC.ID_CLIENTE = DB_CONT.ID_CLIENTE
						JOIN [Homolog].[dbo].[TB_DIVIDA]									DB_DIVI ON DB_CONT.ID_CONTRATO = DB_DIVI.ID_CONTRATO
					WHERE					
						CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, @DATA)
						AND DATEPART(HOUR, DB_CLAC.DT_ACAO) = (@DATEPART_HORA)
						AND DB_CLAC.ID_USUARIO = @ID_USUARIO;
				/***************************************************************************************************************************************************************************************
				*	- QTD_LIG: Quantidade de ligações entregue na PA.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_QTD_LIG = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO NOT IN( 'DESLIGADO DURANTE DETECCAO')
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;
				/***************************************************************************************************************************************************************************************
				*	- QTD_ALO: Quantidade de ligações produtivas (Alô).
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_QTD_ALO = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%ATENDIDA%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;
				/***************************************************************************************************************************************************************************************
				*	- QTD_ACPC: Quantidade de ligações com o cliente (CPC).
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_QTD_CPC = ISNULL(COUNT(DB_CLAC.ID_CLIENTE_ACAO), 0)				
					FROM 
						[Homolog].[dbo].[TB_CLIENTE_ACAO]									DB_CLAC
						JOIN [Homolog].[dbo].[_ACAO_TIPO]									DB_ACTI ON DB_CLAC.ID_ACAO = DB_ACTI.ID_ACAO
					WHERE					
						CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, @DATA)
						AND DATEPART(HOUR, DB_CLAC.DT_ACAO) = (@DATEPART_HORA)
						AND DB_CLAC.ID_USUARIO = @ID_USUARIO
						AND DB_ACTI.NM_TIPO = 'CPC';
				/***************************************************************************************************************************************************************************************
				*	- QTD_ACPCA: Quantidade de ligações com o cliente decisor (CPCA).
				***************************************************************************************************************************************************************************************/
					SET @DAYLING_QTD_CPCA = 0;
				/***************************************************************************************************************************************************************************************
				*	- QTD_ACORD: Quantidade de acordos realizados.
				*	- VLR_ACORDO: Valor de acordos realizados
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_QTD_ACORDO = ISNULL(COUNT(DB_ACDI.ID_ACORDO), 0)	
						,@DAYLING_VLR_ACORDO = ISNULL(SUM(DB_ACDI.VL_DIVIDA), 0)				
					FROM 
							[Homolog].[dbo].[TB_ACORDO]									DB_ACOR
						JOIN [Homolog].[dbo].[TB_ACORDO_DIVIDA]							DB_ACDI ON DB_ACOR.ID_ACORDO = DB_ACDI.ID_ACORDO
					WHERE					
						CONVERT(DATE, DB_ACOR.DT_ACORDO) = CONVERT(DATE, @DATA)
						AND DATEPART(HOUR, DB_ACOR.DT_ACORDO) = (@DATEPART_HORA)
						AND DB_ACOR.ID_USUARIO = @ID_USUARIO
						AND DB_ACOR.TP_STATUS = 0;
				/***************************************************************************************************************************************************************************************
				*	- QTD_ACORDO_PGTO: Quantidade de acordos pagos.
				*	- VLR_ACORDO_PGTO: Valor de acordos pagos.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_QTD_ACORDO_PGTO = ISNULL(COUNT(DB_ACDI.ID_ACORDO), 0)	
						,@DAYLING_VLR_ACORDO_PGTO = ISNULL(SUM(DB_ACDI.VL_DIVIDA), 0)				
					FROM 
							[Homolog].[dbo].[TB_ACORDO]									DB_ACOR
						JOIN [Homolog].[dbo].[TB_ACORDO_DIVIDA]							DB_ACDI ON DB_ACOR.ID_ACORDO = DB_ACDI.ID_ACORDO
					WHERE					
						CONVERT(DATE, DB_ACOR.DT_ACORDO) = CONVERT(DATE, @DATA)
						AND DATEPART(HOUR, DB_ACOR.DT_ACORDO) = (@DATEPART_HORA)
						AND DB_ACOR.ID_USUARIO = @ID_USUARIO
						AND DB_ACOR.TP_STATUS = 2;
				/***************************************************************************************************************************************************************************************
				*	- ACW: Tempo médio de Pós Atendimento.
				***************************************************************************************************************************************************************************************/
					SELECT 
						@DAYLING_QTD_ACW = ISNULL(SUM(DATEDIFF(SECOND, ISNULL(EVENTO_FAST_DT_INI, 0) , ISNULL(EVENTO_FAST_DT_FIM, 0))), 0)
					FROM 
						@TB_OPERADOR_EVENTO_FAST 
					WHERE 
						EVENTO_FAST_OPER_ID = @LOGIN_FAST_ID 
						AND EVENTO_FAST_EVENTO = 'FINALIZACAO'
						AND DATEPART(HOUR, EVENTO_FAST_DT_FIM) = @DATEPART_HORA;
				/***************************************************************************************************************************************************************************************
				*	- QTD_TEMPO_FALADO: Tempo  Falado.
				***************************************************************************************************************************************************************************************/
					SELECT 
						@DAYLING_QTD_TEMPO_FALADO = ISNULL(SUM(DATEDIFF(SECOND, ISNULL(EVENTO_FAST_DT_INI, 0) , ISNULL(EVENTO_FAST_DT_FIM, 0))), 0)
					FROM 
						@TB_OPERADOR_EVENTO_FAST 
					WHERE 
						EVENTO_FAST_OPER_ID = @LOGIN_FAST_ID 
						AND EVENTO_FAST_EVENTO = 'DAC'
						AND DATEPART(HOUR, EVENTO_FAST_DT_FIM) = @DATEPART_HORA;
				/***************************************************************************************************************************************************************************************
				*	- QTD_TEMPO_PAUSA: Tempo demais pausas (Treinamento + Outros).
				***************************************************************************************************************************************************************************************/
					SELECT 
						@DAYLING_QTD_TEMPO_PAUSA = ISNULL(SUM(DATEDIFF(SECOND, ISNULL(EVENTO_FAST_DT_INI, 0) , ISNULL(EVENTO_FAST_DT_FIM, 0))), 0)
					FROM 
						@TB_OPERADOR_EVENTO_FAST 
					WHERE 
						EVENTO_FAST_OPER_ID = @LOGIN_FAST_ID 
						AND EVENTO_FAST_EVENTO = 'PAUSA'
						AND EVENTO_FAST_PAUSA_ID NOT IN (3, 6)
						AND DATEPART(HOUR, EVENTO_FAST_DT_FIM) = @DATEPART_HORA;
				/***************************************************************************************************************************************************************************************
				*	- QTD_TEMPO_CONT: Tempo pausa Contratuais NR17 (meta 00:40:00). 666
				***************************************************************************************************************************************************************************************/
					SELECT 
						@DAYLING_QTD_TEMPO_CONT = ISNULL(SUM(DATEDIFF(SECOND, 
							(CASE
								WHEN ISNULL(EVENTO_FAST_DT_INI, 0) = 0 THEN 0								
								WHEN DATEPART(HOUR, EVENTO_FAST_DT_INI) < @DATEPART_HORA THEN DATEADD(hh, @DATEPART_HORA, DATEADD(mi, 00, DATEADD(ss, 00, DATEDIFF(dd, 0, @DATA))))
								ELSE EVENTO_FAST_DT_INI
								END)
							,(CASE
								WHEN ISNULL(EVENTO_FAST_DT_FIM, 0) = 0 THEN DATEADD(hh, @DATEPART_HORA + 1, DATEADD(mi, 00, DATEADD(ss, 00, DATEDIFF(dd, 0, @DATA))))
								ELSE EVENTO_FAST_DT_FIM
								END)						 
						 )), 0)
					FROM 
						@TB_OPERADOR_EVENTO_FAST 
					WHERE 
						EVENTO_FAST_OPER_ID = @LOGIN_FAST_ID 
						AND EVENTO_FAST_EVENTO = 'PAUSA'
						AND EVENTO_FAST_PAUSA_ID IN (3, 6)						
						AND DATEPART(HOUR, EVENTO_FAST_DT_INI) = @DATEPART_HORA;
				/***************************************************************************************************************************************************************************************
				*	- QTD_TEMPO_AVAI: Tempo Ocioso entre Chamadas.
				***************************************************************************************************************************************************************************************/
					SELECT 
						@DAYLING_QTD_TEMPO_AVAIL = ISNULL(SUM(DATEDIFF(SECOND, ISNULL(EVENTO_FAST_DT_INI, 0) , ISNULL(EVENTO_FAST_DT_FIM, 0))), 0)
					FROM 
						@TB_OPERADOR_EVENTO_FAST 
					WHERE 
						EVENTO_FAST_OPER_ID = @LOGIN_FAST_ID 
						AND EVENTO_FAST_EVENTO = 'ESPERA'
						AND DATEPART(HOUR, EVENTO_FAST_DT_FIM) = @DATEPART_HORA;
				/***************************************************************************************************************************************************************************************
				*	- MEDIA_CHAMADA: Média de chamadas por operador (meta mínimo 100 chamadas).
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_MEDIA_CHAMADAS = ISNULL(AVG(DATEDIFF(SECOND, ISNULL(CALL_HORA_ATENDIDA, 0) , ISNULL(CALL_HORA_ENCERRAMENTO, CALL_HORA_FINALIZACAO))), 0) 
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%ATENDIDA%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA)
						AND CALL_HORA_ATENDIDA IS NOT NULL;
				/***************************************************************************************************************************************************************************************
				*	- TMA: Tempo médio Falado.
				***************************************************************************************************************************************************************************************/
					SELECT 
						@DAYLING_TMA = ISNULL(AVG(DATEDIFF(SECOND, ISNULL(EVENTO_FAST_DT_INI, 0) , ISNULL(EVENTO_FAST_DT_FIM, 0))), 0)
					FROM 
						@TB_OPERADOR_EVENTO_FAST 
					WHERE 
						EVENTO_FAST_OPER_ID = @LOGIN_FAST_ID 
						AND EVENTO_FAST_EVENTO = 'DAC'
						AND DATEPART(HOUR, EVENTO_FAST_DT_FIM) = @DATEPART_HORA;
				/***************************************************************************************************************************************************************************************
				*	- AM_EMAIL:
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AM_EMAIL = ISNULL(COUNT(DB_CLAC.ID_CLIENTE_ACAO), 0)				
					FROM 
						[Homolog].[dbo].[TB_CLIENTE_ACAO]									DB_CLAC
					WHERE					
						CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, @DATA)
						AND DATEPART(HOUR, DB_CLAC.DT_ACAO) = (@DATEPART_HORA)
						AND DB_CLAC.ID_USUARIO = @ID_USUARIO
						AND DB_CLAC.ID_ACAO = 937;
				/***************************************************************************************************************************************************************************************
				*	- AM_EMAIL:
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AM_EMAIL = ISNULL(COUNT(DB_CLAC.ID_CLIENTE_ACAO), 0)				
					FROM 
						[Homolog].[dbo].[TB_CLIENTE_ACAO]									DB_CLAC
					WHERE					
						CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, @DATA)
						AND DATEPART(HOUR, DB_CLAC.DT_ACAO) = (@DATEPART_HORA)
						AND DB_CLAC.ID_USUARIO = @ID_USUARIO
						AND DB_CLAC.DS_ACAO LIKE '%BOLETO ENVIADO%';
				/***************************************************************************************************************************************************************************************
				*	- AA_NUMERO_N_EXISTE: Quantidade de Acionamentos NUMERO NÃO EXISTE.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AA_NUMERO_N_EXISTE = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%NUMERO NÃO EXISTE%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;	
				/***************************************************************************************************************************************************************************************
				*	- AA_LIGACAO_MUDA: Quantidade de Acionamentos CAIXA POSTAL.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AA_CAIXA_POSTAL = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%CAIXA POSTAL%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;
				/***************************************************************************************************************************************************************************************
				*	- AA_LIGACAO_MUDA: Quantidade de Acionamentos LIGAÇÃO MUDA.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AA_LIGACAO_MUDA = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%LIGAÇÃO MUDA%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;
				/***************************************************************************************************************************************************************************************
				*	- AA_SINAL_FAX: Quantidade de Acionamentos SINAL FAX.
				***************************************************************************************************************************************************************************************/
					SET @DAYLING_AA_SINAL_FAX = 0;
				/***************************************************************************************************************************************************************************************
				*	- AA_N_ATENDEU : Quantidade de Acionamentos LIGAÇÃO MUDA.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AA_N_ATENDEU = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%NAO ATENDE%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;
				/***************************************************************************************************************************************************************************************
				*	- AA_N_ATENDEU: Quantidade de Acionamentos LIGAÇÃO MUDA.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AA_N_ATENDEU = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%NAO ATENDE%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;
				/***************************************************************************************************************************************************************************************
				*	- AA_HANGUP: Quantidade de Acionamentos LIGAÇÃO MUDA.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AA_HANGUP = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%HANGUP%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);;
				/***************************************************************************************************************************************************************************************
				*	- AA_OCUPADO: Quantidade de Acionamentos LIGAÇÃO MUDA.
				***************************************************************************************************************************************************************************************/
					SELECT
						@DAYLING_AA_OCUPADO = ISNULL(COUNT(CALL_HISTORY_ID), 0)
					FROM
						__TB_CALL_HISTORY
					WHERE
						CALL_OPERADOR_ID = @LOGIN_FAST_ID
						AND CALL_RESULTADO LIKE '%OCUPADO%'
						AND DATEPART(HOUR, CALL_HORA_ENCERRAMENTO) = (@DATEPART_HORA);
			/***************************************************************************************************************************************************************************************
			*	SE @OPERADOR_DAYLING_NS = 0 INSERE
			***************************************************************************************************************************************************************************************/
				END ELSE BEGIN
					SET @OPERADOR_DAYLING_NS = -1;
				END;
				IF(@OPERADOR_DAYLING_NS = 0)BEGIN
					INSERT INTO TB_OPERADOR_DAYLING(
							LOGIN_FAST_ID
						,DAYLING_HORA
						,DAYLING_QTD_CLIE_TRAB
						,DAYLING_VLR_CLIE_TRAB
						,DAYLING_QTD_LIG
						,DAYLING_QTD_ALO
						,DAYLING_QTD_CPC
						,DAYLING_QTD_CPCA
						,DAYLING_QTD_ACORDO
						,DAYLING_VLR_ACORDO
						,DAYLING_QTD_ACORDO_PGTO
						,DAYLING_VLR_ACORDO_PGTO
						,DAYLING_QTD_ACW
						,DAYLING_QTD_TEMPO_FALADO
						,DAYLING_QTD_TEMPO_PAUSA
						,DAYLING_QTD_TEMPO_CONT
						,DAYLING_QTD_TEMPO_AVAIL
						,DAYLING_MEDIA_CHAMADAS
						,DAYLING_TMA
						,DAYLING_AM_EMAIL
						,DAYLING_AM_BOLETO
						,DAYLING_AA_NUMERO_N_EXISTE
						,DAYLING_AA_CAIXA_POSTAL
						,DAYLING_AA_LIGACAO_MUDA
						,DAYLING_AA_SINAL_FAX
						,DAYLING_AA_N_ATENDEU
						,DAYLING_AA_HANGUP
						,DAYLING_AA_OCUPADO
					)
					SELECT 
						@LOGIN_FAST_ID
						,@DAYLING_HORA
						,@DAYLING_QTD_CLIE_TRAB
						,@DAYLING_VLR_CLIE_TRAB
						,@DAYLING_QTD_LIG
						,@DAYLING_QTD_ALO
						,@DAYLING_QTD_CPC
						,@DAYLING_QTD_CPCA
						,@DAYLING_QTD_ACORDO
						,@DAYLING_VLR_ACORDO
						,@DAYLING_QTD_ACORDO_PGTO
						,@DAYLING_VLR_ACORDO_PGTO
						,@DAYLING_QTD_ACW
						,@DAYLING_QTD_TEMPO_FALADO
						,@DAYLING_QTD_TEMPO_PAUSA
						,@DAYLING_QTD_TEMPO_CONT
						,@DAYLING_QTD_TEMPO_AVAIL
						,@DAYLING_MEDIA_CHAMADAS
						,@DAYLING_TMA
						,@DAYLING_AM_EMAIL
						,@DAYLING_AM_BOLETO
						,@DAYLING_AA_NUMERO_N_EXISTE
						,@DAYLING_AA_CAIXA_POSTAL
						,@DAYLING_AA_LIGACAO_MUDA
						,@DAYLING_AA_SINAL_FAX
						,@DAYLING_AA_N_ATENDEU
						,@DAYLING_AA_HANGUP
						,@DAYLING_AA_OCUPADO

					END;						
				DELETE FROM @TB_OPERADOR_LOGIN_FAST WHERE LOGIN_FAST_ID = @LOGIN_FAST_ID;
			END;
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