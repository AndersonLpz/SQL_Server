USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_ENVIO_DEMONSTRATIVO', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_ENVIO_DEMONSTRATIVO]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE _PROC_ENVIO_DEMONSTRATIVO(
	@TIPO_ID							BIGINT = 0
) 
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 03/10/2022	
	*	DATA MOD..: 14/10/2022	
	*	DESCRIÇÃO.: Procedure para enviar o demonstrativo dos clientes.
	*	EXECUTE msdb.dbo.sysmail_help_profile_sp;  retorna os perfis de envio de email
	***************************************************************************************************************************************************************************************/
	DECLARE @FULLPATHNAME										VARCHAR(MAX) = '\\192.168.3.6\Homolog\Suporte Operacional\Demonstrativos';
	DECLARE @PATHNAME_ORIG										VARCHAR(MAX) = '\\192.168.3.6\#Homolog\_Rotinas_BD\Incluir_Acao_Demo';	
	DECLARE @ARQUIVO_NS											INT = 0;
	DECLARE @ARQUIVO_NOME										VARCHAR(255);	
	DECLARE @PATHNAME_AUX										VARCHAR(MAX) = '';
	DECLARE @FULLPATHNAME_AUX									VARCHAR(MAX) = '';
	DECLARE @DATE												DATE = GETDATE();	
	DECLARE @HORA_ATUAL											TIME = GETDATE();	
	/**************************************************************************************************************************************************************************************/	
	DECLARE @NM_BASE											VARCHAR(MAX) = '[BAIXA$]';	
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_CONSULTA										VARCHAR(MAX) = '';
	DECLARE @EXCEL_CONSULTA										VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_QUERY_ARQ_EXIST								VARCHAR(8000) = '';	
	DECLARE @RET_ARQ											TABLE(Resultado VARCHAR(MAX));
	/**************************************************************************************************************************************************************************************/
	DECLARE @TB_DEMONSTRATIVO									TABLE(ID_CEDENTE BIGINT, ID_CLIENTE BIGINT,ID_CLIENTE_ACAO BIGINT, DS_ACAO VARCHAR(3000), FLAG INT);	
	DECLARE @TB_CLIENTE_ARQUIVO									TABLE(ID_ARQUIVO BIGINT, NM_ARQUIVO VARCHAR(500), FLAG INT);	
	/**************************************************************************************************************************************************************************************/
	DECLARE @ID_CLIENTE											BIGINT = 0;
	DECLARE @ID_CEDENTE											BIGINT = 0;
	DECLARE @ID_CLIENTE_ACAO									BIGINT = 0;
	DECLARE @NM_CONTRATO_CEDENTE								VARCHAR(50) = '';	
	DECLARE @DS_ACAO											VARCHAR(3000) = '';	
	DECLARE @ID_ARQUIVO											BIGINT = 0;
	DECLARE @NM_ARQUIVO											VARCHAR(500) = '';
	DECLARE @FLAG												INT = 0;		
	DECLARE @COUNT												INT = 0;		
	/**************************************************************************************************************************************************************************************/
	DECLARE @BLOQ_EXP_AC_NS										BIGINT = 0; 
	DECLARE @ARQ_NOME											VARCHAR(350) = '';	
	DECLARE @LOGIN_EC											VARCHAR(50) = '';
	DECLARE @NU_CPF_CNPJ										BIGINT = 0;
	DECLARE @NM_NOME											VARCHAR(50) = '';
	DECLARE @ID_USUARIO											BIGINT = 1886;
	DECLARE @ID_ACAO											BIGINT = 2075;
	DECLARE @DS_ACAO_AUX										VARCHAR(3000) = '';
	DECLARE @DS_ACAO_AUX_1										VARCHAR(3000) = '';
	DECLARE @DS_ACAO_DEMO										VARCHAR(3000) = 'DEMONSTRATIVO ANEXADO: ';
	DECLARE @DT_DEVOLUCAO										DATETIME = GETDATE()
	DECLARE @TIME_DEVOLUCAO										TIME = GETDATE()
	DECLARE @FLAG_ADD_CONT_DIVI									BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @TBCMDDIR_TEMP_PATHNAME								VARCHAR(MAX) = '';
	DECLARE @TBCMDDIR_TEMP_NAME									VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************/
	DECLARE @EMAIL_ENVIO_PROFILE_NAME							VARCHAR(100) = '';
	DECLARE @ID_EMAIL											BIGINT = 0;
	DECLARE @NM_EMAIL											VARCHAR(100) = '';
	DECLARE @NM_CEDENTE											VARCHAR(100) = '';
	DECLARE @NM_EMAIL_CEDENTE									VARCHAR(100) = '';
	DECLARE @EMAIL_ENVIO_SUBJECT								VARCHAR(1000) = 'Demonstrativo de Despesas';
	DECLARE @EMAIL_ENVIO_SUBJECT_AUX							VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_FILE_ATT								VARCHAR(2000) = '';
	DECLARE @BODY_ENVIO_HTML									NVARCHAR(MAX) = '' ;
	DECLARE @EMAIL_ENVIO_NS										BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @SQL_ERROR										VARCHAR(MAX) = ''; 
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY
	/***************************************************************************************************************************************************************************************
	*	- CRIA TABELA TEMPORARIA
	***************************************************************************************************************************************************************************************/
		IF (Object_ID('tempDB..##TB_ARQUIVO_DEMONSRTATIVO','U') is not null)BEGIN
			DROP TABLE ##TB_ARQUIVO_DEMONSRTATIVO;
		END;
		CREATE TABLE ##TB_ARQUIVO_DEMONSRTATIVO (
			 ARQUIVO_NS					BIGINT
			,ARQUIVO_NM					VARCHAR(MAX)
			,ARQUIVO_TAMANHO				BIGINT
			,ARQUIVO_DT					DATETIME
			,ARQUIVO_TP					VARCHAR(10)
			,ARQUIVO_PATHNAME				VARCHAR(MAX)
			,ARQUIVO_FLAG					BIGINT DEFAULT 0			 
		);
	/**************************************************************************************************************************************************************************************/
		IF (Object_ID('tempDB..##TB_DEMONSRTATIVO_AC','U') is not null)BEGIN
			DROP TABLE ##TB_DEMONSRTATIVO_AC;
		END;
		CREATE TABLE ##TB_DEMONSRTATIVO_AC(
			 BLOQ_EXP_AC_NS				INT IDENTITY(1, 1)
			,ARQ_NOME					VARCHAR(350)
			,LOGIN_EC					VARCHAR(50)
			,ID_CEDENTE					VARCHAR(350) 
			,NU_CPF_CNPJ				VARCHAR(350)
			,NM_NOME					VARCHAR(50) 
			,DS_ACAO					VARCHAR(500) 
			,FLAG						BIGINT
		);
	/***************************************************************************************************************************************************************************************
	*	Envio do relatorio dos anexos enviados no dia anterior
	***************************************************************************************************************************************************************************************/		
		IF (@TIPO_ID = 0) BEGIN
			
			SET @DATE = DATEADD(DAY, -1, GETDATE());
	
			IF((SELECT (DATEPART(DW,@DATE))) = 1) BEGIN				
				SET @DATE = DATEADD(DAY, -3, GETDATE())
			END;
		/***************************************************************************************************************************************************************************************
		*	ENVIO DO RESUMO DE ENVIO DOS DEMONSTRATIVOS - ALLCARE
		***************************************************************************************************************************************************************************************/
			IF((SELECT COUNT(DEMONSTRATIVO_NS) FROM TB_DEMONSTRATIVO WHERE CONVERT(DATE, DEMONSTRATIVO_DT) = @DATE AND ID_CEDENTE IN (55, 77)) > 0) BEGIN
				SET @BODY_ENVIO_HTML = '';
				SET @BODY_ENVIO_HTML += ' <table> ';
				SET @BODY_ENVIO_HTML += '     <caption><H3> Envio de Demonstrativo </H3></caption> ';
				SET @BODY_ENVIO_HTML += '     <thead> ';
				SET @BODY_ENVIO_HTML += '         <tr> ';
				SET @BODY_ENVIO_HTML += '             <th>Cedente</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Cliente E.C.</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Nome</th> ';
				SET @BODY_ENVIO_HTML += '             <th>E-mail</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Arquivo</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Data de Envio</th> ';
				SET @BODY_ENVIO_HTML += '         </tr> ';
				SET @BODY_ENVIO_HTML += '     </thead> ';
				SET @BODY_ENVIO_HTML += '     <tbody> ';
				SET @BODY_ENVIO_HTML += CAST ( 
												(
												SELECT
													td = DB_CEDE.NM_CEDENTE , '',
													td = DB_CLIE.ID_CLIENTE, '',
													td = DB_CLIE.NM_NOME, '',
													td = DB_CLEM.NM_EMAIL, '',
													td = DB_CLAR.NM_ARQUIVO, '',
													td = CONVERT(VARCHAR(10), DB_DEMO.DEMONSTRATIVO_DT, 108) + ' ' + CONVERT(VARCHAR(10), DB_DEMO.DEMONSTRATIVO_DT, 103)
												FROM 
													TB_DEMONSTRATIVO										DB_DEMO
													JOIN [Homolog].[dbo].[TB_CEDENTE]					DB_CEDE ON DB_DEMO.ID_CEDENTE = DB_CEDE.ID_CEDENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE]					DB_CLIE ON DB_DEMO.ID_CLIENTE = DB_CLIE.ID_CLIENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE_ARQUIVO]			DB_CLAR ON DB_DEMO.ID_ARQUIVO = DB_CLAR.ID_ARQUIVO
													JOIN [Homolog].[dbo].[TB_CLIENTE_EMAIL]			DB_CLEM ON DB_DEMO.ID_EMAIL = DB_CLEM.ID_EMAIL

												WHERE
													CONVERT(DATE, DEMONSTRATIVO_DT) =  @DATE
													AND DB_DEMO.ID_CEDENTE IN (55, 77)

												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);		
				SET @BODY_ENVIO_HTML += '     </tbody> ';
				SET @BODY_ENVIO_HTML += ' </table> ';
				SET @BODY_ENVIO_HTML += ' <br/><br/> ';

				INSERT INTO  TB_EMAIL_ENVIO(
					 EMAIL_ENVIO_PROFILE_NAME
					,EMAIL_ENVIO_RECIPIENTES
					,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
				)
				SELECT
					 'EmailHomolog'
					,'aryane.luz@Homolog.com.br'
					,'anderson.andrade@Homolog.com.br;'
					,@EMAIL_ENVIO_SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High';
			END;
		/***************************************************************************************************************************************************************************************
		*	ENVIO DO RESUMO DE ENVIO DOS DEMONSTRATIVOS - FLEURY
		***************************************************************************************************************************************************************************************/			
			IF((SELECT COUNT(DEMONSTRATIVO_NS) FROM TB_DEMONSTRATIVO WHERE CONVERT(DATE, DEMONSTRATIVO_DT) = @DATE AND ID_CEDENTE IN (62)) > 0) BEGIN
				SET @BODY_ENVIO_HTML = '';
				SET @BODY_ENVIO_HTML += ' <table> ';
				SET @BODY_ENVIO_HTML += '     <caption><H3> Envio de Demonstrativo </H3></caption> ';
				SET @BODY_ENVIO_HTML += '     <thead> ';
				SET @BODY_ENVIO_HTML += '         <tr> ';
				SET @BODY_ENVIO_HTML += '             <th>Cedente</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Cliente E.C.</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Nome</th> ';
				SET @BODY_ENVIO_HTML += '             <th>E-mail</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Arquivo</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Data de Envio</th> ';
				SET @BODY_ENVIO_HTML += '         </tr> ';
				SET @BODY_ENVIO_HTML += '     </thead> ';
				SET @BODY_ENVIO_HTML += '     <tbody> ';
				SET @BODY_ENVIO_HTML += CAST ( 
												(
												SELECT
													td = DB_CEDE.NM_CEDENTE , '',
													td = DB_CLIE.ID_CLIENTE, '',
													td = DB_CLIE.NM_NOME, '',
													td = DB_CLEM.NM_EMAIL, '',
													td = DB_CLAR.NM_ARQUIVO, '',
													td = CONVERT(VARCHAR(10), DB_DEMO.DEMONSTRATIVO_DT, 108) + ' ' + CONVERT(VARCHAR(10), DB_DEMO.DEMONSTRATIVO_DT, 103)
												FROM 
													TB_DEMONSTRATIVO										DB_DEMO
													JOIN [Homolog].[dbo].[TB_CEDENTE]					DB_CEDE ON DB_DEMO.ID_CEDENTE = DB_CEDE.ID_CEDENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE]					DB_CLIE ON DB_DEMO.ID_CLIENTE = DB_CLIE.ID_CLIENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE_ARQUIVO]			DB_CLAR ON DB_DEMO.ID_ARQUIVO = DB_CLAR.ID_ARQUIVO
													JOIN [Homolog].[dbo].[TB_CLIENTE_EMAIL]			DB_CLEM ON DB_DEMO.ID_EMAIL = DB_CLEM.ID_EMAIL

												WHERE
													CONVERT(DATE, DEMONSTRATIVO_DT) =  @DATE
													AND DB_DEMO.ID_CEDENTE IN (62)

												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);		
				SET @BODY_ENVIO_HTML += '     </tbody> ';
				SET @BODY_ENVIO_HTML += ' </table> ';
				SET @BODY_ENVIO_HTML += ' <br/><br/> ';

				INSERT INTO  TB_EMAIL_ENVIO(
					EMAIL_ENVIO_PROFILE_NAME
					,EMAIL_ENVIO_RECIPIENTES
					,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
				)
				SELECT
					 'EmailHomolog'
					,'angela.ferreira@Homolog.com.br;'
					,'anderson.andrade@Homolog.com.br;'
					,@EMAIL_ENVIO_SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High';
			END;
		/***************************************************************************************************************************************************************************************
		*	ENVIO DO RESUMO DE ENVIO DOS DEMONSTRATIVOS - Rede Dor
		***************************************************************************************************************************************************************************************/
			IF((SELECT COUNT(DEMONSTRATIVO_NS) FROM TB_DEMONSTRATIVO WHERE CONVERT(DATE, DEMONSTRATIVO_DT) = @DATE AND ID_CEDENTE IN (27)) > 0) BEGIN
				SET @BODY_ENVIO_HTML = '';
				SET @BODY_ENVIO_HTML += ' <table> ';
				SET @BODY_ENVIO_HTML += '     <caption><H3> Envio de Demonstrativo </H3></caption> ';
				SET @BODY_ENVIO_HTML += '     <thead> ';
				SET @BODY_ENVIO_HTML += '         <tr> ';
				SET @BODY_ENVIO_HTML += '             <th>Cedente</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Cliente E.C.</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Nome</th> ';
				SET @BODY_ENVIO_HTML += '             <th>E-mail</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Arquivo</th> ';
				SET @BODY_ENVIO_HTML += '             <th>Data de Envio</th> ';
				SET @BODY_ENVIO_HTML += '         </tr> ';
				SET @BODY_ENVIO_HTML += '     </thead> ';
				SET @BODY_ENVIO_HTML += '     <tbody> ';
				SET @BODY_ENVIO_HTML += CAST ( 
												(
												SELECT
													td = DB_CEDE.NM_CEDENTE , '',
													td = DB_CLIE.ID_CLIENTE, '',
													td = DB_CLIE.NM_NOME, '',
													td = DB_CLEM.NM_EMAIL, '',
													td = DB_CLAR.NM_ARQUIVO, '',
													td = CONVERT(VARCHAR(10), DB_DEMO.DEMONSTRATIVO_DT, 108) + ' ' + CONVERT(VARCHAR(10), DB_DEMO.DEMONSTRATIVO_DT, 103)
												FROM 
													TB_DEMONSTRATIVO										DB_DEMO
													JOIN [Homolog].[dbo].[TB_CEDENTE]					DB_CEDE ON DB_DEMO.ID_CEDENTE = DB_CEDE.ID_CEDENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE]					DB_CLIE ON DB_DEMO.ID_CLIENTE = DB_CLIE.ID_CLIENTE
													JOIN [Homolog].[dbo].[TB_CLIENTE_ARQUIVO]			DB_CLAR ON DB_DEMO.ID_ARQUIVO = DB_CLAR.ID_ARQUIVO
													JOIN [Homolog].[dbo].[TB_CLIENTE_EMAIL]			DB_CLEM ON DB_DEMO.ID_EMAIL = DB_CLEM.ID_EMAIL

												WHERE
													CONVERT(DATE, DEMONSTRATIVO_DT) =  @DATE
													AND DB_DEMO.ID_CEDENTE IN (27)

												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);		
				SET @BODY_ENVIO_HTML += '     </tbody> ';
				SET @BODY_ENVIO_HTML += ' </table> ';
				SET @BODY_ENVIO_HTML += ' <br/><br/> ';

				INSERT INTO  TB_EMAIL_ENVIO(
					EMAIL_ENVIO_PROFILE_NAME
					,EMAIL_ENVIO_RECIPIENTES
					,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
				)
				SELECT
					 'EmailHomolog'
					,'angela.ferreira@Homolog.com.br;vitoria.neves@Homolog.com.br;'
					,'anderson.andrade@Homolog.com.br;'
					,@EMAIL_ENVIO_SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High';
			END;
			EXEC [dbo].[_PROC_ENVIO_EMAIL];
		END;
	/***************************************************************************************************************************************************************************************
	*	Envio dos anexos
	***************************************************************************************************************************************************************************************/
		IF (@TIPO_ID = 1) BEGIN		

		--SET @DATE = '20221229'
		/***************************************************************************************************************************************************************************************
		*	Verirfica se existe pasta com a data de hoje dentro da pasta Allcare.
		***************************************************************************************************************************************************************************************/
			SET @FULLPATHNAME_AUX = @FULLPATHNAME + '\AllCare\'  + CONVERT(VARCHAR(8), @DATE, 112);

			SET @SQL_QUERY_ARQ_EXIST = 'IF EXIST "' + @FULLPATHNAME_AUX + '" ( echo 1 ) ELSE ( echo 0 )';
			
			INSERT INTO @RET_ARQ EXEC master.dbo.xp_cmdshell @command_string = @SQL_QUERY_ARQ_EXIST;
		
			IF((SELECT CONVERT(BIGINT, Resultado) FROM @RET_ARQ WHERE Resultado IS NOT NULL) > 0)BEGIN
			/***************************************************************************************************************************************************************************************
			*	Insere as informações do cliente
			***************************************************************************************************************************************************************************************/
				INSERT INTO @TB_DEMONSTRATIVO
				SELECT 
					DB_CLIE.ID_CEDENTE
					,DB_CLIE.ID_CLIENTE
					,DB_CLAC.ID_CLIENTE_ACAO
					,DB_CLAC.DS_ACAO
					,0 AS 'FLAG'
				FROM
					[Homolog].[dbo].[TB_CLIENTE]										DB_CLIE
					JOIN [Homolog].[dbo].[TB_CLIENTE_ACAO]							DB_CLAC ON DB_CLIE.ID_CLIENTE = DB_CLAC.ID_CLIENTE
					JOIN [Homolog].[dbo].[TB_CLIENTE_ARQUIVO]							DB_CLAR ON DB_CLIE.ID_CLIENTE = DB_CLAR.ID_CLIENTE
				WHERE					
					DB_CLIE.ID_CEDENTE IN (55, 77)
					AND CONVERT(DATE, DB_CLAC.DT_ACAO) = @DATE
					AND CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, DB_CLAR.DT_ENVIO)
					AND DB_CLAC.ID_ACAO = 2095
					AND DB_CLIE.ID_CLIENTE NOT IN (
						SELECT	
							DB_DEMO.ID_CLIENTE
						FROM
							[Homolog].[dbo].[TB_DEMONSTRATIVO] DB_DEMO
						WHERE
							DB_DEMO.ID_CEDENTE = DB_CLIE.ID_CEDENTE
							AND DB_DEMO.ID_CLIENTE = DB_CLIE.ID_CLIENTE
							AND DB_DEMO.ID_CLIENTE_ACAO = DB_CLAC.ID_CLIENTE_ACAO					
					);
			/***************************************************************************************************************************************************************************************
			*	Insere as informações doarquivo
			***************************************************************************************************************************************************************************************/
				IF(LEN(LTRIM(RTRIM(@FULLPATHNAME_AUX))) > 0) BEGIN
					EXEC [dbo].[__EXEC_CMDSHELL_DIR] @FULLPATHNAME = @FULLPATHNAME_AUX;
				END;

				DELETE FROM @RET_ARQ;
			END ELSE BEGIN
				DELETE FROM @RET_ARQ;
			END;
		/***************************************************************************************************************************************************************************************
		*	Verirfica se existe pasta com a data de hoje dentro da pasta Fleury.
		***************************************************************************************************************************************************************************************/
			SET @FULLPATHNAME_AUX = @FULLPATHNAME + '\Fleury\'  + CONVERT(VARCHAR(8), @DATE, 112);

			SET @SQL_QUERY_ARQ_EXIST = 'IF EXIST "' + @FULLPATHNAME_AUX + '" ( echo 1 ) ELSE ( echo 0 )';
			
			INSERT INTO @RET_ARQ EXEC master.dbo.xp_cmdshell @command_string = @SQL_QUERY_ARQ_EXIST;
		
			IF((SELECT CONVERT(BIGINT, Resultado) FROM @RET_ARQ WHERE Resultado IS NOT NULL) > 0)BEGIN
			/***************************************************************************************************************************************************************************************
			*	Insere as informações do cliente
			***************************************************************************************************************************************************************************************/
				INSERT INTO @TB_DEMONSTRATIVO
				SELECT 
					DB_CLIE.ID_CEDENTE
					,DB_CLIE.ID_CLIENTE
					,DB_CLAC.ID_CLIENTE_ACAO
					,DB_CLAC.DS_ACAO
					,0 AS 'FLAG'
				FROM
					[Homolog].[dbo].[TB_CLIENTE]										DB_CLIE
					JOIN [Homolog].[dbo].[TB_CLIENTE_ACAO]							DB_CLAC ON DB_CLIE.ID_CLIENTE = DB_CLAC.ID_CLIENTE
					JOIN [Homolog].[dbo].[TB_CLIENTE_ARQUIVO]							DB_CLAR ON DB_CLIE.ID_CLIENTE = DB_CLAR.ID_CLIENTE
				WHERE
					DB_CLIE.ID_CEDENTE IN (62)
					AND CONVERT(DATE, DB_CLAC.DT_ACAO) = @DATE
					AND CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, DB_CLAR.DT_ENVIO)
					AND DB_CLAC.ID_ACAO = 2095
					AND DB_CLIE.ID_CLIENTE NOT IN (
						SELECT	
							DB_DEMO.ID_CLIENTE
						FROM
							[Homolog].[dbo].[TB_DEMONSTRATIVO] DB_DEMO
						WHERE
							DB_DEMO.ID_CEDENTE = DB_CLIE.ID_CEDENTE
							AND DB_DEMO.ID_CLIENTE = DB_CLIE.ID_CLIENTE
							AND DB_DEMO.ID_CLIENTE_ACAO = DB_CLAC.ID_CLIENTE_ACAO					
					);
			/***************************************************************************************************************************************************************************************
			*	Insere as informações doarquivo
			***************************************************************************************************************************************************************************************/
				IF(LEN(LTRIM(RTRIM(@FULLPATHNAME_AUX))) > 0) BEGIN
					EXEC [dbo].[__EXEC_CMDSHELL_DIR] @FULLPATHNAME = @FULLPATHNAME_AUX;
				END;

				DELETE FROM @RET_ARQ;
			END ELSE BEGIN
				DELETE FROM @RET_ARQ;
			END;
		/***************************************************************************************************************************************************************************************
		*	Verirfica se existe pasta com a data de hoje dentro da pasta Rede Dor.
		***************************************************************************************************************************************************************************************/
			SET @FULLPATHNAME_AUX = @FULLPATHNAME + '\Rede Dor\'  + CONVERT(VARCHAR(8), @DATE, 112);

			SET @SQL_QUERY_ARQ_EXIST = 'IF EXIST "' + @FULLPATHNAME_AUX + '" ( echo 1 ) ELSE ( echo 0 )';
			
			INSERT INTO @RET_ARQ EXEC master.dbo.xp_cmdshell @command_string = @SQL_QUERY_ARQ_EXIST;
		
			IF((SELECT CONVERT(BIGINT, Resultado) FROM @RET_ARQ WHERE Resultado IS NOT NULL) > 0)BEGIN
			/***************************************************************************************************************************************************************************************
			*	Insere as informações do cliente
			***************************************************************************************************************************************************************************************/
				INSERT INTO @TB_DEMONSTRATIVO
				SELECT 
					DB_CLIE.ID_CEDENTE
					,DB_CLIE.ID_CLIENTE
					,DB_CLAC.ID_CLIENTE_ACAO
					,DB_CLAC.DS_ACAO
					,0 AS 'FLAG'
				FROM
					[Homolog].[dbo].[TB_CLIENTE]										DB_CLIE
					JOIN [Homolog].[dbo].[TB_CLIENTE_ACAO]							DB_CLAC ON DB_CLIE.ID_CLIENTE = DB_CLAC.ID_CLIENTE
					JOIN [Homolog].[dbo].[TB_CLIENTE_ARQUIVO]							DB_CLAR ON DB_CLIE.ID_CLIENTE = DB_CLAR.ID_CLIENTE
				WHERE
					DB_CLIE.ID_CEDENTE IN (27)
					AND CONVERT(DATE, DB_CLAC.DT_ACAO) = @DATE
					AND CONVERT(DATE, DB_CLAC.DT_ACAO) = CONVERT(DATE, DB_CLAR.DT_ENVIO)
					AND DB_CLAC.ID_ACAO = 2095
					AND DB_CLIE.ID_CLIENTE NOT IN (
						SELECT	
							DB_DEMO.ID_CLIENTE
						FROM
							[Homolog].[dbo].[TB_DEMONSTRATIVO] DB_DEMO
						WHERE
							DB_DEMO.ID_CEDENTE = DB_CLIE.ID_CEDENTE
							AND DB_DEMO.ID_CLIENTE = DB_CLIE.ID_CLIENTE
							AND DB_DEMO.ID_CLIENTE_ACAO = DB_CLAC.ID_CLIENTE_ACAO					
					);
			/***************************************************************************************************************************************************************************************
			*	Insere as informações doarquivo
			***************************************************************************************************************************************************************************************/
				IF(LEN(LTRIM(RTRIM(@FULLPATHNAME_AUX))) > 0) BEGIN
					EXEC [dbo].[__EXEC_CMDSHELL_DIR] @FULLPATHNAME = @FULLPATHNAME_AUX;
				END;

				DELETE FROM @RET_ARQ;
			END ELSE BEGIN
				DELETE FROM @RET_ARQ;
			END;			
		/***************************************************************************************************************************************************************************************
		*	
		***************************************************************************************************************************************************************************************/
			WHILE(EXISTS(SELECT TOP 1 ID_CLIENTE FROM @TB_DEMONSTRATIVO ))BEGIN			
			/***************************************************************************************************************************************************************************************
			*	Recupera as informações da tabela temporaria @TB_DEMONSTRATIVO
			***************************************************************************************************************************************************************************************/
				SELECT 
					@ID_CLIENTE = ID_CLIENTE
					,@ID_CEDENTE = ID_CEDENTE
					,@ID_CLIENTE_ACAO = ID_CLIENTE_ACAO
					,@DS_ACAO = DS_ACAO
				FROM
					@TB_DEMONSTRATIVO;	
			/***************************************************************************************************************************************************************************************
			*	Reseta a informação da variavel
			***************************************************************************************************************************************************************************************/
				SET @FLAG = 0;
				SET @EMAIL_ENVIO_SUBJECT_AUX =  '';
				SET @EMAIL_ENVIO_FILE_ATT = '';
				SET @ID_EMAIL = 0;
			/***************************************************************************************************************************************************************************************
			*	verifica se existe o arquivo anexado.
			***************************************************************************************************************************************************************************************/
				DELETE FROM @TB_CLIENTE_ARQUIVO;
				INSERT INTO @TB_CLIENTE_ARQUIVO
				SELECT 
					 ID_ARQUIVO
					,NM_ARQUIVO
					, 0
				FROM 
					[Homolog].[dbo].[TB_CLIENTE_ARQUIVO] 
				WHERE 
					ID_CLIENTE = @ID_CLIENTE 
					AND CONVERT(DATE, DT_ENVIO) = @DATE;
			
				WHILE(EXISTS(SELECT TOP 1 ID_ARQUIVO FROM @TB_CLIENTE_ARQUIVO WHERE FLAG = 0 ))BEGIN	
					SELECT TOP 1 @ID_ARQUIVO = ID_ARQUIVO, @NM_ARQUIVO = NM_ARQUIVO FROM @TB_CLIENTE_ARQUIVO WHERE FLAG = 0;	
		
					IF(CHARINDEX(SUBSTRING(@NM_ARQUIVO, 0, CHARINDEX('.', @NM_ARQUIVO)), @DS_ACAO) > 0) BEGIN					
						SELECT						
							@TBCMDDIR_TEMP_PATHNAME = ISNULL(TBCMDDIR_TEMP_PATHNAME, '')
							,@TBCMDDIR_TEMP_NAME = ISNULL(TBCMDDIR_TEMP_NAME, '')
						FROM
							__TBCMDDIR_TEMP
						WHERE
							TBCMDDIR_TEMP_NAME = @NM_ARQUIVO;

						IF(LEN(LTRIM(RTRIM(@TBCMDDIR_TEMP_NAME))) > 0)BEGIN
					/***************************************************************************************************************************************************************************************
					*	INSERE AS INFORMASÇÕES DO ASSUNTO DO E-MAIL
					***************************************************************************************************************************************************************************************/
							IF(LEN(LTRIM(RTRIM(@EMAIL_ENVIO_SUBJECT_AUX))) = 0)BEGIN
								SET @EMAIL_ENVIO_SUBJECT_AUX =  @EMAIL_ENVIO_SUBJECT + ' - ' + SUBSTRING(@NM_ARQUIVO, 0, CHARINDEX('.', @NM_ARQUIVO));
							END ELSE BEGIN
								SET @EMAIL_ENVIO_SUBJECT_AUX +=  '; ' + SUBSTRING(@NM_ARQUIVO, 0, CHARINDEX('.', @NM_ARQUIVO));
							END;							
					/***************************************************************************************************************************************************************************************
					*	INSERE AS INFORMASÇÕES DO ANEXO DO E-MAIL
					***************************************************************************************************************************************************************************************/
							IF(LEN(LTRIM(RTRIM(@EMAIL_ENVIO_FILE_ATT))) = 0)BEGIN
								SET @EMAIL_ENVIO_FILE_ATT = @TBCMDDIR_TEMP_PATHNAME + '\' + @TBCMDDIR_TEMP_NAME;
							END ELSE BEGIN
								SET @EMAIL_ENVIO_FILE_ATT += ';' + @TBCMDDIR_TEMP_PATHNAME + '\' + @TBCMDDIR_TEMP_NAME;
							END;

						END;

						DELETE FROM __TBCMDDIR_TEMP WHERE TBCMDDIR_TEMP_NAME = @NM_ARQUIVO; 						
						UPDATE @TB_CLIENTE_ARQUIVO SET FLAG = 1 WHERE ID_ARQUIVO = @ID_ARQUIVO;
					END ELSE BEGIN
						UPDATE @TB_CLIENTE_ARQUIVO SET FLAG = -1 WHERE ID_ARQUIVO = @ID_ARQUIVO;
					END;					
				END;

			/***************************************************************************************************************************************************************************************
			*	SE TIVER ANEXO E ASSUNTO RECUPERA AS INFORMAÇÕES DO EMAIL DO CLIENTE.
			***************************************************************************************************************************************************************************************/
				IF(LEN(LTRIM(RTRIM(@EMAIL_ENVIO_SUBJECT_AUX))) > 0 AND LEN(LTRIM(RTRIM(@EMAIL_ENVIO_FILE_ATT))) > 0)BEGIN
				/***************************************************************************************************************************************************************************************
				*	Recupera o email do cliente
				***************************************************************************************************************************************************************************************/
					SELECT TOP 1 
						@ID_EMAIL = ISNULL(ID_EMAIL, 0)
						,@NM_EMAIL = NM_EMAIL 
					FROM 
						[Homolog].[dbo].[TB_CLIENTE_EMAIL] 
					WHERE 
						ID_CLIENTE = @ID_CLIENTE 
						AND TP_HABILITADO = 1 
						AND TP_PREFERENCIAL = 1;

				END;
			/***************************************************************************************************************************************************************************************
			*	SE EXISTIR UM EMAIL
			***************************************************************************************************************************************************************************************/
				IF(@ID_EMAIL > 0) BEGIN
				/***************************************************************************************************************************************************************************************
				*	RESETA AS VARIAVEIS DO EMAIL.
				***************************************************************************************************************************************************************************************/
					SET @EMAIL_ENVIO_PROFILE_NAME = '';
					SET @NM_CEDENTE = '';
					SET @NM_EMAIL_CEDENTE = '';
					SET @BODY_ENVIO_HTML = '';
				/***************************************************************************************************************************************************************************************
				*	INICIA AS CONFIGURAÇÕES DO ENVIO DE EMAIL
				***************************************************************************************************************************************************************************************/
					SET @BODY_ENVIO_HTML += N'<p>'					
				/***************************************************************************************************************************************************************************************
				*	DEFINE A CORDIALIDADE
				***************************************************************************************************************************************************************************************/
					IF(@HORA_ATUAL >= '07:00:00' AND @HORA_ATUAL < '13:00:00')BEGIN			
						SET @BODY_ENVIO_HTML += N'Bom dia.'
					END;			
					IF(@HORA_ATUAL >= '13:00:00' AND @HORA_ATUAL < '19:00:00')BEGIN			
						SET @BODY_ENVIO_HTML += N'Boa tarde.'
					END;		
					IF(@HORA_ATUAL >= '19:00:00' AND @HORA_ATUAL < '20:00:00')BEGIN			
						SET @BODY_ENVIO_HTML += N'Boa noite.'
					END;					
				/***************************************************************************************************************************************************************************************
				*	DEFINE O PROFILE NAME DE ENVIO DE EMAIL CONFORME O CEDENTE
				***************************************************************************************************************************************************************************************/
					IF (@ID_CEDENTE = 55 OR @ID_CEDENTE = 77 OR @ID_CEDENTE = 2) BEGIN
						SET @EMAIL_ENVIO_PROFILE_NAME = 'Email_Allcare';
						SET @NM_CEDENTE = 'Allcare';
						SET @NM_EMAIL_CEDENTE = 'atendimentoallcare@c4assessoria.com.br';
					END;
						
					IF (@ID_CEDENTE = 62) BEGIN
						SET @EMAIL_ENVIO_PROFILE_NAME = '';
						SET @NM_CEDENTE = 'Fleury';
						SET @NM_EMAIL_CEDENTE = '';
					END;
						
					IF (@ID_CEDENTE = 27) BEGIN
						SET @EMAIL_ENVIO_PROFILE_NAME = 'Rede Dor';
						SET @NM_CEDENTE = 'Rede Dor';
						SET @NM_EMAIL_CEDENTE = 'atendimentosaude@Homolog.com.br';
					END;
				/***************************************************************************************************************************************************************************************
				*	DEFINE O TEXTO DE ENVIO DE EMAIL
				***************************************************************************************************************************************************************************************/			
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'Segue em anexo demonstrativo de despesas, referente ao atendimento na ' + @NM_CEDENTE + '.';
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'Peço que por gentileza verifique e nos posicione.';
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'Atenciosamente, Grupo Homolog.';
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'Whatsapp: 11 97443 6680.';
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'Telefone: + 55 11 3292 6359.';	
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'E-mail: ' + @NM_EMAIL_CEDENTE + '.';
					SET @BODY_ENVIO_HTML += N'<br/> ';	
					SET @BODY_ENVIO_HTML += N'</p>';
				/***************************************************************************************************************************************************************************************
				*	INSERE NA TABELA DE ENVIO DE EMAIL
				***************************************************************************************************************************************************************************************/
					INSERT INTO  TB_EMAIL_ENVIO(
						 EMAIL_ENVIO_PROFILE_NAME
						,EMAIL_ENVIO_RECIPIENTES
						,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
						,EMAIL_ENVIO_SUBJECT
						,EMAIL_ENVIO_BODY
						,EMAIL_ENVIO_BODY_FORMAT
						,EMAIL_ENVIO_IMPORTANCE
						,EMAIL_ENVIO_FILE_ATT
					)
					SELECT
						 @EMAIL_ENVIO_PROFILE_NAME
						,@NM_EMAIL
						,'anderson.andrade@Homolog.com.br'
						,@EMAIL_ENVIO_SUBJECT_AUX
						,@BODY_ENVIO_HTML
						,'HTML'
						,'High'
						, @EMAIL_ENVIO_FILE_ATT;		
				/***************************************************************************************************************************************************************************************
				*	RETORNA O ULTIMO ID INSERIDO NA TABELA DE EMAIL
				***************************************************************************************************************************************************************************************/
					SELECT @EMAIL_ENVIO_NS = EMAIL_ENVIO_NS FROM TB_EMAIL_ENVIO WHERE EMAIL_ENVIO_NS = SCOPE_IDENTITY();	
				/***************************************************************************************************************************************************************************************
				*	INSERE NA TABELA TB_DEMONSTRATIVO
				***************************************************************************************************************************************************************************************/						
					IF(@EMAIL_ENVIO_NS > 0) BEGIN
						WHILE(EXISTS(SELECT TOP 1 ID_ARQUIVO FROM @TB_CLIENTE_ARQUIVO WHERE FLAG = 1 ))BEGIN	
							SELECT TOP 1 @ID_ARQUIVO = ID_ARQUIVO FROM @TB_CLIENTE_ARQUIVO WHERE FLAG = 1;	

							INSERT INTO TB_DEMONSTRATIVO(
								 ID_CLIENTE
								,ID_CEDENTE
								,ID_CLIENTE_ACAO
								,ID_ARQUIVO
								,ID_EMAIL
								,EMAIL_ENVIO_NS
							)
							SELECT
								 @ID_CLIENTE
								,@ID_CEDENTE	
								,@ID_CLIENTE_ACAO
								,@ID_ARQUIVO
								,@ID_EMAIL	
								,@EMAIL_ENVIO_NS;
							DELETE FROM @TB_CLIENTE_ARQUIVO WHERE ID_ARQUIVO = @ID_ARQUIVO;
						END;
					END;
				/***************************************************************************************************************************************************************************************
				*	INSERE NA TABELA [TB_CLIENTE_ACAO] a tabulação de enviado
				***************************************************************************************************************************************************************************************/
					INSERT INTO [Homolog].[dbo].[TB_CLIENTE_ACAO]
					SELECT
						 @ID_CLIENTE
						,GETDATE()
						,2096
						,1886
						,REPLACE(@EMAIL_ENVIO_SUBJECT_AUX, 'Demonstrativo de Despesas -', 'ENVIO DE DEMONSTRATIVO:')
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
						
					/*SELECT 
						@ID_CLIENTE as '@ID_CLIENTE'
						,@ID_CEDENTE as '@ID_CEDENTE'
						,@ID_CLIENTE_ACAO as '@ID_CLIENTE_ACAO'
						,@DS_ACAO as '@DS_ACAO'
						,@ID_ARQUIVO as '@ID_ARQUIVO'
						,@NM_ARQUIVO as '@NM_ARQUIVO'
						,@EMAIL_ENVIO_SUBJECT_AUX as '@EMAIL_ENVIO_SUBJECT_AUX'
						,@EMAIL_ENVIO_FILE_ATT as '@EMAIL_ENVIO_FILE_ATT'
						,@NM_EMAIL AS '@NM_EMAIL'*/
			
				END ELSE BEGIN
					INSERT INTO [Homolog].[dbo].[TB_CLIENTE_ACAO]
					SELECT
						 @ID_CLIENTE
						,GETDATE()
						,2096
						,1886
						,'NAO FOI POSSIVEL ENVIAR, POIS O CLIENTE NAO TEM UM EMAIL(PREFERENCIAL OU CADASTRADO).'
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
				END;		
				DELETE FROM @TB_DEMONSTRATIVO WHERE ID_CEDENTE = @ID_CEDENTE AND ID_CLIENTE = @ID_CLIENTE
			END;

			DELETE FROM  __TBCMDDIR_TEMP WHERE TBCMDDIR_TEMP_PATHNAME LIKE '%Demonstrativos%';

			EXEC [dbo].[_PROC_ENVIO_EMAIL] @TIPO_ASSINATURA = 1;
		END;	
	/***************************************************************************************************************************************************************************************
	*	INCLUIR ACIONAMENTO
	***************************************************************************************************************************************************************************************/		
		IF (@TIPO_ID = 2) BEGIN	
			SET @ID_ACAO = 2095;
			SET @DT_DEVOLUCAO = DATEADD(DAY, -1, @DT_DEVOLUCAO);		
			EXEC [__PROC_CMDSHELL] @PATHNAME_CMDSHELL = @PATHNAME_ORIG, @TABELA_NOME = '##TB_ARQUIVO_DEMONSRTATIVO';

		/***************************************************************************************************************************************************************************************
		*	- VERIFICA SE EXISTE ARQUIVO NO DIRETORIO DE ORIGEM.
		***************************************************************************************************************************************************************************************/
			WHILE(EXISTS(SELECT TOP 1 ARQUIVO_NS FROM ##TB_ARQUIVO_DEMONSRTATIVO WHERE ARQUIVO_FLAG =  0))BEGIN
				SELECT TOP 1 
					@ARQUIVO_NS = ARQUIVO_NS
					,@ARQUIVO_NOME = ARQUIVO_NM 
				FROM 
					##TB_ARQUIVO_DEMONSRTATIVO 
				WHERE 
					ARQUIVO_FLAG =  0
				ORDER BY 
					ARQUIVO_NS ;			
			/***************************************************************************************************************************************************************************************
			*	- DELETA A TABELA TEMPORARIA.
			***************************************************************************************************************************************************************************************/
				IF(@ARQUIVO_NOME != 'Arq_Modelo_demonstrativo.xlsx')BEGIN
					IF(CHARINDEX('.xlsx', @ARQUIVO_NOME) > 0)BEGIN	
						SET @PATHNAME_AUX = @PATHNAME_ORIG + '\' + @ARQUIVO_NOME;

						SET @SQL_CONSULTA = 'INSERT INTO ##TB_DEMONSRTATIVO_AC SELECT ''' + @ARQUIVO_NOME + ''' AS ''ARQ_NOME'', * , 0 AS ''FLAG''';
						--SET @SQL_CONSULTA = ' SELECT ''' + @ARQUIVO_NOME + ''' AS ''ARQ_NOME'', * , 0 AS ''FLAG''';
						SET @EXCEL_CONSULTA = 'select * from ' + @NM_BASE;
			
						EXEC [dbo].[__EXEC_OPENROWSET] @CONSULTA_SQL = @SQL_CONSULTA, @CONSULTA_OPENROWSET = @EXCEL_CONSULTA, @FULLPATHNAME = @PATHNAME_AUX, @TIPO = 2;			

					END;
				END ELSE BEGIN			
					DELETE FROM ##TB_ARQUIVO_DEMONSRTATIVO WHERE ARQUIVO_NS = @ARQUIVO_NS;
				END;
				UPDATE ##TB_ARQUIVO_DEMONSRTATIVO SET ARQUIVO_FLAG = 1 WHERE ARQUIVO_NS = @ARQUIVO_NS;
			END;
		/***************************************************************************************************************************************************************************************
		*	- Veririfica se os dados da tabela temporaria exitem no sistema e faz as tratativas do mesmo.
		***************************************************************************************************************************************************************************************/
			WHILE(EXISTS(SELECT TOP 1 BLOQ_EXP_AC_NS FROM ##TB_DEMONSRTATIVO_AC WHERE FLAG =  0))BEGIN
				SELECT TOP 1 
					 @BLOQ_EXP_AC_NS = BLOQ_EXP_AC_NS
					,@ARQ_NOME = ARQ_NOME 
					,@LOGIN_EC = ISNULL(LOGIN_EC, '')
					,@ID_CEDENTE = ISNULL(ID_CEDENTE, 0)
					,@NU_CPF_CNPJ = ISNULL((CASE WHEN ISNUMERIC(NU_CPF_CNPJ) = 1 THEN CAST(CAST(NU_CPF_CNPJ AS FLOAT) AS BIGINT) ELSE 0 END), 0)
					,@NM_NOME = ISNULL(NM_NOME, 0)
					,@DS_ACAO = ISNULL(DS_ACAO, '')
					,@FLAG = FLAG
				FROM 
					##TB_DEMONSRTATIVO_AC 
				WHERE 
					FLAG = 0;
				SET @FLAG = 1;
			/***************************************************************************************************************************************************************************************
			*	- Verifica se o usuario existe no sistema.
			***************************************************************************************************************************************************************************************/			
				SET @ID_USUARIO = 0;
				SELECT TOP 1 
					 @LOGIN_EC = ISNULL(LOGIN_EC, '')
				FROM 
					##TB_DEMONSRTATIVO_AC
				WHERE
					ARQ_NOME = @ARQ_NOME
					AND LOGIN_EC IS NOT NULL;
			
				IF(LEN(LTRIM(RTRIM(@LOGIN_EC))) > 0 )BEGIN				
					SELECT @ID_USUARIO = ISNULL(ID_USUARIO,0) FROM [Homolog].[dbo].[TB_USUARIO] WHERE UPPER(LTRIM(RTRIM(NM_LOGIN))) = UPPER(LTRIM(RTRIM(@LOGIN_EC)))			
					IF(@ID_USUARIO > 0)BEGIN			
						IF((SELECT COUNT(ID_USUARIO) FROM [Homolog].[dbo].[TB_USUARIO] WHERE ID_USUARIO = @ID_USUARIO AND TP_BLOQUEIO = 1) > 0)BEGIN					
							SET @FLAG = -3;
						END;		
					END ELSE BEGIN
						SET @FLAG = -2;
					END;	
				END ELSE BEGIN
					SET @FLAG = -1;
				END;
				
		/***************************************************************************************************************************************************************************************
		*	TENTA ACHAR O CLIENTE
		***************************************************************************************************************************************************************************************/
				SELECT
					@ID_CLIENTE = ISNULL(DB_CLIE.ID_CLIENTE, 0)
				FROM
					[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
				WHERE
					DB_CLIE.ID_CEDENTE = @ID_CEDENTE
					AND DB_CLIE.NU_CPF_CNPJ = @NU_CPF_CNPJ

				IF(@ID_CLIENTE > 0)BEGIN
					SET @DS_ACAO_AUX = '';

					WHILE(LEN(LTRIM(RTRIM(@DS_ACAO))) > 0)BEGIN
						IF(LEN(LTRIM(RTRIM(@DS_ACAO_AUX))) > 0)BEGIN
							SET @DS_ACAO_AUX += '; ';
						END;

						IF(CHARINDEX(';', @DS_ACAO) > 0)BEGIN
							SET @DS_ACAO_AUX_1 = LTRIM(RTRIM(SUBSTRING(@DS_ACAO, 0, CHARINDEX(';', @DS_ACAO))))
							
							SET @DS_ACAO = LTRIM(RTRIM(SUBSTRING(@DS_ACAO,CHARINDEX(';', @DS_ACAO) + 1, LEN(LTRIM(RTRIM(@DS_ACAO))))));
						END ELSE BEGIN
							SET @DS_ACAO_AUX_1 = @DS_ACAO;							

							SET @DS_ACAO = '';
						END;

						SELECT
							@COUNT = COUNT(DB_CLAR.ID_ARQUIVO)
						FROM
							[Homolog].[dbo].[TB_CLIENTE_ARQUIVO]					DB_CLAR
						WHERE
							DB_CLAR.ID_CLIENTE = @ID_CLIENTE
							AND SUBSTRING(NM_ARQUIVO, 0, CHARINDEX('.', NM_ARQUIVO)) = LTRIM(RTRIM(@DS_ACAO_AUX_1));
						IF(@COUNT > 0)BEGIN
							SELECT
								@DS_ACAO_AUX += SUBSTRING(NM_ARQUIVO, 0, CHARINDEX('.', NM_ARQUIVO))
							FROM
								[Homolog].[dbo].[TB_CLIENTE_ARQUIVO]					DB_CLAR
							WHERE
								DB_CLAR.ID_CLIENTE = @ID_CLIENTE
								AND SUBSTRING(NM_ARQUIVO, 0, CHARINDEX('.', NM_ARQUIVO)) = LTRIM(RTRIM(@DS_ACAO_AUX_1));
						END ELSE BEGIN
							SET @FLAG = -91;
						END;
					END;

					IF(LEN(LTRIM(RTRIM(@DS_ACAO_AUX))) > 0)BEGIN					
						INSERT INTO [Homolog].[dbo].[TB_CLIENTE_ACAO]	
						SELECT
							DB_CLIE.ID_CLIENTE
							,@DT_DEVOLUCAO
							,@ID_ACAO
							,@ID_USUARIO
							,@DS_ACAO_DEMO + @DS_ACAO_AUX
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
							,null
						FROM
							[Homolog].[dbo].[TB_CLIENTE]								DB_CLIE
						WHERE
							DB_CLIE.ID_CLIENTE = @ID_CLIENTE;

					END;
				END ELSE BEGIN
					SET @FLAG = -90;
				END;

				UPDATE 
					##TB_DEMONSRTATIVO_AC 
				SET 
					 FLAG = @FLAG 
				WHERE 
					BLOQ_EXP_AC_NS = @BLOQ_EXP_AC_NS;	
			END;
				
			SELECT * FROM ##TB_DEMONSRTATIVO_AC
			
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