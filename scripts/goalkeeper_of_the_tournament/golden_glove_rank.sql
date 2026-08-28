-- Goalkeeper Tournament Analytics View
-- Source: raw_player_performance
-- Fix: percentile values are cast to NUMERIC before ROUND(..., 2).

CREATE OR REPLACE VIEW goalkeeper_tournament_analytics AS
WITH goalkeeper_matches AS (
    SELECT player_id, player_name, team, position, match_id, tournament_stage,
           minutes_played, saves, save_percentage, clean_sheet, goals_conceded,
           penalty_saves, clearances, aerial_duels_won, aerial_duels_lost,
           recoveries, defensive_actions, pass_accuracy, successful_passes,
           clutch_performance_score, tournament_rating
    FROM raw_player_performance
    WHERE LOWER(TRIM(position)) IN ('gk', 'goalkeeper', 'keeper')
      AND minutes_played > 0
),
team_tournament_stage AS (
    SELECT team,
           MAX(CASE
               WHEN LOWER(TRIM(tournament_stage)) = 'final' THEN 4
               WHEN LOWER(TRIM(tournament_stage)) IN ('semi finals', 'third place match') THEN 3
               ELSE 0
           END) AS highest_stage_reached
    FROM goalkeeper_matches
    GROUP BY team
),
qualified_teams AS (
    SELECT team
    FROM team_tournament_stage
    WHERE highest_stage_reached >= 3
),
tournament_agg AS (
    SELECT
        gm.player_id,
        MAX(gm.player_name) AS player_name,
        MAX(gm.team) AS team,
        COUNT(DISTINCT gm.match_id) AS appearances,
        SUM(gm.minutes_played) AS total_minutes,
        SUM(gm.saves) AS total_saves,
        SUM(gm.penalty_saves) AS total_penalty_saves,
        AVG(gm.save_percentage) AS avg_save_percentage,
        SUM(CASE WHEN gm.clean_sheet = 1 THEN 1 ELSE 0 END) AS clean_sheets,
        SUM(gm.clearances) AS total_clearances,
        SUM(gm.aerial_duels_won) AS aerial_duels_won,
        SUM(gm.aerial_duels_lost) AS aerial_duels_lost,
        SUM(gm.recoveries) AS total_recoveries,
        SUM(gm.defensive_actions) AS total_defensive_actions,
        SUM(gm.goals_conceded) AS total_goals_conceded,
        AVG(gm.pass_accuracy) AS avg_pass_accuracy,
        SUM(gm.successful_passes) AS total_successful_passes,
        AVG(gm.clutch_performance_score) AS avg_clutch_score,
        AVG(gm.tournament_rating) AS tournament_rating
    FROM goalkeeper_matches gm
    JOIN qualified_teams qt ON gm.team = qt.team
    GROUP BY gm.player_id
),
rates AS (
    SELECT *,
        total_saves / NULLIF(total_minutes / 90.0, 0) AS saves_per_90,
        total_penalty_saves / NULLIF(total_minutes / 90.0, 0) AS penalty_saves_per_90,
        total_clearances / NULLIF(total_minutes / 90.0, 0) AS clearances_per_90,
        total_recoveries / NULLIF(total_minutes / 90.0, 0) AS recoveries_per_90,
        total_defensive_actions / NULLIF(total_minutes / 90.0, 0) AS defensive_actions_per_90,
        total_goals_conceded / NULLIF(total_minutes / 90.0, 0) AS goals_conceded_per_90,
        total_successful_passes / NULLIF(total_minutes / 90.0, 0) AS successful_passes_per_90,
        clean_sheets::numeric / NULLIF(appearances::numeric, 0) AS clean_sheet_rate,
        aerial_duels_won::numeric /
            NULLIF((aerial_duels_won + aerial_duels_lost)::numeric, 0) AS aerial_duel_win_rate
    FROM tournament_agg
    WHERE total_minutes >= 300
),
ranked AS (
    SELECT *,
        PERCENT_RANK() OVER (ORDER BY avg_save_percentage) * 100 AS score_save_percentage,
        PERCENT_RANK() OVER (ORDER BY saves_per_90) * 100 AS score_saves_per_90,
        PERCENT_RANK() OVER (ORDER BY penalty_saves_per_90) * 100 AS score_penalty_saves_per_90,
        PERCENT_RANK() OVER (ORDER BY clean_sheet_rate) * 100 AS score_clean_sheet_rate,
        PERCENT_RANK() OVER (ORDER BY aerial_duel_win_rate) * 100 AS score_aerial_duel_win_rate,
        PERCENT_RANK() OVER (ORDER BY defensive_actions_per_90) * 100 AS score_defensive_actions_per_90,
        PERCENT_RANK() OVER (ORDER BY recoveries_per_90) * 100 AS score_recoveries_per_90,
        PERCENT_RANK() OVER (ORDER BY clearances_per_90) * 100 AS score_clearances_per_90,
        PERCENT_RANK() OVER (ORDER BY avg_pass_accuracy) * 100 AS score_pass_accuracy,
        PERCENT_RANK() OVER (ORDER BY successful_passes_per_90) * 100 AS score_successful_passes_per_90,
        PERCENT_RANK() OVER (ORDER BY avg_clutch_score) * 100 AS score_clutch,
        PERCENT_RANK() OVER (ORDER BY tournament_rating) * 100 AS score_tournament_rating
    FROM rates
),
component_scores AS (
    SELECT *,
        ROUND((0.70 * score_save_percentage + 0.20 * score_saves_per_90
             + 0.10 * score_penalty_saves_per_90)::numeric, 2) AS shot_stopping_score,
        ROUND((0.30 * score_clean_sheet_rate + 0.25 * score_aerial_duel_win_rate
             + 0.15 * score_defensive_actions_per_90 + 0.15 * score_recoveries_per_90
             + 0.15 * score_clearances_per_90)::numeric, 2) AS defensive_command_score,
        ROUND((0.60 * score_pass_accuracy + 0.40 * score_successful_passes_per_90)::numeric, 2) AS distribution_score,
        ROUND((0.60 * score_clutch + 0.40 * score_penalty_saves_per_90)::numeric, 2) AS big_moments_score,
        ROUND(score_tournament_rating::numeric, 2) AS tournament_rating_score
    FROM ranked
),
final_scores AS (
    SELECT *,
        ROUND((0.35 * shot_stopping_score + 0.25 * defensive_command_score
             + 0.15 * distribution_score + 0.15 * big_moments_score
             + 0.10 * tournament_rating_score)::numeric, 2) AS overall_gk_score
    FROM component_scores
)
SELECT
    RANK() OVER (ORDER BY overall_gk_score DESC, total_minutes DESC) AS gk_rank,
    player_id, player_name, team, appearances, total_minutes,
    total_saves,
    ROUND(avg_save_percentage::numeric, 2) AS save_percentage,
    total_penalty_saves, clean_sheets, total_goals_conceded,
    ROUND(goals_conceded_per_90::numeric, 2) AS goals_conceded_per_90,
    ROUND((clean_sheet_rate * 100)::numeric, 2) AS clean_sheet_rate_pct,
    ROUND((aerial_duel_win_rate * 100)::numeric, 2) AS aerial_duel_win_rate_pct,
    ROUND(saves_per_90::numeric, 2) AS saves_per_90,
    ROUND(penalty_saves_per_90::numeric, 2) AS penalty_saves_per_90,
    ROUND(defensive_actions_per_90::numeric, 2) AS defensive_actions_per_90,
    ROUND(recoveries_per_90::numeric, 2) AS recoveries_per_90,
    ROUND(clearances_per_90::numeric, 2) AS clearances_per_90,
    ROUND(avg_pass_accuracy::numeric, 2) AS pass_accuracy,
    ROUND(successful_passes_per_90::numeric, 2) AS successful_passes_per_90,
    shot_stopping_score, defensive_command_score, distribution_score,
    big_moments_score, tournament_rating_score, overall_gk_score
FROM final_scores;

-- Example:
-- SELECT * FROM goalkeeper_tournament_analytics ORDER BY gk_rank;

