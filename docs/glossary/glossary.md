# OCB PLATFORM v1.0.0

## BUSINESS GLOSSARY & DOMAIN DICTIONARY

### Official Work Package Definition

**Programme:** OCB Platform v1.0.0  
**Work Package:** Business Glossary & Domain Dictionary  
**Component:** Financial Domain, Analytical Data Engineering & Supervisory Intelligence  
**Purpose:** Establish a consistent vocabulary for OCB's institutional domains, financial entities, event attributes, identity model, analytical methods, intelligence signals, and supervisory interpretation.  
**Implementation Status:** Foundational terminology documented and expanded to cover the implemented analytical platform. Definitions distinguish established implementation facts from general business meanings and concepts that are not implemented in v1.0.0.

---

## 1. DOCUMENT PURPOSE

The Business Glossary & Domain Dictionary establishes the controlled vocabulary of the OCB Platform.

Its purpose is to ensure that:

- Business terms have consistent meanings.
- Financial events are defined consistently.
- Entities are not interpreted differently across institutional domains.
- Database objects reflect identifiable business concepts.
- Entity attributes have understandable meanings.
- Analytical metrics and statistical methods have explicit definitions.
- Regulatory intelligence uses consistent terminology.
- Documentation, database structures, testing, and intelligence logic remain aligned.
- Operational, analytical, and intelligence concepts remain distinct.
- Financial events can be distinguished from derived analytical interpretations.
- Technical terminology does not imply capabilities that have not been implemented.

The glossary answers:

**What do the business, financial, data, and intelligence concepts used by OCB mean?**

It is a reference layer between the project overview, engineering documentation, analytical implementation, intelligence logic, and supervisory presentation.

The glossary defines business and analytical meaning. It does not replace the Data Dictionary, which should document the physical structures, data types, nullability, relationships, and constraints of implemented database objects.

### 1.1 Definition standard

Where appropriate, each significant term should identify:

- **Term:** The official terminology.
- **Definition:** The precise meaning.
- **Context:** Where it is used.
- **System:** The originating institution or analytical component.
- **Related concepts:** Closely associated terms.
- **Financial significance:** Why it matters.
- **Implementation reference:** The corresponding database object or analytical output, where established.
- **Status:** Whether the term describes an implemented concept, a general business concept, or a governance/documentation concept.

Not every term requires every field. A statistical method, database identifier, and institution do not need identical definition structures.

The governing requirement is that the definition must be sufficiently precise to prevent materially different interpretations.

---

## 2. PLATFORM IDENTITY AND DOMAIN BOUNDARIES

### 2.1 Osagyefo Central Bank Digital Financial Intelligence Platform (OCB)

**Definition:** OCB is a SQL-first financial intelligence simulation that analyses synthetic financial activity across three independent institutional domains.

**Purpose:** To demonstrate the transformation of financial events into analytical evidence and supervisory intelligence.

**Motto:** Engineer financial truth. Transform events into intelligence.

**Context:** The platform includes data engineering, analytical modelling, customer-level behavioural analysis, cross-domain analysis, and a public supervisory dashboard.

**Implementation boundary:** OCB v1.0.0 is a simulation. It does not represent a live central-bank supervisory connection or a production financial institution.

### 2.2 Financial event

**Definition:** A recorded occurrence representing financial activity, such as a transaction, loan disbursement, repayment, or remittance.

**Context:** Financial events provide the underlying evidence for OCB's analytical and intelligence processing.

**Financial significance:** An analytical conclusion should remain traceable to the events from which it was derived.

An event record and an interpretation of that event are not the same thing. A recorded repayment is an event; a calculation showing how much of a preceding loan had been repaid before another loan was disbursed is a derived analytical result.

### 2.3 Observational model

**Definition:** A modelling approach that represents the information needed to answer an analytical or supervisory question without attempting to reproduce every internal mechanism of the originating institution.

**Context:** OCB models the financial activity needed for its intelligence questions rather than attempting to reproduce the complete operational systems of all three institutions.

**Financial significance:** The model should remain proportionate to the analytical question and the available evidence.

### 2.4 Institutional independence

**Definition:** The principle that Ananse Telecom, SikaCredit, and Oman Remit represent separate institutions with distinct financial activities and source-system identities.

**Context:** OCB observes and analyses their synthetic activity. The institutions are not modelled as a single institution with shared operational accounts or infrastructure.

**Financial significance:** Similar-looking events across institutions must not automatically be treated as the same business process.

### 2.5 Financial truth and derived interpretation

**Financial truth** refers to the recorded financial events and their valid financial consequences within the model.

**Derived interpretation** refers to a result calculated from those events, such as a recurrence interval, repayment-deficiency ratio, or behavioural signal.

**Context:** OCB's intelligence layer derives analytical meaning from the underlying financial evidence.

**Control principle:** A derived interpretation must not silently replace the underlying evidence or be presented as a directly observed fact.

---

## 3. INSTITUTIONAL DOMAIN GLOSSARY

### 3.1 Ananse Telecom

**Domain:** Mobile money and electronic money.

**Definition:** The simulated institution representing mobile-money activity, including customer transactions through the supported transaction types.

**Relevant concepts include:**

- Customers and customer identifiers.
- Transactions.
- Cash-in.
- Cash-out.
- Person-to-person transfers.
- Merchant payments.
- Other represented transaction types.
- Transaction timestamps, amounts, statuses, and available event attributes.

**Context:** Ananse Telecom provides transaction-level evidence for activity monitoring, transaction analysis, and behavioural investigation.

**Boundary:** Ananse Telecom is a simulated institutional domain. Its records must not be treated as live telecommunications or mobile-money data.

### 3.2 SikaCredit

**Domain:** Digital lending.

**Definition:** The simulated institution representing credit activity, including loan disbursements and repayments.

**Relevant concepts include:**

- Customers.
- Loans.
- Loan disbursements.
- Principal amounts.
- Maturity dates.
- Repayments.
- Repayment amounts and timestamps.
- Customer borrowing sequences.
- Credit-value escalation.
- Debt recycling.
- Repayment deficiency.
- Reborrowing rapidity and recurrence.

