using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using FinSure.RiskScoring.Api.Contracts;
using Microsoft.Extensions.Options;

namespace FinSure.RiskScoring.Api.RiskShield;

public interface IRiskShieldClient
{
  Task<RiskScoreResult> GetRiskScoreAsync(ValidateRequest request, string correlationId, CancellationToken cancellationToken);
}

public sealed record RiskScoreResult(int RiskScore, string RiskLevel);

// Typed HttpClient. Resilience (timeout + retry + circuit breaker) is applied
// by AddStandardResilienceHandler at registration; this class only maps outcomes.
public sealed class RiskShieldClient(HttpClient http, IOptions<RiskShieldOptions> options, ILogger<RiskShieldClient> logger)
  : IRiskShieldClient
{
  public const string CorrelationHeader = "X-Correlation-ID";

  public async Task<RiskScoreResult> GetRiskScoreAsync(
    ValidateRequest request, string correlationId, CancellationToken cancellationToken)
  {
    using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "v1/score")
    {
      Content = JsonContent.Create(new
      {
        firstName = request.FirstName,
        lastName = request.LastName,
        idNumber = request.IdNumber,
      }),
    };
    httpRequest.Headers.Add("X-Api-Key", options.Value.ApiKey);
    httpRequest.Headers.Add(CorrelationHeader, correlationId);

    HttpResponseMessage response;
    try
    {
      response = await http.SendAsync(httpRequest, cancellationToken).ConfigureAwait(false);
    }
    catch (Exception ex) when (ex is TaskCanceledException or TimeoutException)
    {
      // PII-safe: log lengths and correlation only, never the id number.
      logger.LogWarning(ex, "RiskShield call timed out. CorrelationId: {CorrelationId}.", correlationId);
      throw new RiskShieldTimeoutException("RiskShield call timed out.", ex);
    }
    catch (HttpRequestException ex)
    {
      logger.LogWarning(ex, "RiskShield transport failure. CorrelationId: {CorrelationId}.", correlationId);
      throw new RiskShieldTransientException("RiskShield transport failure.", ex);
    }

    using (response)
    {
      if (response.IsSuccessStatusCode)
      {
        var body = await response.Content
          .ReadFromJsonAsync<VendorScoreResponse>(cancellationToken)
          .ConfigureAwait(false);
        if (body is null)
        {
          throw new RiskShieldTransientException("RiskShield returned an empty success body.");
        }
        return new RiskScoreResult(body.RiskScore, body.RiskLevel);
      }

      if ((int)response.StatusCode is >= 500 or 408 or 429)
      {
        logger.LogWarning(
          "RiskShield transient failure {StatusCode}. CorrelationId: {CorrelationId}.",
          (int)response.StatusCode, correlationId);
        throw new RiskShieldTransientException($"RiskShield transient failure {(int)response.StatusCode}.");
      }

      logger.LogWarning(
        "RiskShield rejected request {StatusCode}. CorrelationId: {CorrelationId}.",
        (int)response.StatusCode, correlationId);
      throw new RiskShieldRejectedException($"RiskShield rejected request {(int)response.StatusCode}.");
    }
  }

  private sealed record VendorScoreResponse(
    [property: JsonPropertyName("riskScore")] int RiskScore,
    [property: JsonPropertyName("riskLevel")] string RiskLevel);
}
