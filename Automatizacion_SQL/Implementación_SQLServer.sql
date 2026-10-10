/* CREACIÓN DE LA BASE DE DATOS */
CREATE DATABASE DataSalud_SanMartin;
GO

/* SELECCIÓN DE LA BASE DE DATOS */
USE DataSalud_SanMartin;
GO

/* CREACIÓN DE LA TABLA stg_Atenciones */
CREATE TABLE stg_Atenciones (
    ANIO NVARCHAR(30),
    MES NVARCHAR(30),
    DIA NVARCHAR(30),
    CATEGORIA NVARCHAR(100),
    RED NVARCHAR(200),
    MICRORED NVARCHAR(200),
    CODIGO_UNICO NVARCHAR(100),
    NOMBRE_ESTABLECIMIENTO NVARCHAR(300),
    PROVINCIA NVARCHAR(100),
    DISTRITO NVARCHAR(100),
    EDAD_REG NVARCHAR(30),
    TIPO_EDAD NVARCHAR(30),
    SEXO NVARCHAR(30),
    ETNIA NVARCHAR(200),
    TIPO_SEGURO NVARCHAR(100),
    UPS NVARCHAR(500),
    ATENDIDOS NVARCHAR(30),
    ATENCIONES NVARCHAR(30),
    FECHA_CORTE NVARCHAR(30)
);
GO

/* CARGA DEL CSV DE ATENCIONES */
BULK INSERT stg_Atenciones
FROM 'C:\DataSalud\atenciones.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    MAXERRORS = 0
);
GO

/* VISUALIZACIÓN DE LA TABLA stg_Atenciones */
SELECT TOP (10) *
FROM stg_Atenciones;

/* CREACIÓN DE LA TABLA stg_Mortalidad */
CREATE TABLE stg_Mortalidad (
    REGISTROID NVARCHAR(100),
    CODIGO_ESTABLECIMIENTO NVARCHAR(100),
    ESTABLECIMIENTO NVARCHAR(300),
    CATEGORIA_ESTABLECIMIENTO NVARCHAR(100),
    CODIGO_SUBREGION NVARCHAR(100),
    SUBREGION NVARCHAR(200),
    CODIGO_RED NVARCHAR(100),
    RED NVARCHAR(200),
    CODIGO_MICRORED NVARCHAR(100),
    MICROREDES NVARCHAR(200),
    DNI_PACIENTE NVARCHAR(100),
    UBIGEO_PACIENTE NVARCHAR(100),
    CODIGO_DEPARTAMENTO NVARCHAR(100),
    DEPARTAMENTO NVARCHAR(200),
    CODIGO_PROVINCIA NVARCHAR(100),
    PROVINCIA NVARCHAR(200),
    CODIGO_DISTRITO NVARCHAR(100),
    DISTRITO NVARCHAR(200),
    ANIO NVARCHAR(30),
    SEMANA NVARCHAR(30),
    SEXO NVARCHAR(30),
    EDAD_MADRE NVARCHAR(30),
    FECHA_NACIMIENTO NVARCHAR(30),
    HORA_NACIMIENTO NVARCHAR(50),
    FECHA_MUERTE NVARCHAR(30),
    HORA_MUERTE NVARCHAR(50),
    PESO_NACIMIENTO NVARCHAR(30),
    CODIGO_TIPO_MUERTE NVARCHAR(100),
    TIPO_MUERTE NVARCHAR(100),
    DIAGNOSTICO_CODIGO NVARCHAR(100),
    DIAGNOSTICO NVARCHAR(500),
    CODIGO_CATEGORIA NVARCHAR(100),
    CATEGORIA NVARCHAR(300),
    ESTANCIA NVARCHAR(30),
    LUGAR_PARTO NVARCHAR(100),
    MOMENTO NVARCHAR(100),
    LUGAR_MUERTE NVARCHAR(100),
    FECHA_REG NVARCHAR(30),
    PREMATURO NVARCHAR(100),
    CARACTERISTICA_PREMATURO NVARCHAR(100),
    CATEGORIA_PESO1 NVARCHAR(100),
    CATEGORIA_PESO2 NVARCHAR(100),
    EVITABLE NVARCHAR(100),
    MADRE_TIPO_PARTO NVARCHAR(100),
    MADRE_CONDICION_CIEX NVARCHAR(100),
    MADRE_COND_CIEX_NOMBRE NVARCHAR(300),
    ETNIA_FALLECIDO NVARCHAR(100),
    FECHA_CORTE NVARCHAR(30)
);
GO

