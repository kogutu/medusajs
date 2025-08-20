FROM node:20-alpine

WORKDIR /app

# Install system dependencies including Python and build tools
RUN apk add --no-cache \
    python3 \
    py3-pip \
    make \
    g++ \
    git

# Copy package files first for better caching
COPY package.json yarn.lock ./

# Install dependencies with frozen lockfile for reproducibility
RUN yarn install --frozen-lockfile --production=false

# Copy application source code
COPY . .

# Build the application
RUN yarn build

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S medusa -u 1001

# Change ownership of the app directory
RUN chown -R medusa:nodejs /app

# Switch to non-root user
USER medusa

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD node scripts/healthcheck.js || exit 1

# Run migrations and start the application
CMD sh -c "medusa migrations run && yarn start"
