\# BiciMAD 2022 — SQL \& Power BI Analysis



\## Project Overview



This project analyzes Madrid's \*\*BiciMAD bike-sharing system during 2022\*\* using \*\*SQL Server\*\* and \*\*Power BI\*\*.



The goal was to transform raw trip and station-status data into a structured analytical model to understand:



\- \*\*When\*\* demand is highest

\- \*\*Where\*\* bike and docking-slot shortages occur

\- \*\*How\*\* station-level flow imbalances relate to operational pressure



The project covers the full analytical workflow:



\*\*Raw data → Data quality → SQL transformations → Data model → DAX → Power BI dashboard → Operational insights\*\*



\---



\## Dashboard



\### 1. Overview



!\[Overview](images/overview.png)



The Overview page provides a high-level view of BiciMAD usage during 2022.



\#### Key KPIs



\- \*\*4.14M total trips\*\*

\- \*\*3.58M valid trips\*\*

\- \*\*13.58% short circular trips\*\*

\- \*\*14.04 min average trip duration\*\*

\- \*\*12.03 min median trip duration\*\*



\#### Main patterns



\- Weekday demand shows clear commuting peaks around \*\*08:00\*\* and \*\*18:00–20:00\*\*

\- Weekend demand is flatter and shifts later in the day

\- The \*\*10–20 minute\*\* range contains the largest share of valid trips



\---



\### 2. Data Quality \& Trip Types



!\[Data Quality \& Trip Types](images/data\_quality.png)



This page focuses on trip classification and the main data-quality decisions applied before the core mobility analysis.



\#### Key results



\- \*\*562.9K short circular trips\*\*

\- \*\*14.8

