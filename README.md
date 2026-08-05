# sports-store-gateway

NGINX gateway — single entrypoint for the app

Part of the [CloudCart](https://github.com/pyly-devops) polyrepo — see [sports-store-deployments](https://github.com/pyly-devops/sports-store-deployments) for how this service fits into the overall system.

## Branching

- `feature/*` — new work
- `bugfix/*` — non-urgent fixes
- `hotfix/*` — urgent production fixes

`main` is protected: all changes land via pull request with at least one approval.

## Building: `FRONTEND_IMAGE` is required

This image serves the React bundle produced by
[sports-store-frontend](https://github.com/pyly-devops/sports-store-frontend)
and reverse-proxies `/api/*` to the backend services. It does **not** build that
bundle — the frontend repo publishes it as its own `scratch` image containing
only `/dist`, and this build copies it in:

```dockerfile
ARG FRONTEND_IMAGE
FROM ${FRONTEND_IMAGE} AS frontend
...
COPY --from=frontend /dist /usr/share/nginx/html
```

So a build needs the argument, and there is no default:

```bash
docker build --build-arg FRONTEND_IMAGE=sports-store/frontend:0.1.0-393a356 -t gateway .
```

Omit it and the build fails immediately with
`base name (${FRONTEND_IMAGE}) should not be blank`. That is deliberate. A
default would have to be a moving tag, and this project never uses `latest`
anywhere — an unspecified frontend should be a loud build failure, not a stale
bundle discovered at runtime.

Which frontend went into a given gateway image is recorded on the image itself,
since the gateway's own tag carries the *gateway* repo's commit hash:

```bash
docker inspect <image> --format '{{index .Config.Labels "io.cloudcart.frontend-image"}}'
```

**Why not build the bundle here.** It used to. The frontend source was handed
over as a BuildKit named build context
(`--build-context frontend=../sports-store-frontend`), which requires both
repos checked out side by side on one disk. That is true on a laptop and false
in CI, where each repo builds alone. The image-based hand-off is the same
mechanism with a source that actually exists everywhere.

**One consequence worth knowing.** The gateway's tag does not change when only
the frontend changes, because this repo's commit hash has not moved — and ECR
tags are immutable, so the re-push is rejected. The fix is to bump the `<semver>`
half of the tag: that degree of freedom is why the tag format has one.

## Development

<!-- TODO: local setup, env vars, how to run tests -->

For the full stack locally, use
[sports-store-local](https://github.com/pyly-devops/sports-store-local), which
builds the frontend image first and passes it to this one.

## CI/CD

<!-- TODO: what the GitHub Actions workflow does on PR vs. push to main -->

Images are tagged `<semver>-<7-char-git-hash>` and pushed to the
`sports-store/gateway` ECR repository.
