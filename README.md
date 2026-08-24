# Nairobi Matatu Operations Analysis

## Executive Summary

### Overview & Findings

This project presents a full end-to-end data analytics pipeline, analyzing synthetic operational data from Nairobi's matatu transport network. The analysis explores fleet performance, profitability by vehicle type, fuel efficiency, revenue patterns, and seasonal trends across 15 major SACCOs operating 30+ routes in the CBD.

The interactive Power BI dashboard enables us to perform:
- Identify most profitable routes, vehicle types, and SACCOs
- Analyze fuel consumption rates and operational efficiency
- Track revenue and profit trends month-over-month
- Segment performance by time of day, fuel type, and boarding stage
- Understand peak demand hours, seasonal patterns, and fleet deployment

### Data Sources
- 17,000 operational transactions (after deduplication)
- 15 SACCOs (City Shuttle, Forward Travelers, Embassava, City Hoppa, Nicco Movers, Super Metro etc.)
- 30 routes across Nairobi CBD network
- 3 vehicle types (Standard, Nganya, Electric)
- 3 fuel types (Petrol, Diesel, Electric)
- Date range: January 2023 - December 2025

---

## Tools Used

### a. Excel
Excel was used as the initial data inspection tool to:
  
-  Explore the raw dataset structure and column formats
-  Perform a preliminary review of missing values and inconsistencies
-  Validate data before ingestion into Python for deeper analysis

###  b. Python (Jupyter Notebook)

Python was the primary data cleaning and transformation tool used to:
- Standardize column formats
    - route names, vehicle types, SACCO names, fuel types
- Handle messy data
    - mixed date formats, negative distances, currency symbols in revenue/fare columns
- Treat outliers using per-route Winsorization (IQR method) to preserve route-level variation while capping unrealistic values
- Remove duplicates
    - 510 duplicate rows removed, retaining 17,000 clean records
- Engineer new features
    - AbsoluteDistance (from negative values), MonthName, DayOfWeek, TimeOfDayCategory
- Perform Exploratory Data Analysis (EDA)
    - distribution analysis, outlier detection, missing value assessment
- Export clean datasets for SQL and Power BI ingestion

  
###  c. SQL (PostgreSQL)

The cleaned data was loaded into PostgreSQL for structured analytical queries:
- Wrote analytical queries using Common Table Expressions (CTEs), subqueries, and window functions (LAG, LEAD, DENSE_RANK, ROW_NUMBER)
- Performed Month-over-Month (MoM) profit analysis using LAG() to track sequential monthly growth rates
- Calculated profitability metrics
    - profit margin %, revenue per km, fuel cost per km
- Ranked routes, vehicle types, and SACCOs by profit and margin using DENSE_RANK()

  
###  d. Power BI

Power BI was used for interactive dashboard development and storytelling:
- Built a 4-page dashboard covering Overview, Profitability, Costs, and Summary
- Created DAX measures for:
  - Total Revenue, Total Profit, Total Fuel Cost, Total Trips
  - Profit Margin % = (Profit / Revenue) * 100
  - Fuel Consumption Rate = AVERAGE(fuel_consumption)
  - Revenue per Fuel KES = SUM(revenue) / SUM(fuel_cost)
  - Most/Least Profitable Route using TOPN() and CALCULATE()
- Implemented slicers for dynamic filtering by Vehicle Type, Fuel Type, SACCO, Time of Day, and Route
- Designed visual storytelling through KPI cards, dual-axis bar charts, pie charts, trend lines, and matrix tables.

---

## Data Analysis

