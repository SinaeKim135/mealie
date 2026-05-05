#!/usr/bin/env bash
# Fetches a Mealie bearer token from the running container at localhost:9000
# and prints it on stdout. Used by both:
#   - the workflow pre-step (to seed SKYRAMP_TEST_TOKEN in $GITHUB_ENV)
#   - the skyramp/testbot action's authTokenCommand (backup token fetcher)
#
# Kept as a separate script so the YAML/Skyramp runner never has to handle
# multi-line shell with backslash continuations — Skyramp's executor runs
# authTokenCommand directly (not via bash), so any literal '\' chars end
# up inside the JSON value and break parsing.
set -euo pipefail

curl -fsS -X POST http://localhost:9000/api/auth/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=changeme%40example.com&password=MyPassword' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])'
