# OCB Architecture Decision Records

## Purpose

This directory contains the Architecture Decision Records (ADRs) for the Osagyefo Central Bank Digital Financial Intelligence Platform (OCB Platform) v1.0.0.

ADRs provide a controlled record of consequential architectural decisions made during the design and implementation of the platform.

The purpose of an ADR is to preserve:

- the architectural problem or question;
- the context in which the decision was made;
- the alternatives considered;
- the decision reached;
- the consequences of the decision;
- the evidence supporting the decision;
- the relationship between the decision and the implemented platform.

ADRs provide architectural traceability without replacing the governing project documentation.

---

## 1. Relationship to Governing Documentation

The OCB documentation hierarchy remains:

```text
Master Project Document
        ↓
Project Charter
        ↓
Implementation & Engineering Specification
        ↓
Technical Build Guide
        ↓
Work Breakdown Structure
        ↓
Execution Backlog
        ↓
Implementation
        ↓
Validation Evidence
````

ADRs operate across this hierarchy as a controlled decision-record mechanism.

They do not replace or override the governing documents.

A governing document establishes the approved architecture, principles, scope, or construction requirements.

An ADR records a consequential decision made where implementation requires a specific architectural choice, interpretation, refinement, or justified deviation within the approved boundaries.

---

## 2. When an ADR Is Required

An ADR should be created when a decision has meaningful and lasting architectural consequences.

Examples include decisions concerning:

* system boundaries;
* data ownership;
* financial truth;
* transaction processing architecture;
* ledger design;
* state reconstruction;
* reliability mechanisms;
* analytical layer responsibilities;
* warehouse architecture;
* data modelling patterns;
* significant indexing or physical-design strategies;
* integration boundaries;
* identity abstraction;
* event-processing semantics;
* architectural trade-offs;
* significant technology choices;
* deliberate simplification of an architectural mechanism;
* justified deviation from an established implementation approach.

The decision should be recorded when failing to document it would make the architecture materially harder to understand, reproduce, review, or defend.

---

## 3. When an ADR Is Not Required

An ADR is generally unnecessary for routine implementation activity that does not create a consequential architectural decision.

Examples include:

* ordinary SQL implementation;
* routine query development;
* normal bug fixes;
* formatting changes;
* documentation corrections;
* routine index creation where the design is already established;
* ordinary refactoring that does not alter architectural behaviour;
* implementation details that are already determined by an existing governing decision.

An ADR must not be used merely to create documentation volume.

The objective is decision traceability, not documentation for its own sake.

---

## 4. ADR Authority

ADRs record decisions.

They do not independently establish project scope.

They must remain consistent with:

* the Project Charter;
* the Master Project Document;
* the Implementation & Engineering Specification;
* the Technical Build Guide;
* accepted architectural principles;
* the approved v1.0.0 scope.

An ADR must not silently introduce a capability that is outside the locked v1.0.0 scope.

Where a proposed decision would materially alter an established architectural commitment, the appropriate change-control process must be followed.

An ADR may document an approved change, but the ADR itself must not be treated as permission to bypass governance.

---

## 5. ADR Numbering

ADRs use sequential identifiers:

```text
ADR-0001
ADR-0002
ADR-0003
...
```

Numbers must not be reused.

Once an ADR has been assigned a number, that number remains associated with the decision record even if the decision is later superseded.

---

## 6. ADR Filename Convention

ADR files should use the following pattern:

```text
ADR-XXXX-short-descriptive-title.md
```

Example:

```text
ADR-0001-financial-event-source-of-truth.md
```

Filenames should:

* use lowercase descriptive text after the identifier;
* use hyphens between words;
* remain concise;
* describe the decision rather than the implementation task.

---

## 7. ADR Status

An ADR may use the following statuses:

### Proposed

The decision has been documented but has not yet been formally accepted.

### Accepted

The decision has been approved and forms part of the project's architectural decision record.

### Rejected

The proposed decision was considered and explicitly rejected.

### Superseded

The decision was previously accepted but has been replaced by a later ADR.

### Deprecated

The decision is no longer applicable, but remains historically relevant.

The status must reflect the actual state of the decision.

---

## 8. ADR Lifecycle

The general lifecycle is:

```text
Architectural Question
        ↓
Decision Analysis
        ↓
ADR Proposed
        ↓
Review
        ↓
Accepted / Rejected
        ↓
Implementation
        ↓
Validation Evidence
        ↓
Superseded / Deprecated
        ↓
