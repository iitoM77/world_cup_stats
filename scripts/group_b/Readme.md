# Group_B Table

## Overview
The `Group_B` table stores the **log standings** for Group B in the World Cup dataset.  
It is generated from the `group_stage_results` and `tournament_groups` tables, calculating each team’s performance in the group stage.  
This table provides a snapshot of the group standings, including matches played, wins, draws, losses, goals, and points.

---

## Table Structure
The `Group_B` table has the following columns:

| Column            | Type    | Description |
|-------------------|---------|-------------|
| `team`            | VARCHAR | Team name (unique identifier). |
| `matches_played`  | INT     | Total matches played. |
| `wins`            | INT     | Number of matches won. |
| `draws`           | INT     | Number of matches drawn. |
| `losses`          | INT     | Number of matches lost. |
| `goals_scored`    | INT     | Total goals scored. |
| `goals_against`   | INT     | Total goals conceded. |
| `goal_difference` | INT     | Goals scored minus goals conceded. |
| `points`          | INT     | Tournament points (3 per win, 1 per draw). |

---

## Script Logic
1. **Extract Teams**: Pulls the four teams from `tournament_groups` where `Group = 'B'`.  
2. **Expand Matches**: For each fixture in `group_stage_results`, generates two rows (one per team) with goals scored/conceded and win/draw/loss flags.  
3. **Aggregate Stats**: Summarizes per team:
   - Matches played  
   - Wins, draws, losses  
   - Goals scored and conceded  
   - Goal difference  
   - Points (3 × wins + 1 × draws)  
4. **Insert into Group_B**: Results are inserted into the permanent `Group_B` table.
