using System.Collections.Concurrent;
using FinSure.RiskScoring.Api.Contracts;
using FinSure.RiskScoring.Api.RiskShield;
using Microsoft.Extensions.Logging;

namespace FinSure.RiskScoring.Api.Tests;

// Captures every log message so tests can assert PII never reaches the sink.
public sealed class CapturingLoggerProvider : ILoggerProvider
{
  public ConcurrentBag<string> Messages { get; } = [];

  public ILogger CreateLogger(string categoryName) => new CapturingLogger(categoryName, Messages);

  public void Dispose() { }

  private sealed class CapturingLogger(string category, ConcurrentBag<string> messages) : ILogger
  {
    public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

    public bool IsEnabled(LogLevel logLevel) => true;

    public void Log<TState>(
      LogLevel logLevel, EventId eventId, TState state,
      Exception? exception, Func<TState, Exception?, string> formatter)
    {
      messages.Add($"{category} {formatter(state, exception)}");
    }
  }
}

// Configurable IRiskShieldClient fake: captures what the endpoint forwarded.
public sealed class StubRiskShieldClient : IRiskShieldClient
{
  public ValidateRequest? SeenRequest { get; private set; }
  public string? SeenCorrelationId { get; private set; }
  public Func<ValidateRequest, string, Task<RiskScoreResult>> Behavior { get; set; } =
    (_, _) => Task.FromResult(new RiskScoreResult(72, "MEDIUM"));

  public Task<RiskScoreResult> GetRiskScoreAsync(
    ValidateRequest request, string correlationId, CancellationToken cancellationToken)
  {
    SeenRequest = request;
    SeenCorrelationId = correlationId;
    return Behavior(request, correlationId);
  }
}

// Stub primary handler for direct RiskShieldClient unit tests.
public sealed class StubHandler(Func<HttpRequestMessage, HttpResponseMessage> responder) : HttpMessageHandler
{
  public HttpRequestMessage? SeenRequest { get; private set; }

  protected override Task<HttpResponseMessage> SendAsync(
    HttpRequestMessage request, CancellationToken cancellationToken)
  {
    cancellationToken.ThrowIfCancellationRequested();
    SeenRequest = request;
    return Task.FromResult(responder(request));
  }
}