**Context:** SikaCredit provides the evidence used to investigate borrowing patterns, repayment behaviour, loan sequencing, and credit-obligation signals.

**Boundary:** The presence of a behavioural signal does not establish that a borrower has defaulted, acted improperly, or committed fraud.

### 3.3 Oman Remit

**Domain:** Remittance services.

**Definition:** The simulated institution representing remittance activity, including the direction of remittance events and the associated event attributes available in the model.

**Relevant concepts include:**

- Customers.
- Remittance records.
- Remittance direction.
- Send and receive events.
- Remittance amounts.
- Event timestamps.
- Event-location attributes, where represented.
- Cross-domain customer activity.

**Context:** Oman Remit provides evidence for remittance activity analysis and for examining temporal relationships between remittances and activity observed in other institutional domains.

**Boundary:** A temporal relationship between activity at Oman Remit and activity at another institution does not, by itself, prove that one event funded the other.

---

## 4. ENTITY AND IDENTITY TERMINOLOGY

Identifiers are not interchangeable simply because they identify records associated with the same simulated customer.

### 4.1 Entity

**Definition:** A distinguishable business object represented in the data model.

Examples include a customer, transaction, loan, repayment, remittance, or institution.

**Context:** Entities provide the objects to which attributes, relationships, and analytical results refer.

### 4.2 Customer

**Definition:** The customer entity represented within an institutional source domain and, where identity resolution permits, within OCB's cross-domain analytical model.

**Context:** A customer may have source-system identifiers in more than one institution.

**Important distinction:** A source-system customer record and an OCB-resolved analytical customer are different representations, even when they refer to the same simulated individual.

### 4.3 `source_customer_id`

**Definition:** The customer identifier assigned within the originating institutional source.

**Context:** It identifies a customer according to the source system's own identifier space.

**Important distinction:** The same value in two different institutions must not automatically be assumed to identify the same customer. Source identifiers are interpreted within their source-system context.

### 4.4 `source_entity`

**Definition:** The source institution or source domain associated with a source record.

**Context:** It distinguishes the institutional context in which a source identifier is meaningful.

**Relationship:** The source identity bridge uses the combination of `source_entity` and `source_customer_id` to distinguish source identities.

### 4.5 `ocb_customer_id`

**Definition:** OCB's canonical customer identifier for analytical use.

**Context:** It provides the customer key used to associate relevant activity across the platform's analytical model.

**Financial significance:** It allows customer-level analyses to relate events from separate source domains when the implemented identity mapping establishes that relationship.

**Boundary:** It is an OCB analytical identifier, not a source institution's native customer ID and not a real-world identity credential.

### 4.6 `cross_domain_id`

**Definition:** A synthetic identifier used as shared simulation ground truth to associate records that are intended to represent the same synthetic customer across institutional datasets.

**Context:** It supports the controlled identity-resolution assumptions used in the simulation.

**Important distinction:** `cross_domain_id` is a simulation convenience. It is not evidence that real financial institutions possess a shared customer identifier or can identify the same person across systems without a separate identity-resolution process.

It must not be confused with `ocb_customer_id`, which is the canonical customer identifier used in OCB's analytical model.

### 4.7 Source identity bridge

**Definition:** The mapping that relates an institutional source identity to the corresponding OCB analytical customer identity.

**Key:** `(source_entity, source_customer_id)`.

**Purpose:** To preserve the originating identity context while enabling the analytical model to associate records with `ocb_customer_id`.

**Financial significance:** Identity mapping is a prerequisite for interpreting customer activity across independent institutional domains.

### 4.8 Record identifier versus customer identifier

A record identifier identifies an individual record, such as a transaction, loan, repayment, or remittance.

A customer identifier identifies the customer associated with relevant records.

These identifiers answer different questions:

- **Record identifier:** Which event or business record is this?
- **Customer identifier:** Which customer does this record relate to?
- **Source identity:** Which customer identifier did the originating institution assign?
- **OCB analytical identity:** Which canonical customer is used for analysis within OCB?

A record identifier must not be substituted for a customer identifier, and a source identifier must not be treated as globally unique unless the implementation explicitly establishes that property.

---

## 5. ENTITY ATTRIBUTES AND EVENT FIELDS

An entity is not fully understood merely because its name is defined. Its attributes also need clear meanings.

The definitions below establish the business meaning of the field names discussed in the OCB model. They do not independently establish a field's physical SQL data type, nullability, validation rule, or exact population logic. Those details belong in the Data Dictionary and implementation.

### 5.1 Event

**Definition:** An occurrence represented in a source record, with attributes describing what happened and, where available, when, where, how much, and in what status.

**Context:** Transactions, loan disbursements, repayments, and remittances are different event types with different business meanings.

### 5.2 Event timestamp

**Definition:** The recorded time associated with an event.

**Context:** Used to order events, define observation periods, calculate elapsed intervals, and establish temporal relationships.

**Important distinction:** An event timestamp is not automatically the time when an event was received by an analytical process. Event time and processing time are different concepts when both are represented.

### 5.3 Event amount

**Definition:** The monetary amount recorded for the event according to the relevant source representation.

**Context:** Used in transaction analysis, credit analysis, remittance analysis, and monetary comparisons.

**Important distinction:** An amount is not automatically equivalent to a balance, outstanding obligation, net flow, or total over a period. Those quantities require their own definitions and calculation rules.

### 5.4 Event status

**Definition:** A field representing the recorded state of an event according to the relevant source model.

**Context:** Status may determine whether an event qualifies for a particular calculation.

**Important distinction:** A record's existence does not by itself mean that the underlying transaction or financial activity was successful. The exact status values and their treatment must follow the implemented source and analytical logic.

### 5.5 Event region

**Definition:** A geographic attribute representing the region associated with the event in the source data.

**Context:** Can be used to describe or group activity geographically when the field is populated and relevant to the analysis.

**Boundary:** The field's presence does not establish whether the region represents the customer's residence, the transaction location, an agent's location, or another geographic reference. That meaning depends on the source field's actual semantics.

### 5.6 Event town

**Definition:** A geographic attribute representing the town associated with the event in the source data.

**Context:** Provides a more local geographic description than a regional attribute where the source data supports it.

