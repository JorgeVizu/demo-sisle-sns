using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

if (args.Length < 2)
{
    Console.Error.WriteLine("Uso: dotnet run -- salida.json fichero1.csv [fichero2.csv ...]");
    return 1;
}

var territories = new HashSet<string>(StringComparer.Ordinal) { "AND", "ARA", "AST", "BAL", "CAN", "CNT", "CYL", "CLM", "CAT", "VAL", "EXT", "GAL", "MAD", "MUR", "NAV", "PVA", "RIO", "CEU", "MEL" };
var fingerprints = new HashSet<string>(StringComparer.Ordinal);
var deliveries = new List<Delivery>();
var attempts = new List<Attempt>();

foreach (var path in args.Skip(1))
{
    var bytes = File.ReadAllBytes(path);
    var hash = Convert.ToHexString(SHA256.HashData(bytes));
    var name = Path.GetFileName(path);
    if (!fingerprints.Add(hash))
    {
        attempts.Add(new(name, hash, "repetido"));
        continue;
    }

    using var reader = new StringReader(Encoding.UTF8.GetString(bytes).TrimStart('\uFEFF'));
    if (reader.ReadLine() != "comunidad;fecha;revision;pacientes;demora")
    {
        attempts.Add(new(name, hash, "cabecera inválida"));
        continue;
    }

    var rows = new List<Row>();
    var seen = new HashSet<string>(StringComparer.Ordinal);
    string? line;
    while ((line = reader.ReadLine()) != null)
    {
        var fields = line.Split(';', StringSplitOptions.TrimEntries);
        var territory = fields[0].ToUpperInvariant();
        var knownTerritory = territories.Contains(territory);
        var dateValid = DateOnly.TryParseExact(fields.ElementAtOrDefault(1), "yyyy-MM-dd",
            CultureInfo.InvariantCulture, DateTimeStyles.None, out var date);
        var revisionValid = ReadNonnegative(2, out var revision) && revision > 0;
        var patientsValid = ReadNonnegative(3, out var patients);
        var daysValid = ReadNonnegative(4, out var days);
        var key = knownTerritory && dateValid ? $"{territory}-{date:yyyy-MM-dd}" : null;
        var reason = fields.Length != 5 ? "Formato de fila"
            : !knownTerritory ? "Territorio desconocido"
            : !dateValid ? "Fecha inválida"
            : !revisionValid ? "Revisión inválida"
            : !patientsValid ? "Número de pacientes inválido"
            : !daysValid ? "Demora inválida"
            : !seen.Add(key!) ? "Territorio y fecha duplicados"
            : null;
        rows.Add(new(rows.Count + 2, key, knownTerritory ? territory : null,
            dateValid ? date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) : null,
            reason, revisionValid ? revision : null, patientsValid ? patients : null, daysValid ? days : null));

        bool ReadNonnegative(int index, out int value) =>
            int.TryParse(fields.ElementAtOrDefault(index), NumberStyles.None,
                CultureInfo.InvariantCulture, out value);
    }

    deliveries.Add(new(name, hash, rows));
    attempts.Add(new(name, hash, "procesado"));
}

var json = JsonSerializer.Serialize(new { deliveries, attempts }, new JsonSerializerOptions(JsonSerializerDefaults.Web)
{
    WriteIndented = true
});
File.WriteAllText(args[0], json);
return 0;

record Row(int Line, string? Id, string? Territory, string? Date, string? Reason, int? Revision, int? Patients, int? Days);
record Delivery(string File, string Hash, List<Row> Rows);
record Attempt(string File, string Hash, string Status);

