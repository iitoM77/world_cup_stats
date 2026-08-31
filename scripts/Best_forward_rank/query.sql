CREATE OR REPLACE VIEW best_forward_index AS

WITH player_tournament_stats AS (



SELECT
    player_id,
    MAX(player_name) AS player_name,
    MAX(age) AS age,
    MAX(nationality) AS nationality,
    MAX(team) AS team,
    MAX(position) AS position,
    MAX(club_name) AS club_name,

    SUM(COALESCE(minutes_played, 0)) AS total_minutes,

    -- GOALSCORING
    SUM(COALESCE(goals, 0)) AS total_goals,
    SUM(COALESCE(shots, 0)) AS total_shots,
    SUM(COALESCE(shots_on_target, 0)) AS total_shots_on_target,
    SUM(COALESCE(expected_goals_xg, 0)) AS total_xg,

    -- CREATIVITY
    SUM(COALESCE(assists, 0)) AS total_assists,
    SUM(COALESCE(expected_assists_xa, 0)) AS total_xa,
    SUM(COALESCE(key_passes, 0)) AS total_key_passes,

    -- DRIBBLING / PROGRESSION
    SUM(COALESCE(dribbles_attempted, 0)) AS total_dribbles_attempted,
    SUM(COALESCE(successful_dribbles, 0)) AS total_successful_dribbles,
    SUM(COALESCE(fouls_suffered, 0)) AS total_fouls_suffered,

    AVG(COALESCE(possession_impact, 0)) AS avg_possession_impact,
    AVG(COALESCE(pressure_resistance, 0)) AS avg_pressure_resistance,

    -- PERFORMANCE / CONSISTENCY
    AVG(COALESCE(player_rating, 0)) AS avg_player_rating,
    AVG(COALESCE(performance_score, 0)) AS avg_performance_score,
    AVG(COALESCE(consistency_score, 0)) AS avg_consistency_score,
    AVG(COALESCE(tournament_rating, 0)) AS avg_tournament_rating,

    -- CLUTCH
    AVG(COALESCE(clutch_performance_score, 0))
        AS avg_clutch_performance_score,

    MAX(COALESCE(player_of_match_awards, 0))
        AS player_of_match_awards,

    -- TEAM TOURNAMENT PROGRESSION
    BOOL_OR(
        tournament_stage IN (
            'Third Place Match',
            'Semi Finals',
            'Final'
        )
    ) AS reached_semifinals

FROM raw_player_performance

WHERE position IN ('ST', 'LW', 'RW')

GROUP BY player_id

),

eligible_players AS (


SELECT *

FROM player_tournament_stats

WHERE total_minutes >= 300
  AND reached_semifinals = TRUE

),

per_90_metrics AS (



SELECT
    *,

    -- GOALSCORING
    (total_goals * 90.0 / NULLIF(total_minutes, 0))
        AS goals_per_90,

    (total_xg * 90.0 / NULLIF(total_minutes, 0))
        AS xg_per_90,

    (total_shots * 90.0 / NULLIF(total_minutes, 0))
        AS shots_per_90,

    (total_shots_on_target * 90.0 / NULLIF(total_minutes, 0))
        AS shots_on_target_per_90,

    CASE
        WHEN total_shots > 0
        THEN total_goals::numeric / total_shots
        ELSE 0
    END AS goal_conversion_rate,

    -- CREATIVITY
    (total_assists * 90.0 / NULLIF(total_minutes, 0))
        AS assists_per_90,

    (total_xa * 90.0 / NULLIF(total_minutes, 0))
        AS xa_per_90,

    (total_key_passes * 90.0 / NULLIF(total_minutes, 0))
        AS key_passes_per_90,

    -- DRIBBLING
    (total_successful_dribbles * 90.0 /
        NULLIF(total_minutes, 0))
        AS successful_dribbles_per_90,

    CASE
        WHEN total_dribbles_attempted > 0
        THEN total_successful_dribbles::numeric /
             total_dribbles_attempted
        ELSE 0
    END AS dribble_success_rate,

    (total_fouls_suffered * 90.0 /
        NULLIF(total_minutes, 0))
        AS fouls_suffered_per_90

FROM eligible_players

),

