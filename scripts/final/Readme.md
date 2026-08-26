# final_result Table

## Overview
The `final_result` table stores the result of the Final Match in the World Cup dataset.  
It is generated from the `raw_player_performance` table, collapsing the two team perspectives into a single row per match.  
This table provides the match outcome, including goals scored by each team and the winner of the tournament.

---

## Table Structure
The `final_result` table has the following columns:

| Column     | Type    | Description |
|------------|---------|-------------|
| `match_id` | VARCHAR | Unique identifier for the match. |
| `team_a`   | VARCHAR | First team in the fixture. |
| `team_b`   | VARCHAR | Second team in the fixture. |
| `goals_a`  | INT     | Goals scored by Team A. |
| `goals_b`  | INT     | Goals scored by Team B. |
| `winner`   | VARCHAR | The team that won the Final and became Champion. |

---

## Script Logic
1. Filters matches from `raw_player_performance` where `tournament_stage = 'Final'`.  
2. Joins the two team perspectives for each match to avoid duplicate `match_id` entries.  
3. Collapses into one row per match using `DISTINCT ON (match_id)`.  
4. Determines the winner by comparing goals scored.  
5. If goals are equal, the result is marked as `TBD` (extendable for penalty shootouts if tracked).  

---

## Usage Notes
- Run this script after populating `raw_player_performance` with the Final Match fixture.  
- The output is a permanent `final_result` table with one row for the match.  
- This table identifies the **Champion** of the tournament.
