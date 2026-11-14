param(
    [Parameter(Mandatory)]
    [string]$Servidor,
    [Parameter(Mandatory)]
    [string]$Base,
    [switch]$Inicializar
)

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    dotnet run -- resultado.json datos/sisle-original.csv datos/sisle-original.csv datos/sisle-rectificacion.csv
    if ($LASTEXITCODE) { throw 'Falló el validador C#.' }

    $connection = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
    $connection.DataSource = $Servidor
    $connection.InitialCatalog = $Base
    $connection.IntegratedSecurity = $true
    $connection.Encrypt = $true
    $sql = [System.Data.SqlClient.SqlConnection]::new($connection.ConnectionString)
    try {
        $sql.Open()
        $command = $sql.CreateCommand()
        try {
            if ($Inicializar) {
                foreach ($batch in ((Get-Content modelo.sql -Raw) -split '(?im)^GO\s*$')) {
                    if ($batch.Trim()) {
                        $command.CommandText = $batch
                        [void]$command.ExecuteNonQuery()
                    }
                }
            }
            $command.CommandText = @"
EXEC dbo.CargarEnvios @Json = @datos;
EXEC dbo.CargarEnvios @Json = @datos;
IF (SELECT COUNT(*) FROM dbo.Envio) <> 2
   OR (SELECT COUNT(*) FROM dbo.FilaEnvio) <> 20
   OR (SELECT COUNT(*) FROM dbo.vRegistroVigente) <> 19
   OR COALESCE((SELECT SUM(Pacientes) FROM dbo.vRegistroVigente), -1) <> 853740
   OR NOT EXISTS (
       SELECT 1 FROM dbo.vRegistroVigente
       WHERE Comunidad = 'CLM' AND Revision = 2 AND Pacientes = 36491 AND DemoraDias = 117
   )
    THROW 50002, 'La carga no coincide con los resultados esperados.', 1;
"@
            $parameter = $command.Parameters.Add('@datos', [System.Data.SqlDbType]::NVarChar, -1)
            $parameter.Value = Get-Content resultado.json -Raw -Encoding UTF8
            [void]$command.ExecuteNonQuery()
            Write-Output 'Verificado: 2 envíos, 20 filas, 19 territorios y 853.740 pacientes.'
        } finally {
            $command.Dispose()
        }
    } finally {
        $sql.Dispose()
    }
} finally {
    Pop-Location
}
