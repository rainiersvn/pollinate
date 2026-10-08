using System.ComponentModel.DataAnnotations;
using FinSure.RiskScoring.Api.RiskShield;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace FinSure.RiskScoring.Api.Tests;

// Vendor TLS: BaseUrl must stay https; http fails startup validation.
public sealed class RiskShieldOptionsTests
{
  private static bool TryValidate(RiskShieldOptions options, out List<ValidationResult> results)
  {
    results = [];
    return Validator.TryValidateObject(
      options, new ValidationContext(options), results, validateAllProperties: true);
  }

  [Fact]
  public void Default_BaseUrl_IsHttps()
  {
    var options = new RiskShieldOptions { ApiKey = "test-key" };

    Assert.StartsWith("https://", options.BaseUrl, StringComparison.OrdinalIgnoreCase);
    Assert.True(TryValidate(options, out _));
  }

  [Fact]
  public void Http_BaseUrl_FailsValidation()
  {
    var options = new RiskShieldOptions
    {
      BaseUrl = "http://api.riskshield.com",
      ApiKey = "test-key",
    };

    var valid = TryValidate(options, out var results);

    Assert.False(valid);
    Assert.Contains(results, r => r.MemberNames.Contains(nameof(RiskShieldOptions.BaseUrl)));
  }

  [Fact]
  public void Https_BaseUrl_PassesValidation()
  {
    var options = new RiskShieldOptions
    {
      BaseUrl = "https://api.riskshield.com",
      ApiKey = "test-key",
    };

    Assert.True(TryValidate(options, out _));
  }

  [Fact]
  public void Startup_Registration_RejectsHttpBaseUrl()
  {
    var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
    {
      ["RiskShield:BaseUrl"] = "http://api.riskshield.com",
      ["RiskShield:ApiKey"] = "test-key",
    }).Build();

    var services = new ServiceCollection();
    services.AddSingleton<IConfiguration>(config);
    services.AddOptions<RiskShieldOptions>()
      .BindConfiguration(RiskShieldOptions.SectionName)
      .ValidateDataAnnotations()
      .Validate(
        o => Uri.TryCreate(o.BaseUrl, UriKind.Absolute, out var uri) &&
             string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase),
        "RiskShield:BaseUrl must be an absolute https:// URL.");

    using var provider = services.BuildServiceProvider();
    var options = provider.GetRequiredService<IOptions<RiskShieldOptions>>();

    Assert.Throws<OptionsValidationException>(() => _ = options.Value);
  }
}