/* CARGA DEL CSV DE MORTALIDAD */
BULK INSERT stg_Mortalidad
FROM 'C:\DataSalud\mortalidad.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    MAXERRORS = 0
);
GO

/* VISUALIZACIÓN DE LA TABLA stg_Mortalidad */
SELECT TOP (10)
    ANIO, PROVINCIA, DISTRITO, TIPO_MUERTE,
    PREMATURO, ETNIA_FALLECIDO
FROM stg_Mortalidad;

GO
/* CREACIÓN DEL PROCEDIMIENTO sp_ValidarDatos */
CREATE PROCEDURE sp_ValidarDatos
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
        SAVE TRANSACTION PuntoValidacion;

        CREATE TABLE #Resultados (
            RF VARCHAR(4),
            Dataset NVARCHAR(30),
            Regla NVARCHAR(150),
            Cantidad BIGINT
        );

        /* RF01: DUPLICADOS COMPLETOS EN AMBOS DATASETS */
        DECLARE @Paso INT = 1, @Tabla SYSNAME;
        DECLARE @Dataset NVARCHAR(30);
        DECLARE @Columnas NVARCHAR(MAX), @SQL NVARCHAR(MAX);
        DECLARE @Duplicados BIGINT;

        WHILE @Paso <= 2
        BEGIN
            SET @Tabla = CASE @Paso WHEN 1
                THEN N'stg_Atenciones' ELSE N'stg_Mortalidad' END;
            SET @Dataset = CASE @Paso WHEN 1
                THEN N'Atenciones' ELSE N'Mortalidad' END;

            SELECT @Columnas = STRING_AGG(
                CAST(N'CONVERT(VARBINARY(MAX),' + QUOTENAME(name)
                     + N')' AS NVARCHAR(MAX)), N','
            ) WITHIN GROUP (ORDER BY column_id)
            FROM sys.columns
            WHERE object_id = OBJECT_ID(@Tabla);

            SET @SQL = N'
                SELECT @Total = COALESCE(SUM(N - 1), 0)
                FROM (
                    SELECT COUNT_BIG(*) AS N
                    FROM ' + QUOTENAME(@Tabla) + N'
                    GROUP BY ' + @Columnas + N'
                    HAVING COUNT_BIG(*) > 1
                ) AS D;';

            EXEC sys.sp_executesql @SQL,
                N'@Total BIGINT OUTPUT',
                @Total = @Duplicados OUTPUT;

            INSERT INTO #Resultados
            VALUES ('RF01', @Dataset,
                    N'Filas duplicadas adicionales', @Duplicados);

            SET @Paso += 1;
        END;

        /* RF02: VALORES DE ATENCIONES QUE REQUIEREN REVISIÓN */
        INSERT INTO #Resultados
        SELECT 'RF02', N'Atenciones',
               N'EDAD_REG negativa', COUNT_BIG(*)
        FROM stg_Atenciones
        WHERE TRY_CONVERT(INT, EDAD_REG) < 0
        UNION ALL
        SELECT 'RF02', N'Atenciones',
               N'CATEGORIA igual a 0', COUNT_BIG(*)
        FROM stg_Atenciones
        WHERE LTRIM(RTRIM(CATEGORIA)) = N'0';

        /* RF03: INFORMACIÓN NO REGISTRADA EN MORTALIDAD */
        INSERT INTO #Resultados
        SELECT 'RF03', N'Mortalidad',
               N'PREMATURO no registrado o vacío', COUNT_BIG(*)
        FROM stg_Mortalidad
        WHERE UPPER(LTRIM(RTRIM(PREMATURO))) = N'NO REGISTRADO'
           OR NULLIF(LTRIM(RTRIM(PREMATURO)), N'') IS NULL
        UNION ALL
        SELECT 'RF03', N'Mortalidad',
               N'ETNIA_FALLECIDO no registrada o vacía', COUNT_BIG(*)
        FROM stg_Mortalidad
        WHERE UPPER(LTRIM(RTRIM(ETNIA_FALLECIDO))) = N'NO REGISTRADO'
           OR NULLIF(LTRIM(RTRIM(ETNIA_FALLECIDO)), N'') IS NULL;

        /* RF04: CONSISTENCIA TEMPORAL EN MORTALIDAD */
        SELECT
            TRY_CONVERT(INT, ANIO) AS AnioRegistro,
            TRY_CONVERT(DATE, LTRIM(RTRIM(FECHA_NACIMIENTO)), 112)
                AS Nacimiento,
            TRY_CONVERT(DATE, LTRIM(RTRIM(FECHA_MUERTE)), 112)
                AS Muerte,
            TRY_CONVERT(DATE, LTRIM(RTRIM(FECHA_REG)), 112)
                AS Registro
        INTO #Fechas
        FROM stg_Mortalidad;

        INSERT INTO #Resultados
        SELECT 'RF04', N'Mortalidad',
               N'Fecha faltante o no convertible', COUNT_BIG(*)
        FROM #Fechas
        WHERE Nacimiento IS NULL OR Muerte IS NULL OR Registro IS NULL
        UNION ALL
        SELECT 'RF04', N'Mortalidad',
               N'Fallecimiento anterior al nacimiento', COUNT_BIG(*)
        FROM #Fechas
        WHERE Muerte < Nacimiento
        UNION ALL
        SELECT 'RF04', N'Mortalidad',
               N'Registro anterior al fallecimiento: revisar', COUNT_BIG(*)
        FROM #Fechas
        WHERE Registro < Muerte
        UNION ALL
        SELECT 'RF04', N'Mortalidad',
               N'Año de registro distinto al fallecimiento: observación',
               COUNT_BIG(*)
        FROM #Fechas
        WHERE AnioRegistro <> YEAR(Muerte);

        COMMIT TRANSACTION;

        SELECT RF, Dataset, Regla, Cantidad
        FROM #Resultados
        ORDER BY RF, Dataset, Regla;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* COMPROBACIÓN DEL PROCEDIMIENTO sp_ValidarDatos */
