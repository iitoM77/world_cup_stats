CREATE OR REPLACE VIEW best_midfielder_tournament_index AS
WITH qualified_players AS (
    SELECT
        player_id,
        MAX(player_name) AS player_name,
        MAX(age) AS age,
        MAX(nationality) AS nationality,
        MAX(team) AS team,
        MAX(position) AS position,
        MAX(club_name) AS club_name,

        SUM(COALESCE(minutes_played, 0)) AS total_minutes,

        SUM(COALESCE(goals, 0)) AS goals,
        SUM(COALESCE(assists, 0)) AS assists,
        SUM(COALESCE(shots, 0)) AS shots,
        SUM(COALESCE(shots_on_target, 0)) AS shots_on_target,
        SUM(COALESCE(expected_goals_xg, 0)) AS total_xg,
        SUM(COALESCE(expected_assists_xa, 0)) AS total_xa,

        SUM(COALESCE(key_passes, 0)) AS key_passes,
        SUM(COALESCE(successful_passes, 0)) AS successful_passes,
        SUM(COALESCE(total_passes, 0)) AS total_passes,

        SUM(COALESCE(dribbles_attempted, 0)) AS dribbles_attempted,
        SUM(COALESCE(successful_dribbles, 0)) AS successful_dribbles,

        SUM(COALESCE(tackles, 0)) AS tackles,
        SUM(COALESCE(interceptions, 0)) AS interceptions,
        SUM(COALESCE(recoveries, 0)) AS recoveries,
        SUM(COALESCE(defensive_actions, 0)) AS defensive_actions,
        SUM(COALESCE(blocks, 0)) AS blocks,
        SUM(COALESCE(aerial_duels_won, 0)) AS aerial_duels_won,

        SUM(COALESCE(fouls_committed, 0)) AS fouls_committed,
        SUM(COALESCE(yellow_cards, 0)) AS yellow_cards,
        SUM(COALESCE(red_cards, 0)) AS red_cards,

        AVG(COALESCE(possession_impact, 0)) AS possession_impact,
        AVG(COALESCE(pressure_resistance, 0)) AS pressure_resistance,
        AVG(COALESCE(creativity_score, 0)) AS creativity_score,
        AVG(COALESCE(offensive_contribution, 0)) AS offensive_contribution,
        AVG(COALESCE(defensive_contribution, 0)) AS defensive_contribution,

        AVG(COALESCE(consistency_score, 0)) AS consistency_score,
        AVG(COALESCE(clutch_performance_score, 0)) AS clutch_performance_score,
        AVG(COALESCE(player_rating, 0)) AS player_rating,
        AVG(COALESCE(performance_score, 0)) AS performance_score,
        AVG(COALESCE(tournament_rating, 0)) AS tournament_rating,

        SUM(COALESCE(player_of_match_awards, 0)) AS player_of_match_awards,

        MAX(
            CASE
                WHEN tournament_stage IN ('Third Place Match', 'Semi Finals', 'Final')
                THEN 1 ELSE 0
            END
        ) AS reached_semis_or_beyond

    FROM raw_player_performance
    WHERE UPPER(position) IN (
        'CM', 'CDM', 'AM',
        'CENTRAL MIDFIELDER',
        'DEFENSIVE MIDFIELDER',
        'ATTACKING MIDFIELDER',
        'LEFT MIDFIELDER',
        'RIGHT MIDFIELDER'
    )
    GROUP BY player_id
),

eligible AS (
    SELECT *
    FROM qualified_players
    WHERE total_minutes >= 300
      AND reached_semis_or_beyond = 1
),

