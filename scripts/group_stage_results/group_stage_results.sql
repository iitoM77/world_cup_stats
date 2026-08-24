INSERT INTO group_stage_results (match_id, team_a, team_b, goals_a, goals_b, final_score, match_result)
SELECT DISTINCT ON (rp1.match_id)
    rp1.match_id,
    rp1.team AS team_a,
    rp1.opponent_team AS team_b,
    rp1.goals_team AS goals_a,
    rp1.goals_opponent AS goals_b,
    CONCAT(rp1.goals_team, '-', rp1.goals_opponent) AS final_score,
    CASE
        WHEN rp1.goals_team > rp1.goals_opponent THEN rp1.team
        WHEN rp1.goals_team < rp1.goals_opponent THEN rp1.opponent_team
        ELSE 'Draw'
    END AS match_result
FROM raw_player_performance rp1
JOIN raw_player_performance rp2
  ON rp1.match_id = rp2.match_id
 AND rp1.team = rp2.opponent_team
 AND rp1.opponent_team = rp2.team
WHERE rp1.tournament_stage = 'Group Stage'
ORDER BY rp1.match_id, rp1.team;
