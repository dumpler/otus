#!/usr/bin/env bash
set -euo pipefail

echo "host replication replicator all scram-sha-256" >> "$PGDATA/pg_hba.conf"
