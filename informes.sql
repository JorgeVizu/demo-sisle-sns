-- Dataset interactivo. La demora es un indicador territorial.
SELECT Fecha, Comunidad, Revision, Pacientes, DemoraDias
FROM dbo.vRegistroVigente
ORDER BY Fecha, Comunidad;

-- Dataset paginado. Incluye las revisiones anteriores y los rechazos.
SELECT Fecha, Comunidad, Revision, Pacientes, DemoraDias, Archivo, Linea, Motivo, Aceptada
FROM dbo.vCalidadEnvios
ORDER BY Envio, Linea;
