**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.3 — Financial Event Catalogue

**Ticket:** WP-1.3-T04

**Status:** **REVISED / LOCKED**

**Decision Type:** Correction, reversal, adjustment, and historical-truth semantics

---

# OCB Financial Correction and Reversal Semantics

## Purpose

This document establishes how correction, reversal, adjustment, and rollback concepts are treated within the OCB Platform v1.0.0 financial-event model.

The objective is to preserve historical financial truth while maintaining a clear boundary between:

* authoritative institutional financial activity;
* OCB observation and identity resolution;
* financial consequences represented within OCB's financial / analytical model;
* transaction-processing controls;
* subsequent corrective financial activity.

The document does not define physical database structures, ledger implementation, or transaction-processing mechanisms.

Those concerns belong to the appropriate later architectural and engineering stages.

---

# 1. Historical Truth Principle

Once an authoritative financial event or institutional financial activity has been observed within the OCB boundary, its historical occurrence must not be silently rewritten or deleted.

The fundamental principle is:

```text
Original Authoritative Activity
              ↓
        OCB Observation
              ↓
      Historical Record
              ↓
   Subsequent Information
              ↓
   Traceable Resolution
```

The original observation remains part of the historical record.

A subsequent correction to information does not retroactively make the original observation cease to have existed.

This distinction is important because OCB's analytical and supervisory functions may require reconstruction of:

* what occurred;
* what was originally observed;
* when it was observed;
* what was subsequently corrected;
* why the correction occurred;
* what information is currently considered authoritative.

---

# 2. Institutional Correction

## 2.1 Meaning

A correction is an institutional control action used to resolve erroneous or incomplete information within the originating institution.

Examples may include:

* correcting an erroneous transaction attribute;
* correcting an internally identified customer or activity record;
* resolving an institutional processing error;
* correcting information before an authoritative source record is exposed to OCB.

---

## 2.2 OCB Treatment

Institutional correction is **not an independent OCB financial event in v1.0.0**.

The originating institution remains authoritative for the institutional activity and financial object that it owns.

Therefore:

```text
Institutional Financial Object
              ↓
       Source Institution
              ↓
    Internal Correction / Control
              ↓
     Authoritative Source Output
              ↓
             OCB
```

OCB does not reproduce the originating institution's complete internal correction workflow merely for architectural completeness.

This preserves the established institutional boundary:

> **Institutional financial objects remain institution-owned → OCB observes/resolves them → their financial consequences can be represented in OCB's financial / analytical model.**

OCB observation, identity resolution, or analytical representation does not transfer ownership of the underlying institutional object.

---

# 3. Post-Observation Correction

A distinction must be maintained between:

1. correction performed by the source institution before OCB observes the authoritative information; and
2. information subsequently corrected after OCB has already observed the original information.

The first is an originating-institution control matter.

The second is a historical-provenance matter.

If information already observed by OCB is subsequently corrected:

```text
Original Observation
        ↓
Historical Record Preserved
        ↓
Subsequent Corrected Information
        ↓
Traceable Relationship
```

The platform must not silently replace the historical observation in a manner that prevents reconstruction of what OCB originally observed.

Where a future implementation requires correction after observation, the preserved information should allow determination of:

* the original value;
* the corrected value;
* the relevant institutional/source identity;
* the applicable event or activity reference;
* the correction reason where available;
* the original observation timestamp;
* the subsequent correction timestamp;
* which version is currently considered authoritative.

The physical representation of this provenance belongs to the subsequent data-engineering and operational-schema stages.

---

# 4. Correction Does Not Automatically Create a Financial Consequence

A correction to an attribute does not necessarily constitute a new financial event.

For example:

```text
Original Transaction
        ↓
Incorrect Attribute
        ↓
Attribute Corrected
        ↓
No New Financial Consequence
```

Conversely, if a future business requirement establishes that a financial consequence itself must be counteracted, that is not merely an attribute correction.

It would require separate reversal or corrective-financial semantics.

Therefore:

```text
Attribute Correction
        ≠
Financial Reversal
```

This distinction prevents ordinary data-quality correction from being incorrectly treated as a monetary event.

---

# 5. Reversal

## 5.1 Meaning

A reversal is a subsequent financial occurrence that counteracts or reverses the financial consequence of an already-established financial event.

Conceptually:

```text
Original Financial Event
          ↓
Original Financial Consequence
          ↓
      Reversal
          ↓
Counteracting Financial Consequence
```

A reversal is therefore materially different from correcting an attribute on the original record.

---

## 5.2 v1.0.0 Treatment

Reversal is **not included as an approved OCB financial-event type for v1.0.0**.

The current observable institutional domains do not establish a sufficiently strong requirement for modelling an independent reversal event.