**Boundary:** It must not automatically be interpreted as the customer's residence or the physical location of a device.

### 5.7 Event origin country

**Definition:** A country attribute associated with the origin of an event in the relevant source representation.

**Context:** Particularly relevant to cross-border activity and remittance records when the source semantics support that interpretation.

**Boundary:** The exact meaning of *origin* must follow the source model. It must not automatically be equated with the customer's nationality, residence, transaction destination, or the country where an event was processed.

### 5.8 Geographic attributes are not interchangeable

`event_region`, `event_town`, and `event_origin_country` represent different levels or aspects of geographic context.

They should not be treated as synonyms or substituted for one another.

Their presence also does not independently establish a customer's residential address, nationality, physical location at the time of the event, or the legal jurisdiction governing the event.

### 5.9 Event direction

**Definition:** The direction in which a business event is represented from the perspective of the relevant institution or event model.

**Context:** Important for remittance activity because sending and receiving are distinct actions.

**Boundary:** Direction must be interpreted from the relevant event's perspective. It should not be inferred solely from an amount's sign or from the fact that the event is cross-border.

### 5.10 `remittance_send`

**Definition:** A remittance event or representation corresponding to the sending side of a remittance process.

**Context:** Used when the analysis concerns the sending activity represented in the Oman Remit model.

**Important distinction:** A send event must not automatically be treated as identical to the corresponding receive event. They may represent different stages or sides of a remittance process.

### 5.11 `remittance_receive`

**Definition:** A remittance event or representation corresponding to the receiving side of a remittance process.

**Context:** Used when the analysis concerns the receiving activity represented in the Oman Remit model.

**Important distinction:** A receive event must not automatically be treated as a second independent remittance of the same economic value, nor should it be assumed to be paired with a particular send event unless the data and implemented logic establish that relationship.

### 5.12 Remittance direction and event matching

The terms *send* and *receive* describe direction or side of the remittance activity; they do not by themselves prove a one-to-one match between records.

When investigating a relationship between remittances and activity at another institution, temporal proximity and customer association may support an analytical question. They do not independently establish a direct funding path.

### 5.13 Attribute, metric, and derived field

- **Attribute:** A property recorded for an entity or event, such as an event timestamp or event region.
- **Metric:** A measure calculated to describe a population or behaviour, such as a count, total value, or elapsed interval.
- **Derived field:** A field calculated from one or more source attributes or other derived values.

A derived field should not be described as a directly recorded source fact unless it is itself recorded by the source.

---

## 6. FINANCIAL EVENTS AND CREDIT CONCEPTS

### 6.1 Transaction

**Definition:** A recorded financial activity represented in the relevant transaction domain.

**Context:** In the Ananse Telecom domain, transactions include the supported mobile-money activity types.

**Important distinction:** Transaction types can represent different financial actions. They should not be treated as interchangeable merely because each is represented as a transaction record.

### 6.2 Cash-in

**Definition:** A transaction type representing funds entering a mobile-money wallet or account context as defined by the source model.

**Context:** Relevant to mobile-money activity and to analyses examining the temporal relationship between incoming funds and subsequent events.

**Boundary:** A cash-in followed by a remittance does not, by itself, prove that the cash-in funded that remittance.

### 6.3 Cash-out

**Definition:** A transaction type representing funds being withdrawn from the mobile-money context according to the source model.

**Context:** Used in transaction activity and behavioural analysis.

### 6.4 Person-to-person (P2P) transfer

**Definition:** A transfer of value between parties represented as a person-to-person transaction.

**Context:** Ananse Telecom transaction analysis.

### 6.5 Merchant payment

**Definition:** A transaction representing payment to a merchant in the source model.

**Context:** Used in transaction-type analysis and activity monitoring.

**Important distinction:** Merchant payments are not synonymous with P2P transfers or cash-outs. Analytical coverage depends on the transaction types explicitly included in a calculation.

### 6.6 Loan

**Definition:** A credit obligation represented by a loan record.

**Context:** The SikaCredit model uses loan records to represent credit disbursement and associated loan attributes, including the principal amount and maturity date where available.

### 6.7 Loan disbursement

**Definition:** The event or recorded activity through which loan principal is disbursed to a borrower.

**Context:** Provides the time anchor for analyses of borrowing sequences, inter-loan intervals, and repayment behaviour before subsequent borrowing.

**Important distinction:** A loan record, a disbursement event, a repayment, and an outstanding obligation are related but distinct concepts.

### 6.8 Principal amount

**Definition:** The principal value associated with a loan.

**Context:** Used in calculations that compare repayments with the original principal.

**Important distinction:** Principal is not automatically the same as the total amount payable, total repayment amount, or outstanding balance. Those values depend on the credit model and calculation being used.

### 6.9 Repayment

**Definition:** A recorded payment associated with a credit obligation.

**Context:** Repayment records provide the evidence used to calculate the amount repaid over a defined period or before a subsequent borrowing event.

### 6.10 Repayment amount

**Definition:** The monetary amount recorded for a repayment event.

**Context:** Used to calculate cumulative repayments over a specified interval.

**Important distinction:** A repayment amount is an event-level amount. A cumulative repayment amount is a derived total over a defined population and time window. A repayment amount in this project is a reduction against the principal amount and does not include any interests or fees.

### 6.11 Maturity date

**Definition:** The date on which a loan is scheduled to reach its contractual maturity according to the loan data.

**Context:** Used when examining loan timing and maturity-related behaviour.

**Important distinction:** A maturity date is a scheduled contractual reference. It is not itself proof that a loan was fully repaid, defaulted, or remained outstanding after maturity.

### 6.12 Outstanding obligation

**Definition:** A credit obligation that remains unpaid under the interpretation and calculation rules of the model.

**Context:** Relevant to analyses that compare new borrowing with repayment of preceding loans.

**Boundary:** The exact outstanding amount depends on the implemented financial and analytical model. It must not be inferred solely from a maturity date or the existence of another loan.

### 6.13 Debt recycling

**Definition:** A derived credit-behaviour construct identifying a qualifying sequence in which a customer obtains a subsequent loan while the preceding loan has not been fully repaid under the implemented repayment comparison.

