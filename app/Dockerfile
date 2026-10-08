# FinSure Vendor Payment Risk Scoring API — production image.
#
# Build context is app/ (the solution root):
#   docker build -t finsure-risk-scoring:local -f Dockerfile .
#
# Multi-stage: .NET 10 SDK compiles and publishes; the ASP.NET 10 runtime
# image serves. Only the published output ships — no SDK, source, or tests.

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first so the layer is cached unless manifests change.
COPY ["Directory.Packages.props", "./"]
COPY ["NuGet.config", "./"]
COPY ["FinSure.RiskScoring.slnx", "./"]
COPY ["src/FinSure.RiskScoring.Api/FinSure.RiskScoring.Api.csproj", "src/FinSure.RiskScoring.Api/"]
RUN dotnet restore "src/FinSure.RiskScoring.Api/FinSure.RiskScoring.Api.csproj"

# Tests run in CI before docker build; the image publishes Release only.
COPY . .
RUN dotnet publish "src/FinSure.RiskScoring.Api/FinSure.RiskScoring.Api.csproj" \
    -c Release -o /app/publish --no-restore \
    -p:ContinuousIntegrationBuild=true

FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS runtime
WORKDIR /app

ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true

EXPOSE 8080

# Non-root: official .NET 8+ images ship an unprivileged `app` user (UID 1654).
USER app
COPY --from=build --chown=app:app /app/publish .

# Container health mirrors the app liveness probe (busybox wget ships in alpine).
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/health/live > /dev/null || exit 1

ENTRYPOINT ["dotnet", "FinSure.RiskScoring.Api.dll"]
