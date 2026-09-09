# OCB Platform v1.0.0

## Silver Transformation & Identity Resolution Methodology

**Programme:** OCB Platform v1.0.0
**Component:** Data Engineering / Silver Layer
**Work Package:** WP-3.3 — Silver Transformations
**Status:** Final / Reconciled

---

# 1. Purpose

This document describes how the validated Bronze source data is transformed into the Silver trusted layer.

The methodology covers:

* OCB customer resolution;
* OCB customer identity mapping;
* source-specific customer standardisation;
* financial activity standardisation;
* reference-data mapping;
* location parsing;
* remittance classification;
* cross-domain customer key propagation;
* Silver load and verification.

The detailed SQL implementation is contained in:

`WP-5.3-silver_transformations_final_load.sql`

This document explains the transformation methodology rather than reproducing the SQL implementation.

---

# 2. Silver Transformation Model

The Silver layer receives the validated Bronze source data and produces standardized, trusted analytical representations.

The transformation follows:

```text
BRONZE
   ↓
Validation
   ↓
Standardisation
   ↓
Identity Mapping
   ↓
Business-Rule Transformation
   ↓
SILVER
```

The Silver process uses a full-refresh strategy and executes the complete transformation as a single transaction. A failure causes the Silver refresh to roll back.

Source records are retained in Silver. Cross-domain identity resolution adds the canonical `ocb_customer_id`; it does not replace or remove source-system records.

---

# 3. OCB Customer Resolution

## 3.1 Source Customer Population

The three institutional customer populations are combined:

```text
ANANSE
SIKACREDIT
OMAN_REMIT
```

The customer attributes used for OCB identity grouping are:

```text
first_name
last_name
date_of_birth
phone_number
email
```

The source values are standardized before grouping by:

* trimming identifiers and text;
* converting names to lowercase;
* trimming phone numbers;
* trimming email addresses.

---

## 3.2 Identity Grouping

Customer records from the three source systems are combined into one customer population.

Records with identical standardized identity attributes form a single OCB identity group.

The resulting groups represent the canonical OCB customer population.

The source customer records remain separate and retain their institutional identifiers.

---

## 3.3 Representative Customer Record

Within each resolved identity group, source records are ranked using:

```text
created_at DESC
source_entity ASC
source_customer_id ASC
```

The most recently created record receives:

```text
flag = 1
```

The `flag` is used only to select the representative record used to populate:

```text
silver.ocb_customer
```

Records not selected as the representative are not deleted. They remain represented through their source-specific records and the OCB identity mapping.

The final Silver transformation implements this selection through `ROW_NUMBER()`.

---

# 4. OCB Customer Identity Resolution

The OCB identity bridge is handled separately from the canonical customer record.

The resolved mapping contains:

```text
source_entity
source_customer_id
cross_domain_id
ocb_customer_id
```

The validated identity-resolution pipeline compares the source customer population with the generator's identity ground truth and the existing OCB identity assignments.

The resulting mapping was validated before being frozen.

The validation established:

```text
Source customer records:       4,300
Resolved cross-domain IDs:     3,635
Resolved OCB customer IDs:     3,635
```

The source records therefore represent multiple institutional records belonging to a smaller set of resolved cross-domain identities.

The validated mapping is persisted in:

```text
silver.ocb_customer_identity_resolved
```

and loaded into:

```text
silver.ocb_customer_identity
```

during the Silver transformation.

The generator's synthetic identity is retained as `cross_domain_id` within the resolved identity mapping.

It is not propagated as a separate attribute into the institutional Silver tables.

---

# 5. Cross-Domain OCB Customer Mapping

Once the identity bridge is populated, source-specific Silver entities obtain their canonical OCB identity by joining:

```text
source_entity
+
source_customer_id
        ↓
silver.ocb_customer_identity
        ↓
ocb_customer_id
```

This allows the same OCB customer to be represented across independent institutional systems without replacing the institutions' native customer identifiers.

The approach is consistent with the platform's architectural treatment of cross-system identity resolution as a controlled simulation abstraction rather than production-grade regulatory identity infrastructure.

---

# 6. Ananse Customer Transformation

Ananse customer data is standardized before loading into Silver.

Transformations include:

```text
customer_id       → trimmed
first_name        → lowercase + trimmed
last_name         → lowercase + trimmed
nationality       → lowercase + trimmed
occupation        → lowercase + trimmed
phone_number      → trimmed
email             → trimmed
```

The source customer is then joined to the OCB identity bridge using:

```text
source_entity = 'ANANSE'
customer_id = source_customer_id
```

The resulting `ocb_customer_id` is added to the Silver customer record.

---

# 7. Ananse Wallet Transformation

Ananse wallet records are loaded from Bronze with their source identifiers preserved.

The wallet's `customer_id` is used to obtain the corresponding:

```text
ocb_customer_id
```

from the OCB identity bridge.

