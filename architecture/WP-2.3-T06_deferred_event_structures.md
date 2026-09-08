# WP-2.3-T06 — Define Integration and Deferred-Event Boundary

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T06
**Status:** **APPROVED**
**Decision Type:** Integration and deferred-event boundary

---

# 1. Purpose

This ticket defines the **operational-schema boundary for institutional integration, externally originated information, and deferred event capabilities** within OCB Platform v1.0.0.

Its purpose is to establish:

* what integration-related structures are required within the v1.0.0 operational schema;
* what integration capabilities are explicitly outside scope;
* how institutionally originated information is represented without implying production connectivity;
* how provenance and observation remain distinct from integration infrastructure;
* how deferred capabilities are documented without creating unsupported database structures.

The governing principle is:

```text
SOURCE-OWNED ACTIVITY
        ↓
OBSERVABLE INFORMATION
        ↓
OCB REPRESENTATION
        ↓
OCB FINANCIAL / ANALYTICAL MODEL
```

The physical database must not imply capabilities that the v1.0.0 platform does not actually implement.

---

# 2. Integration Boundary

OCB Platform v1.0.0 is a **controlled financial-intelligence sandbox**, not a production institutional integration platform.

Accordingly, v1.0.0 does not implement production connectivity to:

* Ananse Telecom;
* SikaCredit;
* Oman Remit;
* banks;
* payment networks;
* settlement systems;
* external regulatory systems;
* external financial infrastructure.

The following integration mechanisms are explicitly outside the v1.0.0 implementation boundary:

```text
API connectivity
Message brokers
Streaming infrastructure
Real-time institutional feeds
SWIFT connectivity
Payment-network connectivity
External settlement connectivity
Direct institutional system connectivity
```

Their absence from the physical schema is deliberate.

---

# 3. Observation Boundary

The platform may nevertheless contain information that is conceptually originated by an institutional domain.

The distinction is:

```text
Institutional Activity
        ↓
Observable Information
        ↓
OCB Representation
```

and not:

```text
Institutional Activity
        ↓
Production API / Network / Stream
        ↓
OCB
```

The latter describes a production integration architecture and is outside v1.0.0.

Therefore, the OCB schema models the **information required by the approved financial and analytical boundary**, not the production mechanism through which an institution would exchange that information with a regulator.

---

# 4. No Dedicated Integration Schema

No dedicated schema such as:

```text
integration
external
api
network
settlement
```

will be introduced into the v1.0.0 database.

The approved schema architecture remains:

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

This prevents physical schema design from implying an integration platform that does not exist.

---

# 5. No Production Integration Structures

The v1.0.0 operational database will not contain structures representing:

* API requests or responses;
* API endpoints;
* message queues;
* streaming topics;
* SWIFT messages;
* payment-network messages;
* external settlement instructions;
* correspondent-bank messages;
* production integration sessions;
* external connection states;
* real-time delivery mechanisms.

These are implementation concerns of a future integration architecture, not requirements of the v1.0.0 operational schema.

---

# 6. Deferred-Event Principle

A capability being deferred does not create a new financial-event type.

The approved v1.0.0 financial-event catalogue remains authoritative.

Therefore, the following remain distinct:

```text
Financial Event
        ↓
Recognised within the OCB financial model
```

versus:

```text
Integration Event
        ↓
Technical message or delivery mechanism
```

The second is not automatically a financial event.

For example, a future API message describing a remittance would not create:

```text
external.remittance_event
```

as a new OCB financial-event type.

The recognised financial event remains:

```text
Remittance
```

with its source-domain identity and provenance preserved separately.

---

# 7. Source Ownership

Representation within OCB does not transfer ownership of source activity to OCB.

The ownership model remains:

```text
SOURCE INSTITUTION
        ↓
SOURCE-OWNED ACTIVITY
        ↓
OBSERVABLE INFORMATION
        ↓
OCB REPRESENTATION
```

Therefore:

```text
ananse.transaction
```

remains Ananse institutional activity.

```text
sikacredit.loan
```

remains SikaCredit lending activity.

```text
sikacredit.repayment
```

remains SikaCredit repayment activity.

```text
oman_remit.remittance
```

remains Oman Remit remittance activity.

OCB may represent and analyse these activities without becoming the operational owner of them.

---

# 8. Provenance Boundary

