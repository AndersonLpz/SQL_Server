USE [Homolog]
GO

IF OBJECT_ID('dbo.__EXEC_OLE', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__EXEC_OLE]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE __EXEC_OLE(
	 @ProgID				NVARCHAR(500) = 'WinHTTP.WinHTTPRequest.5.1'
	,@URL					NVARCHAR(500) = ''
	,@METODO_TP				NVARCHAR(10) = 'POST'
	,@CONTENT_TYPE			NVARCHAR(500) = 'application/json'
	,@POST_DATA				NVARCHAR(2000) = ''
)
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR....................: ANDERSON LOPEZ
	*	DATA.....................: 19/12/2022
	*	DATA ATUALIZACAO.........: 19/12/2022
	*	DESCRIÇÃO................: Procedure executar o OLE
	***************************************************************************************************************************************************************************************/	
	DECLARE @TOKEN												INT;	
	DECLARE @STATUS												NVARCHAR(32);
	DECLARE @STATUS_TEXT										NVARCHAR(32);
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

		IF (Object_ID('tempDB..##TB_OLE','U') is not null)BEGIN
			DROP TABLE ##TB_OLE;
		END;
		CREATE TABLE ##TB_OLE (
			  XML_RETORNO	NVARCHAR(MAX)			 
		);

	
		EXEC sys.sp_OACreate @ProgID, @TOKEN OUT;
		-- IF @ret <> 0 RAISERROR('Unable to open HTTP connection.', 10, 1);
		
		-- Send the request.
		EXEC sys.sp_OAMethod @TOKEN, 'open', NULL, @METODO_TP, @URL, 'false';
		EXEC sys.sp_OAMethod @TOKEN, 'setRequestHeader', NULL, 'Content-type', @CONTENT_TYPE;

		IF(LEN(LTRIM(RTRIM(@POST_DATA))) > 0) BEGIN
			EXEC sys.sp_OAMethod @TOKEN, 'send', NULL, @POST_DATA;
		END ELSE BEGIN
			EXEC sys.sp_OAMethod @TOKEN, 'send';
		END
		
		-- Handle the response.
		EXEC sys.sp_OAGetProperty @TOKEN, 'status', @STATUS OUT;
		EXEC sys.sp_OAGetProperty @TOKEN, 'statusText', @STATUS_TEXT OUT;

		INSERT INTO 
			##TB_OLE
		EXEC  sys.sp_OAGetProperty @TOKEN, 'responseText';		

		-- Close the connection.
		EXEC sys.sp_OADestroy @TOKEN;
		-- EXEC @ret =  sys.sp_OADestroy @token;
		--IF @ret <> 0 RAISERROR('Unable to close HTTP connection.', 10, 1);	
		
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