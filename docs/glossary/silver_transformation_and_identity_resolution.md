# OCB PLATFORM v1.0.0

## SILVER TRANSFORMATION & IDENTITY RESOLUTION METHODOLOGY

**Programme:** OCB Platform v1.0.0  
**Component:** Data Engineering — Silver Layer  
**Status:** Reconciled Methodology  
**Implementation Reference:** `silver_transformations_final_load.sql`

---

# 1. PURPOSE

This document defines the methodology used to transform validated Bronze records into standardized Silver entities across Ananse Telecom, SikaCredit, and Oman Remit.

It establishes the following:

- Source-data standardization.
- Canonical OCB customer representation.
- Cross-domain customer identity mapping.
- Source-specific transformation rules.
- Reference-data enrichment.
- Derived analytical attributes.
- Identity propagation across Silver entities.
- Silver loading and verification.

The document describes the implemented data transformation architecture. It does not replace the SQL implementation or introduce additional processing capabilities.

---

# 2. TRANSFORMATION ARCHITECTURE

The Silver layer transforms validated Bronze records into standardized, analytically usable representations while preserving their source relationships.

The transformation follows this sequence:

```text
VALIDATED BRONZE DATA
         |
         v
SOURCE-DATA STANDARDIZATION
         |
         v
IDENTITY MAPPING
         |
         v
BUSINESS-RULE TRANSFORMATION
         |
         v
REFERENCE-DATA ENRICHMENT
         |
         v
SILVER ENTITIES
         |
         v
VERIFICATION
```

Identity mapping and business-rule transformation are applied according to the dependencies of each Silver entity.

The Silver transformation uses a full-refresh strategy. The load executes within a single transaction, allowing the transformation to roll back if an error prevents successful completion.

Silver retains the source-system identifiers and financial records required for traceability. The addition of `ocb_customer_id` provides a common analytical identity without replacing institutional identifiers.

---

# 3. SOURCE SYSTEMS AND CUSTOMER IDENTITY

OCB integrates customer records from three independent institutional domains:

| Institution | Source entity prefix |
|---|---|
| Ananse Telecom | `AN-` |
| SikaCredit | `SC-` |
| Oman Remit | `OR-` |

The source systems maintain their own customer identifiers and financial records.

Consequently, the same underlying customer may have multiple institutional records.

OCB addresses this through a canonical customer representation and a separate source-to-OCB identity mapping.

These components serve different purposes and must not be treated as interchangeable.

## 3.1 Canonical Customer Record

The canonical customer record is stored in:

`silver.ocb_customer`

It provides the OCB-level customer representation used by the analytical model.

Where multiple source records belong to the same resolved OCB customer, one record is selected to represent that customer in the canonical customer table.

Representative-record selection determines which source record supplies the canonical profile. It does not, by itself, establish cross-domain identity.

## 3.2 Source-to-OCB Identity Mapping

The source-to-OCB mapping is stored in:

`silver.ocb_customer_identity`

It associates an institutional customer identifier with the corresponding `ocb_customer_id`.

The validated identity-resolution output is persisted separately in:

`silver.ocb_customer_identity_resolved`

The resolved mapping preserves the relationship between institutional customer records and their validated cross-domain identities.

**The canonical customer record and the identity bridge are separate architectural components.** Selecting a representative profile must not replace, regenerate, or independently redefine the validated source-to-OCB assignments.

---

# 4. IDENTITY-RESOLUTION METHODOLOGY

## 4.1 Source Customer Population

The identity-resolution process covers the combined customer populations of:

- Ananse Telecom.
- SikaCredit.
- Oman Remit.

The configured source population contains 4,300 institutional customer records.

The validated identity-resolution output contains 3,635 distinct resolved cross-domain identities and 3,635 associated OCB customer identities.

These counts describe different levels of representation:

| Measure | Count |
|---|---:|
| Institutional customer records | 4,300 |
| Resolved cross-domain identities | 3,635 |
| Resolved OCB customer identities | 3,635 |

The difference between institutional records and resolved identities reflects the presence of multiple institutional records associated with the same simulated customer.

## 4.2 Identity Ground Truth

The project uses synthetic identity ground truth to validate cross-institution customer relationships.

The validated mapping associates source records with the corresponding `cross_domain_id` and `ocb_customer_id`.

The identity-resolution output was validated and frozen before being consumed by the Silver transformation.

The frozen mapping is therefore the authoritative source of cross-domain identity assignments within OCB v1.0.0.

