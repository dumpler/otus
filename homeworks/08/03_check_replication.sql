SELECT
    slot_name,
    slot_type,
    active
FROM pg_replication_slots
ORDER BY slot_name;

SELECT
    application_name,
    state,
    sync_state,
    replay_lag
FROM pg_stat_replication
ORDER BY application_name;

\connect replication_demo

INSERT INTO public.player_scores (player_name, year_game, points)
VALUES
    ('Anna', 2025, 21),
    ('Pavel', 2025, 19)
RETURNING
    id,
    player_name,
    year_game,
    points;

SELECT
    id,
    player_name,
    year_game,
    points
FROM public.player_scores
ORDER BY id;
