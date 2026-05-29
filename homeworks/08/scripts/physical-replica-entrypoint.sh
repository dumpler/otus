#!/usr/bin/env bash
set -euo pipefail

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    rm -rf "$PGDATA"/*

    until PGPASSWORD="$REPLICATION_PASSWORD" pg_basebackup \
        -h "$PRIMARY_HOST" \
        -p "$PRIMARY_PORT" \
        -U "$REPLICATION_USER" \
        -D "$PGDATA" \
        -S "$REPLICATION_SLOT" \
        -R \
        --checkpoint=fast \
        --wal-method=stream
    do
        sleep 2
    done

    echo "recovery_min_apply_delay = '5min'" >> "$PGDATA/postgresql.auto.conf"
    echo "hot_standby = on" >> "$PGDATA/postgresql.auto.conf"
fi

exec docker-entrypoint.sh postgres
