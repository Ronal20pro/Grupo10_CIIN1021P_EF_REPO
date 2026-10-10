/* DATOS PARA EL ANÁLISIS CON SPARK */
USE DW_DataSalud_SanMartin;
GO

SELECT
    U.Provincia AS PROVINCIA,
    F.Atendidos AS ATENDIDOS,
    F.Atenciones AS ATENCIONES
FROM Fact_Atenciones AS F
INNER JOIN Dim_Ubicacion AS U
    ON F.Id_Ubicacion = U.Id_Ubicacion;

/* AGREGACIÓN DE ATENCIONES POR PROVINCIA */
USE DW_DataSalud_SanMartin;
GO

SELECT
    U.Provincia AS PROVINCIA,
    SUM(CAST(F.Atenciones AS BIGINT)) AS TotalAtenciones
FROM Fact_Atenciones AS F
INNER JOIN Dim_Ubicacion AS U
    ON F.Id_Ubicacion = U.Id_Ubicacion
GROUP BY U.Provincia
ORDER BY TotalAtenciones DESC, U.Provincia;

/* MEDICIÓN DEL TIEMPO EN SQL SERVER */
SET STATISTICS TIME ON;

SELECT
    U.Provincia AS PROVINCIA,
    SUM(CAST(F.Atenciones AS BIGINT)) AS TotalAtenciones
FROM Fact_Atenciones AS F
INNER JOIN Dim_Ubicacion AS U
    ON F.Id_Ubicacion = U.Id_Ubicacion
GROUP BY U.Provincia
ORDER BY TotalAtenciones DESC, U.Provincia;

SET STATISTICS TIME OFF;