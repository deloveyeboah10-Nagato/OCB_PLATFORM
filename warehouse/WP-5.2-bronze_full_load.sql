USE [ocb_platform];
GO

/*========================================================================================================================
    OCB PLATFORM v1.0.0
    BRONZE FULL LOAD PROCEDURE

    Purpose:
        Fully refresh Bronze source and reference tables from frozen external CSV files.

    Load Strategy:

        1. Clear existing data in foreign-key dependency order.
        2. Load parent/reference tables.
        3. Load customer tables.
        4. Load intermediate parent tables.
        5. Load dependent transaction/event tables.
        6. Record load provenance.

    Foreign Key Clearing Strategy:
        DELETE is used for tables participating in foreign key relationships.
        SQL Server does not permit TRUNCATE TABLE on a table referenced by an active foreign key constraint.
        load_batch is truncated because it is not referenced by any foreign key constraint.
========================================================================================================================*/
CREATE OR ALTER PROCEDURE dbo.ocb_bronze_full_load
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @start_time DATETIME2(3),
        @end_time DATETIME2(3),
        @overall_start_time DATETIME2(3),
        @overall_end_time DATETIME2(3);

    SET @overall_start_time = SYSDATETIME();

    BEGIN TRY
        BEGIN TRANSACTION;

        PRINT '';
        PRINT '===============================================================================================';
        PRINT 'LOADING BRONZE LAYER';
        PRINT '===============================================================================================';

        /*============================================================================================================
            1. CLEAR EXISTING BRONZE DATA
            Tables must be cleared in child-to-parent dependency order.
        ============================================================================================================*/
        SET @start_time = SYSDATETIME();

        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT '>> CLEARING EXISTING BRONZE DATA';
        PRINT '-----------------------------------------------------------------------------------------------';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE

            ananse_transaction
                    ↓
            ananse_wallet
                    ↓
            ananse_customer
        ------------------------------------------------------------------------------------------------------------*/
        DELETE
        FROM bronze.[ananse_transaction];

        DELETE
        FROM bronze.[ananse_wallet];

        DELETE
        FROM bronze.[ananse_customer];

        /*------------------------------------------------------------------------------------------------------------
            SIKACREDIT

            sikacredit_repayment
                    ↓
            sikacredit_loan
                    ↓
            sikacredit_customer
        ------------------------------------------------------------------------------------------------------------*/
        DELETE
        FROM bronze.[sikacredit_repayment];

        DELETE
        FROM bronze.[sikacredit_loan];

        DELETE
        FROM bronze.[sikacredit_customer];

        /*------------------------------------------------------------------------------------------------------------
            OMAN REMIT

            oman_remit_remittance
                    ↓
            oman_remit_customer
        ------------------------------------------------------------------------------------------------------------*/
        DELETE
        FROM bronze.[oman_remit_remittance];

        DELETE
        FROM bronze.[oman_remit_customer];

        /*------------------------------------------------------------------------------------------------------------
            REFERENCE TABLES

            Dependent transaction records have already been deleted.
        ------------------------------------------------------------------------------------------------------------*/
        DELETE
        FROM bronze.[ref_transaction_type];

        DELETE
        FROM bronze.[ref_transaction_status];

        DELETE
        FROM bronze.[ref_transaction_channel];

        DELETE
        FROM bronze.[ref_currency];

        DELETE
        FROM bronze.[ref_country];

        /*------------------------------------------------------------------------------------------------------------
            LOAD PROVENANCE
        ------------------------------------------------------------------------------------------------------------*/
        TRUNCATE TABLE bronze.[load_batch];

        SET @end_time = SYSDATETIME();

        PRINT '>> EXISTING BRONZE DATA CLEARED';
        PRINT 'DURATION: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR(20)) + ' ms';
        /*============================================================================================================
            2. LOAD REFERENCE MAPPING TABLES
            Reference data is loaded before dependent source transactions.
        ============================================================================================================*/
        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT '>> PERFORMING FULL LOAD ON REFERENCE MAPPING TABLES';
        PRINT '-----------------------------------------------------------------------------------------------';

        SET @start_time = SYSDATETIME();

        /*------------------------------------------------------------------------------------------------------------
            REF TRANSACTION TYPE
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ref_transaction_type]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\reference\transaction_type.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'reference_transaction_type',
            'transaction_type.csv'
            );

        PRINT '>> bronze.[ref_transaction_type] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            REF TRANSACTION STATUS
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ref_transaction_status]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\reference\transaction_status.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'reference_transaction_status',
            'transaction_status.csv'
            );

        PRINT '>> bronze.[ref_transaction_status] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            REF TRANSACTION CHANNEL
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ref_transaction_channel]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\reference\transaction_channel.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'reference_transaction_channel',
            'transaction_channel.csv'
            );

        PRINT '>> bronze.[ref_transaction_channel] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            REF CURRENCY
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ref_currency]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\reference\currency.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'reference_currency',
            'currency.csv'
            );

        PRINT '>> bronze.[ref_currency] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            REF COUNTRY
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ref_country]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\reference\country.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'reference_country',
            'country.csv'
            );

        PRINT '>> bronze.[ref_country] Fully Loaded';

        SET @end_time = SYSDATETIME();

        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT 'REFERENCE MAPPING TABLES LOADED SUCCESSFULLY';
        PRINT 'DURATION: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR(20)) + ' ms';
        PRINT '-----------------------------------------------------------------------------------------------';
        /*============================================================================================================
            3. LOAD ANANSE SOURCE TABLES

            Dependency Order:

                ananse_customer
                        ↓
                ananse_wallet
                        ↓
                ananse_transaction
        ============================================================================================================*/
        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT '>> PERFORMING FULL LOAD ON ANANSE SOURCE TABLES';
        PRINT '-----------------------------------------------------------------------------------------------';

        SET @start_time = SYSDATETIME();

        /*------------------------------------------------------------------------------------------------------------
            ANANSE CUSTOMER
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_customer]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\customers.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_customer',
            'customers.csv'
            );

        PRINT '>> bronze.[ananse_customer] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE WALLET
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_wallet]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\wallets.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_wallet',
            'wallets.csv'
            );

        PRINT '>> bronze.[ananse_wallet] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2023 Q1
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2023_Q1.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2023_Q1.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2023 Q1 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2023 Q2
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2023_Q2.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2023_Q2.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2023 Q2 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2023 Q3
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2023_Q3.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2023_Q3.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2023 Q3 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2023 Q4
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2023_Q4.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2023_Q4.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2023 Q4 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2024 Q1
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2024_Q1.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2024_Q1.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2024 Q1 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2024 Q2
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2024_Q2.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2024_Q2.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2024 Q2 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2024 Q3
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2024_Q3.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2024_Q3.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2024 Q3 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2024 Q4
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2024_Q4.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2024_Q4.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2024 Q4 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2025 Q1
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2025_Q1.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2025_Q1.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2025 Q1 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2025 Q2
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2025_Q2.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2025_Q2.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2025 Q2 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2025 Q3
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2025_Q3.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2025_Q3.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2025 Q3 Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            ANANSE TRANSACTIONS — 2025 Q4
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[ananse_transaction]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\ananse\transactions_2025_Q4.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'transactions_2025_Q4.csv'
            );

        PRINT '>> bronze.[ananse_transaction] 2025 Q4 Fully Loaded';

        SET @end_time = SYSDATETIME();

        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT 'ANANSE SOURCE TABLES LOADED SUCCESSFULLY';
        PRINT 'DURATION: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR(20)) + ' ms';
        PRINT '-----------------------------------------------------------------------------------------------';
        /*============================================================================================================
            4. LOAD SIKACREDIT SOURCE TABLES

            Dependency Order:

                sikacredit_customer
                        ↓
                sikacredit_loan
                        ↓
                sikacredit_repayment
        ============================================================================================================*/
        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT '>> PERFORMING FULL LOAD ON SIKACREDIT SOURCE TABLES';
        PRINT '-----------------------------------------------------------------------------------------------';

        SET @start_time = SYSDATETIME();

        /*------------------------------------------------------------------------------------------------------------
            SIKACREDIT CUSTOMER
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[sikacredit_customer]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\sikacredit\customers.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'sikacredit_customer',
            'customers.csv'
            );

        PRINT '>> bronze.[sikacredit_customer] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            SIKACREDIT LOAN
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[sikacredit_loan]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\sikacredit\loans.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'sikacredit_loan',
            'loans.csv'
            );

        PRINT '>> bronze.[sikacredit_loan] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            SIKACREDIT REPAYMENT
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[sikacredit_repayment]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\sikacredit\repayments.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'sikacredit_repayment',
            'repayments.csv'
            );

        PRINT '>> bronze.[sikacredit_repayment] Fully Loaded';

        SET @end_time = SYSDATETIME();

        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT 'SIKACREDIT SOURCE TABLES LOADED SUCCESSFULLY';
        PRINT 'DURATION: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR(20)) + ' ms';
        PRINT '-----------------------------------------------------------------------------------------------';
        /*============================================================================================================
            5. LOAD OMAN REMIT SOURCE TABLES

            Dependency Order:

                oman_remit_customer
                        ↓
                oman_remit_remittance
        ============================================================================================================*/
        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT '>> PERFORMING FULL LOAD ON OMAN REMIT SOURCE TABLES';
        PRINT '-----------------------------------------------------------------------------------------------';

        SET @start_time = SYSDATETIME();

        /*------------------------------------------------------------------------------------------------------------
            OMAN REMIT CUSTOMER
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[oman_remit_customer]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\oman_remit\customers.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'oman_remit_customer',
            'customers.csv'
            );

        PRINT '>> bronze.[oman_remit_customer] Fully Loaded';

        /*------------------------------------------------------------------------------------------------------------
            OMAN REMIT REMITTANCE
        ------------------------------------------------------------------------------------------------------------*/
        BULK INSERT bronze.[oman_remit_remittance]
        FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\source\oman_remit\remittances.csv' WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK
                );

        INSERT INTO bronze.[load_batch] (
            source_entity,
            source_file_name
            )
        VALUES (
            'oman_remit_remittance',
            'remittances.csv'
            );

        PRINT '>> bronze.[oman_remit_remittance] Fully Loaded';

        SET @end_time = SYSDATETIME();

        PRINT '';
        PRINT '-----------------------------------------------------------------------------------------------';
        PRINT 'OMAN REMIT SOURCE TABLES LOADED SUCCESSFULLY';
        PRINT 'DURATION: ' + CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS VARCHAR(20)) + ' ms';
        PRINT '-----------------------------------------------------------------------------------------------';

        /*============================================================================================================
            6. COMPLETE TRANSACTION
        ============================================================================================================*/
        COMMIT TRANSACTION;

        SET @overall_end_time = SYSDATETIME();

        PRINT '';
        PRINT '===============================================================================================';
        PRINT 'BRONZE LAYER SUCCESSFULLY LOADED';
        PRINT 'DURATION: ' + CAST(DATEDIFF(MILLISECOND, @overall_start_time, @overall_end_time) AS VARCHAR(20)) + ' ms';
        PRINT '===============================================================================================';
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT '';
        PRINT '===============================================================================================';
        PRINT 'BRONZE LOAD FAILED';
        PRINT 'ALL CHANGES HAVE BEEN ROLLED BACK';
        PRINT '===============================================================================================';

        THROW;
    END CATCH;
END;
GO

/*========================================================================================================================
    EXECUTE BRONZE FULL LOAD
========================================================================================================================*/
EXEC dbo.ocb_bronze_full_load;
GO