Institutionally originated information must remain traceable to its source.

The broader OCB provenance standard therefore remains applicable to information entering the OCB analytical environment.

Relevant provenance concepts may include:

* source system;
* source entity;
* source record identifier;
* batch identifier;
* extraction timestamp;
* ingestion timestamp;
* event timestamp;
* schema version;
* ingestion status.

These attributes establish **data lineage**.

They do not represent production integration infrastructure.

The distinction is:

```text
Provenance
    ↓
Where did this information come from?

Integration
    ↓
How did systems exchange it?
```

T06 defines the boundary between the two.

---

# 9. Observation Is Not Integration

The following concepts must remain distinct:

| Concept                     | Meaning                                                               |
| --------------------------- | --------------------------------------------------------------------- |
| **Source activity**         | Activity owned by an institutional domain                             |
| **Observable information**  | Information available to OCB within the approved boundary             |
| **Ingestion**               | Controlled incorporation of information into the OCB data environment |
| **Provenance**              | Evidence of information origin and lineage                            |
| **Integration**             | A system-to-system mechanism for exchanging information               |
| **Analytical relationship** | A relationship established by OCB for analysis                        |

Accordingly:

> **The presence of institutionally sourced information within OCB does not prove or imply that production institutional integration has been implemented.**

---

# 10. Relationship to Institutional Schemas

The institutional schemas remain responsible for their source-domain operational meaning.

```text
ananse
├── customer
└── transaction

sikacredit
├── customer
├── loan
└── repayment

oman_remit
├── customer
└── remittance
```

T06 does not introduce duplicate versions of these structures under a generic integration schema.

For example:

```text
oman_remit.remittance
```

does not become:

```text
integration.remittance
```

simply because OCB observes or analyses it.

This prevents duplication of institutional meaning and preserves the source-domain boundary established by the preceding operational-schema tickets.

---

# 11. Relationship to Financial Events

The financial-event architecture established in WP-2.3-T03 remains unchanged.

The recognised financial flow is:

```text
SOURCE-OWNED ACTIVITY
        ↓
OCB FINANCIAL EVENT
        ↓
EVENT OUTCOME
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER POSTING
        ↓
FINANCIAL STATE
```

Integration is **not inserted into this financial chain** merely because information may have crossed an observation boundary.

Technical delivery and financial semantics remain separate concerns.

For example:

```text
Oman Remit Remittance
        ↓
OCB Financial Event
        ↓
Financial Consequence
```

does not require an intermediate:

```text
integration.remittance_message
```

structure.

---

# 12. Relationship to Ledger Structures

T06 does not create or modify ledger structures.

Ledger representation remains governed by:

**WP-2.3-T04 — Define Ledger Structures**

and the subsequent ledger architecture.

Externally originated information does not require a separate:

```text
integration.ledger
```

or equivalent structure.

Where a recognised financial event produces a valid financial consequence, that consequence follows the same approved financial-event and ledger architecture regardless of the technical mechanism through which the information became observable.

---

# 13. Relationship to Reference Structures

T06 does not introduce additional reference structures.

Controlled classifications remain governed by:

```text
ref
```

as defined in WP-2.3-T05.

Integration-specific technical vocabularies are not introduced merely because future integration could require them.

If future implementation requires such classifications, they must be established through a separately approved architectural requirement.

---

# 14. External Financial Infrastructure Boundary

The v1.0.0 operational schema does not model financial infrastructure outside the approved OCB institutional boundary.

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

These may be relevant to real-world financial systems but are not required to represent the approved v1.0.0 financial model.

Introducing them now would create architectural complexity without an established operational requirement.

---

# 15. Oman Remit Boundary

Oman Remit provides the clearest example.

OCB may represent:

```text
Oman Remit
     ↓
Remittance
     ↓
Observable financial information
     ↓
OCB financial representation
     ↓
OCB analysis
```

T06 does not model the external infrastructure that could exist in a production remittance environment:

```text
Oman Remit
     ↓
Correspondent Institution
     ↓
Payment Network
     ↓
Settlement Institution
     ↓
Beneficiary Institution
```

Such infrastructure would require a separate approved architecture.

Its absence does not prevent the v1.0.0 platform from representing the approved remittance event.

---

# 16. No Cross-Institution Operational Coupling

The database must not introduce physical dependencies that imply operational coupling between Ananse, SikaCredit, and Oman Remit.

