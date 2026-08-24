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
- Date range: January 2023 — December 2025

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

<img width="734" height="411" alt="summary" src="https://github.com/user-attachments/assets/98ef4190-cf35-42bb-ab0a-ee6d7043d711" />



