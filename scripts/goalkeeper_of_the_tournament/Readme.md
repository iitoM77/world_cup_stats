# Goalkeeper Tournament Analytics

## Overview  
It aggregates match‑level performance data for goalkeepers in a soccer tournament, computes per‑90 metrics, applies percentile rankings, and produces a weighted overall score to rank the best performing goalkeepers.

---

## Source Data
- Table: `raw_player_performance`  
- Filter: Only rows where `position` is goalkeeper (`'gk'`, `'goalkeeper'`, `'keeper'`) and `minutes_played > 0`.

---

## Pipeline Steps
The view is built using several CTEs:

1. `goalkeeper_matches` → Filters raw player data to goalkeeper appearances.  
2. `team_tournament_stage` → Determines the highest stage reached by each team.  
3. `qualified_teams` → Keeps only teams that reached at least the semi‑finals.  
4. `tournament_agg` → Aggregates goalkeeper stats across matches.  
5. `rates` → Normalizes stats per 90 minutes and calculates rates.  
6. `ranked` → Applies percentile ranks (`PERCENT_RANK()`) to each metric.  
7. `component_scores` → Combines metrics into weighted component scores:
   - Shot Stopping  
   - Defensive Command  
   - Distribution  
   - Big Moments  
   - Tournament Rating  
8. `final_scores` → Produces a weighted overall goalkeeper score.

---

## Output Columns
The final view returns:
- `gk_rank` → Rank of goalkeeper (1 = best)  
- Player info: `player_id`, `player_name`, `team`  
- Tournament stats: `appearances`, `total_minutes`, `total_saves`, `clean_sheets`, `goals_conceded`, etc.  
- Per‑90 metrics: `saves_per_90`, `goals_conceded_per_90`, `recoveries_per_90`, etc.  
- Rates: `clean_sheet_rate_pct`, `aerial_duel_win_rate_pct`, `pass_accuracy`  
- Component scores: `shot_stopping_score`, `defensive_command_score`, `distribution_score`, `big_moments_score`, `tournament_rating_score`  
- `overall_gk_score` → Final weighted score used for ranking.

---

## Integration with Tableau
- Connect Tableau to your PostgreSQL database.  
- Use `goalkeeper_tournament_analytics` as the data source.  
- Build a dashboard card showing the best goalkeeper (filter `gk_rank = 1`).  
- Extend to show top performers or compare across metrics.

---

## Notes
- Minimum threshold: Goalkeepers must have played at least 300 minutes to be included.
- players' team must also have reached the semis to be eligible
- Percentile values are cast to `NUMERIC` before rounding to avoid type errors.  
- Rankings are based on weighted scores, not raw totals.  
