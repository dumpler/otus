CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator';

SELECT pg_create_physical_replication_slot('physical_replica_slot');

CREATE DATABASE replication_demo;

\connect replication_demo

CREATE TABLE public.player_scores (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_name TEXT NOT NULL,
    year_game SMALLINT NOT NULL CHECK (year_game > 0),
    points NUMERIC(12,2) NOT NULL CHECK (points >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.player_scores (player_name, year_game, points)
VALUES
    ('Mike', 2024, 18),
    ('Jack', 2024, 14),
    ('Jackie', 2024, 30),
    ('Jet', 2025, 30),
    ('Luke', 2025, 16);

GRANT CONNECT ON DATABASE replication_demo TO replicator;
GRANT USAGE ON SCHEMA public TO replicator;
GRANT SELECT ON public.player_scores TO replicator;

CREATE PUBLICATION player_scores_publication
FOR TABLE public.player_scores;
