# Sports Store gateway - the single entrypoint for the whole application.
#
# SINGLE STAGE as of Milestone 5. The React bundle is no longer built here; it
# arrives as an image built and pushed by sports-store-frontend and named by
# FRONTEND_IMAGE.
#
# What this replaces: a two-stage build that ran `npm ci` and `npm run build`
# against the frontend repo's source, handed over as a BuildKit named build
# context (`--build-context frontend=../sports-store-frontend`). That required
# both repos checked out side by side on one disk - true on a developer's
# laptop, false in CI, where each repo builds alone with no sibling checkout.
# Moving the bundle into an image is what lets this repo build by itself.
#
# There is deliberately NO DEFAULT for FRONTEND_IMAGE. A default would have to
# name a moving tag, and this project never uses `latest` anywhere. Left unset
# the build fails immediately with
#     base name (${FRONTEND_IMAGE}) should not be blank
# which is the correct outcome: an unspecified frontend is a broken gateway,
# and it should be loud at build time rather than a stale bundle at runtime.
#
#   docker build \
#     --build-arg FRONTEND_IMAGE=<acct>.dkr.ecr.us-east-1.amazonaws.com/sports-store/frontend:0.1.0-<hash> \
#     -t <acct>.dkr.ecr.us-east-1.amazonaws.com/sports-store/gateway:0.1.0-<hash> .

ARG FRONTEND_IMAGE

# A named stage over an external image. Nothing in it is executed - it is a
# `scratch` image holding /dist and nothing else. Declared before the final
# FROM so BuildKit can resolve and pull it in parallel with the nginx base.
FROM ${FRONTEND_IMAGE} AS frontend

FROM nginx:1.27-alpine

# Re-declared on purpose: a global ARG declared before the first FROM is not in
# scope inside a build stage until it is restated.
ARG FRONTEND_IMAGE

# Recorded on the artifact rather than left implicit. This image's own tag
# carries the GATEWAY repo's commit hash, so without this label there is
# nothing on the image identifying which frontend build is baked into it.
#   docker inspect <image> --format '{{index .Config.Labels "io.cloudcart.frontend-image"}}'
LABEL org.opencontainers.image.title="sports-store-gateway" \
      io.cloudcart.frontend-image="${FRONTEND_IMAGE}"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY proxy_params.conf /etc/nginx/proxy_params.conf

# The only thing that crosses over from the frontend image. No Node, no
# node_modules, no sources - there is nothing else in it to cross over.
COPY --from=frontend /dist /usr/share/nginx/html

EXPOSE 80