**Context:** SikaCredit credit-behaviour analysis.

**Financial significance:** The construct helps investigate repeated reliance on new borrowing while a preceding obligation remains unresolved.

**Boundary:** Debt recycling, as defined here, is an analytical description of a borrowing and repayment pattern. It does not independently prove misconduct, fraud, inability to repay, or the purpose for which borrowed funds were used.

### 6.14 Repayment deficiency

**Definition:** The unrepaid portion of the preceding loan principal, expressed relative to the principal amount, under the specific calculation implemented by the credit-behaviour engine.

In the relevant calculation, the total repayments recorded before the next loan are compared with the preceding loan's principal amount. A positive deficiency ratio identifies a portion of that principal not covered by the repayments included in that comparison.

**Context:** The repayment-deficiency calculation is one of the analytical dimensions used in the debt-recycling construct.

**Important distinction:** Repayment deficiency is not automatically the same as a contractual arrears measure, a formal default classification, or a complete loan-balance calculation. Its interpretation is limited by the repayment records and calculation window used by the implementation.

### 6.15 Credit-value escalation

**Definition:** A pattern in which the value of subsequent borrowing increases relative to earlier borrowing under the comparison defined by the relevant intelligence logic.

**Context:** SikaCredit credit-behaviour analysis.

**Financial significance:** Increasing loan values may warrant further investigation when considered alongside borrowing frequency, repayment behaviour, and the wider customer history.

**Boundary:** Increasing borrowing value alone does not prove deteriorating creditworthiness or misconduct.

### 6.16 Repayment deficiency versus credit-value escalation

These terms describe different dimensions:

- **Repayment deficiency** concerns the portion of the preceding principal not covered by repayments included in the relevant comparison.
- **Credit-value escalation** concerns the relative value of subsequent borrowing.

One measures repayment coverage against a preceding obligation; the other examines changes in borrowing value.

Neither term is a risk classification.

---

## 7. TEMPORAL AND SEQUENCE ANALYSIS

Temporal analysis examines how events relate to one another in time. Sequence analysis examines events in an ordered series.

These concepts are particularly important when analysing repeated borrowing, repayments before subsequent loans, recurring remittances, or the timing between different event types.

### 7.1 Event sequence

**Definition:** An ordered set of events arranged according to their relevant timestamps and any additional ordering keys required by the implementation.

**Context:** Used to identify preceding and subsequent events for a customer.

**Important distinction:** An event's position in an analytical sequence is determined by the implemented ordering rules. Sequence order does not automatically establish a causal relationship.

### 7.2 Anchor event

**Definition:** The event selected as the reference point for a temporal or sequence-based calculation.

**Context:** In a reborrowing-rapidity calculation, the preceding loan's disbursement timestamp can act as the anchor for measuring the interval to the next loan.

**Important distinction:** A metric's anchor must be defined explicitly. Changing the anchor changes the question the metric answers.

### 7.3 Preceding event

**Definition:** The event that occurs immediately before another event within the ordered sequence used by the calculation.

**Context:** For debt-recycling analysis, the preceding loan provides the loan principal against which repayments before the next loan are evaluated.

### 7.4 Subsequent event

**Definition:** An event occurring after the anchor or preceding event within the relevant ordered sequence.

**Context:** In reborrowing analysis, the subsequent event is the next loan disbursement identified by the implemented sequence logic.

### 7.5 Elapsed interval

**Definition:** The amount of time between two specified timestamps.

**Context:** Used to quantify the time between successive loans or remittances, or between other relevant event pairs.

**Important distinction:** An interval must identify both endpoints. A value measured from loan disbursement to the next loan is not the same metric as a value measured from maturity to the next loan.

### 7.6 Recurrence

**Definition:** A measure of repeated occurrence within a defined event sequence or observation population.

The precise interpretation depends on how recurrence is implemented. It may describe the interval between successive qualifying events or the repetition of a qualifying pattern over time.

**Context:** OCB uses recurrence terminology in behavioural intelligence, including repeated borrowing behaviour and remittance-related analysis.

**Important distinction:** Recurrence is not automatically the number of times an event occurred. A recurrence *count*, a recurrence *interval*, and a recurrence *pattern* are different measures.

Where the implemented signal measures the interval between successive qualifying events, recurrence refers to that elapsed time between occurrences—not a risk score or a categorical risk level.

### 7.7 Recurrence interval

**Definition:** The elapsed time between consecutive qualifying occurrences in the event sequence being analysed.

**Example:** If a customer has qualifying remittance events at two different timestamps, the recurrence interval is the elapsed time between those two events.

**Context:** Used where the analytical question concerns how frequently a behaviour repeats over time.

**Interpretive boundary:** A short interval indicates that qualifying events occurred close together. It does not by itself explain why they occurred or prove that they were connected.

### 7.8 Rapidity

**Definition:** A measure of how quickly a subsequent event occurs relative to a specified anchor event.

**Context:** In the SikaCredit reborrowing-rapidity calculation, the interval is measured from the preceding loan's disbursement timestamp to the next loan's disbursement timestamp, in minutes.

**Interpretation:** A smaller elapsed interval means the subsequent borrowing occurred sooner after the anchor event.

**Important distinction:** Rapidity is a temporal measure. It does not mean the monetary value increased, that a repayment was deficient, or that the behaviour is inherently suspicious.

### 7.9 Reborrowing delay

**Definition:** The elapsed time between the preceding loan's disbursement timestamp and the next loan's disbursement timestamp in the relevant SikaCredit sequence.

**Context:** This is the interval used by the reborrowing-rapidity calculation.

**Unit:** The implemented calculation expresses the interval in minutes.

**Interpretation:** A shorter delay means the customer borrowed again sooner after the preceding loan's disbursement.

### 7.10 Rapidity versus recurrence

These terms must not be used interchangeably.

- **Rapidity** measures how quickly a subsequent event follows a defined anchor event.
- **Recurrence interval** measures the elapsed time between consecutive qualifying occurrences in the sequence being analysed.

They can both use elapsed time, but they may use different event populations and endpoints. Their meaning is determined by the implemented anchor and sequence logic—not merely by the fact that both return a time interval.

