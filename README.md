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


## Page 1 — Overview Dashboard

This dashboard provides a high-level summary of matatu transport network performance across 15 SACCOs and 30 routes from January 2026 to December 2026.

**Key KPIs:**
- **Total Revenue** — KSh 57.35M
- **Total Profit** — KSh 43.62M (76.06% profit margin)
- **Total Fuel Cost** — KSh 13.73M (23.94% of revenue)
- **Total Matatu Trips** — 17,000 completed journeys

Overall revenue stood at KSh 57.35M with a healthy profit margin of 76.06%, generating KSh 43.62M in earnings. Fuel costs consumed 23.94% of revenue, leaving strong margins across the network. With 17,000 trips completed across 29 vehicles, the network demonstrates consistent demand and operational utilization. This indicates a well-functioning transport system with sustainable profitability metrics.

Electric vehicles maintain a commanding 95% profit margin despite representing only 6% of total trips, while Standard vehicles drive volume with 59% of trips but earn lower margins at 71%. Nganya vehicles strike a balance at 80% margin with 35% trip volume. Peak demand occurs during afternoon hours (31.17% of daily revenue), morning peaks at 26.26%, with night hours representing the weakest demand at 16.81%. Diesel fuel dominates the fleet's fuel type composition at 73.48% of profit contribution, outperforming Petrol vehicles by 5 percentage points despite lower trip volume. This portfolio composition reveals significant margin-per-trip efficiency differences across vehicle types and fuel types.

This dashboard serves as an executive snapshot, enabling SACCO managers and fleet operators to quickly assess network health, identify the most efficient vehicle deployments, and spot peak demand windows for tactical scheduling decisions.


<img width="731" height="411" alt="overview " src="https://github.com/user-attachments/assets/4806f896-6842-47c7-b770-a313229c1b02" />

<img width="735" height="410" alt="profitability" src="https://github.com/user-attachments/assets/5a858073-1a25-4c07-a579-afd474bf6cdb" />

<img width="735" height="413" alt="cost" src="https://github.com/user-attachments/assets/58efd69c-d9f7-42e1-9ca0-12562c3d5f7a" />

<img width="734" height="411" alt="summary" src="https://github.com/user-attachments/assets/98ef4190-cf35-42bb-ab0a-ee6d7043d711" />