Historical Record
```

Not every ADR will require every lifecycle stage.

The record must nevertheless preserve sufficient information to understand what happened and why.

---

## 9. Decision Scope

An ADR should answer a specific architectural question.

A decision should not be unnecessarily broad.

A strong ADR should make clear:

```text
Problem
   ↓
Context
   ↓
Options
   ↓
Decision
   ↓
Consequences
   ↓
Evidence
```

The decision should be sufficiently specific that another engineer can understand the architectural choice without relying on undocumented project history.

---

## 10. Alternatives

Where meaningful alternatives existed, they should be recorded.

The purpose is not to document every conceivable option.

The ADR should capture the credible alternatives that materially influenced the decision.

Where an alternative was rejected, the reason should be stated.

---

## 11. Consequences

ADRs must document meaningful consequences of the selected decision.

These may include:

* benefits;
* limitations;
* implementation complexity;
* operational consequences;
* analytical consequences;
* performance implications;
* maintenance implications;
* future migration implications;
* constraints imposed on later design decisions.

A decision should not be presented as universally optimal when it represents a trade-off.

---

## 12. Evidence

Where available, architectural decisions should reference supporting evidence.

Evidence may include:

* prototype results;
* SQL execution results;
* execution plans;
* performance measurements;
* reconciliation results;
* test results;
* data-model analysis;
* implementation constraints;
* documented requirements;
* accepted project requirements.

Evidence must not be invented to justify a decision.

Where evidence does not yet exist, the ADR should state that the decision is based on architectural reasoning or currently available requirements.

---

## 13. Implementation Relationship

An ADR records an architectural decision.

Implementation artefacts remain the authoritative evidence of what has actually been built.

Where relevant, an ADR may reference:

* SQL scripts;
* schemas;
* stored procedures;
* views;
* tables;
* tests;
* documentation;
* diagrams;
* repository paths;
* validation evidence.

The ADR must not claim that a decision has been implemented unless implementation evidence supports that claim.

---

## 14. Superseding Decisions

An accepted ADR may later be superseded when a new architectural decision replaces it.

The original ADR must remain in the repository.

Its status should be changed to:

```text
Superseded
```

The new ADR should identify the ADR it supersedes.

Historical architectural decisions must not be silently deleted.

---

## 15. ADR Review

ADRs should be reviewed when they:

* introduce a consequential architectural choice;
* materially affect another subsystem;
* change an established architectural boundary;
* create significant implementation consequences;
* introduce substantial complexity;
* alter an existing accepted decision.

The level of review should be proportional to the significance of the decision.

---

## 16. Architectural Consistency

Every ADR must be evaluated against the established OCB architectural principles.

In particular, decisions must preserve, where applicable:

* single source of financial truth;
* immutable financial history;
* explainable financial state;
* separation of responsibilities;
* analytical separation;
* financial/intelligence separation;
* institutional independence;
* sandbox observation boundaries;
* controlled identity abstraction;
* controlled complexity;
* evidence-based engineering.

An ADR must not be used to rationalize unnecessary technological complexity.

---

## 17. Fidelity and Scope

Where a decision concerns a capability that is simplified, abstracted, conceptual, deferred, or not implemented in v1.0.0, the ADR should make that boundary explicit.

The ADR must distinguish between:

```text
Implemented
Simplified
Observational
Conceptual
Deferred
Not Implemented
```

A conceptual architectural decision must not be represented as an implemented production capability.

---

## 18. Directory Structure

The ADR directory should remain simple:

```text
docs/
└── adrs/
    ├── README.md
    ├── adr-template.md
    ├── ADR-0001-example-decision.md
    ├── ADR-0002-example-decision.md
    └── ...
```

The example filenames above illustrate the convention only.

Actual ADR files should be created only when genuine architectural decisions require them.

---

## 19. ADR Quality Standard

A completed ADR should allow a technically competent reviewer to answer:

1. What problem required a decision?
2. What context existed at the time?
3. What alternatives were considered?
4. What was decided?
5. Why was it decided?
6. What are the consequences?
7. What evidence supports the decision?
8. What part of v1.0.0 does it affect?
9. Has the decision actually been implemented?
10. Has the decision subsequently been superseded?

If these questions cannot be answered, the ADR should be reviewed before being considered complete.

---

## 20. Core Principle

ADRs exist to preserve architectural reasoning.

They are not a substitute for:

* requirements;
* project governance;
* implementation documentation;
* the WBS;
* the Execution Backlog;
* testing evidence.

The purpose of the ADR system is to ensure that consequential architectural decisions remain visible, explainable, reviewable, and historically traceable.

**Document the decision. Preserve the reasoning. Implement within the approved architecture.**

````

