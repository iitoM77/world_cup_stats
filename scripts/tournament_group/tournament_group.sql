DROP TABLE IF EXISTS tournament_groups;

CREATE TABLE tournament_groups AS
WITH team_pairs AS (
    SELECT DISTINCT
        LEAST(team_a, team_b) AS team_1,
        GREATEST(team_a, team_b) AS team_2
    FROM group_stage_results
),

teams AS (
    SELECT team_1 AS team
    FROM team_pairs

    UNION

    SELECT team_2 AS team
    FROM team_pairs
),

four_team_groups AS (
    SELECT
        a.team AS team_1,
        b.team AS team_2,
        c.team AS team_3,
        d.team AS team_4

    FROM teams a

    JOIN teams b
        ON a.team < b.team

    JOIN teams c
        ON b.team < c.team

    JOIN teams d
        ON c.team < d.team

    JOIN team_pairs p12
        ON p12.team_1 = a.team
       AND p12.team_2 = b.team

    JOIN team_pairs p13
        ON p13.team_1 = a.team
       AND p13.team_2 = c.team

    JOIN team_pairs p14
        ON p14.team_1 = a.team
       AND p14.team_2 = d.team

    JOIN team_pairs p23
        ON p23.team_1 = b.team
       AND p23.team_2 = c.team

    JOIN team_pairs p24
        ON p24.team_1 = b.team
       AND p24.team_2 = d.team

    JOIN team_pairs p34
        ON p34.team_1 = c.team
       AND p34.team_2 = d.team
),

numbered_groups AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY team_1, team_2, team_3, team_4
        ) AS group_number,
        team_1,
        team_2,
        team_3,
        team_4
    FROM four_team_groups
)

SELECT
    CHR((64 + group_number)::integer) AS "Group",
    team_1 AS "Team 1",
    team_2 AS "Team 2",
    team_3 AS "Team 3",
    team_4 AS "Team 4"
FROM numbered_groups
WHERE group_number <= 12;
