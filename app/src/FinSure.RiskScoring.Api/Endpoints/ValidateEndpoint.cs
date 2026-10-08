using System.ComponentModel.DataAnnotations;
using FinSure.RiskScoring.Api.Contracts;
using FinSure.RiskScoring.Api.Middleware;
using FinSure.RiskScoring.Api.RiskShield;
using FinSure.RiskScoring.Api.Telemetry;

namespace FinSure.RiskScoring.Api.Endpoints;

public static class ValidateEndpoint
{
  public static void MapValidate(this WebApplication app)
  {
    app.MapPost("/validate", HandleAsync)
      .Produces<ValidateResponse>()
      .ProducesValidationProblem()
      .ProducesProblem(StatusCodes.Status502BadGateway)
      .ProducesProblem(StatusCodes.Status504GatewayTimeout);
  }

  private static async Task<IResult> HandleAsync(
    ValidateRequest? request,
    HttpContext context,
    IRiskShieldClient client,
    ILoggerFactory loggerFactory,
    CancellationToken cancellationToken)
  {
    var logger = loggerFactory.CreateLogger("ValidateEndpoint");

    if (request is null)
    {
      return Results.ValidationProblem(new Dictionary<string, string[]>
      {
        ["request"] = ["Request body is required."],
      });
    }

    var failures = new Dictionary<string, string[]>();
    foreach (var result in Validate(request))
    {
      var key = result.MemberNames.FirstOrDefault() ?? string.Empty;
      failures[key] = [result.ErrorMessage ?? "Invalid value."];
    }
    if (failures.Count > 0)
    {
      // PII-safe: invalid input is counted, never echoed with values.
      logger.LogInformation("Validation failed for {FieldCount} field(s).", failures.Count);
      RiskMeters.Validations.Add(1, new KeyValuePair<string, object?>("outcome", "validation-error"));
      return Results.ValidationProblem(failures);
    }

    var correlationId = context.Items.TryGetValue(CorrelationIdMiddleware.ItemKey, out var id)
      ? id?.ToString() ?? string.Empty
      : string.Empty;

    try
    {
      var score = await client
        .GetRiskScoreAsync(request, correlationId, cancellationToken)
        .ConfigureAwait(false);
      // PII-safe: log score metadata and id length only, never the id number.
      logger.LogInformation(
        "Validation succeeded. CorrelationId: {CorrelationId}. IdLength: {IdLength}.",
        correlationId, request.IdNumber.Length);
      RiskMeters.Validations.Add(1, new KeyValuePair<string, object?>("outcome", "success"));
      return Results.Ok(new ValidateResponse(score.RiskScore, score.RiskLevel));
    }
    catch (RiskShieldTimeoutException ex)
    {
      logger.LogWarning(ex, "Vendor timeout. CorrelationId: {CorrelationId}.", correlationId);
      RiskMeters.Validations.Add(1, new KeyValuePair<string, object?>("outcome", "timeout"));
      return Results.Problem("Risk vendor timed out.", statusCode: StatusCodes.Status504GatewayTimeout);
    }
    catch (Exception ex) when (ex is RiskShieldTransientException or RiskShieldRejectedException)
    {
      logger.LogWarning(ex, "Vendor failure. CorrelationId: {CorrelationId}.", correlationId);
      RiskMeters.Validations.Add(1, new KeyValuePair<string, object?>("outcome", "bad-gateway"));
      return Results.Problem("Risk vendor unavailable.", statusCode: StatusCodes.Status502BadGateway);
    }
  }

  private static IEnumerable<ValidationResult> Validate(ValidateRequest request)
  {
    var results = new List<ValidationResult>();
    Validator.TryValidateObject(request, new ValidationContext(request), results, validateAllProperties: true);
    return results;
  }
}
