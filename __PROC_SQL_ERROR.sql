USE [Homolog]
GO

IF OBJECT_ID('dbo.__PROC_SQL_ERROR_EMAIL', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__PROC_SQL_ERROR_EMAIL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE __PROC_SQL_ERROR_EMAIL(
	@ERROR_NUMBER								VARCHAR(500)
	,@ERROR_SEVERITY							VARCHAR(500)
	,@ERROR_STATE								VARCHAR(500)
	,@ERROR_PROCEDURE							VARCHAR(500)
	,@ERROR_LINE								VARCHAR(500)
	,@ERROR_MESSAGE								VARCHAR(500)
)
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 12/12/2022	
	*	DATA ATUALIZACAO.........: 12/12/2022	
	*	DESCRIÇÃO................: Procedure para envio de email quando ocorre algum erro nas procedures executadas.
	***************************************************************************************************************************************************************************************/	

	/**************************************************************************************************************************************************************************************/	
	DECLARE @SQL_EXEC												VARCHAR(MAX);
	/**************************************************************************************************************************************************************************************
	*	- VARIAVEL ENVIO EMAIL
	***************************************************************************************************************************************************************************************/
	DECLARE @SUBJECT											VARCHAR(200) = 'Erro na execução.';
	DECLARE @BODY_CABECALHO_HTML								NVARCHAR(MAX) = '' ;
	DECLARE @BODY_CORPO_HTML									NVARCHAR(MAX) = '' ;
	DECLARE @BODY_RODAPE_HTML									NVARCHAR(MAX) = '' ;
	DECLARE @BODY_ENVIO_HTML									NVARCHAR(MAX) = '' ;
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	

	SET @BODY_CABECALHO_HTML = N'<H2 style="text-align:center;width: 1400px;"> Erro </H2>';
	SET @BODY_CORPO_HTML = ''
	SET @BODY_CORPO_HTML += ' <table> ';
	SET @BODY_CORPO_HTML += '     <caption><H3>Erro ao processar a Procedure.</H3></caption> ';
	SET @BODY_CORPO_HTML += '     <thead> ';
	SET @BODY_CORPO_HTML += '         <tr> ';
	SET @BODY_CORPO_HTML += '             <th>Error Number</th> ';
	SET @BODY_CORPO_HTML += '             <th>Error Severity</th> ';
	SET @BODY_CORPO_HTML += '             <th>Error State</th> ';
	SET @BODY_CORPO_HTML += '             <th>Error Procedure</th> ';
	SET @BODY_CORPO_HTML += '             <th>Error Line</th> ';
	SET @BODY_CORPO_HTML += '             <th>Error Message</th> ';
	SET @BODY_CORPO_HTML += '         </tr> ';
	SET @BODY_CORPO_HTML += '     </thead> ';
	SET @BODY_CORPO_HTML += '     <tbody> ';
	SET @BODY_CORPO_HTML += CAST ( 
									(SELECT DISTINCT  
										td = ISNULL(@ERROR_NUMBER, ''), '',
										td = ISNULL(@ERROR_SEVERITY, ''), '', 
										td = ISNULL(@ERROR_STATE, ''), '',  
										td = ISNULL(@ERROR_PROCEDURE, ''), '',  
										td = ISNULL(@ERROR_LINE, ''), '',
										td = ISNULL(@ERROR_MESSAGE, ''), ''
							
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
			,EMAIL_ENVIO_CP_RECIPIENTES
			,EMAIL_ENVIO_SUBJECT
			,EMAIL_ENVIO_BODY
			,EMAIL_ENVIO_BODY_FORMAT
			,EMAIL_ENVIO_IMPORTANCE
		)
		SELECT
			'EmailHomolog'
			,'wanderlei.silva@Homolog.com.br;anderson.andrade@Homolog.com.br;'
			--,'anderson.andrade@Homolog.com.br;'
			,@SUBJECT
			,@BODY_ENVIO_HTML
			,'HTML'
			,'High'
	END;	
	EXEC [dbo].[_PROC_ENVIO_EMAIL];
END;