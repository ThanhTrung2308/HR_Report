select * from human_resources

SELECT column_name, data_type, is_nullable, character_maximum_length, column_default
FROM information_schema.columns
WHERE table_name = 'human_resources'

select birthdate from human_resources hr

-- lam sach gia tri birthdate
UPDATE human_resources 
SET birthdate = CASE 
    WHEN birthdate LIKE '%/%' THEN to_char(to_date(birthdate,'MM/DD/YYYY'), 'YYYY-MM-DD')
    WHEN birthdate LIKE '%-%' THEN to_char(to_date(birthdate,'MM-DD-YYYY'), 'YYYY-MM-DD')
    ELSE NULL 
end;

--chyen doi kieu du lieu tu varchar sang date
ALTER TABLE human_resources
ALTER COLUMN birthdate TYPE date
USING birthdate::date

update human_resources 
set birthdate = CASE 
    WHEN birthdate >= '0001-01-01' AND birthdate < '0010-01-01' THEN (birthdate + INTERVAL '2000 years')::DATE
    WHEN birthdate >= '0010-01-01' AND birthdate < '0100-01-01' THEN (birthdate + INTERVAL '1900 years')::DATE
   
    ELSE birthdate
 END 


select birthdate  from human_resources hr 

-- lam sach gia tri hire_date
UPDATE human_resources 
SET hire_date = CASE 
	WHEN hire_date LIKE '%/%' THEN to_char(to_date(hire_date,'MM/DD/YYYY'), 'YYYY-MM-DD')
	WHEN hire_date LIKE '%-%' THEN to_char(to_date(hire_date,'MM-DD-YYYY'), 'YYYY-MM-DD')
	ELSE NULL 
end

update human_resources 
set hire_date = CASE 
    WHEN hire_date >= '0001-01-01' AND hire_date <= '0023-01-01' THEN (hire_date + INTERVAL '2000 years')::DATE
    WHEN hire_date > '0023-01-01' AND hire_date < '0100-01-01' THEN (hire_date + INTERVAL '1900 years')::DATE
    ELSE hire_date
 END 

 select hire_date  from human_resources hr 
 
 SELECT Max(EXTRACT(YEAR FROM hire_date)) AS min_year FROM human_resources;

 
ALTER TABLE human_resources
ALTER COLUMN hire_date TYPE date
USING hire_date::date

/* lam sach termdate
hàm to_timestamp để chuyển đổi giá trị của cột termdate thành kiểu dữ liệu TIMESTAMP, 
và sử dụng định dạng ngày giờ YYYY-MM-DD HH24:MI:SS UTC. */

UPDATE human_resources
SET termdate = to_timestamp(termdate, 'YYYY-MM-DD HH24:MI:SS UTC')
WHERE termdate IS NOT NULL AND termdate != ''

/*Hàm NULLIF sẽ trả về NULL nếu giá trị của trường termdate là rỗng, giúp tránh lỗi khi chuyển đổi kiểu dữ liệu.*/
ALTER TABLE human_resources
ALTER COLUMN termdate TYPE date
USING NULLIF(termdate,'')::date

--them cot moi Age
ALTER TABLE human_resources ADD COLUMN age integer

--ham age() tinh so luong nam giua 2 ngay, hàm age() trả về một giá trị kiểu interval chứ không phải là một số nguyên, 
--do đó cần sử dụng hàm EXTRACT() để lấy ra giá trị năm từ kết quả của hàm age().

UPDATE human_resources SET age = EXTRACT(year FROM age(birthdate));

select birthdate,age from human_resources hr 

select
	min(age) as youngest,
	max(age) as oldest
from human_resources hr 

-- QUESTIONS

-- 1. What is the gender breakdown of employees in the company?
select gender,count(*) 
from human_resources hr 
where age >= 18 and termdate is null 
group by gender  

select count(age) as age18 from human_resources hr where age < 18
-- 2. What is the race/ethnicity breakdown of employees in the company?

select race,count(*) 
from human_resources hr 
where age >= 18 and termdate is null 
group by race
order by count(*) desc  

-- 3. What is the age distribution of employees in the company?
select
	min(age) as youngest,
	max(age) as oldest
from human_resources hr 
where termdate is null

select case 
	when age >=18 and age <=24 then '18-24'
	when age >=25 and age <=34 then '25-34'
	when age >=35 and age <=44 then '35-44'
	when age >=45 and age <=54 then '45-54'
	when age >=55 and age <=64 then '55-64'
	else '65+'
end as age_group,count(*) from human_resources hr 
where termdate is null
group by age_group 
order by age_group 


-- 4. How many employees work at headquarters versus remote locations?
select "location",count(*)  from human_resources hr where termdate is null
group by "location" 

-- 5. What is the average length of employment for employees who have been terminated?
/*age(termdate, hire_date) trả về khoảng thời gian giữa hai ngày, sau đó sử dụng date_part để lấy ra số ngày.*/

SELECT to_char(round(AVG(EXTRACT(DAY FROM (termdate::timestamp - hire_date::timestamp))), 1)/365.0, 'FM999999999.0') AS avg_length_employment 
FROM human_resources 
WHERE termdate < current_date AND termdate IS NOT NULL;

-- 6. How does the gender distribution vary across departments and job titles?
select department, gender ,count(*)  from human_resources hr 
where termdate is null group by department,gender 
order by department 

-- 7. What is the distribution of job titles across the company?
select jobtitle,count(*)  from human_resources hr 
where termdate is null group by jobtitle order by jobtitle desc 

-- 8. Which department has the highest turnover rate?
-- can so luong nhan vien trong department, so nguoi nghi => ty le nghi = so nguoi nghi /tong nhan vien

select department,
total_employee, 
terminate_employee,
terminate_employee::float/total_employee as terminate_rate
from ( select 
	department,count(*) as total_employee, sum( case
		when termdate is not null and termdate <= current_date then 1 else 0 
	end
	) as terminate_employee
	from human_resources hr
	group by department) as subquery
order by department desc 

-- 9. What is the distribution of employees across locations by city and state?
select location_state ,count(*) from human_resources hr 
where termdate is null
group by location_state
order by count(*) desc  

-- 10. How has the company's employee count changed over time based on hire and term dates?
SELECT 
	EXTRACT(YEAR FROM hire_date) AS year,
	COUNT(*) AS hires,
	SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE THEN 1 ELSE 0 END) AS terminate,
	COUNT(*) - SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE THEN 1 ELSE 0 END) AS net_change,
	ROUND(((COUNT(*) - SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURRENT_DATE THEN 1 ELSE 0 END))::decimal/COUNT(*)) * 100,2) AS net_change_percent
FROM human_resources hr 
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY year ASC;

-- 11. What is the tenure distribution for each department?
select department, to_char(round(AVG(EXTRACT(DAY FROM (termdate::timestamp - hire_date::timestamp))), 1)/365.0, 'FM999999999.0') as avg_tenue
from human_resources hr 
WHERE termdate < current_date AND termdate IS NOT NULL
group by department
