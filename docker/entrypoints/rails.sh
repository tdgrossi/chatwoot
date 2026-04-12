#!/bin/sh
set -x

echo "[rails-entrypoint] $(date +%T) - Starting entrypoint"

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "[rails-entrypoint] $(date +%T) - Waiting for postgres..."

# Let DATABASE_URL env take presedence over individual connection params.
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  echo "[rails-entrypoint] $(date +%T) - Waiting for postgres...";
  sleep 2;
done

echo "[rails-entrypoint] $(date +%T) - Postgres ready, checking bundle..."

# Only run bundle install if gems are actually missing (dev speed: avoid reinstalling on every start)
BUNDLE_CHECK=$(bundle check 2>&1)
if ! bundle check > /dev/null 2>&1; then
  echo "[rails-entrypoint] $(date +%T) - Bundle check failed, running bundle install..."
  bundle install
fi

echo "[rails-entrypoint] $(date +%T) - Ready to accept connections"

# Execute the main process of the container
exec "$@"
