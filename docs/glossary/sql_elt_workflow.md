# OCB PLATFORM v1.0.0

## SQL ELT WORKFLOWS

### Official Work Package Definition

**Programme:** OCB Platform v1.0.0  
**Work Package:** SQL ELT Workflows  
**Component:** SQL-Based Data Processing  
**Purpose:** Establish repeatable SQL-based ELT capabilities supporting controlled execution, refresh, transformation, lineage, error handling, validation, and reprocessing where required.

**Implementation Status:** Satisfied — the required ELT capabilities are addressed by the existing Bronze → Silver → Gold processing architecture.

### 1. Implementation Assessment

The existing OCB data-processing architecture provides the SQL-based ELT capabilities required for the current platform. A separate ELT framework or additional orchestration layer is not necessary.

The assessment is based on the existing implementation and its established design.

#### 1.1 Controlled Execution

SQL procedures and transaction-control mechanisms support controlled execution of data-processing operations.

The existing implementation uses mechanisms including `SET NOCOUNT ON`, `SET XACT_ABORT ON`, `TRY/CATCH`, explicit transaction control, and `THROW` where appropriate.

These mechanisms provide the foundation for executing processing operations and handling errors within their defined transaction boundaries.

#### 1.2 Transformation

Data transformation follows the established Bronze → Silver → Gold architecture:

- **Bronze:** Retains ingested source data and associated load-batch context.
- **Silver:** Applies the established transformation, standardisation, and identity-resolution rules.
- **Gold:** Exposes analytical structures for downstream financial intelligence workloads.

Each layer retains its defined responsibility. The ELT workflow does not require a separate transformation architecture or unnecessary duplication of existing logic.

#### 1.3 Lineage and Traceability

Source identifiers, `bronze.load_batch`, relationships between processing layers, and OCB identity-mapping structures support data lineage and traceability.

These structures provide a basis for relating processed records to their source data and associated load context.

#### 1.4 Error Handling

The existing SQL implementation incorporates transaction control and error-handling mechanisms, including rollback behaviour and `THROW` where appropriate.

These mechanisms support the management of processing errors within the relevant operations and transaction boundaries.

#### 1.5 Validation

Validation is incorporated into the existing ingestion, transformation, identity-resolution, and analytical processes.

The architecture does not require a separate validation framework where the existing controls already address the relevant requirements.

#### 1.6 Refresh and Reprocessing

The existing SQL workflows support processing against the established source dataset.

Refresh and reprocessing remain governed by the logic and transaction boundaries of the relevant procedures. They do not require an additional orchestration platform or a separate processing framework.

### 2. Architectural Boundaries

The following are not required for the current platform:

- A separate ELT framework.
- An additional orchestration layer.
- A replacement for the Bronze → Silver → Gold architecture.
- Duplicate transformation or validation logic.
- Additional infrastructure without a demonstrated architectural need.

The existing implementation remains the basis for the platform's SQL-based data-processing workflows.

### 3. Closure Decision

**Status: Satisfied.**

The required SQL ELT capabilities are addressed through the existing processing architecture, including controlled execution, layered transformation, lineage, error handling, validation, and reprocessing support.

No additional implementation is required for this work package under the current OCB Platform v1.0.0 scope.