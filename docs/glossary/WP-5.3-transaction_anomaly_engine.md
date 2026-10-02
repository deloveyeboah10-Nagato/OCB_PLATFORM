# OCB PLATFORM v1.0.0

## WORK PACKAGE 5.3 — RISK INTELLIGENCE

### Official Work Package Definition

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-5.3 — Risk Intelligence
**Component:** Transaction Anomaly Engine
**Purpose:** Identify transactions that exhibit unusual value, customer-relative, transaction-type, or rapid temporal behaviour for regulatory and investigative analysis
**Implementation Status:** Complete — Transaction Anomaly Engine constructed and validated

## Transaction Anomaly Engine — Documentation

### Purpose

Identify transactions that are unusual relative to the OCB transaction population and relevant contextual dimensions.

### Analytical signals

1. **Global transaction-value deviation**

   * Measures deviation from the overall transaction-value distribution.
   * Reference population: all OCB transactions.
   * Method: median + MAD.

2. **Customer-relative value deviation**

   * Measures how unusual a transaction amount is for the individual customer.
   * Reference population: customer's transaction history.
   * Method: customer median + customer MAD.

3. **Transaction-type/context deviation**

   * Measures how unusual an amount is within its transaction type.
   * Reference population: transactions of the same type.
   * Method: transaction-type median + transaction-type MAD.

4. **Temporal/velocity anomaly**

   * Measures unusually short transaction intervals.
   * Current implementation deliberately focuses on the **rapid-transaction side** of the distribution.
   * Reference population: transaction intervals across customers.
   * Method: median + MAD.

### Constructs

| Construct                                 | Signals           | Purpose                                                                            |
| ----------------------------------------- | ----------------- | ---------------------------------------------------------------------------------- |
| Global + Type                             | Global + Type     | Identify transactions unusual both overall and within their transaction type       |
| Global + Customer                         | Global + Customer | Identify transactions unusual overall and relative to the customer's own behaviour |
| Global + Rapid Velocity                   | Global + Velocity | Identify rapid transactions that are also unusual in value                         |
| Global + Customer + Type + Rapid Velocity | All four          | Provide deeper multi-dimensional investigation context                             |

### Key design decision

The engine **does not produce a combined risk score**.

The individual scores remain separate because they answer different analytical questions:

* **Global:** unusual across OCB?
* **Customer:** unusual for this customer?
* **Type:** unusual for this transaction type?
* **Velocity:** unusually rapid?

A high score in one dimension therefore does not imply a high score in another.

### Important statistical interpretation

MAD scores measure **distance from a reference distribution**, not transaction magnitude.

Consequently, a smaller transaction can legitimately have a higher anomaly score than a larger transaction if it is farther from the reference median.

Example from the completed construct:

* ~GHS 22 → global score ~1.22
* ~GHS 2,090 → global score ~1.03

This is statistically consistent because the global median is ~GHS 1,145.

### Current limitations / boundaries

* No universal anomaly threshold has been established.
* No combined risk score has been established.
* Velocity currently represents **rapid temporal behaviour**, not dormancy or long-gap behaviour.
* An anomaly score indicates **unusual behaviour**, not fraud or regulatory misconduct.
* Customer-relative scores with zero MAD are treated as undefined rather than artificially converted to zero.
* The engine provides investigation intelligence; regulatory judgement remains outside the engine.

### Validation status

**Transaction Anomaly Engine: COMPLETE**

Four constructs have been implemented and tested at transaction grain.

The engine is now ready to serve as an input to scenario validation and regulatory/investigative workloads.
