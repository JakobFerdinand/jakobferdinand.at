# Pageview Sessions & Visitors Plan

## Goal

Upgrade the first-party pageview analytics so each beacon carries an anonymous
session ID, a persistent visitor ID and the navigation type (with reloads and
back-forwards counted but *marked* as such), while beacons are gated to the
production hostnames only and paths are normalized. All new fields stay
optional end-to-end, so every deploy step is independently safe and Table
Storage needs no migration (existing rows simply read back `null`).

Because the site's Datenschutzerklärung currently states that neither Local
Storage nor user IDs are used, updating that privacy statement is **mandatory**
and part of this plan.

## Current state (relevant facts)

| Fact | Value |
| ---- | ----- |
| Site type | Plain MPA — two HTML pages, full page loads only, no SPA routing and no view transitions; exactly one beacon fires per document `load` event, so there is no dedupe concern |
| Beacon snippet | Duplicated inline: `public/index.html:62-83` and `public/datenschutz.html:120-141`; payload `{ path, referrerHost, viewportWidth }` via `navigator.sendBeacon('/api/pageview', …)` |
| Write API | `POST /api/pageview`, `AuthorizationLevel.Anonymous` (`api/features/pageviews/PageView.cs:16-19`); hand-rolled validation returning `400` strings (`PageView.cs:61-84`); payload record `Payload(string? Path, string? ReferrerHost, int? ViewportWidth)` at `PageView.cs:53` |
| Entity | `api/shared/entities/PageViewEntity.cs` — `PartitionKey = "Pv|yyyy-MM-dd"`, `RowKey` = GUID (`PageView.cs:90-91`); `ReferrerHost` already nullable, `ViewportWidth` non-null defaulted to `0` on write (`PageView.cs:94`) |
| Read side | None — plan 002 explicitly decided write-only; stats are inspected ad hoc via Azure portal or `az storage table query`. New fields will be stored but surfaced nowhere until a read endpoint exists (out of scope) |
| Preview exposure | `.github/workflows/build-and-deploy.yml:7-8` triggers on `pull_request`, so every PR gets a `*.azurestaticapps.net` preview deployment where the beacon currently fires unconditionally |
| Privacy wording | `public/datenschutz.html:41-45` ("Keine Cookies & kein Local Storage"), `:54-57` (field list), `:59-61` ("keine Nutzer-IDs"), `:63-65` (opt-out rationale), `:89-92` ("keine Identifizierung einzelner Besucher möglich"), `:108-113` (dated statement, 23 August 2026) |
| Verify/build commands | `dotnet publish api/jakobferdinand-api.csproj -o dist-api` (workflow, `build-and-deploy.yml:30`); local site via `python3 -m http.server 8000 --directory public` (`README.md:16`); manual API checks via `api/requests.http`; no lint/test tooling exists |

Decisions made during planning (confirmed with repository owner):

- Extract the duplicated inline beacon into a shared `public/analytics.js`.
- Path normalization lives **server-side** in `PageView.Handler`.
- Strict validation for the new fields: UUID parse for IDs, closed enum for
  navigation type.

## 1. Shared client script (`public/analytics.js`, new)

New dependency-free script referenced by both pages, replacing the two inline
copies. Structure mirrors today's logic (guard, referrer parsing, payload,
`sendBeacon`), plus:

- **Production gating:** bail out early unless
  `location.hostname === 'jakobferdinand.at'`. The custom domain is the only
  production hostname (plan 001: no `www.` domain exists); this excludes
  `localhost`/`127.0.0.1`, the default
  `black-river-03b569003.5.azurestaticapps.net` hostname and all PR preview
  deployments under `*.azurestaticapps.net`. If a `www.` domain is ever added,
  extend this allowlist.
- **Session ID:** key `lt-session` in `sessionStorage` — generate
  `crypto.randomUUID()` when absent, reuse otherwise (new tab/window ⇒ new
  session).
- **Visitor ID:** key `lt-visitor` in `localStorage` — same generation pattern,
  persisted across sessions.
- Both reads/writes wrapped in `try/catch`; if storage is blocked (e.g. strict
  private mode) the respective field is omitted rather than failing the beacon.
- **Navigation type:** `performance.getEntriesByType('navigation')[0]?.type`;
  included only when it is `'navigate'`, `'reload'` or `'back_forward'`
  (anything else, e.g. prerender, or missing API support ⇒ field omitted).

Payload shape becomes `{ path, referrerHost, viewportWidth, sessionId?,
visitorId?, navigationType? }` — the three new keys are simply absent when
unavailable. Reloading the page or returning via history still sends a beacon;
it is merely *marked* via `navigationType`, never dropped.

Wiring edits (delete inline `<script>` blocks, add before `</body>`):

```html
<script src="/analytics.js" defer></script>
```

- `public/index.html:62-83` — remove inline block
- `public/datenschutz.html:120-141` — remove inline block

Two-space indentation per coding-style convention.

## 2. Write API (`api/features/pageviews/PageView.cs`, edit)

- **Payload record** (`PageView.cs:53`) gains three nullable members:
  `string? SessionId`, `string? VisitorId`, `string? NavigationType`.
  Old clients (cached HTML without the fields) deserialize to `null` — fully
  backward compatible; new client against old API sends extra fields that the
  old record ignores — forward compatible.
