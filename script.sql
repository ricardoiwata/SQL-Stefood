USE [master]
GO
/****** Object:  Database [stefood]    Script Date: 03/10/2022 10:34:07 ******/
CREATE DATABASE [stefood]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'stefood', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\stefood.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'stefood_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\stefood_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [stefood] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [stefood].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [stefood] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [stefood] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [stefood] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [stefood] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [stefood] SET ARITHABORT OFF 
GO
ALTER DATABASE [stefood] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [stefood] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [stefood] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [stefood] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [stefood] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [stefood] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [stefood] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [stefood] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [stefood] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [stefood] SET  DISABLE_BROKER 
GO
ALTER DATABASE [stefood] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [stefood] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [stefood] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [stefood] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [stefood] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [stefood] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [stefood] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [stefood] SET RECOVERY FULL 
GO
ALTER DATABASE [stefood] SET  MULTI_USER 
GO
ALTER DATABASE [stefood] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [stefood] SET DB_CHAINING OFF 
GO
ALTER DATABASE [stefood] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [stefood] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [stefood] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [stefood] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'stefood', N'ON'
GO
ALTER DATABASE [stefood] SET QUERY_STORE = OFF
GO
USE [stefood]
GO
/****** Object:  User [ricardoiwata]    Script Date: 03/10/2022 10:34:08 ******/
CREATE USER [ricardoiwata] FOR LOGIN [ricardoiwata] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [ricardoiwata]
GO
/****** Object:  UserDefinedFunction [dbo].[valida_cpf_cnpj]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create function [dbo].[valida_cpf_cnpj] (@documento varchar(18))
returns bit as
begin
    -- Remove caracteres 
    declare @doc varchar(14) = ''
    ;with split as (
        select 1 as id, substring(@documento, 1, 1) as algarismo
        union all
        select id + 1, substring(@documento, id + 1, 1)
        from split
        where id < len(@documento)
    )
    select @doc += algarismo from split where algarismo like '[0-9]'
 
    -- variáveis
    declare
        @doc_len int = len(@doc),
        @doc_digito1 int = substring(@doc, len(@doc) - 1, 1),
        @doc_digito2 int = substring(@doc, len(@doc), 1),
        @loop_digitos_verificadores int = 1,
        @posicao_proximo_algarismo int,
        @somatoria_algarismos_x_coeficientes int,
        @coeficiente_multiplicador int,
        @algarismo int,
        @resto_divisao_inteira int,
        @digito_calculado1 int,
        @digito_calculado2 int
 
    -- loop: executa uma validação para cada um dos digitos (começa em 1 termina em 2)
    while @loop_digitos_verificadores <= 2 begin select @somatoria_algarismos_x_coeficientes = 0, @coeficiente_multiplicador = 2, @posicao_proximo_algarismo = @doc_len + @loop_digitos_verificadores - 3 -- loop: Uma repetição para cada algarismo da raiz do cnpj ou cpf while @posicao_proximo_algarismo >= 0
                begin
                    select
                        @algarismo = substring(@doc, @posicao_proximo_algarismo, 1),
                        @somatoria_algarismos_x_coeficientes += @algarismo * @coeficiente_multiplicador,
                        @coeficiente_multiplicador = @coeficiente_multiplicador + 1,
                        @posicao_proximo_algarismo -= 1
                    --print '@algarismo: ' + convert(varchar, @algarismo)
                    --print '@coeficiente_multiplicador: ' + convert(varchar, @coeficiente_multiplicador - 1)
                    --print 'produto: ' + convert(varchar, @algarismo * (@coeficiente_multiplicador - 1))
                    --print '@somatoria_algarismos_x_coeficientes (somatória atual): ' + convert(varchar, @somatoria_algarismos_x_coeficientes)
                     
                    -- Se for um cnpj reinicia a contagem de coeficientes (para cpf continua)
                    if @doc_len > 11 and @coeficiente_multiplicador > 9
                        set @coeficiente_multiplicador = 2
                end
            --print '@somatoria_algarismos_x_coeficientes (somatória final): ' + convert(varchar, @somatoria_algarismos_x_coeficientes)
 
            set @resto_divisao_inteira = 11 - (@somatoria_algarismos_x_coeficientes % 11)
            --print '@resto_divisao_inteira: ' + convert(varchar, @resto_divisao_inteira)
 
            if (@resto_divisao_inteira = 10)
                set @resto_divisao_inteira = 0
   
            if @loop_digitos_verificadores = 1
                set @digito_calculado1 = @resto_divisao_inteira
            else
                set @digito_calculado2 = @resto_divisao_inteira
  
            set @loop_digitos_verificadores += 1
        end
   
    return
    -- select
        case
            when @digito_calculado1 = @doc_digito1 and @digito_calculado2 = @doc_digito2 then 1
            else 0
        end
end
GO
/****** Object:  UserDefinedFunction [dbo].[validaEmail]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[validaEmail](@EMAIL varchar(100))

RETURNS VARCHAR(20) as
BEGIN     
  DECLARE @resultado as VARCHAR(20)
  IF (@EMAIL <> '' AND @EMAIL NOT LIKE '_%@__%.__%')
     SET @resultado = 'Inválido'  -- Invalid
  ELSE 
    SET @resultado = 'Válido'   -- Valid
  RETURN @resultado
END 
GO
/****** Object:  UserDefinedFunction [dbo].[validarCPF]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[validarCPF](@CPF VARCHAR(11))
RETURNS CHAR(1)
AS
BEGIN
  DECLARE @INDICE INT,
          @SOMA INT,
          @DIG1 INT,
          @DIG2 INT,
          @CPF_TEMP VARCHAR(11),
          @DIGITOS_IGUAIS CHAR(1),
          @RESULTADO CHAR(1)
          
  SET @RESULTADO = 'N'

  SET @CPF_TEMP = SUBSTRING(@CPF,1,1)

  SET @INDICE = 1
  SET @DIGITOS_IGUAIS = 'S'

  WHILE (@INDICE <= 11)
  BEGIN
    IF SUBSTRING(@CPF,@INDICE,1) <> @CPF_TEMP
      SET @DIGITOS_IGUAIS = 'N'
    SET @INDICE = @INDICE + 1
  END;

  IF @DIGITOS_IGUAIS = 'N'
  BEGIN
  
    SET @SOMA = 0
    SET @INDICE = 1
    WHILE (@INDICE <= 9)
    BEGIN
      SET @Soma = @Soma + CONVERT(INT,SUBSTRING(@CPF,@INDICE,1)) * (11 - @INDICE);
      SET @INDICE = @INDICE + 1
    END

    SET @DIG1 = 11 - (@SOMA % 11)

    IF @DIG1 > 9
      SET @DIG1 = 0;


    SET @SOMA = 0
    SET @INDICE = 1
    WHILE (@INDICE <= 10)
    BEGIN
      SET @Soma = @Soma + CONVERT(INT,SUBSTRING(@CPF,@INDICE,1)) * (12 - @INDICE);
      SET @INDICE = @INDICE + 1
    END

    SET @DIG2 = 11 - (@SOMA % 11)

    IF @DIG2 > 9
      SET @DIG2 = 0;

    IF (@DIG1 = SUBSTRING(@CPF,LEN(@CPF)-1,1)) AND (@DIG2 = SUBSTRING(@CPF,LEN(@CPF),1))
      SET @RESULTADO = 'Válido'
    ELSE
      SET @RESULTADO = 'Não Válido'
  END
  RETURN @RESULTADO
END
GO
/****** Object:  Table [dbo].[deliveryman]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[deliveryman](
	[deliveryman_id] [int] IDENTITY(1,1) NOT NULL,
	[bike_plate] [nchar](7) NULL,
	[deliveryman_name] [nchar](50) NULL,
	[deliveryman_cpf] [nchar](11) NULL,
	[license_number] [nchar](10) NULL,
 CONSTRAINT [PK_deliveryman] PRIMARY KEY CLUSTERED 
(
	[deliveryman_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[product]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[product](
	[product_id] [int] IDENTITY(1,1) NOT NULL,
	[name_product] [varchar](50) NULL,
	[price_product] [varchar](5) NULL,
	[description_product] [varchar](100) NULL,
	[restaurant_id] [int] NOT NULL,
 CONSTRAINT [PK_product] PRIMARY KEY CLUSTERED 
(
	[product_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[order_itens]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[order_itens](
	[orderitens_id] [int] IDENTITY(1,1) NOT NULL,
	[product_id] [int] NOT NULL,
	[orderitens_qnty] [float] NULL,
	[orderitens_totalvalue] [float] NULL,
	[orderitens_description] [nchar](50) NULL,
	[client_id] [int] NULL,
	[order_date] [datetime] NULL,
	[deliveryman_id] [int] NULL,
	[orderitens_status] [nchar](10) NULL,
	[deliveryman_status] [nchar](10) NULL,
 CONSTRAINT [PK_order_itens_1] PRIMARY KEY CLUSTERED 
(
	[orderitens_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[clientes]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[clientes](
	[client_id] [int] IDENTITY(1,1) NOT NULL,
	[client_name] [nchar](70) NULL,
	[client_adress] [nchar](255) NULL,
	[client_phone] [nchar](11) NULL,
	[client_cpf] [nchar](11) NULL,
 CONSTRAINT [PK_clientes] PRIMARY KEY CLUSTERED 
(
	[client_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[pedidosRestaurante]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[pedidosRestaurante]
AS SELECT
		orderitens_id as [ID do pedido],
		dbo.product.name_product as [Nome do produto],
		dbo.order_itens.orderitens_qnty as Quantidade,
		dbo.clientes.client_name as [Nome do Cliente],
		dbo.clientes.client_phone as [Telefone do Cliente],
		dbo.deliveryman.deliveryman_name as Motoboy,
		dbo.deliveryman.bike_plate as [Placa do Motoboy]


		FROM dbo.order_itens

		INNER JOIN dbo.clientes
		ON dbo.order_itens.client_id = dbo.clientes.client_id

		INNER JOIN dbo.product
		ON dbo.order_itens.product_id = dbo.product.product_id

		INNER JOIN dbo.deliveryman
		ON dbo.order_itens.deliveryman_id = dbo.deliveryman.deliveryman_id


	

		

	
GO
/****** Object:  View [dbo].[ClientesCadastrados]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ClientesCadastrados] AS
SELECT client_name AS Nome,
	client_phone AS Telefone,
	client_cpf AS CPF,
	client_adress AS Endereço 

	FROM clientes
 
GO
/****** Object:  Table [dbo].[restaurant]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[restaurant](
	[restaurant_id] [int] IDENTITY(1,1) NOT NULL,
	[restaurant_name] [nchar](50) NULL,
	[restaurant_adress] [varchar](255) NULL,
	[restaurant_cnpj] [nchar](14) NULL,
 CONSTRAINT [PK_restaurant] PRIMARY KEY CLUSTERED 
(
	[restaurant_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[restaurantesCadastrados]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[restaurantesCadastrados]
AS SELECT 
	restaurant_id AS Código,
	restaurant_name AS Nome,
	restaurant_adress AS Endereço,
	restaurant_cnpj AS CNPJ

	FROM restaurant
GO
/****** Object:  View [dbo].[cpfsvalidos]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[cpfsvalidos] AS 
select client_name as Nome, 
	client_cpf as CPF,
	dbo.validarCPF(client_cpf) as Validação
	from dbo.clientes

	
GO
/****** Object:  View [dbo].[cnpjvalidos]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[cnpjvalidos] AS 
select restaurant_name as [Nome do Restaurante], 
	restaurant_cnpj as CNPJ,
	dbo.valida_cpf_cnpj(restaurant_cnpj) as Validação 
	from dbo.restaurant

	
GO
/****** Object:  Table [dbo].[login_stefood]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[login_stefood](
	[login_id] [int] IDENTITY(1,1) NOT NULL,
	[login_email] [nchar](100) NULL,
	[login_password] [nchar](16) NULL,
	[client_id] [int] NULL,
 CONSTRAINT [PK_login_stefood] PRIMARY KEY CLUSTERED 
(
	[login_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[emailsValidos]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[emailsValidos] AS 
select login_email as Email, 
	dbo.validaEmail(login_email) as Validação
	from dbo.login_stefood

	
GO
/****** Object:  Table [dbo].[payment]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[payment](
	[payment_id] [int] IDENTITY(1,1) NOT NULL,
	[card_number] [nchar](16) NULL,
	[card_validity] [date] NULL,
	[validation_code] [nchar](3) NULL,
	[client_id] [int] NULL,
 CONSTRAINT [PK_payment] PRIMARY KEY CLUSTERED 
(
	[payment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [idx_cpf]    Script Date: 03/10/2022 10:34:08 ******/
