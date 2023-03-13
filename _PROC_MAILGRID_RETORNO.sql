USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_MAILGRID_RETORNO', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_MAILGRID_RETORNO]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_MAILGRID_RETORNO(
	@TIPO						INT = 0
)
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 19/12/2022
	*	DATA ATUALIZACAO.........: 19/12/2022
	*	DESCRIÇÃO................: Procedure executar o OLE
	***************************************************************************************************************************************************************************************/
	DECLARE @TABLE												TABLE(JSON_RETORNO				NVARCHAR(MAX))
	DECLARE @TABLE_JSON											TABLE(
																	 JSON_NS					BIGINT DEFAULT 0
																	,JSON_NOME					VARCHAR(250) DEFAULT ''
																	,JSON_DESCRICAO				VARCHAR(MAX) DEFAULT ''
																);																
	DECLARE @TB_EMAIL_ERRO_TP									TABLE(
																	 EMAIL_ERRO_TP_NS			BIGINT DEFAULT 0
																	,EMAIL_ERRO_TP_COD			VARCHAR(250) DEFAULT ''
																	,FLAG						BIGINT DEFAULT 0
																);
	DECLARE @TB_EMAIL											TABLE(
																	EMAIL_ERRO_NS 					INT IDENTITY(1,1) PRIMARY KEY,
																	EMAIL_DE						VARCHAR(MAX) DEFAULT '',
																	EMAIL_PARA						VARCHAR(MAX) DEFAULT '',
																	EMAIL_DATA						DATE DEFAULT '',
																	EMAIL_HORA						TIME DEFAULT '',
																	EMAIL_STATUS					VARCHAR(MAX) DEFAULT ''
																);
	/**************************************************************************************************************************************************************************************/
	DECLARE @DATA_OLE											DATE = GETDATE();	
	DECLARE @HORA_INICIO										TIME = '08:00:00';	
	DECLARE @HORA_INICIO_AUX									TIME = '';
	DECLARE @HORA_ATUAL											TIME = GETDATE();
	/**************************************************************************************************************************************************************************************/
	DECLARE @POST_DATA_AUX										NVARCHAR(2000) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @JSON_RETORNO										NVARCHAR(MAX);
	/**************************************************************************************************************************************************************************************/
	DECLARE @JSON_NS											BIGINT = 0
	DECLARE @JSON_NOME											VARCHAR(250) = '';
	DECLARE @JSON_DESCRICAO										VARCHAR(MAX) = '';
	DECLARE @EMAIL_PARA											VARCHAR(MAX) = '';
	DECLARE @EMAIL_DE											VARCHAR(MAX) = '';
	DECLARE @DATA												DATE = '';
	DECLARE @HORA												TIME = '';
	DECLARE @STATUS												VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @EMAIL_ERRO_NS										BIGINT = 0;
	DECLARE @EMAIL_STATUS										VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @EMAIL_ERRO_TP_NS									BIGINT = 0;
	DECLARE @EMAIL_ERRO_TP_COD									VARCHAR(250) = ''
	/**************************************************************************************************************************************************************************************/
	DECLARE @FLAG												BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @COUNT_BOLETO										BIGINT = 0;
	DECLARE @COUNT_AVISO										BIGINT = 0;
	DECLARE @COUNT_OUTROS										BIGINT = 0;
	/**************************************************************************************************************************************************************************************
	*	- VARIAVEL ENVIO EMAIL
	***************************************************************************************************************************************************************************************/
	DECLARE @SUBJECT											VARCHAR(200) = 'Erro envio de e-mail';
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
		-- Ao finalizar a proc comentar a linha abaixo
		/*DELETE FROM [Homolog].[dbo].[TB_EMAIL_ERRO]
		DBCC CHECKIDENT (TB_EMAIL_ERRO, RESEED, 0)*/
		--SET @HORA_ATUAL = '14:00:00';		
		
		IF(@TIPO = 1)BEGIN
			SET @HORA_ATUAL = '20:00:00'
		END;
	/***************************************************************************************************************************************************************************************
	*	- SETA AS VARIAVEIS INICIAIS PARA O LOOP
	***************************************************************************************************************************************************************************************/
		SET @HORA_INICIO_AUX = @HORA_INICIO;
		SET @HORA_INICIO = DATEADD(MINUTE, 5, @HORA_INICIO);

		WHILE(@HORA_INICIO <= @HORA_ATUAL)BEGIN
			SET @POST_DATA_AUX  = N'{';
			SET @POST_DATA_AUX += N'"usuario_smtp":"smtp1@Homolog.com.br"';
			SET @POST_DATA_AUX += N',"senha_smtp":"dsj83mwn2h2"';
			SET @POST_DATA_AUX += N',"dataini":"'+ REPLACE(CONVERT(VARCHAR(10),@DATA_OLE,111 ), '/', '-') +'"';
			SET @POST_DATA_AUX += N',"horaini":"' + SUBSTRING(CONVERT(VARCHAR(8), @HORA_INICIO_AUX, 108), 1,  LEN(CONVERT(VARCHAR(8),  @HORA_INICIO_AUX, 108)) -3 ) + '"';
			SET @POST_DATA_AUX += N',"datafim":"'+ REPLACE(CONVERT(VARCHAR(10),@DATA_OLE,111 ), '/', '-') +'"';
			SET @POST_DATA_AUX += N',"horafim":"' + SUBSTRING(CONVERT(VARCHAR(8), @HORA_INICIO, 108), 1,  LEN(CONVERT(VARCHAR(8),  @HORA_INICIO, 108)) -3 ) + '"';
			SET @POST_DATA_AUX += N',"status":"erro"';
			SET @POST_DATA_AUX += N'}';

			IF(@TIPO = 1) BEGIN
				SET @POST_DATA_AUX  = REPLACE(@POST_DATA_AUX, '"status":"erro"', '"status":""')
			END;

			EXEC [dbo].[__EXEC_OLE] 
				 @ProgID = N'WinHTTP.WinHTTPRequest.5.1'
				,@URL = N'http://painel.mailgrid.com.br/api/report.php'
				,@METODO_TP = N'POST'
				,@CONTENT_TYPE = N'application/json'
				,@POST_DATA = @POST_DATA_AUX;

			SELECT @JSON_RETORNO = XML_RETORNO FROM ##TB_OLE;	
			--SELECT  XML_RETORNO FROM ##TB_OLE;	
						
			DELETE FROM  @TABLE_JSON;

			IF(@JSON_RETORNO != 'null' AND CHARINDEX(']', @JSON_RETORNO) > 0) BEGIN
				INSERT INTO @TABLE_JSON
				SELECT 
					FNC_RET.Id_Objeto_Pai
					,FNC_RET.Ds_Nome
					,FNC_RET.Ds_String				
				FROM 
					dbo.fncJSON_Read(@JSON_RETORNO) FNC_RET
				WHERE
					FNC_RET.Id_Objeto_Pai IS NOT NULL
					AND FNC_RET.Ds_Nome IS NOT NULL
				ORDER BY
					FNC_RET.Id_Objeto_Pai, FNC_RET.Ds_Nome;			
			/***************************************************************************************************************************************************************************************
			*	-  TRATA OS DADOS DA TABELA @TABLE_JSON INSERINDO NA TABELA @TB_EMAIL
			***************************************************************************************************************************************************************************************/
				WHILE(EXISTS(SELECT TOP 1 JSON_NS FROM @TABLE_JSON))BEGIN
					SELECT TOP 1 @JSON_NS = JSON_NS FROM @TABLE_JSON;
					/***************************************************************************************************************************************************************************************
					*	- RESETA AS VARIAVEIS
					***************************************************************************************************************************************************************************************/
						SET @EMAIL_PARA = '';
						SET @EMAIL_DE = '';
						SET @DATA = ''
						SET @HORA = '';
						SET @STATUS = '';
					/***************************************************************************************************************************************************************************************
					*	- PEGA AS INFORMAÇOES DA TABELA CONFORME A VARIAVEL
					***************************************************************************************************************************************************************************************/
					WHILE(EXISTS(SELECT TOP 1 JSON_NS FROM @TABLE_JSON WHERE JSON_NS = @JSON_NS))BEGIN
						SELECT TOP 1 @JSON_NOME = JSON_NOME, @JSON_DESCRICAO = JSON_DESCRICAO FROM @TABLE_JSON;
						
						IF(@JSON_NOME = 'data' AND LEN(LTRIM(RTRIM(@JSON_DESCRICAO))) = 10)BEGIN		
							SET @DATA = (
								CASE
									WHEN ISDATE(@JSON_DESCRICAO) = 0 AND LEN(LTRIM(RTRIM(@JSON_DESCRICAO))) > 0 THEN CONVERT(DATETIME,CONVERT(VARCHAR(10), CAST(SUBSTRING(@JSON_DESCRICAO,4,3) + LEFT(@JSON_DESCRICAO,3) + RIGHT(@JSON_DESCRICAO,4) AS DATE) ,121))
									WHEN ISDATE(@JSON_DESCRICAO) = 1 THEN CONVERT(DATETIME,CONVERT(VARCHAR(10), @JSON_DESCRICAO ,121))						
									ELSE ''
								END			
							);	
						END;

						IF(@JSON_NOME = 'email_de')BEGIN
							SET @EMAIL_DE = ISNULL(@JSON_DESCRICAO, '')
						END;

						IF(@JSON_NOME = 'email_para')BEGIN
							SET @EMAIL_PARA = ISNULL(@JSON_DESCRICAO, '')
						END;						

						IF(@JSON_NOME = 'hora')BEGIN
							SET @HORA = ISNULL(@JSON_DESCRICAO, '')
						END;

						IF(@JSON_NOME = 'status')BEGIN
							SET @STATUS = ISNULL(@JSON_DESCRICAO, '')
						END;

						DELETE FROM @TABLE_JSON WHERE JSON_NS = @JSON_NS AND JSON_NOME = @JSON_NOME;
					END;				
				/***************************************************************************************************************************************************************************************
				*	- INSERE OS VALORES DAS VARIAVEIS NA TABELA TB_EMAIL_ERRO
				***************************************************************************************************************************************************************************************/
					IF(LEN(LTRIM(RTRIM(@EMAIL_DE))) > 0 AND LEN(LTRIM(RTRIM(@EMAIL_PARA))) > 0 AND @DATA != '1900-01-01' AND  @HORA != '00:00:00.000' AND  LEN(LTRIM(RTRIM(@STATUS))) > 0 )BEGIN
						INSERT INTO [Homolog].[dbo].[TB_EMAIL_ERRO](
							[ID_CLIENTE]
							,[ID_EMAIL]
							,[ID_CLIENTE_EVENTO]
							,[DT_EVENTO]
							,[EMAIL_DE]
							,[EMAIL_PARA]
							,[EMAIL_STATUS]
							,[EMAIL_ERRO_TP_NS]
						)
						SELECT DISTINCT
							DB_CLIE.ID_CLIENTE
							,DB_CLEM.ID_EMAIL
							,DB_CLEV.ID_CLIENTE_EVENTO
							,DB_CLEV.DT_EVENTO
							,@EMAIL_DE
							,@EMAIL_PARA
							,@STATUS
							,(CASE WHEN (@STATUS = 'Entregue com sucesso') THEN 173 ELSE 0 END)
						FROM				
							[Homolog].[dbo].[TB_CLIENTE]										DB_CLIE
							JOIN [Homolog].[dbo].[TB_CLIENTE_EMAIL]							DB_CLEM ON DB_CLIE.ID_CLIENTE = DB_CLEM.ID_CLIENTE
							JOIN [Homolog].[dbo].[TB_CLIENTE_EVENTO]							DB_CLEV ON DB_CLIE.ID_CLIENTE = DB_CLEV.ID_CLIENTE
						WHERE
							CONVERT(DATE, DB_CLEV.DT_EVENTO) = @DATA
							AND DB_CLEV.DS_EVENTO LIKE '%' + @EMAIL_PARA + '%'
							AND DATEPART(HOUR, DB_CLEV.DT_EVENTO) = DATEPART(HOUR, @HORA)
							AND 1 = (
								CASE
									WHEN (
										SELECT 
											COUNT(DB_EMER.EMAIL_ERRO_NS) 
										FROM 
											TB_EMAIL_ERRO DB_EMER
										WHERE 
											DB_EMER.ID_CLIENTE = DB_CLIE.ID_CLIENTE 
											AND DB_EMER.ID_EMAIL = DB_CLEM.ID_EMAIL 
											AND DB_EMER.ID_CLIENTE_EVENTO = DB_CLEV.ID_CLIENTE_EVENTO
											AND DB_EMER.DT_EVENTO = DB_CLEV.DT_EVENTO
									) = 0 THEN 1
									ELSE 0
									END			
							);
					END;
					DELETE FROM @TABLE_JSON WHERE JSON_NS = @JSON_NS
				END;
			END;
			SET @HORA_INICIO_AUX = @HORA_INICIO;
			SET @HORA_INICIO = DATEADD(MINUTE, 5, @HORA_INICIO)
		END;
		
	/***************************************************************************************************************************************************************************************
	*	-  RETORNA AS INFORMAÇÕES DO CLIENTE QUE FOI ENVIADO O EMAIL E SALVA NA TABELA TB_EMAIL_ERRO
	***************************************************************************************************************************************************************************************/
		INSERT INTO @TB_EMAIL_ERRO_TP
		SELECT 
			EMAIL_ERRO_TP_NS
			,EMAIL_ERRO_TP_COD
			,0
		FROM
			TB_EMAIL_ERRO_TP
		ORDER BY
			EMAIL_ERRO_TP_NS;

		WHILE(EXISTS(SELECT TOP 1 EMAIL_ERRO_NS FROM TB_EMAIL_ERRO WHERE EMAIL_ERRO_STATUS = 0 AND EMAIL_ERRO_TP_NS != 173))BEGIN
			SELECT TOP 1 @EMAIL_ERRO_NS = EMAIL_ERRO_NS, @EMAIL_STATUS = EMAIL_STATUS FROM TB_EMAIL_ERRO WHERE EMAIL_ERRO_STATUS = 0;			
		/***************************************************************************************************************************************************************************************
		*	-  
		***************************************************************************************************************************************************************************************/
			UPDATE @TB_EMAIL_ERRO_TP SET FLAG = 0;
			SET @FLAG = 0;
			WHILE(EXISTS(SELECT TOP 1 EMAIL_ERRO_TP_NS FROM @TB_EMAIL_ERRO_TP WHERE FLAG = 0))BEGIN
				SELECT TOP 1 @EMAIL_ERRO_TP_NS = EMAIL_ERRO_TP_NS, @EMAIL_ERRO_TP_COD = EMAIL_ERRO_TP_COD FROM @TB_EMAIL_ERRO_TP WHERE FLAG = 0
				SET @FLAG = -1
				
				IF(CHARINDEX(@EMAIL_ERRO_TP_COD, @EMAIL_STATUS) > 0) BEGIN
					SET @FLAG = CHARINDEX(@EMAIL_ERRO_TP_COD, @EMAIL_STATUS);
				END;	
				
				UPDATE @TB_EMAIL_ERRO_TP SET FLAG = @FLAG WHERE EMAIL_ERRO_TP_NS = @EMAIL_ERRO_TP_NS;
			END;
			SELECT @FLAG = MAX(FLAG) FROM @TB_EMAIL_ERRO_TP WHERE FLAG > 0;

			UPDATE TB_EMAIL_ERRO SET EMAIL_ERRO_STATUS = 1, EMAIL_ERRO_TP_NS = ISNULL((SELECT TOP 1 EMAIL_ERRO_TP_NS FROM @TB_EMAIL_ERRO_TP WHERE FLAG = @FLAG), 0) WHERE EMAIL_ERRO_NS = @EMAIL_ERRO_NS
		END; 
	/***************************************************************************************************************************************************************************************
	*	-  FAZ A TRATATIVA DO EMAIL CONFORME O TIPO DE ERRO
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 EMAIL_ERRO_NS FROM TB_EMAIL_ERRO WHERE EMAIL_ERRO_STATUS = 1 AND EMAIL_ERRO_TP_NS != 173))BEGIN
			SELECT TOP 1 
				@EMAIL_ERRO_NS = EMAIL_ERRO_NS
				,@EMAIL_ERRO_TP_NS = EMAIL_ERRO_TP_NS 
				,@EMAIL_PARA = EMAIL_PARA
			FROM 
				TB_EMAIL_ERRO 
			WHERE 
				EMAIL_ERRO_STATUS = 1;
		/***************************************************************************************************************************************************************************************
		*	-  VERIFICA SE O TIPO DE ERRO É IGUAL A 2, SE FOR DESABILITA O EMAIL, TIRA A PREFERENCIA E INSERE UM EVENTO
		***************************************************************************************************************************************************************************************/
			IF((SELECT EMAIL_ERRO_TP_MEDIDA_TP FROM TB_EMAIL_ERRO_TP WHERE EMAIL_ERRO_TP_NS = @EMAIL_ERRO_TP_NS) = 2) BEGIN			
			/***************************************************************************************************************************************************************************************
			*	-  DESABILITA O EMAIL E TIRA A PREFERENCIA
			***************************************************************************************************************************************************************************************/
				UPDATE
					DB_CLEM
				SET
					TP_HABILITADO = 0
					,TP_PREFERENCIAL = 0
				FROM
					[Homolog].[dbo].[TB_CLIENTE_EMAIL]							DB_CLEM
				WHERE
					DB_CLEM.NM_EMAIL = @EMAIL_PARA;
			/***************************************************************************************************************************************************************************************
			*	-  INSERE UM EVENTO
			***************************************************************************************************************************************************************************************/
				INSERT INTO [Homolog].[dbo].[TB_CLIENTE_EVENTO]
				SELECT
					DB_CLEM.ID_CLIENTE
					,GETDATE()
					,'BLOCKMAIL'
					,1886
					,(SELECT EMAIL_ERRO_TP_DESC FROM TB_EMAIL_ERRO_TP WHERE EMAIL_ERRO_TP_NS = @EMAIL_ERRO_TP_NS) + ' - (' + @EMAIL_PARA + ')'
				FROM
					[Homolog].[dbo].[TB_CLIENTE_EMAIL]							DB_CLEM
				WHERE
					DB_CLEM.NM_EMAIL = @EMAIL_PARA
					AND 1 = (
						CASE	
							WHEN (
								SELECT
									COUNT(DB_CLEC.ID_CLIENTE_EVENTO)
								FROM
									[Homolog].[dbo].[TB_CLIENTE_EVENTO]					DB_CLEC
								WHERE
									DB_CLEC.ID_CLIENTE = DB_CLEM.ID_CLIENTE
									AND CONVERT(DATE, DB_CLEC.DT_EVENTO) = CONVERT(DATE, GETDATE())
									AND NM_EVENTO = 'BLOCKMAIL'
									AND DB_CLEC.DS_EVENTO LIKE '%' + @EMAIL_PARA + '%'
							) = 0 THEN 1
							ELSE 0
							END				
					)
					AND 1 = (
						CASE	
							WHEN (
								SELECT
									COUNT(DB_CLEV.ID_CLIENTE_EVENTO)
								FROM
									[Homolog].[dbo].[TB_CLIENTE_EVENTO]							DB_CLEV
								WHERE
									DB_CLEV.ID_CLIENTE = DB_CLEM.ID_CLIENTE
									AND CONVERT(DATE, DB_CLEV.DT_EVENTO) = CONVERT(DATE, GETDATE())
									AND DB_CLEV.NM_EVENTO IN ('AVCOBRANCA', 'BOLETO')
							) > 0 THEN 1
							ELSE 0
							END
					);		
			END;
			UPDATE TB_EMAIL_ERRO SET EMAIL_ERRO_STATUS = 2 WHERE EMAIL_ERRO_NS = @EMAIL_ERRO_NS
		END;
	/***************************************************************************************************************************************************************************************
	*	-  FAZ O DISPARO DOS E-MAIL INFORMANDO QUAIS FORAM OS ERROS E QUAIS MEDIDAS FORAM TOMADAS
	***************************************************************************************************************************************************************************************/
		IF((SELECT COUNT(EMAIL_ERRO_NS) FROM TB_EMAIL_ERRO WHERE EMAIL_ERRO_STATUS = 2 AND CONVERT(DATE, DT_EVENTO) = CONVERT(DATE, GETDATE()) AND EMAIL_ERRO_TP_NS != 173) > 0)BEGIN

		/***************************************************************************************************************************************************************************************
		*	-  
		***************************************************************************************************************************************************************************************/
			SELECT 
				@COUNT_BOLETO = COUNT(DB_EMER.ID_CLIENTE)
			FROM 
				TB_EMAIL_ERRO										DB_EMER
				JOIN [Homolog].[dbo].[TB_CLIENTE_EVENTO]		DB_CLEC ON DB_EMER.ID_CLIENTE_EVENTO = DB_CLEC.ID_CLIENTE_EVENTO
			WHERE 
				EMAIL_ERRO_STATUS = 2 
				AND CONVERT(DATE, DB_EMER.DT_EVENTO) = CONVERT(DATE, GETDATE())
				AND DB_CLEC.NM_EVENTO = 'BOLETO'
				AND DB_CLEC.ID_CLIENTE = DB_EMER.ID_CLIENTE
				AND EMAIL_ERRO_TP_NS != 173;
		/***************************************************************************************************************************************************************************************
		*	-  
		***************************************************************************************************************************************************************************************/
			SELECT 
				@COUNT_AVISO = COUNT(DB_EMER.ID_CLIENTE)
			FROM 
				TB_EMAIL_ERRO										DB_EMER
				JOIN [Homolog].[dbo].[TB_CLIENTE_EVENTO]		DB_CLEC ON DB_EMER.ID_CLIENTE_EVENTO = DB_CLEC.ID_CLIENTE_EVENTO
			WHERE 
				EMAIL_ERRO_STATUS = 2 
				AND CONVERT(DATE, DB_EMER.DT_EVENTO) = CONVERT(DATE, GETDATE())
				AND DB_CLEC.NM_EVENTO = 'AVCOBRANCA'
				AND DB_CLEC.ID_CLIENTE = DB_EMER.ID_CLIENTE
				AND EMAIL_ERRO_TP_NS != 173;
		/***************************************************************************************************************************************************************************************
		*	-  
		***************************************************************************************************************************************************************************************/
			SELECT 
				@COUNT_OUTROS = COUNT(DB_EMER.ID_CLIENTE)
			FROM 
				TB_EMAIL_ERRO										DB_EMER
				JOIN [Homolog].[dbo].[TB_CLIENTE_EVENTO]		DB_CLEC ON DB_EMER.ID_CLIENTE_EVENTO = DB_CLEC.ID_CLIENTE_EVENTO
			WHERE 
				EMAIL_ERRO_STATUS = 2 
				AND CONVERT(DATE, DB_EMER.DT_EVENTO) = CONVERT(DATE, GETDATE())
				AND DB_CLEC.NM_EVENTO NOT IN ('AVCOBRANCA', 'BOLETO')
				AND DB_CLEC.ID_CLIENTE = DB_EMER.ID_CLIENTE
				AND EMAIL_ERRO_TP_NS != 173;

			SET @BODY_CORPO_HTML = ''
			SET @BODY_CORPO_HTML += N'<H2 style="text-align:center;width: 1400px;">Relatorio de erros do envio de e-mail.</H2>';
			SET @BODY_CORPO_HTML += ' <table> ';
			SET @BODY_CORPO_HTML += '     <caption><H3>Resumo de Erros</H3></caption> ';
			SET @BODY_CORPO_HTML += '     <thead> ';
			SET @BODY_CORPO_HTML += '         <tr> ';
			SET @BODY_CORPO_HTML += '             <th>Cedente</th> ';
			SET @BODY_CORPO_HTML += '             <th>Cliente E.C.</th> ';
			SET @BODY_CORPO_HTML += '             <th>Nome</th> ';
			SET @BODY_CORPO_HTML += '             <th>Data</th> ';
			SET @BODY_CORPO_HTML += '             <th>E-mail De</th> ';
			SET @BODY_CORPO_HTML += '             <th>E-mail Para</th> ';
			SET @BODY_CORPO_HTML += '             <th>Evento</th> ';
			SET @BODY_CORPO_HTML += '             <th>Erro</th> ';
			SET @BODY_CORPO_HTML += '             <th>Ação</th> ';
			SET @BODY_CORPO_HTML += '         </tr> ';
			SET @BODY_CORPO_HTML += '     </thead> ';
			SET @BODY_CORPO_HTML += '     <tbody> ';
			IF(@COUNT_BOLETO > 0) BEGIN
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT 
													td = DB_CEDE.NM_CEDENTE, '',
													td = DB_CLIE.ID_CLIENTE, '',
													td = DB_CLIE.NM_NOME, '',
													td = CONVERT(VARCHAR(8),DB_EMER.DT_EVENTO, 108) + ' ' + CONVERT(VARCHAR(10), DB_EMER.DT_EVENTO, 103), '',
													td = DB_EMER.EMAIL_DE, '',
													td = DB_EMER.EMAIL_PARA, '',
													td = DB_CLEC.NM_EVENTO, '',
													td = (CASE WHEN DB_EMER.EMAIL_ERRO_TP_NS = 0 THEN DB_EMER.EMAIL_STATUS ELSE DB_EMTP.EMAIL_ERRO_TP_DESC END), '',
													td = ISNULL(DB_EMTP.EMAIL_ERRO_TP_MEDIDA_DESC, ' '), ''
												FROM 
													TB_EMAIL_ERRO										DB_EMER
													LEFT JOIN TB_EMAIL_ERRO_TP							DB_EMTP ON DB_EMER.EMAIL_ERRO_TP_NS = DB_EMTP.EMAIL_ERRO_TP_NS
													JOIN [Homolog].[dbo].[TB_CLIENTE]				DB_CLIE ON DB_EMER.ID_CLIENTE = DB_CLIE.ID_CLIENTE
													JOIN [Homolog].[dbo].[TB_CEDENTE]				DB_CEDE ON DB_CLIE.ID_CEDENTE = DB_CEDE.ID_CEDENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE_EVENTO]		DB_CLEC ON DB_EMER.ID_CLIENTE_EVENTO = DB_CLEC.ID_CLIENTE_EVENTO
												WHERE 
													EMAIL_ERRO_STATUS = 2 
													AND CONVERT(DATE, DB_EMER.DT_EVENTO) = CONVERT(DATE, GETDATE())
													AND DB_CLEC.NM_EVENTO = 'BOLETO'
													AND DB_CLEC.ID_CLIENTE = DB_EMER.ID_CLIENTE
													AND DB_EMER.EMAIL_ERRO_TP_NS != 173
												ORDER BY
													DB_CEDE.NM_CEDENTE, DB_CLIE.NM_NOME
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);	
			END;
			IF(@COUNT_BOLETO > 0 AND @COUNT_AVISO > 0) BEGIN
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', ''
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);	
			END;
			IF(@COUNT_AVISO > 0) BEGIN
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT 
													td = DB_CEDE.NM_CEDENTE, '',
													td = DB_CLIE.ID_CLIENTE, '',
													td = DB_CLIE.NM_NOME, '',
													td = CONVERT(VARCHAR(8),DB_EMER.DT_EVENTO, 108) + ' ' + CONVERT(VARCHAR(10), DB_EMER.DT_EVENTO, 103), '',
													td = DB_EMER.EMAIL_DE, '',
													td = DB_EMER.EMAIL_PARA, '',
													td = DB_CLEC.NM_EVENTO, '',
													td = (CASE WHEN DB_EMER.EMAIL_ERRO_TP_NS = 0 THEN DB_EMER.EMAIL_STATUS ELSE DB_EMTP.EMAIL_ERRO_TP_DESC END), '',
													td = ISNULL(DB_EMTP.EMAIL_ERRO_TP_MEDIDA_DESC, ' '), ''
												FROM 
													TB_EMAIL_ERRO										DB_EMER
													LEFT JOIN TB_EMAIL_ERRO_TP							DB_EMTP ON DB_EMER.EMAIL_ERRO_TP_NS = DB_EMTP.EMAIL_ERRO_TP_NS
													JOIN [Homolog].[dbo].[TB_CLIENTE]				DB_CLIE ON DB_EMER.ID_CLIENTE = DB_CLIE.ID_CLIENTE
													JOIN [Homolog].[dbo].[TB_CEDENTE]				DB_CEDE ON DB_CLIE.ID_CEDENTE = DB_CEDE.ID_CEDENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE_EVENTO]		DB_CLEC ON DB_EMER.ID_CLIENTE_EVENTO = DB_CLEC.ID_CLIENTE_EVENTO
												WHERE 
													EMAIL_ERRO_STATUS = 2 
													AND CONVERT(DATE, DB_EMER.DT_EVENTO) = CONVERT(DATE, GETDATE())
													AND DB_CLEC.NM_EVENTO = 'AVCOBRANCA'
													AND DB_CLEC.ID_CLIENTE = DB_EMER.ID_CLIENTE
													AND DB_EMER.EMAIL_ERRO_TP_NS != 173
												ORDER BY
													DB_CEDE.NM_CEDENTE, DB_CLIE.NM_NOME
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);	
			END;
			IF((@COUNT_BOLETO > 0 OR @COUNT_AVISO > 0) AND @COUNT_OUTROS > 0) BEGIN
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', '',
													td = '**********', ''
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);
			END;
			IF(@COUNT_OUTROS > 0) BEGIN
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT 
													td = DB_CEDE.NM_CEDENTE, '',
													td = DB_CLIE.ID_CLIENTE, '',
													td = DB_CLIE.NM_NOME, '',
													td = CONVERT(VARCHAR(8),DB_EMER.DT_EVENTO, 108) + ' ' + CONVERT(VARCHAR(10), DB_EMER.DT_EVENTO, 103), '',
													td = DB_EMER.EMAIL_DE, '',
													td = DB_EMER.EMAIL_PARA, '',
													td = DB_CLEC.NM_EVENTO, '',
													td = (CASE WHEN DB_EMER.EMAIL_ERRO_TP_NS = 0 THEN DB_EMER.EMAIL_STATUS ELSE DB_EMTP.EMAIL_ERRO_TP_DESC END), '',
													td = ISNULL(DB_EMTP.EMAIL_ERRO_TP_MEDIDA_DESC, ' '), ''
												FROM 
													TB_EMAIL_ERRO										DB_EMER
													LEFT JOIN TB_EMAIL_ERRO_TP							DB_EMTP ON DB_EMER.EMAIL_ERRO_TP_NS = DB_EMTP.EMAIL_ERRO_TP_NS
													JOIN [Homolog].[dbo].[TB_CLIENTE]				DB_CLIE ON DB_EMER.ID_CLIENTE = DB_CLIE.ID_CLIENTE
													JOIN [Homolog].[dbo].[TB_CEDENTE]				DB_CEDE ON DB_CLIE.ID_CEDENTE = DB_CEDE.ID_CEDENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE_EVENTO]		DB_CLEC ON DB_EMER.ID_CLIENTE_EVENTO = DB_CLEC.ID_CLIENTE_EVENTO
												WHERE 
													EMAIL_ERRO_STATUS = 2 
													AND CONVERT(DATE, DB_EMER.DT_EVENTO) = CONVERT(DATE, GETDATE())
													AND DB_CLEC.NM_EVENTO NOT IN ('AVCOBRANCA', 'BOLETO')
													AND DB_CLEC.ID_CLIENTE = DB_EMER.ID_CLIENTE
													AND DB_EMER.EMAIL_ERRO_TP_NS != 173
												ORDER BY
													DB_CEDE.NM_CEDENTE, DB_CLIE.NM_NOME
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);	
			END;
			SET @BODY_CORPO_HTML += '     </tbody> ';
			SET @BODY_CORPO_HTML += ' </table> ';
			SET @BODY_CORPO_HTML += ' <br/><br/> ';		
		
			IF(LEN(LTRIM(RTRIM(@BODY_CORPO_HTML))) > 0) BEGIN
				SET @BODY_ENVIO_HTML =  @BODY_CABECALHO_HTML + @BODY_CORPO_HTML ;			
			END;
			IF(LEN(LTRIM(RTRIM(@BODY_ENVIO_HTML))) > 0) BEGIN
			
				INSERT INTO  TB_EMAIL_ENVIO(
					EMAIL_ENVIO_PROFILE_NAME
					--,EMAIL_ENVIO_RECIPIENTES
					--,EMAIL_ENVIO_CP_RECIPIENTES
					,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
				)
				SELECT
					'EmailHomolog'
					--,'suporte@Homolog.com.br'
					,'wanderlei.silva@Homolog.com.br;anderson.andrade@Homolog.com.br;'
					--,'anderson.andrade@Homolog.com.br;'
					,@SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High'
			END;
			UPDATE TB_EMAIL_ERRO SET EMAIL_ERRO_STATUS = 3 WHERE EMAIL_ERRO_STATUS = 2 AND CONVERT(DATE, DT_EVENTO) = CONVERT(DATE, GETDATE())
			EXEC [dbo].[_PROC_ENVIO_EMAIL];
		END;
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