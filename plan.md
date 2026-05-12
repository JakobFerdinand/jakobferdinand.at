# Plan: Drop Astro, ship plain HTML/CSS

Goal: deliver the exact same site (`https://jakobferdinand.at`) as a single
static `index.html` + `style.css`, with **zero npm dependencies**, no build
step, no Node requirement, and therefore no Dependabot PRs.

---

## Why

The site is one static page (`src/pages/index.astro`) with no JS, no
collections, no markdown, no image pipeline. Astro pulls in ~200 transitive
packages (vite, rollup, postcss, h3, svgo, …) which is the source of the
constant Dependabot churn. None of Astro's features are actually used.

Outcome after this plan:

- `package.json`, `package-lock.json`, `node_modules/`, `astro.config.mjs`,
  `tsconfig.json`, `src/`, `.astro/`, `dist/` all gone.
- Repo contains: `index.html`, `style.css`, `fonts/`, `images/`, favicons,
  `license`, `README.md`, `.github/`, `.gitignore`.
- Dependabot npm ecosystem disabled (no manifest left to scan).
- Deployment continues to use the existing Azure Static Web Apps workflow,
  but without the Node/install/build steps.

---

## Pre-flight decisions (locked in)

1. **Font**: self-host **Source Code Pro** as a single woff2 file under
   `/fonts/`. Keep the visual design; eliminate the Google Fonts request.
   - Subset: Latin only.
   - Weights: 400 (regular) and 600 (semibold). The current CSS also lists
     300 but it is never actually applied (no element uses `font-weight:
     300`); skip it to keep payload small.
   - Source: download from
     https://fonts.google.com/specimen/Source+Code+Pro (or use
     google-webfonts-helper) and save as e.g.
     `fonts/source-code-pro-latin-400.woff2` and
     `fonts/source-code-pro-latin-600.woff2`.
   - Declare with `@font-face` in `style.css` using
     `font-display: swap` and `unicode-range: U+0000-00FF, U+0131,
     U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F,
     U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF,
     U+FFFD;` (standard Google "latin" subset range).
   - Add `<link rel="preload" as="font" type="font/woff2" crossorigin>` for
     the 400-weight file in `<head>` so first paint is not delayed.
2. **Portrait image**: download
   `https://avatars1.githubusercontent.com/u/16666458?s=460&v=4` once and
   save as `images/portrait.jpg`. Reference it locally from `index.html`.
3. **Hosting**: **Azure Static Web Apps**, deployed via
   `.github/workflows/build-and-deploy.yml` using
   `Azure/static-web-apps-deploy@v1`. Strategy: keep the workflow file,
   delete the Node/install/build steps, and change `output_location` so the
   action uploads the repo root instead of `dist/`. See step 3 for the
   exact diff.

---

## Step-by-step

### 1. Create the new static site at the repo root

- Create `index.html` containing the merged output of `MainLayout.astro` +
  `index.astro`. Inline the `<head>`:
  - `<meta charset>`, `<meta viewport>`, `<meta name="description">`
  - `<title>Jakob Ferdinand Wegenschimmel</title>`
  - Favicons + `site.webmanifest` links (root-relative paths)
  - `<link rel="preload" as="font" type="font/woff2"
    href="/fonts/source-code-pro-latin-400.woff2" crossorigin>`
  - `<link rel="stylesheet" href="/style.css">`
  - **No** `fonts.googleapis.com` / `fonts.gstatic.com` links.
- Create `style.css` containing only the rules actually used by the page:
  `:root`, `*`, `body`, `a`, `a:hover`, `.page`, `.site-header`,
  `.site-header a`, `.brand`, `.nav-links`, `.site-main`, `.main-content`
  (+ `@media (max-width: 768px)`), `.site-footer`, `.site-footer a`,
  `img`, `.home-wrapper`, `.home`, `.home .intro-text`,
  `.home .intro-text p`, `.home .portrait`
  (+ `@media (max-width: 640px)`), `.home h2`, `.home p`.
  Drop all `.blog-*`, `.post-*`, `.markdown*` rules (currently dead code).
  Prepend the two `@font-face` declarations for Source Code Pro 400/600.
  Keep `"Source Code Pro"` at the front of the `font-family` stack.
- Create `fonts/` and place the two woff2 files inside.
- Move `public/images/*` to `./images/` and the favicons / webmanifest
  (`favicon.ico`, `favicon-16x16.png`, `favicon-32x32.png`,
  `apple-touch-icon.png`, `android-chrome-192x192.png`,
  `android-chrome-512x512.png`, `site.webmanifest`) to the repo root.
  Update paths in `index.html` accordingly (use root-relative `/...`).
- Save the portrait locally as `images/portrait.jpg` and update the
  `<img src>` in `index.html`.

### 2. Verify locally

- Serve the folder with `python -m http.server` (a static server is needed
  for the font preload + `crossorigin` to behave correctly; `file://` will
  give misleading results for fonts).
