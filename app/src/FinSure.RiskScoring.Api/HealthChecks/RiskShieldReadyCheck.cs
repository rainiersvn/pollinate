using FinSure.RiskScoring.Api.RiskShield;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace FinSure.RiskScoring.Api.HealthChecks;

// Ready means this instance can serve traffic: the vendor API key resolved
// (environment locally, Key Vault reference on Azure). Unhealthy here keeps
// the revision out of rotation instead of failing requests at runtime.
public sealed class RiskShieldReadyCheck(IOptions<RiskShieldOptions> options) : IHealthCheck
{
  public Task<HealthCheckResult> CheckHealthAsync(
    HealthCheckContext context, CancellationToken cancellationToken = default)
  {
    var ready = !string.IsNullOrWhiteSpace(options.Value.ApiKey)
      && Uri.TryCreate(options.Value.BaseUrl, UriKind.Absolute, out _);
    return Task.FromResult(ready
      ? HealthCheckResult.Healthy("RiskShield configuration resolved.")
      : HealthCheckResult.Unhealthy("RiskShield API key or base URL is not configured."));
  }
}
