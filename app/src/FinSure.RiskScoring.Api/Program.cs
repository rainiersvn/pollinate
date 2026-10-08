using FinSure.RiskScoring.Api.Endpoints;
using FinSure.RiskScoring.Api.HealthChecks;
using FinSure.RiskScoring.Api.Middleware;
using FinSure.RiskScoring.Api.RiskShield;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

// Fail fast on missing vendor configuration instead of failing requests at runtime.
// BaseUrl https is enforced here as well: http downgrades fail startup.
builder.Services
  .AddOptions<RiskShieldOptions>()
  .BindConfiguration(RiskShieldOptions.SectionName)
  .ValidateDataAnnotations()
  .Validate(
    o => Uri.TryCreate(o.BaseUrl, UriKind.Absolute, out var uri) &&
         string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase),
    "RiskShield:BaseUrl must be an absolute https:// URL.")
  .ValidateOnStart();

var resilience = builder.Configuration.GetSection(RiskShieldOptions.SectionName).Get<RiskShieldOptions>()
  ?? new RiskShieldOptions();

// One config block: timeout + retry-with-backoff + circuit breaker.
// Retries only 5xx/408/429: vendor 4xx is a caller error and must not be retried.
builder.Services
  .AddHttpClient<IRiskShieldClient, RiskShieldClient>(client =>
  {
    client.BaseAddress = new Uri(resilience.BaseUrl.TrimEnd('/') + "/");
  })
  .AddStandardResilienceHandler(handler =>
  {
    handler.AttemptTimeout.Timeout = TimeSpan.FromSeconds(resilience.TimeoutSeconds);
    handler.TotalRequestTimeout.Timeout = TimeSpan.FromSeconds(resilience.TimeoutSeconds * (resilience.MaxRetries + 2));
    handler.Retry.MaxRetryAttempts = resilience.MaxRetries;
    handler.Retry.ShouldHandle = args => ValueTask.FromResult(
      args.Outcome.Result?.StatusCode is System.Net.HttpStatusCode.RequestTimeout
        or System.Net.HttpStatusCode.TooManyRequests
        or >= System.Net.HttpStatusCode.InternalServerError);
  });

builder.Services.AddHealthChecks()
  .AddCheck("self", () => HealthCheckResult.Healthy(), tags: ["live"])
  .AddCheck<RiskShieldReadyCheck>("riskshield-config", tags: ["ready"]);

var app = builder.Build();

app.UseMiddleware<CorrelationIdMiddleware>();

app.MapHealthChecks("/health/live", new() { Predicate = check => check.Tags.Contains("live") });
app.MapHealthChecks("/health/ready", new() { Predicate = check => check.Tags.Contains("ready") });
app.MapValidate();

app.Run();

// Test seam for WebApplicationFactory.
public partial class Program;
