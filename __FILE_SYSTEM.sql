USE [Homolog]
GO

IF OBJECT_ID('dbo.__FILE_SYSTEM', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[__FILE_SYSTEM]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[__FILE_SYSTEM] (
	@STRING Varchar(max),
    @PATH VARCHAR(300),
    @FILE_NAME VARCHAR(200)
) AS 
	/********************************************************************************************
	*	AUTOR.....: ANDERSON LOPEZ
	*	DATA......: 21/09/2022	
	*	DESCRIÇÃO.: 
	*********************************************************************************************/
	DECLARE @EXEC_BCP										VARCHAR(4000) = '';
	DECLARE @OBJ_FILE_SYSTEM								INT;
    DECLARE @OBJ_TEXT_STREAM								INT;
    DECLARE @OBJ_ERROR										INT;
    DECLARE @ERROR_MESSAGE									VARCHAR(1000);
    DECLARE @COMMAND										VARCHAR(1000);
    DECLARE @FLAG											INT;
    DECLARE @FILE_PATH										VARCHAR(200)
	/********************************************************************************************/
SET NOCOUNT ON
BEGIN 	
	BEGIN TRY
		--Reconfigura opções do SQL Server
		EXEC sp_configure 'show advanced options', 1
		RECONFIGURE
		EXEC sp_configure 'Ole Automation Procedures', 1
		RECONFIGURE
 
		--Abrindo o Objeto
		SELECT @ERROR_MESSAGE='Abrindo File System Object'
		EXECUTE @FLAG = sp_OACreate  'Scripting.FileSystemObject' , @OBJ_FILE_SYSTEM OUT
 
		--Tratamento para string nula
		SET @STRING = ISNULL(@STRING, '')
 
		--Define o diretório e a pasta
		Select @FILE_PATH = @PATH+'\'+@FILE_NAME
 
		--Criando o arquivo
		if @FLAG = 0 Select @OBJ_ERROR = @OBJ_FILE_SYSTEM, @ERROR_MESSAGE = 'Criando arquivo "'+@FILE_PATH+'"'
		if @FLAG=0 execute @FLAG = sp_OAMethod @OBJ_FILE_SYSTEM, 'CreateTextFile', @OBJ_TEXT_STREAM OUT, @FILE_PATH, 2, True
 
		--Escrevendo texto no arquivo
		if @FLAG=0 Select @OBJ_ERROR = @OBJ_TEXT_STREAM, @ERROR_MESSAGE = 'Escrevendo no arquivo "'+@FILE_PATH+'"'
		if @FLAG=0 execute @FLAG = sp_OAMethod  @OBJ_TEXT_STREAM, 'Write', Null, @STRING
 
		--Fechando o aruqivo
		if @FLAG=0 Select @OBJ_ERROR = @OBJ_TEXT_STREAM, @ERROR_MESSAGE = 'Fechando e finalizando o arquivo "'+@FILE_PATH+'"'
		if @FLAG=0 execute @FLAG = sp_OAMethod  @OBJ_TEXT_STREAM, 'Close'
 
		--Se o ponteiro for diferente de 0 (houve erros
		if @FLAG<>0
			begin
			Declare 
				@Source varchar(255),
				@Description Varchar(255),
				@Helpfile Varchar(255),
				@HelpID int
 
			EXECUTE sp_OAGetErrorInfo  @OBJ_ERROR, 
				@Source output,@Description output,@Helpfile output,@HelpID output
			Select @ERROR_MESSAGE='Erro '
					+coalesce(@ERROR_MESSAGE,'...')
					+', '+coalesce(@Description,'')
			raiserror (@ERROR_MESSAGE,16,1)
		end
 
	END TRY
	BEGIN CATCH
		INSERT INTO __TBRELTEMP(
			TBRELTEMP_NM_PROC
			,TBRELTEMP_VCHAR01
			,TBRELTEMP_VCHAR02
			,TBRELTEMP_VCHAR03
			,TBRELTEMP_VCHAR04
		)VALUES(
			'__EXEC_BCP'
			,'ERRO'
			,CONVERT(VARCHAR(MAX), ERROR_NUMBER())
			,CONVERT(VARCHAR(MAX), ERROR_MESSAGE())
			,@EXEC_BCP
		)

	END CATCH
END;
