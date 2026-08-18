# OCB Documentation Baseline

## Purpose

This document records the controlled documentation baseline for OCB Platform v1.0.0 and identifies where each document is maintained within the repository.

The repository must distinguish between established project baselines, living implementation documentation, validation evidence, and future documentation.

## Governing Documentation

| Document | Repository Location | Status | Role |
|---|---|---|---|
| Master Project Document | `docs/governance/master_project_document.md` | Baseline | Defines what OCB is |
| Project Charter | `docs/governance/project_charter.md` | Locked | Defines what is locked for v1.0.0 |
| Implementation & Engineering Specification | `docs/governance/implementation_engineering_specification.md` | Locked Baseline | Defines how OCB is engineered |
| Technical Build Guide | `docs/governance/technical_build_guide.md` | Baseline | Defines the construction sequence |
| Work Breakdown Structure | `docs/execution/wbs.md` | Execution Baseline | Defines the executable engineering work |

## Supporting Documentation

| Document | Repository Location | Status |
|---|---|---|
| Architecture Decision Records | `docs/adr/` | Living |
| Business Glossary | `docs/glossary/` | Build-Time |
| Data Dictionary | `docs/data_dictionary/` | Build-Time |
| Testing & Validation Handbook | `docs/testing/` | Living |
| Developer Guide | `docs/developer/` | Living |
| User & Demonstration Guide | `docs/user/` | Build-Time |
| Future Architecture | `docs/future_architecture/` | Future |
| Repository Naming Conventions | `docs/repository_naming_conventions.md` | Baseline |

## Documentation Principle

Documentation is an engineering deliverable. It must reflect the architecture and implementation actually established by the project.

Foundational documents should not be repeatedly rewritten merely because implementation has not yet reached completion. Where implementation materially changes an established architectural decision, the affected documentation must be reviewed and updated through the appropriate governance process.

Implementation-specific details should be added when they become known rather than being invented during the foundation phase.