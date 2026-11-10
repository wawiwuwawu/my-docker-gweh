# Fastify + Prisma (Node 22, TypeScript) — production multi-stage build.
#
# prisma generate runs in the build stage; `prisma migrate deploy` runs at
# container start so the schema is applied before Fastify listens.
FROM node:22-alpine AS deps
WORKDIR /app
RUN apk add --no-cache openssl libc6-compat
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci

FROM deps AS build
COPY . .
RUN npx prisma generate && npm run build

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache openssl libc6-compat && addgroup -S app && adduser -S app -G app
COPY --from=deps  /app/node_modules ./node_modules
COPY --from=build /app/dist        ./dist
COPY --from=build /app/prisma      ./prisma
COPY package*.json ./
USER app
EXPOSE 3000
# migrate deploy is idempotent; drop it if the schema is managed elsewhere
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