The transformation does not independently infer new cross-domain relationships by matching customer names or other descriptive attributes.

## 4.3 Identity Attributes and Standardization

Customer attributes used in the broader customer-standardization process include:

```text
first_name
last_name
date_of_birth
phone_number
email
```

Standardization includes applicable trimming and case normalization.

These transformations improve consistency in the descriptive representation of customer records.

However, identical standardized attributes must not be treated as sufficient proof that two records represent the same person. Conversely, differences in descriptive attributes must not independently override an established identity assignment.

The validated identity mapping and the standardized customer profile therefore have distinct responsibilities.

## 4.4 Identity Mapping Structure

The resolved identity mapping contains:

```text
source_entity
source_customer_id
cross_domain_id
ocb_customer_id
```

The mapping preserves the institutional origin of each customer record while associating it with the validated OCB identity.

The generator's `cross_domain_id` provides synthetic identity ground truth for the simulation. It is not a replacement for the institutional source identifier or the canonical OCB customer key.

The identity bridge exposes the `ocb_customer_id` needed by downstream Silver entities.

---

# 5. CANONICAL CUSTOMER CONSTRUCTION

Canonical customer construction determines which source record represents each OCB customer in `silver.ocb_customer`.

This process is distinct from identity resolution.

## 5.1 Representative-Record Selection

Within a resolved identity group, source records are ranked using:

```text
created_at DESC
source_entity ASC
source_customer_id ASC
```

The ranking prioritizes the most recently created record, with the remaining attributes providing deterministic tie-breaking.

The representative record is selected through `ROW_NUMBER()` and identified by:

```text
flag = 1
```

The selected record supplies the canonical customer profile.

## 5.2 Relationship to the Frozen Identity Mapping

Representative selection must operate within the customer group established by the validated identity assignments.

Standardized descriptive attributes may be used to prepare customer records, but independent grouping by those attributes must not redefine the frozen identity mapping.

The required relationship is:

```text
VALIDATED IDENTITY ASSIGNMENTS
             |
             v
RESOLVED OCB CUSTOMER GROUPS
             |
             v
REPRESENTATIVE-RECORD SELECTION
             |
             v
silver.ocb_customer
```

The identity bridge retains the source-to-OCB relationships independently:

```text
FROZEN IDENTITY MAPPING
             |
             v
silver.ocb_customer_identity_resolved
             |
             v
silver.ocb_customer_identity
```

This separation prevents canonical profile selection from becoming a second identity-resolution process.

## 5.3 Population Consistency

The canonical customer population must be compatible with the validated identity population.

In particular:

- Each resolved OCB customer must have a corresponding canonical customer record.
- Each source-to-OCB mapping must reference a valid OCB customer.
- Representative selection must not merge separately resolved identities.
- Representative selection must not split one resolved identity into multiple canonical customers.
- The source records must remain traceable through their institutional identifiers and identity mappings.

These requirements define the consistency expected between canonical customer construction and identity propagation.

---

# 6. CROSS-DOMAIN IDENTITY PROPAGATION

Once the identity bridge is loaded, source-specific Silver entities obtain their OCB identity through the institutional mapping.

The relationship is:

```text
source_entity
      +
source_customer_id
      |
      v
silver.ocb_customer_identity
      |
      v
ocb_customer_id
```

The mapping uses both the source entity and its source customer identifier to identify the appropriate institutional record.

This is necessary because customer identifiers belong to independent source systems and are not assumed to be globally unique.

The resulting `ocb_customer_id` allows analytical queries to associate customer activity across the three institutional domains.

Institutional identifiers remain available for source-level traceability.

---

# 7. ANANSE CUSTOMER TRANSFORMATION

Ananse customer records are standardized before loading into Silver.

Applicable transformations include:

| Attribute | Transformation |
|---|---|
| `customer_id` | Trim surrounding whitespace |
| `first_name` | Lowercase and trim |
| `last_name` | Lowercase and trim |
| `nationality` | Lowercase and trim |
| `occupation` | Lowercase and trim |
| `phone_number` | Trim surrounding whitespace |
| `email` | Trim surrounding whitespace |

The source customer identifier is mapped through the OCB identity bridge using:

```text
source_entity = 'ANANSE'
source_customer_id = customer_id
```

The resulting Silver customer record retains its institutional identity and receives the corresponding `ocb_customer_id`.

---

# 8. ANANSE WALLET TRANSFORMATION

