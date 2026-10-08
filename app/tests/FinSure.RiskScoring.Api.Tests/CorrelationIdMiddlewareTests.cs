using System.Net;
using System.Net.Http.Json;
using System.Text.RegularExpressions;
using FinSure.RiskScoring.Api.Middleware;
using FinSure.RiskScoring.Api.RiskShield;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace FinSure.RiskScoring.Api.Tests;

// Correlation cap: 128 chars + [A-Za-z0-9-] allowlist, truncate-or-mint.
public sealed class CorrelationIdMiddlewareTests
{
  private static readonly Regex Allowed = new("^[A-Za-z0-9-]+$", RegexOptions.Compiled);

  private static (WebApplicationFactory<Program> Factory, StubRiskShieldClient Stub)
    CreateFactory()
  {
    var stub = new StubRiskShieldClient();
    var factory = new WebApplicationFactory<Program>().WithWebHostBuilder(builder =>
    {
      builder.UseSetting("RiskShield:ApiKey", "test-key");
      builder.ConfigureTestServices(services =>
      {
        services.AddSingleton<IRiskShieldClient>(stub);
      });
    });
    return (factory, stub);
  }

  private static HttpContent ValidPayload() =>
    JsonContent.Create(new
    {
      firstName = "Jane",
      lastName = "Doe",
      idNumber = "9001011234088",
    });

  [Fact]
  public async Task Overlong_ValidId_IsTruncatedTo128()
  {
    var (factory, stub) = CreateFactory();
    using var client = factory.CreateClient();
    var overlong = new string('a', 200);
    using var request = new HttpRequestMessage(HttpMethod.Post, "/validate")
    {
      Content = ValidPayload(),
    };
    request.Headers.Add(CorrelationIdMiddleware.HeaderName, overlong);

    var response = await client.SendAsync(request);

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    var echoed = response.Headers.GetValues(CorrelationIdMiddleware.HeaderName).Single();
    Assert.Equal(128, echoed.Length);
    Assert.Equal(overlong.Substring(0, 128), echoed);
    Assert.Equal(echoed, stub.SeenCorrelationId);
  }

  [Fact]
  public async Task InvalidChars_AreMinted()
  {
    var (factory, stub) = CreateFactory();
    using var client = factory.CreateClient();
    using var request = new HttpRequestMessage(HttpMethod.Post, "/validate")
    {
      Content = ValidPayload(),
    };
    request.Headers.TryAddWithoutValidation(CorrelationIdMiddleware.HeaderName, "bad\ninjection\r\n<script>$x");

    var response = await client.SendAsync(request);

    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    var echoed = response.Headers.GetValues(CorrelationIdMiddleware.HeaderName).Single();
    Assert.NotEqual("bad\ninjection\r\n<script>$x", echoed);
    Assert.True(echoed.Length <= CorrelationIdMiddleware.MaxLength);
    Assert.Matches(Allowed, echoed);
    Assert.Equal(echoed, stub.SeenCorrelationId);
  }

  [Fact]
  public void Sanitize_TruncatesOrMints()
  {
    var truncated = CorrelationIdMiddleware.Sanitize(new string('b', 200));
    Assert.Equal(128, truncated.Length);
    Assert.Equal(new string('b', 128), truncated);

    var minted = CorrelationIdMiddleware.Sanitize("has space and $ymbol!");
    Assert.NotEqual("has space and $ymbol!", minted);
    Assert.True(minted.Length <= CorrelationIdMiddleware.MaxLength);
    Assert.Matches(Allowed, minted);

    var kept = CorrelationIdMiddleware.Sanitize("trace-123");
    Assert.Equal("trace-123", kept);
  }
}
