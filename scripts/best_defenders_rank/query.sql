CREATE OR REPLACE VIEW best_defenders_tournament_ranking AS

WITH semifinal_teams AS (
    SELECT DISTINCT team
    FROM raw_player_performance
    WHERE tournament_stage IN (
        'Third Place Match',
        'Semi Finals',
        'Final'
    )
),

player_tournament_stats AS (
    SELECT
        p.player_id,
        MAX(p.player_name) AS player_name,
        MAX(p.age) AS age,
        MAX(p.nationality) AS nationality,
        p.team,
        MAX(p.jersey_number) AS jersey_number,
        MAX(p.position) AS position,
        MAX(p.height_cm) AS height_cm,
        MAX(p.weight_kg) AS weight_kg,
        MAX(p.preferred_foot) AS preferred_foot,
        MAX(p.club_name) AS club_name,
        MAX(p.market_value_eur) AS market_value_eur,

        SUM(p.minutes_played) AS total_minutes,

        /* Defensive Metrics */
        SUM(p.tackles) AS tackles,
        SUM(p.interceptions) AS interceptions,
        SUM(p.blocks) AS blocks,
        SUM(p.recoveries) AS recoveries,
        SUM(p.defensive_actions) AS defensive_actions,
        SUM(p.clearances) AS clearances,

        SUM(p.aerial_duels_won) AS aerial_duels_won,
        SUM(p.aerial_duels_lost) AS aerial_duels_lost,

        /* Discipline */
        SUM(p.fouls_committed) AS fouls_committed,
        SUM(p.yellow_cards) AS yellow_cards,
        SUM(p.red_cards) AS red_cards,

        /* Ball Playing */
        SUM(p.successful_passes) AS successful_passes,
        SUM(p.total_passes) AS total_passes,

        AVG(p.pass_accuracy) AS avg_pass_accuracy,
        AVG(p.pressure_resistance) AS avg_pressure_resistance,
        AVG(p.possession_impact) AS avg_possession_impact,

        /* Consistency & Tournament Performance */
        AVG(p.consistency_score) AS avg_consistency_score,
        AVG(p.player_rating) AS avg_player_rating,
        AVG(p.performance_score) AS avg_performance_score,
        AVG(p.tournament_rating) AS avg_tournament_rating

    FROM raw_player_performance p

    INNER JOIN semifinal_teams st
        ON p.team = st.team

    WHERE p.position IN ('RB', 'LB', 'CB')

    GROUP BY
        p.player_id,
        p.team
),

qualified_players AS (
    SELECT *
    FROM player_tournament_stats
    WHERE total_minutes >= 300
),

