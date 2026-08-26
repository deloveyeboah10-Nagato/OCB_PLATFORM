# OCB Data Dictionary

## Purpose

This directory contains the Data Dictionary for the Osagyefo Central Bank Digital Financial Intelligence Platform (OCB Platform) v1.0.0.

The Data Dictionary defines how approved business concepts are represented within the platform's technical data structures.

Its purpose is to provide a controlled reference for:

* database objects;
* data attributes;
* relationships;
* constraints;
* indexes;
* analytical structures;
* data lineage;
* data grain;
* implementation status;
* technical ownership and responsibility.

The Data Dictionary exists to make the implemented data architecture understandable, traceable, reproducible, and maintainable.

It must describe the **actual implementation**.

It must not be populated with invented database objects merely to make the documentation appear complete.

---

## 1. Relationship to the Business Glossary

The Business Glossary and Data Dictionary serve different purposes.

The distinction is:

```text
Business Glossary
"What does this concept mean?"
        ↓
Data Model
"How is this concept represented?"
        ↓
Data Dictionary
"What are the technical characteristics?"
```

The Business Glossary establishes controlled business meaning.

The Data Dictionary documents the technical representation of that meaning.

For example, a business concept may eventually correspond to:

* a table;
* a column;
* a relationship;
* a calculated attribute;
* a fact;
* a dimension;
* a view;
* a data-mart structure.

The Data Dictionary must not redefine the established business meaning.

---

## 2. Relationship to Governing Documentation

The Data Dictionary operates within the established OCB documentation hierarchy:

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
Business Glossary
        ↓
Data Dictionary
        ↓
Implementation
        ↓
Validation Evidence
```

The Data Dictionary remains subordinate to the governing architecture.

It must remain consistent with:

* the Master Project Document;
* the Project Charter;
* the Implementation & Engineering Specification;
* the Technical Build Guide;
* accepted ADRs;
* the Business Glossary;
* the actual implementation.

The Data Dictionary must not independently introduce:

* new platform scope;
* new financial capabilities;
* unsupported database structures;
* unapproved architectural boundaries;
* production capabilities outside v1.0.0.

---

## 3. Dictionary Status

The Data Dictionary is a **build-time and living technical reference**.

Its framework is established during the foundation phase.

Detailed entries are populated as actual database and analytical structures are implemented.

The dictionary must therefore distinguish between:

* planned structures;
* implemented structures;
* deprecated structures;
* superseded structures;
* future structures.

Documentation must not represent planned structures as implemented.

---

## 4. Documentation Principle

The Data Dictionary follows one fundamental rule:

> **Document what the platform actually contains and how it behaves.**

A database object is not considered documented merely because its name has been listed.

Where appropriate, documentation should establish:

```text
Object
   ↓
Purpose
   ↓
Structure
   ↓
Relationships
   ↓
Data Meaning
   ↓
Lineage
   ↓
Usage
   ↓