The wallet therefore retains both its institutional customer relationship and its cross-domain OCB identity.

---

# 8. Ananse Transaction Transformation

Ananse transactions are standardized and enriched using reference data.

Reference mappings include:

```text
transaction_type_id
    ↓
ref_transaction_type

transaction_channel_id
    ↓
ref_transaction_channel

transaction_status_id
    ↓
ref_transaction_status

currency_id
    ↓
ref_currency
```

Reference names are standardized to lowercase.

The transaction location is split into:

```text
transaction_location_region
transaction_location_town
```

using the `|` delimiter contained in the source location.

The source customer is mapped to `ocb_customer_id` through the OCB identity bridge.

The source transaction amount and timestamp are retained as:

```text
transaction_amount
transaction_timestamp
```

The source device identifier is also retained.

---

# 9. SikaCredit Customer Transformation

SikaCredit customer data is standardized using the same customer-field treatment applied to Ananse:

```text
customer_id       → trimmed
first_name        → lowercase + trimmed
last_name         → lowercase + trimmed
nationality       → lowercase + trimmed
occupation        → lowercase + trimmed
phone_number      → trimmed
email             → trimmed
```

The source customer is then mapped to its OCB identity using:

```text
source_entity = 'SIKACREDIT'
```

and the source customer identifier.

---

# 10. SikaCredit Loan Transformation

Loan records are standardized from Bronze.

The source disbursement location is separated into:

```text
disbursement_location_region
disbursement_location_town
```

using the `|` delimiter.

The loan currency is standardized to lowercase.

The loan's customer identifier is mapped to `ocb_customer_id` through the OCB identity bridge.

The resulting Silver record retains:

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

---

# 11. SikaCredit Repayment Transformation

Repayment records are standardized from Bronze.

The repayment location is separated into:

```text
repayment_location_region
repayment_location_town
```

using the `|` delimiter.

The repayment is linked to its loan through:

```text
loan_id
```

The `ocb_customer_id` is inherited from the corresponding Silver loan record.

Therefore:

```text
repayment
    ↓
loan_id
    ↓
silver.sikacredit_loan
    ↓
ocb_customer_id
```

This preserves the existing source relationship while making the OCB identity directly available on the repayment record.

---

# 12. Oman Remit Customer Transformation

Oman Remit customer data is standardized in the same manner as the other source customer populations.

The source customer is mapped to its canonical OCB identity through:

```text
source_entity = 'OMAN_REMIT'
```

and the source customer identifier.

This provides direct cross-domain customer access within the Silver remittance domain.

---

# 13. Oman Remit Remittance Transformation

Oman Remit remittance records are standardized and enriched with reference data.

The source country identifier is mapped through the country reference table.

The transaction channel is mapped through the transaction-channel reference table.

The resulting values are standardized as:

```text
remittance_origin_country
remittance_transaction_channel
```

The remittance location is split into:

```text
remittance_location_region
remittance_location_town
```

using the `|` delimiter.

The currency is standardized to lowercase.

---

# 14. Remittance Type Derivation

`remittance_type` is derived from the standardized remittance origin country.

The rule is:

| Condition                              | Remittance Type       |
| -------------------------------------- | --------------------- |
| `remittance_origin_country = 'ghana'`  | `remittance_sent`     |
| `remittance_origin_country <> 'ghana'` | `remittance_received` |

Therefore:

```text
Ghana origin
    ↓
remittance_sent

Non-Ghana origin
    ↓
remittance_received
```

The derived type is stored in Silver rather than requiring downstream analytical users to repeatedly apply the classification rule.

The Silver verification procedure explicitly checks that every remittance satisfies this derivation rule.

---

# 15. Location Transformation

The source datasets encode certain locations as a combined value:

```text
region|town
```

Silver separates these into independent analytical attributes.

Applied transformations include:

```text
Ananse transaction
    → transaction_location_region
    → transaction_location_town

SikaCredit loan
    → disbursement_location_region
    → disbursement_location_town

SikaCredit repayment
    → repayment_location_region
    → repayment_location_town

Oman Remit remittance
    → remittance_location_region
    → remittance_location_town
```

The transformation verification checks that the resulting region and town fields are populated.

---

# 16. Reference Data Mapping

Reference identifiers in Bronze are translated into descriptive analytical values where required.

The principal mappings are:

```text
Transaction Type
transaction_type_id
        ↓
ref.transaction_type
        ↓
transaction_type

Transaction Channel
transaction_channel_id
        ↓
ref.transaction_channel
        ↓
transaction_channel

Transaction Status
transaction_status_id
        ↓
ref.transaction_status
        ↓
transaction_status

Currency
currency_id
        ↓
ref.currency
        ↓
transaction_currency

Country
country_id
        ↓
ref.country
        ↓
remittance_origin_country
```

This allows Silver analytical records to retain descriptive values while preserving the source relationships used in Bronze.

---

