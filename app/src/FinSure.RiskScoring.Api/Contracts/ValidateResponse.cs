namespace FinSure.RiskScoring.Api.Contracts;

// Vendor risk score returned to the caller.
public sealed record ValidateResponse(int RiskScore, string RiskLevel);