per90 AS (
    SELECT
        *,
        (goals::double precision / NULLIF(total_minutes, 0)) * 90 AS goals_p90,
        (assists::double precision / NULLIF(total_minutes, 0)) * 90 AS assists_p90,
        (shots_on_target::double precision / NULLIF(total_minutes, 0)) * 90 AS shots_on_target_p90,
        (total_xg / NULLIF(total_minutes, 0)) * 90 AS xg_p90,
        (total_xa / NULLIF(total_minutes, 0)) * 90 AS xa_p90,
        (key_passes::double precision / NULLIF(total_minutes, 0)) * 90 AS key_passes_p90,
        (successful_passes::double precision / NULLIF(total_minutes, 0)) * 90 AS successful_passes_p90,
        (successful_dribbles::double precision / NULLIF(total_minutes, 0)) * 90 AS successful_dribbles_p90,
        (tackles::double precision / NULLIF(total_minutes, 0)) * 90 AS tackles_p90,
        (interceptions::double precision / NULLIF(total_minutes, 0)) * 90 AS interceptions_p90,
        (recoveries::double precision / NULLIF(total_minutes, 0)) * 90 AS recoveries_p90,
        (defensive_actions::double precision / NULLIF(total_minutes, 0)) * 90 AS defensive_actions_p90,
        (blocks::double precision / NULLIF(total_minutes, 0)) * 90 AS blocks_p90,
        (aerial_duels_won::double precision / NULLIF(total_minutes, 0)) * 90 AS aerial_duels_won_p90,
        (fouls_committed::double precision / NULLIF(total_minutes, 0)) * 90 AS fouls_committed_p90,
        (yellow_cards::double precision / NULLIF(total_minutes, 0)) * 90 AS yellow_cards_p90
    FROM eligible
),

normalized AS (
    SELECT
        *,
        -- 25% Possession & Ball Progression
        PERCENT_RANK() OVER (ORDER BY successful_passes_p90) AS n_successful_passes,
        PERCENT_RANK() OVER (
            ORDER BY successful_passes::double precision / NULLIF(total_passes, 0)
        ) AS n_pass_accuracy,
        PERCENT_RANK() OVER (ORDER BY possession_impact) AS n_possession_impact,
        PERCENT_RANK() OVER (ORDER BY pressure_resistance) AS n_pressure_resistance,
        PERCENT_RANK() OVER (ORDER BY successful_dribbles_p90) AS n_successful_dribbles,

        -- 20% Creativity & Chance Creation
        PERCENT_RANK() OVER (ORDER BY assists_p90) AS n_assists,
        PERCENT_RANK() OVER (ORDER BY xa_p90) AS n_xa,
        PERCENT_RANK() OVER (ORDER BY key_passes_p90) AS n_key_passes,
        PERCENT_RANK() OVER (ORDER BY creativity_score) AS n_creativity,

        -- 20% Defensive Contribution
        PERCENT_RANK() OVER (ORDER BY tackles_p90) AS n_tackles,
        PERCENT_RANK() OVER (ORDER BY interceptions_p90) AS n_interceptions,
        PERCENT_RANK() OVER (ORDER BY recoveries_p90) AS n_recoveries,
        PERCENT_RANK() OVER (ORDER BY defensive_actions_p90) AS n_defensive_actions,
        PERCENT_RANK() OVER (ORDER BY defensive_contribution) AS n_defensive_contribution,

        -- 10% Goal Threat
        PERCENT_RANK() OVER (ORDER BY goals_p90) AS n_goals,
        PERCENT_RANK() OVER (ORDER BY xg_p90) AS n_xg,
        PERCENT_RANK() OVER (ORDER BY shots_on_target_p90) AS n_shots_on_target,
        PERCENT_RANK() OVER (ORDER BY offensive_contribution) AS n_offensive_contribution,

        -- 10% Discipline & Ball Security
        PERCENT_RANK() OVER (ORDER BY fouls_committed_p90) AS n_fouls_committed,
        PERCENT_RANK() OVER (ORDER BY yellow_cards_p90) AS n_yellow_cards,
        PERCENT_RANK() OVER (ORDER BY red_cards) AS n_red_cards,

        -- 15% Consistency & Tournament Performance
        PERCENT_RANK() OVER (ORDER BY consistency_score) AS n_consistency,
        PERCENT_RANK() OVER (ORDER BY clutch_performance_score) AS n_clutch,
        PERCENT_RANK() OVER (ORDER BY player_rating) AS n_player_rating,
        PERCENT_RANK() OVER (ORDER BY performance_score) AS n_performance,
        PERCENT_RANK() OVER (ORDER BY tournament_rating) AS n_tournament_rating,
        PERCENT_RANK() OVER (ORDER BY player_of_match_awards) AS n_potm
    FROM per90
),

