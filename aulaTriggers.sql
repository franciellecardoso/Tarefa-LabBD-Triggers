--tarefa aula TRIGGERS
CREATE DATABASE ex_triggers_07
GO
USE ex_triggers_07
GO
CREATE TABLE cliente (
codigo		    INT			        NOT NULL,
nome		    VARCHAR(70)	        NOT NULL
PRIMARY KEY(codigo)
)
GO
CREATE TABLE venda (
codigo_venda	INT				    NOT NULL,
codigo_cliente	INT				    NOT NULL,
valor_total		DECIMAL(7,2)	    NOT NULL
PRIMARY KEY (codigo_venda)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO
CREATE TABLE pontos (
codigo_cliente	INT					NOT NULL,
total_pontos	DECIMAL(4,1)		NOT NULL
PRIMARY KEY (codigo_cliente)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO
INSERT INTO cliente (codigo, nome)
VALUES (1, 'Fulano'),
       (2, 'Beltrano'),
	   (3, 'Cicrano'),
	   (4, 'Deltrano')
GO
INSERT INTO venda(codigo_venda, codigo_cliente, valor_total)
VALUES (1, 1, 100.00), 
	   (2, 2, 200.00),
	   (3, 3, 300.00),
	   (4, 4, 400.00)
GO
-- Para n�o prejudicar a tabela venda, nenhum produto pode ser deletado, mesmo que n�o venha mais a ser vendido
CREATE TRIGGER t_delvenda ON venda
AFTER DELETE
AS
BEGIN
	ROLLBACK TRANSACTION
	RAISERROR('N�o � poss�vel excluir produtos', 16, 1)
END
GO
DELETE venda
WHERE codigo_venda = 1
GO
-- Para n�o prejudicar os relat�rios e a contabilidade, a tabela venda n�o pode ser alterada. 
-- Ao inv�s de alterar a tabela venda deve-se exibir uma tabela com o nome do �ltimo cliente que comprou e o valor da �ltima compra
CREATE TRIGGER t_ultima_compra ON venda
FOR UPDATE
AS
BEGIN
	ROLLBACK TRANSACTION
��� CREATE TABLE #table (ucliente VARCHAR(50), compra DECIMAL(7,2))
��� SELECT TOP 1 ucliente = nome, compra = valor_total FROM venda, cliente
��� GROUP BY venda.codigo_cliente, cliente.nome, venda.valor_total
��� ORDER BY codigo_cliente desc
��� SELECT * FROM #table
��� RAISERROR('N�o � poss�vel atualizar tabela', 16, 1)
END
GO
-- Ap�s a inser��o de cada linha na tabela venda, 10% do total dever� ser transformado em pontos.
-- Se o cliente ainda n�o estiver na tabela de pontos, deve ser inserido automaticamente ap�s sua primeira compra
-- Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que ganhou
CREATE TRIGGER insere_pontos ON venda
FOR INSERT
AS
BEGIN
	DECLARE @total DECIMAL(4,1),
            @codcliente INT
    SET @total = 0
    SET @codcliente = (SELECT P.codigo_cliente FROM pontos P WHERE P.codigo_cliente = (SELECT codigo_cliente FROM inserted))
    SET @total = ((SELECT SUM(V.valor_total) FROM venda V WHERE V.codigo_cliente = 
    (SELECT codigo_cliente FROM inserted))*0.1)

    IF(@codcliente IS NULL)
    BEGIN
        INSERT INTO pontos VALUES ((SELECT codigo_cliente FROM inserted),@total)
    END
    ELSE
    BEGIN
        UPDATE pontos
        SET pontos.total_pontos = @total
        WHERE pontos.codigo_cliente = @codcliente
    END
    IF((SELECT P.total_pontos FROM pontos P WHERE P.codigo_cliente = (SELECT codigo_cliente FROM inserted))>1)
    BEGIN
        PRINT('Ganhou um ponto')
    END

	UPDATE venda
    SET venda.codigo_cliente = (SELECT codigo_cliente FROM inserted), 
    venda.valor_total = (SELECT valor_total FROM inserted)
    WHERE venda.codigo_venda = 1
END

SELECT * FROM cliente
SELECT * FROM venda
SELECT * FROM pontos