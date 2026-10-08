# E2E evidence (Phase 8, local — 2026-10-06)

All gates re-run after the Phase 7 doc pass and the two pipeline fixes
(`dotnetVersion` 9.0.x → 10.0.x to match the `net10.0` target; smoke
`/validate` payload corrected to the real `firstName/lastName/idNumber`
contract with 200-or-502 pass logic). Pollinate files are committed;
this batch is working tree only (see G9).

## Gate results

| # | Gate | Command | Result |
|---|---|---|---|
| G1 | terraform fmt (root) | `terraform fmt -check -recursive` in `terraform/` | exit 0 PASS |
| G2 | terraform fmt (bootstrap) | `terraform fmt -check` in `terraform/bootstrap/` | exit 0 PASS |
| G3 | terraform validate (root) | `terraform init -backend=false` + `terraform validate` | `Success! The configuration is valid.` PASS |
| G4 | terraform validate (bootstrap) | `terraform init -backend=false` + `terraform validate` | `Success! The configuration is valid.` PASS |
| G5 | dotnet test (full, Release, coverage gate) | `dotnet test FinSure.RiskScoring.slnx --configuration Release --collect:'XPlat Code Coverage'` in `app/` + line-rate >= 80% from `coverage.cobertura.xml` | `Failed: 0, Passed: 16, Skipped: 0, Total: 16`; line-rate 93.4% >= 80% PASS |
| G6 | YAML re-parse | `python -c "import yaml; yaml.safe_load(...azure-pipelines.yml)"` | OK, stages: Build, InfraDev, InfraProd, DeployDev, DeployProd, SmokeDev, SmokeProd PASS |
| G7 | Secret scan (repo-wide) | grep for `api-key/password/secret = "..."`, `BEGIN PRIVATE KEY`, storage `AccountKey` | Only `local-dummy-key` (README example) and `"secret-key"` (xUnit stub) — no real keys, no PII values in tfvars/pipeline PASS |
| G8 | docker build | `docker build -f Dockerfile -t finsure-risk-scoring:e2e .` (context `app/`) | export + `naming to finsure-risk-scoring:e2e done` PASS |
| G9 | git status | `git status --short` | Pollinate files committed (HEAD `80df616` + this batch uncommitted); untracked: brief `DVT/*.docx` (then untracked; moved with the solution to `Pollinate/*.docx`, now tracked) + new repo-root `README.md` (this batch) PASS |

Per-env note: `terraform validate` is backend-independent here (no remote-state
read at validate time), so root validate covers both `dev` and `prod`
configurations; env differences are tfvars-only (`lock_type`, names via
`environment`) and were diffed by inspection (7 lines each, no secrets).

## Runtime evidence (built image, `RiskShield__ApiKey=local-dummy-key`)

```
docker run -d --name finsure-e2e -p 18080:8080 -e RiskShield__ApiKey=local-dummy-key finsure-risk-scoring:e2e
docker exec finsure-e2e whoami                      # -> app
Invoke-RestMethod http://127.0.0.1:18080/health/live   # -> Healthy (200)
Invoke-RestMethod http://127.0.0.1:18080/health/ready  # -> Healthy (200)
POST /validate {"firstName":"Jane","lastName":"Doe","idNumber":"9001011234088"}
                                                    # -> 502 BadGateway
```

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| `whoami` in container | `app` (non-root, UID 1654) | `app` | PASS — `USER app` honored |
| `GET /health/live` | 200 Healthy | 200 Healthy | PASS — app healthy |
| `GET /health/ready` | 200 Healthy (dummy key resolves) | 200 Healthy | PASS — vendor-key wiring healthy |
| `POST /validate` (synthetic PII) | 502 (api.riskshield.com unreachable; wiring correct) | 502 BadGateway | PASS — expected vendor-unreachable mapping, not a wiring fault |
| PII in container logs | `idNumber` value never logged | `docker logs \| grep 9001011234088` → 0 matches | PASS — log redaction holds on the 502 path too |

Container removed after evidence (`docker rm -f finsure-e2e`). Image tag
`finsure-risk-scoring:e2e` is local-only evidence, not pushed.
