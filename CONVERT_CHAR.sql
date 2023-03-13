USE [Homolog]
GO
/****** Object:  UserDefinedFunction [dbo].[ConvertChar1]    Script Date: 19/06/2019 17:53:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CONVERT_CHAR] (@texto VARCHAR(MAX) = '', @tamanho INT = 0, @tipo CHAR = 'N')
RETURNS VARCHAR(MAX)
AS
BEGIN   
	/*
	* @tipo = 0 => REPLICATE
	* @tipo = 1 => SPACE
	*/
	DECLARE @RETORNO VARCHAR(MAX);

	SET @texto = LTRIM(RTRIM(@texto));

	IF(@tamanho = 5) BEGIN	
		IF @tipo = 'R'
			SET @RETORNO = CONVERT(CHAR(5), REPLICATE('0', 5 - LEN(@texto)) + @texto);
		IF @tipo = 'S'
			SET @RETORNO = CONVERT(CHAR(5), SPACE(5 - LEN(@texto)) + @texto)
	END;

	IF(@tamanho = 10) BEGIN
		IF @tipo = 'R'
			SET @RETORNO = CONVERT(CHAR(10), REPLICATE('0', 10 - LEN(@texto)) + @texto);
		IF @tipo = 'S'
			SET @RETORNO = CONVERT(CHAR(10), SPACE(10 - LEN(@texto)) + @texto)
	END;

	IF(@tamanho = 15) BEGIN
		IF @tipo = 'R'
			SET @RETORNO = CONVERT(CHAR(15), REPLICATE('0', 15 - LEN(@texto)) + @texto);
		IF @tipo = 'S'
			SET @RETORNO = CONVERT(CHAR(15), SPACE(15 - LEN(@texto)) + @texto)
	END;

	IF(@tamanho = 20) BEGIN
		IF @tipo = 'R'
			SET @RETORNO = CONVERT(CHAR(20), REPLICATE('0', 20 - LEN(@texto)) + @texto);
		IF @tipo = 'S'
			SET @RETORNO = CONVERT(CHAR(20), SPACE(20 - LEN(@texto)) + @texto)
	END;

	IF(@tamanho = 50) BEGIN
		IF @tipo = 'R'
			SET @RETORNO = CONVERT(CHAR(50), REPLICATE('0', 50 - LEN(@texto)) + @texto);
		IF @tipo = 'S'
			SET @RETORNO = CONVERT(CHAR(50), SPACE(50 - LEN(@texto)) + @texto)
	END;

    RETURN (@RETORNO)
END
