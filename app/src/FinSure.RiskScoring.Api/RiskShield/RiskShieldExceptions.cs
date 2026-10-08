namespace FinSure.RiskScoring.Api.RiskShield;

// Vendor returned 5xx, 408/429 after retries, or the transport failed. Maps to 502.
public sealed class RiskShieldTransientException(string message, Exception? inner = null)
  : Exception(message, inner);

// Vendor returned 4xx: caller error, retrying cannot help. Maps to 502 without retry.
public sealed class RiskShieldRejectedException(string message)
  : Exception(message);

// Vendor call exceeded the configured timeout. Maps to 504.
public sealed class RiskShieldTimeoutException(string message, Exception? inner = null)
  : Exception(message, inner);