# 17. Identity Propagation Across Silver

The resulting customer identity relationship is:

```text
                    OCB CUSTOMER
                         │
                         │
              ocb_customer_id
                         │
                         ▼
             OCB CUSTOMER IDENTITY
                         │
          ┌──────────────┼──────────────┐
          │              │              │
        ANANSE       SIKACREDIT      OMAN REMIT
          │              │              │
       customer        customer        customer
       wallet          loan            remittance
       transaction     repayment
```

The `ocb_customer_id` therefore acts as the common analytical integration key.

Institution-specific identifiers remain intact.

---

# 18. Transformation Preservation Principle

The Silver transformation does not recreate or replace source financial events.

Instead, it:

* standardizes source attributes;
* resolves analytical identity;
* maps reference values;
* derives required analytical attributes;
* separates compound fields;
* adds canonical OCB identity keys;
* preserves source identifiers and financial values.

This follows the project requirement that Silver create trusted analytical data while remaining traceable to Bronze/source records.

---

# 19. Load Control

The Silver transformation uses a full-refresh process.

The dependency sequence is:

```text
OCB CUSTOMER
      ↓
OCB CUSTOMER IDENTITY
      ↓
ANANSE CUSTOMER
      ↓
ANANSE WALLET
      ↓
ANANSE TRANSACTION
      ↓
SIKACREDIT CUSTOMER
      ↓
SIKACREDIT LOAN
      ↓
SIKACREDIT REPAYMENT
      ↓
OMAN REMIT CUSTOMER
      ↓
OMAN REMIT REMITTANCE
```

The complete load executes inside one transaction.

Successful entity loads are registered in:

```text
silver.load_batch
```

after the corresponding target load completes.

---

# 20. Verification

The Silver verification process covers:

### Row-count reconciliation

Bronze and Silver populations are compared for each transformed entity.

### Identity verification

OCB identity mappings are checked for completeness and consistency.

### Referential integrity

Relationships between:

```text
customer
wallet
transaction
loan
repayment
remittance
```

are checked.

### Transformation sanity

Derived and parsed fields are checked, including:

* transaction locations;
* loan locations;
* repayment locations;
* remittance locations;
* remittance type.

### Load registration

Expected Silver entities are checked against `silver.load_batch`.

---

# 21. Reconciled Final State

The final Silver methodology therefore consists of two distinct OCB customer processes.

## OCB Customer

Determines the canonical customer record:

```text
Source customer records
        ↓
Standardize identity attributes
        ↓
Group matching identities
        ↓
Rank source records
        ↓
Select representative record
        ↓
silver.ocb_customer
```

## OCB Customer Identity

Uses the separately validated and frozen identity mapping:

```text
Validated identity-resolution output
        ↓
silver.ocb_customer_identity_resolved
        ↓
silver.ocb_customer_identity
        ↓
ocb_customer_id propagated to Silver entities
```

This separation allows the canonical OCB customer representation and the source-to-OCB identity bridge to perform their respective roles without duplicating the identity-resolution process.

---

# 22. Architectural Boundary

The identity mechanism represents a **controlled simulation abstraction**.

It demonstrates cross-institution entity resolution sufficient for the OCB analytical use case, but it does not represent:

* national identity infrastructure;
* production KYC infrastructure;
* institutional identity APIs;
* biometric identity systems;
* distributed regulatory identity services.

The project explicitly treats production-grade identity infrastructure as outside the v1.0.0 implementation boundary.

---

# 23. Final Reconciliation Notes

The following implementation decisions are now treated as final:

| Area                             | Final implementation                                     |                                      |
| -------------------------------- | -------------------------------------------------------- | ------------------------------------ |
| Canonical OCB customer           | `silver.ocb_customer`                                    |                                      |
| Source-to-OCB identity bridge    | `silver.ocb_customer_identity`                           |                                      |
| Frozen resolved identity mapping | `silver.ocb_customer_identity_resolved`                  |                                      |
| Cross-domain identity            | `cross_domain_id` from validated identity resolution     |                                      |
| OCB identity key                 | `ocb_customer_id`                                        |                                      |
| Source identifiers               | Retained                                                 |                                      |
| Source financial records         | Retained                                                 |                                      |
| Identity resolution              | Performed once through the dedicated resolution pipeline |                                      |
| Source-specific OCB mapping      | Via `silver.ocb_customer_identity`                       |                                      |
| Remittance classification        | Derived from origin country                              |                                      |
| Location parsing                 | `region                                                  | town` split into separate attributes |
| Reference mapping                | Reference IDs translated to descriptive values           |                                      |
| Silver load                      | Full refresh                                             |                                      |
| Transaction control              | One atomic Silver transaction                            |                                      |
| Verification                     | Separate Silver verification procedure                   |                                      |

The methodology is therefore aligned with the final Silver transformation implementation and the project's broader Bronze → Silver → Gold architecture.

````
