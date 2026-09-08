# SQL load order
1. ref tables
2. institutional customer tables
3. wallet.wallet
4. ananse.transaction quarterly files
5. sikacredit.loan
6. sikacredit.repayment
7. oman_remit.remittance
8. OCB identity/control outputs are analytical/control artifacts and are not source operational tables unless explicitly loaded by a later OCB processing step.
