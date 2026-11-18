# Listas de espera quirúrgica del SNS

Demo de portfolio con datos públicos agregados a 31 de diciembre de 2025. Abre index.html y recorre la carga original, el reproceso y la rectificación. Filtra por Castilla-La Mancha para ver el cambio de 36.260 a 36.491 pacientes y de 92 a 117 días de demora media. Es una revisión del mismo cierre.

## Procedencia

- [Informe original](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/docs/Datos_ccaa_dic2025.pdf)
- [Informe rectificado](https://www.sanidad.gob.es/ca/estadEstudios/estadisticas/inforRecopilaciones/docs/Datos_ccaa_dic2025_rectificado.pdf)
- [Nota oficial](https://vsf-iwsold-pro-portal.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/docs/Nota_Aclaratoria_Rectificacion_Dic_2025.pdf)

Los CSV transcriben la columna TOTAL de pacientes en espera estructural y tiempo medio de espera (páginas 3 y 4). El fichero original contiene 19 territorios. El fichero de revisión contiene el cambio de Castilla-La Mancha. La cifra nacional de demora del cuadro proviene de la nota oficial. Las revisiones 1 y 2 y los códigos territoriales son convenciones de la demo.

## Ejecutar la carga

Con el SDK de .NET 8, ejecuta desde esta carpeta:

```powershell
dotnet run -- resultado.json datos/sisle-original.csv datos/sisle-original.csv datos/sisle-rectificacion.csv
```

C# valida cada fila y registra la huella del fichero. En Visual Studio puedes depurar el proyecto Validador.csproj. Para probar errores por separado, modifica una copia del CSV. Los dos ficheros SISLE son los insumos de la carga real. envio.csv y correccion.csv pertenecen al ejemplo ficticio anterior.

Ejecuta modelo.sql en una base SQL Server vacía con compatibilidad 130 o superior y pasa el contenido de resultado.json como parámetro NVARCHAR(MAX) a dbo.CargarEnvios. Repite la llamada y comprueba que se mantienen dos envíos, 20 filas históricas y 19 territorios vigentes. La vista vigente selecciona la revisión de mayor número por territorio y fecha.

```sql
SELECT Revision, Pacientes, DemoraDias
FROM dbo.vCalidadEnvios WHERE Comunidad = 'CLM' ORDER BY Revision;

SELECT COUNT(*) AS Territorios, SUM(Pacientes) AS Pacientes
FROM dbo.vRegistroVigente WHERE Fecha = '2025-12-31';
```

El cuadro local reproduce las dos publicaciones con una copia de las cifras. Selecciona resultado.json en «Importar resultado del validador» para usar el histórico validado por C# y mostrar la última revisión por territorio. En el modo importado, la demora nacional queda sin valor porque el CSV contiene cifras territoriales. El paso SQL se ejecuta por separado.

## Implantación propuesta

SSIS recogería los CSV, ejecutaría el validador y enviaría el JSON al procedimiento SQL. SSAS Tabular expondría las cifras por fecha y territorio. La demora media nacional se cargaría como un indicador oficial de ámbito nacional. Power BI mostraría los indicadores vigentes y SSRS generaría un informe paginado de revisiones y rechazos. Power BI Report Server alojaría ambos informes.

<img width="700" alt="Arquitectura de implantación propuesta" src="https://github.com/user-attachments/assets/52808394-d383-430e-b7e2-5519bf74d66e" />

C#/.NET y SQL Server ejecutados y verificados. La integración con SSIS, SSAS, Power BI, SSRS y Power BI Report Server forma parte del diseño de implantación propuesto.


## Prueba repetible en Windows

Con .NET 8 y una instancia SQL Server con autenticación integrada y certificado de confianza, crea una base vacía dedicada a la demo. Ejecuta una vez:

```powershell
.\comprobar-carga.ps1 -Servidor '<servidor>' -Base '<base-demo>' -Inicializar
```

En repeticiones, omite -Inicializar. El script vuelve a generar resultado.json, ejecuta dos veces el procedimiento y verifica los recuentos y la revisión de Castilla-La Mancha. Ejecuta la prueba en una base dedicada, ya que sus comprobaciones cuentan todos los registros de las tablas.

## Consultas para los informes

informes.sql contiene dos consultas independientes. Usa la primera como origen del cuadro interactivo y la segunda como origen del informe paginado. En el cuadro, suma Pacientes solo dentro de un mismo cierre y muestra DemoraDias por territorio. En el paginado, incluye Archivo y Linea para rastrear cada fila y permite seleccionar revisiones y rechazos.