Validation
```

The level of documentation should be proportional to the importance and complexity of the object.

---

## 5. Object Classification

The Data Dictionary should support documentation of the major OCB data structures.

### 5.1 Operational Objects

Where implemented:

* schemas;
* tables;
* columns;
* primary keys;
* foreign keys;
* constraints;
* indexes;
* triggers;
* stored procedures;
* functions;
* operational views.

### 5.2 Financial Core Objects

Where implemented:

* transaction structures;
* financial-event structures;
* wallet/account structures;
* financial-state structures;
* ledger structures;
* correction/reversal structures;
* reconciliation structures.

These objects require particular attention because they participate in the authoritative financial processing path.

### 5.3 Reliability Objects

Where implemented:

* deferred-work structures;
* queue/work tables;
* processing-state structures;
* retry metadata;
* failure records;
* idempotency structures.

The dictionary should distinguish reliability structures from financial truth structures.

### 5.4 Analytical Objects

Where implemented:

* Bronze structures;
* Silver structures;
* Gold structures;
* analytical views;
* aggregate structures;
* summary structures;
* staging structures;
* ELT support structures.

### 5.5 Warehouse Objects

Where implemented:

* fact tables;
* dimension tables;
* bridge structures;
* warehouse views;
* snapshot structures;
* historical analytical structures.

### 5.6 Data-Mart Objects

Where implemented:

* financial intelligence marts;
* risk marts;
* liquidity marts;
* credit marts;
* regulatory intelligence marts;
* other justified analytical marts.

Every data mart must have an explicit analytical purpose and documented grain.

### 5.7 Intelligence Objects

Where implemented:

* intelligence tables;
* intelligence views;
* risk-calculation structures;
* analytical procedures;
* metric structures;
* rule-support structures;
* intelligence output structures.

### 5.8 Regulatory Intelligence Objects

Where implemented:

* regulatory indicator structures;
* supervisory monitoring structures;
* investigation-support structures;
* regulatory analytical views;
* decision-support structures.

---

## 6. Object-Level Documentation Standard

Each significant database object should eventually have the following information.

| Field                | Purpose                                                                |
| -------------------- | ---------------------------------------------------------------------- |
| **Object Name**      | Exact database object name                                             |
| **Object Type**      | Table, view, procedure, function, index, etc.                          |
| **Schema**           | Owning database schema                                                 |
| **Layer / Domain**   | Operational, Bronze, Silver, Gold, warehouse, mart, intelligence, etc. |
| **Purpose**          | Why the object exists                                                  |
| **Business Concept** | Related glossary concept                                               |
| **Grain**            | Level represented by the object                                        |
| **Source**           | Originating information                                                |
| **Relationships**    | Relevant relationships                                                 |
| **Key Structure**    | Primary/foreign/unique keys                                            |
| **Constraints**      | Important integrity rules                                              |
| **Lifecycle**        | Creation/update/deprecation status                                     |
| **Lineage**          | Upstream and downstream relationships                                  |
| **Consumers**        | Processes or analytical workloads using it                             |
| **Validation**       | Relevant validation evidence                                           |
| **Notes / Boundary** | Important limitations or distinctions                                  |

Not every field will apply to every object.

---

## 7. Table Documentation

Every significant table should eventually document:

* table name;
* schema;
* purpose;
* business meaning;
* grain;
* primary key;
* foreign keys;
* important constraints;
* indexes;
* source;
* loading or population mechanism;
* update characteristics;
* downstream consumers;
* lineage;
* validation status.

The documented grain must be explicit.

For example:

```text
One row represents one ______.
```

This requirement is especially important for:

* fact tables;
* event tables;
* ledger tables;
* snapshots;
* aggregate tables;
* data marts.

Ambiguous grain creates a material risk of incorrect analytical results.

---

## 8. Column Documentation

Significant columns should eventually document:

| Field                      | Description                                      |
| -------------------------- | ------------------------------------------------ |
| **Column Name**            | Exact column name                                |
| **Data Type**              | SQL Server data type                             |
| **Nullable**               | Whether NULL is permitted                        |
| **Default**                | Default value where applicable                   |
| **Business Meaning**       | Meaning of the attribute                         |
| **Source**                 | Origin of the value                              |
| **Key Role**               | PK, FK, business key, etc.                       |
| **Allowed Values**         | Controlled values where applicable               |
| **Units**                  | Currency, count, percentage, duration, etc.      |
| **Temporal Meaning**       | Event time, processing time, etc. where relevant |
| **Sensitivity / Handling** | Relevant handling requirement where applicable   |
| **Validation**             | How the attribute is validated                   |
| **Notes**                  | Important implementation or semantic boundary    |

The Data Dictionary must preserve the distinction between:

* identifier;
* business identifier;
* analytical integration key;
* technical surrogate key.

A field must not be described as a production identity mechanism when it is only a controlled analytical abstraction.

---

## 9. DATA TYPE STANDARDS

OCB data types must reflect the business meaning, operational role, and expected behaviour of the data.

The following standards apply to implemented OCB Platform v1.0.0 structures unless a documented source-system or architectural requirement justifies a different implementation.

### 9.1 Monetary Values

Financial amounts must use exact numeric data types.

**OCB v1.0.0 standard:**

```text
DECIMAL(18,4)
```

This provides fixed precision and scale suitable for the financial values represented within the v1.0.0 simulation while avoiding the rounding and representation issues associated with approximate floating-point types.

The same monetary precision should be used consistently across related financial structures unless a specific business requirement requires otherwise.

Examples include:

* transaction amounts;
* loan principal amounts;
* repayment amounts;
* financial consequences;
* ledger entry amounts.

### 9.2 Rates and Percentages

Rates must use exact decimal types rather than approximate floating-point types.

Where a rate is stored as a decimal fraction, the stored value represents the rate directly.

Example:

```text
0.1250 = 12.50%
```

The physical precision and scale must be sufficient to preserve the required business precision.

For the current SikaCredit loan implementation:

```text
DECIMAL(5,4)
```

is used for interest rates stored as decimal fractions.

### 9.3 OCB Internal Identifiers

OCB-generated internal identifiers may use `BIGINT` where the identifier is expected to support high-volume internal relationships or cross-table mapping.

Examples include:

* `ocb_customer_id`;
* `financial_event_id`;
* `financial_consequence_id`;
* `ledger_entry_id`;
* `wallet_id`.

Where an identifier originates from an external institution, the source identifier should normally be preserved using an appropriate character or source-compatible data type rather than being converted solely for convenience.

### 9.4 Source-System Identifiers

Source-system identifiers must preserve the identifier as supplied by the originating institution.

Character-based types such as `VARCHAR` may be used where the source identifier is alphanumeric or where the source system's identifier format should remain unchanged.

OCB must not assume that identifiers generated by different institutions share the same format.

Source identifiers remain distinct from OCB-generated identifiers.

### 9.5 Human-Readable Text

`NVARCHAR` should be used where values may contain Unicode or multilingual human-readable text.

Examples include:

* names;
* occupations;
* nationalities;
* locations;
* country names.

`VARCHAR` may be used where the value is a controlled technical code or identifier whose character set does not require Unicode.

### 9.6 Currency Codes

Currency codes use:

```text
CHAR(3)
```

for the three-character currency representation used by OCB v1.0.0.

Currency values should represent controlled reference data rather than unrestricted descriptive text.

### 9.7 Dates

`DATE` should be used where only the calendar date has business meaning and time-of-day is not required.

Examples include:

* date of birth;
* maturity date.

### 9.8 Timestamps

`DATETIME2(3)` is the standard timestamp type for OCB v1.0.0 where millisecond precision is sufficient.

Timestamp columns must be interpreted according to their business meaning.

The dictionary should identify whether a timestamp represents, for example:

* event time;
* processing time;
* recording time;
* effective time;
* settlement time.

Timestamp precision must not be increased merely for technical appearance if the additional precision has no business meaning.

### 9.9 NULLability

NULLability is a business and data-quality decision, not merely a technical convenience.

A column should be `NOT NULL` when its value is required for the existence, interpretation, or validity of the record.

A column may be nullable where the absence of a value has a legitimate business meaning.

Examples include information that:

* may legitimately be unavailable;
* is optional;
* is not applicable to every record;
* is not required at the point the record is created.

Nullable columns must therefore have a defensible reason for permitting `NULL`.

### 9.10 Data-Type Consistency

Where the same business concept appears across related OCB structures, compatible data types should normally be used.

Examples include:

* identifiers used across relationships;
* monetary amounts;
* currency codes;
* timestamps;
* source-system identifiers.

Inconsistent physical representation of the same business concept should be avoided unless there is a documented reason.

### 9.11 Physical Design Authority

These standards establish the default physical representation for OCB v1.0.0.

They do not override:

* source-system requirements;
* approved architectural decisions;
* business meaning;
* SQL Server limitations;
* justified implementation requirements.

Where an implemented structure requires a deviation from an established standard, the deviation must be documented in the relevant data dictionary entry and escalated through the appropriate engineering governance process where materially significant.

---

## 10. Key Documentation

The dictionary should document important key structures.

### Primary Keys

Document:

* key name;
* columns;
* uniqueness;
* object;
* purpose.

### Foreign Keys

Document:

* child object;
* child column;
* referenced object;
* referenced column;
* relationship purpose.

### Business Keys

Where applicable, distinguish business identifiers from technical database identifiers.

### Analytical Integration Keys

Where applicable, explicitly identify controlled analytical integration keys such as the synthetic canonical `user_id`.

Such a key must not be documented as evidence that independent institutions natively share a production identity system.

---

## 11. Constraint Documentation

Important constraints should be documented where they materially contribute to integrity.

Examples include:

* NOT NULL constraints;
* UNIQUE constraints;
* CHECK constraints;
* foreign keys;
* controlled status values;
* financial amount rules;
* temporal rules;
* state-transition controls.

Database constraints should complement business rules.

The Data Dictionary should not assume that every business rule can or must be enforced through a database constraint.

---

## 12. Index Documentation

Indexes should be documented where they are material to the platform's performance or access patterns.

Each significant index should eventually identify:

* index name;
* object;
* indexed columns;
* included columns where applicable;
* uniqueness;
* purpose;
* workload supported;
* relevant performance evidence;
* maintenance considerations.

Indexes must be justified by workload requirements or demonstrated performance characteristics.

The presence of an index must not be treated as proof that a query is optimized.

---

## 13. View Documentation

Views should document:

* view name;
* purpose;
* source objects;
* output grain;
* important transformations;
* intended consumers;
* dependencies;
* performance considerations;
* implementation status.

Where a view represents a financial or analytical transformation, the transformation must remain traceable to its source structures.

---

## 14. Stored Procedure and Function Documentation

Where implemented, procedures and functions should document:

* name;
* purpose;
* inputs;
* outputs;
* affected objects;
* transaction behaviour;
* financial consequences where applicable;
* error handling;
* idempotency requirements where applicable;
* dependencies;
* validation evidence.

Financial processing procedures require stronger documentation because they may participate directly in the authoritative financial processing path.

---

## 15. Financial Core Documentation

Financial truth structures require additional documentation.

Where applicable, the dictionary should establish the relationship between:

```text
Financial Event
      ↓
