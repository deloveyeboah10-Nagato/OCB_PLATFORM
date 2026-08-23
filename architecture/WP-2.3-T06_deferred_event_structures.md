**Programme:** OCB Platform v1.0.0

**Work Package:** WP-2.3 — Operational Schema Design

**Ticket:** WP-2.3-T06

**Status:** **APPROVED**

**Decision Type:** Integration and deferred-event boundary

---

# 1. Purpose

This ticket defines the physical-schema boundary for integration-related and deferred-event information within the OCB Platform v1.0.0.

The purpose is to establish what integration structures are required, what is explicitly deferred, and how the platform represents externally originated or institutionally observed information without introducing production integration infrastructure that is outside the approved v1.0.0 scope.

The design must preserve:

* institutional independence;
* source ownership;
* OCB observation boundaries;
* financial-event authority;
* provenance;
* the distinction between observed information and implemented integration;
* the deferred status of production connectivity and external financial infrastructure.

---

# 2. Integration Boundary

The OCB Platform v1.0.0 does not implement production-grade institutional integration.

The platform does not introduce:

* APIs;
* message brokers;
* streaming infrastructure;
* SWIFT connectivity;
* payment-network connectivity;
* real-time institutional feeds;
* external settlement infrastructure;
* direct institutional system connectivity.

These capabilities remain outside the v1.0.0 implementation boundary.

The simulated institutional domains remain independently operated conceptual sources:

```text
ANANSE TELECOM
SIKACREDIT
OMAN REMIT
```

OCB receives or represents information within the approved sandbox observation boundary without modelling the production mechanism through which that information would be exchanged.

---

# 3. Deferred Integration Principle

The absence of production integration infrastructure does not prevent the platform from representing information that is conceptually observable from an institutional source.

The distinction is:

```text
Institutional Source
        ↓
Observable Information
        ↓
OCB Platform
```

rather than:

```text
Institutional Source
        ↓
Production API / Network / Stream
        ↓
OCB Platform
```

The second architecture is explicitly outside v1.0.0.

Therefore, the platform models the **observable data boundary**, not the production integration mechanism.

---

# 4. No Dedicated Integration Schema

No dedicated SQL Server schema such as:

```text
integration
external
api
network
settlement
```

will be introduced for v1.0.0.

The existing schema architecture remains:

```text
ocb
ananse
sikacredit
oman_remit
wallet
ledger
ref
```

This prevents the physical database from implying capabilities that the platform does not actually implement.

---

# 5. No Production Integration Tables

The platform will not create tables representing:

* API messages;
* API endpoints;
* message queues;
* streaming events;
* SWIFT messages;
* payment-network messages;
* external settlement instructions;
* correspondent-bank messages;
* production integration sessions;
* institutional connection states.

Such structures would represent implementation of capabilities explicitly deferred from v1.0.0.

Their absence is therefore deliberate.

---

# 6. Deferred-Event Boundary

A deferred event is not automatically a new financial-event type.

The approved financial-event catalogue remains authoritative.

If an event is recognised within the v1.0.0 financial model, it must be represented according to the established financial-event architecture regardless of whether its conceptual origin is internal or externally observable.

For example:

```text
OMAN REMIT
Remittance
     ↓
Observable to OCB
     ↓
OCB financial-event representation
```

does not require:

```text
external.remittance_message
```

or:

```text
integration.remittance_feed
```

The event remains an Oman Remit-owned financial event.

---

# 7. Source Ownership Remains Intact

Information observed from an external or institutional source does not become OCB-owned merely because it is represented within the OCB database.

The ownership distinction remains:

```text
SOURCE INSTITUTION
        ↓
SOURCE-OWNED EVENT / ENTITY
        ↓
OBSERVABLE INFORMATION
        ↓
OCB REPRESENTATION
```

OCB may use the information for identity resolution, financial analysis and regulatory intelligence.

It does not acquire operational ownership of the source event or source financial state.

---

# 8. Provenance Requirement

Where externally originated or institutionally sourced information is represented within the platform, the platform must preserve sufficient provenance to establish where the information originated and when it was observed or ingested.

The provenance model established by the broader platform architecture remains applicable.

Relevant provenance concepts include:

* source system;
* source identifier;
* batch identifier;
* extraction timestamp;
* ingestion timestamp;
* event timestamp;
* schema version;
* ingestion status.

These attributes describe the lineage of information entering the analytical environment.

They do not constitute production integration infrastructure.

---

# 9. Observation Does Not Equal Integration

The platform must distinguish:

| Concept                     | Meaning                                                                      |
| --------------------------- | ---------------------------------------------------------------------------- |
| **Source activity**         | Activity owned by an institutional domain                                    |
| **Observable information**  | Information made available to OCB within the approved observation boundary   |
| **Ingestion**               | The controlled representation of information within the OCB data environment |
| **Integration**             | A production mechanism through which systems exchange information            |
| **Analytical relationship** | An OCB relationship established from observable information                  |

Therefore:

> **The presence of institutionally sourced information in the OCB database does not imply that production institutional integration has been implemented.**

---

# 10. External Financial Infrastructure

The v1.0.0 platform does not model external financial infrastructure that is outside the approved institutional boundary.

This includes:

* correspondent institutions;
* external banks;
* settlement banks;
* escrow structures;
* payment networks;
* SWIFT;
* PAPSS;
* CIPS;
* external clearing infrastructure;
* external settlement infrastructure.

