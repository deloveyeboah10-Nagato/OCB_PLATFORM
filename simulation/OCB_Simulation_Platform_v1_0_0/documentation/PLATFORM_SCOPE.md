# OCB Platform v1.0.0 — Simulation Package

## Authority
Physical WP-2.4 deployment > WP-2.2 > WP-2.3. Earlier simulation artifacts are baseline/reference only where they do not contradict the physical model.

## Locked simulation configuration
- Ananse customers: 3,000
- SikaCredit customers: 800
- Oman Remit customers: 500
- Period: 2023-01-01 to 2025-12-31
- 12 quarters
- Seed: OCB2020 / 2255779
- Hard ceiling: 1,000,000 source records

## P2P
P2P Transfer is one authoritative event. A successful transfer has two legs: P2P_SEND (debit) and P2P_RECEIVE (credit). The physical transaction table is unchanged; the paired legs are delivered in control/p2p_transfer_legs.csv.

## Behavioural corrections
The rebuilt generator implements temporal propensity effects (weekday/weekend, payday, approximately 14-day cycle, holidays, December/13th-month), lifecycle transitions, true 1–7 day quarterly bursts at 1.5x–4x, long-tail activity, scenario evidence, lending/repayment lifecycle and cross-institution synthetic-person overlap.
