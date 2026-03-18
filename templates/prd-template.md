# PRD: [Feature Name]

## Overview

[One paragraph describing the feature and its purpose]

## Goals

- **Primary goal:** [What this must achieve]
- **Secondary goals:** [Nice to have outcomes]

## Non-Goals (Out of Scope)

- [Explicitly what we're NOT doing]
- [Things that might seem related but aren't included]

## User Stories

### US-1: [Story Title]

**As a** [user type]
**I want** [action]
**So that** [benefit]

**Acceptance Criteria:**

- [ ] Given [context], when [action], then [expected result]
- [ ] Given [context], when [action], then [expected result]

**How to Test:**

- Manual: [Steps to verify manually]
- Automated: [What the test should check]

**Priority:** [1-5, where 1 is highest]

---

### US-2: [Story Title]

**As a** [user type]
**I want** [action]
**So that** [benefit]

**Acceptance Criteria:**

- [ ] Given [context], when [action], then [expected result]
- [ ] Given [context], when [action], then [expected result]

**How to Test:**

- Manual: [Steps to verify manually]
- Automated: [What the test should check]

**Priority:** [1-5]

---

## Technical Approach

[High-level approach, key architectural decisions]

## Dependencies

- [What must exist before this can be built]
- [External services or APIs needed]

## Success Metrics

- [How we'll measure if this worked]
- [Quantifiable criteria where possible]

## Constraints

- **Performance:** [e.g. Must respond within 200ms, handle 1000 concurrent users] — why: [user experience, SLA]
- **Security:** [e.g. All inputs sanitised, no secrets in logs, OWASP top 10] — why: [compliance, trust]
- **Dependencies:** [e.g. No new runtime dependencies, must work with Python 3.11+] — why: [deployment stability]
- **API shape:** [e.g. Must follow existing REST conventions, backwards compatible] — why: [client compatibility]
- **Style:** [e.g. Follow existing patterns in src/api/, max 100 line functions] — why: [maintainability]

## Verification Plan

- [ ] **Demo scenario:** [Walk through the primary user flow end-to-end]
- [ ] **Automated test results:** [Link to passing CI run, summary of new test coverage]
- [ ] **Manual checks:** [Specific things to verify by hand that automated tests cannot cover]
- [ ] **Stakeholder review:** [Who needs to sign off and what they should look at]
- [ ] **Edge cases tested:** [Boundary conditions verified manually or via tests]

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [How to address] |

## Open Questions

- [ ] [Question that needs answering before/during implementation]
