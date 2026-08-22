## Financial Entity Responsibility Definitions

The following definitions establish the business meaning, ownership, lifecycle, authoritative system, and relationships for the financial entities identified in WP-1.2-T01.

### Institution

| Field                        | Definition                                                                                                                                                                                             |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Term**                     | Institution                                                                                                                                                                                            |
| **Definition**               | An independent simulated financial institution participating in the OCB financial ecosystem. The v1.0.0 institutional domains are Ananse Telecom, SikaCredit, and Oman Remit.                          |
| **Context**                  | Institution establishes the organizational ownership and financial-domain context for observable activity within the OCB sandbox.                                                                      |
| **System / Domain**          | Institutional Domain Model                                                                                                                                                                             |
| **Ownership**                | Each institution owns its own simulated operational domain, business rules, financial processes, and authoritative financial information. OCB observes these domains but does not own or operate them. |
| **Related Concepts**         | Ananse Telecom; SikaCredit; Oman Remit; institutional boundary; customer; financial event; OCB observation boundary                                                                                    |
| **Financial Significance**   | Establishes which independent institution is responsible for a financial activity and its resulting financial consequences.                                                                            |
| **Analytical Significance**  | Enables institutional monitoring, cross-institution analysis, attribution of financial activity, and regulatory investigation.                                                                         |
| **Implementation Reference** | To be established during operational data-model design.                                                                                                                                                |
| **Status**                   | **Defined**                                                                                                                                                                                            |
| **Notes / Boundary**         | An Institution represents an independent domain, not a subsystem of OCB. OCB does not reproduce the institution's complete internal architecture.                                                      |

**Lifecycle:** Institutional existence is established for the simulation and remains stable for the v1.0.0 operating period. Institutional financial activity may vary over time without changing the institution's identity.

**Authoritative System:** The originating institution's simulated operational domain is authoritative for its own institutional financial activity and state.

**Relationships:** An Institution owns/operates financial activity within its domain and may be associated with Customers, Wallets, Loans, Merchants, Agents, Transactions, and other financial concepts according to the institution's domain.

---

### Customer

| Field                        | Definition                                                                                                                                                                                    |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Term**                     | Customer                                                                                                                                                                                      |
| **Definition**               | A simulated financial participant whose observable financial activity may be associated with one or more independent institutional domains.                                                   |
| **Context**                  | Used to provide a controlled shared identity for customer-level and cross-institution analysis within the OCB sandbox.                                                                        |
| **System / Domain**          | Cross-Institution Customer / Identity Model                                                                                                                                                   |
| **Ownership**                | Institutions own their respective institutional customer relationships and records. The shared simulation identity is an OCB modelling construct used for controlled supervisory correlation. |
| **Related Concepts**         | Institution; institutional customer identifier; shared simulation identity; Wallet; Loan; remittance activity; financial event                                                                |
| **Financial Significance**   | Provides the participant context required to associate financial activity with an individual simulated customer across relevant institutional domains.                                        |
| **Analytical Significance**  | Supports customer investigation, behavioural analysis, cross-institution correlation, transaction tracing, and exposure analysis.                                                             |
| **Implementation Reference** | To be established during customer and identity-model implementation.                                                                                                                          |
| **Status**                   | **Defined**                                                                                                                                                                                   |
| **Notes / Boundary**         | The shared simulation identity is an explicit v1.0.0 simplification. It does not represent production-grade national identity resolution or a universal operational customer system.          |

**Lifecycle:** A Customer may be represented as an active participant during the simulation period and may have financial relationships established, changed, or closed over time. The identity itself remains distinct from the lifecycle of any individual financial relationship.

**Authoritative System:** Institutional customer records remain authoritative within their respective institutions. The OCB shared simulation identity is authoritative only for the controlled analytical correlation representation.

**Relationships:** A Customer may be associated with an Institution and may participate in financial activity involving Wallets, Loans, and other observable financial activities. A Customer may have relationships with multiple institutions.

---

### Wallet

