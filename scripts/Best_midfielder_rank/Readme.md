# Best Midfielder Tournament Index

A comprehensive SQL ranking system that identifies and ranks the best midfielders from tournament semi-finalists based on multi-dimensional performance metrics.

## Overview

This project provides a sophisticated SQL view that ranks midfielders (CM, CDM, AM, LM, RM) from teams that reached the tournament's final stages. The ranking system uses a weighted scoring methodology with percentile-based normalization to evaluate midfielders across multiple performance dimensions.

## Features

### Multi-Dimensional Scoring System

The ranking evaluates midfielders across six key performance categories:

| Category | Weight | Metrics Included |
|----------|--------|------------------|
| **Possession & Ball Progression** | 25% | Successful Passes, Pass Accuracy, Possession Impact, Pressure Resistance, Dribbles |
| **Creativity & Chance Creation** | 20% | Assists, Expected Assists, Key Passes, Creativity Score |
| **Defensive Contribution** | 20% | Tackles, Interceptions, Recoveries, Defensive Actions, Defensive Contribution Score |
| **Consistency & Tournament Performance** | 15% | Consistency, Clutch Performance, Player Rating, Performance Score, Tournament Rating, Player of Match Awards |
| **Goal Threat** | 10% | Goals, Expected Goals, Shots on Target, Offensive Contribution |
| **Discipline** | 10% | Fouls Committed, Yellow Cards, Red Cards (inverted scoring) |

### Data Processing Pipeline

The view processes data through multiple CTEs:

1. **qualified_players**: Aggregates player statistics and identifies midfielder positions
2. **eligible**: Filters players with minimum 300 minutes played who reached semi-finals or beyond
3. **per90**: Calculates per-90-minute rates for fair comparison
4. **normalized**: Applies percentile ranking for all metrics
5. **scored**: Calculates weighted category scores
6. **final_scores**: Computes the final midfielder index

### Key Metrics Calculated

- **Attacking Output**: Goals, assists, expected goals, expected assists per 90 minutes
- **Chance Creation**: Key passes, creativity score, offensive contribution
- **Ball Progression**: Pass accuracy, successful dribbles, possession impact
- **Defensive Work**: Tackles, interceptions, recoveries, defensive actions per 90 minutes
- **Discipline**: Fouls and cards per 90 minutes (lower is better)
- **Tournament Performance**: Average ratings, consistency, and clutch performance
