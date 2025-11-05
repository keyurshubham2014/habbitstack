# Task 27: AI Insights Screen

**Status**: TODO
**Priority**: HIGH
**Estimated Time**: 4 hours
**Assigned To**: Claude
**Dependencies**: Task 26 (OpenRouter Setup)
**Completed**: -

---

## Objective

Build an AI-powered insights screen that analyzes user's habit data and provides personalized recommendations, pattern recognition, and predictive alerts.

## Acceptance Criteria

- [ ] Insights screen shows AI-generated analysis
- [ ] Weekly insights summary
- [ ] Pattern recognition (best times, success factors)
- [ ] Predictive alerts (likely skip days)
- [ ] Personalized recommendations
- [ ] Refresh to generate new insights
- [ ] Premium feature (paywall for non-premium)
- [ ] Loading states during AI generation
- [ ] Insights save to database (cache)

---

## Implementation Summary

### Key Components:
1. **Insights Model** - Store AI-generated insights
2. **Insights Service** - Generate insights via OpenRouter
3. **Insights Screen** - Display formatted insights
4. **Cache System** - Store insights for 7 days

### Insight Types:
- **Weekly Summary**: Overall progress and highlights
- **Pattern Recognition**: Optimal times, success factors
- **Predictions**: Days likely to skip, streaks at risk
- **Recommendations**: Specific actionable advice

---

## Quick Implementation Guide

See full implementation in task file for:
- Complete models and services
- UI components and screens
- Prompt engineering for Claude
- Caching and optimization
- Testing scenarios

---

## Next Task

After completion, proceed to: [28_pattern_analysis.md](./28_pattern_analysis.md)

---

**Last Updated**: 2025-11-05