```python
# Load the dataset
df = pd.read_csv("./data/nairobi_matatu_synthetic_dataset.csv")

print(df.to_string(max_rows = 10))
```
```python
# Save the cleaned dataset to a new CSV file
df.to_csv("./data/nairobi_matatu_synthetic_dataset_cleaned.csv", index = False)
```
```sql
-- Profit Margin
SELECT
	total_revenue,
	total_profit,
	ROUND((total_profit/total_revenue) * 100,2) AS profit_margin
FROM(
	SELECT
		ROUND(SUM(revenue_ksh)::numeric,2) AS total_revenue,
		ROUND(SUM(profit_ksh)::numeric,2) AS total_profit
	FROM matatu_operation_dataset
);
```
```sql


-- Best Performing Routes per Vehicle Type
WITH route_performance AS (
	SELECT
		route_number,
		vehicle_type, 
		ROUND(SUM(revenue_ksh)::numeric,2) AS total_revenue,
		ROUND(SUM(profit_ksh)::numeric,2) AS total_profit
	FROM matatu_operation_dataset
	GROUP BY route_number, vehicle_type
	-- ORDER BY total_profit DESC
),
best_routes_per_vehicle_type AS(
	SELECT
		route_number,
		vehicle_type,
		total_revenue,
		total_profit,
		DENSE_RANK() OVER(PARTITION BY vehicle_type ORDER BY total_profit DESC) AS profit_rank
	FROM route_performance
)
SELECT
	route_number,
	vehicle_type,
	total_revenue,
	total_profit,
	profit_rank
FROM best_routes_per_vehicle_type
WHERE profit_rank <= 3;
```
```sql

-- Monthly Performance
SELECT
	EXTRACT(MONTH FROM date_clean) AS month,
	TO_CHAR(date_clean, 'Mon') AS month_name,
	ROUND(SUM(revenue_ksh)::numeric,2) AS revenue,
	ROUND(SUM(profit_ksh)::numeric,2) AS matatu_profits
FROM matatu_operation_dataset
GROUP BY EXTRACT(MONTH FROM date_clean), TO_CHAR(date_clean, 'Mon')
ORDER BY month ASC;


-- MOM Analysis
WITH monthly_performance AS (
	SELECT
		EXTRACT(MONTH FROM date_clean) AS month,
		TO_CHAR(date_clean, 'Mon') AS month_name,
		ROUND(SUM(revenue_ksh)::numeric,2) AS revenue,
		ROUND(SUM(profit_ksh)::numeric,2) AS matatu_profits
	FROM matatu_operation_dataset
	GROUP BY EXTRACT(MONTH FROM date_clean), TO_CHAR(date_clean, 'Mon')
)
SELECT
	month,
	month_name,
	revenue,
	matatu_profits,
	LAG(matatu_profits) OVER(ORDER BY month ASC) AS previous_month,
	ROUND(
	(matatu_profits - LAG(matatu_profits) OVER(ORDER BY month ASC))
	/ LAG(matatu_profits) OVER(ORDER BY month ASC) * 100
	,2 ) AS monthly_pct_change
FROM monthly_performance
ORDER BY month ASC;
```
---
# Project Dashboards

The project includes interactive Power BI dashboards designed to analyze Nairobi's matatu transport operations from multiple perspectives, including profitability analysis, fuel efficiency, operational performance, and strategic planning.


## Page 1 - Overview Dashboard

This dashboard provides a high-level summary of matatu transport network performance across 15 SACCOs and 30 routes from January 2026 to December 2026.

```
Key KPIs:
- Total Revenue — KSh 57.35M
- Total Profit — KSh 43.62M (76.06% profit margin)
- Total Fuel Cost — KSh 13.73M (23.94% of revenue)
- Total Matatu Trips — 17,000 completed journeys
```

Overall revenue stood at KSh 57.35M with a healthy profit margin of 76.06%, generating KSh 43.62M profits in return across the 3 years. 
Fuel costs consumed 23.94% of revenue, leaving strong margins across the network. 

With 17,000 trips completed across 29 vehicles, the network demonstrates consistent demand and operational utilization. This indicates a well-functioning transport system with sustainable profitability metrics.

Electric vehicles maintain a commanding 95% profit margin despite representing only 6% of total trips, while Standard vehicles drive volume with 59% of trips but earn lower margins at 71%. Nganya vehicles strike a balance at 80% margin with 35% trip volume. 

