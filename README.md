BiciMAD 2022 — SQL & Power BI Analysis




Project Overview

This project analyzes Madrid's BiciMAD bike-sharing system during 2022 using SQL Server and Power BI.

The goal was to transform raw trip and station-status data into a structured analytical model to understand:

when demand is highest,

where bike and docking-slot shortages occur,

and how station-level flow imbalances relate to operational pressure.

The project covers the full analytical workflow:

Raw data → Data quality → SQL transformations → Data model → DAX → Power BI dashboard → Operational insights

Dashboard Preview

Overview



Main network KPIs and temporal demand patterns.

4.14M total trips

3.58M valid trips

13.58% short circular trips

14.04 min average trip duration

12.03 min median trip duration

Data Quality & Trip Types



Focuses on trip classification and the main data-quality decisions.

562.9K short circular trips

14.8K trips over 24 hours

16.8K missing origin stations

19.9K missing destination stations

86.42% of trips included in the core mobility analysis

Short circular trips were defined as trips returning to the same station in under one minute and were analyzed separately from standard mobility activity.

Stations



Analyzes bike and docking-slot availability across 264 stations.

48.5K no-bike snapshots

43.8K no-slot snapshots

54 stations above the selected availability-issue threshold

The analysis shows that operational pressure is concentrated in specific stations rather than evenly distributed across the network.

Flows & Imbalances



Examines how trips move between stations and how flow imbalance relates to availability.

115 net receiver stations

148 net sender stations

124K total absolute network imbalance

3.5K largest single-station imbalance

Positive net balance is associated with higher no-slot rates, while negative net balance is associated with higher no-bike rates.

These relationships are associative rather than causal.

Tools & Technologies

SQL Server / T-SQL — cleaning, consolidation, joins and analytical views

Power BI — data modeling and dashboard development

DAX — KPIs, time analysis and station-level measures

Data & Methodology

The analysis combines two main sources:

approximately 4.14M BiciMAD trips

2.3M station-status records across 8,738 snapshots

Main preparation steps:

monthly data-quality validation,

annual trip consolidation,

trip-duration anomaly detection,

short circular trip classification,

station identifier normalization,

integration of trip and station-status data,

creation of station-level analytical views for Power BI.

Short circular trips were retained in the dataset but excluded from the core mobility analysis.

Key Findings

Demand follows predictable temporal patterns

Weekdays show clear commuting peaks around 08:00 and 18:00–20:00, while weekend demand is flatter and shifts later.

A significant share of trips behaves differently

Short circular trips account for 13.58% of total activity, supporting the decision to analyze them separately.

Station availability is uneven

Bike and docking-slot shortages repeatedly affect specific stations, indicating localized operational pressure.

Flow imbalance helps explain availability problems

Net receiver stations tend to face greater docking saturation, while net sender stations are more exposed to bike shortages.

Recommendations

Prioritize rebalancing at persistent negative-balance stations

Anticipate saturation at strong positive-balance stations

Concentrate operational resources around weekday commuting peaks

Monitor recurrent no-bike and no-slot stations

Keep short circular trips separate from core mobility KPIs

Combine station balance, availability and trip volume when prioritizing rebalancing

Final Conclusion

BiciMAD's main operational challenge is not simply demand generation, but redistributing bikes across space and time.

Usage follows predictable temporal patterns, while station-level imbalances contribute to recurring shortages of bikes and docking capacity.

Targeted rebalancing during peak periods and at persistently imbalanced stations could improve service reliability across the network.

Repository Structure

bicimad-2022-analysis/
│
├── README.md
├── sql/
│   ├── 01_data_quality_january.sql
│   ├── ...
│   ├── 18_powerbi_views.sql
├── powerbi/
│   └── BiciMAD_2022.pbix
└── images/
    ├── overview.png
    ├── data_quality.png
    ├── stations.png
    └── flows_imbalances.png

Skills Demonstrated

SQL · T-SQL · Data Cleaning · EDA · Data Modeling · DAX · Power BI · Dashboard Design · Data Storytelling