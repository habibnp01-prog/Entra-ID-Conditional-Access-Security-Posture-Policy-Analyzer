# Findings Reference

| ID | Severity | Name |
|----|----------|------|
| CA-001 | High | Enabled policy with no assigned users or groups |
| CA-002 | Medium | Excluded groups in Conditional Access policy |
| CA-003 | Critical | Privileged roles not covered by MFA-requiring policy |
| CA-004 | High | Break-glass account not properly excluded |
| CA-005 | Medium | Wide exclusion group (>20 members) |
| CA-006 | High | No enabled policy blocks legacy authentication |
| CA-007 | Critical | Insufficient or absent CA enforcement |
| CA-008 | Medium | Conflicting Conditional Access policies |
| CA-009 | Low | Admin policy uses weak authentication strength |
| CA-010 | Medium | Named location used in policy requires review |

## Scoring Impact

Each unique finding ID deducts a fixed number of points from the tenant score:

| Severity | Points per Finding |
|----------|-------------------|
| Critical | 30 |
| High | 15 |
| Medium | 7 |
| Low | 2 |

Repeated instances of the same finding ID do **not** compound the penalty.

## Score Bands

| Score | Band |
|-------|------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Fair |
| 40-59 | Poor |
| 0-39 | Critical |
