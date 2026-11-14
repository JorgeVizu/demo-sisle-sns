CREATE TABLE dbo.Envio (
    Orden bigint IDENTITY PRIMARY KEY,
    Huella char(64) NOT NULL UNIQUE,
    Archivo nvarchar(260) NOT NULL
);
CREATE TABLE dbo.FilaEnvio (
    Envio bigint NOT NULL REFERENCES dbo.Envio(Orden),
    Linea int NOT NULL,
    Id varchar(40) NULL,
    Comunidad char(3) NULL,
    Fecha date NULL,
    Motivo nvarchar(100) NULL,
    Revision int NULL,
    Pacientes int NULL,
    DemoraDias int NULL,
    PRIMARY KEY (Envio, Linea)
);
GO
CREATE OR ALTER PROCEDURE dbo.CargarEnvios @Json nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DECLARE @Bloqueo int;
    EXEC @Bloqueo = sys.sp_getapplock
        @Resource = 'CargarEnvios', @LockMode = 'Exclusive', @LockOwner = 'Transaction';
    IF @Bloqueo < 0 THROW 50001, 'No se pudo bloquear la carga.', 1;

    DECLARE @Entrada table (Posicion int PRIMARY KEY, Huella char(64), Archivo nvarchar(260), Filas nvarchar(max));
    INSERT @Entrada
    SELECT CONVERT(int, j.[key]), d.Huella, d.Archivo, d.Filas
    FROM OPENJSON(@Json, '$.deliveries') AS j
    CROSS APPLY OPENJSON(j.value) WITH (
        Huella char(64) '$.hash', Archivo nvarchar(260) '$.file', Filas nvarchar(max) '$.rows' AS JSON
    ) AS d;

    INSERT dbo.Envio (Huella, Archivo)
    SELECT TOP (2147483647) Huella, Archivo
    FROM @Entrada AS e
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Envio AS x WHERE x.Huella = e.Huella)
    ORDER BY Posicion;

    INSERT dbo.FilaEnvio (Envio, Linea, Id, Comunidad, Fecha, Motivo, Revision, Pacientes, DemoraDias)
    SELECT e.Orden, f.Linea, f.Id, f.Comunidad, f.Fecha, f.Motivo, f.Revision, f.Pacientes, f.DemoraDias
    FROM @Entrada AS i
    JOIN dbo.Envio AS e ON e.Huella = i.Huella
    CROSS APPLY OPENJSON(i.Filas) WITH (
        Linea int '$.line', Id varchar(40) '$.id', Comunidad char(3) '$.territory',
        Fecha date '$.date', Motivo nvarchar(100) '$.reason', Revision int '$.revision',
        Pacientes int '$.patients', DemoraDias int '$.days'
    ) AS f
    WHERE NOT EXISTS (SELECT 1 FROM dbo.FilaEnvio AS x WHERE x.Envio = e.Orden AND x.Linea = f.Linea);
    COMMIT;
END;
GO
CREATE OR ALTER VIEW dbo.vCalidadEnvios AS
SELECT f.*, e.Archivo,
    DATEFROMPARTS(YEAR(f.Fecha), MONTH(f.Fecha), 1) AS Mes,
    CASE WHEN f.Motivo IS NULL THEN 1 ELSE 0 END AS Aceptada
FROM dbo.FilaEnvio AS f JOIN dbo.Envio AS e ON e.Orden = f.Envio;
GO
CREATE OR ALTER VIEW dbo.vRegistroVigente AS
WITH Ordenados AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Id ORDER BY Revision DESC, Envio DESC, Linea DESC) AS Version
    FROM dbo.vCalidadEnvios WHERE Aceptada = 1
)
SELECT Id, Comunidad, Fecha, Mes, Envio, Linea, Revision, Pacientes, DemoraDias FROM Ordenados WHERE Version = 1;

