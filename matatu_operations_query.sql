DROP TABLE IF EXISTS matatu_operation_dataset;

CREATE TABLE matatu_operation_dataset(
	trip_id	VARCHAR(30) PRIMARY KEY,
	time_of_day	VARCHAR(30),
	season VARCHAR(25),	
	corridor VARCHAR(60),	
	cbd_stage VARCHAR(30),
	sacco VARCHAR(50),	
	vehicle_type VARCHAR(50),	
	vehicle_name VARCHAR(45),	
	passenger_count	INT,
	fuel_type VARCHAR(35),
	payment_method VARCHAR(25),	
	vehicle_capacity INT,	
	fare_ksh FLOAT,	
	fuel_consumption_Litrers100km	FLOAT,
	fuel_price_unit FLOAT,
	revenue_ksh FLOAT,	
	fuel_cost FLOAT,
	profit_ksh FLOAT,	
	date_clean DATE,
	distance_km_clean FLOAT,
	route_number VARCHAR(10)


)

SELECT * FROM matatu_operation_dataset;

-- Checking for Duplicate Records
SELECT *
FROM matatu_operation_dataset
GROUP BY trip_id
	HAVING COUNT(*) > 1;

-- Total Trips made by Matatus Under Operation
SELECT
	COUNT(*) AS total_matatu_trips
FROM matatu_operation_dataset;

-- Total Revenue
SELECT
	ROUND(SUM(revenue_ksh)::numeric,2) AS total_revenue
FROM matatu_operation_dataset;

-- Total Profit
SELECT
	ROUND(SUM(profit_ksh)::numeric,2) AS total_profit
FROM matatu_operation_dataset;
   
-- Total Fuel Cost
SELECT
	ROUND(SUM(fuel_cost)::numeric,2) AS total_fuel_cost
FROM matatu_operation_dataset;

-- Total Matatus
SELECT
	COUNT(DISTINCT vehicle_name) AS total_matatus
FROM matatu_operation_dataset;

-- Total Routes
SELECT
	COUNT(DISTINCT route_number) AS total_routes
FROM matatu_operation_dataset; -- 31 ROUTES


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
WHERE profit_rank <= 3

-- Top 3 Best Performing Saccos by Profitability
WITH sacco_performance AS (
	SELECT
		sacco,
		ROUND(SUM(revenue_ksh)::numeric,2) AS total_revenue,
		ROUND(SUM(profit_ksh)::numeric,2) AS total_profit
	FROM matatu_operation_dataset
	GROUP BY sacco
), 
best_performing_saccos AS(
	SELECT
		sacco,
		total_revenue,
		total_profit,
		DENSE_RANK() OVER(ORDER BY total_profit DESC) AS sacco_profit_rank
	FROM sacco_performance
)
SELECT
	sacco,
	total_revenue,
	total_profit,
	sacco_profit_rank
FROM best_performing_saccos
WHERE sacco_profit_rank <= 3
ORDER BY total_profit DESC;


--- Profit margin percentage per route
WITH route_profit_margin AS(
	SELECT
		route_number,
		vehicle_type, 
		ROUND(SUM(revenue_ksh)::numeric,2) AS total_revenue,
		ROUND(SUM(profit_ksh)::numeric,2) AS total_profit,
		ROUND((SUM(profit_ksh) / SUM(revenue_ksh))::numeric * 100,2) AS profit_margin
	FROM matatu_operation_dataset
	GROUP BY route_number, vehicle_type
), 
profit_margin_performance AS(
SELECT
	route_number,
	vehicle_type,
	total_revenue,
	total_profit,
	profit_margin,
	DENSE_RANK() OVER(PARTITION BY vehicle_type ORDER BY profit_margin DESC) AS profit_margin_rn
FROM route_profit_margin
)
SELECT
	route_number,
	vehicle_type,
	total_revenue,
	total_profit,
	profit_margin,
	profit_margin_rn
FROM profit_margin_performance
WHERE profit_margin_rn <= 5;


-- Total Trips made by matatus on operations by time of the day
SELECT
	time_of_day,
	COUNT(*) AS total_matatu_trips
FROM matatu_operation_dataset
GROUP BY time_of_day
ORDER BY total_matatu_trips DESC;

-- Trips on specific routes
SELECT
	route_number AS total_routes,
	COUNT(*) total_matatu_trips
FROM matatu_operation_dataset
GROUP BY route_number
ORDER BY total_matatu_trips DESC;

-- SACCO performance by Matatus
SELECT
	sacco,
	COUNT(*) AS total_matatu_trips,
	ROUND(SUM(revenue_ksh)::numeric,2) AS total_revenue,
	ROUND(SUM(profit_ksh)::numeric,2) AS total_profit
FROM matatu_operation_dataset
GROUP BY sacco
ORDER BY total_profit DESC;

-- Revenue per kilometre travelled
SELECT
	distance_km_clean,
	ROUND(SUM(revenue_ksh)::numeric,2)
FROM matatu_operation_dataset
GROUP BY distance_km_clean
ORDER BY distance_km_clean DESC

-- Fuel Consumption Rates based on the Vehicle type
SELECT
	vehicle_type, 
	ROUND(AVG(distance_km_clean)::numeric,2) AS avg_distance,
	ROUND(AVG(fuel_consumption_litrers100km)::numeric,2) AS avg_fuel_consumption,
	ROUND(AVG (fuel_cost)::numeric,2) AS avg_fuel_cost
FROM matatu_operation_dataset
GROUP BY vehicle_type
ORDER BY avg_fuel_cost ASC;

-- Revenue generation by Payment Methods
SELECT
	payment_method,
	ROUND(SUM(revenue_ksh)::numeric,2) AS revenue
FROM matatu_operation_dataset
GROUP BY payment_method
ORDER BY revenue DESC;

-- Matatu Operations Yearly Performance
SELECT
	EXTRACT(YEAR FROM date_clean) AS year,
	ROUND(SUM(revenue_ksh)::numeric,2) AS revenue,
	ROUND(SUM(profit_ksh)::numeric,2) AS matatu_profits
FROM matatu_operation_dataset
GROUP BY EXTRACT(YEAR FROM date_clean)
ORDER BY matatu_profits DESC;

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

-- YOY Analysis
WITH yearly_performance AS (
	SELECT
		EXTRACT(YEAR FROM date_clean) AS year,
		ROUND(SUM(revenue_ksh)::numeric,2) AS revenue,
		ROUND(SUM(profit_ksh)::numeric,2) AS matatu_profits
	FROM matatu_operation_dataset
	GROUP BY EXTRACT(YEAR FROM date_clean)
)
SELECT
	year,
	revenue,
	matatu_profits,
	LAG(matatu_profits) OVER(ORDER BY year) AS previous_year,
	ROUND(
		(matatu_profits - LAG(matatu_profits) OVER(ORDER BY year ASC))
		/ LAG(matatu_profits) OVER(ORDER BY year) * 100
	, 2) AS yr_pct_change
FROM yearly_performance
ORDER BY year ASC;

-- Fuel consumption by type
SELECT
	fuel_type,
	ROUND(SUM(fuel_cost)::numeric,2) AS avg_fuel_cost
FROM matatu_operation_dataset
GROUP BY fuel_type
ORDER BY avg_fuel_cost DESC;



