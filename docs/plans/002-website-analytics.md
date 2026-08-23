# Website Analytics Plan

## Goal

Track basic website usage (page views) for jakobferdinand.at in a cookie-free,
first-party, privacy-friendly way: the site beacons a small JSON payload to an
HTTP endpoint on the Static Web App, which writes one row per page view into
Azure Table Storage. No cookies, no third-party SDKs, no IP addresses.

## Current state (relevant facts)

| Fact | Value |
| ---- | ----- |
| Static Web App | `jakobferdinand` (Free SKU, westeurope, RG-jakobferdinand) |
| Site sources | Plain HTML/CSS in `public/`; **no build step** — `.github/workflows/build-and-deploy.yml` uploads `public/` directly (`app_location: "public"`) |
| Managed functions | None today; `api_location` is unset in the deploy workflow |
| `staticwebapp.config.json` | Does not exist yet — must be created in `public/` |
| Privacy policy | No Datenschutzerklärung exists yet — must be created |

## What is needed (inventory)

| Component | New? | Notes |
| --------- | ---- | ----- |
| Storage account (Azure Table Storage) | **New** | Stores the `pageviews` table; only new Azure resource |
| Function hosting | **No new resource** | Hosted by the Static Web App itself as *managed functions* (consumption plan, HTTP-only triggers) — no separate Function App resource, no extra cost |
| Function code (`api/` in this repo) | **New** | C# .NET isolated, HTTP trigger `POST /api/pageview`, writes to Table Storage |
| Beacon script in `public/index.html` | **New** | `navigator.sendBeacon` on window load |
| SWA app setting `StorageConnection` | **New** | Storage connection string; set via workflow, not committed |
| `public/staticwebapp.config.json` | **New file** | Declares the managed-functions `apiRuntime` (`dotnet-isolated:9.0`) |
| Build-and-deploy workflow (`build-and-deploy.yml`) | **Edit** | Build and publish the API, pass `api_location` |
| Infra workflow (`infra-deploy.yml`) | **Edit** | Set the `StorageConnection` app setting after each infra deploy |
| `.gitignore` / `.github/dependabot.yml` | **Edit** | Ignore API build artifacts; add nuget ecosystem |
| Datenschutzerklärung (`public/datenschutz.html`) | **New** | German-language disclosure of the pseudonymous visit statistics, linked from `index.html` |

No Key Vault is introduced; the storage key is fetched in the infra deploy
workflow and never enters the repository. Application Insights is optional and
not required.

## Decisions

- **Managed functions instead of a separate Function App.** The API runs inside
  the existing Static Web App (`jakobferdinand`, Free SKU, `westeurope`). The
  Free plan includes enough function executions for this traffic volume.
  Consequence: only HTTP triggers are supported — retention cleanup must run
  lazily inside the write path, not on a timer.
- **Write-only tracking for now.** No read endpoint, no dashboard, no stats
  page. Data is inspected ad hoc via Azure portal or `az storage table query`.
  A protected read endpoint can be added later without changing the write path.
- **Cookie-free and first-party.** No cookies, no localStorage, no SDKs. The
  beacon goes to the same origin (`/api/pageview`), so no CORS is needed.
- **Privacy by design (DSGVO, Art. 6 lit. f).** Store no IP address, no user
  agent, no user ID, no full referrer URL. Only: path, referrer *host* (origin
  only), and viewport width. Disclose the tracking on a new German
  Datenschutzerklärung.
- **Anonymous write endpoint.** `AuthorizationLevel.Anonymous` — it must be
  callable by any visitor without credentials.
- **Table auto-created by the function** (`CreateIfNotExistsAsync`), not
  declared in Bicep.
- **Retention: 36 months**, enforced via a lazy purge in the write path (see
  below).
- **Workflow-applied app setting instead of Bicep-declared.** The ARM schema
  `Microsoft.Web/staticSites/config` supports app settings, but declaring the
  connection string in Bicep would materialize the key via `listKeys(...)` into
  what-if output and deployment history (readable by anyone with Reader on the
  resource group) and would be drift-prone. A workflow step with `--output none`
  keeps the key out of logs and out of the repository.

## 1. Azure resources (Bicep)

### New storage module

Add `infrastructure/modules/storage.bicep` and wire it into `main.bicep`:

- **Storage account** `stjakobferdinand` — `Standard_LRS`, `StorageV2`, Hot
  tier, `westeurope`, HTTPS-only, TLS 1.2 minimum. Global name must stay unique
  (3–24 chars, lowercase).
