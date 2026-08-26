# third_place_result Table

## Overview
The `third_place_result` table stores the result of the Third Place Match in the World Cup dataset.  
It is generated from the `raw_player_performance` table, collapsing the two team perspectives into a single row per match.  
This table provides the match outcome, including goals scored by each team and the winner of the match.

---

## Table Structure
The `third_place_result` table has the following columns:

| Column     | Type    | Description |
|------------|---------|-------------|
| `match_id` | VARCHAR | Unique identifier for the match. |
| `team_a`   | VARCHAR | First team in the fixture. |
| `team_b`   | VARCHAR | Second team in the fixture. |
| `goals_a`  | INT     | Goals scored by Team A. |
| `goals_b`  | INT     | Goals scored by Team B. |
| `winner`   | VARCHAR | The team that won the Third Place Match. |

---

## Script Logic
1. Filters matches from `raw_player_performance` where `tournament_stage = 'Third Place'`.  
2. Joins the two team perspectives for each match to avoid duplicate `match_id` entries.  
3. Collapses into one row per match using `DISTINCT ON (match_id)`.  
4. Determines the winner by comparing goals scored.  
5. If goals are equal, the result is marked as `TBD` (extendable for penalty shootouts if tracked).  

---

## Usage Notes
- Run this script after populating `raw_player_performance` with the Third Place Match fixture.  
- The output is a permanent `third_place_result` table with one row for the match.  
- Extendable: You can replicate this approach for the Final stage, adjusting the logic to identify the Champion.
