USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_ACORDO_BAIXA_POS', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_ACORDO_BAIXA_POS]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_ACORDO_BAIXA_POS (
	 @ID_CARGA					BIGINT = 0	 
	,@SEQUENCIAL_IN				INT = 0	 
	,@SEQUENCIAL_OUTPUT			INT = 0 OUTPUT 
)
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 24/08/2022
	*	DESCRIÇÃO.: Procedure para a geraçao do arquivo de acordo e baixa no sistema e geraçao do arquivo para inserçao dos acionamentos
	***************************************************************************************************************************************************************************************/
	DECLARE @TB_BAIXA										TABLE(
																ID_REGISTRO					BIGINT
																,ID_CLIENTE					BIGINT
																,ID_CEDENTE					BIGINT
																,NM_CLIENTE_CEDENTE			VARCHAR(50)
																,NM_CEDENTE_CEDENTE			VARCHAR(50)
																,NM_ACORDO_CEDENTE			VARCHAR(50)
																,ID_DIVIDA					BIGINT
																,NM_DIVIDA_CEDENTE			VARCHAR(50)
																,VL_DIVIDA					NUMERIC(18,2)
																,DT_VENCIMENTO				DATE
																,DT_PAGAMENTO				DATE
																,ID_CONTRATO				BIGINT
																,NM_CONTRATO_CEDENTE		VARCHAR(50)
																,ID_PRODUTO					BIGINT
																,NM_PRODUTO					VARCHAR(50)
																,TP_STATUS_ACORDO			BIGINT
															);

	DECLARE @TB_ACORDO_FATURA								TABLE(
																 ID_CLIENTE					BIGINT
																,ID_FATURA					BIGINT
																,ID_ACORDO					BIGINT
															);
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/			
	DECLARE @NM_ORIGEM										VARCHAR(50) = '';
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ID_REGISTRO									BIGINT;
	DECLARE @ID_CLIENTE										BIGINT;
	DECLARE @ID_CEDENTE										BIGINT;
	DECLARE @NM_CLIENTE_CEDENTE								VARCHAR(50);
	DECLARE @NM_CEDENTE_CEDENTE								VARCHAR(50);
	DECLARE @NM_ACORDO_CEDENTE								VARCHAR(50);
	DECLARE @ID_DIVIDA										BIGINT;
	DECLARE @NM_DIVIDA_CEDENTE								VARCHAR(50);
	DECLARE @VL_DIVIDA										NUMERIC(18,2);
	DECLARE @DT_VENCIMENTO									DATE;
	DECLARE @DT_PAGAMENTO									DATE;
	DECLARE @ID_CONTRATO									BIGINT;
	DECLARE @NM_CONTRATO_CEDENTE							VARCHAR(50);
	DECLARE @ID_PRODUTO										BIGINT;
	DECLARE @NM_PRODUTO										VARCHAR(50)
	DECLARE @TP_STATUS_ACORDO								BIGINT;
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ID_FATURA										BIGINT
	DECLARE @ID_ACORDO										BIGINT
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ARQ_POS_TP_CANCEL								INT = 81;
	DECLARE @ARQ_POS_TP_PGTO								INT = 71;
	DECLARE @ARQ_POS_TP_ACORDO								INT = 51;
	DECLARE @COUNT_TP_CANCEL								INT = 81;
	DECLARE @COUNT_TP_PGTO									INT = 71;
	DECLARE @COUNT_TP_ACORDO								INT = 51;
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/	
	DECLARE @SEQUENCIAL										INT = 0;
	DECLARE @DT_ARQUIVO										DATETIME = GETDATE();
	DECLARE @TP_ARQUIVO										CHAR(1) = '';
	DECLARE @DS_ARQUIVO										VARCHAR(50) = '';	
	DECLARE @NM_ASSESSORIA									VARCHAR(50) = 'Homolog';	
	DECLARE @VERSAO											VARCHAR(10) = '1.0';
	DECLARE @ID_ASSESSORIA									VARCHAR(10) = '0';	
	DECLARE @COUNT_REG										INT = 0;
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ERROR_NUMBER_AUX								VARCHAR(500)
	DECLARE @ERROR_SEVERITY_AUX								VARCHAR(500)
	DECLARE @ERROR_STATE_AUX								VARCHAR(500)
	DECLARE @ERROR_PROCEDURE_AUX							VARCHAR(500)
	DECLARE @ERROR_LINE_AUX									VARCHAR(500)
	DECLARE @ERROR_MESSAGE_AUX								VARCHAR(500)
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY	
	/***************************************************************************************************************************************************************************************
	*	- RECUPERA O VALOR DA VARIAVEL @NM_ORIGEM
	***************************************************************************************************************************************************************************************/
		SELECT
			@NM_ORIGEM = ISNULL(DB_CARG.NM_ORIGEM, '')
		FROM
			[Homolog].[dbo].[TB_CARGA]										DB_CARG
		WHERE 
			ID_CARGA = @ID_CARGA;
	/***************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
		IF(LEN(LTRIM(RTRIM(@NM_ORIGEM))) > 0)BEGIN		
		/***************************************************************************************************************************************************************************************
		*	- RECUPERA O ULTIMO NUMERO SEQUENCIAL E INCREMENTA 1
		***************************************************************************************************************************************************************************************/
			IF(@SEQUENCIAL_IN > 0) BEGIN
				SET @SEQUENCIAL = @SEQUENCIAL_IN + 1;
			END ELSE BEGIN
				SELECT 
					@SEQUENCIAL = ISNULL(MAX(DB_CARG.NU_REMESSA), 0) + 1
				FROM
					[Homolog].[dbo].[TB_CARGA]										DB_CARG
				WHERE
					DB_CARG.NM_ORIGEM = REPLACE(@NM_ORIGEM, 'BAIXA_', '')
					AND DB_CARG.TP_ARQUIVO = 2;
			END;
			SET @SEQUENCIAL_OUTPUT = @SEQUENCIAL;
		/***************************************************************************************************************************************************************************************
		*	- RECUPERA AS INFORMAÇOES CONTIDA NA TABELA CARGA DIVIDA COM AS OUTRAS TABELAS PARA MONTAR O ARQUIVO POSICIONAL.
		***************************************************************************************************************************************************************************************/
			INSERT INTO @TB_BAIXA
			SELECT  DISTINCT
				 DB_CADI.ID_REGISTRO
				,DB_CLIE.ID_CLIENTE
				,DB_CLIE.ID_CEDENTE 
				,DB_CLIE.NM_CLIENTE_CEDENTE 
				,DB_CEDE.NM_CEDENTE_CEDENTE
				,ISNULL(DB_ACOR.NM_ACORDO_CEDENTE, '') AS 'NM_ACORDO_CEDENTE'
				,ISNULL(DB_DIVI.ID_DIVIDA, DB_ACDI.ID_DIVIDA) AS 'ID_DIVIDA'
				,ISNULL(DB_DIVI.NM_DIVIDA_CEDENTE, DB_ACDI.NM_DIVIDA_CEDENTE) AS 'NM_DIVIDA_CEDENTE'
				,ISNULL(DB_DIVI.VL_DIVIDA, DB_ACDI.VL_DIVIDA) AS 'VL_DIVIDA'
				,ISNULL(DB_DIVI.DT_VENCIMENTO, DB_ACDI.DT_VENCIMENTO) AS 'DT_VENCIMENTO'
				,DB_CADI.DT_PAGAMENTO
				,DB_CONT.ID_CONTRATO
				,DB_CONT.NM_CONTRATO_CEDENTE
				,DB_PROD.ID_PRODUTO
				,DB_PROD.NM_PRODUTO
				,(
					CASE
						WHEN DB_ACDI.ID_DIVIDA IS NOT NULL AND (SELECT COUNT(ID_USUARIO) FROM [Homolog].[dbo].TB_ACORDO DB_ACOR WHERE DB_ACDI.ID_ACORDO = DB_ACOR.ID_ACORDO AND DB_ACOR.TP_STATUS NOT IN (2, 3)) > 0 AND  DB_CONT.DT_EXPIRACAO > DB_CADI.DT_PAGAMENTO THEN @ARQ_POS_TP_CANCEL
						WHEN DB_ACDI.ID_DIVIDA IS NOT NULL AND (SELECT COUNT(DB_ACOR.ID_ACORDO) FROM [Homolog].[dbo].TB_ACORDO DB_ACOR WHERE DB_ACDI.ID_ACORDO = DB_ACOR.ID_ACORDO AND ID_USUARIO IS NULL  AND DB_ACOR.TP_STATUS NOT IN (2)) > 0 THEN @ARQ_POS_TP_PGTO
						WHEN DB_DIVI.ID_DIVIDA IS NOT NULL THEN @ARQ_POS_TP_ACORDO
						ELSE 0
						END				
				)AS 'TP_STATUS_ACORDO'
			FROM
				[Homolog].[dbo].TB_CARGA_DIVIDA										DB_CADI
				JOIN [Homolog].[dbo].TB_CLIENTE										DB_CLIE ON DB_CADI.NM_CLIENTE_CEDENTE = DB_CLIE.NM_CLIENTE_CEDENTE
				JOIN [Homolog].[dbo].TB_CEDENTE										DB_CEDE ON DB_CLIE.ID_CEDENTE = DB_CEDE.ID_CEDENTE
				JOIN [Homolog].[dbo].TB_CONTRATO										DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
				JOIN [Homolog].[dbo].TB_PRODUTO										DB_PROD ON DB_CONT.ID_PRODUTO = DB_PROD.ID_PRODUTO
				LEFT JOIN [Homolog].[dbo].TB_DIVIDA									DB_DIVI ON DB_CONT.ID_CONTRATO = DB_DIVI.ID_CONTRATO AND DB_CADI.NM_DIVIDA_CEDENTE = DB_DIVI.NM_DIVIDA_CEDENTE
				LEFT JOIN [Homolog].[dbo].TB_ACORDO_DIVIDA							DB_ACDI ON DB_CONT.ID_CONTRATO = DB_ACDI.ID_CONTRATO AND DB_CADI.NM_DIVIDA_CEDENTE = DB_ACDI.NM_DIVIDA_CEDENTE
				LEFT JOIN [Homolog].[dbo].[TB_ACORDO]									DB_ACOR ON DB_ACDI.ID_ACORDO = DB_ACOR.ID_ACORDO AND DB_ACDI.ID_CLIENTE = DB_ACOR.ID_CLIENTE
			WHERE
				DB_CADI.ID_CARGA = @ID_CARGA
				AND DB_CADI.TP_STATUS = 0
				AND 1 = (
					CASE
						WHEN (DB_DIVI.ID_DIVIDA IS NOT NULL) OR (DB_ACDI.ID_DIVIDA IS NOT NULL) THEN 1
						ELSE 0
					END		
				);
			
			IF((SELECT COUNT (ID_REGISTRO) FROM @TB_BAIXA WHERE TP_STATUS_ACORDO != 0) = 0) BEGIN
				SET @SEQUENCIAL_OUTPUT = -1;

				SELECT 
					* 
				FROM 
					@TB_BAIXA											DB_BAIX
					LEFT JOIN [Homolog].[dbo].TB_CARGA_DIVIDA		DB_CADI ON DB_BAIX.NM_CLIENTE_CEDENTE = DB_CADI.NM_CLIENTE_CEDENTE AND DB_CADI.NM_DIVIDA_CEDENTE = DB_BAIX.NM_DIVIDA_CEDENTE
				--WHERE
					
			END;
		END;

		SELECT @COUNT_TP_CANCEL =  COUNT(ID_REGISTRO) FROM @TB_BAIXA WHERE TP_STATUS_ACORDO = @ARQ_POS_TP_CANCEL;
		SELECT @COUNT_TP_ACORDO = COUNT(ID_REGISTRO) FROM @TB_BAIXA WHERE TP_STATUS_ACORDO = @ARQ_POS_TP_ACORDO
		SELECT @COUNT_TP_PGTO = COUNT(ID_REGISTRO) FROM @TB_BAIXA WHERE TP_STATUS_ACORDO = @ARQ_POS_TP_PGTO;

	/***************************************************************************************************************************************************************************************
	*	- SE NA TABELA TEMPORARIA TIVER CASOS EM ACORDO, GERA O ARQUIVO PARA FAZER O CANCELAMENTO DO ACORDO.
	***************************************************************************************************************************************************************************************/
		IF(@COUNT_TP_CANCEL > 0  ) BEGIN
			WHILE(EXISTS(SELECT TOP 1 ID_REGISTRO FROM @TB_BAIXA WHERE TP_STATUS_ACORDO =  @ARQ_POS_TP_CANCEL))BEGIN
				SELECT 
					 @ID_REGISTRO = ID_REGISTRO
					,@ID_CLIENTE = ID_CLIENTE
					,@ID_CEDENTE = ID_CEDENTE
					,@NM_CLIENTE_CEDENTE = NM_CLIENTE_CEDENTE
					,@NM_CEDENTE_CEDENTE = NM_CEDENTE_CEDENTE
					,@NM_ACORDO_CEDENTE = NM_ACORDO_CEDENTE
					,@ID_DIVIDA = ID_DIVIDA
					,@NM_DIVIDA_CEDENTE = NM_DIVIDA_CEDENTE
					,@VL_DIVIDA = VL_DIVIDA
					,@DT_VENCIMENTO = DT_VENCIMENTO
					,@DT_PAGAMENTO = DT_PAGAMENTO
					,@ID_CONTRATO = ID_CONTRATO
					,@NM_CONTRATO_CEDENTE = NM_CONTRATO_CEDENTE
					,@ID_PRODUTO = ID_PRODUTO
					,@NM_PRODUTO = NM_PRODUTO
					,@TP_STATUS_ACORDO = TP_STATUS_ACORDO
				FROM 
					@TB_BAIXA
				WHERE 
					TP_STATUS_ACORDO =  @ARQ_POS_TP_CANCEL;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				SET @COUNT_REG = 0;

				UPDATE [Homolog].[dbo].TB_CONTRATO SET DT_EXPIRACAO = @DT_PAGAMENTO WHERE ID_CONTRATO = @ID_CONTRATO
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(ARQUIVO_POS_NS) FROM __TB_ARQUIVO_POS WHERE ARQUIVO_POS_TP_NM = '1_HEADER' AND ARQUIVO_POS_SEQ = @SEQUENCIAL AND ARQUIVO_POS_TP_NS = @ARQ_POS_TP_CANCEL) = 0) BEGIN
					SET @TP_ARQUIVO = '4';
					SET @DS_ARQUIVO = 'ARQUIVO DE CANCELAMENTOS E EXCLUSOES'

					INSERT INTO __TB_ARQUIVO_POS(
						ARQUIVO_POS_SEQ,
						ARQUIVO_POS_NM,
						ARQUIVO_POS_TP_NS,
						ARQUIVO_POS_TP_NM,
						ARQUIVO_POS_REG
					)
					SELECT
						@SEQUENCIAL
						,@NM_CEDENTE_CEDENTE + '_CANCEL_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
						,@ARQ_POS_TP_CANCEL
						,'1_HEADER'
						, CONVERT(CHAR(02), '00') /*................................................................................................................................Tipo de Registro */
						+ CONVERT(CHAR(10), @DT_ARQUIVO, 111) /*....................................................................................................................Data do Arquivo */		
						+ CONVERT(CHAR(01), REPLICATE('0', 1 - LEN(@TP_ARQUIVO)) + @TP_ARQUIVO) /*..................................................................................Tipo do Arquivo */		
						+ (SELECT dbo.CONVERT_CHAR(@DS_ARQUIVO, 50, 'S')) /*........................................................................................................Descrição */	
						+ (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) /*....................................................................................................... Sequencial de remessa */		
						+ (SELECT dbo.CONVERT_CHAR(@NM_ASSESSORIA, 50, 'S')) /*.....................................................................................................Assessoria de Cobrança */	 
						+ (SELECT dbo.CONVERT_CHAR(@VERSAO, 10, 'S')) /*............................................................................................................Versão do Layout */	  			
						+ (SELECT dbo.CONVERT_CHAR(@ID_ASSESSORIA, 10, 'R')) /*.....................................................................................................ID da assessoria*/;
				END;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				INSERT INTO __TB_ARQUIVO_POS(
					ARQUIVO_POS_SEQ,
					ARQUIVO_POS_NM,
					ARQUIVO_POS_TP_NS,
					ARQUIVO_POS_TP_NM,
					ARQUIVO_POS_REG
				)
				SELECT
					@SEQUENCIAL
					,@NM_CEDENTE_CEDENTE + '_CANCEL_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
					,@ARQ_POS_TP_CANCEL
					,'2_BODY'
					, (CONVERT(CHAR(02),'81')) /*................................................................................................................................Tipo de Registro */
					+ (SELECT dbo.CONVERT_CHAR(@NM_ACORDO_CEDENTE, 10, 'R')) /*..................................................................................................Identificador do acordo*/	
					+ (SELECT dbo.CONVERT_CHAR(@ID_CLIENTE, 10, 'R')) /*.........................................................................................................ID Cliente EC */
					+ (SELECT dbo.CONVERT_CHAR(@ID_CEDENTE, 10, 'R')) /*.........................................................................................................ID Cedente */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CLIENTE_CEDENTE, 50, 'S')) /*.................................................................................................ID Cliente (NM_CLIENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CEDENTE_CEDENTE, 50, 'S')) /*.................................................................................................Nome Cedente (NM_CEDENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@ID_DIVIDA, 50, 'S')) /*..........................................................................................................ID Acordo (ID_DIVIDA) */
					+ (CONVERT(CHAR(10), CONVERT(DATETIME, GETDATE()), 111))/*...................................................................................................Data do Cancelamento */	
					+ (CONVERT(CHAR(8), CONVERT(DATETIME, GETDATE()), 108))/*...................................................................................................Hora do Cancelamento  */;

				DELETE FROM @TB_BAIXA WHERE ID_DIVIDA = @ID_DIVIDA;			
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(ID_REGISTRO) FROM @TB_BAIXA WHERE TP_STATUS_ACORDO =  @ARQ_POS_TP_CANCEL) = 0) BEGIN
					SELECT @COUNT_REG = COUNT(ARQUIVO_POS_NS) + 1 FROM __TB_ARQUIVO_POS WHERE ARQUIVO_POS_TP_NS =  @ARQ_POS_TP_CANCEL AND ARQUIVO_POS_SEQ = @SEQUENCIAL;
				END;
				IF(@COUNT_REG > 0) BEGIN
					INSERT INTO __TB_ARQUIVO_POS(
						ARQUIVO_POS_SEQ,
						ARQUIVO_POS_NM,
						ARQUIVO_POS_TP_NS,
						ARQUIVO_POS_TP_NM,
						ARQUIVO_POS_REG
					)
					SELECT
						@SEQUENCIAL
						,@NM_CEDENTE_CEDENTE + '_CANCEL_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
						,@ARQ_POS_TP_CANCEL
						,'3_TRAILLER'
						,CONVERT(CHAR(02), '99') /*................................................................................................................................Tipo de Registro */
						+ (SELECT dbo.CONVERT_CHAR(@COUNT_REG, 10, 'R')) /*........................................................................................................Total de registros */;
				END;

				DELETE FROM @TB_BAIXA WHERE ID_DIVIDA = @ID_DIVIDA;	
			END;
		END;
	/***************************************************************************************************************************************************************************************
	*	- ARQUIVO DE PAGAMENTO
	***************************************************************************************************************************************************************************************/
		IF(@COUNT_TP_CANCEL = 0 AND @COUNT_TP_PGTO > 0 AND @COUNT_TP_ACORDO = 0 ) BEGIN
			WHILE(EXISTS(SELECT TOP 1 ID_REGISTRO FROM @TB_BAIXA WHERE TP_STATUS_ACORDO = @ARQ_POS_TP_PGTO))BEGIN
				SELECT 
					 @ID_REGISTRO = ID_REGISTRO
					,@ID_CLIENTE = ID_CLIENTE
					,@ID_CEDENTE = ID_CEDENTE
					,@NM_CLIENTE_CEDENTE = NM_CLIENTE_CEDENTE
					,@NM_CEDENTE_CEDENTE = NM_CEDENTE_CEDENTE
					,@ID_DIVIDA = ID_DIVIDA
					,@NM_DIVIDA_CEDENTE = NM_DIVIDA_CEDENTE
					,@VL_DIVIDA = VL_DIVIDA
					,@DT_VENCIMENTO = DT_VENCIMENTO
					,@DT_PAGAMENTO = DT_PAGAMENTO
					,@ID_CONTRATO = ID_CONTRATO
					,@NM_CONTRATO_CEDENTE = NM_CONTRATO_CEDENTE
					,@ID_PRODUTO = ID_PRODUTO
					,@NM_PRODUTO = NM_PRODUTO
					,@TP_STATUS_ACORDO = TP_STATUS_ACORDO
				FROM 
					@TB_BAIXA;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				SET @COUNT_REG = 0;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(ARQUIVO_POS_NS) FROM __TB_ARQUIVO_POS WHERE ARQUIVO_POS_TP_NM = '1_HEADER' AND ARQUIVO_POS_SEQ = @SEQUENCIAL AND ARQUIVO_POS_TP_NS = @ARQ_POS_TP_PGTO) = 0) BEGIN
					SET @TP_ARQUIVO = '3';
					SET @DS_ARQUIVO = 'ARQUIVO DE PAGAMENTOS'

					INSERT INTO __TB_ARQUIVO_POS(
						ARQUIVO_POS_SEQ,
						ARQUIVO_POS_NM,
						ARQUIVO_POS_TP_NS,
						ARQUIVO_POS_TP_NM,
						ARQUIVO_POS_REG
					)
					SELECT
						@SEQUENCIAL
						,@NM_CEDENTE_CEDENTE + '_PGTO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
						,@ARQ_POS_TP_PGTO
						,'1_HEADER'
						, CONVERT(CHAR(02), '00') /*................................................................................................................................Tipo de Registro */
						+ CONVERT(CHAR(10), @DT_ARQUIVO, 111) /*....................................................................................................................Data do Arquivo */		
						+ CONVERT(CHAR(01), REPLICATE('0', 1 - LEN(@TP_ARQUIVO)) + @TP_ARQUIVO) /*..................................................................................Tipo do Arquivo */		
						+ (SELECT dbo.CONVERT_CHAR(@DS_ARQUIVO, 50, 'S')) /*........................................................................................................Descrição */	
						+ (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) /*....................................................................................................... Sequencial de remessa */		
						+ (SELECT dbo.CONVERT_CHAR(@NM_ASSESSORIA, 50, 'S')) /*.....................................................................................................Assessoria de Cobrança */	 
						+ (SELECT dbo.CONVERT_CHAR(@VERSAO, 10, 'S')) /*............................................................................................................Versão do Layout */	  			
						+ (SELECT dbo.CONVERT_CHAR(@ID_ASSESSORIA, 10, 'R')) /*.....................................................................................................ID da assessoria*/;
				END;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				INSERT INTO __TB_ARQUIVO_POS(
					ARQUIVO_POS_SEQ,
					ARQUIVO_POS_NM,
					ARQUIVO_POS_TP_NS,
					ARQUIVO_POS_TP_NM,
					ARQUIVO_POS_REG
				)
				SELECT
					@SEQUENCIAL
					,@NM_CEDENTE_CEDENTE + '_PGTO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
					,@ARQ_POS_TP_PGTO
					,'2_BODY'
					, (CONVERT(CHAR(02),'71')) /*..............................................................................................................................Tipo de Registro */
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................Identificador do acordo*/	
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................ID Cliente EC */
					+ (SELECT dbo.CONVERT_CHAR(@ID_CEDENTE, 10, 'R')) /*.......................................................................................................ID Cedente */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CLIENTE_CEDENTE, 50, 'S')) /*...............................................................................................ID Cliente (NM_CLIENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CEDENTE_CEDENTE, 50, 'S')) /*...............................................................................................Nome Cedente (NM_CEDENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@ID_DIVIDA, 50, 'S')) /*........................................................................................................ID Acordo (ID_DIVIDA) */
					+ (SELECT dbo.CONVERT_CHAR(1, 5, 'R')) /*..................................................................................................................Parcela do acordo */
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................Identificador da fatura */
					+ CONVERT(CHAR(02), REPLICATE('0', 2 - LEN('4')) + '4') /*.................................................................................................Tipo da Fatura */		
					+ CONVERT(CHAR(10), @DT_ARQUIVO, 111) /*...................................................................................................................Data de vencimento da parcela do acordo */		
					+ (SELECT dbo.CONVERT_CHAR(REPLACE(@VL_DIVIDA,'.',''), 15,'R')) /*.........................................................................................Valor da parcela do acordo */	
					+ CONVERT(CHAR(10), @DT_ARQUIVO, 111) /*...................................................................................................................Data de vencimento da fatura */
					+ (SELECT dbo.CONVERT_CHAR(REPLACE(@VL_DIVIDA,'.',''), 15,'R')) /*.........................................................................................Valor da fatura */		
					+ CONVERT(CHAR(10), @DT_PAGAMENTO, 111) /*.................................................................................................................Data de Pagamento */			
					+ (SELECT dbo.CONVERT_CHAR(REPLACE(@VL_DIVIDA,'.',''), 15, 'R')) /*........................................................................................Valor Pago */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor da Receita */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor do Repasse */
					+ (SELECT dbo.CONVERT_CHAR('0', 20, 'R')) /*...............................................................................................................Nosso Número Boleto */
					+ (SELECT dbo.CONVERT_CHAR('0', 50, 'R')) /*...............................................................................................................Número DI */
						
				DELETE FROM @TB_BAIXA WHERE ID_DIVIDA = @ID_DIVIDA;			
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(ID_REGISTRO) FROM @TB_BAIXA WHERE TP_STATUS_ACORDO = @ARQ_POS_TP_PGTO) = 0) BEGIN
					SELECT @COUNT_REG = COUNT(ARQUIVO_POS_NS) + 1 FROM __TB_ARQUIVO_POS WHERE ARQUIVO_POS_TP_NS =  @ARQ_POS_TP_PGTO AND ARQUIVO_POS_SEQ = @SEQUENCIAL
				END;
				IF(@COUNT_REG > 0) BEGIN
					INSERT INTO __TB_ARQUIVO_POS(
						ARQUIVO_POS_SEQ,
						ARQUIVO_POS_NM,
						ARQUIVO_POS_TP_NS,
						ARQUIVO_POS_TP_NM,
						ARQUIVO_POS_REG
					)
					SELECT
						@SEQUENCIAL
						,@NM_CEDENTE_CEDENTE + '_PGTO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
						,@ARQ_POS_TP_PGTO
						,'3_TRAILLER'
						,CONVERT(CHAR(02), '99') /*................................................................................................................................Tipo de Registro */
						+ (SELECT dbo.CONVERT_CHAR(@COUNT_REG, 10, 'R')) /*........................................................................................................Total de registros */;
				END;
			END;
		END;
	/***************************************************************************************************************************************************************************************
	*	- ARQUIVO DE ACORDO
	***************************************************************************************************************************************************************************************/
		IF(@COUNT_TP_CANCEL = 0 AND @COUNT_TP_PGTO = 0 AND @COUNT_TP_ACORDO > 0 ) BEGIN
			WHILE(EXISTS(SELECT TOP 1 ID_REGISTRO FROM @TB_BAIXA WHERE TP_STATUS_ACORDO = @ARQ_POS_TP_ACORDO))BEGIN
				SELECT 
					 @ID_REGISTRO = ID_REGISTRO
					,@ID_CLIENTE = ID_CLIENTE
					,@ID_CEDENTE = ID_CEDENTE
					,@NM_CLIENTE_CEDENTE = NM_CLIENTE_CEDENTE
					,@NM_CEDENTE_CEDENTE = NM_CEDENTE_CEDENTE
					,@ID_DIVIDA = ID_DIVIDA
					,@NM_DIVIDA_CEDENTE = NM_DIVIDA_CEDENTE
					,@VL_DIVIDA = VL_DIVIDA
					,@DT_VENCIMENTO = DT_VENCIMENTO
					,@DT_PAGAMENTO = DT_PAGAMENTO
					,@ID_CONTRATO = ID_CONTRATO
					,@NM_CONTRATO_CEDENTE = NM_CONTRATO_CEDENTE
					,@ID_PRODUTO = ID_PRODUTO
					,@NM_PRODUTO = NM_PRODUTO
					,@TP_STATUS_ACORDO = TP_STATUS_ACORDO
				FROM 
					@TB_BAIXA;

				DELETE FROM [Homolog].[dbo].[TB_DIVIDA_BLOQUEIO] WHERE ID_CONTRATO = @ID_CONTRATO AND ID_DIVIDA = @ID_DIVIDA;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				SET @COUNT_REG = 0;
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(ARQUIVO_POS_NS) FROM __TB_ARQUIVO_POS WHERE ARQUIVO_POS_TP_NM = '1_HEADER' AND ARQUIVO_POS_SEQ = @SEQUENCIAL AND ARQUIVO_POS_TP_NS = @ARQ_POS_TP_ACORDO) = 0) BEGIN
					SET @TP_ARQUIVO = '2';
					SET @DS_ARQUIVO = 'ARQUIVO DE ACORDOS'

					INSERT INTO __TB_ARQUIVO_POS(
						ARQUIVO_POS_SEQ,
						ARQUIVO_POS_NM,
						ARQUIVO_POS_TP_NS,
						ARQUIVO_POS_TP_NM,
						ARQUIVO_POS_REG
					)
					SELECT
						@SEQUENCIAL
						,@NM_CEDENTE_CEDENTE + '_ACORDO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
						,@ARQ_POS_TP_ACORDO
						,'1_HEADER'
						, CONVERT(CHAR(02), '00') /*................................................................................................................................Tipo de Registro */
						+ CONVERT(CHAR(10), @DT_ARQUIVO, 111) /*....................................................................................................................Data do Arquivo */		
						+ CONVERT(CHAR(01), REPLICATE('0', 1 - LEN(@TP_ARQUIVO)) + @TP_ARQUIVO) /*..................................................................................Tipo do Arquivo */		
						+ (SELECT dbo.CONVERT_CHAR(@DS_ARQUIVO, 50, 'S')) /*........................................................................................................Descrição */	
						+ (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) /*....................................................................................................... Sequencial de remessa */		
						+ (SELECT dbo.CONVERT_CHAR(@NM_ASSESSORIA, 50, 'S')) /*.....................................................................................................Assessoria de Cobrança */	 
						+ (SELECT dbo.CONVERT_CHAR(@VERSAO, 10, 'S')) /*............................................................................................................Versão do Layout */	  			
						+ (SELECT dbo.CONVERT_CHAR(@ID_ASSESSORIA, 10, 'R')) /*.....................................................................................................ID da assessoria*/;
				END;
				/***************************************************************************************************************************************************************************************
				*	- 51
				***************************************************************************************************************************************************************************************/
				INSERT INTO __TB_ARQUIVO_POS(
					ARQUIVO_POS_SEQ,
					ARQUIVO_POS_NM,
					ARQUIVO_POS_TP_NS,
					ARQUIVO_POS_TP_NM,
					ARQUIVO_POS_REG
				)
				SELECT
					@SEQUENCIAL
					,@NM_CEDENTE_CEDENTE + '_ACORDO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
					,@ARQ_POS_TP_ACORDO
					,'2_BODY'
					, (CONVERT(CHAR(02),'51')) /*..............................................................................................................................Tipo de Registro */
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................Identificador do acordo*/	
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................ID Cliente EC */
					+ (SELECT dbo.CONVERT_CHAR(@ID_CEDENTE, 10, 'R')) /*.......................................................................................................ID Cedente */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CLIENTE_CEDENTE, 50, 'S')) /*...............................................................................................ID Cliente (NM_CLIENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CEDENTE_CEDENTE, 50, 'S')) /*...............................................................................................Nome Cedente (NM_CEDENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@ID_DIVIDA, 50, 'S')) /*........................................................................................................ID Acordo (ID_DIVIDA) */
					+ (CONVERT(CHAR(10), @DT_ARQUIVO, 111)) /*.................................................................................................................Data do Acordo */
					+ (CONVERT(CHAR(08), @DT_ARQUIVO, 108)) /*.................................................................................................................Hora do Acordo */
					+ (CONVERT(CHAR(02),'00')) /*..............................................................................................................................Origem Acordo */
					+ (CONVERT(CHAR(10), @DT_ARQUIVO, 111)) /*.................................................................................................................Data Calculo */
					+ (SELECT dbo.CONVERT_CHAR(1, 5, 'R')) /*..................................................................................................................Parcelas do acordo*/

				/***************************************************************************************************************************************************************************************
				*	- 52
				***************************************************************************************************************************************************************************************/
				INSERT INTO __TB_ARQUIVO_POS(
					ARQUIVO_POS_SEQ,
					ARQUIVO_POS_NM,
					ARQUIVO_POS_TP_NS,
					ARQUIVO_POS_TP_NM,
					ARQUIVO_POS_REG
				)
				SELECT
					@SEQUENCIAL
					,@NM_CEDENTE_CEDENTE + '_ACORDO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
					,@ARQ_POS_TP_ACORDO
					,'2_BODY'
					, (CONVERT(CHAR(02),'52')) /*..............................................................................................................................Tipo de Registro */
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................Identificador do acordo*/	
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................ID Cliente EC */
					+ (SELECT dbo.CONVERT_CHAR(@ID_CEDENTE, 10, 'R')) /*.......................................................................................................ID Cedente */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CLIENTE_CEDENTE, 50, 'S')) /*...............................................................................................ID Cliente (NM_CLIENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CEDENTE_CEDENTE, 50, 'S')) /*...............................................................................................Nome Cedente (NM_CEDENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@ID_DIVIDA, 50, 'S')) /*........................................................................................................ID Acordo (ID_DIVIDA) */				
					+ (SELECT dbo.CONVERT_CHAR(1, 5, 'R')) /*..................................................................................................................Parcelas do acordo*/
					+ (CONVERT(CHAR(10), @DT_PAGAMENTO, 111)) /*.................................................................................................................Data Parcela */	
					+ (SELECT dbo.CONVERT_CHAR(REPLACE(@VL_DIVIDA,'.',''), 15, 'R')) /*........................................................................................Valor Divida */
					+ (CONVERT(CHAR(01), 0)) /*................................................................................................................................Status Parcela */	

				/***************************************************************************************************************************************************************************************
				*	- 53
				***************************************************************************************************************************************************************************************/
				INSERT INTO __TB_ARQUIVO_POS(
					ARQUIVO_POS_SEQ,
					ARQUIVO_POS_NM,
					ARQUIVO_POS_TP_NS,
					ARQUIVO_POS_TP_NM,
					ARQUIVO_POS_REG
				)
				SELECT
					@SEQUENCIAL
					,@NM_CEDENTE_CEDENTE + '_ACORDO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
					,@ARQ_POS_TP_ACORDO
					,'2_BODY'
					, (CONVERT(CHAR(02),'53')) /*..............................................................................................................................Tipo de Registro */
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................Identificador do acordo*/	
					+ (SELECT dbo.CONVERT_CHAR('0', 10, 'R')) /*...............................................................................................................ID Cliente EC */
					+ (SELECT dbo.CONVERT_CHAR(@ID_CEDENTE, 10, 'R')) /*.......................................................................................................ID Cedente */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CLIENTE_CEDENTE, 50, 'S')) /*...............................................................................................ID Cliente (NM_CLIENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CEDENTE_CEDENTE, 50, 'S')) /*...............................................................................................Nome Cedente (NM_CEDENTE_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@ID_DIVIDA, 50, 'S')) /*........................................................................................................ID Acordo (ID_DIVIDA) */
					+ (SELECT dbo.CONVERT_CHAR(@ID_CONTRATO, 10, 'R')) /*......................................................................................................ID Contrato EC */
					+ (SELECT dbo.CONVERT_CHAR(@NM_CONTRATO_CEDENTE, 50, 'S')) /*..............................................................................................ID Contrato (NM_CONTRATO_CEDENTE) */
					+ (SELECT dbo.CONVERT_CHAR(@ID_PRODUTO, 10,'R')) /*........................................................................................................ID Produto */
					+ (SELECT dbo.CONVERT_CHAR(@NM_PRODUTO, 50, 'S')) /*.......................................................................................................Nome Produto */	
					+ (SELECT dbo.CONVERT_CHAR(@NM_DIVIDA_CEDENTE, 50, 'S')) /*................................................................................................ID Divida (NM_DIVIDA_CEDENTE) */
					+ (CONVERT(CHAR(20), REPLICATE(@ID_DIVIDA, 20 - LEN('0')) + '0')) /*.......................................................................................ID Divida EC */
					+ (SELECT dbo.CONVERT_CHAR(REPLACE(@VL_DIVIDA,'.',''), 15, 'R')) /*........................................................................................Valor Divida */
					+ (CONVERT(CHAR(10), @DT_VENCIMENTO, 111)) /*..............................................................................................................Data de Vencimento */
					+ (SELECT dbo.CONVERT_CHAR('0', 5, 'R')) /*................................................................................................................Número da prestação */	
					+ (CONVERT(CHAR(10), SPACE(10))) /*........................................................................................................................Data Correção */	
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Correção */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Mínimo */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Juros */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Multa */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Taxa Administrativa */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Encargos*/ 
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Desconto Juros */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Desconto Principal */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Receita */
					+ (SELECT dbo.CONVERT_CHAR('0', 15, 'R')) /*...............................................................................................................Valor Repasse */

				DELETE FROM @TB_BAIXA WHERE ID_DIVIDA = @ID_DIVIDA;			
				/***************************************************************************************************************************************************************************************
				*	- 
				***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(ID_REGISTRO) FROM @TB_BAIXA WHERE TP_STATUS_ACORDO = @ARQ_POS_TP_ACORDO) = 0) BEGIN
					SELECT @COUNT_REG = COUNT(ARQUIVO_POS_NS) + 1 FROM __TB_ARQUIVO_POS WHERE ARQUIVO_POS_TP_NS =  @ARQ_POS_TP_ACORDO AND ARQUIVO_POS_SEQ = @SEQUENCIAL
				END;
				IF(@COUNT_REG > 0) BEGIN
					INSERT INTO __TB_ARQUIVO_POS(
						ARQUIVO_POS_SEQ,
						ARQUIVO_POS_NM,
						ARQUIVO_POS_TP_NS,
						ARQUIVO_POS_TP_NM,
						ARQUIVO_POS_REG
					)
					SELECT
						@SEQUENCIAL
						,@NM_CEDENTE_CEDENTE + '_ACORDO_' + (SELECT dbo.CONVERT_CHAR(@SEQUENCIAL, 10, 'R')) 
						,@ARQ_POS_TP_ACORDO
						,'3_TRAILLER'
						,CONVERT(CHAR(02), '99') /*................................................................................................................................Tipo de Registro */
						+ (SELECT dbo.CONVERT_CHAR(@COUNT_REG, 10, 'R')) /*........................................................................................................Total de registros */;
				END;
			END;
		END;
				
		RETURN;
	END TRY 
	BEGIN CATCH  
		SELECT 
			@ERROR_NUMBER_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_NUMBER()), '')
			,@ERROR_SEVERITY_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_SEVERITY()), '')
			,@ERROR_STATE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_STATE()), '')
			,@ERROR_PROCEDURE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_PROCEDURE()), '')
			,@ERROR_LINE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_LINE()), '')
			,@ERROR_MESSAGE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_MESSAGE()), '');	

		SELECT @ERROR_NUMBER_AUX, @ERROR_SEVERITY_AUX ,@ERROR_STATE_AUX ,@ERROR_PROCEDURE_AUX ,@ERROR_LINE_AUX ,@ERROR_MESSAGE_AUX 
		/*EXEC [dbo].[__PROC_SQL_ERROR_EMAIL]
			@ERROR_NUMBER = @ERROR_NUMBER_AUX
			,@ERROR_SEVERITY = @ERROR_SEVERITY_AUX
			,@ERROR_STATE = @ERROR_STATE_AUX
			,@ERROR_PROCEDURE = @ERROR_PROCEDURE_AUX
			,@ERROR_LINE = @ERROR_LINE_AUX
			,@ERROR_MESSAGE = @ERROR_MESSAGE_AUX;
		EXEC [dbo].[_PROC_ENVIO_EMAIL];		*/				
	END CATCH; 
END;