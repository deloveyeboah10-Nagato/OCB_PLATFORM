# OCB PLATFORM v1.0.0

## SUPERVISORY INTELLIGENCE QUESTIONS

### Official Work Package Definition

**Programme:** OCB Platform v1.0.0  
**Work Package:** Supervisory Intelligence Questions  
**Component:** Supervisory Intelligence, Institutional Monitoring & Cross-Institution Investigation  
**Purpose:** Define the canonical questions the OCB v1.0.0 dashboard is designed to support through its existing institutional monitoring outputs, financial event sequences, behavioural analysis, and cross-institution intelligence signals.  
**Implementation Status:** The 12-question set is implemented in the completed dashboard. The questions direct users to existing analytical outputs and supporting event-level evidence; they do not represent automated regulatory findings.

---

## 1. Document Purpose

This document establishes the canonical supervisory intelligence question set for the Osagyefo Central Bank Digital Financial Intelligence Platform.

The questions define the investigative direction of the delivered dashboard. They connect observed institutional activity and financial events to specific analytical outputs, allowing a reviewer to examine customer behaviour, transaction patterns, lending activity, remittance flows, and relationships across the three simulated institutions.

The questions are intended to guide the examination of existing evidence. They do not establish that an institution or customer has committed misconduct, nor do they establish causation merely because financial events occur in a particular sequence.

The 12 questions below are the canonical question set for the OCB v1.0.0 dashboard.

## 2. Supervisory Intelligence Questions

### 2.1 SikaCredit Lending and Repayment Behaviour

**Question 1 — Debt Recycling and Repayment Deficiency**

During SikaCredit's November 2025 lending surge, which customers exhibit elevated debt-recycling repayment-deficiency, reborrowing-rapidity and recurrence signals?

**Question 2 — Borrower Composition and Lending Frequency**

Was the November 2025 lending surge driven mainly by first-time borrowers, repeat borrowers, or frequent borrowing and short inter-loan intervals?

**Question 3 — Credit-Value Escalation and Credit Obligations**

Among customers receiving loans during the November 2025 surge, which exhibit credit-value escalation, escalation recurrence or credit-obligation signals?

### 2.2 Ananse Transaction Activity and Behaviour

**Question 4 — December Transaction Surge**

Which customers contributed materially to Ananse's December 2025 transaction surge, and what existing TAE or cash-in → P2P → cash-out signals are associated with them?

**Question 5 — Failed or Rejected Transactions and Behavioural Signals**

Are customers associated with failed or rejected Ananse transactions also exhibiting elevated overnight transaction rapidity or residual-value signals?

### 2.3 Inbound Remittances and Cross-Institution Activity

**Question 6 — Inbound Remittances from FATF-Flagged Origins**

Which customers account for the highest volume and value of successful inbound remittances from FATF-flagged origins, and what failed or rejected activity is associated with them?

**Question 7 — Loan Disbursement to Ananse Cash-Out Sequences**

Among customers receiving SikaCredit loans during the November 2025 surge, which exhibit loan-disbursement → Ananse cash-out sequences with elevated rapidity, amount-ratio or recurrence signals?

**Question 8 — FATF-Flagged Remittance-to-Cash-Out Sequences**

Which FATF-flagged Oman Remit remittance-to-cash-out sequences during Q4 2025 also exhibit TAE transaction-type amount anomalies in the associated Ananse cash-outs?

**Question 9 — Inbound Remittance and P2P Redistribution**

Among customers contributing to the December 2025 increase in inbound remittances, which exhibit the existing inbound remittance → Ananse P2P redistribution signals?

**Question 10 — Inbound Remittances and Loan Repayments**

Which inbound Oman Remit funds were associated with SikaCredit loan repayments during February 2025, following the decline in repayment value?

### 2.4 Outbound Remittances and Domestic Funding Relationships

**Question 11 — Ananse Cash-In to Outbound Remittance**

Did successful outbound remittances follow domestic Ananse cash-ins closely enough, and with enough value correspondence or repeated remittance behaviour, to merit review?

**Question 12 — SikaCredit Loan Disbursement to Outbound Remittance**

