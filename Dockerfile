# Sports Store gateway - the single entrypoint for the whole application.
#
# Two stages: build the React bundle, then serve the static output with NGINX
# and reverse-proxy /api/* to the backend services.
#
# The frontend lives in its own repository, so this build needs a second
# source tree. Compose supplies it as a NAMED BUILD CONTEXT called `frontend`
# (see sports-store-local/docker-compose.yml). That keeps this Dockerfile
# referencing the frontend repo's own paths instead of hard-coding a
# "../sibling-directory" layout that only works on a developer's laptop.
#
# In CI each repo builds on its own, with no sibling checkout at all. There
# the frontend repo publishes its build output as its own image to ECR and
# the copy below becomes `COPY --from=<frontend-image> /dist ./`. Same
# mechanism, different source - which is why the named context is worth
# using now rather than a relative path.

# ---------------------------------------------------------------------
# Stage 1: build the React frontend
# ---------------------------------------------------------------------
FROM node:20-alpine AS frontend-build

WORKDIR /build

# Manifests first, so the slow dependency layer stays cached when only
# application source changes. `npm ci` - not `npm install` - installs exactly
# what the lockfile pins, which is what a reproducible build needs.
COPY --from=frontend package.json package-lock.json ./
RUN npm ci

COPY --from=frontend . .
RUN npm run build

# ---------------------------------------------------------------------
# Stage 2: serve with NGINX
# ---------------------------------------------------------------------
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY proxy_params.conf /etc/nginx/proxy_params.conf

# Only the built assets cross over from stage 1 - Node, node_modules and the
# frontend sources never reach the final image.
COPY --from=frontend-build /build/dist /usr/share/nginx/html

EXPOSE 80
