USE [Homolog]
GO

IF OBJECT_ID('dbo._PROC_ENVIO_EMAIL', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[_PROC_ENVIO_EMAIL]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[_PROC_ENVIO_EMAIL](
	@TIPO_ASSINATURA							BIGINT = 0
) 
AS
	/***************************************************************************************************************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 16/08/2022	
	*	DESCRIÇÃO.: Procedure para verificar o decurso das dividas que estao para expirar
	***************************************************************************************************************************************************************************************/
	DECLARE @EMAIL_ENVIO_NS											BIGINT = 0;
	DECLARE @EMAIL_ENVIO_PROFILE_NAME 								VARCHAR(250) = '';
	DECLARE @EMAIL_ENVIO_RECIPIENTES								VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_CP_RECIPIENTES								VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_BLIND_CP_RECIPIENTES						VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_FROM_ADDRESS								VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_REPLY_TO									VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_SUBJECT									VARCHAR(1000) = '';
	DECLARE @EMAIL_ENVIO_BODY									    NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO_BODY_FORMAT								VARCHAR(100) = '';
	DECLARE @EMAIL_ENVIO_IMPORTANCE									VARCHAR(100) = '';
	DECLARE @EMAIL_ENVIO_SENSITIVITY								VARCHAR(100) = '';
	DECLARE @EMAIL_ENVIO_FILE_ATT									VARCHAR(2000) = '';
	DECLARE @EMAIL_ENVIO_QUERY										NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO_EXEC_QUERY_DB								NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO_ATT_QUERY_RESULT							NVARCHAR(MAX) = '';
	DECLARE @EMAIL_ENVIO											INT = 0;
	DECLARE @EMAIL_ENVIO_MAILITEM_ID								BIGINT = 0;
	/**************************************************************************************************************************************************************************************/
	DECLARE @HTML													VARCHAR(MAX);  
	DECLARE @CSS													VARCHAR(MAX);  
	DECLARE @BODY_ENVIO_HTML										NVARCHAR(MAX) = '' ;
	DECLARE @ASSINATURA												VARCHAR(MAX) = '' ;
	/**************************************************************************************************************************************************************************************/
	/**************************************************************************************************************************************************************************************/
BEGIN 	
	BEGIN TRY 
	/**************************************************************************************************************************************************************************************/
		SET @CSS  = ' <style type="text/css">';
		SET @CSS += '     table { padding:0; border-spacing: 0; border-collapse: collapse; width: 1400px }';
		SET @CSS += '     caption { padding: 10px; font-weight: bold; color: #fff; }';
		SET @CSS += '     thead { background: #848484; border: 1px solid #ddd; }';
		SET @CSS += '     tbody { font-weight: normal; important! }';
		SET @CSS += '     th { padding: 10px; font-weight: bold; border: 1px solid #000; color: #fff; }';
		SET @CSS += '     tr { padding: 0;  }';
		SET @CSS += '     td { padding: 5px; border: 1px solid #cacaca; margin:0; text-align: center; font-size: 14px; font-weight: normal; important!}';
		SET @CSS += '     p {font-size:13px;font-family:Arial;color: #1f497d;}';
		SET @CSS += ' </style>';		
	/**************************************************************************************************************************************************************************************/
		SET @HTML  = ' <html> ';
		SET @HTML += ' <head> ';
		SET @HTML += @CSS;
		SET @HTML += ' </head> ';
		--SET @HTML += ' <br/> ';
	/**************************************************************************************************************************************************************************************/
		IF(@TIPO_ASSINATURA = 0) BEGIN
			SET @ASSINATURA = N'<img src="http://Homolog.com.br/assinaturas_Homolog/Depto_TI_Atualizado.png" width="220px" height="100px" border="0"/>'
			SET @ASSINATURA += N'<p>AVISO LEGAL: Esta Mensagem foi enviada de um endereço no qual não é monitorado. Não responda a esta mensagem.</p>';
			SET @ASSINATURA += N'<p>LEGAL NOTICE: This Message was sent from an address at which it is not monitored. Do not reply to this message.</p>';
		END;
	/**************************************************************************************************************************************************************************************/


		WHILE(EXISTS(SELECT TOP 1 EMAIL_ENVIO_NS FROM TB_EMAIL_ENVIO WHERE EMAIL_ENVIO = 0))BEGIN
			SELECT TOP 1 @EMAIL_ENVIO_NS = EMAIL_ENVIO_NS FROM TB_EMAIL_ENVIO WHERE EMAIL_ENVIO = 0;

			SELECT 
				@EMAIL_ENVIO_PROFILE_NAME = EMAIL_ENVIO_PROFILE_NAME
				,@EMAIL_ENVIO_RECIPIENTES = EMAIL_ENVIO_RECIPIENTES
				,@EMAIL_ENVIO_CP_RECIPIENTES = EMAIL_ENVIO_CP_RECIPIENTES
				,@EMAIL_ENVIO_BLIND_CP_RECIPIENTES = EMAIL_ENVIO_BLIND_CP_RECIPIENTES
				,@EMAIL_ENVIO_FROM_ADDRESS = EMAIL_ENVIO_FROM_ADDRESS
				,@EMAIL_ENVIO_REPLY_TO = EMAIL_ENVIO_REPLY_TO
				,@EMAIL_ENVIO_SUBJECT = EMAIL_ENVIO_SUBJECT
				,@EMAIL_ENVIO_BODY = EMAIL_ENVIO_BODY
				,@EMAIL_ENVIO_BODY_FORMAT = EMAIL_ENVIO_BODY_FORMAT
				,@EMAIL_ENVIO_IMPORTANCE = EMAIL_ENVIO_IMPORTANCE
				,@EMAIL_ENVIO_SENSITIVITY = EMAIL_ENVIO_SENSITIVITY
				,@EMAIL_ENVIO_FILE_ATT = EMAIL_ENVIO_FILE_ATT
				,@EMAIL_ENVIO_QUERY = EMAIL_ENVIO_QUERY
				,@EMAIL_ENVIO_EXEC_QUERY_DB = EMAIL_ENVIO_EXEC_QUERY_DB
				,@EMAIL_ENVIO_ATT_QUERY_RESULT = EMAIL_ENVIO_ATT_QUERY_RESULT
			FROM TB_EMAIL_ENVIO WHERE EMAIL_ENVIO_NS = @EMAIL_ENVIO_NS;
	
			IF(	LEN(LTRIM(RTRIM(@ASSINATURA))) > 0) BEGIN
				SET @BODY_ENVIO_HTML = @HTML + @EMAIL_ENVIO_BODY + @ASSINATURA;
			END ELSE BEGIN
				SET @BODY_ENVIO_HTML = @HTML + @EMAIL_ENVIO_BODY;
			END;

			EXEC msdb.dbo.sp_send_dbmail
				  @profile_name = @EMAIL_ENVIO_PROFILE_NAME
				 ,@recipients = @EMAIL_ENVIO_RECIPIENTES
				 ,@copy_recipients = @EMAIL_ENVIO_CP_RECIPIENTES
				 ,@blind_copy_recipients = @EMAIL_ENVIO_BLIND_CP_RECIPIENTES
				 ,@from_address = @EMAIL_ENVIO_FROM_ADDRESS
				 ,@reply_to = @EMAIL_ENVIO_REPLY_TO
				 ,@subject = @EMAIL_ENVIO_SUBJECT
				 ,@body = @BODY_ENVIO_HTML
				 ,@body_format = @EMAIL_ENVIO_BODY_FORMAT
				 ,@importance = @EMAIL_ENVIO_IMPORTANCE
				 ,@sensitivity = @EMAIL_ENVIO_SENSITIVITY
				 ,@file_attachments = @EMAIL_ENVIO_FILE_ATT
				 ,@query = @EMAIL_ENVIO_QUERY
				 ,@execute_query_database = @EMAIL_ENVIO_EXEC_QUERY_DB
				 ,@attach_query_result_as_file = @EMAIL_ENVIO_ATT_QUERY_RESULT
				 ,@query_attachment_filename = ''   
				 ,@query_result_header = ''   
				 ,@query_result_width = ''   
				 ,@query_result_separator = ''   
				 ,@exclude_query_output = ''   
				 ,@append_query_error = ''   
				 ,@query_no_truncate = ''    
				 ,@query_result_no_padding = ''    
				 ,@mailitem_id = @EMAIL_ENVIO_MAILITEM_ID OUTPUT;

			UPDATE TB_EMAIL_ENVIO SET EMAIL_ENVIO = 1, EMAIL_ENVIO_MAILITEM_ID = @EMAIL_ENVIO_MAILITEM_ID WHERE EMAIL_ENVIO_NS = @EMAIL_ENVIO_NS;
		END;
	END TRY 
	BEGIN CATCH  
	
		SELECT CONVERT(VARCHAR(500), ERROR_NUMBER()) AS 'ErrorNumber';
		SELECT CONVERT(VARCHAR(500), ERROR_SEVERITY()) AS 'ErrorSeverity';
		SELECT CONVERT(VARCHAR(500), ERROR_STATE()) AS 'ErrorState';
		SELECT CONVERT(VARCHAR(500), ERROR_PROCEDURE()) AS 'ErrorProcedure';
		SELECT CONVERT(VARCHAR(500), ERROR_LINE()) AS 'ErrorLine';
		SELECT CONVERT(VARCHAR(500), ERROR_MESSAGE()) AS 'ErrorMessage';

	END CATCH; 
END;