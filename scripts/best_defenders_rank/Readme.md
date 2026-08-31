# Best Defenders Tournament Ranking

A comprehensive SQL ranking system that identifies and ranks the best defenders from tournament semi-finalists based on multi-dimensional performance metrics.

## Overview

This ranks defenders (RB, LB, CB) from teams that reached the tournament's final stages. The ranking system uses a weighted scoring methodology to evaluate defenders across multiple performance dimensions, normalized to per-90-minute metrics for fair comparison.

## Features

### Multi-Dimensional Scoring System

The ranking evaluates defenders across four key performance categories:

| Category | Weight | Metrics Included |
|----------|--------|------------------|
| **Defensive Performance** | 50% | Interceptions, Defensive Actions, Recoveries, Tackles, Blocks, Aerial Duels |
| **Consistency & Tournament Performance** | 25% | Consistency Score, Player Rating, Performance Score, Tournament Rating |
| **Possession & Ball Playing** | 15% | Pass Success, Pressure Resistance, Possession Impact |
| **Discipline** | 10% | Fouls, Yellow Cards, Red Cards (inverted scoring) |

###  Data Processing Pipeline

The view processes data through multiple CTEs:

1. **semifinal_teams**: Filters teams that reached Semi Finals or beyond
2. **player_tournament_stats**: Aggregates player statistics across the tournament
3. **qualified_players**: Filters players with minimum 300 minutes played
4. **per_90_metrics**: Calculates per-90-minute rates for fair comparison
5. **normalized_metrics**: Normalizes all metrics to 0-100 scale
6. **scored_players**: Applies weighted scoring system

### Key Metrics Calculated

- **Defensive Stats**: Tackles, interceptions, blocks, recoveries, clearances per 90 minutes
- **Aerial Performance**: Aerial duel success percentage
- **Discipline**: Fouls and cards per 90 minutes (lower is better)
- **Ball Playing**: Pass accuracy, pressure resistance, possession impact
- **Tournament Performance**: Average ratings and consistency scores
