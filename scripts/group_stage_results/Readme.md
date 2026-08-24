# group_stage_results Script

## 📌 Overview
The `group_stage_results` script populates the **group_stage_results** table with match outcomes from the **raw_player_performance** dataset.  
It extracts only **Group Stage matches** from the tournament, ensuring each fixture is represented once with the correct teams, scores, and result.

---

## 🗂 Table Structure
The `group_stage_results` table has the following columns:

| Column        | Type    | Description |
|---------------|---------|-------------|
| `match_id`    | VARCHAR | Unique identifier for each match (e.g., `WC26-001`). |
| `team_a`      | VARCHAR | The first team in the fixture. |
| `team_b`      | VARCHAR | The opponent team. |
| `goals_a`     | INT     | Goals scored by `team_a`. |
| `goals_b`     | INT     | Goals scored by `team_b`. |
| `final_score` | VARCHAR | Scoreline in `X-Y` format. |
| `match_result`| VARCHAR | Winner of the match or `Draw`. |

---

## ⚙️ Script Logic
1. **Source Data**: Reads from `raw_player_performance`.  
2. **Filter**: Only includes rows where `tournament_stage = 'Group Stage'`.  
3. **Deduplication**: Each match appears twice (once per team perspective). The query collapses them into a single row per `match_id`.  
4. **Result Calculation**:  
   - If `goals_team > goals_opponent` → `team` wins.  
   - If `goals_team < goals_opponent` → `opponent_team` wins.  
   - If equal → `Draw`.  
