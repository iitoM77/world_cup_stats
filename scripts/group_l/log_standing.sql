-- 1. Drop and recreate the Group_L table
DROP TABLE IF EXISTS Group_L;

CREATE TABLE Group_L (
    team VARCHAR PRIMARY KEY,
    matches_played INT NOT NULL,
    wins INT NOT NULL,
    draws INT NOT NULL,
    losses INT NOT NULL,
    goals_scored INT NOT NULL,
    goals_against INT NOT NULL,
    goal_difference INT NOT NULL,
    points INT NOT NULL
);

-- 2. Insert Group L standings
WITH group_l AS (
    SELECT "Team 1" AS team FROM tournament_groups WHERE "Group" = 'L'
    UNION ALL
    SELECT "Team 2" FROM tournament_groups WHERE "Group" = 'L'
    UNION ALL
    SELECT "Team 3" FROM tournament_groups WHERE "Group" = 'L'
    UNION ALL
    SELECT "Team 4" FROM tournament_groups WHERE "Group" = 'L'
),
team_stats AS (
    SELECT
        team_a AS team,
        goals_a AS gs,
        goals_b AS ga,
        CASE WHEN goals_a > goals_b THEN 1 ELSE 0 END AS win,
        CASE WHEN goals_a < goals_b THEN 1 ELSE 0 END AS loss,
        CASE WHEN goals_a = goals_b THEN 1 ELSE 0 END AS draw
    FROM group_stage_results
    WHERE team_a IN (SELECT team FROM group_l)
      AND team_b IN (SELECT team FROM group_l)

    UNION ALL

    SELECT
        team_b AS team,
        goals_b AS gs,
        goals_a AS ga,
        CASE WHEN goals_b > goals_a THEN 1 ELSE 0 END AS win,
        CASE WHEN goals_b < goals_a THEN 1 ELSE 0 END AS loss,
        CASE WHEN goals_b = goals_a THEN 1 ELSE 0 END AS draw
    FROM group_stage_results
    WHERE team_a IN (SELECT team FROM group_l)
      AND team_b IN (SELECT team FROM group_l)
)
INSERT INTO Group_L (team, matches_played, wins, draws, losses, goals_scored, goals_against, goal_difference, points)
SELECT
    team,
    COUNT(*) AS matches_played,
    SUM(win) AS wins,
    SUM(draw) AS draws,
    SUM(loss) AS losses,
    SUM(gs) AS goals_scored,
    SUM(ga) AS goals_against,
    SUM(gs) - SUM(ga) AS goal_difference,
    SUM(win) * 3 + SUM(draw) AS points
FROM team_stats
GROUP BY team
ORDER BY points DESC, goal_difference DESC, goals_scored DESC;
