# WP-2.3-T05 — Define Reference Structures

**Programme:** OCB Platform v1.0.0

**Work Package:** WP-2.3 — Operational Schema Design

**Ticket:** WP-2.3-T05

**Status:** **APPROVED**

**Decision Type:** Shared controlled-reference structure

---

## 1. Purpose

This ticket defines the physical reference-data structures required to support controlled classifications across the OCB Platform.

The purpose is to prevent operational tables from embedding uncontrolled business classifications directly within transactional data.

Reference structures provide stable identifiers and controlled values for classifications that are shared across multiple operational domains.

The reference layer therefore supports:

* consistency;
* referential integrity;
* controlled vocabulary;
* extensibility;
* historical interpretation;
* cross-domain comparability.

---

# 2. Reference Schema

The reference structures reside within:

```text
OCB_PLATFORM
└── ref
```

The `ref` schema is a **shared control-data responsibility**.

It is not an institutional domain and does not represent a financial institution.

---

# 3. Reference-Data Principle

Where a classification is controlled and reused across operational structures, the platform should represent it through reference data rather than repeatedly embedding uncontrolled text values.

Conceptually:

```text
Operational Table
       │
       │ foreign key
       ↓
Reference Table
       │
       ↓
Controlled Classification
```

For example:

```text
ananse.transaction
       │
       ├── transaction_type_id
       │
       ↓
ref.transaction_type
```

This separates the **operational fact** from the **controlled vocabulary used to classify it**.

---

# 4. Authoritative Reference Structures

The v1.0.0 reference layer will initially contain the following structures:

```text
ref.transaction_type
ref.transaction_status
ref.transaction_channel
ref.currency
ref.country
```

These structures correspond to classifications already required by the approved operational model.

No additional reference entities are introduced merely for completeness.

---

# 5. Transaction Type

The structure:

```text
ref.transaction_type
```

provides the controlled vocabulary for transaction/event classification where applicable.

Conceptually:

```text
transaction_type_id
transaction_type_code
transaction_type_name
description
```

The reference structure may contain approved values such as:

```text
CASH_IN
CASH_OUT
P2P_TRANSFER
MERCHANT_PAYMENT
```

and other transaction classifications established by the approved event catalogue.

The reference table does not become the authoritative event catalogue itself.

The distinction remains:

```text
ref.transaction_type
        ↓
classification

financial event
        ↓
actual occurrence
```

---

# 6. Transaction Status

The structure:

```text
ref.transaction_status
```

provides the controlled vocabulary for transaction outcomes/statuses.

The approved status model includes:

```text
SUCCESSFUL
FAILED
REJECTED
```

The reference table therefore provides a controlled representation of those classifications.

Conceptually:

```text
transaction_status_id
transaction_status_code
transaction_status_name
description
```

The reference structure does not determine whether a transaction actually succeeded.

It only defines the valid classification used to represent that outcome.

---

# 7. Transaction Channel

The structure:

```text
ref.transaction_channel
```

provides controlled values for the channel through which an applicable transaction is initiated or processed.

The approved channel vocabulary includes:

```text
USSD
MOBILE_APP
QR
AGENT
POS
WEB
API
THIRD_PARTY
```

However, **the existence of a value in the reference table does not mean every institution uses that channel**.

Applicability remains determined by the relevant institutional domain.

For example, the current Ananse design does not imply that POS/card infrastructure exists merely because `POS` is available as a controlled reference classification.

This preserves the distinction between:

```text
controlled vocabulary
        ≠
implemented institutional capability
```

---

# 8. Currency

The structure:

```text
ref.currency
```

provides controlled currency identifiers used by financial activity and financial consequences.

Conceptually:

```text
currency_id
currency_code
currency_name
```

The currency code should use a consistent controlled representation.

The reference structure prevents different operational tables from independently defining currency values.

The existence of a currency in the reference structure does not imply that every institution supports or transacts in that currency.

---

# 9. Country

The structure:

```text
ref.country
```

provides controlled country identifiers for geographic attributes used across the platform.

Potential uses include:

* customer nationality;
* transaction location where represented through country;
* origin country;
* destination country;
* remittance geography.

The reference structure provides a consistent country vocabulary.

It does not establish institutional relationships or geographic capabilities.

---

# 10. Reference Identity

Each reference structure requires its own stable identifier.

Conceptually:

```text
transaction_type_id
transaction_status_id
transaction_channel_id
currency_id
country_id
```

The identifier is the database reference to the classification.

Operational tables should reference the controlled identifier rather than depend exclusively on free-form descriptive text.

---

# 11. Codes and Names

Reference structures should distinguish between a stable machine-oriented code and a descriptive name.

For example:

```text
transaction_status
------------------
status_id
status_code
status_name
description
```

This allows:

```text
status_code = SUCCESSFUL
status_name = Successful
```

without forcing operational tables to depend on display text.

Codes should remain stable once established.

