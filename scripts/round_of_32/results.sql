-- 1. Drop and recreate the round_of_32_results table
DROP TABLE IF EXISTS round_of_32_results;

CREATE TABLE round_of_32_results (
    match_id VARCHAR PRIMARY KEY,
    team_a VARCHAR NOT NULL,
    team_b VARCHAR NOT NULL,
    goals_a INT NOT NULL,
    goals_b INT NOT NULL,
    winner VARCHAR NOT NULL
);

-- 2. Insert Round of 32 results (one row per match)
INSERT INTO round_of_32_results (match_id, team_a, team_b, goals_a, goals_b, winner)
SELECT DISTINCT ON (rp1.match_id)
    rp1.match_id,
    rp1.team AS team_a,
    rp1.opponent_team AS team_b,
    rp1.goals_team AS goals_a,
    rp1.goals_opponent AS goals_b,
    CASE
        WHEN rp1.goals_team > rp1.goals_opponent THEN rp1.team
        WHEN rp1.goals_team < rp1.goals_opponent THEN rp1.opponent_team
        ELSE 'Draw'
    END AS winner
FROM raw_player_performance rp1
JOIN raw_player_performance rp2
  ON rp1.match_id = rp2.match_id
 AND rp1.team = rp2.opponent_team
 AND rp1.opponent_team = rp2.team
WHERE rp1.tournament_stage = 'Round of 32'
ORDER BY rp1.match_id, rp1.team;