T06 therefore prohibits the introduction of:

* cross-institution transactional triggers;
* shared institutional processing tables;
* integration-specific foreign-key chains;
* synchronous institutional dependencies;
* external-system state machines;
* cross-institution message workflows.

Cross-domain relationships remain governed by the approved OCB identity, observation, financial-event, and analytical architectures.

---

# 17. Deferred Capability Principle

Deferred capabilities are handled explicitly rather than being partially implemented through placeholder structures.

The rule is:

```text
Required for v1.0.0
        ↓
Implement

Relevant but outside v1.0.0
        ↓
Define boundary and defer

Unsupported or unjustified
        ↓
Do not model
```

This prevents speculative architecture from entering the operational database.

The absence of a table is therefore not an architectural omission where the underlying capability is deliberately deferred.

---

# 18. Future Integration Expansion

A future OCB version may introduce integration structures if an approved requirement establishes the need.

Such an architecture would require separate definition of, at minimum:

* source-system interfaces;
* ingestion mechanisms;
* message or file structures;
* delivery semantics;
* failure handling;
* idempotency;
* reconciliation;
* security;
* provenance;
* operational monitoring;
* external-system dependencies.

Those concerns are explicitly outside T06.

T06 therefore preserves **architectural extensibility without prematurely implementing integration infrastructure**.

---

# 19. Physical Schema Decision

The v1.0.0 physical schema remains:

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

No additional integration schema is required.

No generic deferred-event table is required.

No external-infrastructure tables are required.

No technical message structures are required merely to preserve the possibility of future integration.

The operational database represents the approved financial and institutional model rather than hypothetical future connectivity.

---

# 20. Relationship to WP-2.4

T06 establishes a **physical-schema boundary**, not an implementation of integration mechanisms.

WP-2.4 may therefore implement only the structures authorised by the preceding operational-schema tickets.

T06 specifically prevents WP-2.4 from introducing tables whose existence would imply:

```text
Production API
Production streaming
Production messaging
External settlement
Payment-network connectivity
Institutional system connectivity
```

unless a separately approved architectural decision changes the v1.0.0 boundary.

---

# 21. Decision

The OCB Platform v1.0.0 will **not implement or physically model production institutional integration infrastructure**.

The platform will represent institutionally originated information within its approved observation and ingestion boundaries while preserving source ownership, financial-event semantics, and provenance.

Accordingly:

1. **No `integration` schema will be created.**

2. **No API, message, queue, or streaming tables will be created.**

3. **No SWIFT, PAPSS, CIPS, or payment-network structures will be created.**

4. **No correspondent-bank or settlement-institution structures will be created.**

5. **No generic deferred-event table will be created solely to represent future capabilities.**

6. **Existing institutional schemas remain responsible for source-owned operational activity.**

7. **Financial-event structures remain governed by WP-2.3-T03.**

8. **Ledger structures remain governed by WP-2.3-T04 and subsequent ledger architecture.**

9. **Controlled classifications remain governed by WP-2.3-T05.**

10. **Provenance and ingestion remain governed by the broader OCB data-lineage architecture.**

11. **Future production integration requires a separately approved architectural decision.**

---

# 22. Final Boundary

The resulting architecture is:

```text
SOURCE INSTITUTION
        │
        ↓
SOURCE-OWNED ACTIVITY
        │
        ↓
OBSERVABLE INFORMATION
        │
        ↓
OCB CONTROLLED REPRESENTATION
        │
        ├── Financial Event
        │
        ├── Financial Consequence
        │
        └── Analytical Representation
```

The technical mechanism by which information could be exchanged in production remains:

```text
API / FILE / MESSAGE / NETWORK / STREAM
                  ↓
              [DEFERRED]
```

It is not part of the v1.0.0 operational schema.

---

# 23. Status

**Status: APPROVED**

WP-2.3-T06 establishes that OCB Platform v1.0.0 models the **observable institutional information required by its approved financial and analytical boundary**, while deliberately avoiding physical structures that would imply production integration, external financial infrastructure, or operational coupling.

---

# Core Principle

> **OCB v1.0.0 represents institutionally originated information within its approved observation boundary, but does not physically model production integration, external financial infrastructure, or operational connectivity that the platform does not implement. Deferred capabilities remain architectural boundaries rather than fictional database objects.**
