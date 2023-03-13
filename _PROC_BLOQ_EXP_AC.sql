USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_BLOQ_EXP_AC', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_BLOQ_EXP_AC]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_BLOQ_EXP_AC
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.........: ANDERSON LOPEZ
	*	DATA..........: 24/08/2022
	*	ALTERAÇÃO.....: 07/11/2022
	*	DESCRIÇÃO.....: Procedure para a geraçao do arquivo de acordo e baixa no sistema e geraçao do arquivo para inserçao dos acionamentos
	***************************************************************************************************************************************************************************************/
	DECLARE @SQL_ERROR											VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	
	/**************************************************************************************************************************************************************************************/
	DECLARE @PATHNAME_ORIG										VARCHAR(MAX) = '\\192.168.3.6\#Homolog\_Rotinas_BD\Acao_Bloqueio_Expiracao';	
	DECLARE @PATHNAME_DEST										VARCHAR(MAX) = 'D:\Homolog\arquivos\Carga\Conversor\#Acao_Bloqueio_Expiracao';
	DECLARE @PATHNAME_AUX										VARCHAR(MAX) = '';
	DECLARE @ARQUIVO_NS											INT = 0;
	DECLARE @ARQUIVO_NOME										VARCHAR(255);
	/**************************************************************************************************************************************************************************************/
	DECLARE @CMD_SHELL											VARCHAR(8000) = '';	
	/**************************************************************************************************************************************************************************************/	
	DECLARE @NM_BASE											VARCHAR(MAX) = '[BAIXA$]';	
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_CONSULTA										VARCHAR(MAX) = '';
	DECLARE @EXCEL_CONSULTA										VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @BLOQ_EXP_AC_NS										BIGINT = 0; 
	DECLARE @ARQ_NOME											VARCHAR(350) = '';	
	DECLARE @TIPO_EXEC											BIGINT = 0;
	DECLARE @LOGIN_EC											VARCHAR(50) = '';
	DECLARE @ID_CEDENTE											BIGINT = 0;
	DECLARE @NM_CLIENTE_CEDENTE									VARCHAR(50) = '';
	DECLARE @ID_CLIENTE											BIGINT = 0;
	DECLARE @NU_CPF_CNPJ										BIGINT = 0;
	DECLARE @NM_NOME											VARCHAR(50) = '';
	DECLARE @NM_CONTRATO										VARCHAR(50) = '';
	DECLARE @ID_CONTRATO										BIGINT = 0;
	DECLARE @NM_DIVIDA											VARCHAR(50) = '';
	DECLARE @NM_DIVIDA_AUX_1									VARCHAR(3000) = '';
	DECLARE @NM_DIVIDA_AUX_2									VARCHAR(3000) = '';
	DECLARE @ID_DIVIDA											BIGINT = 0;
	DECLARE @ID_USUARIO											BIGINT = 1886;
	DECLARE @ID_USUARIO_AUX										BIGINT = 0;
	DECLARE @ID_ACAO											BIGINT = 2075;
	DECLARE @DS_ACAO											VARCHAR(3000) = '';
	DECLARE @DS_ACAO_AUX										VARCHAR(3000) = '';
	DECLARE @DT_DEVOLUCAO_AUX									VARCHAR(50) = '';
	DECLARE @DT_DEVOLUCAO										DATETIME = GETDATE()
	DECLARE @TIME_DEVOLUCAO										TIME = GETDATE()
	DECLARE @FLAG												BIGINT = 0;
	DECLARE @FLAG_ADD_CONT_DIVI									BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @COUNT												BIGINT = 0; 
	DECLARE @COUNT_ARQUIVO_SUCESSO								BIGINT = 0; 
	DECLARE @COUNT_ARQUIVO_FALHA								BIGINT = 0; 
	/**************************************************************************************************************************************************************************************/
	DECLARE @ID_CLIENTE_ACAO									BIGINT = 0; 
	DECLARE @DT_INICIO											DATETIME = GETDATE()
	/***************************************************************************************************************************************************************************************
	*	- VARIAVEL ENVIO EMAIL
	***************************************************************************************************************************************************************************************/
	DECLARE @SUBJECT											VARCHAR(200) = 'Bloqueio e Expiração de dividas';
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
		/***************************************************************************************************************************************************************************************
	*	- CRIA TABELA TEMPORARIA
	***************************************************************************************************************************************************************************************/
		IF (Object_ID('tempDB..##TB_ARQUIVO_BLOQ','U') is not null)BEGIN
			DROP TABLE ##TB_ARQUIVO_BLOQ;
		END;
		CREATE TABLE ##TB_ARQUIVO_BLOQ (
			  ARQUIVO_NS					INT IDENTITY(1, 1)
			 ,ARQUIVO_NM					VARCHAR(MAX)
			 ,ARQUIVO_TAMANHO				BIGINT
			 ,ARQUIVO_DT					DATETIME
			 ,ARQUIVO_TP					VARCHAR(10)
			 ,ARQUIVO_PATHNAME				VARCHAR(MAX)
			 ,ARQUIVO_FLAG					BIGINT DEFAULT 0			 
		);
	/**************************************************************************************************************************************************************************************/
		IF (Object_ID('tempDB..##TB_BLOQ_EXP_AC','U') is not null)BEGIN
			DROP TABLE ##TB_BLOQ_EXP_AC;
		END;
		CREATE TABLE ##TB_BLOQ_EXP_AC(
			 BLOQ_EXP_AC_NS				INT IDENTITY(1, 1)
			,ARQ_NOME					VARCHAR(350)
			,TIPO_EXEC					VARCHAR(350) 
			,LOGIN_EC					VARCHAR(50)
			,ID_CEDENTE					VARCHAR(350) 
			,NM_CLIENTE_CEDENTE			VARCHAR(50)
			,ID_CLIENTE					VARCHAR(350) 
			,NU_CPF_CNPJ				VARCHAR(350)
			,NM_NOME					VARCHAR(50) 
			,NM_CONTRATO				VARCHAR(50)
			,ID_CONTRATO				VARCHAR(350)
			,NM_DIVIDA					VARCHAR(50) 
			,ID_DIVIDA					VARCHAR(350)
			,ID_ACAO					VARCHAR(350)
			,DS_ACAO					VARCHAR(500) 
			,DT_DEVOLUCAO				NVARCHAR(50) 
			,FLAG						BIGINT
		);
	/***************************************************************************************************************************************************************************************
	*	- RETORNA OS ARQUIVOS DO @PATHNAME_ORIG
	***************************************************************************************************************************************************************************************/
		EXEC [__PROC_CMDSHELL] @PATHNAME_CMDSHELL = @PATHNAME_ORIG, @TABELA_NOME = '##TB_ARQUIVO_BLOQ';
	/***************************************************************************************************************************************************************************************
	*	- VERIFICA SE EXISTE ARQUIVO NO DIRETORIO DE ORIGEM.
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 ARQUIVO_NS FROM ##TB_ARQUIVO_BLOQ WHERE ARQUIVO_FLAG =  0))BEGIN
			SELECT TOP 1 
				@ARQUIVO_NS = ARQUIVO_NS
				,@ARQUIVO_NOME = ARQUIVO_NM 
			FROM 
				##TB_ARQUIVO_BLOQ 
			WHERE 
				ARQUIVO_FLAG =  0
			ORDER BY 
				ARQUIVO_NS ;			
		/***************************************************************************************************************************************************************************************
		*	- DELETA A TABELA TEMPORARIA.
		***************************************************************************************************************************************************************************************/
			IF(@ARQUIVO_NOME != 'Arq_Modelo.xlsx')BEGIN
				IF(CHARINDEX('.xlsx', @ARQUIVO_NOME) > 0)BEGIN	
					SET @PATHNAME_AUX = @PATHNAME_ORIG + '\' + @ARQUIVO_NOME;
					SET @CMD_SHELL = 'move /Y "' + @PATHNAME_AUX + '" "' + @PATHNAME_DEST + '"';
					IF(LEN(LTRIM(RTRIM(@CMD_SHELL))) > 0)BEGIN
						EXEC master.dbo.xp_cmdshell @command_string = @CMD_SHELL;
					END;
					UPDATE ##TB_ARQUIVO_BLOQ SET ARQUIVO_PATHNAME = @PATHNAME_DEST WHERE ARQUIVO_NS = @ARQUIVO_NS;
				END;
			END ELSE BEGIN			
				DELETE FROM ##TB_ARQUIVO_BLOQ WHERE ARQUIVO_NS = @ARQUIVO_NS;
			END;
			UPDATE ##TB_ARQUIVO_BLOQ SET ARQUIVO_FLAG = 1 WHERE ARQUIVO_NS = @ARQUIVO_NS;
		END;		
	/***************************************************************************************************************************************************************************************
	*	- SE TIVER ARQUIVO NO DESTINO FAZ A IMPORTAÇÃO PARA UMA PASTA TEMPORARIA.
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 ARQUIVO_NS FROM ##TB_ARQUIVO_BLOQ WHERE ARQUIVO_FLAG = 1  AND ARQUIVO_PATHNAME = @PATHNAME_DEST))BEGIN
			SELECT TOP 1 
				@ARQUIVO_NS = ARQUIVO_NS
				,@ARQUIVO_NOME = ARQUIVO_NM 
			FROM 
				##TB_ARQUIVO_BLOQ 
			WHERE 
				ARQUIVO_FLAG =  1
				AND ARQUIVO_PATHNAME = @PATHNAME_DEST
			ORDER BY 
				ARQUIVO_NS ;
		/***************************************************************************************************************************************************************************************
		*	- DELETA A TABELA TEMPORARIA.
		***************************************************************************************************************************************************************************************/
			SET @PATHNAME_AUX = @PATHNAME_DEST + '\' + @ARQUIVO_NOME;
			SET @SQL_CONSULTA = 'INSERT INTO ##TB_BLOQ_EXP_AC SELECT ''' + @ARQUIVO_NOME + ''' AS ''ARQ_NOME'', * , 0 AS ''FLAG''';
			--SET @SQL_CONSULTA = ' SELECT ''' + @ARQUIVO_NOME + ''' AS ''ARQ_NOME'', * , 0 AS ''FLAG''';
			SET @EXCEL_CONSULTA = 'select * from ' + @NM_BASE;
			
			EXEC [dbo].[__EXEC_OPENROWSET] @CONSULTA_SQL = @SQL_CONSULTA, @CONSULTA_OPENROWSET = @EXCEL_CONSULTA, @FULLPATHNAME = @PATHNAME_AUX, @TIPO = 2;

			UPDATE ##TB_ARQUIVO_BLOQ SET ARQUIVO_FLAG = 2 WHERE ARQUIVO_NS = @ARQUIVO_NS;
		END;
	/***************************************************************************************************************************************************************************************
	*	- Veririfica se os dados da tabela temporaria exitem no sistema e faz as tratativas do mesmo dependendo do tipo de execução (@TIPO_EXEC).
	*	@TIPO_EXEC = 1; EXPIRAR
	*	@TIPO_EXEC = 2; BLOQUEAR
	*	@TIPO_EXEC = 3; INCLUIR AÇAO
	*	@TIPO_EXEC = 4; EXPIRAR, BLOQUEAR E INCLUIR AÇÃO
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 BLOQ_EXP_AC_NS FROM ##TB_BLOQ_EXP_AC WHERE FLAG =  0))BEGIN
			SELECT TOP 1 
				 @BLOQ_EXP_AC_NS = BLOQ_EXP_AC_NS
				,@ARQ_NOME = ARQ_NOME 
				,@TIPO_EXEC = ISNULL(TIPO_EXEC, 0)
				,@LOGIN_EC = ISNULL(LOGIN_EC, '')
				,@ID_CEDENTE = ISNULL(ID_CEDENTE, 0)
				,@NM_CLIENTE_CEDENTE = ISNULL((CASE WHEN ISNUMERIC(NM_CLIENTE_CEDENTE) = 1 THEN CAST(CAST(CAST(NM_CLIENTE_CEDENTE AS FLOAT) AS BIGINT) AS VARCHAR(50)) ELSE CAST(NM_CLIENTE_CEDENTE AS VARCHAR(50)) END), '')
				,@ID_CLIENTE = ISNULL(ID_CLIENTE, 0)
				,@NU_CPF_CNPJ = ISNULL((CASE WHEN ISNUMERIC(NU_CPF_CNPJ) = 1 THEN CAST(CAST(NU_CPF_CNPJ AS FLOAT) AS BIGINT) ELSE 0 END), 0)
				,@NM_NOME = ISNULL(NM_NOME, 0)
				,@NM_CONTRATO = ISNULL((CASE WHEN ISNUMERIC(NM_CONTRATO) = 1 THEN CAST(CAST(CAST(NM_CONTRATO AS FLOAT) AS BIGINT) AS VARCHAR(50)) ELSE CAST(NM_CONTRATO AS VARCHAR(50)) END),'')
				,@ID_CONTRATO = ISNULL(ID_CONTRATO, 0)
				,@NM_DIVIDA = ISNULL((CASE WHEN ISNUMERIC(NM_DIVIDA) = 1 THEN CAST(CAST(CAST(NM_DIVIDA AS FLOAT) AS BIGINT) AS VARCHAR(50)) ELSE CAST(NM_DIVIDA AS VARCHAR(50)) END),'')
				,@ID_DIVIDA = ISNULL(ID_DIVIDA, 0)
				,@ID_ACAO = ISNULL(ID_ACAO, 2075)
				,@DS_ACAO = ISNULL(DS_ACAO, 'PROCESSO SEGUE PARA DEVOLUÇÃO')	
				,@DT_DEVOLUCAO_AUX = ISNULL(DT_DEVOLUCAO, '')
				,@FLAG = FLAG
			FROM 
				##TB_BLOQ_EXP_AC 
			WHERE 
				FLAG = 0;

			SET @DT_DEVOLUCAO = (
				CASE
					WHEN ISDATE(@DT_DEVOLUCAO_AUX) = 0 AND LEN(LTRIM(RTRIM(@DT_DEVOLUCAO_AUX))) > 0 THEN CONVERT(DATETIME,CONVERT(VARCHAR(10), CAST(SUBSTRING(@DT_DEVOLUCAO_AUX,4,3) + LEFT(@DT_DEVOLUCAO_AUX,3) + RIGHT(@DT_DEVOLUCAO_AUX,4) AS DATE) ,121) + ' '+ CONVERT(VARCHAR(8), @TIME_DEVOLUCAO, 108))
					WHEN ISDATE(@DT_DEVOLUCAO_AUX) = 1 THEN CONVERT(DATETIME,CONVERT(VARCHAR(10), @DT_DEVOLUCAO_AUX ,121) + ' '+ CONVERT(VARCHAR(8), @TIME_DEVOLUCAO, 108))						
					ELSE GETDATE()
				END			
			);			
			SET @ID_USUARIO_AUX = 0;
		/***************************************************************************************************************************************************************************************
		*	- Verifica se o usuario existe no sistema.
		***************************************************************************************************************************************************************************************/
			SELECT TOP 1 
				 @LOGIN_EC = ISNULL(LOGIN_EC, '')
			FROM 
				##TB_BLOQ_EXP_AC
			WHERE
				ARQ_NOME = @ARQ_NOME
				AND LOGIN_EC IS NOT NULL;

			IF(LEN(LTRIM(RTRIM(@LOGIN_EC))) > 0 )BEGIN			
				IF(LTRIM(RTRIM(@LOGIN_EC)) = 'T.I.')BEGIN		
					SELECT @LOGIN_EC = NM_LOGIN FROM [Homolog].[dbo].[TB_USUARIO] WHERE ID_USUARIO = @ID_USUARIO
				END ELSE BEGIN					
					SELECT @ID_USUARIO_AUX = ISNULL(ID_USUARIO,0) FROM [Homolog].[dbo].[TB_USUARIO] WHERE UPPER(LTRIM(RTRIM(NM_LOGIN))) = UPPER(LTRIM(RTRIM(@LOGIN_EC)))			
					IF(@ID_USUARIO_AUX > 0)BEGIN			
						IF((SELECT COUNT(ID_USUARIO) FROM [Homolog].[dbo].[TB_USUARIO] WHERE ID_USUARIO = @ID_USUARIO_AUX AND TP_BLOQUEIO = 1) > 0)BEGIN					
							SET @FLAG = -3;
						END;		
					END ELSE BEGIN
						SET @FLAG = -2;
					END;
				END;	
			END ELSE BEGIN
				SET @FLAG = -1;
			END;

			IF(@FLAG < 0)BEGIN
				UPDATE ##TB_BLOQ_EXP_AC SET FLAG = @FLAG, LOGIN_EC = @LOGIN_EC, DT_DEVOLUCAO = CONVERT(VARCHAR(26), @DT_DEVOLUCAO ,120) WHERE ARQ_NOME = @ARQ_NOME
			END;
			IF(@FLAG = 0) BEGIN
			/***************************************************************************************************************************************************************************************
			*	
			***************************************************************************************************************************************************************************************/
				IF(@ID_USUARIO > 0 AND @TIPO_EXEC > 0 AND @ID_CEDENTE > 0 ) BEGIN
				/***************************************************************************************************************************************************************************************
				*	
				***************************************************************************************************************************************************************************************/		
					IF(@ID_CLIENTE = 0)BEGIN
						IF(LEN(LTRIM(RTRIM(@NM_CLIENTE_CEDENTE))) > 0) BEGIN
							SELECT
								 @ID_CLIENTE = ID_CLIENTE
								,@NU_CPF_CNPJ = NU_CPF_CNPJ						
							FROM
								[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
							WHERE
								DB_CLIE.ID_CEDENTE = @ID_CEDENTE
								AND DB_CLIE.NM_CLIENTE_CEDENTE = @NM_CLIENTE_CEDENTE;
						END;
					END;
				/***************************************************************************************************************************************************************************************
				*	
				***************************************************************************************************************************************************************************************/
					IF(@ID_CLIENTE = 0)BEGIN
						IF(@NU_CPF_CNPJ > 0) BEGIN
							SELECT							
								@ID_CLIENTE = ID_CLIENTE
								,@NM_CLIENTE_CEDENTE = NM_CLIENTE_CEDENTE			
							FROM
								[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
							WHERE
								DB_CLIE.ID_CEDENTE = @ID_CEDENTE
								AND DB_CLIE.NU_CPF_CNPJ = @NU_CPF_CNPJ 		
						END;
					END;
				/***************************************************************************************************************************************************************************************
				*	
				***************************************************************************************************************************************************************************************/
					IF(@ID_CLIENTE > 0)BEGIN	
						SET @FLAG_ADD_CONT_DIVI = 0;				
					/***************************************************************************************************************************************************************************************
					*	- RECUPERA AS INFORMAÇOES DO CONTRATO
					*	SE O CONTRATO NAO CONTIVER NENHUMA INFORMAÇÃO IRA RETORNAR TODOS OS CONTRATOS E DIVIDAS DO CLIENTE.
					***************************************************************************************************************************************************************************************/
						IF(LEN(LTRIM(RTRIM(@NM_CONTRATO))) = 0 AND @ID_CONTRATO = 0) BEGIN
							SET @FLAG_ADD_CONT_DIVI = 1;
						END;

						IF(LEN(LTRIM(RTRIM(@NM_CONTRATO))) > 0 OR @ID_CONTRATO > 0) BEGIN
						/***************************************************************************************************************************************************************************************
						*	- RECUPERA AS INFORMAÇOES DA DIVIDA
						*	SE A DIVIDA NAO CONTIVER NENHUMA INFORMAÇÃO IRA RETORNAR TODOS AS DIVIDA DO CLIENTE.
						***************************************************************************************************************************************************************************************/
							IF(LEN(LTRIM(RTRIM(@NM_DIVIDA))) = 0 AND @ID_DIVIDA = 0) BEGIN
								SET @FLAG_ADD_CONT_DIVI = 1;
							END;
							IF(LEN(LTRIM(RTRIM(@NM_CONTRATO))) > 0) BEGIN
								SET @COUNT = 0;
								SELECT
									@COUNT = DB_CONT.ID_CONTRATO
								FROM
									[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
									JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
								WHERE
									DB_CLIE.ID_CLIENTE = @ID_CLIENTE
									AND DB_CONT.NM_CONTRATO_CEDENTE = @NM_CONTRATO;							
							/***************************************************************************************************************************************************************************************
							*	
							***************************************************************************************************************************************************************************************/
								IF(@COUNT > 1)BEGIN
									DELETE FROM ##TB_BLOQ_EXP_AC WHERE BLOQ_EXP_AC_NS = @BLOQ_EXP_AC_NS
									INSERT INTO ##TB_BLOQ_EXP_AC
									SELECT 
										@ARQ_NOME
										,@TIPO_EXEC
										,@LOGIN_EC
										,@ID_CEDENTE
										,@NM_CLIENTE_CEDENTE
										,DB_CLIE.ID_CLIENTE	
										,DB_CLIE.NU_CPF_CNPJ
										,DB_CLIE.NM_NOME
										,DB_CONT.NM_CONTRATO_CEDENTE
										,DB_CONT.ID_CONTRATO
										,@NM_DIVIDA
										,@ID_DIVIDA	
										,@ID_ACAO
										,@DS_ACAO
										,CONVERT(VARCHAR(26), @DT_DEVOLUCAO ,120)
										,1
									FROM
										[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
										JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
									WHERE
										DB_CLIE.ID_CLIENTE = @ID_CLIENTE
										AND DB_CONT.NM_CONTRATO_CEDENTE = @NM_CONTRATO	
								END ELSE BEGIN
									SELECT
										@ID_CONTRATO = DB_CONT.ID_CONTRATO
									FROM
										[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
										JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
									WHERE
										DB_CLIE.ID_CLIENTE = @ID_CLIENTE
										AND DB_CONT.NM_CONTRATO_CEDENTE = @NM_CONTRATO		
								END;
							END;

							IF(@ID_CONTRATO > 0)BEGIN
								IF(LEN(LTRIM(RTRIM(@NM_DIVIDA))) > 0 OR @ID_DIVIDA = 0) BEGIN
								
									SELECT
										@ID_DIVIDA = DB_DIVI.ID_DIVIDA
									FROM
										[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
										JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
										JOIN [Homolog].[dbo].[TB_DIVIDA]							DB_DIVI ON DB_CONT.ID_CONTRATO = DB_DIVI.ID_CONTRATO
									WHERE
										DB_CLIE.ID_CLIENTE = @ID_CLIENTE
										AND DB_CONT.ID_CONTRATO = @ID_CONTRATO
										AND DB_DIVI.NM_DIVIDA_CEDENTE = @NM_DIVIDA;	
								END;
							END;

							IF(@ID_DIVIDA > 0)BEGIN								
								SELECT
									@NM_DIVIDA = DB_DIVI.NM_DIVIDA_CEDENTE
								FROM
									[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
									JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
									JOIN [Homolog].[dbo].[TB_DIVIDA]							DB_DIVI ON DB_CONT.ID_CONTRATO = DB_DIVI.ID_CONTRATO
								WHERE
									DB_CLIE.ID_CLIENTE = @ID_CLIENTE
									AND DB_CONT.ID_CONTRATO = @ID_CONTRATO
									AND DB_DIVI.ID_DIVIDA = @ID_DIVIDA;
							END;							
						END;
						SET @FLAG = 1;
					END ELSE BEGIN
						SET @FLAG = -11;
					END;
				END ELSE BEGIN
					SET @FLAG = -10;
				END;
				IF(@FLAG_ADD_CONT_DIVI = 1) BEGIN
					DELETE FROM ##TB_BLOQ_EXP_AC WHERE ID_CLIENTE = @ID_CLIENTE
					INSERT INTO ##TB_BLOQ_EXP_AC
					SELECT DISTINCT
							@ARQ_NOME
						,@TIPO_EXEC
						,@LOGIN_EC
						,DB_CLIE.ID_CEDENTE
						,NM_CLIENTE_CEDENTE
						,DB_CLIE.ID_CLIENTE	
						,DB_CLIE.NU_CPF_CNPJ
						,DB_CLIE.NM_NOME
						,DB_CONT.NM_CONTRATO_CEDENTE
						,DB_CONT.ID_CONTRATO
						,ISNULL(DB_DIVI.NM_DIVIDA_CEDENTE, '') AS NM_DIVIDA_CEDENTE
						,ISNULL(DB_DIVI.ID_DIVIDA,  '')AS ID_DIVIDA
						,@ID_ACAO
						,@DS_ACAO
						,CONVERT(VARCHAR(26), @DT_DEVOLUCAO ,120)
						,1
					FROM
						[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
						JOIN [Homolog].[dbo].[TB_CONTRATO]						DB_CONT ON DB_CLIE.ID_CLIENTE = DB_CONT.ID_CLIENTE
						JOIN [Homolog].[dbo].[TB_DIVIDA]							DB_DIVI ON DB_CONT.ID_CONTRATO = DB_DIVI.ID_CONTRATO									
					WHERE
						DB_CLIE.ID_CLIENTE = @ID_CLIENTE;
				END ELSE BEGIN
					UPDATE 
						##TB_BLOQ_EXP_AC 
					SET 
						 LOGIN_EC = @LOGIN_EC
						,NM_CLIENTE_CEDENTE = @NM_CLIENTE_CEDENTE
						,ID_CLIENTE = @ID_CLIENTE
						,NU_CPF_CNPJ = @NU_CPF_CNPJ
						,ID_CONTRATO = @ID_CONTRATO
						,NM_CONTRATO = @NM_CONTRATO
						,NM_DIVIDA = @NM_DIVIDA
						,ID_DIVIDA = @ID_DIVIDA
						,ID_ACAO = @ID_ACAO
						,DS_ACAO = @DS_ACAO
						,DT_DEVOLUCAO = CONVERT(VARCHAR(26), @DT_DEVOLUCAO ,120)
						,FLAG = @FLAG 
					WHERE 
						BLOQ_EXP_AC_NS = @BLOQ_EXP_AC_NS;	
				
				END;
			
			END;		
		END;
		--DELETE FROM ##TB_BLOQ_EXP_AC WHERE ID_CLIENTE != 1380537
	/***************************************************************************************************************************************************************************************
	*	- FAZ AS TRATATIVAS DA FICHA CO CLIENTE CONFORME A OPÇÃO ESCOLHIDA
	***************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 BLOQ_EXP_AC_NS FROM ##TB_BLOQ_EXP_AC WHERE FLAG =  1))BEGIN
			SELECT TOP 1 
				 @BLOQ_EXP_AC_NS = BLOQ_EXP_AC_NS
				,@TIPO_EXEC = TIPO_EXEC
				,@LOGIN_EC = LOGIN_EC
				,@ID_CLIENTE = ID_CLIENTE
				,@ID_CONTRATO = ID_CONTRATO
				,@ID_DIVIDA = ID_DIVIDA
				,@ID_ACAO = ID_ACAO
				,@DS_ACAO = DS_ACAO
				,@DT_DEVOLUCAO = DT_DEVOLUCAO
			FROM 
				##TB_BLOQ_EXP_AC 
			WHERE 
				FLAG = 1;
		/***************************************************************************************************************************************************************************************
		*	
		***************************************************************************************************************************************************************************************/
			SELECT @ID_USUARIO = ID_USUARIO FROM [Homolog].[dbo].[TB_USUARIO] WHERE UPPER(LTRIM(RTRIM(NM_LOGIN))) = UPPER(LTRIM(RTRIM(@LOGIN_EC)))
		/***************************************************************************************************************************************************************************************
		*	EXPIRAR
		***************************************************************************************************************************************************************************************/
			IF(@TIPO_EXEC = 2 OR @TIPO_EXEC = 3 OR @TIPO_EXEC = 6 OR @TIPO_EXEC = 99) BEGIN
				UPDATE 
					DB_CONT
				SET
					DB_CONT.DT_EXPIRACAO = @DT_DEVOLUCAO	
				FROM
					[Homolog].[dbo].[TB_CONTRATO]										DB_CONT
				WHERE
					DB_CONT.ID_CONTRATO = @ID_CONTRATO;
			END;
		/***************************************************************************************************************************************************************************************
		*	BLOQUEAR
		***************************************************************************************************************************************************************************************/
			IF(@TIPO_EXEC = 4 OR @TIPO_EXEC = 5 OR @TIPO_EXEC = 6 OR @TIPO_EXEC = 99) BEGIN
				INSERT INTO [Homolog].[dbo].[TB_DIVIDA_BLOQUEIO]
				SELECT 							
					 DB_DIVI.ID_CONTRATO
					,DB_DIVI.ID_DIVIDA
					,2
					,@DT_DEVOLUCAO
					,DB_DIVI.NU_PRESTACAO
					,DB_DIVI.DT_VENCIMENTO
					,NULL
					,@ID_USUARIO
					,0
					,NULL
					,NULL
				FROM
					[Homolog].[dbo].[TB_DIVIDA]							DB_DIVI 
				WHERE
					DB_DIVI.ID_DIVIDA = @ID_DIVIDA
					AND DB_DIVI.ID_DIVIDA NOT IN (SELECT DB_DIBL.ID_DIVIDA FROM [Homolog].[dbo].[TB_DIVIDA_BLOQUEIO] DB_DIBL WHERE DB_DIBL.ID_DIVIDA = DB_DIVI.ID_DIVIDA);
			END;
		/***************************************************************************************************************************************************************************************
		*	INCLUIR AÇÃO
		***************************************************************************************************************************************************************************************/
			IF(@TIPO_EXEC = 1 OR @TIPO_EXEC = 3 OR @TIPO_EXEC = 5 OR @TIPO_EXEC = 99) BEGIN
				SET @DS_ACAO_AUX = @DS_ACAO;
				SET @NM_DIVIDA_AUX_1 = '';
				SET @NM_DIVIDA_AUX_2 = '';
					
				WHILE(EXISTS(SELECT TOP 1 BLOQ_EXP_AC_NS FROM ##TB_BLOQ_EXP_AC WHERE FLAG =  1 AND DS_ACAO IS NOT NULL AND ID_CLIENTE = @ID_CLIENTE))BEGIN
					SELECT TOP 1 @BLOQ_EXP_AC_NS = BLOQ_EXP_AC_NS FROM ##TB_BLOQ_EXP_AC WHERE FLAG =  1 AND DS_ACAO IS NOT NULL AND ID_CLIENTE = @ID_CLIENTE
					SET @ID_CLIENTE_ACAO = 0;
					IF(LEN(LTRIM(RTRIM(@NM_DIVIDA_AUX_1))) = 0)BEGIN
						SELECT @NM_DIVIDA = NM_DIVIDA  FROM ##TB_BLOQ_EXP_AC WHERE BLOQ_EXP_AC_NS = @BLOQ_EXP_AC_NS;
						SET @NM_DIVIDA_AUX_1 = @NM_DIVIDA;
						SET @NM_DIVIDA_AUX_2 = @NM_DIVIDA;
					END ELSE BEGIN
						SET @NM_DIVIDA_AUX_2 =(SELECT TOP 1 CONVERT(VARCHAR(50), NM_DIVIDA) FROM ##TB_BLOQ_EXP_AC WHERE FLAG =  1 AND DS_ACAO IS NOT NULL AND ID_CLIENTE = @ID_CLIENTE AND NM_DIVIDA != @NM_DIVIDA)
						SET @NM_DIVIDA_AUX_1 += '; ' + @NM_DIVIDA_AUX_2;
					END;

					SELECT 
						@ID_CLIENTE_ACAO = ISNULL(ID_CLIENTE_ACAO, 0)
					FROM
						[Homolog].[dbo].[TB_CLIENTE_ACAO]						DB_CLAC
					WHERE
						DB_CLAC.ID_CLIENTE = @ID_CLIENTE
						AND DB_CLAC.ID_ACAO = @ID_ACAO
						AND DB_CLAC.ID_USUARIO = @ID_USUARIO
						AND CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, @DT_DEVOLUCAO);

					IF(@ID_CLIENTE_ACAO = 0)BEGIN
						INSERT INTO [Homolog].[dbo].[TB_CLIENTE_ACAO]	
						SELECT
							 @ID_CLIENTE
							,GETDATE()
							,@ID_ACAO
							,@ID_USUARIO
							,'Divida: ' + @NM_DIVIDA_AUX_1 + ', ' + @DS_ACAO_AUX
							,NULL
							,NULL
							,NULL
							,NULL
							,NULL
							,2
							,NULL
							,0
							,0
							,0
							,0
							,NULL
					END ELSE BEGIN
						SELECT 
							@COUNT = COUNT(ID_CLIENTE_ACAO)
						FROM
							[Homolog].[dbo].[TB_CLIENTE_ACAO]						DB_CLAC
						WHERE
							DB_CLAC.ID_CLIENTE = @ID_CLIENTE
							AND DB_CLAC.ID_ACAO = @ID_ACAO
							AND DB_CLAC.ID_USUARIO = @ID_USUARIO
							AND DB_CLAC.DS_ACAO LIKE '%'+ @NM_DIVIDA_AUX_2 + '%'
							AND CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, @DT_DEVOLUCAO);

						IF(@COUNT = 0)BEGIN
							UPDATE
								DB_CLAC
							SET							
								DB_CLAC.DS_ACAO =  'Divida: ' + @NM_DIVIDA_AUX_1 + ', ' + @DS_ACAO_AUX
							FROM
								[Homolog].[dbo].[TB_CLIENTE_ACAO]						DB_CLAC
							WHERE
								DB_CLAC.ID_CLIENTE_ACAO = @ID_CLIENTE_ACAO;
						END;						
					END;
					UPDATE ##TB_BLOQ_EXP_AC SET DS_ACAO = NULL WHERE BLOQ_EXP_AC_NS = @BLOQ_EXP_AC_NS; 
				END;					
				UPDATE ##TB_BLOQ_EXP_AC SET DS_ACAO = @DS_ACAO_AUX WHERE ID_CLIENTE = @ID_CLIENTE;	
			END;
			UPDATE ##TB_BLOQ_EXP_AC SET FLAG = 2 WHERE BLOQ_EXP_AC_NS = @BLOQ_EXP_AC_NS;	
		END;
	/***************************************************************************************************************************************************************************************
	*	Envio email.
	***************************************************************************************************************************************************************************************/	
		SET @BODY_CORPO_HTML = '';		
		SET @BODY_CABECALHO_HTML = N'<H2 style="text-align:center;width: 1400px;"> Resumo (Bloqueio ou Expiração) </H2>';
	/**************************************************************************************************************************************************************************************/
	
		SELECT * FROM ##TB_BLOQ_EXP_AC
		WHILE(EXISTS(SELECT TOP 1 BLOQ_EXP_AC_NS FROM ##TB_BLOQ_EXP_AC))BEGIN
			SELECT TOP 1
				 @ARQ_NOME = ARQ_NOME
				,@ID_CEDENTE = ISNULL(ID_CEDENTE, 0) 
				,@LOGIN_EC = ISNULL(LOGIN_EC, '')
				,@TIPO_EXEC = ISNULL(TIPO_EXEC, 0)
			FROM 
				##TB_BLOQ_EXP_AC;
			/***************************************************************************************************************************************************************************************
			*	- SE NAO FOI POSSIVEL ENCONTRAR O USUARIO.
			***************************************************************************************************************************************************************************************/
			IF((SELECT COUNT(ARQ_NOME) FROM ##TB_BLOQ_EXP_AC WHERE FLAG IN(-1,-2,-3) AND ARQ_NOME = @ARQ_NOME) > 0)BEGIN

				SET @BODY_CORPO_HTML += ' <table> ';
				SET @BODY_CORPO_HTML += '     <caption><H3>Erro ao processar o arquivo</H3></caption> ';
				SET @BODY_CORPO_HTML += '     <thead> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <th>Arquivo</th> ';
				SET @BODY_CORPO_HTML += '             <th>Usuario EC</th> ';
				SET @BODY_CORPO_HTML += '             <th>Descrição</th> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </thead> ';
				SET @BODY_CORPO_HTML += '     <tbody> ';
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT DISTINCT
													td = ARQ_NOME, '',   
													td = ISNULL(LOGIN_EC, ''), '',   
													td = (CASE 
														WHEN FLAG = -1 THEN 'Não foi possivel encontrar usuario na planilha.'
														WHEN FLAG = -2 THEN 'Usuario nao encontrado.'
														WHEN FLAG = -3 THEN 'Usuario bloqueado.'
														ELSE ''
													END), ''
												FROM 
													##TB_BLOQ_EXP_AC 
												WHERE
													FLAG IN(-1,-2,-3)
													AND ARQ_NOME = @ARQ_NOME
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);		
				SET @BODY_CORPO_HTML += '     </tbody> ';
				SET @BODY_CORPO_HTML += ' </table> ';
				SET @BODY_CORPO_HTML += ' <br/><br/> ';			

				SELECT TOP 1 
					@ARQUIVO_NS = ARQUIVO_NS
					,@ARQUIVO_NOME = ARQUIVO_NM 
					,@PATHNAME_AUX = ARQUIVO_PATHNAME
				FROM 
					##TB_ARQUIVO_BLOQ 
				WHERE 
						ARQUIVO_NM = @ARQ_NOME;

				SET @PATHNAME_AUX +=  '\' + @ARQUIVO_NOME;
				SET @CMD_SHELL = 'move /Y "' + @PATHNAME_AUX + '" "' + @PATHNAME_ORIG + '"';
				IF(LEN(LTRIM(RTRIM(@CMD_SHELL))) > 0)BEGIN
					EXEC master.dbo.xp_cmdshell @command_string = @CMD_SHELL;
				END;

				DELETE FROM ##TB_ARQUIVO_BLOQ WHERE ARQUIVO_NM = @ARQ_NOME;

			END ELSE BEGIN

				SELECT @COUNT = COUNT(BLOQ_EXP_AC_NS) FROM ##TB_BLOQ_EXP_AC WHERE ARQ_NOME = @ARQ_NOME
				SELECT @COUNT_ARQUIVO_SUCESSO = COUNT(BLOQ_EXP_AC_NS) FROM ##TB_BLOQ_EXP_AC WHERE ARQ_NOME = @ARQ_NOME AND FLAG = 2;
				SELECT @COUNT_ARQUIVO_FALHA = COUNT(BLOQ_EXP_AC_NS) FROM ##TB_BLOQ_EXP_AC WHERE ARQ_NOME = @ARQ_NOME AND FLAG != 2
				
				SET @BODY_CORPO_HTML += ' <table> ';
				SET @BODY_CORPO_HTML += '     <caption><H3>' + @SUBJECT + '</H3></caption> ';
				SET @BODY_CORPO_HTML += '     <thead> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <th>Origem</th> ';
				SET @BODY_CORPO_HTML += '             <th>Inicio</th> ';
				SET @BODY_CORPO_HTML += '             <th>Fim</th> ';
				SET @BODY_CORPO_HTML += '             <th>Nome arquivo</th> ';
				SET @BODY_CORPO_HTML += '             <th>Usuario</th> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </thead> ';
				SET @BODY_CORPO_HTML += '     <tbody> ';
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT 
													td = (SELECT NM_CEDENTE FROM [Homolog].[dbo].[TB_CEDENTE] WHERE ID_CEDENTE = @ID_CEDENTE), '',  												
													td = CONVERT(VARCHAR(8), @DT_INICIO, 108) + ' ' + CONVERT(VARCHAR(10), @DT_INICIO, 103),  '',  
													td = CONVERT(VARCHAR(8), GETDATE(), 108) + ' ' + CONVERT(VARCHAR(10), GETDATE(), 103),  '',  
													td = @ARQ_NOME, '',
													td = @LOGIN_EC
												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);		
				SET @BODY_CORPO_HTML += '     </tbody> ';
				SET @BODY_CORPO_HTML += ' </table> ';
				SET @BODY_CORPO_HTML += ' <br/><br/> ';

				SET @BODY_CORPO_HTML += ' <table> ';
				SET @BODY_CORPO_HTML += '     <caption><H3>Resumo da movimentação</H3></caption> ';
				SET @BODY_CORPO_HTML += '     <thead> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <th>Arquivo</th> ';
				SET @BODY_CORPO_HTML += '             <th>Tipo Evento</th> ';
				SET @BODY_CORPO_HTML += '             <th>Total arquivo</th> ';
				SET @BODY_CORPO_HTML += '             <th>Total concluido com sucesso</th> ';
				SET @BODY_CORPO_HTML += '             <th>Total com erro</th> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </thead> ';
				SET @BODY_CORPO_HTML += '     <tbody> ';
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT 
													td = @ARQ_NOME, '',  													
													td = (
														CASE 
															WHEN @TIPO_EXEC = 1 THEN 'INCLUIR AÇÃO'
															WHEN @TIPO_EXEC = 2 THEN 'EXPIRAR'
															WHEN @TIPO_EXEC = 3 THEN 'EXPIRAR E INCLUIR AÇÃO'
															WHEN @TIPO_EXEC = 4 THEN 'BLOQUEAR'
															WHEN @TIPO_EXEC = 5 THEN 'BLOQUEAR E INCLUIR AÇÃO'
															WHEN @TIPO_EXEC = 6 THEN 'EXPIRAR E BLOQUEAR'
															WHEN @TIPO_EXEC = 99 THEN 'EXPIRAR, BLOQUEAR E INCLUIR AÇÃO'
															ELSE ''
															END),'',
													td = CONVERT(VARCHAR(20), @COUNT), '',
													td = CONVERT(VARCHAR(20), @COUNT_ARQUIVO_SUCESSO), '',
													td = CONVERT(VARCHAR(20), @COUNT_ARQUIVO_FALHA), ''

													

												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);		
				SET @BODY_CORPO_HTML += '     </tbody> ';
				SET @BODY_CORPO_HTML += ' </table> ';
				SET @BODY_CORPO_HTML += ' <br/><br/> ';

				IF(@COUNT_ARQUIVO_FALHA > 0)BEGIN
					SET @BODY_CORPO_HTML += ' <table> ';
					SET @BODY_CORPO_HTML += '     <caption><H3>Erro</H3></caption> ';
					SET @BODY_CORPO_HTML += '     <thead> ';
					SET @BODY_CORPO_HTML += '         <tr> ';
					SET @BODY_CORPO_HTML += '             <th>Arquivo</th> ';
					SET @BODY_CORPO_HTML += '             <th>Cliente</th> ';
					SET @BODY_CORPO_HTML += '             <th>Cliente EC</th> ';
					SET @BODY_CORPO_HTML += '             <th>CPF/CNPJ</th> ';
					SET @BODY_CORPO_HTML += '             <th>Nome</th> ';
					SET @BODY_CORPO_HTML += '             <th>Contrato</th> ';
					SET @BODY_CORPO_HTML += '             <th>Contrato EC</th> ';
					SET @BODY_CORPO_HTML += '             <th>Divida</th> ';
					SET @BODY_CORPO_HTML += '             <th>Divida EC</th> ';
					SET @BODY_CORPO_HTML += '         </tr> ';
					SET @BODY_CORPO_HTML += '     </thead> ';
					SET @BODY_CORPO_HTML += '     <tbody> ';
					SET @BODY_CORPO_HTML += CAST ( 
													(SELECT 
														td = @ARQ_NOME, '',
														td = NM_CLIENTE_CEDENTE,'',
														td = ISNULL(ID_CLIENTE,''),'',
														td = NU_CPF_CNPJ,'',
														td = NM_NOME,'',
														td = ISNULL(NM_CONTRATO,''),'',
														td = ISNULL(ID_CONTRATO,''),'',
														td = ISNULL(NM_DIVIDA,''),'',
														td = ISNULL(ID_DIVIDA,''),''
													FROM 
														##TB_BLOQ_EXP_AC 
													WHERE 
														ARQ_NOME = @ARQ_NOME 
														AND FLAG != 2
													FOR XML PATH('tr'), TYPE   
													) AS NVARCHAR(MAX) 
					);		
					SET @BODY_CORPO_HTML += '     </tbody> ';
					SET @BODY_CORPO_HTML += ' </table> ';
					SET @BODY_CORPO_HTML += ' <br/><br/> ';
				END;
				SET @CMD_SHELL = '';
				SELECT TOP 1 
					@ARQUIVO_NS = ARQUIVO_NS
					,@ARQUIVO_NOME = ARQUIVO_NM 
					,@PATHNAME_AUX = ARQUIVO_PATHNAME
				FROM 
					##TB_ARQUIVO_BLOQ 
				WHERE 
					ARQUIVO_NM = @ARQ_NOME;
					
				SET @PATHNAME_AUX +=  '\' + @ARQUIVO_NOME;
				IF(@COUNT = @COUNT_ARQUIVO_SUCESSO AND @COUNT_ARQUIVO_FALHA = 0)BEGIN
					SET @CMD_SHELL = 'move /Y "' + @PATHNAME_AUX + '" "' + @PATHNAME_DEST + '\ok"';	
				END ELSE BEGIN
					SET @CMD_SHELL = 'move /Y "' + @PATHNAME_AUX + '" "' + @PATHNAME_ORIG + '"';	
				END;

				IF(LEN(LTRIM(RTRIM(@CMD_SHELL))) > 0)BEGIN
					EXEC master.dbo.xp_cmdshell @command_string = @CMD_SHELL;
				END;				
				DELETE FROM ##TB_ARQUIVO_BLOQ WHERE ARQUIVO_NM = @ARQ_NOME;
			END;
			IF(LEN(LTRIM(RTRIM(@BODY_CORPO_HTML))) > 0) BEGIN
				SET @BODY_ENVIO_HTML =  @BODY_CABECALHO_HTML + @BODY_CORPO_HTML ;			
			END;
			IF(LEN(LTRIM(RTRIM(@BODY_ENVIO_HTML))) > 0) BEGIN
			
				INSERT INTO  TB_EMAIL_ENVIO(
					EMAIL_ENVIO_PROFILE_NAME
					--,EMAIL_ENVIO_RECIPIENTES
					,EMAIL_ENVIO_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
				)
				SELECT
					'EmailHomolog'
					--,'suporte@Homolog.com.br'
					--,'wanderlei.silva@Homolog.com.br;anderson.andrade@Homolog.com.br;paulo.sousa@Homolog.com.br;'
					,'anderson.andrade@Homolog.com.br;'
					,@SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High'
			END;
						
			DELETE FROM ##TB_BLOQ_EXP_AC WHERE ARQ_NOME = @ARQ_NOME;
		END;
		EXEC [dbo].[_PROC_ENVIO_EMAIL]

		
	END TRY 
	BEGIN CATCH		
		SELECT 
			@ERROR_NUMBER_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_NUMBER()), '')
			,@ERROR_SEVERITY_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_SEVERITY()), '')
			,@ERROR_STATE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_STATE()), '')
			,@ERROR_PROCEDURE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_PROCEDURE()), '')
			,@ERROR_LINE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_LINE()), '')
			,@ERROR_MESSAGE_AUX = ISNULL(CONVERT(VARCHAR(500), ERROR_MESSAGE()), '');
	
		/*EXEC [dbo].[__PROC_SQL_ERROR_EMAIL]
			@ERROR_NUMBER = @ERROR_NUMBER_AUX
			,@ERROR_SEVERITY = @ERROR_SEVERITY_AUX
			,@ERROR_STATE = @ERROR_STATE_AUX
			,@ERROR_PROCEDURE = @ERROR_PROCEDURE_AUX
			,@ERROR_LINE = @ERROR_LINE_AUX
			,@ERROR_MESSAGE = @ERROR_MESSAGE_AUX;
		EXEC [dbo].[_PROC_ENVIO_EMAIL];*/
		
	END CATCH; 
END;