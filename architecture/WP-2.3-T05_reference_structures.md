# WP-2.3-T05 — Define Reference Structures

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T05
**Status:** **APPROVED**
**Decision Type:** Shared Controlled-Reference Structure

---

# 1. Purpose

This ticket defines the shared controlled-reference structures required by the OCB Platform v1.0.0 operational schema.

The purpose of the reference layer is to provide controlled classifications for attributes that require consistent interpretation across one or more operational structures.

Reference structures support:

* controlled vocabulary;
* consistent classification;
* referential integrity;
* cross-domain comparability;
* stable interpretation of operational records;
* extensibility where justified by approved requirements.

The reference layer must remain distinct from:

* institutional operational activity;
* financial events;
* financial consequences;
* ledger postings;
* financial state;
* business-processing rules.

The reference layer defines **what a classification means**. It does not define **what financially occurred** or **how the platform processes that occurrence**.

---

# 2. Reference Schema

The reference structures are physically located within:

```text
OCB_PLATFORM
└── ref
```

The `ref` schema is a **shared platform-control boundary**.

It is not an institutional domain and does not represent a financial institution.

Its responsibility is limited to controlled classifications required by the approved OCB Platform data model.

---

# 3. Governing Reference-Data Principle

Where an attribute represents a controlled classification that requires consistent interpretation, the platform should use a governed reference structure rather than unrestricted free-form values.

Conceptually:

```text
Operational Record
       │
       │ classification reference
       ↓
Reference Structure
       │
       ↓
Controlled Classification
```

For example:

```text
ananse.transaction
       │
       └── transaction_type_id
                    │
                    ↓
          ref.transaction_type
```

The operational record remains the authoritative record of the activity.

The reference structure provides only the controlled classification associated with that activity.

Therefore:

```text
Reference Classification
        ≠
Operational Activity
```

---

# 4. Initial Reference Structures

The approved v1.0.0 reference layer consists of:

```text
ref.transaction_type
ref.transaction_status
ref.transaction_channel
ref.currency
ref.country
```

These structures correspond to controlled classifications already required by the approved operational model.

No additional reference structures are introduced merely because they could theoretically be useful.

New reference structures require an established architectural or implementation requirement.

---

# 5. Reference Structure Identity

Each reference structure requires a stable identifier appropriate to its role.

Conceptually:

```text
transaction_type_id
transaction_status_id
transaction_channel_id
currency_id
country_id
```

These identifiers provide database-level references to controlled classifications.

The identifier represents the classification itself.

It must not be confused with:

```text
customer_id
wallet_id
transaction_id
loan_id
repayment_id
remittance_id
financial_event_id
ledger_entry_id
```

Reference identifiers therefore classify operational objects without becoming identities for those objects.

---

# 6. Code, Name and Description

Reference structures should distinguish between:

```text
stable code
descriptive name
description
```

For example:

```text
status_id
status_code
status_name
description
```

A controlled code should remain stable once established.

The descriptive name provides a human-readable representation.

The description provides additional semantic context where required.

The operational model should not depend on display text where a controlled identifier is available.

For example:

```text
status_code = SUCCESSFUL
status_name = Successful
```

The code provides the controlled machine-oriented classification while the name provides the presentation-oriented representation.

---

# 7. Transaction Type

The structure:

```text
ref.transaction_type
```

provides controlled classifications for institutional transaction activity where applicable.

The initial Ananse transaction classifications include:

```text
CASH_IN
CASH_OUT
P2P_TRANSFER
MERCHANT_PAYMENT
```

The reference structure classifies an operational transaction.

It does not replace the financial-event catalogue.

The distinction is:

```text
Transaction Type
        ↓
Classification of operational activity

Financial Event Type
        ↓
Recognised financial event within the OCB financial model
```

Where the same business concept is represented in both structures, the relationship must remain deliberate rather than assumed.

