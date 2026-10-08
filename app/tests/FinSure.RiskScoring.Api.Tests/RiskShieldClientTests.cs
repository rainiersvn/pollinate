using System.Net;
using System.Text;
using FinSure.RiskScoring.Api.Contracts;
using FinSure.RiskScoring.Api.RiskShield;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace FinSure.RiskScoring.Api.Tests;

// Vendor mapping: success shape, header contract, 4xx/5xx/timeout outcomes.
public sealed class RiskShieldClientTests
{
  private static readonly ValidateRequest Request = new()
  {
    FirstName = "Jane",
    LastName = "Doe",
    IdNumber = "9001011234088",
  };

  private static RiskShieldClient CreateClient(
    Func<HttpRequestMessage, HttpResponseMessage> responder, out StubHandler handler)
  {
    handler = new StubHandler(responder);
    var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.riskshield.com/") };
    var options = Options.Create(new RiskShieldOptions
    {
      BaseUrl = "https://api.riskshield.com",
      ApiKey = "secret-key",
    });
    return new RiskShieldClient(http, options, NullLogger<RiskShieldClient>.Instance);
  }

  private static HttpResponseMessage JsonScore(int score = 72, string level = "MEDIUM") =>
    new(HttpStatusCode.OK)
    {
      Content = new StringContent(
        $"{{\"riskScore\":{score},\"riskLevel\":\"{level}\"}}", Encoding.UTF8, "application/json"),
    };

  [Fact]
  public async Task Success_MapsScoreAndLevel()
  {
    var client = CreateClient(_ => JsonScore(), out _);

    var result = await client.GetRiskScoreAsync(Request, "corr-1", CancellationToken.None);

    Assert.Equal(72, result.RiskScore);
    Assert.Equal("MEDIUM", result.RiskLevel);
  }

  [Fact]
  public async Task Request_SendsApiKeyCorrelationAndVendorPath()
  {
    var client = CreateClient(_ => JsonScore(), out var handler);

    await client.GetRiskScoreAsync(Request, "corr-9", CancellationToken.None);

    Assert.NotNull(handler.SeenRequest);
    Assert.Equal("v1/score", handler.SeenRequest.RequestUri?.PathAndQuery.TrimStart('/'));
    Assert.Equal("secret-key", string.Join(",", handler.SeenRequest.Headers.GetValues("X-Api-Key")));
    Assert.Equal("corr-9", string.Join(",", handler.SeenRequest.Headers.GetValues("X-Correlation-ID")));
  }

  [Fact]
  public async Task Vendor500_MapsToTransient()
  {
    var client = CreateClient(_ => new HttpResponseMessage(HttpStatusCode.InternalServerError), out _);

    await Assert.ThrowsAsync<RiskShieldTransientException>(
      () => client.GetRiskScoreAsync(Request, "corr-1", CancellationToken.None));
  }

  [Fact]
  public async Task Vendor400_MapsToRejected()
  {
    var client = CreateClient(_ => new HttpResponseMessage(HttpStatusCode.BadRequest), out _);

    await Assert.ThrowsAsync<RiskShieldRejectedException>(
      () => client.GetRiskScoreAsync(Request, "corr-1", CancellationToken.None));
  }

  [Fact]
  public async Task CancelledCall_MapsToTimeout()
  {
    var cts = new CancellationTokenSource();
    await cts.CancelAsync();
    var client = CreateClient(_ => JsonScore(), out _);

    await Assert.ThrowsAsync<RiskShieldTimeoutException>(
      () => client.GetRiskScoreAsync(Request, "corr-1", cts.Token));
  }
}