### 7.11 Event frequency

**Definition:** The number of events observed within a specified population and time window.

**Context:** Used to describe activity volume or the number of occurrences.

**Important distinction:** Frequency is a count; recurrence interval and rapidity are elapsed-time measures.

A customer with many events may have high event frequency without every interval between events being short.

### 7.12 Sequence duration

**Definition:** The elapsed time between the defined beginning and end of a sequence.

**Context:** Used when the analytical question concerns the length of a multi-event behavioural sequence.

**Important distinction:** Sequence duration measures the span from the chosen first event to the chosen last event. It is not automatically the same as an interval between adjacent events.

### 7.13 Temporal association

**Definition:** A relationship identified because events occur within a defined temporal window or order.

**Context:** Used to investigate potential relationships between events across institutional domains.

**Boundary:** Temporal association alone does not establish direct funding, causation, common intent, or a direct financial path between the events.

---

## 8. STATISTICAL TERMINOLOGY

Statistical terms used by the analytical engines must be defined separately from the business signals that use them.

A statistical method describes how a value is calculated or compared. It does not automatically determine the business interpretation of that value.

### 8.1 Population

**Definition:** The set of observations included in a particular calculation.

**Context:** A statistical baseline may be calculated over a defined set of qualifying customers, loans, events, or signal observations.

**Important distinction:** A statistic is meaningful only in relation to the population from which it was calculated.

### 8.2 Distribution

**Definition:** The pattern of values observed within a population.

**Context:** Used to understand the spread and typical values of a metric and to establish statistical reference points.

### 8.3 Median

**Definition:** The middle value of an ordered set of observations.

For an odd number of observations, the median is the middle observation. For an even number, it is conventionally the average of the two middle observations.

**Context:** Used as a measure of central tendency.

**Why it matters:** The median is less affected by extreme observations than the arithmetic mean.

### 8.4 Absolute deviation from the median

**Definition:** The non-negative distance between an observation and the median of the relevant population.

It is calculated by taking the absolute value of the difference between the observation and the median.

**Context:** This is the basis for calculating the median absolute deviation.

**Important distinction:** The absolute deviation of an individual observation is not itself the median absolute deviation of the population.

### 8.5 Median absolute deviation (MAD)

**Definition:** A robust measure of statistical dispersion calculated as the median of the absolute deviations of observations from their population median.

In words:

1. Calculate the median of the observations.
2. Calculate each observation's absolute distance from that median.
3. Calculate the median of those absolute distances.

The resulting value is the median absolute deviation.

**Context:** Used in statistical analysis to describe how widely observations are spread around the median.

**Why it matters:** MAD is less sensitive to extreme values than measures such as the standard deviation.

**Important distinction:** MAD measures dispersion. It is not a risk score, a risk classification, or a probability of misconduct.

### 8.6 `abs_mad`

**Definition:** In the context of the implemented calculation, `abs_mad` refers to an absolute deviation from the relevant median or a similarly named intermediate quantity, depending on the exact SQL expression in which the field appears.

**Implementation note:** The name alone is insufficient to establish whether a field stores an individual absolute deviation, the population MAD, or a further transformation. These are distinct quantities.

For the SikaCredit calculation, the SQL expression must be used to distinguish:

- The median of repayment-deficiency ratios.
- The absolute deviation of each repayment-deficiency ratio from that median.
- The median of those absolute deviations, which is the MAD.
- Any later comparison or transformation using those quantities.

**Important distinction:** `abs_mad` should not be used as a synonym for MAD without confirming the exact field expression. The precise physical field definition belongs in the Data Dictionary and should match the implemented SQL.

### 8.7 MAD-based comparison

**Definition:** A comparison that evaluates an observation's deviation relative to the median and MAD of a defined population.

**Context:** Can be used to identify observations that differ materially from the typical value in the relevant population.

**Boundary:** The interpretation depends on the implemented formula, population, and comparison threshold. The presence of a MAD-based calculation does not, by itself, establish a formal risk classification or prove misconduct.

### 8.8 Statistical baseline

**Definition:** A reference distribution or reference value derived from a defined observation population.

**Context:** Used to compare a current observation with the values observed in the selected baseline population.

**Important distinction:** A baseline is not automatically a regulatory limit, legal threshold, or validated risk boundary.

### 8.9 Outlier

**Definition:** An observation that is unusually distant from the reference distribution under a specified statistical or analytical rule.

**Context:** May be relevant when identifying activity that warrants closer examination.

**Boundary:** An outlier is not necessarily erroneous, fraudulent, or suspicious. It is unusual relative to a defined reference.

### 8.10 Statistical anomaly versus misconduct

A statistical anomaly describes an observation that differs from a reference pattern under a defined calculation.

Misconduct is a substantive conclusion requiring evidence and an appropriate determination.

The former does not establish the latter.

---

## 9. INTELLIGENCE SIGNALS AND ANALYTICAL CONSTRUCTS

This section defines the general terminology used by the intelligence layer. It does not replace the individual signal notes, which remain the authoritative explanations of each signal's business logic, qualifying conditions, and interpretation.

### 9.1 Intelligence signal

**Definition:** An analytical output produced by applying a defined rule or calculation to financial events or related records.

**Context:** OCB's intelligence layer uses signals to identify patterns that may warrant further investigation.

**Important distinction:** A signal is an analytical result, not automatically a finding of wrongdoing.

### 9.2 Behavioural signal

**Definition:** A signal derived from a pattern of activity, such as event frequency, timing, sequence, value changes, or relationships between events.

**Context:** Used to describe customer or event behaviour in the available synthetic data.

**Boundary:** Behavioural signals describe patterns within the model. They do not independently establish intent.

### 9.3 Debt-recycling signal

**Definition:** An analytical output associated with a qualifying borrowing sequence in which a subsequent loan occurs while the preceding loan remains incompletely repaid under the implemented comparison.

**Context:** SikaCredit credit-behaviour analysis.

The relevant dimensions may include:

- Repayment deficiency.
- Reborrowing rapidity.
- Recurrence of the qualifying behaviour.

These are separate dimensions. They should not be collapsed into a composite score unless such a composite is explicitly implemented.

### 9.4 Credit-obligation signal