Transaction
      ↓
Financial State
      ↓
Ledger
      ↓
Reconciliation
```

For each relevant structure, document:

* authoritative role;
* source event relationship;
* state relationship;
* ledger relationship;
* correction/reversal relationship;
* historical preservation;
* reconciliation role.

The Data Dictionary must not allow an analytical representation to appear to be an alternative authoritative financial source.

---

## 16. Temporal Documentation

Temporal semantics must be documented for important time-related attributes.

Where applicable, distinguish:

* event timestamp;
* transaction timestamp;
* processing timestamp;
* ingestion timestamp;
* extraction timestamp;
* settlement timestamp;
* effective timestamp.

The dictionary should state what each timestamp represents.

Similar-looking timestamps must not be treated as interchangeable without justification.

---

## 17. Bronze / Silver / Gold Documentation

Analytical objects should identify their layer and responsibility.

### Bronze

Document:

* observable source;
* ingestion characteristics;
* provenance;
* source fidelity;
* ingestion metadata;
* load information.

### Silver

Document:

* standardization;
* validation;
* cleansing;
* business-rule application;
* duplicate handling;
* temporal treatment;
* quality classification.

### Gold

Document:

* analytical purpose;
* grain;
* facts;
* dimensions;
* aggregates;
* analytical views;
* lineage;
* consumers.

The layers represent analytical responsibilities.

They must not automatically be interpreted as requiring unnecessary physical duplication.

---

## 18. Fact Table Documentation

Every implemented fact structure must have an explicit grain.

The documentation should establish:

* fact name;
* business process;
* grain;
* measures;
* dimensions;
* keys;
* source;
* transformation;
* refresh/load characteristics;
* downstream consumers.

For example:

```text
Grain:
One row represents one ______.
```

Measures must be documented according to their actual meaning and aggregation behaviour.

The dictionary should identify measures that:

* are additive;
* are semi-additive;
* are non-additive;
* require special aggregation logic.

---

## 19. Dimension Documentation

Each implemented dimension should document:

* dimension name;
* business purpose;
* grain;
* key;
* attributes;
* source;
* transformation;
* history behaviour where applicable;
* consumers.

Dimensions must remain consistent with the Business Glossary.

Where historical changes matter, the dictionary should identify how those changes are represented.

---

## 20. Analytical Grain and Aggregation

The Data Dictionary must explicitly document the grain of analytical structures.

This is especially important where analytical queries combine:

* fact tables;
* dimensions;
* events;
* snapshots;
* aggregates;
* data marts.

Documentation should make it possible to determine whether a join preserves, changes, or duplicates the intended grain.

The dictionary should support the following reasoning:

```text
Source Grain
      ↓
