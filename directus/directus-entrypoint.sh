#!/bin/bash
set -e

cd /directus

# Run database migrations then start Directus
npx directus bootstrap
exec npx directus start