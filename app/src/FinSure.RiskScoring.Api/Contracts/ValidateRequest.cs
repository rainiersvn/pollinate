using System.ComponentModel.DataAnnotations;

namespace FinSure.RiskScoring.Api.Contracts;

// Applicant details submitted for pre-approval risk validation.
public sealed class ValidateRequest
{
  [Required]
  [MaxLength(100)]
  public string FirstName { get; init; } = string.Empty;

  [Required]
  [MaxLength(100)]
  public string LastName { get; init; } = string.Empty;

  // South African identity number: exactly 13 digits. PII: never log the value.
  [Required]
  [RegularExpression(@"^\d{13}$", ErrorMessage = "IdNumber must be exactly 13 digits.")]
  public string IdNumber { get; init; } = string.Empty;
}