scored AS (
    SELECT
        *,

        (
            n_successful_passes * 0.20 +
            n_pass_accuracy * 0.20 +
            n_possession_impact * 0.25 +
            n_pressure_resistance * 0.20 +
            n_successful_dribbles * 0.15
        ) * 25 AS possession_ball_progression_score,

        (
            n_assists * 0.20 +
            n_xa * 0.25 +
            n_key_passes * 0.30 +
            n_creativity * 0.25
        ) * 20 AS creativity_chance_creation_score,

        (
            n_tackles * 0.20 +
            n_interceptions * 0.20 +
            n_recoveries * 0.20 +
            n_defensive_actions * 0.20 +
            n_defensive_contribution * 0.20
        ) * 20 AS defensive_contribution_score,

        (
            n_goals * 0.25 +
            n_xg * 0.30 +
            n_shots_on_target * 0.20 +
            n_offensive_contribution * 0.25
        ) * 10 AS goal_threat_score,

        (
            (1 - n_fouls_committed) * 0.40 +
            (1 - n_yellow_cards) * 0.35 +
            (1 - n_red_cards) * 0.25
        ) * 10 AS discipline_score,

        (
            n_consistency * 0.25 +
            n_clutch * 0.15 +
            n_player_rating * 0.15 +
            n_performance * 0.15 +
            n_tournament_rating * 0.20 +
            n_potm * 0.10
        ) * 15 AS consistency_tournament_score

    FROM normalized
),

final_scores AS (
    SELECT
        *,
        possession_ball_progression_score
        + creativity_chance_creation_score
        + defensive_contribution_score
        + goal_threat_score
        + discipline_score
        + consistency_tournament_score AS midfielder_index
    FROM scored
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY midfielder_index DESC, tournament_rating DESC, total_minutes DESC
    ) AS midfielder_rank,

    player_id,
    player_name,
    age,
    nationality,
    team,
    position,
    club_name,
    total_minutes,

    ROUND(goals_p90::numeric, 2) AS goals_p90,
    ROUND(assists_p90::numeric, 2) AS assists_p90,
    ROUND(xg_p90::numeric, 2) AS xg_p90,
    ROUND(xa_p90::numeric, 2) AS xa_p90,
    ROUND(key_passes_p90::numeric, 2) AS key_passes_p90,
    ROUND(successful_passes_p90::numeric, 2) AS successful_passes_p90,
    ROUND(successful_dribbles_p90::numeric, 2) AS successful_dribbles_p90,
    ROUND(tackles_p90::numeric, 2) AS tackles_p90,
    ROUND(interceptions_p90::numeric, 2) AS interceptions_p90,
    ROUND(recoveries_p90::numeric, 2) AS recoveries_p90,

    ROUND(possession_ball_progression_score::numeric, 2) AS possession_ball_progression_score,
    ROUND(creativity_chance_creation_score::numeric, 2) AS creativity_chance_creation_score,
    ROUND(defensive_contribution_score::numeric, 2) AS defensive_contribution_score,
    ROUND(goal_threat_score::numeric, 2) AS goal_threat_score,
    ROUND(discipline_score::numeric, 2) AS discipline_score,
    ROUND(consistency_tournament_score::numeric, 2) AS consistency_tournament_score,

    ROUND(midfielder_index::numeric, 2) AS midfielder_index,
    ROUND(tournament_rating::numeric, 2) AS tournament_rating

FROM final_scores
ORDER BY midfielder_rank;