| Field                        | Definition                                                                                                                                             |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Term**                     | Wallet                                                                                                                                                 |
| **Definition**               | A simulated mobile-money value-holding entity operated within the Ananse Telecom domain and associated with a customer or other justified participant. |
| **Context**                  | Represents the wallet-based financial state used by Ananse for mobile-money activity.                                                                  |
| **System / Domain**          | Ananse Telecom — Mobile Money / Electronic Money                                                                                                       |
| **Ownership**                | Ananse Telecom owns the operational wallet and its authoritative financial state.                                                                      |
| **Related Concepts**         | Customer; Ananse Telecom; cash-in; cash-out; P2P transfer; merchant payment; financial event; ledger                                                   |
| **Financial Significance**   | Provides the financial state against which valid mobile-money financial events produce value changes.                                                  |
| **Analytical Significance**  | Supports wallet activity analysis, transaction behaviour, velocity analysis, liquidity-related analysis, anomaly detection, and investigation.         |
| **Implementation Reference** | To be established during Ananse operational data-model implementation.                                                                                 |
| **Status**                   | **Defined**                                                                                                                                            |
| **Notes / Boundary**         | OCB observes relevant wallet information but does not operate the wallet or become its operational source of truth.                                    |

**Lifecycle:** A Wallet may be created, become active for financial activity, and subsequently become inactive or closed. Its historical financial activity must remain traceable after its active lifecycle ends.

**Authoritative System:** Ananse Telecom's simulated operational financial system is authoritative for wallet state and wallet-related financial consequences.

**Relationships:** A Wallet is associated with Ananse Telecom and a Customer where applicable. Wallets participate in financial events such as cash-in, cash-out, P2P transfer, and merchant payment and may be referenced by ledger records.

---

### Loan

| Field                        | Definition                                                                                                                                                                         |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Term**                     | Loan                                                                                                                                                                               |
| **Definition**               | A simulated digital lending obligation originated and managed within the SikaCredit domain.                                                                                        |
| **Context**                  | Represents the financial obligation created through SikaCredit lending activity and its subsequent repayment and state progression.                                                |
| **System / Domain**          | SikaCredit — Digital Lending                                                                                                                                                       |
| **Ownership**                | SikaCredit owns the operational loan relationship, loan state, and financial consequences of lending activity within its domain.                                                   |
| **Related Concepts**         | Customer; SikaCredit; borrower role; loan disbursement; loan repayment; outstanding balance; loan state; credit exposure                                                           |
| **Financial Significance**   | Represents the principal financial obligation created through lending and the subsequent financial effects of disbursement and repayment.                                          |
| **Analytical Significance**  | Supports credit exposure analysis, repayment behaviour, delinquency/default analysis, lending-risk intelligence, customer investigation, and institutional monitoring.             |
| **Implementation Reference** | To be established during SikaCredit operational data-model implementation.                                                                                                         |
| **Status**                   | **Defined**                                                                                                                                                                        |
| **Notes / Boundary**         | Borrower is treated as a role associated with a Customer rather than as a separate first-class entity. OCB does not reproduce SikaCredit's complete internal lending architecture. |

**Lifecycle:** A Loan progresses through its established lending lifecycle, including origination, disbursement, repayment, and eventual closure or other defined terminal state. Exact state semantics will be established in later state-model and lending work.

**Authoritative System:** SikaCredit's simulated operational financial system is authoritative for the loan and its operational financial state.

**Relationships:** A Loan is associated with SikaCredit and a borrowing Customer and is affected by financial events including loan disbursement and loan repayment.

---

### Merchant

