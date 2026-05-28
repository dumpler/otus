DROP TABLE IF EXISTS statistic;

CREATE TABLE statistic (
    player_name VARCHAR(100) NOT NULL,
    player_id INT NOT NULL,
    year_game SMALLINT NOT NULL CHECK (year_game > 0),
    points DECIMAL(12,2) CHECK (points >= 0),
    PRIMARY KEY (player_name, year_game)
);

INSERT INTO statistic(player_name, player_id, year_game, points)
VALUES
    ('Mike', 1, 2018, 18),
    ('Jack', 2, 2018, 14),
    ('Jackie', 3, 2018, 30),
    ('Jet', 4, 2018, 30),
    ('Luke', 1, 2019, 16),
    ('Mike', 2, 2019, 14),
    ('Jack', 3, 2019, 15),
    ('Jackie', 4, 2019, 28),
    ('Jet', 5, 2019, 25),
    ('Luke', 1, 2020, 19),
    ('Mike', 2, 2020, 17),
    ('Jack', 3, 2020, 18),
    ('Jackie', 4, 2020, 29),
    ('Jet', 5, 2020, 27);

SELECT
    year_game,
    sum(points) AS total_points
FROM statistic
GROUP BY year_game
ORDER BY year_game;

WITH points_by_year AS (
    SELECT
        year_game,
        sum(points) AS total_points
    FROM statistic
    GROUP BY year_game
)
SELECT
    year_game,
    total_points
FROM points_by_year
ORDER BY year_game;

WITH points_by_year AS (
    SELECT
        year_game,
        sum(points) AS total_points
    FROM statistic
    GROUP BY year_game
),
points_with_previous_year AS (
    SELECT
        year_game,
        total_points AS current_year_points,
        lag(total_points) OVER (ORDER BY year_game) AS previous_year_points
    FROM points_by_year
)
SELECT
    year_game,
    current_year_points,
    previous_year_points,
    current_year_points - previous_year_points AS points_difference
FROM points_with_previous_year
ORDER BY year_game;
