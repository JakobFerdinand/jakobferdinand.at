# jakobferdinand.at

[![build and deploy](https://github.com/JakobFerdinand/jakobferdinand.at/actions/workflows/build-and-deploy.yml/badge.svg)](https://github.com/JakobFerdinand/jakobferdinand.at/actions/workflows/build-and-deploy.yml)

Here is the sourcecode of my homepage [jakobferdinand.at](https://jakobferdinand.at).

## Development

Static site. Edit files under `public/` and push to `main`; Azure Static Web Apps deploys automatically.

## Local development

Serve the site over HTTP with Python's built-in server:

```bash
python3 -m http.server 8000 --directory public
```

Then open <http://localhost:8000>.

Refresh the browser after each save to see changes. Avoid opening `index.html` via `file://` — the font preload uses `crossorigin` and only behaves correctly over HTTP.

## Infrastructure

The Azure estate (Static Web App `jakobferdinand`, custom domain
`jakobferdinand.at`, cost budget) is managed with Bicep under `infrastructure/`
and adopted in place — see `docs/plans/001-infrastructure-as-code.md`.

Changes to `infrastructure/**` deploy automatically through
`.github/workflows/infra-deploy.yml`: pull requests get a what-if preview
comment; pushes to `main` apply the deployment (guarded against destructive
changes). Validate locally before committing infra changes:

```bash
az bicep build --file infrastructure/main.bicep
az deployment group what-if --resource-group RG-jakobferdinand \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/main.bicepparam
```