EXEC sp_ValidarDatos;

GO
/* CREACIÓN DE LA TABLA Atenciones */
CREATE TABLE Atenciones (
    Id_Atencion BIGINT IDENTITY(1,1) PRIMARY KEY,
    ANIO INT,
    MES INT,
    DIA INT,
    CATEGORIA NVARCHAR(100),
    RED NVARCHAR(200),
    MICRORED NVARCHAR(200),
    CODIGO_UNICO NVARCHAR(100),
    NOMBRE_ESTABLECIMIENTO NVARCHAR(300),
    PROVINCIA NVARCHAR(100),
    DISTRITO NVARCHAR(100),
    EDAD_REG INT,
    TIPO_EDAD NVARCHAR(30),
    SEXO NVARCHAR(30),
    ETNIA NVARCHAR(200),
    TIPO_SEGURO NVARCHAR(100),
    UPS NVARCHAR(500),
    ATENDIDOS INT,
    ATENCIONES INT,
    FECHA_CORTE DATE
);
GO

/* CREACIÓN DE LA TABLA Mortalidad */
CREATE TABLE Mortalidad (
    Id_Mortalidad BIGINT IDENTITY(1,1) PRIMARY KEY,
    REGISTROID NVARCHAR(100),
    CODIGO_ESTABLECIMIENTO NVARCHAR(100),
    ESTABLECIMIENTO NVARCHAR(300),
    CATEGORIA_ESTABLECIMIENTO NVARCHAR(100),
    CODIGO_SUBREGION NVARCHAR(100),
    SUBREGION NVARCHAR(200),
    CODIGO_RED NVARCHAR(100),
    RED NVARCHAR(200),
    CODIGO_MICRORED NVARCHAR(100),
    MICROREDES NVARCHAR(200),
    DNI_PACIENTE NVARCHAR(100),
    UBIGEO_PACIENTE NVARCHAR(100),
    CODIGO_DEPARTAMENTO NVARCHAR(100),
    DEPARTAMENTO NVARCHAR(200),
    CODIGO_PROVINCIA NVARCHAR(100),
    PROVINCIA NVARCHAR(200),
    CODIGO_DISTRITO NVARCHAR(100),
    DISTRITO NVARCHAR(200),
    ANIO INT,
    SEMANA INT,
    SEXO NVARCHAR(30),
    EDAD_MADRE INT,
    FECHA_NACIMIENTO DATE,
    HORA_NACIMIENTO NVARCHAR(50),
    FECHA_MUERTE DATE,
    HORA_MUERTE NVARCHAR(50),
    PESO_NACIMIENTO INT,
    CODIGO_TIPO_MUERTE NVARCHAR(100),
    TIPO_MUERTE NVARCHAR(100),
    DIAGNOSTICO_CODIGO NVARCHAR(100),
    DIAGNOSTICO NVARCHAR(500),
    CODIGO_CATEGORIA NVARCHAR(100),
    CATEGORIA NVARCHAR(300),
    ESTANCIA INT,
    LUGAR_PARTO NVARCHAR(100),
    MOMENTO NVARCHAR(100),
    LUGAR_MUERTE NVARCHAR(100),
    FECHA_REG DATE,
    PREMATURO NVARCHAR(100),
    CARACTERISTICA_PREMATURO NVARCHAR(100),
    CATEGORIA_PESO1 NVARCHAR(100),
    CATEGORIA_PESO2 NVARCHAR(100),
    EVITABLE NVARCHAR(100),
    MADRE_TIPO_PARTO NVARCHAR(100),
    MADRE_CONDICION_CIEX NVARCHAR(100),
    MADRE_COND_CIEX_NOMBRE NVARCHAR(300),
    ETNIA_FALLECIDO NVARCHAR(100),
    FECHA_CORTE DATE
);
GO

