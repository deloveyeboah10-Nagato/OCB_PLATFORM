# Osagyefo Central Bank Digital Financial Intelligence Platform (OCB)

**Version:** 1.0.0\
**Project type:** SQL-first financial intelligence and supervisory
analytics sandbox\
**Status:** Core analytical development completed; dashboard, deployment
and documentation delivery in progress

> Engineer financial truth. Transform events into intelligence.

## Overview

The Osagyefo Central Bank Digital Financial Intelligence Platform (OCB)
is a portfolio project exploring how a supervisory analytics function
could examine activity across different digital-finance institutions
using structured data and SQL-based intelligence.

OCB is an analytical and supervisory sandbox---not a bank, payment
processor, production ledger, reconciliation platform or live regulatory
system. It uses synthetic data and does not connect to real customer
accounts or financial institutions.

The core analytical work is complete. Remaining delivery work includes
building the dashboard and presentation layer, finalising the agreed
local/GitHub and public-dashboard deployment arrangements, and
reconciling project notes and documentation to reflect the
implementation.

## Why I built it

Digital financial activity is distributed across different business
models and event types. Looking at transactions, loans, repayments and
remittances in isolation can make it difficult to identify patterns that
span products or institutions.

OCB explores how a SQL-first workflow can:

-   structure synthetic data from multiple digital-finance domains;
-   validate and model data for consistent analysis;
-   examine transactions, lending, repayments and remittance activity;
-   develop event-level signals for monitoring and investigation; and
-   expose analytical outputs through SQL interfaces that can later
    support a dashboard.

The aim is to demonstrate financial-data reasoning and analytical system
design---not to claim that an anomaly is proof of fraud or misconduct.

## Simulated institutions

OCB keeps three synthetic institutions distinct within the supervisory
sandbox.

  -----------------------------------------------------------------------
  Institution             Simulated domain        Example activity
  ----------------------- ----------------------- -----------------------
  **Ananse Telecom**      Electronic money /      Cash-in, cash-out, P2P
                          mobile money            and merchant payments

  **SikaCredit**          Digital lending         Loan records,
                                                  disbursements and
                                                  repayments

  **Oman Remit**          Remittance              Inbound and outbound
                                                  remittance events
  -----------------------------------------------------------------------

These are fictional institutions created for the project. They do not
represent real providers or real customer activity.

## Architecture and workflow

The platform follows a SQL-first analytical workflow:

1.  **Bronze --- source data:** synthetic source-domain records.
2.  **Silver --- structured data:** cleaned and standardised tables used
    for analysis.
3.  **Gold --- analytical model:** reusable views presenting core
    entities and events.
4.  **Intelligence layer:** SQL views and analytical logic that derive
    monitoring signals from the model.
5.  **Presentation layer:** a dashboard planned to help users explore
    results and investigate patterns without duplicating the underlying
    analytical logic.

The dashboard is a presentation and exploration layer. Core financial
logic is developed in SQL and remains separate from dashboard-specific
presentation code.

## Analytical scope

The completed SQL analytical work covers event-level analysis across the
simulated domains. The project has included work on:

-   transaction activity and distribution;
-   lending and repayment behaviour;
-   remittance activity and outbound flows;
-   sequences and intervals between financial events;
-   cross-domain relationships between payment, credit and remittance
    activity; and
-   monitoring signals intended to support further review.

Specific signals are analytical indicators, not final determinations.
Their interpretation depends on the underlying data, business context
and additional investigation.

## Technical approach

The core analytical layer uses **Microsoft SQL Server and T-SQL**. The
work includes relational joins, common table expressions, window
functions, analytical views and event-grain queries.

The project uses synthetic data to support repeatable analysis without
exposing real personal or financial information.

Dashboard and deployment work is being kept separate from the completed
SQL analytical layer. Final hosting and presentation choices should be
documented here once implemented and validated.

## Data and interpretation caveats

-   All institution, customer and financial-event data are synthetic.
-   OCB is a portfolio and learning project, not a live supervisory
    system.
-   A monitoring signal indicates a pattern worth examining; it does not
    establish intent, fraud or regulatory non-compliance.
-   Results depend on the assumptions and behaviour embedded in the
    synthetic data.
-   The project should not be interpreted as evidence of production
    readiness or validation against real-world financial data.

## Current status

  -----------------------------------------------------------------------
  Workstream                          Status
  ----------------------------------- -----------------------------------
  SQL analytical development          **Completed**

  Core data model and analytical      Implemented for the project
  interfaces                          

  Dashboard and presentation layer    In progress

  Local development and GitHub        Being finalised separately from
  technical evidence                  dashboard deployment

  Public dashboard hosting/deployment Pending implementation and
                                      validation

  Project notes and documentation     In progress
  reconciliation                      
  -----------------------------------------------------------------------

This status distinguishes completion of the analytical core from
completion of the overall portfolio deliverable.

## Repository guide

Use this repository to inspect the SQL implementation and supporting
project materials. Add links to key scripts, work packages and the
dashboard after the final repository audit, ensuring every link points
to a current, verified file.

## What this project demonstrates

OCB is intended to demonstrate the ability to:

-   work with relational financial data using SQL;
-   model and analyse events across distinct financial domains;
-   develop reusable analytical views rather than relying only on
    one-off queries;
-   translate financial behaviour into defined monitoring signals;
-   distinguish an indicator from a conclusion; and
-   separate analytical logic from its eventual dashboard and deployment
    layer.

## Next steps

The remaining work is focused on delivery and presentation rather than
extending the completed analytical workload:

1.  Build and validate the dashboard.
2.  Finalise the separate local/GitHub workflow and public dashboard
    deployment.
3.  Reconcile older notes, specifications and project documents with the
    implementation actually delivered.
4.  Audit repository paths and add verified links to principal scripts,
    work packages and the dashboard when available.

------------------------------------------------------------------------

**Project:** Osagyefo Central Bank Digital Financial Intelligence
Platform (OCB)\
**Version:** 1.0.0\
**Data:** Synthetic\
**Primary analytical technology:** Microsoft SQL Server / T-SQL