- No tables declared in Bicep; the function creates `pageviews` itself.
- **Cost:** negligible (few MB of rows; LRS transaction prices at this volume).

`main.bicep` gains a `storageAccountName` param and a `storage` module;
`main.bicepparam` gains the storage account name param. The existing what-if
guard in `infra-deploy.yml` stays valid: a new storage account is a `Create`,
not a destructive change. The existing OIDC service principal (Contributor on
RG-jakobferdinand) already covers the new resource — no new identity needed.

### SWA app setting

After every infra deployment, the workflow fetches the account key and sets the
connection string on the SWA:

```bash
KEY=$(az storage account keys list --resource-group RG-jakobferdinand \
  --account-name stjakobferdinand --query "[0].value" -o tsv)
az staticwebapp appsettings set --name jakobferdinand \
  --resource-group RG-jakobferdinand \
  --setting-names "StorageConnection=DefaultEndpointsProtocol=https;AccountName=stjakobferdinand;AccountKey=$KEY;EndpointSuffix=core.windows.net" \
  --output none
```

The function reads `StorageConnection` from its environment (SWA app settings
become env vars; the name does not collide with the reserved `AzureWeb*`,
`WEBSITE*`, … prefixes). Wrap the key fetch in `::group::`/`::endgroup::` and
use `--output none` so the key never appears in pipeline logs.

## 2. Function code (`api/`)

New `api/` directory in the repo, C# .NET isolated, namespace
`JakobFerdinand.Api`:

- `api/jakobferdinand-api.csproj` — net9.0 (`dotnet-isolated:9.0` is currently
  the newest .NET runtime supported by SWA managed functions), packages
  `Microsoft.Azure.Functions.Worker`, `Microsoft.Azure.Functions.Worker.Extensions.Http`,
  `Microsoft.Azure.Functions.Worker.Sdk`, `Azure.Data.Tables`.
- `api/Program.cs` — reads `StorageConnection` (throw if unset), registers a
  singleton `TableServiceClient` and the page-view handler/store.
- `api/features/pageviews/PageView.cs` —
  - `[Function("pageview")]`, `[HttpTrigger(AuthorizationLevel.Anonymous, "post")]`
    → route `/api/pageview`.
  - Payload: `{ path, referrerHost, viewportWidth }`.
  - Validation: `path` required, starts with `/`, max 200 chars; `referrerHost`
    max 200 chars; `viewportWidth` 0–10000. Invalid JSON → 400, validation
    failure → 400 with detail, success → `204 No Content`.
  - Writes a `PageViewEntity`: `PartitionKey = "Pv|{yyyy-MM-dd}"` (daily
    partitions), `RowKey = Guid`, fields `Path`, `ReferrerHost`,
    `ViewportWidth`; storage sets `Timestamp`. No requester data is derived
    server-side.
  - **Retention:** on write, if the last cleanup marker (`Cleanup`/`last`
    entity) is older than one day, delete all partitions older than 36 months
    in 100-row transaction batches. Cleanup failures are logged and swallowed
    (fail-open — tracking must never break because of purge errors).
- `api/shared/EnvironmentVariables.cs`, `api/shared/entities/PageViewEntity.cs`.
- `api/requests.http` for manual endpoint testing.

### Runtime declaration

Create `public/staticwebapp.config.json` (picked up from the upload root since
there is no build step):

```json
{
  "platform": {
    "apiRuntime": "dotnet-isolated:9.0"
  }
}
```

No `responseOverrides` for now — the site has no dedicated 404 page. If SWA
adds a newer managed-functions runtime later, bump both `apiRuntime` here and
`<TargetFramework>` in the csproj together.

## 3. Client beacon (`public/index.html`)

Inline script at the end of `<body>` (before `</body>`):

- Fire once on `window` `load`, guarded by `'sendBeacon' in navigator`.
- `navigator.sendBeacon('/api/pageview', new Blob([JSON.stringify(payload)], { type: 'application/json' }))`
  — fire-and-forget, survives page unload.
- Payload: `path: location.pathname`, `referrerHost` = host of
  `document.referrer` (never the full URL; empty string if none),
  `viewportWidth: screen.width`.

Two-space indentation per the coding-style convention.

## 4. Deployment workflows

### Build-and-deploy (`build-and-deploy.yml`)