Such structures may be relevant to real-world financial systems, but introducing them into the v1.0.0 operational schema would create unsupported institutional architecture.

---

# 11. Oman Remit Boundary

The Oman Remit domain provides the clearest example of this boundary.

The platform may represent:

```text
OMAN REMIT
    ↓
Remittance
    ↓
Observable financial information
    ↓
OCB analysis
```

The platform does not attempt to model:

```text
Oman Remit
    ↓
Correspondent Bank
    ↓
SWIFT / Payment Network
    ↓
Settlement Bank
    ↓
Beneficiary Institution
```

unless a future approved architectural requirement explicitly introduces such structures.

The remittance event remains authoritative within the Oman Remit domain.

---

# 12. Deferred Capability Principle

Deferred capabilities must remain explicitly deferred rather than being partially simulated through misleading database structures.

The platform therefore follows:

```text
Required for v1.0.0
        ↓
Implement

Relevant but outside scope
        ↓
Represent boundary / defer

Unsupported or unjustified
        ↓
Do not model
```

This prevents the database from acquiring artificial complexity merely to create the appearance of institutional integration.

---

# 13. Relationship to Financial Events

T06 does not alter the financial-event model established in WP-1.3 and operationalised through WP-2.3.

A financial event remains:

```text
Institutional Activity
        ↓
Financial Event
        ↓
Outcome
        ↓
Financial Consequence
        ↓
Financial State
```

Integration is not inserted into this chain merely because the information may have originated outside the OCB analytical environment.

Where information is observable, its provenance is retained separately from the financial semantics of the event.

---

# 14. Relationship to Ledger Structures

T06 does not create or modify ledger structures.

Ledger representation remains governed by:

**WP-2.3-T04 — Define Ledger Structures**

The existence of an externally originated or institutionally observed event does not justify a separate integration ledger.

The financial consequence and ledger treatment remain governed by the approved event and accounting architecture.

---

# 15. Relationship to Reference Structures

T06 does not create additional reference structures.

Controlled classifications remain within:

```text
ref
```

as established by WP-2.3-T05.

Integration-specific classifications will not be introduced unless a future requirement establishes a legitimate operational need.

---

# 16. Relationship to Institutional Schemas

The institutional schemas remain the physical home of their respective source-owned operational activity:

```text
ananse
sikacredit
oman_remit
```

The fact that information may conceptually enter OCB through an observation boundary does not justify moving it into a generic integration schema.

For example:

```text
oman_remit.remittance
```

remains the physical representation of Oman Remit's remittance activity.

It does not become:

```text
integration.remittance
```

merely because OCB observes it.

---

# 17. Deferred Integration Architecture

The resulting v1.0.0 boundary is:

```text
SOURCE INSTITUTION
        │
        ↓
SOURCE-OWNED DATA
        │
        ↓
OBSERVATION / CONTROLLED INGESTION
        │
        ↓
OCB PLATFORM
```

The production mechanism is intentionally abstracted:

```text
SOURCE SYSTEM
        │
        │  [DEFERRED]
        ↓
API / FILE / MESSAGE / NETWORK / STREAM
        │
        ↓
OCB
```

The platform therefore preserves the architectural possibility of future integration without implementing it.

---

# 18. No Integration Coupling

The database must not introduce direct dependencies that imply operational coupling between the simulated institutions.

In particular, T06 does not introduce:

* cross-institution transactional triggers;
* shared institutional processing tables;
* integration-specific foreign-key chains;
* synchronous institutional dependencies;
* external-system state machines;
* cross-institution message workflows.

Cross-institution relationships remain analytical and observational as established in WP-1.1 and WP-2.1.

---

# 19. Physical Schema Decision

The physical schema architecture remains:

```text
OCB_PLATFORM
│
├── ocb
├── ananse
├── sikacredit
├── oman_remit
├── wallet
├── ledger
└── ref
```

No additional integration schema is required for v1.0.0.

No dedicated deferred-event table is required merely to represent deferred integration capabilities.

Deferred capabilities remain documented as architectural boundaries rather than being represented as fictional operational objects.

---

# 20. Future Expansion

A future version may introduce integration structures if an approved architectural requirement establishes a need for them.

Such expansion would require explicit definition of:

* source-system interfaces;
* ingestion mechanisms;
* message or file structures;
* delivery semantics;
* failure handling;
* reconciliation;
* security;
* provenance;
* idempotency;
* operational monitoring;
* external-system dependencies.

These are deliberately outside the present ticket.

---

# 21. Decision

The OCB Platform v1.0.0 will **not implement or physically model production institutional integration infrastructure**.

The platform will instead represent institutionally originated information within the approved observation and ingestion boundaries while preserving source ownership and provenance.

Accordingly:

1. No `integration` schema is created.
2. No API/message/streaming tables are created.
3. No SWIFT or payment-network structures are created.
4. No correspondent or settlement-institution structures are created.
5. No generic deferred-event table is created solely to represent future capabilities.
6. Existing institutional schemas remain responsible for source-owned operational activity.
7. Provenance and observation information remain governed by the existing platform data standards.
8. Future integration capability may be introduced only through a separately approved architectural change.

---

# 22. Status

**Status: APPROVED**

The v1.0.0 operational schema therefore distinguishes between **observable institutional information** and **implemented institutional integration**.

The platform models the former while deliberately deferring the latter.

---

# Core Principle

> **OCB v1.0.0 may represent institutionally originated information within its approved observation boundary, but the database must not imply production integration, external financial infrastructure, or operational coupling that the platform does not implement.**
