USE ev;
SELECT * FROM electric_vehicle_sales_by_state;
SELECT * FROM ev.electric_vehicle_sales_by_makers;
select * from dim_date;
##--data cleaning
#---date in form of abbreviated month name('01-Apr-2021') so use ('%d-%b-%y')
UPDATE electric_vehicle_sales_by_state
SET ï»¿date = STR_TO_DATE(ï»¿date, '%d-%b-%y');

update electric_vehicle_sales_by_makers
set ï»¿date = str_to_date(ï»¿date, '%d-%b-%y');

update  dim_date
set ï»¿date = str_to_date(ï»¿date,'%d-%b-%y');

ALTER table dim_date
rename column ï»¿date to date;

ALTER table electric_vehicle_sales_by_makers
rename column ï»¿date to date;

ALTER table electric_vehicle_sales_by_state
rename column ï»¿date to date;

#1. List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.

WITH cte1 AS
(SELECT 
    ev.maker,
    fiscal_year,
    sum(ev.electric_vehicles_sold) as total_ev_sales,
    dense_rank()over(partition by fiscal_year order by sum(ev.electric_vehicles_sold) desc) as ranking 
FROM electric_vehicle_sales_by_makers ev
JOIN dim_date d 
ON d.date=ev.date
WHERE vehicle_category="2-Wheelers" and fiscal_year IN ("2023","2024")
GROUP BY maker,fiscal_year
Order By fiscal_year)
select 
	maker,
    fiscal_year,
    total_ev_sales,
    ranking
from cte1
where ranking<=3;

#2.Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.
select s.state,((electric_vehicles_sold / total_vehicles_sold) * 100) as Penetration Rate,d.fiscal_year
from electric_vehicle_sales_by_state s
join dim_date d on d.date=s.date
where s.vehicle_category in ("2-Wheelers","4-Wheelers") and d.fiscal_year=2024
group by state
order by Penetration Rate desc limit 5;

#3. List the states with negative penetration (decline) in EV sales from 2022 to 2024?
select s.state,((electric_vehicles_sold / total_vehicles_sold) * 100) as Penetration Rate,d.fiscal_year
from electric_vehicle_sales_by_state s
join dim_date d on d.date=s.date
where d.fiscal_year between 2022 and 2024
and ((electric_vehicles_sold / total_vehicles_sold) * 100) < 0;

#4. What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?
with Top5makers as (select maker,vehicle_category,d.fiscal_year,sum(electric_vehicles_sold) as total_sold
from electric_vehicle_sales_by_makers m
join dim_date d on d.date=m.date
where d.fiscal_year between 2022 and 2024
and vehicle_category="4-Wheelers"
group by maker
order by total_sold desc limit 5)
SELECT m.maker,
       m.vehicle_category,
       d.fiscal_year,
       d.quarter,
       SUM(m.electric_vehicles_sold) AS sold_volume
FROM electric_vehicle_sales_by_makers m
JOIN dim_date d ON d.date = m.date
JOIN Top5Makers t ON m.maker = t.maker
WHERE d.fiscal_year BETWEEN 2022 AND 2024
  AND m.vehicle_category = '4-Wheelers'
GROUP BY m.maker, m.vehicle_category, d.fiscal_year, d.quarter
ORDER BY m.maker, d.fiscal_year, d.quarter;

#5. How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?
select state,electric_vehicles_sold,
((electric_vehicles_sold / total_vehicles_sold) * 100) as Penetration_Rate
from electric_vehicle_sales_by_state s
join dim_date d on d.date=s.date
where state in ("Delhi","karnataka") 
and d.fiscal_year = 2024
order by Penetration_Rate desc;

#6. List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.
with Top5makers as (select maker,vehicle_category,d.fiscal_year,sum(electric_vehicles_sold) as total_sold
from electric_vehicle_sales_by_makers m
join dim_date d on d.date=m.date
where d.fiscal_year between 2022 and 2024
and vehicle_category="4-Wheelers"
group by maker
order by total_sold desc limit 5)
select m.maker, 
round(power((SUM(CASE WHEN d.fiscal_year = "2024" THEN m.electric_vehicles_sold ELSE 0 END) / 
     SUM(CASE WHEN d.fiscal_year = "2022" THEN m.electric_vehicles_sold ELSE 0 END)),0.5) - 1,2) AS CAGR
