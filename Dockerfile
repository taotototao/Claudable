############################
# 1️⃣ Base
############################
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache libc6-compat git


############################
# 2️⃣ Déps
############################
FROM base AS deps

COPY package.json package-lock.json* ./
RUN npm ci


############################
# 3️⃣ Build
############################
FROM base AS builder

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build


############################
# 4️⃣ Runner (PRODUCTION)
############################
FROM node:20-alpine AS runner
WORKDIR /app

# 👉 Vars runtime
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# 👉 IMPORTANT : rendre les binaires globaux visibles
ENV PATH="/usr/local/bin:${PATH}"

# 👉 Dépendances runtime
RUN apk add --no-cache \
    libc6-compat \
    git \
    bash

# 👉 INSTALL CLAUDE CODE (ICI est la clé)
RUN npm install -g @anthropic-ai/claude-code \
 && ln -s /usr/local/bin/claude /usr/bin/claude

# 👉 Sécurité
RUN addgroup --system --gid 1001 nextjs \
 && adduser --system --uid 1001 nextjs

# 👉 Fichiers Next.js standalone
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# 👉 Permissions (important pour Claudable)
RUN chown -R nextjs:nextjs /app

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
