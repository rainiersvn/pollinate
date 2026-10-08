# ck-labs_az_observability

Log Analytics workspace plus workspace-backed Application Insights for ck-labs.
The Container Apps environment forwards console logs to the workspace. The
Application Insights resource is provisioned but unwired: the API has no
exporter (no OpenTelemetry / Application Insights SDK, no connection string
passed via `env_vars`), and `FinSure.RiskScoring` / `riskscoring.validations`
is an in-process counter only. Telemetry is console logs — provisioned console-shipped by design within the current scope, no code change.

Trade-off: console logs keep the path simple with no SDK; Insights adds distributed tracing at the cost of SDK wiring and secret handling. One-var wiring path when needed: store the Insights connection string as a vault secret, map it via secret_env for the connection string, add the SDK exporter, no other infra reshaping. The root module already exposes the sensitive connection-string output for that wiring; env_vars carries no telemetry setting until that wiring is added.

## Files

| File                | Contents                                                   |
|---------------------|------------------------------------------------------------|
| `main.tf`           | `terraform` block (versions, `azurerm = 4.81.0`)            |
| `variables.tf`      | Location, resource group, `workspace` + `insights` objects, tags |
| `locals.tf`         | Workspace / Insights names, `common_tags`                  |
| `outputs.tf`        | Workspace id, Insights id, connection string (sensitive)   |
| `observability.tf`  | `azurerm_log_analytics_workspace` + `azurerm_application_insights` |
| `README.Resources.md` | Per-resource inventory                                   |

## Usage

```hcl
module "observability" {
  source              = "./modules/ck-labs_az_observability"
  location            = "southafricanorth"
  resource_group_name = "rg-ck-labs-dev"
  environment         = "dev"

  workspace = {
    retention_days = 30
  }
}
```
