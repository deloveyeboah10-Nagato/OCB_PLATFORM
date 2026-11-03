# SQL Load Order

Execute the platform load in the following order.

## 1. Bronze Layer

Deploy the Bronze tables, then load the authoritative source data in the following order:

1. Reference tables.
2. Institutional customer tables.
3. Ananse wallet table.
4. Ananse transaction data (quarterly files).
5. SikaCredit loan data (consolidated CSV).
6. SikaCredit repayment data (consolidated CSV).
7. Oman Remit remittance data (consolidated CSV).

### Alternative Quarterly Exports

SikaCredit and Oman Remit also have quarterly CSV exports alongside their consolidated CSV files. These quarterly exports contain exactly the same records as their respective consolidated files.

**Load the consolidated CSV files only. Do not load the alternative quarterly exports.** Loading both versions would duplicate the source data.

The synthetic identity ground-truth file is a control artifact. It is not loaded as a Bronze operational table. The identity-resolution process reads it directly during Silver initialisation.

## 2. Silver Layer

After the Bronze deployment and data load are complete, execute the Silver scripts in this order:

1. `silver_table_deployment.sql` — create the Silver tables, including `silver.ocb_customer_identity_resolved`.
2. `ocb_customer_identity_resolution.sql` — generate candidate OCB customer identities from the Bronze customer records, compare them with the synthetic identity ground truth, validate the mappings, and persist the resolved mappings.
3. `WP-5.3-silver_transformations_final_load.sql` — populate the Silver tables using the validated identity mappings.
4. Execute the Silver transformation verification procedure to verify the completed load.

**Dependency:** The Silver full-load transformation must not be executed before the identity-resolution script has completed successfully. The transformation consumes the resolved identity mappings produced by that script.
