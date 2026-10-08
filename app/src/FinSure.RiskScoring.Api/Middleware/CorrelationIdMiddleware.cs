namespace FinSure.RiskScoring.Api.Middleware;

// Accepts an inbound X-Correlation-ID or mints one. Echoes it on the response
// so callers can trace a request across FinSure and RiskShield.
public sealed class CorrelationIdMiddleware(RequestDelegate next)
{
  public const string HeaderName = "X-Correlation-ID";
  public const string ItemKey = "CorrelationId";

  public async Task InvokeAsync(HttpContext context)
  {
    var correlationId = context.Request.Headers.TryGetValue(HeaderName, out var incoming)
      && !string.IsNullOrWhiteSpace(incoming)
        ? incoming.ToString()
        : Guid.NewGuid().ToString("N");

    context.Items[ItemKey] = correlationId;
    context.Response.Headers[HeaderName] = correlationId;

    using (context.RequestServices
      .GetRequiredService<ILogger<CorrelationIdMiddleware>>()
      .BeginScope(new Dictionary<string, object> { ["CorrelationId"] = correlationId }))
    {
      await next(context).ConfigureAwait(false);
    }
  }
}