**Definition:** An analytical signal concerning a credit obligation or a pattern of borrowing and repayment that may warrant further examination.

**Context:** SikaCredit intelligence.

**Boundary:** A signal concerning an obligation is not equivalent to a formal credit-risk grade, default status, or regulatory determination.

### 9.5 Credit-value escalation signal

**Definition:** A signal derived from the implemented comparison of borrowing values across a relevant sequence.

**Context:** Used to investigate whether subsequent borrowing values increase relative to earlier borrowing.

**Boundary:** Its meaning and qualifying conditions are governed by the corresponding signal implementation and signal notes.

### 9.6 Recurrence signal

**Definition:** A signal using the recurrence concept defined by its implementation—for example, the interval between successive qualifying occurrences where that is the implemented measure.

**Context:** Behavioural analysis of repeated qualifying activity.

**Boundary:** The signal's meaning depends on the event sequence, interval endpoints, and comparison logic. The term does not imply that recurrence is a composite risk score.

### 9.7 Rapidity signal

**Definition:** A signal derived from the elapsed time between a defined anchor event and a subsequent event.

**Context:** The SikaCredit reborrowing-rapidity calculation measures the delay between the preceding loan's disbursement and the next loan's disbursement.

**Boundary:** It describes timing. It does not independently establish the purpose of the borrowing or the borrower's ability to repay.

### 9.8 Signal threshold

**Definition:** A condition used by an implemented rule to determine whether an observation qualifies for an analytical output.

**Context:** Signal-specific logic may use numeric comparisons or other conditions.

**Important distinction:** An implemented analytical threshold is not automatically a formally approved regulatory threshold or a validated risk boundary.

### 9.9 Signal score

**Definition:** A numeric output explicitly calculated by a signal implementation when that implementation produces such a value.

**Context:** The term should be used only for an actual calculated output.

**OCB v1.0.0 boundary:** This glossary does not assert that OCB implemented a general risk score or risk classification. Individual calculated measures and signal outputs must be described according to their actual SQL definitions.

### 9.10 Risk score and risk classification

**Risk score:** A numeric value intended to represent a level or degree of risk according to a defined scoring methodology.

**Risk classification:** A categorical assignment, such as low, medium, or high risk, made under defined classification rules.

The existence of statistical calculations, behavioural signals, or anomaly-related outputs must not be represented as evidence that a risk-scoring model or formal risk-classification framework was implemented.

These terms are retained here to clarify the distinction and prevent unsupported claims.

---

## 10. CROSS-DOMAIN AND REMITTANCE ANALYSIS

### 10.1 Cross-domain analysis

**Definition:** Analysis that relates records or activity from more than one institutional domain.

**Context:** OCB can use its analytical customer identity model to examine activity associated with the same synthetic customer across Ananse Telecom, SikaCredit, and Oman Remit.

**Boundary:** Cross-domain analysis depends on the implemented identity mapping and available records. It does not imply that the institutions share an operational system or possess a common native identifier.

### 10.2 Cross-domain event relationship

**Definition:** An analytical relationship between events from different institutional domains.

**Context:** Used to investigate whether events occur in a sequence or temporal pattern that merits closer examination.

**Boundary:** A relationship established by customer association and timing does not prove a direct financial connection between the events.

### 10.3 Cash-in-to-remittance relationship

**Definition:** An analytical examination of the temporal relationship between a cash-in event and a remittance event.

**Context:** Used to investigate whether the events occur within a specified sequence or time interval.

**Boundary:** The relationship does not by itself prove that the cash-in funded the remittance.

### 10.4 Loan-to-remittance relationship

**Definition:** An analytical examination of the temporal relationship between loan activity and remittance activity.

**Context:** Used to investigate whether remittance events occur after credit events within the sequence and observation conditions defined by the relevant intelligence logic.

**Boundary:** Temporal order does not establish that loan proceeds directly funded a remittance.

### 10.5 Direct funding versus temporal proximity

**Direct funding** is a claim about the actual source and movement of funds.

**Temporal proximity** describes how close two events occur in time.

A subsequent event may occur shortly after an earlier event without being directly funded by it. Establishing direct funding requires evidence that supports that financial relationship, not timing alone.

---

## 11. DATA ENGINEERING AND ANALYTICAL LAYERS

### 11.1 Source data

**Definition:** Data originating from the represented institutional source domain.

**Context:** Source records provide the starting evidence for OCB's data engineering process.

### 11.2 Bronze layer

**Definition:** The initial data-engineering layer used to retain or represent ingested source data before downstream transformations.

**Context:** The Bronze layer is part of OCB's logical data flow.

**Boundary:** Its precise physical implementation and retention behaviour must be established by the relevant database objects and engineering documentation.

### 11.3 Silver layer

**Definition:** The transformation layer in which source data is prepared for consistent downstream use, including the implemented identity-resolution and transformation processes.

**Context:** Silver structures provide prepared records for the analytical model.

### 11.4 Gold layer

**Definition:** The analytical layer that exposes prepared financial entities and records through the established Gold model.

**Context:** OCB's Gold views include the implemented customer, institution, transaction, loan, repayment, and remittance representations.

**Boundary:** A Gold view is an analytical representation. Its existence does not imply that a separate operational system or a physically duplicated data store exists for every logical layer.

### 11.5 Analytical view

**Definition:** A database view that presents data in a form suited to a particular analytical purpose.

**Context:** Gold views expose prepared data, while intelligence views apply analytical logic to answer specific questions.

### 11.6 Intelligence view

**Definition:** A database view that implements a defined analytical or intelligence calculation over the relevant underlying records.

**Context:** Used to expose event-level or other derived analytical outputs to downstream analysis and supervisory presentation.

**Important distinction:** An intelligence view is not the same thing as the source event record from which its output is derived.

### 11.7 Event grain

**Definition:** The level of detail represented by an individual record in an event-oriented dataset or query result.

**Context:** An event-grain result preserves individual qualifying events rather than replacing them with a grouped aggregate.

**Financial significance:** Event grain is important when an investigation needs to examine individual timestamps, event sequences, and the relationship between particular records.

