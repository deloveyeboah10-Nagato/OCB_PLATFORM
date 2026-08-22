# OCB Financial Correction and Reversal Semantics

## Purpose

This document establishes how financial errors, corrections, reversals, and adjustments are treated within the OCB Platform v1.0.0 financial-event model.

The objective is to ensure that historical financial truth is not silently rewritten.

This document does not introduce physical database structures or implementation mechanisms.

---

## 1. Historical Truth Principle

Once a financial event has been accepted as authoritative within the OCB observation boundary, its historical occurrence must not be silently rewritten or deleted.

Where a future architecture requires a change to an established financial state, the relationship between the original occurrence and the subsequent action must remain traceable.

```text
Original Financial Event
        ↓
Historical Record
        ↓
Subsequent Corrective Action
        ↓
Traceable Relationship
````

The original event remains part of the historical record.

---

# 2. Correction

## 2.1 Meaning

A correction is an institutional control action used to resolve erroneous information before or at the point where authoritative information is exposed to OCB.

Examples may include:

* correcting an erroneous transaction attribute;
* correcting an internally identified data error;
* resolving an institutional processing error before authoritative output.

## 2.2 OCB Treatment

Correction is **not an independent OCB financial event in v1.0.0**.

The sandbox assumes that information received from Ananse Telecom, SikaCredit, and Oman Remit has passed through the originating institution's applicable internal controls.

OCB therefore observes the authoritative result rather than reproducing each institution's internal correction workflow.

## 2.3 Historical Truth

A correction must not be implemented by silently overwriting an already-established OCB financial event.

If a future requirement requires correction after OCB ingestion, the correction mechanism must preserve:

* the original record;
* the corrected information;
* the relationship between them;
* the reason for correction;
* appropriate timestamps.

---

# 3. Reversal

## 3.1 Meaning

A reversal is a subsequent financial action that counteracts or reverses the financial consequence of an already-established financial event.

Conceptually:

```text
Original Event
      ↓
Financial Consequence
      ↓
Reversal
      ↓
Counteracting Financial Consequence
```

A reversal is therefore fundamentally different from correcting an attribute of an existing record.

## 3.2 OCB Treatment

Reversal is **not included as a v1.0.0 OCB financial event**.

The current OCB observable domains do not establish a sufficiently strong business requirement for modelling customer-initiated reversals, institutional reversals, escrow reversals, or other reversal mechanisms.

Introducing reversal would require additional semantics for:

* the original event;
* the reversal event;
* the relationship between them;
* the resulting ledger consequences;
* reconciliation;
* reconstructed historical state.

That complexity is not justified by the current v1.0.0 intelligence requirements.

## 3.3 Future Boundary

A future architecture involving additional financial institutions, banks, escrow arrangements, external settlement infrastructure, or explicit reversal workflows may establish a legitimate requirement for reversal.

Such a requirement must be evaluated as an architectural change rather than introduced implicitly.

---

# 4. Adjustment

## 4.1 Meaning

Adjustment is not sufficiently specific to represent a controlled financial event within the v1.0.0 model.

The term could represent multiple institutional processes with different financial meanings.

## 4.2 OCB Treatment

Adjustment is therefore **not included as a v1.0.0 financial event**.

A future adjustment mechanism must first establish:

* what is being adjusted;
* why it is being adjusted;
* which original financial state is affected;
* whether a new financial consequence is created;
* how the adjustment relates to the original event.

---

# 5. Rollback vs Reversal

Rollback and reversal are distinct concepts.

## Rollback

A rollback concerns an incomplete database transaction or processing operation.

```text
Processing
    ↓
Failure before commit
    ↓
Rollback
    ↓
No financial state committed
```

Rollback therefore prevents an incomplete operation from becoming authoritative financial state.

## Reversal

A reversal occurs after an original financial event has already established financial state.

```text
Original Event
    ↓
Financial State Established
    ↓
Reversal Event
    ↓
Counteracting Financial Consequence
```

A reversal therefore does not erase the original event.

It creates a subsequent financial occurrence that must remain traceable to it.

---

# 6. v1.0.0 Decision

| Concept    | v1.0.0 Treatment               | Reason                                                           |
| ---------- | ------------------------------ | ---------------------------------------------------------------- |
| Correction | Excluded as OCB event          | Treated as originating-institution internal control              |
| Reversal   | Excluded                       | No sufficiently strong v1.0.0 business requirement               |
| Adjustment | Excluded                       | Insufficiently defined financial meaning                         |
| Rollback   | Required as processing control | Prevents incomplete transactions from committing financial state |

The exclusions do not imply that these concepts are unimportant in real financial systems.

They indicate that they are outside the required observable financial architecture of OCB Platform v1.0.0.

---

# 7. Historical Truth Requirement

The exclusion of correction and reversal from the v1.0.0 event catalogue does not permit historical financial information to be silently rewritten.

Where an authoritative source subsequently provides materially different information, the platform must preserve sufficient provenance to determine:

```text
What was originally observed?
        ↓
When was it observed?
        ↓
What information was subsequently provided?
        ↓
What is currently considered authoritative?
```

The detailed implementation of such provenance is addressed by the platform's data-engineering and ledger design.

---

# 8. Future Architectural Boundary

Correction, reversal, or adjustment may be reconsidered if a future OCB requirement introduces scenarios such as:

* bank participation;
* escrow accounts;
* external settlement obligations;
* explicit customer-initiated reversal workflows;
* post-settlement financial corrections;
* inter-institution financial dispute processing.

Any such requirement must establish the business semantics before introducing a corresponding event or state transition.

Material architectural changes must be documented through the ADR process.

---

# 9. Status

**Status:** Defined

Correction, reversal, and adjustment semantics have been established for v1.0.0.

No new correction, reversal, or adjustment financial-event types are authorised by this document.

---

## Core Principle

> **Historical financial truth is preserved; internal correction is not reproduced unnecessarily; and a future reversal, where required, must be represented as a traceable subsequent financial action rather than as a silent replacement of the original event.**

```

This closes **WP-1.3-T04** without accidentally turning the OCB sandbox into an EMI, bank, or settlement-system architecture.
```
