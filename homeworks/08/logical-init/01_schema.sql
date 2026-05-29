CREATE TABLE public.player_scores (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_name TEXT NOT NULL,
    year_game SMALLINT NOT NULL CHECK (year_game > 0),
    points NUMERIC(12,2) NOT NULL CHECK (points >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