Peak demand occurs during afternoon hours (31.17% of daily revenue), morning peaks at 26.26%, with night hours representing the weakest demand at 16.81%. 

Diesel fuel dominates the fleet's fuel type composition at 73.48% of profit contribution, outperforming Petrol vehicles by 5 percentage points despite lower trip volume. 

This portfolio composition reveals significant margin-per-trip efficiency differences across vehicle types and fuel types.

This dashboard serves as an executive snapshot, enabling SACCO managers and fleet operators to quickly assess network health, identify the most efficient vehicle deployments, and spot peak demand windows for tactical scheduling decisions.


<img width="731" height="411" alt="overview " src="https://github.com/user-attachments/assets/4806f896-6842-47c7-b770-a313229c1b02" />

## Page 2 - Profitability Dashboard

This dashboard analyzes profitability performance across vehicle types, fuel types, SACCOs, and geographic boarding stages, revealing which operational segments drive the highest returns.

```
Key KPIs:
- Total Profit — KSh 43.62M
- Profit Margin — 76.06%
- Number of Routes — 30 active corridors
- Number of SACCOs — 15 transport operators
```

Profit distribution across the network is heavily concentrated in a few high-performing SACCOs and routes, with Embassava generating KSh 5.1M (11.7% of network profit), Citi Hoppa contributing KSh 4.7M (10.8%), and KBS adding KSh 3.9M (8.9%).

Together, the top 3 SACCOs account for 31% of network profit, indicating that profitability is not evenly distributed. This concentration presents a strategic opportunity, replicating the operational practices of top performers across lower-performing SACCOs could unlock significant margin improvements across the network.

Vehicle type profitability reveals a clear efficiency hierarchy: Electric vehicles achieve 95.45% margin in morning slots despite low volume, Nganya vehicles consistently maintain 80% margins across all time periods with balanced trip counts, and Standard vehicles persist at 71% margins despite representing the majority of trips. 

Diesel-powered vehicles dominate profit contribution at 73.48%, with CBD Railway and OTC boarding stages accounting for over 60% of revenue. This suggests that core urban corridor performance drives the network's profitability, and that fuel type optimization (Diesel-heavy fleets) directly improves bottom-line performance.

This dashboard enables SACCO management to identify their competitive position within the network, benchmark performance against peers, and understand which vehicle-type and fuel-type combinations maximize profit for their operational scale and route mix.

<img width="733" height="412" alt="profitability" src="https://github.com/user-attachments/assets/3907ed04-9da5-40b7-8cb3-5f95d1ab2dc9" />


## Page 3 - Costs Dashboard

This dashboard provides a granular view of fuel spending, consumption efficiency, and cost structures across vehicle types, fuel types, SACCOs, and time-of-day periods.

```
Key KPIs:
- Total Fuel Cost — KSh 13.73M
- Fuel Consumption Rate — 26.64 L/100km (average across petrol/diesel)
- Average Trip Distance — 16.15 km
- Trips Analyzed — 17,000 journeys
```

Fuel expenditure of KSh 13.73M represents 23.94% of total network revenue, a ratio well within sustainable operating parameters. Average fuel consumption of 26.64 L/100km across the petrol/diesel fleet indicates moderate efficiency typical of African urban transport operations. 

With an average trip length of 16.15 km, the typical matatu journey consumes approximately 4.3 litres of fuel, translating to a fuel cost of approximately KSh 807 per trip when calculated at average fuel prices. This cost structure is recoverable through current fares, confirming the network's operational sustainability.

Standard vehicles consume 64% of the network's total fuel budget at KSh 8.7M, while operating 59% of trips indicating slightly higher fuel consumption per trip than the network average. 

Nganya vehicles maintain better efficiency, consuming only KSh 4.7M fuel while running 35% of trips. Electric vehicles, though representing only 6% of trips, consume negligible fuel cost at KSh 0.3M due to extremely low electricity rates compared to petrol/diesel. 

