using System.Net;
using System.Net.Http.Json;
using FinSure.RiskScoring.Api.Contracts;
using FinSure.RiskScoring.Api.RiskShield;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace FinSure.RiskScoring.Api.Tests;

// Endpoint contract: status codes, response shape, correlation, PII safety.
public sealed class ValidateEndpointTests
{
  private const string ProbeIdNumber = "9001011234088";

  private static (WebApplicationFactory<Program> Factory, StubRiskShieldClient Stub, CapturingLoggerProvider Logs)
    CreateFactory()
  {
    var stub = new StubRiskShieldClient();
    var logs = new CapturingLoggerProvider();
    var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
    {
      builder.UseSetting("RiskShield:ApiKey", "test-key");
      builder.ConfigureTestServices(services =>
      {
        services.AddSingleton<IRiskShieldClient>(stub);
        services.AddSingleton<ILoggerProvider>(logs);
      });
    });
    return (factory, stub, logs);
  }

  private static HttpContent ValidPayload(string idNumber = ProbeIdNumber) =>
    JsonContent.Create(new
    {
      firstName = "Jane",
      lastName = "Doe",
      idNumber,
    });

  [Fact]
  public async Task HappyPath_ReturnsRiskScore()
  {
    var (factory, _, _) = CreateFactory();
    using var client = factory.CreateClient();

    var response = await client.PostAsync("/validate", ValidPayload());

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    var body = await response.Content.ReadFromJsonAsync<ValidateResponse>();
    Assert.NotNull(body);
    Assert.Equal(72, body.RiskScore);
    Assert.Equal("MEDIUM", body.RiskLevel);
  }

  [Fact]
  public async Task MissingField_Returns400()
  {
    var (factory, _, _) = CreateFactory();
    using var client = factory.CreateClient();

    var response = await client.PostAsync("/validate",
      JsonContent.Create(new { firstName = "Jane", lastName = "Doe" }));

    Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
  }

  [Fact]
  public async Task MalformedIdNumber_Returns400()
  {
    var (factory, _, _) = CreateFactory();
    using var client = factory.CreateClient();

    var response = await client.PostAsync("/validate", ValidPayload("not-an-id"));

    Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
  }

  [Fact]
  public async Task VendorTransientFailure_Returns502()
  {
    var (factory, stub, _) = CreateFactory();
    stub.Behavior = (_, _) => throw new RiskShieldTransientException("vendor 500");
    using var client = factory.CreateClient();

    var response = await client.PostAsync("/validate", ValidPayload());

    Assert.Equal(HttpStatusCode.BadGateway, response.StatusCode);
  }

  [Fact]
  public async Task VendorRejection_Returns502()
  {
    var (factory, stub, _) = CreateFactory();
    stub.Behavior = (_, _) => throw new RiskShieldRejectedException("vendor 400");
    using var client = factory.CreateClient();

    var response = await client.PostAsync("/validate", ValidPayload());

    Assert.Equal(HttpStatusCode.BadGateway, response.StatusCode);
  }

  [Fact]
  public async Task VendorTimeout_Returns504()
  {
    var (factory, stub, _) = CreateFactory();
    stub.Behavior = (_, _) => throw new RiskShieldTimeoutException("timed out");
    using var client = factory.CreateClient();

    var response = await client.PostAsync("/validate", ValidPayload());

    Assert.Equal(HttpStatusCode.GatewayTimeout, response.StatusCode);
  }

  [Fact]
  public async Task CorrelationId_IsEchoedAndForwarded()
  {
    var (factory, stub, _) = CreateFactory();
    using var client = factory.CreateClient();
    using var request = new HttpRequestMessage(HttpMethod.Post, "/validate")
    {
      Content = ValidPayload(),
    };
    request.Headers.Add("X-Correlation-ID", "trace-123");

    var response = await client.SendAsync(request);

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    Assert.Equal("trace-123", response.Headers.GetValues("X-Correlation-ID").Single());
    Assert.Equal("trace-123", stub.SeenCorrelationId);
  }

  [Fact]
  public async Task CorrelationId_IsMintedWhenAbsent()
  {
    var (factory, stub, _) = CreateFactory();
    using var client = factory.CreateClient();

    var response = await client.PostAsync("/validate", ValidPayload());

    var echoed = response.Headers.GetValues("X-Correlation-ID").Single();
    Assert.False(string.IsNullOrWhiteSpace(echoed));
    Assert.Equal(echoed, stub.SeenCorrelationId);
  }

  [Fact]
  public async Task IdNumber_NeverReachesLogs()
  {
    var (factory, stub, logs) = CreateFactory();
    using var client = factory.CreateClient();

    await client.PostAsync("/validate", ValidPayload());
    await client.PostAsync("/validate", ValidPayload("not-an-id"));

    // Transient path: vendor 500 -> 502 still must not log the id number.
    stub.Behavior = (_, _) => throw new RiskShieldTransientException("vendor 500");
    await client.PostAsync("/validate", ValidPayload());

    // Timeout path: vendor timeout -> 504 still must not log the id number.
    stub.Behavior = (_, _) => throw new RiskShieldTimeoutException("timed out");
    await client.PostAsync("/validate", ValidPayload());

    Assert.DoesNotContain(logs.Messages, m => m.Contains(ProbeIdNumber));
  }

  [Fact]
  public async Task LiveEndpoint_Returns200()
  {
    var (factory, _, _) = CreateFactory();
    using var client = factory.CreateClient();

    var response = await client.GetAsync("/health/live");

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
  }

  [Fact]
  public async Task ReadyEndpoint_Returns200WhenConfigured()
  {
    var (factory, _, _) = CreateFactory();
    using var client = factory.CreateClient();

    var response = await client.GetAsync("/health/ready");

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
  }
}
