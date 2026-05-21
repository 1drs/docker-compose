#!/bin/sh
set -e

export NODE_ENV=${NODE_ENV:-production}

cd /var/lib/ghost
exec su-exec ghost node current/index.js