- Spot-check: layout, link colours, hover, mobile breakpoints (≤640 px and
  ≤768 px), favicon in the tab, font actually loads (DevTools → Network →
  Font filter shows your woff2 served from `/fonts/`, no requests to
  `fonts.gstatic.com`).
- Confirm there are **no** third-party network requests on the page.
- Validate the HTML at https://validator.w3.org/.

### 3. Update the deploy workflow

Edit `.github/workflows/build-and-deploy.yml`:

- Delete the steps:
  - `Set up Node.js` (lines 23-27)
  - `Install dependencies` (lines 29-30)
  - `npm run build` (lines 32-33)
- In the `Build And Deploy` step, change:
  - `app_location: "/"` → keep as is.
  - `output_location: "dist"` → `output_location: ""` (Azure SWA then
    publishes `app_location` directly with no build artifact folder).
- Leave the `close_pull_request_job` untouched.
- Result: workflow checkout → deploy. No Node, no npm.

### 4. Remove Astro and all build tooling

Delete:

- `package.json`
- `package-lock.json`
- `node_modules/`
- `astro.config.mjs`
- `tsconfig.json`
- `src/` (entire folder, including `content.config.ts`, `env.d.ts`,
  `layouts/`, `pages/`, `styles/`)
- `.astro/`
- `dist/`
- `public/` (after its contents have been moved in step 1)
- `.nvmrc` (no Node needed anymore)
- `.devcontainer/` if its only purpose was Node-based development; review
  first and keep if it serves another purpose.

### 5. Update Dependabot config

Edit `.github/dependabot.yml`:

- Remove the `npm` ecosystem block entirely (no `package.json` to scan).
- Keep `github-actions` and `devcontainers` blocks (still useful, low
  noise — already grouped weekly).

### 6. Update README

Replace the Astro/dev-server instructions with a one-liner:
"Static site. Edit `index.html` / `style.css` and push to `main`; Azure
Static Web Apps deploys automatically."

### 7. Commit, push, verify deploy

- One commit (or a small series) with a clear message, e.g.
  `chore: replace Astro with static HTML/CSS`.
- Watch the GitHub Actions run (the deploy job should be much faster
  without the Node/build steps).
- Visit https://jakobferdinand.at and confirm visual parity and that the
  font is being served from your domain (DevTools → Network).

---

## File changes summary

| Action | Path |
|---|---|
| Add | `index.html` |
| Add | `style.css` |
| Add | `fonts/source-code-pro-latin-400.woff2` |
| Add | `fonts/source-code-pro-latin-600.woff2` |
| Add | `images/portrait.jpg` |
| Move | `public/images/*` → `images/` |
| Move | `public/{favicon*,android-chrome*,apple-touch-icon*,site.webmanifest}` → repo root |
| Edit | `.github/workflows/build-and-deploy.yml` (drop Node/build, set `output_location: ""`) |
| Edit | `.github/dependabot.yml` (remove npm ecosystem) |
| Edit | `README.md` |
| Delete | `package.json`, `package-lock.json`, `astro.config.mjs`, `tsconfig.json`, `.nvmrc` |
| Delete | `src/`, `.astro/`, `dist/`, `node_modules/`, `public/` (after move) |

---

## Risks & mitigations

- **Azure SWA picks up something unexpected at the repo root** → SWA with
  no `output_location` simply uploads everything in `app_location`. To
  avoid shipping junk, ensure `.gitignore` excludes editor / OS files and
  that the only top-level files in the repo are those listed in the
  outcome section. Optionally add a `staticwebapp.config.json` later if
  routing rules become necessary.
- **Font flash / FOUT** → mitigated by preloading the 400-weight file and
  using `font-display: swap`. The fallback stack already contains
  monospace system fonts so the swap is visually close.
- **Broken asset paths** → use root-relative paths (`/images/...`,
  `/fonts/...`, `/favicon.ico`) in `index.html` and verify with the
  browser dev tools' Network tab before pushing.
- **Lost portrait if GitHub avatar changes later** → that's actually a
  feature; the local copy is now under your control.
- **Future blog plans** → if a blog is on the roadmap, reconsider this
  plan. For a single static page it is clearly the right call; for a
  multi-page site with markdown content, Astro earns its keep.

---

## Definition of done

- `https://jakobferdinand.at` renders the same content and layout as today.
- The Source Code Pro font is served from `jakobferdinand.at/fonts/...`,
  not from Google.
- No third-party network requests on page load (check dev tools Network
  tab).
- Repo has no `package.json`, no `node_modules`, no Astro.
- `.github/dependabot.yml` no longer lists the npm ecosystem.
- The Azure Static Web Apps deploy workflow runs successfully without any
  Node setup or `npm` invocation.
- No Dependabot PRs for npm packages appear in the following weeks.
