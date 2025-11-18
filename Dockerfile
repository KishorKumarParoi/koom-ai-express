# Production-grade container for KoomAI Real-Time Media Ingestion Engine
FROM oven/bun:1.2-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production \
    PORT=5001

RUN apk add --no-cache curl

COPY package.json bun.lock* ./
RUN bun install --production --frozen-lockfile || bun install --production

COPY . .

RUN mkdir -p temp_upload && chown -R bun:bun /app

USER bun

EXPOSE 5001

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5001/health || exit 1

CMD ["bun", "run", "start"]
