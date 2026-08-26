# round_of_32_results Table

## Overview
The `round_of_32_results` table stores the results of knockout matches from the Round of 32 stage in the World Cup dataset.  
It is generated from the `raw_player_performance` table, collapsing the two team perspectives into a single row per match.  
This table provides match outcomes, including goals scored by each team and the winner.

---

## Table Structure
The `round_of_32_results` table has the following columns:

| Column     | Type    | Description |
|------------|---------|-------------|
| `match_id` | VARCHAR | Unique identifier for the match. |
| `team_a`   | VARCHAR | First team in the fixture. |
| `team_b`   | VARCHAR | Second team in the fixture. |
| `goals_a`  | INT     | Goals scored by Team A. |
| `goals_b`  | INT     | Goals scored by Team B. |
| `winner`   | VARCHAR | Match winner (Team A, Team B, or 'Draw'). |

---

## Script Logic
1. Filters matches from `raw_player_performance` where `tournament_stage = 'Round of 32'`.  
2. Joins the two team perspectives for each match to avoid duplicate `match_id` entries.  
3. Collapses into one row per match using `DISTINCT ON (match_id)`.  
4. Determines the winner by comparing goals scored.  
   - If goals are equal, the result is marked as `Draw` (extendable for penalties/extra time).  
5. Inserts the results into the permanent `round_of_32_results` table.

---

## Usage Notes
- Run this script after populating `raw_player_performance` with Round of 32 fixtures.  
- The output is a permanent `round_of_32_results` table with one row per match.  
- Extendable: You can replicate this approach for other knockout stages (Round of 16, Quarterfinals, Semifinals, Final) by changing the `tournament_stage` filter.