/* CREACIÓN DEL PROCEDIMIENTO sp_IngestarDatos */
CREATE PROCEDURE sp_IngestarDatos
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @@TRANCOUNT > 0
        THROW 50001, 'Ejecute sin una transacción abierta.', 1;

    DECLARE @Paso INT = 1, @Tabla SYSNAME, @Origen SYSNAME;
    DECLARE @Columnas NVARCHAR(MAX), @Valores NVARCHAR(MAX);
    DECLARE @Comparacion NVARCHAR(MAX), @SQL NVARCHAR(MAX);
    DECLARE @Antes BIGINT, @Insertadas BIGINT;

    CREATE TABLE #Resumen (
        Dataset NVARCHAR(30),
        FilasAntes BIGINT,
        FilasInsertadas BIGINT,
        FilasFinales BIGINT,
        Estado NVARCHAR(50)
    );

    BEGIN TRY
        BEGIN TRANSACTION;
        SAVE TRANSACTION PuntoIngesta;

        WHILE @Paso <= 2
        BEGIN
            SET @Tabla = CASE @Paso WHEN 1
                THEN N'Atenciones' ELSE N'Mortalidad' END;
            SET @Origen = N'stg_' + @Tabla;

            /* COMPROBAR LA TABLA DESTINO */
            SET @SQL = N'SELECT @N = COUNT_BIG(*)
                         FROM ' + QUOTENAME(@Tabla)
                         + N' WITH (TABLOCKX, HOLDLOCK);';

            EXEC sys.sp_executesql @SQL,
                N'@N BIGINT OUTPUT', @N = @Antes OUTPUT;

            SET @Insertadas = 0;

            IF @Antes = 0
            BEGIN
                /* COLUMNAS Y CONVERSIONES DEL DESTINO */
                SELECT
                    @Columnas = STRING_AGG(
                        CAST(QUOTENAME(c.name) AS NVARCHAR(MAX)), N','
                    ) WITHIN GROUP (ORDER BY c.column_id),
                    @Valores = STRING_AGG(
                        CAST(
                            CASE
                                WHEN t.name = N'int' THEN
                                    N'TRY_CONVERT(INT,'
                                    + QUOTENAME(c.name) + N')'
                                WHEN t.name = N'date' THEN
                                    N'TRY_CONVERT(DATE,LTRIM(RTRIM('
                                    + QUOTENAME(c.name) + N')),112)'
                                ELSE
                                    N'LTRIM(RTRIM('
                                    + QUOTENAME(c.name) + N'))'
                            END AS NVARCHAR(MAX)
                        ), N','
                    ) WITHIN GROUP (ORDER BY c.column_id)
                FROM sys.columns c
                JOIN sys.types t ON c.user_type_id = t.user_type_id
                WHERE c.object_id = OBJECT_ID(@Tabla)
                  AND c.is_identity = 0;

                /* COMPARAR TODOS LOS CAMPOS ORIGINALES */
                SELECT @Comparacion = STRING_AGG(
                    CAST(N'CONVERT(VARBINARY(MAX),'
                         + QUOTENAME(name) + N')' AS NVARCHAR(MAX)),
                    N','
                ) WITHIN GROUP (ORDER BY column_id)
                FROM sys.columns
                WHERE object_id = OBJECT_ID(@Origen);

                /* EXCLUIR COPIAS ADICIONALES ANTES DE CONVERTIR */
                SET @SQL = N'
                    IF NOT EXISTS (SELECT 1 FROM '
                    + QUOTENAME(@Origen) + N')
                        THROW 50002, ''La tabla de preparación está vacía.'', 1;

                    WITH Datos AS (
                        SELECT *, ROW_NUMBER() OVER (
                            PARTITION BY ' + @Comparacion + N'
                            ORDER BY (SELECT NULL)
                        ) AS NumeroCopia
                        FROM ' + QUOTENAME(@Origen) + N'
                    )
                    INSERT INTO ' + QUOTENAME(@Tabla)
                    + N' (' + @Columnas + N')
                    SELECT ' + @Valores + N'
                    FROM Datos
                    WHERE NumeroCopia = 1;

                    SET @N = @@ROWCOUNT;';

                EXEC sys.sp_executesql @SQL,
                    N'@N BIGINT OUTPUT', @N = @Insertadas OUTPUT;
            END;

            INSERT INTO #Resumen
            VALUES (
                @Tabla, @Antes, @Insertadas, @Antes + @Insertadas,
                CASE WHEN @Antes = 0 THEN N'Carga realizada'
                     ELSE N'Carga omitida: tabla con datos' END
            );

            SET @Paso += 1;
        END;

        COMMIT TRANSACTION;

        SELECT *
        FROM #Resumen
        ORDER BY Dataset;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* COMPROBACIÓN DEL PROCEDIMIENTO sp_IngestarDatos */
EXEC sp_IngestarDatos;

GO
/* CREACIÓN DE LA TABLA Log_Auditoria */
CREATE TABLE Log_Auditoria (
    Id_Log BIGINT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Usuario NVARCHAR(128) NOT NULL,
    Tabla NVARCHAR(50) NOT NULL,
    Operacion NVARCHAR(30) NOT NULL,
    Id_Registro BIGINT,
    Detalle NVARCHAR(500)
);
GO

/* CREACIÓN DEL TRIGGER DE AUDITORÍA */
CREATE TRIGGER trg_Auditoria_Atenciones
ON Atenciones
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Log_Auditoria (
        Usuario, Tabla, Operacion, Id_Registro, Detalle
    )
    SELECT
        ORIGINAL_LOGIN(),
        N'Atenciones',
        CASE
            WHEN d.Id_Atencion IS NULL THEN N'INSERT'
            WHEN i.Id_Atencion IS NULL THEN N'DELETE'
            ELSE N'UPDATE'
        END,
        COALESCE(i.Id_Atencion, d.Id_Atencion),
        CONCAT(
            N'ATENCIONES anterior: ',
            COALESCE(CONVERT(NVARCHAR(20), d.ATENCIONES), N'NULL'),
            N'; ATENCIONES nueva: ',
            COALESCE(CONVERT(NVARCHAR(20), i.ATENCIONES), N'NULL')
        )
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON i.Id_Atencion = d.Id_Atencion;
END;
GO

/* PRUEBA DEL TRIGGER DE AUDITORÍA */
DECLARE @IdPrueba BIGINT;

INSERT INTO Atenciones (
    ANIO, MES, DIA, CODIGO_UNICO,
    NOMBRE_ESTABLECIMIENTO, ATENDIDOS, ATENCIONES
)
VALUES (
    2023, 1, 1, N'PRUEBA_AUDITORIA',
    N'ESTABLECIMIENTO DE PRUEBA', 1, 2
);

SET @IdPrueba = CONVERT(BIGINT, SCOPE_IDENTITY());

UPDATE Atenciones
SET ATENCIONES = 3
WHERE Id_Atencion = @IdPrueba;

DELETE FROM Atenciones
WHERE Id_Atencion = @IdPrueba;

/* VISUALIZACIÓN DE LA AUDITORÍA */
SELECT Id_Log, Fecha, Usuario, Operacion, Id_Registro, Detalle
FROM Log_Auditoria
WHERE Tabla = N'Atenciones'
  AND Id_Registro = @IdPrueba
ORDER BY Id_Log;

GO
/* CREACIÓN DEL TRIGGER DE INTEGRIDAD */
CREATE TRIGGER trg_Integridad_Atenciones
ON Atenciones
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE ATENDIDOS < 0 OR ATENCIONES < 0
    )
        THROW 50003,
              'ATENDIDOS y ATENCIONES no pueden ser negativos.',
              1;

    INSERT INTO Log_Auditoria (
        Usuario, Tabla, Operacion, Id_Registro, Detalle
    )
    SELECT
        ORIGINAL_LOGIN(),
        N'Atenciones',
        N'INTEGRIDAD_OK',
        Id_Atencion,
        N'Comprobación de cantidades negativas superada.'
    FROM inserted;
