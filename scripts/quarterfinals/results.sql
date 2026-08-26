-- 1. Drop and recreate the quarterfinal_results table
DROP TABLE IF EXISTS quarterfinal_results;

CREATE TABLE quarterfinal_results (
    match_id VARCHAR PRIMARY KEY,
    team_a VARCHAR NOT NULL,
    team_b VARCHAR NOT NULL,
    goals_a INT NOT NULL,
    goals_b INT NOT NULL,
    advanced VARCHAR NOT NULL
);

-- 2. Insert Quarterfinal results with 'advanced' team
INSERT INTO quarterfinal_results (match_id, team_a, team_b, goals_a, goals_b, advanced)
SELECT DISTINCT ON (rp1.match_id)
    rp1.match_id,
    rp1.team AS team_a,
    rp1.opponent_team AS team_b,
    rp1.goals_team AS goals_a,
    rp1.goals_opponent AS goals_b,
    -- Determine which team advanced by checking who appears in Semi Finals
    CASE
        WHEN sf.team IS NOT NULL THEN sf.team
        ELSE CASE
            WHEN rp1.goals_team > rp1.goals_opponent THEN rp1.team
            WHEN rp1.goals_team < rp1.goals_opponent THEN rp1.opponent_team
            ELSE 'TBD'
        END
    END AS advanced
FROM raw_player_performance rp1
JOIN raw_player_performance rp2
  ON rp1.match_id = rp2.match_id
 AND rp1.team = rp2.opponent_team
 AND rp1.opponent_team = rp2.team
LEFT JOIN (
    SELECT DISTINCT team
    FROM raw_player_performance
    WHERE tournament_stage = 'Semi Finals'
) sf
  ON sf.team = rp1.team OR sf.team = rp1.opponent_team
WHERE rp1.tournament_stage = 'Quarter Finals'
ORDER BY rp1.match_id, rp1.team;