Introducing reversal would require explicit semantics for:

* the original financial event;
* the reversal occurrence;
* the relationship between the two;
* the financial consequence of the reversal;
* ledger representation;
* reconciliation;
* chronological state reconstruction;
* lifecycle implications.

Those requirements are outside the current v1.0.0 event inventory.

---

## 5.3 Future Reversal Boundary

A future architecture may establish a legitimate requirement for reversal.

Examples could include:

* explicit customer-initiated reversal workflows;
* post-settlement reversal;
* inter-institution financial disputes;
* additional settlement infrastructure;
* bank or escrow participation;
* other concrete financial-processing requirements.

If such a requirement is introduced, reversal must be modelled as a **traceable subsequent occurrence** rather than as a modification or deletion of the original event.

Conceptually:

```text
Original Event
      ↓
Original Financial Consequence
      ↓
Reversal Event
      ↓
Counteracting Consequence
```

The original event remains historically observable.

Any material introduction of reversal must be evaluated through the appropriate architectural governance process.

---

# 6. Reversal and Financial State

A future reversal, if eventually introduced, would not erase the original financial consequence from historical event history.

Instead, state reconstruction would account for both occurrences:

```text
Original Event
      ↓
Original Consequence
      ↓
Financial State
      ↓
Reversal Event
      ↓
Counteracting Consequence
      ↓
Subsequent Financial State
```

This preserves the ability to answer both:

* what originally happened; and
* what subsequently changed the resulting financial position.

No reversal state-transition rule is authorised for v1.0.0.

---

# 7. Adjustment

## 7.1 Meaning

`Adjustment` is not sufficiently specific to constitute a controlled financial event within the v1.0.0 model.

The term could represent materially different institutional processes, including:

* accounting correction;
* fee correction;
* balance adjustment;
* reconciliation adjustment;
* operational remediation;
* other institution-specific activity.

These processes do not necessarily have the same financial semantics.

---

## 7.2 v1.0.0 Treatment

Adjustment is therefore **not included as a v1.0.0 authoritative financial event**.

A future adjustment mechanism would require an explicit business definition establishing:

* what is being adjusted;
* why it is being adjusted;
* which financial object or state is affected;
* whether a financial consequence is created;
* whether the adjustment relates to an existing event;
* how the adjustment is reconciled;
* how historical truth is preserved.

No generic adjustment mechanism is introduced merely for completeness.

---

# 8. Rollback

Rollback is fundamentally different from correction and reversal.

Rollback is a **transaction-processing control**, not a financial event.

Conceptually:

```text
Financial Processing
        ↓
Validation / Execution
        ↓
Failure before Commit
        ↓
Rollback
        ↓
No Financial State Committed
```

Rollback prevents an incomplete processing operation from becoming committed financial state.

It therefore belongs to transaction-processing and atomicity design rather than the authoritative financial-event catalogue.

This is consistent with the later financial-processing architecture, where atomic processing must ensure that required financial changes either all succeed or all fail.

---

# 9. Rollback vs Reversal

The distinction is mandatory:

| Concept        | Meaning                                                                               |
| -------------- | ------------------------------------------------------------------------------------- |
| **Rollback**   | Processing control that prevents an incomplete operation from committing              |
| **Correction** | Resolution of erroneous information or attributes                                     |
| **Reversal**   | Subsequent financial occurrence that counteracts an established financial consequence |
| **Adjustment** | Generic financial-control concept requiring a specific business definition            |

The temporal distinction is particularly important:

```text
ROLLBACK

Processing
   ↓
Failure before commitment
   ↓
No financial state established
```

versus:

```text
REVERSAL

Original Event
   ↓
Financial State Established
   ↓
Subsequent Reversal
   ↓
Counteracting Consequence
```

A rollback therefore does not create a historical financial event.

A reversal, if eventually introduced, would create a subsequent historical occurrence.

---

# 10. Relationship to the OCB Ledger / Financial Model

A ledger entry is **not** a correction event, reversal event, or replacement for the originating financial activity.

The conceptual relationship remains:

```text
Institutional Financial Activity
              ↓
      Financial Consequence
              ↓
        Ledger Entry
              ↓
      Financial Position
              ↓
       OCB Analysis
```

The ledger entry represents the accounting consequence arising from authoritative financial activity.

It does not replace the originating institutional financial object or financial event.

Therefore:

```text
Financial Event
      ≠
Ledger Entry
```

and:

```text
Ledger Entry
      ≠
Correction / Reversal
```

The ledger / financial-core model may represent consequences required for reconciliation and state reconstruction without assuming ownership of the underlying institutional financial object.