END;
GO

/* PRUEBA DEL TRIGGER DE INTEGRIDAD */
DECLARE @IdPrueba BIGINT;

INSERT INTO Atenciones (
    CODIGO_UNICO, NOMBRE_ESTABLECIMIENTO,
    ATENDIDOS, ATENCIONES
)
VALUES (
    N'PRUEBA_INTEGRIDAD', N'ESTABLECIMIENTO DE PRUEBA', 1, 2
);

SET @IdPrueba = CONVERT(BIGINT, SCOPE_IDENTITY());

/* INTENTO DE ACTUALIZACIÓN CON CANTIDAD NEGATIVA */
BEGIN TRY
    UPDATE Atenciones
    SET ATENCIONES = -5
    WHERE Id_Atencion = @IdPrueba;
END TRY
BEGIN CATCH
    SELECT N'Operación rechazada' AS Resultado,
           ERROR_MESSAGE() AS Motivo;
END CATCH;

/* COMPROBAR QUE SE CONSERVÓ LA CANTIDAD VÁLIDA */
SELECT Id_Atencion, CODIGO_UNICO, ATENDIDOS, ATENCIONES
FROM Atenciones
WHERE Id_Atencion = @IdPrueba;

/* COMPROBAR EL REGISTRO DE INTEGRIDAD */
SELECT Operacion, Id_Registro, Detalle
FROM Log_Auditoria
WHERE Id_Registro = @IdPrueba
  AND Tabla = N'Atenciones'
  AND Operacion = N'INTEGRIDAD_OK';

/* ELIMINACIÓN DE LA FILA DE PRUEBA */
DELETE FROM Atenciones
WHERE Id_Atencion = @IdPrueba;

/* CREACIÓN DE LA FUNCIÓN ESCALAR */
CREATE FUNCTION fn_NormalizarTexto (
    @Texto NVARCHAR(500)
)
RETURNS NVARCHAR(500)
AS
BEGIN
    RETURN NULLIF(UPPER(LTRIM(RTRIM(@Texto))), N'');
END;
GO

/* PRUEBA DE LA FUNCIÓN ESCALAR */
SELECT
    Texto AS TextoOriginal,
    dbo.fn_NormalizarTexto(Texto) AS TextoNormalizado
FROM (VALUES
    (N'  femenino  '),
    (N' masculino '),
    (N' no registrado '),
    (N'   ')
) AS Prueba(Texto);
GO