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

## Project Structure


<img width="731" height="411" alt="overview " src="https://github.com/user-attachments/assets/4806f896-6842-47c7-b770-a313229c1b02" />

<img width="735" height="410" alt="profitability" src="https://github.com/user-attachments/assets/5a858073-1a25-4c07-a579-afd474bf6cdb" />

<img width="735" height="413" alt="cost" src="https://github.com/user-attachments/assets/58efd69c-d9f7-42e1-9ca0-12562c3d5f7a" />

<img width="734" height="411" alt="summary" src="https://github.com/user-attachments/assets/98ef4190-cf35-42bb-ab0a-ee6d7043d711" />



