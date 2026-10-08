using System.Text.RegularExpressions;

namespace FinSure.RiskScoring.Api.Middleware;

// Accepts an inbound X-Correlation-ID or mints one. Echoes it on the response
// so callers can trace a request across FinSure and RiskShield.
// Inbound values are capped at 128 chars with an [A-Za-z0-9-] allowlist:
// overlong valid values are truncated, values with invalid chars are dropped
// and replaced with a minted id. This bounds header/log size and blocks
// log injection via control chars or newlines.
public sealed class CorrelationIdMiddleware(RequestDelegate next)
{
  public const string HeaderName = "X-Correlation-ID";
  public const string ItemKey = "CorrelationId";
  public const int MaxLength = 128;

  private static readonly Regex Allowed = new("^[A-Za-z0-9-]+$", RegexOptions.Compiled);

  public async Task InvokeAsync(HttpContext context)
  {
    var correlationId = Sanitize(
      context.Request.Headers.TryGetValue(HeaderName, out var incoming)
        ? incoming.ToString()
        : null);

    context.Items[ItemKey] = correlationId;
    context.Response.Headers[HeaderName] = correlationId;

    using (context.RequestServices
      .GetRequiredService<ILogger<CorrelationIdMiddleware>>()
      .BeginScope(new Dictionary<string, object> { ["CorrelationId"] = correlationId }))
    {
      await next(context).ConfigureAwait(false);
    }
  }

  public static string Sanitize(string? incoming)
  {
    if (string.IsNullOrWhiteSpace(incoming))
    {
      return Guid.NewGuid().ToString("N");
    }

    var candidate = incoming.Length > MaxLength
      ? incoming.Substring(0, MaxLength)
      : incoming;

    if (!Allowed.IsMatch(candidate))
    {
      return Guid.NewGuid().ToString("N");
    }

    return candidate;
  }
}
