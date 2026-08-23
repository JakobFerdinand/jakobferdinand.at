# Infrastructure as Code Plan

## Goal

Bring the Azure estate for jakobferdinand.at under Infrastructure as Code using
Bicep and auto-deploy infrastructure changes through GitHub Actions, following
the same pattern already established in the diermair.at repository (PR #156).
Only changes to `infrastructure/**` trigger the infra deployment; the existing
app build-and-deploy workflow (`build-and-deploy.yml`) stays untouched.

This estate is even simpler than diermair.at's: a single Static Web App with
one custom domain, no app settings, no APIs, no storage and no secrets. The
plan is therefore reduced accordingly — no Key Vault, no seed/sync scripts.

## Current Azure estate (resource group RG-jakobferdinand)

| Resource | Name | Notes |
| --- | --- | --- |
| Static Web App | `jakobferdinand` | Free SKU, westeurope; default hostname `black-river-03b569003.5.azurestaticapps.net`; GitHub integration for `JakobFerdinand/jakobferdinand.at`, branch `main`; app location `public`, no build step |
| Custom domain | `jakobferdinand.at` | Validated (`Ready`) since Jul 2024; **no** `www.` domain exists |

The resource group itself lives in `germanywestcentral`, while all resources
are in `westeurope`; deployments will use `westeurope` as deployment location.
No cost budget exists for this estate yet (unlike Alpakasoelde/Diermairat).

Deployment today happens via the custom workflow `.github/workflows/
build-and-deploy.yml`, which uploads `./public` directly using the
`AZURE_STATIC_WEB_APPS_API_TOKEN` secret. There is no IaC in the repo yet.

## Approach: adopt existing resources in place

Bicep declares the existing resources with their current names, resource group,
location and SKU, so the first deployment is an idempotent adopt with no
recreation or downtime. `az deployment group what-if` verifies this before
applying.

The custom domain (`jakobferdinand.at`) is the adoption hotspot: it is declared
as a `Microsoft.Web/staticSites/customDomains@2023-12-01` child resource, but
gated on a what-if review first — if what-if reports a destructive `Replace`
or `Delete`, it is left out of IaC initially and stays portal-managed (it is
already configured and validated).

## Milestones (tracked)

Checkboxes are updated as work progresses.

- [ ] Create git branch `feat/infrastructure-as-code`
- [x] Write infrastructure plan (`docs/plans/001-infrastructure-as-code.md`)
- [ ] Scaffold Bicep templates (`main.bicep`, optional `main-subscription.bicep`, modules, `*.bicepparam`, `bicepconfig.json`)
- [ ] Validate templates locally (`az bicep build` + `az deployment group what-if`)
- [ ] Write `.github/workflows/infra-deploy.yml` (what-if PR job + deploy on main)
- [ ] Manual: create service principal + OIDC federated credential scoped to RG-jakobferdinand, add GitHub secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`)
- [ ] First deploy: review what-if → apply → verify site stays live and the custom domain remains intact
- [ ] Optional: create subscription cost budget via `main-subscription.bicep`
- [ ] Update README (and add an AGENTS.md section) documenting the deployment commands
- [ ] Open pull request and merge to main

## 1. Bicep structure under `infrastructure/`

```
infrastructure/
  main.bicep              # RG-scoped orchestrator (targetScope = resourceGroup)
  main.bicepparam         # values: SWA name, location, custom domains
  main-subscription.bicep # subscription-scoped deployment (optional cost budget)
  main-subscription.bicepparam
  bicepconfig.json        # lint rules
  modules/
    static-sites.bicep    # SWA + custom domain (adopt in place)
    budget.bicep          # subscription cost budget + action group (new resource)
```

Details:

- `static-sites.bicep` declares the `jakobferdinand` Static Web App (Free SKU,
  westeurope, `allowConfigFileUpdates: true`) plus the single custom domain as
  a child resource.
- Unlike alpakasoelde/diermairat there are currently no storage or
  observability modules — those resources do not exist in this estate.
- There are no app settings to manage, so no Key Vault and no
  `seed-keyvault.sh` / `sync-swappsettings.sh` scripts are needed.
- The subscription-scoped budget template mirrors the diermairat pattern
  (`Jakobferdinand-Budget`, monthly grain, notifications at 20/80/100% via an
  action group). This creates a **new** budget — none exists today — and can
  be deferred or dropped if not wanted.

## 2. Secret management

Not applicable. The Static Web App has empty app settings and the site holds
no secrets (the existing `AZURE_STATIC_WEB_APPS_API_TOKEN` deploy secret is
managed by GitHub and not part of the Bicep estate). If app settings are
introduced later, adopt the alpakasoelde pattern: Key Vault + seed/sync
scripts + workflow-applied settings.

## 3. GitHub Actions – infra auto-deploy

New workflow `.github/workflows/infra-deploy.yml`:

- Triggers: push to `main` with paths `infrastructure/**` (plus the workflow
  file itself), and `pull_request` for a what-if preview job; both also support
  `workflow_dispatch`.
- Env: `RESOURCE_GROUP=RG-jakobferdinand`, `DEPLOYMENT_LOCATION=westeurope`.

Deploy identity (one-time setup):

- Create a service principal for this repo.
- Add an OIDC federated credential for `JakobFerdinand/jakobferdinand.at`.
- Grant Contributor on `RG-jakobferdinand` only (least privilege; add
  subscription scope only if the budget module is adopted).
- Store `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` in repo
  secrets (separate from the other repos' ones).

Jobs:

- **what-if** (pull requests): `azure/login@v2` (OIDC) → `az bicep build` →
  `az deployment group what-if` (+ subscription what-if if budget adopted) →
  post the diff as a PR comment (marker-based upsert), so infra PRs show their
  impact before merge.
- **deploy** (main): `azure/login@v2` → `az bicep build` → what-if guard that
  fails on any `Delete`/`Replace` change → `az deployment group create`;
  optionally `az deployment sub create` for the budget.

## 4. Rollout order (safe, no downtime)

1. One-time prep: create service principal + OIDC federated credential, add
   the three GitHub secrets.
2. Scaffold the Bicep templates; run `az bicep build` locally and then
   `az deployment group what-if --resource-group RG-jakobferdinand
   --template-file infrastructure/main.bicep --parameters
   infrastructure/main.bicepparam` to confirm zero destructive changes on the
   Static Web App and its custom domain (the adoption hotspot).
3. Commit the templates plus `infra-deploy.yml`; open a PR and check the
   posted what-if comment.
4. Merge; verify the deploy job succeeds and the site stays live at
   https://jakobferdinand.at with the custom domain still resolving.
5. Optionally deploy the subscription budget.
6. Update README with an "Infrastructure" section pointing at
   `infrastructure/` and the workflow behaviour.

## 5. Known limitations (kept manual, documented)

- Custom-domain DNS validation records cannot be managed by Bicep.
- The SWA↔GitHub connection (build/deploy integration) remains managed by the
  existing `build-and-deploy.yml` workflow; Bicep only declares the resource
  itself.

## Decisions

- Bicep with a single RG-scoped `main.bicep`; subscription-scoped
  `main-subscription.bicep` reserved for the optional cost budget.
- Adopt existing resources in place; no recreation, no downtime.
- No Key Vault: the estate has no secrets today.
- Existing app build-and-deploy workflow stays untouched; infra changes deploy
  through a separate path-filtered workflow.
- Pull requests: infra changes run a what-if job that posts the diff as a PR
  comment; deploys refuse destructive changes via a what-if guard.
