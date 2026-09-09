# OCB Platform v1.0.0

## Deprecated Implementation Artifacts

**Programme:** OCB Platform v1.0.0
**Component:** Historical / Deprecated Implementations
**Work Package:** Cross-Work-Package
**Status:** Deprecated / Retained for Historical Reference

### Purpose

This directory contains earlier OCB Platform implementation artifacts that have been superseded by later architectural and implementation decisions.

These artifacts are retained intentionally to document valid approaches used during earlier stages of development and to preserve the evolution of the platform.

### Contents

#### `database_reset.sql`

Earlier development utility for completely resetting the `ocb_platform` database by dropping and recreating it.

**Status:** Deprecated as a normal deployment mechanism.

**Reason:** The platform subsequently adopted controlled, non-destructive deployment and layer-specific reload strategies.

#### `ocb_platform_tables_deployment.sql`

Earlier non-destructive procedure for creating the initial OCB Platform physical schema.

**Status:** Deprecated.

**Reason:** The physical schema was subsequently redesigned and formalized as the platform architecture matured.

#### `ocb_customer_identity_population.sql`

Earlier implementation of OCB customer identity resolution.

**Status:** Deprecated.

**Reason:** The implementation used source customer attributes and source identifier patterns to establish cross-domain identity. Validation against the generator's identity ground truth demonstrated that this did not reliably represent the intended synthetic identities.

The current implementation uses the validated identity mapping produced through the OCB customer identity-resolution validation workflow.

### Retention Principle

These artifacts are preserved as **historical implementation records**, not as current authoritative implementations.

The current OCB Platform implementation and reconciled documentation take precedence. Deprecated artifacts should only be used when reviewing, reconstructing, or understanding an earlier stage of the platform.
