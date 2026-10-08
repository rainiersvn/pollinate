using System.ComponentModel.DataAnnotations;

namespace FinSure.RiskScoring.Api.RiskShield;

// Bound from configuration section "RiskShield".
// ApiKey arrives via environment (locally) or a Key Vault reference (Azure).
public sealed class RiskShieldOptions
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
}