Names and descriptions may be revised where governance permits without changing the identity of the underlying classification.

---

# 12. Referential Integrity

Operational tables should reference reference structures through controlled relationships.

For example:

```text
ananse.transaction
       │
       ├── transaction_type_id ──→ ref.transaction_type
       │
       ├── transaction_status_id ─→ ref.transaction_status
       │
       └── transaction_channel_id ─→ ref.transaction_channel
```

Likewise:

```text
financial structure
       │
       └── currency_id ──→ ref.currency
```

and:

```text
customer / remittance structure
       │
       └── country_id ──→ ref.country
```

These relationships enforce controlled classification without transferring ownership of the operational records.

---

# 13. Reference Data Does Not Own Operational Activity

The `ref` schema defines classifications.

It does not own:

* transactions;
* customers;
* wallets;
* loans;
* repayments;
* remittances;
* ledger entries;
* financial positions.

For example:

```text
ref.transaction_status
        ≠
ananse.transaction
```

The former defines what a status means.

The latter records an actual institutional transaction.

---

# 14. Institutional Independence

Shared reference data must not be confused with shared institutional ownership.

Ananse, SikaCredit, and Oman Remit may reference the same controlled classification while remaining completely independent institutional domains.

For example:

```text
ananse.transaction
       │
       └──→ ref.currency

sikacredit.loan
       │
       └──→ ref.currency

oman_remit.remittance
       │
       └──→ ref.currency
```

This means only that the platform uses a common controlled currency vocabulary.

It does **not** mean that the institutions share financial systems, financial state, or operational data.

---

# 15. Reference Data vs Business Rules

Reference structures must not become a dumping ground for business logic.

The distinction is:

```text
Reference Data
      ↓
What classifications are valid?

Business Rules
      ↓
How should those classifications affect processing?
```

For example:

```text
ref.transaction_status
      ↓
SUCCESSFUL
```

does not itself determine how a successful transaction changes a wallet.

That behaviour belongs to the financial-event, state, and ledger architectures.

---

# 16. Reference Data vs Event Catalogue

The financial event catalogue established earlier remains authoritative for defining the platform's recognised financial events.

The reference layer provides controlled physical values required to represent those events in operational structures.

Therefore:

```text
Event Catalogue
      ↓
Defines recognised financial events

Reference Structure
      ↓
Provides controlled database classifications
```

These must not be conflated.

---

# 17. Initial Physical Structures

The resulting reference architecture is:

```text
ref
├── transaction_type
├── transaction_status
├── transaction_channel
├── currency
└── country
```

The structures are intentionally limited to classifications already required by the approved logical model.

No speculative reference tables are introduced.

---

# 18. Deferred Reference Structures

The following are **not** introduced merely because they could theoretically be reference data:

* customer status extensions;
* loan-status taxonomies beyond approved requirements;
* remittance-specific classifications;
* geographic hierarchies;
* institution classifications;
* risk-rating taxonomies;
* regulatory classifications;
* analytical categories.

Such structures may be introduced later if an approved operational or intelligence requirement establishes them.

This prevents the reference schema from becoming an uncontrolled catalogue of hypothetical future concepts.

---

# 19. Relationship to WP-2.2

WP-2.2 established the logical attributes and controlled relationships required by the model.

T05 translates the relevant classifications into physical shared-reference structures.

The progression is:

```text
WP-2.2
Logical Attribute
      ↓
WP-2.3-T05
Reference Structure
      ↓
WP-2.4
Physical Table Implementation
```

T05 does not alter the logical model established in WP-2.2.

---

# 20. Relationship to T01 and T02

T01 established:

```text
ref
```

as a physical SQL Server schema.

T02 established `ref` as the responsibility boundary for shared controlled reference data.

T05 now defines the initial structures contained within that boundary.

Therefore:

```text
T01
Schema Boundary
      ↓
T02
Responsibility
      ↓
T05
Reference Structures
```

---

# 21. v1.0.0 Boundary

The reference architecture does not introduce:

* external master-data management systems;
* external country/currency APIs;
* dynamic reference-data services;
* real-time reference-data synchronization;
* institutional reference-data integration.

Reference data is maintained within the SQL Server platform for v1.0.0.

---

# 22. Decision

The OCB Platform v1.0.0 will maintain a dedicated:

```text
ref
```

schema containing controlled reference structures required by the approved operational model.

The initial structures are:

```text
ref.transaction_type
ref.transaction_status
ref.transaction_channel
ref.currency
ref.country
```

These structures provide controlled classifications for operational data without becoming owners of operational activity or financial state.

Operational tables will reference these classifications through controlled identifiers where applicable.

No additional reference structures will be introduced without an established requirement.

---

# Core Principle

> **Reference data defines controlled classifications; it does not define the financial activity itself. Shared reference structures provide consistency across institutional domains without creating shared institutional ownership, shared financial state, or operational coupling.**
