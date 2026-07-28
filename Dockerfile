# Build context is the project root (see docker-compose.yml) — this
# Dockerfile needs access to both frontend/ and gateway/.
#
# This image has two stages:
#   1. Build the React frontend into static files.
#   2. Serve those static files with NGINX, and proxy /api/* to the
#      backend services.

# ---------------------------------------------------------------------
# Stage 1: build the frontend
# ---------------------------------------------------------------------
# TODO: FROM a Node LTS image (e.g. node:20-alpine), and name this stage
#   so the next stage can copy from it (`AS frontend-build`).

# TODO: set a working directory.

# TODO: install dependencies.
#   - Copy frontend/package.json and frontend/package-lock.json first,
#     then run `npm ci` (not `npm install` — ci uses the lockfile exactly
#     and is meant for reproducible, automated builds).
#   - Copying only the manifest files first keeps this layer cached
#     separately from application source changes.

# TODO: copy the rest of frontend/ and run the production build
#   (`npm run build`). The build output goes to frontend/dist.

# ---------------------------------------------------------------------
# Stage 2: serve with NGINX
# ---------------------------------------------------------------------
# TODO: FROM an nginx image (e.g. nginx:1.27-alpine).

# TODO: copy gateway/nginx.conf into the image at
#   /etc/nginx/conf.d/default.conf

# TODO: copy gateway/proxy_params.conf into the image at
#   /etc/nginx/proxy_params.conf

# TODO: copy the built frontend from the frontend-build stage into
#   /usr/share/nginx/html
#   (use `COPY --from=frontend-build <src> <dest>`)

# TODO: document the port NGINX listens on (80).