The existence of a transaction-type value does not automatically establish a corresponding financial event, consequence, or ledger posting.

---

# 8. Transaction Status

The structure:

```text
ref.transaction_status
```

provides the controlled vocabulary for transaction outcomes.

The approved v1.0.0 outcome classifications are:

```text
SUCCESSFUL
FAILED
REJECTED
```

The reference structure defines the valid classification.

It does not determine the processing behaviour associated with that classification.

For example:

```text
SUCCESSFUL
```

does not itself create a wallet credit.

The financial consequence is determined by the approved financial-event and ledger architecture.

Therefore:

```text
Status Classification
        ↓
describes outcome

Financial Rule
        ↓
determines consequence
```

---

# 9. Transaction Channel

The structure:

```text
ref.transaction_channel
```

provides controlled classifications for transaction channels.

The approved v1.0.0 channel vocabulary is:

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

The presence of a channel in the reference structure does **not** imply that every institution supports that channel.

For example, the existence of:

```text
POS
```

does not establish that Ananse operates a card/POS infrastructure.

Channel applicability remains determined by the relevant institutional operational model.

Therefore:

```text
Controlled Vocabulary
        ≠
Institutional Capability
```

This prevents the reference layer from accidentally creating unsupported business capabilities.

---

# 10. Currency

The structure:

```text
ref.currency
```

provides controlled currency classifications used by financial activity and financial representations.

Conceptually:

```text
currency_id
currency_code
currency_name
```

The currency code provides the stable controlled representation.

The currency name provides the human-readable representation.

The reference structure establishes currency classification only.

It does not establish:

* supported institutional currencies;
* foreign-exchange rules;
* currency conversion;
* settlement rules;
* reporting-currency transformation.

Those concerns belong to the appropriate financial or analytical architecture.

The existence of a currency in `ref.currency` therefore does not imply that every institution supports or transacts in that currency.

---

# 11. Country

The structure:

```text
ref.country
```

provides controlled geographic classifications required by the approved operational model.

Potential uses include:

* customer nationality;
* country associated with transaction location where applicable;
* remittance origin country;
* remittance destination country;
* other approved country-based attributes.

The country reference provides a consistent classification.

It does not establish:

* institutional presence;
* regulatory jurisdiction;
* transaction corridors;
* remittance capability;
* customer eligibility.

Those are separate business or analytical concepts.

---

# 12. Referential Integrity

Where an operational attribute requires controlled classification, the physical implementation should establish an appropriate relationship to its reference structure.

Conceptually:

```text
ananse.transaction
       │
       ├── transaction_type_id
       │          ↓
       │   ref.transaction_type
       │
       ├── transaction_status_id
       │          ↓
       │   ref.transaction_status
       │
       └── transaction_channel_id
                  ↓
          ref.transaction_channel
```

Similarly:

```text
financial structure
       │
       └── currency_id
                  ↓
            ref.currency
```

and:

```text
customer / remittance structure
       │
       └── country_id
                  ↓
             ref.country
```

The physical implementation of these relationships, including foreign keys and exact column definitions, belongs to WP-2.4.

T05 establishes the architectural requirement rather than prematurely defining the implementation mechanics.

---

# 13. Reference Data Does Not Own Operational Records

The `ref` schema does not own the operational records that reference it.

It does not own:

* customers;
* wallets;
* transactions;
* loans;
* repayments;
* remittances;
* financial events;
* financial consequences;
* ledger entries;
* financial positions.

For example:

```text
ref.transaction_status
        ≠
ananse.transaction
```

The former defines an approved classification.

The latter records an actual institutional transaction.

---

# 14. Shared Reference Data Does Not Create Shared Institutional Ownership

Multiple institutional domains may use the same reference classification without becoming part of the same operational system.

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

This means only that the OCB Platform uses a common controlled currency vocabulary.

It does not mean that:

* Ananse owns SikaCredit activity;
* SikaCredit owns Ananse activity;
* institutions share operational records;
* institutions share financial state;
* the reference layer owns institutional activity.

The `ref` schema is therefore a **shared classification boundary, not a shared institutional domain**.

---

# 15. Reference Data Does Not Implement Business Rules

Reference structures must not become a container for business-processing logic.

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

does not determine:

```text
wallet balance += amount
```

The resulting financial consequence is governed by the financial-event, ledger, and financial-state architecture.

Similarly:

```text
ref.transaction_channel
        ↓
USSD
```

does not itself determine transaction limits, risk treatment, authentication requirements, or processing behaviour.

---

# 16. Reference Data Does Not Define the Event Catalogue

The approved financial-event catalogue remains the authority for recognised OCB financial events.

The reference layer provides controlled classifications needed to represent operational data.

Therefore:

```text
Event Catalogue
        ↓
Defines recognised financial events

Reference Structure
        ↓
Defines controlled classifications
```

These are complementary but distinct responsibilities.

The reference layer must not be used to introduce unauthorised financial events.

In particular, adding a value to a reference table must not be interpreted as approval of a new v1.0.0 financial event.

---

# 17. Controlled Vocabulary vs Institutional Applicability

A controlled reference value establishes that a classification is recognised by the platform.

It does not establish that the classification applies to every institutional domain.

For example:

```text
ref.transaction_channel
        │
        ├── USSD
        ├── MOBILE_APP
        ├── QR
        ├── AGENT
        ├── POS
        ├── WEB
        ├── API
        └── THIRD_PARTY
```

does not mean:

```text
Ananse supports all eight channels
```

Institution-specific applicability remains determined by the relevant institutional schema and approved business model.

This principle prevents reference data from silently expanding the platform's operational scope.

---

# 18. Reference Data and Historical Interpretation

Reference classifications must support consistent interpretation of historical operational records.

Where a controlled classification is used by an operational record, the classification must remain interpretable throughout the relevant historical period.

Stable codes therefore provide an important historical anchor.

Reference-data governance must avoid casually reusing an existing code for a materially different business meaning.

The principle is:

```text
Existing Code
      ↓
Established Meaning
      ↓
Historical Interpretation
```

A materially different classification should not simply inherit an old identifier for convenience.

Detailed reference-data lifecycle governance may be established later where required.

---

# 19. Initial Physical Reference Structures

The resulting v1.0.0 reference architecture is:

```text
ref
├── transaction_type
├── transaction_status
├── transaction_channel
├── currency
└── country
```

The structures are deliberately limited to classifications already required by the approved operational model.

No speculative reference entities are introduced.

---

# 20. Deferred Reference Structures

The following structures are not introduced merely for completeness:

* extended customer-status taxonomies;
* expanded loan-status taxonomies;
* remittance-specific classification hierarchies;
* geographic hierarchies;
* institution classifications;
* risk-rating taxonomies;
* regulatory classifications;
* analytical categories;
* fraud classifications;
* behavioural classifications.

Such structures may be introduced only when an approved requirement establishes their necessity.

This prevents the `ref` schema from becoming an uncontrolled catalogue of hypothetical future concepts.

---

# 21. Relationship to WP-2.2

WP-2.2 established the logical attributes and relationships required by the approved model.

T05 translates the relevant controlled classifications into shared reference structures.

The progression is:

```text
WP-2.2
Logical Model
      ↓
WP-2.3-T05
Reference Structure Definition
      ↓
WP-2.4
Physical SQL Implementation
```

T05 does not alter the logical model established in WP-2.2.

---

# 22. Relationship to WP-2.3-T01 and T02

WP-2.3-T01 established:

```text
ref
```

as a physical SQL Server schema boundary.

WP-2.3-T02 established:

```text
ref
```

as the responsibility boundary for shared controlled reference data.

T05 defines the structures contained within that boundary.

Therefore:

```text
T01
Schema Boundary
      ↓
T02
Responsibility Boundary
      ↓
T05
Reference Structures
```

This preserves the separation between:

* where a structure physically resides;
* what responsibility that structure serves;
* who owns the institutional activity being classified.

---

# 23. Relationship to WP-2.3-T03 and T04

T03 defines:

```text
Financial Event
Financial Consequence
```

T04 defines:

```text
Ledger Entry
```

T05 defines the shared classifications required to represent these and other operational structures consistently.

The responsibilities therefore remain separate:

```text
T03
Financial Event / Consequence
       ↓
T04
Ledger Structure
       ↓
T05
Shared Controlled Classifications
```

Reference data supports these structures but does not replace them.

---

# 24. Relationship to WP-2.4

T05 defines the required reference structures and their semantic responsibilities.

It does not yet implement:

* SQL Server tables;
* exact data types;
* primary keys;
* foreign keys;
* unique constraints;
* CHECK constraints;
* defaults;
* indexes;
* seed-data deployment mechanics;
* reference-data loading procedures.

Those implementation concerns belong to WP-2.4.

The architectural requirement established by T05 is that controlled classifications required by the approved model must have an appropriate governed reference representation.

---

# 25. v1.0.0 Boundary

The reference architecture does not introduce:

* external master-data-management platforms;
* external country or currency APIs;
* dynamic reference-data services;
* real-time reference-data synchronisation;
* institutional reference-data integration;
* external reference-data ownership dependencies.

For v1.0.0, the approved reference structures are maintained within the OCB Platform SQL Server environment.

---

# 26. Resulting Operational Schema Architecture

The resulting schema architecture is:

```text
OCB_PLATFORM
│
├── ocb
│   ├── customer
│   └── customer_identity
│
├── ananse
│   ├── customer
│   └── transaction
│
├── sikacredit
│   ├── customer
│   ├── loan
│   └── repayment
│
├── oman_remit
│   ├── customer
│   └── remittance
│
├── wallet
│   └── wallet
│
├── ledger
│   ├── financial_event
│   ├── financial_consequence
│   └── entry
│
└── ref
    ├── transaction_type
    ├── transaction_status
    ├── transaction_channel
    ├── currency
    └── country
```

The reference layer remains a shared control boundary.

It does not become an institutional domain or financial-state owner.

---

# 27. Decision

The OCB Platform v1.0.0 will maintain a dedicated:

```text
ref
```

schema containing the following initial controlled-reference structures:

```text
ref.transaction_type
ref.transaction_status
ref.transaction_channel
ref.currency
ref.country
```

These structures will provide governed classifications required by the approved operational model.

The authoritative decisions are:

1. **Controlled classifications required across the operational model will be represented through governed reference structures where appropriate.**

2. **Reference structures classify operational records; they do not become the operational records themselves.**

3. **The `ref` schema is a shared platform-control boundary and is not an institutional domain.**

4. **Shared reference data does not create shared institutional ownership or shared financial state.**

5. **Reference classifications do not establish institutional capabilities merely because a value exists in the reference structure.**

6. **Reference data does not implement financial-processing rules or determine financial consequences.**

7. **Reference data does not replace or expand the approved financial-event catalogue.**

8. **Reference identifiers remain distinct from operational, financial-event, and ledger identifiers.**

9. **Reference codes must remain stable once established and must not be casually reused for materially different meanings.**

10. **The initial reference structures are intentionally limited to requirements already established by the approved v1.0.0 model.**

11. **Physical SQL implementation, constraints, indexes, and seed-data deployment are deferred to WP-2.4.**

12. **No additional reference structure will be introduced without an established and approved requirement.**

---

# Core Principle

> **Reference data defines controlled classifications; it does not define the financial activity itself. The `ref` schema provides a shared classification boundary that enables consistency and referential integrity across institutional domains without transferring ownership, creating shared financial state, or introducing business-processing logic.**
