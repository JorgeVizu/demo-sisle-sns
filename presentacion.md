# Guion de presentación

## Demo en 60 segundos

- **0–15 s.** «El Ministerio de Sanidad publicó una rectificación de las listas de espera quirúrgica de diciembre de 2025. Quería reproducir cómo se incorpora ese cambio a un cuadro y cómo se conserva la publicación inicial».
- **15–35 s.** Abre la publicación original, filtra Castilla-La Mancha y aplica la rectificación. Señala el cambio de 36.260 a 36.491 pacientes y de 92 a 117 días. Ambas cifras corresponden al mismo cierre.
- **35–50 s.** Importa resultado.json. Explica cómo el validador C# reconoce el fichero repetido y cómo el modelo SQL conserva las filas de cada revisión y selecciona la vigente.
- **50–60 s.** Abre el README para mostrar las fuentes y los pasos de ejecución.

## Borrador para LinkedIn

¿Cómo actualizas un cuadro de mando cuando la fuente oficial rectifica un dato ya publicado?

He preparado una demo con las listas de espera quirúrgica del SNS a 31 de diciembre de 2025. El caso reproduce la rectificación de Castilla-La Mancha, que pasó de 36.260 a 36.491 pacientes en espera y de 92 a 117 días de demora media.

El proyecto usa C#/.NET para validar los CSV, SQL Server para guardar el histórico de revisiones y un cuadro web para consultar el resultado. La carga reconoce ficheros repetidos y permite rastrear qué versión de cada cifra está vigente.

[Enlace al repositorio cuando esté publicado]
