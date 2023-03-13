USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_REL_IMP_CARGA', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_REL_IMP_CARGA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

CREATE PROCEDURE _PROC_REL_IMP_CARGA
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 15/08/2022	
	*	DATA.....................: 29/12/2022	
	*	DESCRIÇÃO................: Procedure para verificar o decurso das dividas que estao para expirar
	***************************************************************************************************************************************************************************************/
	DECLARE @TB_CARGA_AUX									TABLE(
																CARGA_AUX_ID			BIGINT
																,CARGA_AUX_ORIGEM		VARCHAR(15)
																,CARGA_AUX_NM_ARQ		VARCHAR(500)
																,CARGA_AUX_DT			DATETIME
																,CARGA_AUX_TP_REG		VARCHAR(500)
																,CARGA_AUX_TP_EVENTO	VARCHAR(500)
																,CARGA_AUX_OK			VARCHAR(500)
																,CARGA_AUX_REJEITADO	VARCHAR(500)
															);
	DECLARE @TB_REL01										TABLE(
																CARGA_AUX_ID			BIGINT
																,CARGA_AUX_ORIGEM		VARCHAR(15)
																,CARGA_AUX_TP_REG		VARCHAR(500)
																,CARGA_AUX_TP_EVENTO	VARCHAR(500)
																,CARGA_AUX_DS_REJEICAO	VARCHAR(500)
																,CARGA_AUX_TOTAL		BIGINT
															);
	
	DECLARE @TB_REL02										TABLE(
																CARGA_AUX_NM_ORIGEM 	VARCHAR(500)
																,CARGA_AUX_TP_STATUS 	BIGINT
																,CARGA_AUX_ID_REGISTRO	BIGINT																	
																,CARGA_AUX_VL_DIVIDA	NUMERIC(18,2)
																,CARGA_AUX_DS_REGISTRO 	VARCHAR(500)
															);
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/
	DECLARE @ID_EXECUCAO									BIGINT;
	DECLARE @ID_CARGA										BIGINT;
	DECLARE @NM_ARQUIVO										VARCHAR(200);	
	DECLARE @DT_INICIO										DATETIME;
	DECLARE @DT_FIM											DATETIME;
	DECLARE @DS_STATUS_PROCESSADO							VARCHAR(MAX) = '';
	DECLARE @DS_LOG											VARCHAR(MAX);
	DECLARE @NM_CEDENTE										VARCHAR(50);
	DECLARE @NU_RETORNO										BIGINT;
	DECLARE @ID_USUARIO										BIGINT;
	DECLARE @DS_CONSULTA									VARCHAR(MAX) = '';	
	/**************************************************************************************************************************************************************************************
	*	- 
	***************************************************************************************************************************************************************************************/	
	DECLARE @SUBJECT										VARCHAR(200) = '';
	DECLARE @BODY_CABECALHO_HTML							NVARCHAR(MAX) = '' ;
	DECLARE @BODY_CORPO_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @BODY_RODAPE_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @BODY_ENVIO_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @AVISO											VARCHAR(MAX) = '';
	/**************************************************************************************************************************************************************************************
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
	/**************************************************************************************************************************************************************************************/
		WHILE(EXISTS(SELECT TOP 1 ID_EXECUCAO FROM TB_PROCESSO_EXECUCAO WHERE TP_ENVIO_EMAIL = 0 AND ID_CARGA > 0 ))BEGIN
			SELECT TOP 1 
				@ID_EXECUCAO = ID_EXECUCAO 
				,@ID_CARGA = ID_CARGA 
				,@NM_ARQUIVO = NM_ARQUIVO
				,@DT_INICIO = DT_INICIO
				,@DT_FIM = DT_FIM
				,@DS_STATUS_PROCESSADO = DS_STATUS_PROCESSADO
				,@DS_LOG = DS_LOG
				,@NU_RETORNO = NU_RETORNO
				,@ID_USUARIO = ID_USUARIO
			FROM 
				TB_PROCESSO_EXECUCAO 
			WHERE 
				TP_ENVIO_EMAIL = 0 
				AND ID_CARGA > 0
			ORDER BY
				ID_EXECUCAO;
		/**************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/				
			DELETE FROM @TB_CARGA_AUX;
			DELETE FROM @TB_REL01;
		/**************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 1;

			SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
			SET @DS_CONSULTA += ' FROM';
			SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
			SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_MOVIMENTO] B ON A.ID_CARGA = B.ID_CARGA';
			SET @DS_CONSULTA += ' WHERE';
			SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
			SET @DS_CONSULTA += ' ORDER BY B.ID_CARGA, B.TP_REGISTRO, B.TP_EVENTO';				
		
			INSERT INTO @TB_CARGA_AUX EXEC (@DS_CONSULTA);
		/**************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			IF((SELECT COUNT(CARGA_AUX_ID) FROM @TB_CARGA_AUX) > 0)BEGIN
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'CLIENTE' ) > 0)BEGIN
					
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 2;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(1,7,29) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'ENDEREÇO' ) > 0)BEGIN
										
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 3;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(2) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'EMAIL' ) > 0)BEGIN
										
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 4;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(31) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'TELEFONE' ) > 0)BEGIN
										
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 5;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(3,24) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'CONTRATO' ) > 0)BEGIN
										
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 6;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(4,5) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'DÍVIDA' ) > 0)BEGIN
										
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 7;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(6,8,14) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'ACORDO' ) > 0)BEGIN
										
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 8;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(11,12,13,30) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_TP_REG)  FROM @TB_CARGA_AUX WHERE CARGA_AUX_ID = @ID_CARGA AND CARGA_AUX_TP_REG = 'FATURA' ) > 0)BEGIN
										
					SELECT @DS_CONSULTA = DS_CONSULTA FROM [Homolog].[dbo].[TB_RELATORIO_CONSULTA] WHERE ID_RELATORIO = 9 AND NU_CONSULTA = 9;
					
					SELECT @DS_CONSULTA = SUBSTRING( @DS_CONSULTA, 0, CHARINDEX('FROM', UPPER(@DS_CONSULTA)) -1)
					SET @DS_CONSULTA  =  REPLACE(REPLACE(REPLACE(REPLACE(@DS_CONSULTA, 'B.ID_CLIENTE,', ''), 'C.NU_CPF_CNPJ,',''), 'B.NM_IDENTIFICADOR,',''), 'A.DT_PROCESSAMENTO DT_CARGA,','')
					SET @DS_CONSULTA += ' , COUNT (B.DS_REJEICAO) AS ''TOTAL''';
					SET @DS_CONSULTA += ' FROM';
					SET @DS_CONSULTA += '     [Homolog].[dbo].[TB_CARGA] A';
					SET @DS_CONSULTA += '     JOIN [Homolog].[dbo].[TB_CARGA_REJEICAO] B ON A.ID_CARGA = B.ID_CARGA';
					SET @DS_CONSULTA += '     LEFT OUTER JOIN [Homolog].[dbo].[TB_CLIENTE] C ON B.ID_CLIENTE = C.ID_CLIENTE';
					SET @DS_CONSULTA += ' WHERE';
					SET @DS_CONSULTA += '     A.ID_CARGA = ' + CONVERT(VARCHAR(20), @ID_CARGA);
					SET @DS_CONSULTA += '     AND B.TP_REGISTRO IN(15,28) ';
					SET @DS_CONSULTA += ' GROUP BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';	
					SET @DS_CONSULTA += ' ORDER BY A.ID_CARGA, A.NM_ORIGEM, TP_REGISTRO ,TP_EVENTO, B.DS_REJEICAO';		

					INSERT INTO @TB_REL01 EXEC (@DS_CONSULTA);
				END;
			END;
		/**************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			SELECT TOP 1
				@NM_CEDENTE = DB_CEDE.NM_CEDENTE							
			FROM
				[Homolog].[dbo].[TB_CARGA_CLIENTE]										DB_CACL
				JOIN [Homolog].[dbo].[TB_CEDENTE]											DB_CEDE ON (DB_CACL.NM_CEDENTE_CEDENTE = DB_CEDE.NM_CEDENTE_CEDENTE)
			WHERE
				DB_CACL.ID_CARGA = @ID_CARGA;
		/**************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			SET @SUBJECT = 'Importação ID: ' + CONVERT(VARCHAR(20), @ID_CARGA) + ' Cliente: ' + @NM_CEDENTE;			
			SET @BODY_CABECALHO_HTML = '';
			SET @BODY_CORPO_HTML = '';
			SET @BODY_CABECALHO_HTML += N'<H2 style="text-align:center;width: 1400px;"> Resumo da importação.</H2>';
			SET @AVISO = '';
			IF((SELECT COUNT(ID_CARGA) FROM [Homolog].[dbo].[TB_CARGA] WHERE NM_ARQUIVO = @NM_ARQUIVO) > 1)BEGIN
				SET @AVISO = N' <H4 style="color:#f5b7b1">ARQUIVO IMPORTADO ';
				SET @AVISO += (SELECT CONVERT(VARCHAR(10), COUNT(ID_CARGA)) FROM [Homolog].[dbo].[TB_CARGA] WHERE NM_ARQUIVO = @NM_ARQUIVO );
				SET @AVISO += ' VEZES.</H4>';
			END;
		/**************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			SET @BODY_CORPO_HTML += ' <table> ';
			SET @BODY_CORPO_HTML += '     <caption><H3>' + @NM_CEDENTE + '</H3> ' + @AVISO +'</caption> ';
			SET @BODY_CORPO_HTML += '     <thead> ';
			SET @BODY_CORPO_HTML += '         <tr> ';
			SET @BODY_CORPO_HTML += '             <th>ID</th> ';
			SET @BODY_CORPO_HTML += '             <th>Origem</th> ';
			SET @BODY_CORPO_HTML += '             <th>Status</th> ';
			SET @BODY_CORPO_HTML += '             <th>Inicio</th> ';
			SET @BODY_CORPO_HTML += '             <th>Fim</th> ';
			SET @BODY_CORPO_HTML += '             <th>Nome arquivo</th> ';
			SET @BODY_CORPO_HTML += '             <th>Usuario</th> ';
			SET @BODY_CORPO_HTML += '         </tr> ';
			SET @BODY_CORPO_HTML += '     </thead> ';
			SET @BODY_CORPO_HTML += '     <tbody> ';
			SET @BODY_CORPO_HTML += CAST ( 
											(SELECT 
												td = CONVERT(VARCHAR(20), @ID_CARGA), '',  
												td = (SELECT NM_ORIGEM FROM [Homolog].[dbo].[TB_CARGA] WHERE ID_CARGA = @ID_CARGA), '',
												td = (CASE WHEN @NU_RETORNO = 0 THEN 'IMPORTADO COM SUCESSO'	ELSE 'ERRO NA IMPORTAÇÃO' END), '',  
												td = CONVERT(VARCHAR(8), @DT_INICIO, 108) + ' ' + CONVERT(VARCHAR(10), @DT_INICIO, 103), '',  
												td = CONVERT(VARCHAR(8), ISNULL(@DT_FIM, '1999 00:00:00.000'), 108) + ' ' + CONVERT(VARCHAR(10), ISNULL(@DT_FIM, '1999 00:00:00.000'), 103),  '',  
												td = @NM_ARQUIVO, '',
												td = (
													CASE
														WHEN @ID_USUARIO = 0 THEN 'Execução Automatica'
														ELSE (SELECT NM_LOGIN FROM [Homolog].[dbo].[TB_USUARIO] WHERE ID_USUARIO = @ID_USUARIO)
														END
												), ''
											FOR XML PATH('tr'), TYPE   
											) AS NVARCHAR(MAX) 
			);		
			SET @BODY_CORPO_HTML += '     </tbody> ';
			SET @BODY_CORPO_HTML += ' </table> ';
			SET @BODY_CORPO_HTML += ' <br/><br/> ';
		/**************************************************************************************************************************************************************************************
		*	- 
		***************************************************************************************************************************************************************************************/
			IF(@NU_RETORNO != 0) BEGIN						
				SET @BODY_CORPO_HTML += '<table>';
				SET @BODY_CORPO_HTML += '     <caption><H3>Descrição do erro</caption> ';
				SET @BODY_CORPO_HTML += '     <thead> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <th>Retorno</th> ';
				SET @BODY_CORPO_HTML += '             <th>Descrição retorno</th> ';
				SET @BODY_CORPO_HTML += '             <th>Log</th> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </thead> ';
				SET @BODY_CORPO_HTML += '     <tbody> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <td>' + CONVERT(VARCHAR(20), @NU_RETORNO) + '</td> ';
				SET @BODY_CORPO_HTML += '             <td>' + @DS_STATUS_PROCESSADO + '</td> ';
				SET @BODY_CORPO_HTML += '             <td>' + @DS_LOG + '</td> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </tbody> ';
				SET @BODY_CORPO_HTML += ' </table> ';
				SET @BODY_CORPO_HTML += ' <br/><br/> ';
			END ELSE BEGIN
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				DELETE FROM @TB_REL02;

				INSERT INTO @TB_REL02
				SELECT DISTINCT
						DB_CARG.NM_ORIGEM 
						,DB_CADI.TP_STATUS 
						,DB_CADI.ID_REGISTRO
						,VL_DIVIDA
						,(SELECT TOP 1 DB_CARE.DS_REJEICAO FROM [Homolog].[dbo].[TB_CARGA_REJEICAO] DB_CARE WHERE DB_CARG.ID_CARGA = DB_CARE.ID_CARGA AND DB_CADI.TP_STATUS = DB_CARE.TP_STATUS and DB_CARE.TP_REGISTRO IN(6,14) ) as 'Valor total'
				FROM 
					[Homolog].[dbo].[TB_CARGA]										DB_CARG    
					JOIN [Homolog].[dbo].[TB_CARGA_DIVIDA]							DB_CADI ON DB_CARG.ID_CARGA = DB_CADI.ID_CARGA  
				WHERE 
					DB_CARG.ID_CARGA = @ID_CARGA;
			/**************************************************************************************************************************************************************************************
			*	- 
			***************************************************************************************************************************************************************************************/
				IF((SELECT COUNT(CARGA_AUX_ID_REGISTRO) FROM @TB_REL02) > 0)BEGIN
					SET @BODY_CORPO_HTML += ' <table> ';
					SET @BODY_CORPO_HTML += '     <caption><H3>Resumo do valor da movimentação</caption> ';
					SET @BODY_CORPO_HTML += '     <thead> ';
					SET @BODY_CORPO_HTML += '         <tr> ';
					SET @BODY_CORPO_HTML += '             <th>Origem</th> ';
					SET @BODY_CORPO_HTML += '             <th>Evento</th> ';
					SET @BODY_CORPO_HTML += '             <th>Total Registro</th> ';
					SET @BODY_CORPO_HTML += '             <th>Total Valor</th> ';
					SET @BODY_CORPO_HTML += '     </thead> ';
					SET @BODY_CORPO_HTML += '     <tbody> ';
					SET @BODY_CORPO_HTML += CAST ( 
													(SELECT 
														td = @NM_ARQUIVO, '', 
														td = 'Importação', '',  
														td = COUNT(CARGA_AUX_ID_REGISTRO), '',  
														td = CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( SUM(CARGA_AUX_VL_DIVIDA))))
													FROM 
														@TB_REL02

													FOR XML PATH('tr'), TYPE   
													) AS NVARCHAR(MAX) 
					);
					SET @BODY_CORPO_HTML += CAST ( 
													(SELECT 
														td = CARGA_AUX_NM_ORIGEM, '', 
														td = 'Registros Incluidos', '',  
														td = COUNT(CARGA_AUX_ID_REGISTRO), '',  
														td = CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( SUM(CARGA_AUX_VL_DIVIDA))))
													FROM 
														@TB_REL02
													WHERE 
														CARGA_AUX_TP_STATUS = 1
													GROUP BY
														CARGA_AUX_NM_ORIGEM

													FOR XML PATH('tr'), TYPE   
													) AS NVARCHAR(MAX) 
					);
					IF((SELECT COUNT(CARGA_AUX_DS_REGISTRO) FROM @TB_REL02 WHERE CARGA_AUX_TP_STATUS != 1) > 0)BEGIN
						SET @BODY_CORPO_HTML += CAST ( 
														(SELECT 
															td = CARGA_AUX_NM_ORIGEM, '', 
															td = CARGA_AUX_DS_REGISTRO, '',  
															td = COUNT(CARGA_AUX_ID_REGISTRO), '',  
															td = CONVERT(VARCHAR(3), 'R$ ') + CONVERT(VARCHAR(17), (SELECT dbo.FMTMOEDA( SUM(CARGA_AUX_VL_DIVIDA))))
														FROM 
															@TB_REL02
														WHERE 
															CARGA_AUX_TP_STATUS != 1
														GROUP BY
															CARGA_AUX_NM_ORIGEM, CARGA_AUX_DS_REGISTRO

														FOR XML PATH('tr'), TYPE   
														) AS NVARCHAR(MAX) 
						);
					END
					SET @BODY_CORPO_HTML += '     </tbody> ';
					SET @BODY_CORPO_HTML += ' </table> ';
					SET @BODY_CORPO_HTML += ' <br/><br/> ';
				END;	
			END;
		/**************************************************************************************************************************************************************************************/
			IF((SELECT COUNT(CARGA_AUX_ID) FROM @TB_CARGA_AUX	) > 0) BEGIN	
				SET @BODY_CORPO_HTML += ' <table> ';
				SET @BODY_CORPO_HTML += '     <caption><H3>Carga Movimento</caption> ';
				SET @BODY_CORPO_HTML += '     <thead> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <th>Carga</th> ';
				SET @BODY_CORPO_HTML += '             <th>Origem</th> ';
				SET @BODY_CORPO_HTML += '             <th>Data</th> ';
				SET @BODY_CORPO_HTML += '             <th>Tipo de Registro</th> ';
				SET @BODY_CORPO_HTML += '             <th>Tipo Evento</th> ';
				SET @BODY_CORPO_HTML += '             <th>Incluido com Sucesso</th> ';
				SET @BODY_CORPO_HTML += '             <th>Erro</th> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </thead> ';
				SET @BODY_CORPO_HTML += '     <tbody> ';
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT 
													td = DB_CARG.CARGA_AUX_ID, '',  
													td = DB_CARG.CARGA_AUX_ORIGEM, '', 
													td = CONVERT(VARCHAR(8), DB_CARG.CARGA_AUX_DT, 108) + ' ' + CONVERT(VARCHAR(10), DB_CARG.CARGA_AUX_DT, 103), '',  
													td = DB_CARG.CARGA_AUX_TP_REG, '',  
													td = DB_CARG.CARGA_AUX_TP_EVENTO, '',  
													td = DB_CARG.CARGA_AUX_OK, '',  
													td = DB_CARG.CARGA_AUX_REJEITADO
												FROM 
													@TB_CARGA_AUX DB_CARG

												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);
				SET @BODY_CORPO_HTML += '     </tbody> ';
				SET @BODY_CORPO_HTML += ' </table> ';
				SET @BODY_CORPO_HTML += ' <br/><br/> ';
			END;
		/**************************************************************************************************************************************************************************************/
			IF((SELECT COUNT(CARGA_AUX_ID) FROM @TB_REL01 ) > 0) BEGIN	
				SET @BODY_CORPO_HTML += ' <table> ';
				SET @BODY_CORPO_HTML += '     <caption><H3>Rejeição</caption> ';
				SET @BODY_CORPO_HTML += '     <thead> ';
				SET @BODY_CORPO_HTML += '         <tr> ';
				SET @BODY_CORPO_HTML += '             <th>Carga</th> ';
				SET @BODY_CORPO_HTML += '             <th>Origem</th> ';
				SET @BODY_CORPO_HTML += '             <th>Tipo de Registro</th> ';
				SET @BODY_CORPO_HTML += '             <th>Tipo Evento</th> ';
				SET @BODY_CORPO_HTML += '             <th>Descrição da Rejeição</th> ';
				SET @BODY_CORPO_HTML += '             <th>Total</th> ';
				SET @BODY_CORPO_HTML += '         </tr> ';
				SET @BODY_CORPO_HTML += '     </thead> ';
				SET @BODY_CORPO_HTML += '     <tbody> ';
				SET @BODY_CORPO_HTML += CAST ( 
												(SELECT 
													td = DB_CARG.CARGA_AUX_ID, '',  
													td = DB_CARG.CARGA_AUX_ORIGEM, '',
													td = DB_CARG.CARGA_AUX_TP_REG, '',  
													td = DB_CARG.CARGA_AUX_TP_EVENTO, '',  
													td = DB_CARG.CARGA_AUX_DS_REJEICAO, '',  
													td = DB_CARG.CARGA_AUX_TOTAL
												FROM 
													@TB_REL01 DB_CARG

												FOR XML PATH('tr'), TYPE   
												) AS NVARCHAR(MAX) 
				);
				SET @BODY_CORPO_HTML += '     </tbody> ';
				SET @BODY_CORPO_HTML += ' </table> ';
				SET @BODY_CORPO_HTML += ' <br/><br/> ';
			END;

			SET @BODY_ENVIO_HTML =  @BODY_CABECALHO_HTML + @BODY_CORPO_HTML + @BODY_RODAPE_HTML;
			
			IF(LEN(LTRIM(RTRIM(@BODY_ENVIO_HTML))) > 0) BEGIN
				INSERT INTO  TB_EMAIL_ENVIO(
					EMAIL_ENVIO_PROFILE_NAME
					,EMAIL_ENVIO_RECIPIENTES
					,EMAIL_ENVIO_CP_RECIPIENTES
					--,EMAIL_ENVIO_BLIND_CP_RECIPIENTES
					,EMAIL_ENVIO_SUBJECT
					,EMAIL_ENVIO_BODY
					,EMAIL_ENVIO_BODY_FORMAT
					,EMAIL_ENVIO_IMPORTANCE
				)
				SELECT
					'EmailHomolog'
					,'suporte@Homolog.com.br;'
					,'wanderlei.silva@Homolog.com.br;anderson.andrade@Homolog.com.br;paulo.sousa@Homolog.com.br;'						
					--,'anderson.andrade@Homolog.com.br;'
					,@SUBJECT
					,@BODY_ENVIO_HTML
					,'HTML'
					,'High'

			END;
			UPDATE TB_PROCESSO_EXECUCAO SET TP_ENVIO_EMAIL = 1 WHERE ID_EXECUCAO = @ID_EXECUCAO;
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
	
		SELECT @ERROR_NUMBER_AUX, @ERROR_SEVERITY_AUX ,@ERROR_STATE_AUX ,@ERROR_PROCEDURE_AUX ,@ERROR_LINE_AUX ,@ERROR_MESSAGE_AUX 
	
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