CREATE NONCLUSTERED INDEX [idx_cpf] ON [dbo].[clientes]
(
	[client_cpf] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [idx_cnpj]    Script Date: 03/10/2022 10:34:08 ******/
CREATE NONCLUSTERED INDEX [idx_cnpj] ON [dbo].[restaurant]
(
	[restaurant_cnpj] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[login_stefood]  WITH CHECK ADD  CONSTRAINT [FK_login_stefood_clientes] FOREIGN KEY([client_id])
REFERENCES [dbo].[clientes] ([client_id])
GO
ALTER TABLE [dbo].[login_stefood] CHECK CONSTRAINT [FK_login_stefood_clientes]
GO
ALTER TABLE [dbo].[order_itens]  WITH CHECK ADD  CONSTRAINT [FK_order_itens_clientes] FOREIGN KEY([client_id])
REFERENCES [dbo].[clientes] ([client_id])
GO
ALTER TABLE [dbo].[order_itens] CHECK CONSTRAINT [FK_order_itens_clientes]
GO
ALTER TABLE [dbo].[order_itens]  WITH CHECK ADD  CONSTRAINT [FK_order_itens_deliveryman] FOREIGN KEY([deliveryman_id])
REFERENCES [dbo].[deliveryman] ([deliveryman_id])
GO
ALTER TABLE [dbo].[order_itens] CHECK CONSTRAINT [FK_order_itens_deliveryman]
GO
ALTER TABLE [dbo].[order_itens]  WITH CHECK ADD  CONSTRAINT [FK_order_itens_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[product] ([product_id])
GO
ALTER TABLE [dbo].[order_itens] CHECK CONSTRAINT [FK_order_itens_product]
GO
ALTER TABLE [dbo].[payment]  WITH CHECK ADD  CONSTRAINT [FK_payment_clientes] FOREIGN KEY([client_id])
REFERENCES [dbo].[clientes] ([client_id])
GO
ALTER TABLE [dbo].[payment] CHECK CONSTRAINT [FK_payment_clientes]
GO
ALTER TABLE [dbo].[product]  WITH CHECK ADD  CONSTRAINT [FK_product_restaurant] FOREIGN KEY([restaurant_id])
REFERENCES [dbo].[restaurant] ([restaurant_id])
GO
ALTER TABLE [dbo].[product] CHECK CONSTRAINT [FK_product_restaurant]
GO
/****** Object:  StoredProcedure [dbo].[inserirclient]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inserirclient] ( 
									@name VARCHAR(70),
									@adress VARCHAR(255),
									@phone VARCHAR(11),
									@cpf VARCHAR(11),
									@email VARCHAR(100),
									@password VARCHAR(16))
	AS BEGIN
		BEGIN TRANSACTION 
			INSERT INTO login_stefood(login_email,login_password)
			VALUES (@email, @password)

			IF(dbo.validaEmail(@email)) = 'Inválido'
				ROLLBACK
			ELSE

			INSERT INTO clientes(client_name,client_phone,client_cpf,client_adress)
			VALUES (@name, @phone, @cpf, @adress)

			IF (dbo.validarCPF(@cpf)) = 'Inválido'
				ROLLBACK
				
				
				ELSE 
			COMMIT


			END
GO
/****** Object:  StoredProcedure [dbo].[SP_pedido]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_pedido] (
									@cpf VARCHAR(11),
									@email VARCHAR(100),
									@productid INTEGER,
									@quantity FLOAT,
									@totalvalue FLOAT,
									@description VARCHAR(50),
									@idclient INTEGER,
									@orderdate DATETIME,
									@deliveryman_id INTEGER,
									@status VARCHAR(10))
	AS BEGIN
		BEGIN TRANSACTION 
			SELECT dbo.login_stefood.login_email FROM dbo.login_stefood WHERE login_email = @email

			IF(dbo.validaEmail(@email)) = 'Inválido'
				ROLLBACK
			ELSE

			SELECT dbo.clientes.client_cpf FROM dbo.clientes WHERE client_cpf = @cpf
			IF (dbo.validarCPF(@cpf)) = 'Inválido'
				ROLLBACK
	
				ELSE 

				INSERT INTO dbo.order_itens(product_id, orderitens_qnty, orderitens_totalvalue, 
				orderitens_description, client_id, order_date, deliveryman_id, orderitens_status)

				VALUES (@productid, @quantity, @totalvalue, @description, @idclient, @orderdate, @deliveryman_id, @status)

				IF @status = 'Preparando'
				UPDATE dbo.order_itens SET deliveryman_status =  'A caminho do restaurante'
				
			
				ELSE IF @status = 'A caminho'
				UPDATE dbo.order_itens SET deliveryman_status =  'A caminho'
						
					
				ELSE IF @status = 'Entregue'
				UPDATE dbo.order_itens set deliveryman_status = 'Pedido Finalizado'

			COMMIT
				
			END
GO
/****** Object:  StoredProcedure [dbo].[SPcriarpedido]    Script Date: 03/10/2022 10:34:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SPcriarpedido]  (
									@cpf VARCHAR(11),
									@email VARCHAR(100),
									@productid INTEGER,
									@quantity FLOAT,
									@totalvalue FLOAT,
									@description VARCHAR(50),
									@idclient INTEGER,
									@orderdate DATETIME,
									@deliveryman_id INTEGER,
									@status VARCHAR(10),
                                    @cardnumber VARCHAR(16))
	AS BEGIN
		BEGIN TRANSACTION 
			SELECT dbo.login_stefood.login_email FROM dbo.login_stefood WHERE login_email = @email

			IF(dbo.validaEmail(@email)) = 'Inválido'
				ROLLBACK
			ELSE

			SELECT dbo.clientes.client_cpf FROM dbo.clientes WHERE client_cpf = @cpf
			IF (dbo.validarCPF(@cpf)) = 'Inválido'
				ROLLBACK
	
				ELSE 

                SELECT dbo.payment.card_number FROM dbo.payment WHERE card_number = @cardnumber
                IF len(@cardnumber) < 16 
                    ROLLBACK 

                    ELSE

				INSERT INTO dbo.order_itens(product_id, orderitens_qnty, orderitens_totalvalue, 
				orderitens_description, client_id, order_date, deliveryman_id, orderitens_status)

				VALUES (@productid, @quantity, @totalvalue, @description, @idclient, @orderdate, @deliveryman_id, @status)

				IF @status = 'Preparando'
				UPDATE dbo.order_itens SET deliveryman_status =  'A caminho do restaurante'
				
			
				ELSE IF @status = 'A caminho'
				UPDATE dbo.order_itens SET deliveryman_status =  'A caminho da sua residência'
						
					
				ELSE IF @status = 'Entregue'
				UPDATE dbo.order_itens set deliveryman_status = 'Pedido Finalizado'

			COMMIT
				
			END
GO
USE [master]
GO
ALTER DATABASE [stefood] SET  READ_WRITE 
GO
