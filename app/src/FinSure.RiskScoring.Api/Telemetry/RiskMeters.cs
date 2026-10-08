using System.Diagnostics.Metrics;

namespace FinSure.RiskScoring.Api.Telemetry;

// Minimal built-in instrumentation: one counter per validation outcome.
// In-process only: no exporter is wired (no OpenTelemetry / Application
// Insights SDK), so values are not shipped anywhere. Observability is
// console logs, forwarded to Log Analytics by the Container Apps environment.
public static class RiskMeters
{
  public const string MeterName = "FinSure.RiskScoring";

  private static readonly Meter Meter = new(MeterName);

  public static readonly Counter<long> Validations = Meter.CreateCounter<long>(
    "riskscoring.validations",
    description: "Number of /validate requests by outcome.");
}