Ananse wallet records are loaded from Bronze with their source identifiers preserved.

The wallet's customer relationship is used to retrieve the corresponding OCB identity.

```text
ANANSE WALLET
      |
      v
source customer identifier
      |
      v
silver.ocb_customer_identity
      |
      v
ocb_customer_id
```

The transformation preserves the institutional customer relationship while making the canonical OCB identity available for analytical use.

The wallet remains an Ananse entity. Adding `ocb_customer_id` does not change its institutional ownership or source identity.

---

# 9. ANANSE TRANSACTION TRANSFORMATION

Ananse transaction records are standardized and enriched using the relevant reference data.

## 9.1 Reference Mappings

The transformation resolves applicable reference identifiers for:

- Transaction type.
- Transaction channel.
- Transaction status.
- Currency.

The corresponding reference values are incorporated into the Silver transaction representation.

## 9.2 Location Parsing

The source transaction location uses the combined structure:

```text
region|town
```

Silver separates this into:

```text
transaction_location_region
transaction_location_town
```

This makes region and town independently available for analytical grouping.

## 9.3 Customer Identity

The transaction's source customer identifier is mapped through the OCB identity bridge.

The resulting record retains its institutional transaction identifier, customer relationship, transaction amount, timestamp, status, channel, type, and other implemented attributes.

The transformation standardizes and enriches the source event; it does not create a replacement financial event.

---

# 10. SIKACREDIT CUSTOMER TRANSFORMATION

SikaCredit customer records undergo the applicable customer-standardization rules used by the Silver transformation.

| Attribute | Transformation |
|---|---|
| `customer_id` | Trim surrounding whitespace |
| `first_name` | Lowercase and trim |
| `last_name` | Lowercase and trim |
| `nationality` | Lowercase and trim |
| `occupation` | Lowercase and trim |
| `phone_number` | Trim surrounding whitespace |
| `email` | Trim surrounding whitespace |

The customer is mapped through the OCB identity bridge using:

```text
source_entity = 'SIKACREDIT'
source_customer_id = customer_id
```

The resulting Silver record retains the SikaCredit customer identifier and carries the corresponding `ocb_customer_id`.

---

# 11. SIKACREDIT LOAN TRANSFORMATION

Loan records are standardized from Bronze.

## 11.1 Location Parsing

The source disbursement location is separated into:

```text
disbursement_location_region
disbursement_location_town
```

The transformation uses the source's `region|town` representation.

## 11.2 Currency Standardization

The loan currency is standardized to lowercase.

## 11.3 Customer Identity

The loan's customer identifier is mapped through the OCB identity bridge.

The resulting Silver loan retains the institutional loan and customer identifiers, together with the implemented loan attributes, including:

```text
loan_id
customer_id
ocb_customer_id
principal_amount
disbursement_timestamp
disbursement_location_region
disbursement_location_town
maturity_date
interest_rate
loan_currency
```

The loan's source identifier remains the identifier used to preserve its relationship with the corresponding repayment records.

---

# 12. SIKACREDIT REPAYMENT TRANSFORMATION

Repayment records are standardized from Bronze.

## 12.1 Location Parsing

The source repayment location is separated into:

```text
repayment_location_region
repayment_location_town
```

## 12.2 Loan Relationship

Each repayment retains its relationship to the source loan through `loan_id`.

The repayment obtains its canonical customer identity from the corresponding Silver loan record.

```text
SIKACREDIT REPAYMENT
          |
          v
        loan_id
          |
          v
silver.sikacredit_loan
          |
          v
    ocb_customer_id
```

This follows the implemented parent-child relationship between loans and repayments.

The repayment does not require a separate customer identity-resolution process because its customer relationship is established through the loan.

The resulting record retains the source repayment identifier and the applicable repayment attributes.

---

# 13. OMAN REMIT CUSTOMER TRANSFORMATION

Oman Remit customer records are standardized using the applicable customer-field transformations.

The source customer identifier is mapped through the identity bridge using:

```text
source_entity = 'OMAN_REMIT'
source_customer_id = customer_id
```

The resulting Silver customer record retains its Oman Remit identity and carries the corresponding `ocb_customer_id`.

This makes the canonical customer identity available within the remittance domain without replacing the source customer identifier.

---

# 14. OMAN REMIT REMITTANCE TRANSFORMATION

Oman Remit remittance records are standardized and enriched using the applicable reference data.

## 14.1 Reference Mapping

The source country identifier is mapped through the country reference table.