normalized_metrics AS (

SELECT
    *,

    PERCENT_RANK() OVER (
        ORDER BY goals_per_90
    ) * 100 AS goals_per_90_score,

    PERCENT_RANK() OVER (
        ORDER BY xg_per_90
    ) * 100 AS xg_per_90_score,

    PERCENT_RANK() OVER (
        ORDER BY shots_on_target_per_90
    ) * 100 AS shots_on_target_score,

    PERCENT_RANK() OVER (
        ORDER BY goal_conversion_rate
    ) * 100 AS finishing_efficiency_score,

    PERCENT_RANK() OVER (
        ORDER BY assists_per_90
    ) * 100 AS assists_score,

    PERCENT_RANK() OVER (
        ORDER BY xa_per_90
    ) * 100 AS xa_score,

    PERCENT_RANK() OVER (
        ORDER BY key_passes_per_90
    ) * 100 AS key_passes_score,

    PERCENT_RANK() OVER (
        ORDER BY successful_dribbles_per_90
    ) * 100 AS dribbles_score,

    PERCENT_RANK() OVER (
        ORDER BY dribble_success_rate
    ) * 100 AS dribble_success_score,

    PERCENT_RANK() OVER (
        ORDER BY fouls_suffered_per_90
    ) * 100 AS fouls_suffered_score,

    PERCENT_RANK() OVER (
        ORDER BY avg_possession_impact
    ) * 100 AS possession_impact_score,

    PERCENT_RANK() OVER (
        ORDER BY avg_pressure_resistance
    ) * 100 AS pressure_resistance_score,

    PERCENT_RANK() OVER (
        ORDER BY avg_player_rating
    ) * 100 AS player_rating_score,

    PERCENT_RANK() OVER (
        ORDER BY avg_performance_score
    ) * 100 AS performance_score_normalized,

    PERCENT_RANK() OVER (
        ORDER BY avg_consistency_score
    ) * 100 AS consistency_normalized,

    PERCENT_RANK() OVER (
        ORDER BY avg_tournament_rating
    ) * 100 AS tournament_rating_score,


    PERCENT_RANK() OVER (
        ORDER BY avg_clutch_performance_score
    ) * 100 AS clutch_score,

    PERCENT_RANK() OVER (
        ORDER BY player_of_match_awards
    ) * 100 AS player_of_match_score

FROM per_90_metrics


),

category_scores AS (



SELECT
    *,
    (
        goals_per_90_score * 0.35 +
        xg_per_90_score * 0.25 +
        shots_on_target_score * 0.20 +
        finishing_efficiency_score * 0.20
    ) AS goal_threat_finishing_index,

    (
        assists_score * 0.35 +
        xa_score * 0.30 +
        key_passes_score * 0.35
    ) AS creativity_chance_creation_index,


    (
        dribbles_score * 0.30 +
        dribble_success_score * 0.20 +
        fouls_suffered_score * 0.15 +
        possession_impact_score * 0.20 +
        pressure_resistance_score * 0.15
    ) AS dribbling_progression_index,


    (
        player_rating_score * 0.25 +
        performance_score_normalized * 0.25 +
        consistency_normalized * 0.25 +
        tournament_rating_score * 0.25
    ) AS consistency_tournament_index,

    (
        clutch_score * 0.70 +
        player_of_match_score * 0.30
    ) AS clutch_big_game_index

FROM normalized_metrics


),

final_index AS (


SELECT
    *,

    (
        goal_threat_finishing_index * 0.35 +
        creativity_chance_creation_index * 0.20 +
        dribbling_progression_index * 0.15 +
        consistency_tournament_index * 0.20 +
        clutch_big_game_index * 0.10
    ) AS forward_index_score

FROM category_scores

)

SELECT RANK() OVER (
    ORDER BY forward_index_score DESC
) AS forward_rank,

player_id,
player_name,
age,
nationality,
team,
position,
club_name,

total_minutes,

-- RAW TOURNAMENT OUTPUT
total_goals,
total_assists,
total_xg,
total_xa,

-- PER-90 PERFORMANCE
ROUND(goals_per_90::numeric, 2) AS goals_per_90,
ROUND(xg_per_90::numeric, 2) AS xg_per_90,
ROUND(shots_per_90::numeric, 2) AS shots_per_90,
ROUND(shots_on_target_per_90::numeric, 2)
    AS shots_on_target_per_90,

ROUND(assists_per_90::numeric, 2) AS assists_per_90,
ROUND(xa_per_90::numeric, 2) AS xa_per_90,
ROUND(key_passes_per_90::numeric, 2)
    AS key_passes_per_90,

ROUND(successful_dribbles_per_90::numeric, 2)
    AS successful_dribbles_per_90,

ROUND((dribble_success_rate * 100)::numeric, 2)
    AS dribble_success_percentage,

ROUND(fouls_suffered_per_90::numeric, 2)
    AS fouls_suffered_per_90,


-- CATEGORY INDEXES
ROUND(goal_threat_finishing_index::numeric, 2)
    AS goal_threat_finishing_index,

ROUND(creativity_chance_creation_index::numeric, 2)
    AS creativity_chance_creation_index,

ROUND(dribbling_progression_index::numeric, 2)
    AS dribbling_progression_index,

ROUND(consistency_tournament_index::numeric, 2)
    AS consistency_tournament_index,

ROUND(clutch_big_game_index::numeric, 2)
    AS clutch_big_game_index,


-- FINAL SCORE
ROUND(forward_index_score::numeric, 2)
    AS forward_index_score,

-- ADDITIONAL TOURNAMENT METRICS
avg_player_rating,
avg_performance_score,
avg_consistency_score,
avg_tournament_rating,
avg_clutch_performance_score,
player_of_match_awards

FROM final_index

ORDER BY forward_index_score DESC;
