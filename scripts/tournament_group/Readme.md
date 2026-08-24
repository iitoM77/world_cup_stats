# tournament_groups Table

## Overview
The `tournament_groups` table is generated from the **group_stage_results** data.  
It reconstructs the World Cup group classifications by identifying sets of **four teams** that all played each other in the group stage.  
This ensures each group (A–L) contains exactly four teams, matching the tournament format.

---

## Table Structure
The `tournament_groups` table has the following columns:

| Column   | Type    | Description |
|----------|---------|-------------|
| `Group`  | VARCHAR | Alphabetical group label (A–L). |
| `Team 1` | VARCHAR | First team in the group. |
| `Team 2` | VARCHAR | Second team in the group. |
| `Team 3` | VARCHAR | Third team in the group. |
| `Team 4` | VARCHAR | Fourth team in the group. |

---

## Script Logic
1. **Team Pairs**: Extracts all unique team matchups from `group_stage_results`.  
2. **Teams**: Collects all distinct teams from those pairs.  
3. **Four‑Team Groups**: Builds candidate groups by joining teams together and checking that all six possible pairings exist (ensuring they all played each other).  
4. **Numbered Groups**: Assigns a sequential number to each valid group.  
5. **Final Output**: Converts group numbers into alphabetical labels (`Group A`, `Group B`, …) and selects the first 12 groups.