1. New steps before `Azure/static-web-apps-deploy@v1`: setup .NET 9 SDK
   (`actions/setup-dotnet@v4`, `dotnet-version: 9.0.x`), then
   `dotnet publish api/jakobferdinand-api.csproj -o dist-api` (API output
   outside the static app content).
2. In the `static-web-apps-deploy` step: keep `app_location: "public"` and
   `output_location: ""`, change `api_location` to `"dist-api"` and add
   `skip_api_build: true`. Token and PR-close job stay unchanged.

Local development: run the function directly with a local `StorageConnection`;
keep `requests.http` for manual endpoint testing.

### Infra deploy (`infra-deploy.yml`)

New final step in the `deploy` job (after *Deploy resource group resources*):
fetch the storage account key and set the `StorageConnection` app setting as
shown above. The PR what-if job needs no change.

## 5. Datenschutzerklärung (`public/datenschutz.html`)

New German-language page, styled like `index.html` (same header/nav/footer,
`style.css`), linked from the navigation. Sections:

- **Verantwortlicher**: Jakob Ferdinand Wegenschimmel, contact e-mail.
- **Keine Cookies & kein Local Storage**: no cookies/localStorage, no
  third-party tracking tools.
- **Pseudonyme Besuchsstatistik**: legal basis Art. 6 Abs. 1 lit. f DSGVO
  (berechtigtes Interesse); recorded fields are exclusively page path, referrer
  host (domain only, never the full URL) and screen width; no cookies, no IP
  addresses, no user IDs, no user agent; identification of individual visitors
  is not possible; stored in Azure Table Storage in the EU (westeurope),
  automatic deletion after 36 months; pseudonymous, consent-free data → no
  opt-out required.
- **Server- und Logdaten**: beyond the statistics above, the operator raises no
  server logs or access protocols.
- **Hosting**: Azure Static Web Apps, EU (westeurope).
- **Weitergabe von Daten**: none to third parties apart from hosting/statistics
  storage at Microsoft Azure (westeurope).
- **Betroffenenrechte**: Auskunft, Berichtigung, Löschung, Einschränkung,
  Widerspruch, Datenübertragbarkeit, Beschwerderecht bei der Aufsichtsbehörde.
- **Änderungen dieser Datenschutzerklärung**: dated statement.

## 6. Repository hygiene

- `.gitignore`: add `dist-api/`, `bin/`, `obj/`, `*.user`, and
  `api/local.settings.json` (may contain secrets locally).
- `.github/dependabot.yml`: add a second entry — `package-ecosystem: "nuget"`,
  `directory: "/api"`, weekly Monday 06:00 Europe/Vienna, grouped as
  `nuget-all` (matching the existing github-actions entry's style).
- `AGENTS.md`: document the new `api/` directory, the managed-functions runtime
  in `staticwebapp.config.json`, and that `StorageConnection` is applied by the
  infra workflow rather than committed or declared in Bicep.

## Milestones (tracked)

Checkboxes are updated as work progresses.

- [x] Decide final storage account name (`stjakobferdinand`) and retention (36 months)
- [x] Add `storage.bicep` module + `main.bicep` wiring; validate with `az bicep build` + `az deployment group what-if` (expect only `Create`)
- [x] Extend `infra-deploy.yml` deploy job to set the `StorageConnection` app setting
- [x] Scaffold `api/` (csproj, Program.cs, pageview feature, requests.http); verify `dotnet publish`
- [x] Add beacon script to `index.html`; create `staticwebapp.config.json` (`apiRuntime`)
- [x] Update `build-and-deploy.yml` (dotnet publish + `api_location`)
- [x] Create `datenschutz.html` (German, pseudonymous statistics section) and link it
- [x] Ignore API build artifacts; add nuget dependabot updates
- [x] Update `AGENTS.md` (new `api/` dir, app setting note)
- [x] Merge; deploy infrastructure; verify storage account exists
- [x] Deploy app; verify: beacon fires, 204 returned, rows appear in the
      `pageviews` table (`az storage table query`)

## Verification checklist

1. `curl -i -X POST https://jakobferdinand.at/api/pageview -H "Content-Type: application/json" -d '{"path":"/","referrerHost":"google.at","viewportWidth":1920}'`
   → `204`.
2. Invalid payloads (`{}`, path without `/`) → `400`.
3. `az storage table query --account-name stjakobferdinand --table-name pageviews`
   shows one entity per request with today's `Pv|yyyy-MM-dd` partition.
4. Datenschutzerklärung renders in site styling and is reachable from the
   navigation; no cookies are set (check DevTools / `curl -v` response headers).