**Important distinction:** Event-level rows and aggregated totals answer different questions. An aggregate cannot automatically substitute for event-level evidence when the analysis depends on the sequence of individual events.

### 11.8 Aggregation

**Definition:** The process of combining records into a summary, such as a count, sum, or average, over a defined grouping.

**Context:** Used for reporting activity by customer, institution, period, or other dimensions.

**Important distinction:** Aggregation reduces the visible event-level detail. A grouped total does not by itself preserve the order or individual timing of the events that produced it.

### 11.9 Data lineage

**Definition:** The ability to trace a derived value or analytical result to the source records and transformations that produced it.

**Context:** Relevant to explaining and validating intelligence outputs.

---

## 12. METRICS, COUNTS, AND MONETARY MEASURES

### 12.1 Count

**Definition:** The number of records or qualifying events included in a calculation.

**Context:** Used for transaction counts, loan counts, repayment counts, and other activity measures.

**Important distinction:** A count depends on the population, event type, status treatment, and observation window specified by the calculation.

### 12.2 Total value

**Definition:** The sum of the monetary amounts included in a defined population.

**Context:** Used to describe aggregate transaction, loan, repayment, or remittance values where the relevant calculation supports that measure.

**Important distinction:** Total value is not the same as net flow or an outstanding balance.

### 12.3 Average value

**Definition:** The arithmetic mean of the included monetary values.

**Context:** Used to describe the average amount per qualifying record or event.

**Important distinction:** The average depends on the population included in the calculation. It should not be compared across populations without considering differences in inclusion rules.

### 12.4 Net flow

**Definition:** A derived measure of the net direction of monetary movement according to a specified definition of inflows and outflows.

**Context:** May be used to describe net movement within a defined domain or observation period.

**Important distinction:** Net flow is not simply total transaction value. Its interpretation depends on which amounts are treated as inflows, which are treated as outflows, and how the calculation handles the relevant event types.

### 12.5 Observation window

**Definition:** The time period within which events or observations are selected for a calculation.

**Context:** Used to define populations for monthly analysis, event sequences, statistical baselines, and behavioural comparisons.

**Important distinction:** Changing the observation window may change the result even when the underlying historical data remains unchanged.

---

## 13. SUPERVISORY INTERPRETATION AND EVIDENCE

### 13.1 Supervisory intelligence

**Definition:** Analytical information derived from financial records to support examination of activity, behaviour, and patterns across the represented institutions.

**Context:** OCB's supervisory dashboard presents the outputs of the SQL intelligence layer through a set of investigation questions.

**Boundary:** The dashboard presents analytical evidence. It does not independently establish a legal or regulatory finding.

### 13.2 Investigation question

**Definition:** A defined question that directs an analytical examination of a financial pattern or population.

**Context:** OCB's supervisory dashboard organises its outputs around investigation questions supported by the available analytical evidence.

### 13.3 Evidence

**Definition:** The source records, derived values, and documented calculation logic that support or qualify an analytical statement.

**Context:** Evidence allows an analyst to understand how an intelligence output was produced and what it does—and does not—establish.

### 13.4 Investigative lead

**Definition:** An observation or analytical result that may justify further examination.

**Context:** A behavioural signal may provide a lead for additional analysis.

**Boundary:** A lead is not a conclusion. Additional evidence may support, qualify, or contradict the initial interpretation.

### 13.5 Association

**Definition:** A relationship between observations established by a defined matching rule, shared analytical identity, timing, or other explicit condition.

**Context:** Used when examining activity across events or institutional domains.

**Boundary:** Association must not be presented as causation or proof of direct financial linkage without supporting evidence.

### 13.6 Causation

**Definition:** A relationship in which one event or factor is established to have caused another.

**Context:** Causal claims require evidence beyond temporal order or statistical association.

**OCB boundary:** The existence of a sequence, recurrence interval, rapidity measure, or cross-domain relationship does not by itself establish causation.

### 13.7 Interpretive limitation

**Definition:** A documented boundary on what an analytical result supports.

**Context:** OCB's signals must be interpreted according to their actual calculation and available evidence.

The platform must not claim that a signal independently proves:

- Fraud.
- Money laundering.
- Misconduct.
- Intent.
- Direct funding between events.
- Causation.
- A formal risk classification.
- A validated probability of wrongdoing.

---

## 14. GOVERNANCE AND DOCUMENTATION TERMINOLOGY

The following terms describe project documentation and engineering governance. They are not financial entities, event attributes, or implemented analytical measures.

They are retained in the glossary to explain references that may appear in project-control documentation, but they must not be presented as features of the OCB intelligence engine.

### 14.1 Architectural Decision Record (ADR)

**Definition:** A document recording a consequential architectural decision, including its context, rationale, alternatives, and consequences.

**Context:** Project governance and architectural documentation.

**Implementation distinction:** An ADR is a documentation artefact, not a database entity or an analytical signal.

### 14.2 Work Breakdown Structure (WBS)

**Definition:** A structured decomposition of project work into programmes, work packages, tasks, and deliverables.

**Context:** Project planning and delivery control.

**Implementation distinction:** A WBS is a project-management structure, not part of the financial data model or intelligence logic.

### 14.3 Acceptance criteria

**Definition:** Conditions that must be satisfied for a defined work item to be considered complete.

**Context:** Project delivery and validation.

### 14.4 Validation

**Definition:** The process of establishing whether an implementation or analytical result meets its specified requirements.

**Context:** Includes checks on data, calculations, relationships, and expected analytical behaviour where implemented.

**Important distinction:** A test passing demonstrates that the tested condition passed under the test's assumptions. It does not establish that every possible interpretation or operational condition has been validated.

### 14.5 Baseline

**Definition:** The agreed version of the platform and its documented implementation state against which changes are assessed.

**Context:** OCB v1.0.0 release control.

---

## 15. ACRONYMS AND ABBREVIATIONS

