#!/bin/sh
set -e

echo "🚀 Starting Claudable..."

# Vérifier que DATABASE_URL est défini
if [ -z "$DATABASE_URL" ]; then
  echo "⚠️  DATABASE_URL not set, using default SQLite"
  export DATABASE_URL="file:/app/data/cc.db"
fi

echo "✅ DATABASE_URL configured"

# Créer le répertoire data si nécessaire
mkdir -p /app/data
chmod 777 /app/data

# Initialiser la base de données SQLite
echo "📦 Initializing database..."

# Vérifier si la base existe déjà
if [ -f "/app/data/cc.db" ]; then
  echo "✅ Database exists, checking schema..."
  
  # Appliquer les migrations si nécessaire
  if npx prisma migrate deploy 2>&1; then
    echo "✅ Migrations applied successfully"
  else
    echo "⚠️  Migration failed, trying db push..."
    npx prisma db push --skip-generate --accept-data-loss 2>&1 || echo "⚠️  DB push warning (continuing)"
  fi
else
  echo "📦 Creating new database..."
  npx prisma db push --skip-generate --accept-data-loss 2>&1 || echo "⚠️  DB creation warning (continuing)"
  echo "✅ Database created"
fi

# S'assurer que les permissions sont correctes
chmod 666 /app/data/cc.db 2>/dev/null || true
chmod 777 /app/data 2>/dev/null || true

echo "✅ Database ready"
echo "🎉 Starting Claudable application..."

# Lancer l'application
exec "$@"