The transaction-channel identifier is mapped through the transaction-channel reference table.

The resulting descriptive attributes include:

```text
remittance_origin_country
remittance_transaction_channel
```

The currency is standardized to lowercase.

## 14.2 Location Parsing

The source location is separated into:

```text
remittance_location_region
remittance_location_town
```

using the source's `region|town` representation.

## 14.3 Customer Identity

The remittance's customer relationship is mapped to the corresponding `ocb_customer_id` through the OCB identity bridge.

The source remittance identifier and implemented remittance attributes remain available in Silver.

---

# 15. REMITTANCE TYPE DERIVATION

The Silver transformation derives `remittance_type` from the standardized remittance origin country.

The implemented rule is:

| Condition | Derived type |
|---|---|
| `remittance_origin_country = 'ghana'` | `remittance_sent` |
| `remittance_origin_country <> 'ghana'` | `remittance_received` |

The classification is therefore:

```text
Ghana origin
     |
     v
remittance_sent


Non-Ghana origin
     |
     v
remittance_received
```

The derived attribute is stored in Silver so downstream analytical queries can use the classification directly.

The verification process checks the consistency of the derived type against the origin-country rule.

This is a project-specific simulation rule. It should not be interpreted as a complete representation of all possible real-world remittance classification requirements.

---

# 16. REFERENCE-DATA ENRICHMENT

Bronze contains reference identifiers that are translated into descriptive values where required by the Silver model.

The implemented mappings include:

| Source reference | Reference data | Resulting attribute |
|---|---|---|
| `transaction_type_id` | Transaction-type reference | `transaction_type` |
| `transaction_channel_id` | Transaction-channel reference | `transaction_channel` |
| `transaction_status_id` | Transaction-status reference | `transaction_status` |
| `currency_id` | Currency reference | Transaction currency |
| `country_id` | Country reference | `remittance_origin_country` |

The specific target attribute depends on the entity being transformed.

Reference enrichment improves analytical usability while preserving the source relationships and identifiers required for traceability.

It does not change the underlying financial meaning of a source record.

---

# 17. SILVER ENTITY RELATIONSHIPS

The resulting Silver identity structure is:

```text
                  OCB CUSTOMER
                       |
                       | ocb_customer_id
                       |
           OCB CUSTOMER IDENTITY
                       |
          +------------+------------+
          |            |            |
       ANANSE       SIKACREDIT    OMAN REMIT
          |            |            |
       Customer      Customer      Customer
          |            |            |
        Wallet        Loan       Remittance
          |            |
      Transaction   Repayment
```

The diagram represents the identity and entity relationships relevant to the Silver transformation.

The institutional entities remain independent within their respective source domains.

The shared `ocb_customer_id` provides the analytical integration key across those domains.

The loan-to-repayment relationship remains based on `loan_id`, with the repayment's customer identity inherited through its parent loan.

---

# 18. DATA PRESERVATION AND TRACEABILITY

The Silver transformation standardizes and enriches source data rather than replacing its underlying records.

The preservation principles are:

1. Retain institutional source identifiers.
2. Retain source financial records and their implemented financial attributes.
3. Preserve established source relationships.
4. Add canonical customer identity through the validated mapping.
5. Translate reference identifiers into descriptive values where required.
6. Derive implemented analytical attributes using their defined business rules.
7. Maintain traceability between Silver entities and their Bronze sources.

The canonical OCB identity does not replace an institutional customer identifier.

Similarly, standardized descriptions and derived attributes do not replace the source event's underlying financial values.

These principles allow downstream analytical models to use a consistent customer identity while preserving the institutional context of each record.

---

# 19. SILVER LOAD CONTROL

The Silver transformation uses a full-refresh strategy.

The implemented entity-load sequence is:

```text
OCB CUSTOMER
      |
      v
OCB CUSTOMER IDENTITY
      |
      v
ANANSE CUSTOMER
      |
      v
ANANSE WALLET
      |
      v
ANANSE TRANSACTION
      |
      v
SIKACREDIT CUSTOMER
      |
      v
SIKACREDIT LOAN
      |
      v
SIKACREDIT REPAYMENT
      |
      v
OMAN REMIT CUSTOMER
      |
      v
OMAN REMIT REMITTANCE
```

The sequence reflects the dependencies required by the implemented transformation.

The complete Silver load executes within a single transaction. A failure during the process causes the transaction to roll back rather than leave a partially refreshed Silver layer.

