# AGENTS.md

Guidance for coding agents working in this repository.

## Project overview

- Dependency-free static site for [jakobferdinand.at](https://jakobferdinand.at); all sources live under `public/` (HTML, CSS, fonts, images).
- Deployed to Azure Static Web App `jakobferdinand` (RG-jakobferdinand, westeurope, Free SKU) by `.github/workflows/build-and-deploy.yml`, which uploads `public/` directly — there is no build step.

## Infrastructure as Code

- `infrastructure/`: Bicep templates that adopt the Azure estate in place (`main.bicep` declares the Static Web App `jakobferdinand` plus custom domain `jakobferdinand.at` and the resource-group cost budget `Jakobferdinand-Budget`). There are no secrets or app settings in this estate, hence no Key Vault.
- Changes to `infrastructure/**` deploy automatically through `.github/workflows/infra-deploy.yml`: PRs get a what-if preview comment, pushes to `main` apply (guarded against Delete/Replace changes).
- Validate locally before committing infra changes:
  - `az bicep build --file infrastructure/main.bicep`
  - `az deployment group what-if --resource-group RG-jakobferdinand --template-file infrastructure/main.bicep --parameters infrastructure/main.bicepparam`
- See `docs/plans/001-infrastructure-as-code.md` for the adoption plan and rollout notes.

## Coding style

- Two-space indentation in HTML/CSS/JSON files.
- Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, `chore:`).

## Environment & Configuration

- Never commit secrets; the site holds none today. If app settings become necessary later, follow the Key Vault pattern from the alpakasoelde repo instead of storing values in Bicep.