This is consistent with the conceptual model established in WP-2.1.

---

# 11. Cross-Institutional Correction and Reversal Boundary

OCB must not create corrective financial relationships merely because two institutional activities can be analytically related.

For example:

```text
SIKACREDIT
Loan Disbursement
        ↓
OCB Identity Resolution
        ↓
ANANSE Customer / Wallet Activity
```

does not establish a direct SikaCredit → Ananse Wallet ownership relationship.

Likewise:

```text
OMAN REMIT
Remittance
        ↓
OCB Identity Resolution
        ↓
ANANSE Customer / Wallet Activity
```

does not automatically establish a direct Oman Remit → Ananse Wallet relationship.

The logical model deliberately does not create such direct foreign-key relationships. Cross-institutional financial consequences are handled through the appropriate financial-core architecture rather than by forcing institutional objects into shared relationships.

Consequently, a correction or reversal must not be invented merely to explain an analytical relationship between institutional domains.

---

# 12. Historical Financial Truth and State Reconstruction

The exclusion of correction and reversal as v1.0.0 event types does not permit historical financial information to be silently rewritten.

The state-reconstruction model requires that authoritative financial positions remain reconstructable from valid financial consequences while preserving chronology and institutional ownership.

Therefore:

```text
Historical Event
      ↓
Historical Consequence
      ↓
Historical State
```

must remain distinguishable from:

```text
Subsequent Information
      ↓
Corrective / Reversal Interpretation
      ↓
Subsequent State
```

where such subsequent activity becomes relevant in a future architecture.

OCB's financial / analytical representation may therefore contain the evidence necessary to reconcile historical and subsequently corrected information without transferring ownership of the source financial object to OCB.

---

# 13. v1.0.0 Decision

| Concept          | v1.0.0 Treatment                     | Rationale                                                                         |
| ---------------- | ------------------------------------ | --------------------------------------------------------------------------------- |
| **Correction**   | Not an OCB financial event           | Source-institution control; post-observation changes require preserved provenance |
| **Reversal**     | Excluded                             | No sufficiently strong v1.0.0 business requirement                                |
| **Adjustment**   | Excluded                             | Financial meaning is insufficiently defined                                       |
| **Rollback**     | Required processing control          | Prevents incomplete financial processing from committing state                    |
| **Ledger Entry** | Financial consequence representation | Does not replace originating institutional activity                               |

These exclusions are deliberate architectural boundaries rather than claims that the concepts are unimportant in real financial systems.

---

# 14. Future Architectural Boundary

Correction, reversal, or adjustment may be reconsidered where a concrete future requirement introduces:

* post-settlement financial correction;
* explicit reversal workflows;
* bank participation;
* escrow arrangements;
* external settlement obligations;
* inter-institution financial disputes;
* other financial-processing requirements that cannot be represented adequately by the current model.

Any such requirement must first establish its business semantics.

The resulting change must then be reflected in the relevant event, lifecycle, state, ledger, and reconciliation models.

Material architectural changes must follow the applicable ADR and governance process.

---

# 15. Relationship to Later Transaction Lifecycle Modelling

This document establishes the **financial-event semantics boundary**.

It does not define the complete lifecycle state machine for transactions.

States such as:

* initiated;
* validated;
* processing;
* successful;
* failed;
* rejected;
* reversed;
* corrected;

and their permissible transitions belong to the subsequent **WP-2.5 Transaction Lifecycle Model**.

This separation prevents WP-1.3 from prematurely defining operational processing states that belong to the later transaction-lifecycle architecture.

---

# 16. Status

**Status: REVISED / LOCKED**

The v1.0.0 financial-event model establishes:

1. institutional correction as an originating-institution control concept rather than an OCB financial event;
2. preservation of historical OCB observations where subsequently corrected information is received;
3. reversal as a future, traceable financial-event capability rather than a v1.0.0 event;
4. adjustment as an undefined concept requiring a concrete business meaning before adoption;
5. rollback as a processing-control mechanism rather than a financial event;
6. ledger entries as representations of financial consequences rather than originating events or corrective events;
7. institutional ownership as remaining with the originating institution throughout observation, resolution, reconciliation, and analytical representation.

No correction, reversal, or adjustment financial-event type is authorised for OCB Platform v1.0.0 by this ticket.

---

## Core Principle

> **Historical financial truth must not be silently rewritten. Source institutions remain authoritative for the financial objects they own; OCB observes and resolves those objects and may represent their financial consequences without assuming ownership. Correction is a control process, reversal is a distinct subsequent financial occurrence when explicitly required, adjustment requires a defined business meaning, and rollback is a processing control—not a financial event.**

**WP-1.3-T04 — REVISED AND LOCKED.**
