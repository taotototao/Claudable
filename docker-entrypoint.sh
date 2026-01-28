#!/bin/sh
set -e

echo "🚀 Starting Claudable..."

# Default DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
  echo "⚠️  DATABASE_URL not set, using SQLite"
  export DATABASE_URL="file:/app/data/cc.db"
fi

echo "✅ DATABASE_URL = $DATABASE_URL"

# Ensure data directory exists
mkdir -p /app/data

echo "📦 Initializing database..."

PRISMA="node node_modules/.bin/prisma"

if [ -f "/app/data/cc.db" ]; then
  echo "✅ Database exists"
  echo "🔄 Applying migrations (best effort)..."
  $PRISMA migrate deploy || echo "⚠️  migrate deploy skipped"
else
  echo "📦 Creating new database..."
  $PRISMA db push --skip-generate --accept-data-loss || echo "⚠️  db push warning"
fi

echo "✅ Database ready"
echo "🎉 Starting Claudable application..."

exec "$@"