Did successful outbound remittances follow SikaCredit loan disbursements, with timing, value correspondence or repeated remittance behaviour that merits review?

---

## 3. Analytical Scope

The questions direct attention to four broad areas of supervisory examination.

| Area | Questions | Analytical focus |
|---|---|---|
| Lending and repayment behaviour | 1–3 | Debt recycling, repayment deficiency, borrower composition, borrowing intervals, credit-value escalation, and credit obligations |
| Transaction activity and behaviour | 4–5 | Institutional transaction surges, transaction-type anomalies, failed or rejected activity, overnight rapidity, and residual-value signals |
| Inbound remittances and cross-institution activity | 6–10 | Remittance origins, associated transaction activity, lending-to-cash-out sequences, redistribution, and remittance-to-repayment relationships |
| Outbound remittances and domestic funding relationships | 11–12 | Temporal proximity, value correspondence, and repeated behaviour involving domestic cash-ins or loan disbursements followed by outbound remittances |

This grouping describes the questions' investigative themes. It does not introduce additional analytical rules or claim that every possible relationship between the three institutions is covered.

## 4. How the Questions Should Be Used

The questions are entry points into the platform's existing analytical outputs.

A reviewer should use the relevant dashboard outputs and supporting event-level evidence to examine:

- **Institutional activity:** changes in transaction counts, transaction values, lending activity, repayment activity, and remittance activity.
- **Customer contribution:** the customers and events associated with a material institutional or monthly change.
- **Temporal relationships:** the order of events and the intervals between relevant financial events.
- **Value relationships:** whether event amounts exhibit the correspondence or differences identified by an existing analytical output.
- **Repeated behaviour:** whether a relevant pattern recurs for a customer or across multiple events.
- **Associated signals:** whether other existing analytical signals appear alongside the behaviour under examination.

The relevant analytical grain must be respected. Where a question concerns an event sequence, recurrence interval, or temporal relationship, the underlying events and their timestamps matter. An aggregate count or value alone cannot establish the order, timing, or relationship between individual events.

The reviewer should distinguish the question being investigated, the evidence returned by the analytical output, and the interpretation drawn from that evidence.

## 5. Interpretation and Supervisory Boundaries

The questions identify patterns that may merit examination. They do not constitute findings of misconduct.

In particular:

1. **Temporal sequence is not proof of funding.** An event occurring before another event does not, by itself, establish that the earlier event funded the later one.
2. **Value correspondence is not proof of a direct financial link.** Similar or related amounts do not independently establish that funds moved directly between the observed events.
3. **A signal is not a conclusion.** An elevated, unusual, repeated, or anomalous pattern is a reason to examine the evidence, not automatic proof of fraud, money laundering, illicit funding, or misconduct.
4. **Cross-institution association is not causation.** A relationship between activity recorded by different institutions does not establish that one institution's activity caused the other.
5. **Synthetic evidence has defined limits.** OCB operates on simulated financial data. Its outputs demonstrate analytical methods and investigative reasoning; they are not findings about real customers, institutions, or financial activity.
6. **Supervisory judgement remains necessary.** Any interpretation must be grounded in the underlying evidence and the limits of the analytical method used.

The platform supports structured examination of financial activity. It does not replace evidence assessment or turn analytical signals into automatic regulatory determinations.

## 6. Canonical Status and Change Control

The 12 questions in this document constitute the canonical supervisory intelligence question set for OCB v1.0.0.

The same question set should be maintained consistently across:

- The GitHub project README.
- The OCB Project Control Document.
- The public dashboard.
- This standalone Supervisory Intelligence Questions document.

Changes to the question wording, scope, or order should be made consistently across those locations. A new question should not be described as implemented unless the delivered analytical outputs and dashboard support it.

The document does not independently define new signals, calculations, or intelligence rules. Those remain governed by the relevant analytical implementations and their supporting documentation.

## 7. Governing Principle

**Supervisory questions direct the investigation; analytical outputs provide evidence; interpretation must remain proportionate to what that evidence establishes.**

OCB's purpose is to transform financial events into intelligence that can be examined and explained—not to treat unusual patterns or observed relationships as proof of wrongdoing.