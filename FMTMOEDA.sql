SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.FMTMOEDA
(
    -- Parâmetro que vai receber o valor
    @VLR NUMERIC(18,2)
)
RETURNS VARCHAR(50)
AS
BEGIN
    -- Declaração das variáveis de apoio
    DECLARE @INTEIRO INT
    DECLARE @FRACAO INT
    DECLARE @STRINTEIRO VARCHAR(50)
    DECLARE @STRFRACAO VARCHAR(50)
    DECLARE @STRRESULT VARCHAR(50)
    -- Obtém a parte inteira e a parte decimal do valor passado
    SET @INTEIRO = ROUND(@VLR,2)
    SET @FRACAO = ((ROUND(@VLR,2) - (@INTEIRO / 1.000)) * 100)
    -- Transforma os valores obtidos em caractere
    SET @STRINTEIRO = LTRIM(RTRIM(CAST(@INTEIRO AS VARCHAR(50))))
    SET @STRFRACAO = RIGHT('0'+LTRIM(RTRIM(CAST(@FRACAO AS VARCHAR(50)))),2)
    -- Separa a string de 3 em 3 para montar o texto formatado
    SET @STRRESULT = ''
    WHILE LEN(@STRINTEIRO) > 0
    BEGIN
        IF LEN(@STRINTEIRO) > 3
        BEGIN
            SET @STRRESULT = RIGHT(@STRINTEIRO,3) + '.' + @STRRESULT
            SET @STRINTEIRO = LEFT(@STRINTEIRO,LEN(@STRINTEIRO)-3)
        END
        ELSE
        BEGIN
            SET @STRRESULT = @STRINTEIRO + '.' + @STRRESULT
            SET @STRINTEIRO = ''
        END;
    END;
    -- Retorna a texto final, concatenando a parte inteira à parte decimal
    RETURN REPLACE(@STRRESULT + ',' + @STRFRACAO, '.,', ',')
END
GO