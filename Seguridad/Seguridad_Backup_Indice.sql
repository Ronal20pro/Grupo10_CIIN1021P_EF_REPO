USE DataSalud_SanMartin;
GO

/*CREACIÓN DE LOS ROLES*/

-- ROL PARA EL ADMINISTRADOR
CREATE ROLE rol_Administrador;
GO

-- ROL PARA EL OPERADOR
CREATE ROLE rol_Operador;
GO

-- ROL PARA EL ANALISTA
CREATE ROLE rol_Analista;
GO


/*CREACIÓN DE PERMISOS PARA CADA ROL*/

-- PERMISOS PARA EL ROL DE ADMINISTRADOR

-- Permitir consultar y modificar la tabla Atenciones
GRANT SELECT, INSERT, UPDATE, DELETE
ON Atenciones
TO rol_Administrador;
GO

-- Permitir consultar y modificar la tabla Mortalidad
GRANT SELECT, INSERT, UPDATE, DELETE
ON Mortalidad
TO rol_Administrador;
GO

-- Permitir consultar los registros de auditoría
GRANT SELECT
ON Log_Auditoria
TO rol_Administrador;
GO

-- Permitir ejecutar el procedimiento de ingesta
GRANT EXECUTE
ON sp_IngestarDatos
TO rol_Administrador;
GO

-- Permitir ejecutar el procedimiento de validación
GRANT EXECUTE
ON sp_ValidarDatos
TO rol_Administrador;
GO


-- PERMISOS PARA EL ROL DE OPERADOR

-- Permitir consultar e insertar datos en Atenciones
GRANT SELECT, INSERT
ON Atenciones
TO rol_Operador;
GO

-- Permitir consultar e insertar datos en Mortalidad
GRANT SELECT, INSERT
ON Mortalidad
TO rol_Operador;
GO

-- Permitir ejecutar el procedimiento de ingesta
GRANT EXECUTE
ON sp_IngestarDatos
TO rol_Operador;
GO

-- Permitir ejecutar el procedimiento de validación
GRANT EXECUTE
ON sp_ValidarDatos
TO rol_Operador;
GO


-- PERMISOS PARA EL ROL DE ANALISTA

-- Permitir consultar los datos de Atenciones
GRANT SELECT
ON Atenciones
TO rol_Analista;
GO

-- Permitir consultar los datos de Mortalidad
GRANT SELECT
ON Mortalidad
TO rol_Analista;
GO

-- Permitir utilizar la función de normalización
GRANT EXECUTE
ON fn_NormalizarTexto
TO rol_Analista;
GO


/*VISUALIZACIÓN DE LOS PERMISOS POR ROL*/

SELECT
    dp.name AS Rol,
    o.name AS Objeto,
    p.permission_name AS Permiso
FROM sys.database_permissions p
INNER JOIN sys.database_principals dp
    ON p.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o
    ON p.major_id = o.object_id
WHERE dp.name IN (
    'rol_Administrador',
    'rol_Operador',
    'rol_Analista'
)
ORDER BY dp.name, o.name, p.permission_name;
GO


/*CREACIÓN DEL BACKUP FULL*/

USE master;
GO

BACKUP DATABASE DataSalud_SanMartin
TO DISK = 'C:\DataSalud\Backups\DataSalud_SanMartin_FULL.bak'
WITH
    INIT,
    NAME = 'Backup FULL DataSalud_SanMartin',
    STATS = 10;
GO


/*CREACIÓN DEL BACKUP DIFERENCIAL*/

USE master;
GO

BACKUP DATABASE DataSalud_SanMartin
TO DISK = 'C:\DataSalud\Backups\DataSalud_SanMartin_DIFF.bak'
WITH
    DIFFERENTIAL,
    INIT,
    NAME = 'Backup DIFERENCIAL DataSalud_SanMartin',
    STATS = 10;
GO


/*PREPARACIÓN PARA LA RESTAURACIÓN*/

USE master;
GO

RESTORE FILELISTONLY
FROM DISK = 'C:\DataSalud\Backups\DataSalud_SanMartin_FULL.bak';
GO


/*RESTAURACIÓN DEL BACKUP FULL*/

USE master;
GO

RESTORE DATABASE DataSalud_SanMartin_Restore
FROM DISK = 'C:\DataSalud\Backups\DataSalud_SanMartin_FULL.bak'
WITH
    MOVE 'DataSalud_SanMartin'
        TO 'C:\DataSalud\Backups\DataSalud_SanMartin_Restore.mdf',
    MOVE 'DataSalud_SanMartin_log'
        TO 'C:\DataSalud\Backups\DataSalud_SanMartin_Restore.ldf',
    NORECOVERY,
    REPLACE;
GO


/*RESTAURACIÓN DEL BACKUP DIFERENCIAL*/

USE master;
GO

RESTORE DATABASE DataSalud_SanMartin_Restore
FROM DISK = 'C:\DataSalud\Backups\DataSalud_SanMartin_DIFF.bak'
WITH
    RECOVERY;
GO


/*VERIFICACIÓN DE LA RESTAURACIÓN*/

SELECT COUNT(*) AS RegistrosRestaurados_Atenciones
FROM DataSalud_SanMartin_Restore.dbo.Atenciones;
GO

SELECT COUNT(*) AS RegistrosRestaurados_Mortalidad
FROM DataSalud_SanMartin_Restore.dbo.Mortalidad;
GO


/*RENDIMIENTO ANTES DEL ÍNDICE*/

USE DataSalud_SanMartin;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    CODIGO_UNICO,
    NOMBRE_ESTABLECIMIENTO,
    PROVINCIA,
    ATENDIDOS,
    ATENCIONES
FROM Atenciones
WHERE CODIGO_UNICO = '32185';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO


/*CREACIÓN DEL ÍNDICE*/

USE DataSalud_SanMartin;
GO

CREATE NONCLUSTERED INDEX IX_Atenciones_CodigoUnico
ON Atenciones (CODIGO_UNICO)
INCLUDE (
    NOMBRE_ESTABLECIMIENTO,
    PROVINCIA,
    ATENDIDOS,
    ATENCIONES
);
GO


/*RENDIMIENTO DESPUÉS DE LA CREACIÓN DEL ÍNDICE*/

USE DataSalud_SanMartin;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    CODIGO_UNICO,
    NOMBRE_ESTABLECIMIENTO,
    PROVINCIA,
    ATENDIDOS,
    ATENCIONES
FROM Atenciones
WHERE CODIGO_UNICO = '32185';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO