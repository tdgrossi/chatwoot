#!/bin/sh
set -x

echo "[vite-entrypoint] $(date +%T) - Starting entrypoint"

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "[vite-entrypoint] $(date +%T) - Running pnpm install..."
pnpm install --force

# vite binstub requires bundler; base image has 2.6.7, Gemfile.lock specifies 2.5.16
# Override so bin/vite uses the available bundler version
export BUNDLER_VERSION=2.6.7

# Bind Vite to all interfaces so Rails (in another container) can proxy to it
# vite-plugin-ruby uses VITE_RUBY_<option> prefix
export VITE_RUBY_HOST=0.0.0.0

echo "[vite-entrypoint] $(date +%T) - Ready to run Vite dev server"

exec "$@"