Afternoon peak hours (2–5 PM) drive the highest fuel spend at KSh 4.3M, directly correlating with peak demand. 

SACCO-level fuel cost analysis reveals efficiency variation: Embassava achieves KSh 835 fuel cost per trip, while smaller operators vary between KSh 750–KSh 950 per trip, suggesting best-practice fuel management techniques are concentrated in larger SACCOs.

This dashboard enables fleet operators to monitor fuel spend in real time, identify which vehicle types and routes are over-consuming fuel relative to revenue generation, and benchmark SACCO-level efficiency metrics to drive continuous cost reduction.

<img width="734" height="412" alt="cost" src="https://github.com/user-attachments/assets/5c8af59b-8b1c-4e5a-9613-be6f2f378988" />

## Page 4 - Summary Dashboard

This dashboard synthesizes all dimensions — revenue, profitability, fuel costs, customer behavior, and seasonality vinto an integrated view for strategic decision-making and forward planning.

```
Key KPIs:
- Total Revenue — KSh 57.35M
- Total Profit — KSh 43.62M
- Total Trips — 17,000 journeys
- Active Fleet — 29 vehicles
```

Network revenue of KSh 57.35M translates to KSh 3.37M in average monthly revenue with consistent profitability maintaining 76% margins month-to-month. 

Standard vehicles generate the largest revenue volume at KSh 30M (52% of network revenue), followed by Nganya at KSh 21M (37%), and Electric vehicles at KSh 6M (11%). 

The consistency of profit across months suggests a stable operational model not significantly impacted by external shocks, though seasonal patterns warrant monitoring. 

M-Pesa payment dominance at 85%+ of transactions aligns with Kenya's mobile-money ecosystem, while cash payments remain a secondary channel at 15%, indicating mature digital payment adoption.

Revenue concentration by geography shows CBD Railway and OTC boarding stages accounting for over 60% of network revenue, with secondary nodes like Odeon and Kencom contributing 15–20% each. 

Seasonal analysis reveals Dry Season (June–October) generates 49.78% of annual revenue, indicating strong demand during school terms and favorable travel conditions, while Long Rains and Short Rains seasons each contribute ~25%, pointing to weather-dependent demand elasticity. 

Time-of-day analysis confirms Afternoon (2–5 PM) as the critical revenue window at 31.17%, suggesting that workforce commutes and afternoon leisure travel drive the bulk of matatu demand.

This dashboard serves as the strategic command center for network-wide planning, enabling leadership to forecast revenue by season, allocate vehicles by peak demand windows, manage cash flow across payment channels, and identify growth opportunities in underperforming geographic and temporal segments.


<img width="734" height="411" alt="summary" src="https://github.com/user-attachments/assets/98ef4190-cf35-42bb-ab0a-ee6d7043d711" />

---

## Recommendations

Based on the analysis of Nairobi matatu operations data across 15 SACCOs and 30 routes from January 2023 to December 2025, the following recommendations are proposed to guide strategic decision-making and improve overall network profitability and operational efficiency.

### 1. Expand Electric Vehicle Fleet from 6% to 15% of Network

Electric vehicles maintain a commanding 95% profit margin, the highest across all vehicle types yet represent only 6% of total network trips at 1,020 journeys. Despite generating just KSh 6M in absolute revenue, their near-zero fuel costs (KSh 0.3M) and high per-trip profitability make them the most efficient revenue generators. 

Expanding the Electric fleet from 2 vehicles to 5–6 vehicles (15% of network) would add approximately KSh 7–8M in incremental profit assuming same utilization rates, without proportional fuel cost increases. This expansion should prioritize short-haul, high-frequency CBD routes where Electric vehicles excel.

### 2. Redeploy Standard Vehicles from Primary Routes to Secondary Corridors