per_90_metrics AS (
    SELECT
        *,

        /* Defensive Per 90 */

        (tackles::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS tackles_per_90,

        (interceptions::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS interceptions_per_90,

        (blocks::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS blocks_per_90,

        (recoveries::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS recoveries_per_90,

        (defensive_actions::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS defensive_actions_per_90,

        (clearances::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS clearances_per_90,

        /* Aerial Duel Success Percentage */

        (
            aerial_duels_won::NUMERIC * 100
            / NULLIF(
                aerial_duels_won + aerial_duels_lost,
                0
            )
        ) AS aerial_duel_success_pct,

        /* Discipline Per 90 */

        (fouls_committed::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS fouls_per_90,

        (yellow_cards::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS yellow_cards_per_90,

        (red_cards::NUMERIC * 90 / NULLIF(total_minutes, 0))
            AS red_cards_per_90,

        /* Passing Success Percentage */

        (
            successful_passes::NUMERIC * 100
            / NULLIF(total_passes, 0)
        ) AS pass_success_pct

    FROM qualified_players
),

normalized_metrics AS (
    SELECT
        *,

        /* =====================================================
           DEFENSIVE PERFORMANCE - 50%
           ===================================================== */

        (
            (interceptions_per_90 - MIN(interceptions_per_90) OVER ())
            / NULLIF(
                MAX(interceptions_per_90) OVER ()
                - MIN(interceptions_per_90) OVER (),
                0
            )
        ) * 100 AS norm_interceptions,

        (
            (defensive_actions_per_90 - MIN(defensive_actions_per_90) OVER ())
            / NULLIF(
                MAX(defensive_actions_per_90) OVER ()
                - MIN(defensive_actions_per_90) OVER (),
                0
            )
        ) * 100 AS norm_defensive_actions,

        (
            (recoveries_per_90 - MIN(recoveries_per_90) OVER ())
            / NULLIF(
                MAX(recoveries_per_90) OVER ()
                - MIN(recoveries_per_90) OVER (),
                0
            )
        ) * 100 AS norm_recoveries,

        (
            (tackles_per_90 - MIN(tackles_per_90) OVER ())
            / NULLIF(
                MAX(tackles_per_90) OVER ()
                - MIN(tackles_per_90) OVER (),
                0
            )
        ) * 100 AS norm_tackles,

        (
            (blocks_per_90 - MIN(blocks_per_90) OVER ())
            / NULLIF(
                MAX(blocks_per_90) OVER ()
                - MIN(blocks_per_90) OVER (),
                0
            )
        ) * 100 AS norm_blocks,

        (
            (aerial_duel_success_pct
                - MIN(aerial_duel_success_pct) OVER ())
            / NULLIF(
                MAX(aerial_duel_success_pct) OVER ()
                - MIN(aerial_duel_success_pct) OVER (),
                0
            )
        ) * 100 AS norm_aerial_success,


        /* =====================================================
           DISCIPLINE - 10%
           Lower is Better
           ===================================================== */

        100 -
        (
            (fouls_per_90 - MIN(fouls_per_90) OVER ())
            / NULLIF(
                MAX(fouls_per_90) OVER ()
                - MIN(fouls_per_90) OVER (),
                0
            )
        ) * 100 AS norm_fouls,

        100 -
        (
            (yellow_cards_per_90
                - MIN(yellow_cards_per_90) OVER ())
            / NULLIF(
                MAX(yellow_cards_per_90) OVER ()
                - MIN(yellow_cards_per_90) OVER (),
                0
            )
        ) * 100 AS norm_yellow_cards,

        100 -
        (
            (red_cards_per_90
                - MIN(red_cards_per_90) OVER ())
            / NULLIF(
                MAX(red_cards_per_90) OVER ()
                - MIN(red_cards_per_90) OVER (),
                0
            )
        ) * 100 AS norm_red_cards,


        /* =====================================================
           POSSESSION / BALL PLAYING - 15%
           ===================================================== */

        (
            (pass_success_pct - MIN(pass_success_pct) OVER ())
            / NULLIF(
                MAX(pass_success_pct) OVER ()
                - MIN(pass_success_pct) OVER (),
                0
            )
        ) * 100 AS norm_pass_success,

        (
            (avg_pressure_resistance
                - MIN(avg_pressure_resistance) OVER ())
            / NULLIF(
                MAX(avg_pressure_resistance) OVER ()
                - MIN(avg_pressure_resistance) OVER (),
                0
            )
        ) * 100 AS norm_pressure_resistance,

        (
            (avg_possession_impact
                - MIN(avg_possession_impact) OVER ())
            / NULLIF(
                MAX(avg_possession_impact) OVER ()
                - MIN(avg_possession_impact) OVER (),
                0
            )
        ) * 100 AS norm_possession_impact,


        /* =====================================================
           CONSISTENCY & TOURNAMENT PERFORMANCE - 25%
           ===================================================== */

        (
            (avg_consistency_score
                - MIN(avg_consistency_score) OVER ())
            / NULLIF(
                MAX(avg_consistency_score) OVER ()
                - MIN(avg_consistency_score) OVER (),
                0
            )
        ) * 100 AS norm_consistency,

        (
            (avg_player_rating
                - MIN(avg_player_rating) OVER ())
            / NULLIF(
                MAX(avg_player_rating) OVER ()
                - MIN(avg_player_rating) OVER (),
                0
            )
        ) * 100 AS norm_player_rating,

        (
            (avg_performance_score
                - MIN(avg_performance_score) OVER ())
            / NULLIF(
                MAX(avg_performance_score) OVER ()
                - MIN(avg_performance_score) OVER (),
                0
            )
        ) * 100 AS norm_performance_score,

        (
            (avg_tournament_rating
                - MIN(avg_tournament_rating) OVER ())
            / NULLIF(
                MAX(avg_tournament_rating) OVER ()
                - MIN(avg_tournament_rating) OVER (),
                0
            )
        ) * 100 AS norm_tournament_rating

    FROM per_90_metrics
),

scored_players AS (
    SELECT
        *,

        /* =============================================
           DEFENSIVE PERFORMANCE SCORE - 50%
           ============================================= */

        (
            COALESCE(norm_interceptions, 0) * 0.10 +
            COALESCE(norm_defensive_actions, 0) * 0.10 +
            COALESCE(norm_recoveries, 0) * 0.08 +
            COALESCE(norm_tackles, 0) * 0.08 +
            COALESCE(norm_blocks, 0) * 0.06 +
            COALESCE(norm_aerial_success, 0) * 0.08
        ) AS defensive_performance_score,


        /* =============================================
           DISCIPLINE SCORE - 10%
           ============================================= */

        (
            COALESCE(norm_fouls, 0) * 0.04 +
            COALESCE(norm_yellow_cards, 0) * 0.03 +
            COALESCE(norm_red_cards, 0) * 0.03
        ) AS discipline_score,


        /* =============================================
           POSSESSION / BALL PLAYING - 15%
           ============================================= */

        (
            COALESCE(norm_pass_success, 0) * 0.06 +
            COALESCE(norm_pressure_resistance, 0) * 0.05 +
            COALESCE(norm_possession_impact, 0) * 0.04
        ) AS possession_ball_playing_score,


        /* =============================================
           CONSISTENCY & TOURNAMENT PERFORMANCE - 25%
           ============================================= */

        (
            COALESCE(norm_consistency, 0) * 0.08 +
            COALESCE(norm_player_rating, 0) * 0.05 +
            COALESCE(norm_performance_score, 0) * 0.06 +
            COALESCE(norm_tournament_rating, 0) * 0.06
        ) AS consistency_tournament_score

    FROM normalized_metrics
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            (
                defensive_performance_score +
                discipline_score +
                possession_ball_playing_score +
                consistency_tournament_score
            ) DESC
    ) AS defender_rank,

    player_id,
    player_name,
    age,
    nationality,
    team,
    jersey_number,
    position,
    height_cm,
    weight_kg,
    preferred_foot,
    club_name,
    market_value_eur,

    total_minutes,

    /* Raw Defensive Stats */
    tackles,
    interceptions,
    blocks,
    recoveries,
    defensive_actions,
    clearances,
    aerial_duels_won,
    aerial_duels_lost,

    /* Per 90 Metrics */

    ROUND(tackles_per_90::NUMERIC, 2)
        AS tackles_per_90,

    ROUND(interceptions_per_90::NUMERIC, 2)
        AS interceptions_per_90,

    ROUND(blocks_per_90::NUMERIC, 2)
        AS blocks_per_90,

    ROUND(recoveries_per_90::NUMERIC, 2)
        AS recoveries_per_90,

    ROUND(defensive_actions_per_90::NUMERIC, 2)
        AS defensive_actions_per_90,

    ROUND(clearances_per_90::NUMERIC, 2)
        AS clearances_per_90,

    ROUND(aerial_duel_success_pct::NUMERIC, 2)
        AS aerial_duel_success_pct,

    /* Discipline */

    fouls_committed,
    yellow_cards,
    red_cards,

    ROUND(fouls_per_90::NUMERIC, 2)
        AS fouls_per_90,

    /* Ball Playing */

    ROUND(pass_success_pct::NUMERIC, 2)
        AS pass_success_pct,

    ROUND(avg_pass_accuracy::NUMERIC, 2)
        AS avg_pass_accuracy,

    ROUND(avg_pressure_resistance::NUMERIC, 2)
        AS pressure_resistance,

    ROUND(avg_possession_impact::NUMERIC, 2)
        AS possession_impact,

    /* Category Scores */

    ROUND(defensive_performance_score::NUMERIC, 2)
        AS defensive_performance_score,

    ROUND(discipline_score::NUMERIC, 2)
        AS discipline_score,

    ROUND(possession_ball_playing_score::NUMERIC, 2)
        AS possession_ball_playing_score,

    ROUND(consistency_tournament_score::NUMERIC, 2)
        AS consistency_tournament_score,

    /* Final Best Defender Index */

    ROUND(
        (
            defensive_performance_score +
            discipline_score +
            possession_ball_playing_score +
            consistency_tournament_score
        )::NUMERIC,
        2
    ) AS best_defender_index

FROM scored_players

ORDER BY
    best_defender_index ASC;