Successful entity loads are registered in:

`silver.load_batch`

The load registration records completed entity loads as part of the implemented control process.

---

# 20. SILVER VERIFICATION

The Silver verification procedure checks the transformed data against the expected source populations and transformation rules.

## 20.1 Population Reconciliation

Bronze and Silver row counts are compared for the relevant transformed entities.

The purpose is to identify unintended record loss or unexpected changes in entity populations.

## 20.2 Identity Verification

Identity checks assess the completeness and consistency of the source-to-OCB mapping.

The canonical customer population and identity bridge must remain compatible with the frozen identity assignments.

This includes verifying that mapped OCB identities correspond to valid canonical customer records.

## 20.3 Relationship Verification

The verification process checks applicable relationships among:

- Customers.
- Wallets.
- Transactions.
- Loans.
- Repayments.
- Remittances.

The loan-to-repayment relationship is verified through `loan_id`.

Customer identity propagation is verified against the corresponding source-to-OCB mapping or, for repayments, the associated loan.

## 20.4 Transformation Verification

The procedure checks applicable derived and standardized attributes, including:

- Transaction locations.
- Loan disbursement locations.
- Repayment locations.
- Remittance locations.
- Remittance type.

## 20.5 Load Registration

The expected Silver entities are checked against `silver.load_batch` to verify the required load registration.

The verification process complements the atomic load. It checks the resulting data and recorded load state rather than replacing transaction control.

---

# 21. ARCHITECTURAL BOUNDARIES

The identity mechanism is a controlled simulation abstraction designed for OCB's cross-institution analytical requirements.

The v1.0.0 implementation does not claim to provide:

- National identity infrastructure.
- Production KYC infrastructure.
- Institutional identity APIs.
- Biometric identity systems.
- Distributed regulatory identity services.

The synthetic identity ground truth makes it possible to validate known cross-domain relationships within the simulation.

The implementation demonstrates how a common analytical customer identity can be propagated across independent institutional datasets. It does not establish the identity-resolution controls, legal authority, governance, or operational infrastructure required for a production regulatory identity service.

---

# 22. FINAL IMPLEMENTATION RECONCILIATION

The Silver transformation methodology is governed by the following implementation decisions.

| Area | Reconciled implementation |
|---|---|
| Canonical customer | `silver.ocb_customer` |
| Frozen identity-resolution output | `silver.ocb_customer_identity_resolved` |
| Source-to-OCB identity bridge | `silver.ocb_customer_identity` |
| Cross-domain ground-truth identifier | `cross_domain_id` |
| Canonical analytical identity | `ocb_customer_id` |
| Identity assignment authority | Validated and frozen identity-resolution mapping |
| Representative customer selection | Selects a canonical profile within a resolved customer group |
| Source identifiers | Retained |
| Source financial records | Retained |
| Ananse wallet identity | Mapped through the source-to-OCB identity bridge |
| Ananse transaction identity | Mapped through the source-to-OCB identity bridge |
| SikaCredit loan identity | Mapped through the source-to-OCB identity bridge |
| SikaCredit repayment identity | Inherited through the corresponding Silver loan |
| Oman Remit customer identity | Mapped through the source-to-OCB identity bridge |
| Remittance classification | Derived from standardized origin country |
| Location parsing | Compound location separated into region and town |
| Reference enrichment | Reference identifiers translated into descriptive values where required |
| Silver loading | Full refresh |
| Transaction control | One atomic Silver transaction |
| Load registration | `silver.load_batch` |
| Verification | Separate Silver verification procedure |

## 22.1 Identity Consistency Requirement

Canonical customer construction and identity propagation must describe the same resolved customer population.

Representative-record selection determines which source record supplies the canonical profile. The frozen identity mapping determines which institutional records belong to each resolved OCB customer.

Neither process substitutes for the other.

The two processes must be reconciled so that every resolved OCB identity has an appropriate canonical customer record and the source-to-OCB mappings remain consistent with that population.

This is the principal architectural distinction governing this document.

## 22.2 Final State

This document establishes the transformation of validated Bronze records into standardized Silver entities, with separate responsibilities for canonical customer construction, frozen identity mapping, source-specific transformation, and analytical identity propagation.

The methodology preserves institutional identifiers and financial records while making a common OCB customer identity available across Ananse Telecom, SikaCredit, and Oman Remit.

The implementation remains within the established OCB v1.0.0 architecture and does not introduce additional identity-resolution services or transformation capabilities.