Standard vehicles consume 64% of the network's fuel budget (KSh 8.7M) while operating only 59% of trips, indicating fuel inefficiency compared to Nganya. Yet Standard vehicles generate KSh 30M in revenue and remain critical for volume. 

Rather than eliminating Standard vehicles, redeploy them to secondary, lower-demand routes and shorter-haul trips where their higher consumption is offset by simplicity and lower maintenance costs. Reserve primary high-volume corridors (CBD-Westlands, CBD-Karen, CBD-South) for Nganya vehicles which achieve 80% margins at identical fuel costs but with better per-trip profitability.

### 3. Accelerate Fleet Transition from Petrol to Diesel

Diesel-powered vehicles outperform Petrol vehicles by 5 percentage points in profit margin (77.35% vs 72.73%) across comparable routes and trip volumes. Petrol vehicles currently consume 16% of fuel budget (KSh 2.2M) while contributing only 12.73% of network profit. 

A systematic transition from Petrol to Diesel targeting 50% of Petrol fleet conversion within 12 months would unlock approximately KSh 1.5–2M in incremental annual profit through improved fuel efficiency and higher per-kilometer returns. Negotiate bulk Diesel-vehicle procurement with manufacturers to achieve favorable pricing during transition.

### 4. Optimize Afternoon Peak Deployment (12–5 PM Window)

Afternoon hours generate 31.17% of daily revenue (KSh 12.2M) despite representing only 25% of operational hours, indicating extreme peak concentration during the 12–5 PM commute window. 

Current deployment does not fully capitalize on this peak. SACCOs should redeploy 30–40% of fleet capacity to afternoon routes 12–2 hours before peak (1:00 PM departure) to maximize trip completion during the high-demand window. This tactical scheduling adjustment could increase afternoon revenue by 8–12% (approximately KSh 1–1.5M incremental) without requiring additional vehicles.


### 5. Invest in Electric Infrastructure at CBD Charging Hubs

Electric vehicles currently represent 95% margin but only 6% of network trips due to charging infrastructure limitations. Establish dedicated EV charging stations at the three highest-revenue CBD boarding stages (Railways, OTC, Odeon) to enable electric vehicles to complete multiple high-volume CBD loops without range constraints. 

Capital investment of approximately KSh 2–3M in charging infrastructure would enable scaling Electric fleet to 10–15 vehicles (from current 2) without operational risk. The 7–8 vehicles added would generate KSh 12–15M in incremental annual revenue at 95% margins.

### 6. Implement Dynamic Pricing for Peak Hours and Peak Seasons

Dry season (June–October) generates 49.78% of annual revenue while Short Rains and Long Rains seasons each contribute ~25%, yet current fares remain flat year-round. Similarly, afternoon peak (2–5 PM) drives 31% of daily revenue while night hours (10 PM–6 AM) drive only 17%, yet no time-of-day fare differentiation exists. 

Implement a dynamic pricing model: increase fares by 10–15% during Dry season and afternoon peaks, decrease by 5–10% during off-peak seasons and night hours. This model would improve revenue per trip by 3–5% (approximately KSh 1.7–2.8M incremental annually) while smoothing demand across underutilized night and off-season periods.

---

## Limitations

This analysis has several limitations that should be acknowledged when interpreting the results:

-	The dataset used in this project is synthetically generated and does not reflect real matatu operations. As a result, certain patterns and trends may be simplified or artificially structured, limiting the extent to which findings can be generalized to actual Nairobi SACCOs and route performance.

-	The analysis covers only a single calendar year (January 2023 – December 2025) and therefore cannot capture multi-year trends, cyclical patterns, or how the network responds to external shocks such as fuel price spikes, regulatory changes, or major traffic disruptions.

-	Fuel consumption data exhibits implausibly uniform variance across routes (3–7 percentage points within vehicle type), suggesting the synthetic data does not account for real-world consumption variation driven by traffic conditions, route terrain, driver skill, vehicle maintenance, and passenger load.