from electric_vehicle_sales_by_makers m  
join dim_date d on d.date = m.date
where vehicle_category="4-Wheelers" and maker in (select maker from Top5makers)
group by maker
order by CAGR desc;
     
#7. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.
    with Top10state as (select state,sum(total_vehicles_sold) as total_vahicle_sold from electric_vehicle_sales_by_state s
     join dim_date d on d.date = s.date
     where d.fiscal_year between 2022 and 2024
     group by state
     order by total_vahicle_sold desc limit 10)
select state,round(power((sum(case when d.fiscal_year = 2024 then total_vehicles_sold else 0 end)/
                   sum(case when d.fiscal_year ="2022" then total_vehicles_sold else 0 end)),0.5)-1,2) as CAGR 
                   from electric_vehicle_sales_by_state s
                   join dim_date d on d.date=s.date
                   where state in (select state from Top10state)
                   group by state
                   order by CAGR desc;
                   
#8. What are the peak and low season months for EV sales based on the data from 2022 to 2024?                  
   
select extract(month from d.date) as peak_month,
monthname(d.date) as monthname,
sum(electric_vehicles_sold) as total_ev_sales,
d.fiscal_year
from electric_vehicle_sales_by_makers m
join dim_date d on d.date=m.date
where d.fiscal_year between 2022 and 2024
group by peak_month,monthname
order by total_ev_sales desc limit 3;    

select extract(month from d.date) as low_month,
monthname(d.date) as monthname,
sum(electric_vehicles_sold) as total_ev_sales,
d.fiscal_year
from electric_vehicle_sales_by_makers m
join dim_date d on d.date=m.date
where d.fiscal_year between 2022 and 2024
group by low_month,monthname
order by total_ev_sales asc limit 3 ;  

# 9. What is the projected number of EV sales (including 2-wheelers and 4-wheelers) 
	 #for the top 10 states by penetration rate in 2030,
     #based on the compounded annual growth rate (CAGR) from previous years?
     with Top10states as (select state,(sum(electric_vehicles_sold)/sum(total_vehicles_sold))*100 as per_rate
     from electric_vehicle_sales_by_state m
     join dim_date d on d.date= m.date
     group by state
     order by per_rate desc 
     limit 10),
     
     cagr_cte as 
     (select state,round(power((sum(case when d.fiscal_year = 2024 then total_vehicles_sold else 0 end)/
                   sum(case when d.fiscal_year ="2022" then total_vehicles_sold else 0 end)),0.5)-1,2 )as CAGR 
                   from electric_vehicle_sales_by_state s
                   join dim_date d on d.date=s.date
                   where state in (select state from Top10states)
                   group by state
                   order by CAGR desc),
                   
      sales_2024 as             
     (select m.state,d.fiscal_year,sum(electric_vehicles_sold) as sales_2024
     from electric_vehicle_sales_by_state m
     join dim_date d on d.date=m.date
     join Top10states T on T.state=m.state
     where d.fiscal_year=2024
     group by T.state)
     
     select s.state,s.sales_2024,
     ROUND(sales_2024*power((1+CAGR),6),2) as project_sales,c.CAGR
     from sales_2024 s
     join cagr_cte c on c.state=s.state
     group by state
     order by project_sales desc ;
     
     #10. Estimate the revenue growth rate of 4-wheeler 
     #and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price. 
     with revenue as 
     (SELECT 
	vehicle_category,fiscal_year,
	CASE
		WHEN vehicle_category="2-Wheelers" THEN sum(electric_vehicles_sold*85000)
        ELSE sum(electric_vehicles_sold*1500000)
        END AS revenue
FROM electric_vehicle_sales_by_makers m 
JOIN dim_date d 
ON d.date=m.date
group by vehicle_category,fiscal_year
order by vehicle_category,fiscal_year)
#----calculate revenue growth rate
select vehicle_category,fiscal_year,revenue,
lag(revenue,1) over (partition by vehicle_category order by fiscal_year) as last_year_revenu,
case 
when lag(revenue,1) over (partition by vehicle_category order by fiscal_year) is not null 
then (revenue-lag(revenue,1) over (partition by vehicle_category order by fiscal_year))/ lag(revenue,1) over (partition by vehicle_category order by fiscal_year) *100 
else null end as revenue_growth_rate
from revenue
order by vehicle_category,fiscal_year;