| Field                        | Definition                                                                                                                                                                                                                                                    |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Term**                     | Merchant                                                                                                                                                                                                                                                      |
| **Definition**               | A lightweight observable reference representing a merchant associated with Ananse Telecom merchant-payment activity.                                                                                                                                          |
| **Context**                  | Used to identify and analyse the merchant associated with observable merchant-payment transactions without modelling the merchant's internal operational or settlement architecture.                                                                          |
| **System / Domain**          | Ananse Telecom — Mobile Money / Electronic Money                                                                                                                                                                                                              |
| **Ownership**                | The merchant relationship and underlying merchant information belong to the relevant institutional domain. OCB maintains only the observable reference required for approved analytical and investigative purposes.                                           |
| **Related Concepts**         | Ananse Telecom; Customer; Wallet; merchant payment; transaction; financial event; investigation                                                                                                                                                               |
| **Financial Significance**   | Identifies the receiving merchant associated with a merchant-payment financial activity.                                                                                                                                                                      |
| **Analytical Significance**  | Supports transaction attribution, merchant-level investigation, suspicious merchant-payment analysis, and concentration analysis where required.                                                                                                              |
| **Implementation Reference** | To be established during operational data-model design.                                                                                                                                                                                                       |
| **Status**                   | **Defined**                                                                                                                                                                                                                                                   |
| **Notes / Boundary**         | Merchant is a lightweight observable reference, not an OCB-operated merchant-management system. Merchant settlement, float, acquiring, onboarding, and other internal merchant operations remain outside the OCB v1.0.0 boundary unless separately justified. |

**Lifecycle:** The reference may identify a merchant during the period in which the merchant is relevant to observable Ananse activity. Detailed merchant operational lifecycle is outside the OCB model.

**Authoritative System:** The originating Ananse domain is authoritative for the merchant relationship and underlying merchant information. OCB's merchant reference is an analytical/observational representation.

**Relationships:** A Merchant is associated with Ananse Telecom and may be referenced by merchant-payment financial events or transactions.

---

### Agent

| Field                        | Definition                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Term**                     | Agent                                                                                                                                                                                                                                                                                                                                                                           |
| **Definition**               | A lightweight observable reference representing an agent associated with Ananse Telecom agent-mediated financial activity, particularly cash-in and cash-out activity.                                                                                                                                                                                                          |
| **Context**                  | Used to identify and analyse the agent associated with observable agent-mediated transactions without reproducing the agent's internal operational architecture.                                                                                                                                                                                                                |
| **System / Domain**          | Ananse Telecom — Mobile Money / Electronic Money                                                                                                                                                                                                                                                                                                                                |
| **Ownership**                | The agent relationship and underlying agent information belong to Ananse Telecom. OCB maintains only the observable reference required for approved analytical and investigative purposes.                                                                                                                                                                                      |
| **Related Concepts**         | Ananse Telecom; Customer; Wallet; cash-in; cash-out; transaction; financial event; investigation                                                                                                                                                                                                                                                                                |
| **Financial Significance**   | Identifies the agent associated with relevant observable cash-in or cash-out activity.                                                                                                                                                                                                                                                                                          |
| **Analytical Significance**  | Supports transaction attribution, suspicious-agent investigation, concentration analysis, and geographic analysis where such analysis is justified.                                                                                                                                                                                                                             |
| **Implementation Reference** | To be established during operational data-model design.                                                                                                                                                                                                                                                                                                                         |
| **Status**                   | **Defined**                                                                                                                                                                                                                                                                                                                                                                     |
| **Notes / Boundary**         | Agent is a lightweight observable reference, not an OCB-operated agent-management system. Agent float, liquidity, settlement, commissions, network management, and other internal agent operations are outside the OCB v1.0.0 model unless separately justified. Geographic attributes must only be retained where required by an approved analytical or intelligence question. |

**Lifecycle:** The reference may identify an agent during the period in which the agent is relevant to observable Ananse activity. Detailed agent operational lifecycle is outside the OCB model.

**Authoritative System:** Ananse Telecom's domain is authoritative for the agent relationship and underlying agent information. OCB's agent reference is an analytical/observational representation.

**Relationships:** An Agent is associated with Ananse Telecom and may be referenced by agent-mediated financial events or transactions, particularly cash-in and cash-out activity.

---

## T02 Boundary

These definitions establish the business meaning, ownership, lifecycle, authoritative system, and relationships required by WP-1.2-T02.

They do not define:

* physical database schemas;
* tables;
* columns;
* primary or foreign keys;
* cardinalities;
* normalization;
* operational workflows;
* institutional integration mechanisms.

Those concerns belong to later implementation programmes.

The distinction between **core financial entities** and **lightweight observable reference entities** is intentional. The latter provide sufficient observable identity for financial intelligence and investigation without requiring OCB to reproduce the internal operational architecture of the originating institution.
