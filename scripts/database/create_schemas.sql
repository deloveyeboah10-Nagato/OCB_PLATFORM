USE [ocb_platform];
GO

/*========================================================================================================================
    OCB PLATFORM — ANALYTICAL LAYER SCHEMA DEPLOYMENT

    Purpose:
        Creates the three approved Medallion data-layer schemas required by the OCB Platform analytical architecture.

    Architecture:
        FROZEN GENERATED SOURCE FILES
                    ↓
                 BRONZE
                    ↓
                 SILVER
                    ↓
                  GOLD
                    ↓
              OLAP / INTELLIGENCE

    Approved schemas:
        bronze  — Source-preserved data loaded from the frozen dataset.
        silver  — Standardised, validated and integrated analytical data.
        gold    — Analytical facts, dimensions, derived structures and intelligence-ready data.

    Design principles:
        - The database is an analytical/regulatory sandbox.
        - No OLTP domain-schema architecture is created.
        - No separate source-domain schemas are created.
        - Source identity is represented by table names within the appropriate analytical layer.
        - The generator's frozen CSV output remains the source dataset.
        - This script creates schemas only.
        - No tables, data, transformations or business rules are created here.
        - Existing schemas are left unchanged.
        - The script is safe to re-run.
========================================================================================================================*/
PRINT '===============================================================';
PRINT '>>> STARTING OCB_PLATFORM ANALYTICAL SCHEMA DEPLOYMENT <<<';
PRINT '===============================================================';

/*========================================================================================================================
    1. BRONZE SCHEMA
========================================================================================================================*/
IF NOT EXISTS (
        SELECT
            1
        FROM sys.schemas
        WHERE name = N'bronze'
        )
BEGIN
    PRINT '>> bronze schema not found. Creating...';

    EXEC ('CREATE SCHEMA [bronze]');

    PRINT '>> bronze schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> bronze schema already exists. No action required.';
END;

/*========================================================================================================================
    2. SILVER SCHEMA
========================================================================================================================*/
IF NOT EXISTS (
        SELECT
            1
        FROM sys.schemas
        WHERE name = N'silver'
        )
BEGIN
    PRINT '>> silver schema not found. Creating...';

    EXEC ('CREATE SCHEMA [silver]');

    PRINT '>> silver schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> silver schema already exists. No action required.';
END;

/*========================================================================================================================
    3. GOLD SCHEMA
========================================================================================================================*/
IF NOT EXISTS (
        SELECT
            1
        FROM sys.schemas
        WHERE name = N'gold'
        )
BEGIN
    PRINT '>> gold schema not found. Creating...';

    EXEC ('CREATE SCHEMA [gold]');

    PRINT '>> gold schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> gold schema already exists. No action required.';
END;

PRINT '===============================================================';
PRINT '>>> ANALYTICAL SCHEMA DEPLOYMENT COMPLETE <<<';
PRINT '===============================================================';
GO


