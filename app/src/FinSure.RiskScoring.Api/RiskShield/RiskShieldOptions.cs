using System.ComponentModel.DataAnnotations;

namespace FinSure.RiskScoring.Api.RiskShield;

// Bound from configuration section "RiskShield".
// ApiKey arrives via environment (locally) or a Key Vault reference (Azure).
// BaseUrl must stay https: startup validation fails fast on http.
public sealed class RiskShieldOptions : IValidatableObject
{
  public const string SectionName = "RiskShield";

  [Required]
  [Url]
  public string BaseUrl { get; set; } = "https://api.riskshield.com";

  [Required]
  public string ApiKey { get; set; } = string.Empty;

  [Range(1, 60)]
  public int TimeoutSeconds { get; set; } = 5;

  [Range(0, 5)]
  public int MaxRetries { get; set; } = 3;

  public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
  {
    if (!Uri.TryCreate(BaseUrl, UriKind.Absolute, out var uri) ||
        !string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase))
    {
      yield return new ValidationResult(
        "RiskShield:BaseUrl must be an absolute https:// URL.",
        [nameof(BaseUrl)]);
    }
  }
}
