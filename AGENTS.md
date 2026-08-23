# AGENTS.md

Guidance for coding agents working in this repository.

## Project overview

- Dependency-free static site for [jakobferdinand.at](https://jakobferdinand.at); all sources live under `public/` (HTML, CSS, fonts, images).
- Deployed to Azure Static Web App `jakobferdinand` (RG-jakobferdinand, westeurope, Free SKU) by `.github/workflows/build-and-deploy.yml`, which uploads `public/` directly — there is no site build step.
- `api/`: Azure Functions managed API (C# .NET isolated); serves the `POST /api/pageview` endpoint and writes page views to Azure Table Storage (account `stjakobferdinand`, table `pageviews`). See `docs/plans/002-website-analytics.md`.
- `public/staticwebapp.config.json` configures the managed-functions `apiRuntime` (`dotnet-isolated:9.0`) for the Static Web App.

## Infrastructure as Code

- `infrastructure/`: Bicep templates that adopt the Azure estate in place (`main.bicep` declares the Static Web App `jakobferdinand`, the storage account `stjakobferdinand`, custom domain `jakobferdinand.at` and the resource-group cost budget `Jakobferdinand-Budget`). The only secret-ish value, the storage connection string, is applied as the SWA app setting `StorageConnection` by the infra workflow — never committed, no Key Vault.
- Changes to `infrastructure/**` deploy automatically through `.github/workflows/infra-deploy.yml`: PRs get a what-if preview comment, pushes to `main` apply (guarded against Delete/Replace changes).
- Validate locally before committing infra changes:
  - `az bicep build --file infrastructure/main.bicep`
  - `az deployment group what-if --resource-group RG-jakobferdinand --template-file infrastructure/main.bicep --parameters infrastructure/main.bicepparam`
- See `docs/plans/001-infrastructure-as-code.md` for the adoption plan and rollout notes.

## Coding style

- Two-space indentation in HTML/CSS/JSON files.
- Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, `chore:`).

## Environment & Configuration

- Never commit secrets; there are none committed today. The SWA app setting `StorageConnection` (storage account connection string for the pageview API) is applied by the infra deploy workflow, not stored in the repo or Bicep.
