#!/bin/sh
set -e

# Start uvicorn in the background; nginx runs in foreground so the container
# stays alive and logs go to stdout.
uvicorn app.backend.main:app --host 127.0.0.1 --port 8000 &

nginx -g "daemon off;"