-	The dataset does not include upcountry routes (Nairobi–Nakuru, Nairobi–Mombasa) or specialized transport segments (school shuttles, corporate transport), limiting the generalizability of recommendations to long-distance and niche transport operations.

-	The analysis assumes uniform profit margins (76.06%) across all routes and SACCOs, but real operations exhibit significant fixed-cost structures and economies of scale that create route-level profitability variance not captured in this model.

-	Monthly profit trends show an artificial oscillating pattern (up-down-up-down) arising from the data generator rather than realistic seasonal variation, limiting the reliability of specific monthly rankings and seasonal recommendations without validation against actual historical traffic data.

-	Data quality issues were addressed through Winsorization (capping outlier distances) and deduplication (removing 510 suspected duplicates), which may have introduced systematic bias if these records represented legitimate operational states (express routes, parallel bookings) rather than errors.

-	The analysis does not account for external factors such as public holidays, fuel price fluctuations, competitor SACCO activity, weather events, or regulatory changes that would significantly influence real-world matatu demand and profitability.

---

## Conclusion

This end-to-end analytics project successfully transformed raw, messy matatu operational data into actionable business intelligence across 15 SACCOs, 30 routes, and 17,000 trips. The analysis reveals a fundamentally profitable transport network operating at 76% margins, but one with significant untapped efficiency and growth potential.

### Strategic Value Delivered

This project answers the five core business questions that matatu operators typically lack data to address:

1. **Which vehicle types are most profitable?** Electric (95% margin), Nganya (80%), Standard (71%)
2. **How can we optimize revenue?** Dynamic pricing for peak hours and seasons; afternoon deployment surge
3. **Which vehicles truly earn their fuel cost?** Diesel vehicles outperform Petrol by 5%; Electric eliminates fuel cost entirely
4. **When should we expand or contract?** Dry season drives 50% of revenue; afternoon generates 31% of daily trips
5. **Which operational practices drive profit?** Embassava's efficiency (KSh 835 fuel/trip) vs network (KSh 807 average) suggests replicable best practices

### Recommended Immediate Actions (90 Days)

- **Optimize afternoon peak deployment** - Reallocate 30–40% of fleet to 1:00 PM departure to maximize 2–5 PM demand window (KSh 1.0–1.5M incremental profit)
- **Implement dynamic pricing** - Increase fares 10–15% during Dry season and afternoon peaks; decrease 5–10% during off-peak periods (KSh 1.7–2.8M incremental profit)
- **Benchmark Embassava operations** - Audit top SACCO's fleet management, driver incentives, and route selection; roll out learnings to underperformers (KSh 2.0–3.0M incremental profit)

These three actions alone could unlock KSh 4.7–7.3M in incremental annual profit with minimal capital investment.

### Long-Term Strategic Opportunity

Expanding the Electric vehicle fleet from 2 to 5–6 vehicles (15% of network) represents a transformational investment. Capital cost of approximately KSh 2–3M per vehicle (totaling KSh 10–15M) would be recovered within 18–24 months through incremental profit of KSh 7–8M annually at 95% margins. Beyond financial returns, Electric vehicles position the network as a sustainable, forward-looking transport operator aligned with Kenya's climate goals and urban development priorities.

### Technical Excellence

The project demonstrates proficiency across the full modern data stack: Python for ETL and data cleaning, PostgreSQL for analytical SQL (CTEs, window functions, MoM analysis), Power BI for interactive dashboards, and Git for version control and reproducibility. The 4-page interactive dashboard enables SACCO managers and fleet operators to move from intuition-based decisions to data-backed strategy without requiring SQL or analytics expertise.

### Final Remarks

Nairobi's matatu industry is the backbone of urban mobility, moving millions daily. This project proves that structured analytics can unlock significant value not just through cost-cutting, but through strategic fleet optimization, dynamic pricing, and best-practice replication that benefit both operators and passengers through improved service and efficiency.

---

*Matatu Operations Analysis - Complete. Ready for Implementation.*