Join Relationship
      ↓
Resulting Grain
      ↓
Aggregation
      ↓
Analytical Measure
```

This is a data-integrity requirement, not merely a documentation preference.

---

## 21. Data-Mart Documentation

Every implemented data mart should document:

* mart name;
* consumer;
* analytical purpose;
* grain;
* source structures;
* transformations;
* measures;
* dimensions;
* refresh/load process;
* lineage;
* validation;
* known limitations.

A data mart should not exist merely because a subject area appears interesting.

Its analytical purpose must be identifiable.

---

## 22. Lineage Documentation

Where practical, significant analytical structures should preserve lineage through:

```text
Source
  ↓
Bronze
  ↓
Silver
  ↓
Gold
  ↓
Data Mart
  ↓
Intelligence
```

Lineage documentation should identify meaningful transformations such as:

* filtering;
* cleansing;
* standardization;
* classification;
* aggregation;
* enrichment;
* derived calculations.

Lineage must be sufficiently clear to support investigation and reconciliation.

---

## 23. Source and Provenance

Where applicable, document:

* source system;
* source identifier;
* source record identifier;
* batch/load identifier;
* extraction timestamp;
* ingestion timestamp;
* event timestamp;
* schema/version information;
* ingestion status.

These attributes support:

* traceability;
* reconciliation;
* debugging;
* reproducibility;
* late-arriving-event handling.

They do not imply production APIs, streaming infrastructure, or institutional integration services.

---

## 24. Implementation Status

Data Dictionary entries should use an appropriate implementation status.

Recommended values are:

### Planned

The structure is approved or anticipated but has not yet been implemented.

### Implemented

The structure exists in the repository/database and has been validated to the applicable completion standard.

### Simplified

The implemented structure intentionally represents a simplified version of the conceptual requirement.

### Observational

The structure represents information intentionally observable within the sandbox rather than reproducing an institution's complete internal system.

### Conceptual

The structure describes an architectural concept without a corresponding v1.0.0 implementation.

### Deferred

The structure belongs to a future version.

### Deprecated

The structure is no longer part of the active implementation but remains historically relevant.

The status must never overstate implementation fidelity.

---

## 25. Relationship to ADRs

The Data Dictionary documents technical structures.

ADRs document consequential architectural decisions.

A data-structure decision may require an ADR when it materially affects:

* system architecture;
* financial truth;
* data ownership;
* analytical architecture;
* performance strategy;
* integration boundaries;
* significant technology choices.

The Data Dictionary must not become a substitute for ADRs.

---

## 26. Relationship to Testing & Validation

The Data Dictionary should provide references to relevant validation evidence where appropriate.

Validation may include:

* schema validation;
* constraint tests;
* referential-integrity tests;
* reconciliation;
* data-quality tests;
* grain validation;
* lineage validation;
* query-result validation;
* performance evidence.

A documented structure must not be considered fully validated merely because the object was successfully created.

---

## 27. Change Control

Changes to implemented data structures must trigger review of the relevant documentation.

Potentially affected artefacts include:

* Business Glossary;
* Data Dictionary;
* ERDs;
* ELT processes;
* intelligence logic;
* tests;
* ADRs;
* WBS acceptance criteria;
* downstream analytical structures.

Material architectural changes must follow the established governance and change-control process.

---

## 28. Naming Consistency

Data Dictionary entries must use the actual repository/database names.

The dictionary should not silently substitute conceptual names for physical implementation names.

Where a conceptual name differs from an implementation name, document both where useful:

```text
Business Concept
      ↓
