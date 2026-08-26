# quarterfinal_results Table

## Overview
The `quarterfinal_results` table stores the results of knockout matches from the Quarterfinals stage in the World Cup dataset.  
It is generated from the `raw_player_performance` table, collapsing the two team perspectives into a single row per match.  
This table provides match outcomes, including goals scored by each team and the team that advanced to the Semi Finals.

---

## Table Structure
The `quarterfinal_results` table has the following columns:

| Column     | Type    | Description |
|------------|---------|-------------|
| `match_id` | VARCHAR | Unique identifier for the match. |
| `team_a`   | VARCHAR | First team in the fixture. |
| `team_b`   | VARCHAR | Second team in the fixture. |
| `goals_a`  | INT     | Goals scored by Team A. |
| `goals_b`  | INT     | Goals scored by Team B. |
| `advanced` | VARCHAR | The team that progressed to the Semi Finals. |

---

## Script Logic
1. Filters matches from `raw_player_performance` where `tournament_stage = 'Quarterfinals'`.  
2. Joins the two team perspectives for each match to avoid duplicate `match_id` entries.  
3. Collapses into one row per match using `DISTINCT ON (match_id)`.  
4. Determines the advancing team by checking which of the two teams appears in the `Semi Finals` stage.  
5. If Semi Finals data is not yet populated, falls back to goals comparison to decide the advancing team.  

---

## Usage Notes
- Run this script after populating `raw_player_performance` with Quarterfinal fixtures and Semi Final participants.  
- The output is a permanent `quarterfinal_results` table with one row per match.  
- Extendable: You can replicate this approach for later knockout stages (Semi Finals, Final) by changing the `tournament_stage` filter and adjusting the advancement check.
