# Group_C Table

## Overview
The `Group_C` table stores the standings for Group C in the World Cup dataset.  
It is generated from the `group_stage_results` and `tournament_groups` tables, calculating each team’s performance in the group stage.  
This table provides a snapshot of the group standings, including matches played, wins, draws, losses, goals, and points.

---

## Table Structure
The `Group_C` table has the following columns:

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
1. Extracts the four teams from `tournament_groups` where `Group = 'C'`.  
2. Expands each fixture in `group_stage_results` into two rows (one per team) with goals scored/conceded and win/draw/loss flags.  
3. Aggregates per team to calculate:
   - Matches played  
   - Wins, draws, losses  
   - Goals scored and conceded  
   - Goal difference  
   - Points (3 × wins + 1 × draws)  
4. Inserts the aggregated results into the permanent `Group_C` table.

---

## Common Issues
- **Empty Table**: Ensure `tournament_groups` has Group C populated before running.  
- **Duplicate Matches**: The query expands each match into two rows, so aggregation is required to avoid duplicates.  
- **Ranking**: The final ordering ensures FIFA‑style ranking (points → goal difference → goals scored).

---

## Usage Notes
- Run this script after populating `group_stage_results` and `tournament_groups`.  
- The output is a permanent `Group_C` table with standings.  
- Extendable: You can replicate this script for other groups (D–L) by changing the group filter in the CTE.