Logical Name
      ↓
Physical Object
```

Naming conventions must remain consistent with the project's repository and SQL naming standards.

---

## 29. Documentation Location

The framework is maintained under:

```text
docs/data_dictionary/
```

The directory may eventually contain additional dictionary artefacts if the size of the implementation warrants them.

For example:

```text
docs/
└── data_dictionary/
    ├── README.md
    ├── operational_objects.md
    ├── warehouse_objects.md
    ├── data_marts.md
    └── intelligence_objects.md
```

These additional files are examples of possible future organization.

They should be introduced only when actual implementation volume justifies them.

The foundation phase does not require them.

---

## 30. Completion Standard

The Data Dictionary framework is complete for the foundation phase when:

* the dictionary repository location is established;
* its purpose is defined;
* its relationship to the Business Glossary is defined;
* its relationship to governing documentation is defined;
* object classifications are established;
* table documentation requirements are established;
* column documentation requirements are established;
* key and constraint documentation requirements are established;
* index documentation requirements are established;
* view/procedure/function documentation requirements are established;
* financial-core documentation requirements are established;
* temporal semantics are addressed;
* Bronze/Silver/Gold documentation responsibilities are established;
* analytical grain requirements are established;
* data-mart documentation requirements are established;
* lineage requirements are established;
* implementation-status categories are established;
* the relationship to ADRs and validation is defined;
* change-control expectations are established;
* future expansion is explicitly tied to actual implementation.

The framework does **not** require the complete database to be documented at this stage.

---

## 31. Core Principle

The Data Dictionary follows one fundamental rule:

> **A data structure is not adequately documented until its purpose, meaning, grain, relationships, lineage, and implementation status can be understood without guessing.**

The objective is not to produce documentation volume.

The objective is to make the actual OCB data architecture understandable and defensible.

The dictionary should evolve with the implementation.

It should document what exists, distinguish what is planned from what is implemented, and preserve the relationship between business meaning and technical representation.

**Define the data. Document the structure. Preserve the lineage.**