| Term | Meaning | Context |
|---|---|---|
| OCB | Osagyefo Central Bank Digital Financial Intelligence Platform | Project identity |
| SQL | Structured Query Language | Data querying and manipulation |
| T-SQL | Transact-SQL | SQL Server implementation language |
| MAD | Median Absolute Deviation | Robust statistical measure of dispersion |
| P2P | Person-to-Person | Mobile-money transaction type |
| ADR | Architectural Decision Record | Architecture governance documentation |
| WBS | Work Breakdown Structure | Project planning and delivery control |
| ID | Identifier | A value used to identify an entity or record |
| v1.0.0 | Version 1.0.0 | OCB baseline release |

Acronyms should be included only where they help readers interpret the platform or its documentation. An acronym's presence in this glossary does not imply that it appears in the dashboard, SQL output, or financial data model.

---

## 16. TERMINOLOGY DISTINCTIONS THAT MUST BE PRESERVED

The following distinctions are particularly important to the interpretation of OCB.

| Term A | Term B | Required distinction |
|---|---|---|
| `source_customer_id` | `ocb_customer_id` | Source-assigned customer identity versus OCB's canonical analytical customer identity |
| `cross_domain_id` | `ocb_customer_id` | Synthetic simulation ground truth versus the canonical analytical customer key |
| Record ID | Customer ID | Identifies an individual record versus a customer |
| Event timestamp | Processing timestamp | Time associated with the event versus time associated with its processing, where both are represented |
| Event attribute | Derived field | Recorded property versus a value calculated from other data |
| Transaction amount | Total value | Individual monetary amount versus an aggregate |
| Total value | Net flow | Sum of included amounts versus net movement under defined inflow/outflow rules |
| Loan principal | Outstanding obligation | Original principal amount versus the obligation remaining under the applicable calculation |
| Repayment amount | Cumulative repayment | Individual repayment event amount versus the sum over a defined period |
| Maturity date | Repayment status | Scheduled contractual date versus evidence about the state of repayment |
| Repayment deficiency | Credit-value escalation | Incomplete repayment relative to the preceding principal versus increasing subsequent borrowing value |
| Rapidity | Recurrence interval | Time from a defined anchor event to a subsequent event versus time between successive qualifying occurrences |
| Frequency | Recurrence interval | Event count versus elapsed time between occurrences |
| Sequence duration | Event interval | Span across a defined sequence versus elapsed time between two specified events |
| Absolute deviation | MAD | Individual observation's distance from the median versus the median of those distances |
| MAD | Risk score | Statistical dispersion measure versus a numeric risk-scoring output |
| Statistical anomaly | Misconduct | Unusual observation under a defined rule versus a substantive conclusion |
| Signal | Risk classification | Analytical output versus an explicit categorical assignment under defined classification rules |
| Temporal association | Direct funding | Events occurring in a temporal relationship versus evidence of an actual funding relationship |
| Remittance send | Remittance receive | Different sides or directions of remittance activity |
| Source record | Intelligence output | Recorded evidence versus a result derived from that evidence |
| Logical data layer | Physical database implementation | A conceptual processing layer versus its actual physical implementation |
| ADR | Intelligence signal | Architecture-governance document versus an analytical output |
| WBS | Data model | Project work structure versus the representation of financial entities and events |

---

## 17. DEFINITION AND IMPLEMENTATION CONTROL

The glossary must remain consistent with the implemented OCB v1.0.0 platform.

When a term refers to a physical field or calculated output, its final technical definition should be checked against the corresponding SQL object and the Data Dictionary.

This is especially important for:

- Event-location attributes.
- Remittance direction and send/receive representations.
- Source and analytical customer identifiers.
- The event population used by a sequence calculation.
- The timestamps used as temporal anchors.
- The exact formula represented by a field such as `abs_mad`.
- The qualifying conditions for each intelligence signal.
- The distinction between event-level outputs and aggregated metrics.

A field name alone is not sufficient evidence for its full implementation semantics. Where the exact SQL expression or source definition has not been verified, the glossary should state the supported business meaning without inventing additional behaviour.

### 17.1 Terminology change control

A material terminology change may require updates to:

- Database objects.
- Documentation.
- The Data Dictionary.
- Intelligence logic.
- Tests and validation evidence.
- Diagrams.
- Relevant project-governance records.

A terminology change that alters the interpretation of existing financial data must not silently change the historical meaning of that data.

### 17.2 Relationship to other documents

- **Project Summary:** Explains the platform's identity, purpose, and overall scope.
- **Project Control Document:** Establishes project boundaries, governance, and release control.
- **Work-package documentation:** Explains the implementation work and the analytical logic within its scope.
- **Business Glossary & Domain Dictionary:** Defines the business and analytical terminology.
- **Signal notes:** Explain the individual signal's qualifying conditions, calculations, and interpretation.

The glossary supports these documents without replacing their specialised responsibilities.

---

## 18. COMPLETION STANDARD

The Business Glossary & Domain Dictionary is sufficiently mature for the v1.0.0 release when:

- The three institutional domains have consistent definitions.
- Implemented financial entities and event types have defined meanings.
- Identity terms distinguish source identifiers, simulation ground truth, and the canonical analytical customer key.
- Important entity attributes have clear business definitions.
- Remittance direction and event terminology are not conflated.
- Temporal concepts such as sequence, recurrence, and rapidity are distinguished.
- Statistical terms such as median, absolute deviation, and MAD are explained accurately.
- Derived analytical concepts are distinguishable from source financial events.
- Intelligence signals are described without implying unsupported conclusions.
- Unsupported claims about risk scores and risk classifications are excluded.
- Governance terms are clearly separated from implemented analytical concepts.
- Terminology remains consistent with the relevant SQL logic and physical data definitions.
- Unverified implementation details are not presented as facts.
- Cross-domain relationships are not described as proof of causation or direct funding without supporting evidence.

---

## 19. GOVERNING PRINCIPLE

The purpose of this document is not to create a dictionary of every term used in finance or software engineering. It is to establish a precise shared language for the concepts that matter to OCB's implemented platform.

Terms should reflect the real business and analytical model. Statistical methods should be distinguished from the signals that use them. Source facts should be distinguished from derived interpretations. Governance documentation should be distinguished from system functionality.

Most importantly, the glossary must describe what OCB v1.0.0 actually implements—not what a future or more elaborate platform might implement.

**END OF BUSINESS GLOSSARY & DOMAIN DICTIONARY — OCB PLATFORM v1.0.0**