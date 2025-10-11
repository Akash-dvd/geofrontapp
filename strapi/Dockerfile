# Builder stage: install deps and build admin
FROM node:22-bullseye AS builder

# set working dir
WORKDIR /srv/app

# install system build deps needed for native modules
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential python3 pkg-config git ca-certificates libvips-dev && \
    rm -rf /var/lib/apt/lists/*

# copy package manifest first (leverages Docker cache)
COPY package*.json ./
# copy npm lock if present
COPY package-lock.json ./

# install all dependencies
RUN npm ci --no-audit --no-fund

# copy project files
COPY . .

# build admin (produces admin build and prepares app)
RUN npm run build

# Runtime stage: lighter image for running the app
FROM node:22-bullseye AS runtime
WORKDIR /srv/app

# install minimal runtime deps (libvips required by sharp, if used)
RUN apt-get update && \
    apt-get install -y --no-install-recommends libvips-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# copy node_modules and built files from builder
COPY --from=builder /srv/app ./

# set environment for production by default
ENV NODE_ENV=production
ENV PORT=1337

EXPOSE 1337

# ensure uploads dir exists
RUN mkdir -p /srv/app/uploads && chown -R node:node /srv/app/uploads

# run as non-root user for better security
USER node

# start command (uses the project's npm start script)
CMD ["npm", "run", "start"]