- **Validation** (`Handler.Validate`, `PageView.cs:61-84`) extends with:
  - `sessionId`/`visitorId`, when present, must parse via
    `Guid.TryParse` (any casing/format .NET accepts; store normalized
    `"D"`-format string) — else `400`.
  - `navigationType`, when present, must be exactly `"navigate"`,
    `"reload"` or `"back_forward"` — else `400`.
- **Path normalization** (server-side, in `Handler` before the length check):
  collapse trailing slashes (`"/about/"` → `"/about"`, `"/"` stays `"/"`),
  applied to the validated value before entity mapping. One place benefits any
  client, including manual `curl`/`requests.http` traffic.
- **Entity** (`api/shared/entities/PageViewEntity.cs`): add
  `string? SessionId`, `string? VisitorId`, `string? NavigationType` — all
  nullable so historical rows read back `null`. Unlike `ViewportWidth`
  (non-null with `?? 0` write default, `PageView.cs:94`), do **not** default
  these to sentinel values. Partition/RowKey scheme and the lazy 36-month
  cleanup (`PageView.cs:105-174`) are untouched.

No migration needed anywhere: Azure Table Storage is schemaless per property;
old entities simply lack the new properties.

## 3. Datenschutzerklärung (`public/datenschutz.html`, edit — mandatory)

The current wording becomes false the moment `analytics.js` ships; it must be
corrected in the same release (or deployed just before it):

- `:41-45` — replace the *"Diese Website verwendet keine Cookies und keinen
  Local Storage"* section: the site stores two random identifiers locally —
  `lt-visitor` (Local Storage, persistent) and `lt-session` (Session Storage,
  per browser session). Neither is a cookie, neither leaves the device except
  inside the statistics beacon, neither can be linked to a person.
- `:54-57` — extend the recorded-fields list: page path, referrer host, screen
  width **plus** random session ID, random visitor ID and navigation type
  (normal call / reload / back-forward), used solely to distinguish visits and
  count repeat loads.
- `:59-61` — drop the *"keine Nutzer-IDs"* claim; restate accurately: no IP
  addresses, no cookies, no user agent, no account data; the IDs are random
  UUIDs generated on the device with no connection to identity.
- `:63-65` — revisit the opt-out rationale: visitors can clear/delete the two
  storage entries at any time (browser setting), which ends recognition;
  keep or adjust the consent-free-processing statement accordingly.
- `:89-92` — soften *"keine Identifizierung einzelner Besucher möglich"*:
  recognizing the *same browser* across visits is now possible via
  `lt-visitor`; identifying a natural person remains impossible.
- `:108-113` — refresh the dated validity statement.

## Rollout order

Each step is safe to deploy alone; nothing depends on its predecessor being
live:

1. **Privacy page first** (step 3 above) — the disclosure must be true no later
   than the moment the new fields start flowing.
2. **API-only change** (step 2) — accepts the three optional fields; existing
   beacons unaffected, `204` behaviour unchanged.
3. **Client change** (step 1) — `analytics.js` with gating, IDs and navigation
   type replaces both inline snippets; works identically against the previous
   API (extra fields ignored) and the new one.

Steps 2+3 land in one PR since they share no risk boundary; step 1 may ride
along or precede it. Preview environments (`*.azurestaticapps.net` PR deploys)
stop beaconing as soon as step 3 ships — expected, not a regression.

## Milestones (tracked)

Checkboxes are updated as work progresses.

- [ ] Update `datenschutz.html` wording (storage, IDs, identification claims, date)
- [ ] Extend `PageView.Payload` + validation (UUID parse, enum) + entity nullable fields
- [ ] Server-side trailing-slash normalization in `Handler`
- [ ] Create `public/analytics.js` (gating, `lt-session`, `lt-visitor`, navigation type)
- [ ] Replace inline scripts in `index.html` and `datenschutz.html` with `analytics.js`
- [ ] Extend `api/requests.http` with valid/invalid examples for the new fields
- [ ] `dotnet publish api/jakobferdinand-api.csproj -o dist-api` passes
- [ ] Merge/deploy; verify checklist below in production

## Verification checklist

1. `dotnet publish api/jakobferdinand-api.csproj -o dist-api` succeeds (the
   only build gate; there is no lint/test tooling).
2. Via `api/requests.http` or curl against localhost:7071:
   - Old-shape payload `{path:"/",referrerHost:"g.at",viewportWidth:1920}` → `204`.
   - With `sessionId`/`visitorId` as GUIDs and `navigationType:"reload"` → `204`.
   - `navigationType:"unknown"`, non-GUID `visitorId`, `path:"about"` → `400`.
   - `path:"/about/"` stored as `/about` (check the written entity).
3. `az storage table query --account-name stjakobferdinand
   --table-name pageviews` — rows written after deploy carry the new
   properties; pre-existing rows read back without them (`null`).
4. Production (`https://jakobferdinand.at`, DevTools): request to
   `/analytics.js` fires one beacon per load; Application → Local/Session
   Storage shows `lt-visitor`/`lt-session`; reload marks `navigationType:"reload"`,
   history navigation marks `back_forward`; normal clicks mark `navigate`.
5. Gating: open `http://localhost:8000` (per `README.md:16`) and a PR preview
   URL — no `/api/pageview` request appears in DevTools.
6. `datenschutz.html` renders with corrected statements; no cookies are set
   (DevTools / `curl -v` response headers), only the two documented storage keys.
