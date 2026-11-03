# OCB Platform v1.0.0 — Synthetic Simulation Platform

Rebuilt against physical WP-2.4 deployment, WP-2.2 and WP-2.3. Population is 3,000 / 800 / 500 over 2023-2025. Seed OCB2020. Hard ceiling 1,000,000.

P2P Transfer remains one authoritative event. Successful events receive exactly two control legs: P2P_SEND/debit and P2P_RECEIVE/credit. The physical transaction schema is unchanged.

The generator explicitly applies weekday/weekend, payday, approximately 14-day cycle, Ghana holiday, December/13th-month, lifecycle and true quarterly burst effects. Scenario evidence is generated rather than merely labelled.

Run `python ocb_simulation_generator_v1_0_2.py` to regenerate the dataset.
