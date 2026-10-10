/* CREACIÓN DEL DATA WAREHOUSE */
CREATE DATABASE DW_DataSalud_SanMartin;
GO

/* SELECCIÓN DEL DATA WAREHOUSE */
USE DW_DataSalud_SanMartin;
GO

/* CREACIÓN DE LA DIMENSIÓN TIEMPO */
CREATE TABLE Dim_Tiempo (
    Id_Tiempo INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    Anio INT NOT NULL,
    Mes INT NOT NULL,
    Dia INT NOT NULL
);
GO

/* CREACIÓN DE LA DIMENSIÓN UBICACIÓN */
CREATE TABLE Dim_Ubicacion (
    Id_Ubicacion INT IDENTITY(1,1) PRIMARY KEY,
    Departamento NVARCHAR(200) NOT NULL,
    Provincia NVARCHAR(200) NOT NULL,
    Distrito NVARCHAR(200) NOT NULL,
    UNIQUE (Departamento, Provincia, Distrito)
);
GO

/* CREACIÓN DE LA DIMENSIÓN SEXO */
CREATE TABLE Dim_Sexo (
    Id_Sexo INT IDENTITY(1,1) PRIMARY KEY,
    Sexo NVARCHAR(30) NOT NULL UNIQUE
);
GO

/* CREACIÓN DE LA TABLA DE HECHOS ATENCIONES */
CREATE TABLE Fact_Atenciones (
    Id_Hecho BIGINT IDENTITY(1,1) PRIMARY KEY,
    Id_Atencion BIGINT NOT NULL UNIQUE,
    Id_Tiempo INT NOT NULL,
    Id_Ubicacion INT NOT NULL,
    Id_Sexo INT NOT NULL,
    Atendidos INT,
    Atenciones INT,

    FOREIGN KEY (Id_Tiempo)
        REFERENCES Dim_Tiempo(Id_Tiempo),

    FOREIGN KEY (Id_Ubicacion)
        REFERENCES Dim_Ubicacion(Id_Ubicacion),

    FOREIGN KEY (Id_Sexo)
        REFERENCES Dim_Sexo(Id_Sexo)
);
GO

/* CREACIÓN DE LA BITÁCORA ETL*/
USE DW_DataSalud_SanMartin;
GO

CREATE TABLE Log_ETL (
    Id_Log INT IDENTITY(1,1) PRIMARY KEY,
    Id_Ejecucion UNIQUEIDENTIFIER NOT NULL,
    Etapa NVARCHAR(100) NOT NULL,
    FechaInicio DATETIME2 NOT NULL,
    FechaFin DATETIME2,
    Registros BIGINT NOT NULL,
    Estado NVARCHAR(20) NOT NULL,
    Detalle NVARCHAR(500)
);
GO

/* VERIFICACIÓN DE LA TABLA DE LOG */
SELECT *
FROM Log_ETL
ORDER BY Id_Log;
GO

/* VERIFICACIÓN DE LAS TABLAS DEL DATA WAREHOUSE */
SELECT
    (SELECT COUNT(*) FROM Dim_Tiempo) AS Dim_Tiempo,
    (SELECT COUNT(*) FROM Dim_Ubicacion) AS Dim_Ubicacion,
    (SELECT COUNT(*) FROM Dim_Sexo) AS Dim_Sexo,
    (SELECT COUNT(*) FROM Fact_Atenciones) AS Fact_Atenciones;
GO

/* COMPARACIÓN ENTRE ORIGEN Y DESTINO */
SELECT
    N'Origen' AS Tabla,
    COUNT(*) AS Registros,
    SUM(CAST(ATENDIDOS AS BIGINT)) AS TotalAtendidos,
    SUM(CAST(ATENCIONES AS BIGINT)) AS TotalAtenciones
FROM DataSalud_SanMartin.dbo.Atenciones

UNION ALL

SELECT
    N'Destino',
    COUNT(*),
    SUM(CAST(Atendidos AS BIGINT)),
    SUM(CAST(Atenciones AS BIGINT))
FROM Fact_Atenciones;