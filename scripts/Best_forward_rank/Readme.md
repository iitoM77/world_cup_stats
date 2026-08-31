# Best Forward Index

A comprehensive SQL ranking system that identifies and ranks the best forwards from tournament semi-finalists based on multi-dimensional performance metrics.

## Overview

This project provides a sophisticated SQL view that ranks forwards (ST, LW, RW) from teams that reached the tournament's final stages. The ranking system uses a weighted scoring methodology with percentile-based normalization to evaluate forwards across multiple performance dimensions.

## Features

### Multi-Dimensional Scoring System

The ranking evaluates forwards across five key performance categories:

| Category | Weight | Metrics Included |
|----------|--------|------------------|
| **Goal Threat & Finishing** | 35% | Goals, Expected Goals, Shots on Target, Finishing Efficiency |
| **Consistency & Tournament Performance** | 20% | Player Rating, Performance Score, Consistency, Tournament Rating |
| **Creativity & Chance Creation** | 20% | Assists, Expected Assists, Key Passes |
| **Dribbling & Progression** | 15% | Successful Dribbles, Dribble Success Rate, Fouls Suffered, Possession Impact, Pressure Resistance |
| **Clutch & Big Game Performance** | 10% | Clutch Performance Score, Player of Match Awards |

### Data Processing Pipeline

The view processes data through multiple CTEs:

1. **player_tournament_stats**: Aggregates player statistics and identifies forward positions
2. **eligible_players**: Filters players with minimum 300 minutes played who reached semi-finals or beyond
3. **per_90_metrics**: Calculates per-90-minute rates and efficiency ratios
4. **normalized_metrics**: Applies percentile ranking for all metrics
5. **category_scores**: Calculates weighted category indexes
6. **final_index**: Computes the final forward index score

### Key Metrics Calculated

- **Goal Scoring**: Goals, expected goals, shots, shots on target per 90 minutes
- **Finishing Efficiency**: Goal conversion rate from shots
- **Chance Creation**: Assists, expected assists, key passes per 90 minutes
- **Dribbling**: Successful dribbles, dribble success rate, fouls suffered per 90 minutes
- **Ball Progression**: Possession impact, pressure resistance
- **Tournament Performance**: Average ratings, consistency, and clutch performance

