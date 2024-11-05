-- First let's investigate what's in the dataset and check data quality.

select count(*)
from evanston_data ed;

-- There is 36431 rows (requests) in the dataset

select
	count(*)
from evanston_data ed 
group by ed.priority, ed."source", ed.category, ed.date_created, ed.date_completed 
having count(*) > 1;

-- There is no duplicates in the dataset

select *
from evanston_data ed 
where ed.priority is null or ed."source" is null or ed.category is null or ed.date_created is null or ed.date_completed is null or ed.street is null 
or ed.house_num is null or ed.zip is null or ed.description is null;

-- There is no missing values in the table. But in some columns a lot of "NA" (No answer?) occures. Let's check how many?

select 
	count(case when ed.street like 'NA' then 1 end) as na_in_street,
	count(case when ed.house_num  like 'NA' then 1 end) as na_in_house_num,
	count(case when ed.zip like 'NA' then 1 end) as na_in_zip,
	count(case when ed.description like 'NA' then 1 end) as na_in_description
from evanston_data ed;

/* There are: 
1699 'NA' cases in street column
4227 'NA' cases in house_num column
5528 'NA' cases in zip column
10977 'NA' cases in description column
*/

select
	ed.priority,
	count(*)
from evanston_data ed 
group by ed.priority 
order by count(*) desc;

/* 
Frequency distribution of priority categories:
NONE	30081
MEDIUM	5745
LOW		517
HIGH	88
About 83 % of requests do not have a priority assigned. Data quality personnel should investigate why the percentage of 'NONE' priorities is so high
*/

select
	ed."source" ,
	count(*)
from evanston_data ed 
group by ed."source"  
order by count(*) desc;

/*
Frequency distribution of source categories:
gov.publicstuff.com	30985
Iframe				3670
iOS					1199
Android				444
Iframe (Staff)		83
iOS (Staff)			40
Android (Staff)		9
Legacy API 2.1		1
About 84 % of requests were submitted via 'gov.publicstaff.com' system. 
For analytical purpose four least frequent categories will be recoded into one categry 'other' (in new column)   
*/

alter table evanston_data 
add column source_cat varchar(50);

update evanston_data 
set source_cat =
	case 
		when source in ('Iframe (Staff)', 'iOS (Staff)', 'Android (Staff)', 'Legacy API 2.1') then 'other'
		else source
	end;

select
	ed.source_cat,
	count(*)
from evanston_data ed 
group by ed.source_cat  
order by count(*) desc;

/*
New variable looks like this now: 
gov.publicstuff.com	30985
Iframe				3670
iOS					1199
Android				444
other				133
*/

select
	ed.category,
	count(*)
from evanston_data ed 
group by ed.category  
order by count(*) desc;

/*
There are 149 request categories in the dataset. Only 8 of them have more then 1000 requests and 88 of them have less then 100 requests.
Additional column with main categories should be created. The categories in this new variable should align with the key urban concerns of residents, including: 
urban greenery, animals, waste management, transportation, law&order and utilities.
*/

alter table evanston_data 
add column main_category varchar(50);	
	
UPDATE evanston_data  
SET main_category = 
    CASE 
        WHEN (SELECT COUNT(*) FROM evanston_data AS sub WHERE sub.category = evanston_data.category) < 10 THEN 'rare'
        -- Urban Greenery
        WHEN lower(category) LIKE '%tree%' 
          OR lower(category) LIKE '%grass%' 
          OR lower(category) LIKE '%weed%' 
          OR lower(category) LIKE '%leave%' 
          OR lower(category) LIKE '%branch%' 
          OR lower(category) LIKE '%forestry%' 
        THEN 'urban greenery'
        -- Animals
        WHEN lower(category) LIKE '%rat%' 
          OR lower(category) LIKE '%cat%' 
          OR lower(category) LIKE '%dog%' 
          OR lower(category) LIKE '%bat%' 
          OR lower(category) LIKE '%raccoon%' 
          OR lower(category) LIKE '%animal%' 
        THEN 'animals'
        -- Waste Management
        when lower(category) LIKE '%trash%' 
          or lower(category) LIKE '%recycling%' 
          OR lower(category) LIKE '%waste%' 
          OR lower(category) LIKE '%garbage%' 
        THEN 'waste management'
        -- Transportation
        WHEN lower(category) like '%parking meter%'
          or lower(category) like '%child seat%'
          or lower(category) like '%traffic%'
          or lower(category) like '%car%'
          or lower(category) like '%bus%'
          or lower(category) like '%street signs%'
       then 'transportation'
       -- Law&Order
       WHEN lower(category) like 'graffiti'
         or lower(category) like '%ticket%'
       then 'law&order'
       -- Utilities
       WHEN lower(category) like '%street lights%' 
	     or lower(category) like '%sidewalk%' 
	     or lower(category) like '%pot hole%' 
	     or lower(category) like '%water%'  
	     or lower(category) like '%electricity%' 
	     or lower(category) like '%power%' 
	     or lower(category) like '%pay station%'
       then 'utilities'      
       else 'other' 
    end;
       
select
	ed.main_category, 
	count(*)
from evanston_data ed 
group by ed.main_category  
order by count(*) desc;

/*
After recoding category variable into main_category we have 8 categories with following frequencies:
waste management	7845
transportation		7689
other				6808
urban greenery		5127
utilities			5105
animals				3038
law&order			638
rare				181 
 */

select
	min(ed.date_created) as min_date,
	max(ed.date_created) as max_date
from evanston_data ed; 

-- The data in the table includes help requests from the period of January 1, 2016 to June 30, 2018 (2.5 years)

select
	min(ed.date_completed) as min_date,
	max(ed.date_completed) as max_date
from evanston_data ed;

-- Help requests were completed between January 4, 2016 and September 20, 2018
-- Let's check date columns consistency

select
	ed.date_completed,
	ed.date_created
from evanston_data ed
where ed.date_completed <= ed.date_created;

-- I found 32 records in the table where the ticket completion date is earlier or equal to the creation date. These rows will be deleted from the table

delete from evanston_data 
where date_completed <= date_created;

-- Now we can check the quality of adress data

select ed.street 
from evanston_data ed 
where ed.street ~* '[0-9#/%]';

SELECT ed.house_num  
FROM evanston_data ed 
WHERE ed.house_num ~* '[A-Z#/%]';

SELECT ed.zip  
FROM evanston_data ed 
WHERE ed.zip ~* '[A-Z#/%]';

-- Let's create additional column with full cleaned adress

alter table evanston_data 
add column full_address varchar(64);

update evanston_data
set full_address = 
    CONCAT(trim(zip), ' ', 
           REGEXP_REPLACE(trim(street), '^[0-9#%./]+|[^a-zA-Z0-9 ]+$', ''),
           ' ', trim(house_num));
          
/* 
 Last but not least - description column. To check the quality of help request descriptions, 
 I checked the length of the description and the relationship between the description and the category of the ticket.
 */
          
select 
	min(length(ed.description))	,
	max(length(ed.description)),
	avg(length(ed.description))
from evanston_data ed; 
 
/* 
 Some of the descriptions are very long (max length: 5000 characters, on average: 97,6 characters),
 so I decided to create another column with short version of description (about 100 characcters).
 */

alter table evanston_data 
add column short_description varchar(120);

update evanston_data 
set short_description = 
	case 
		when length(description) > 100 then REGEXP_REPLACE(LEFT(description, 100) || ' ', '\\s+', '', 1) || '...'
		else description 
	end;


select
	ed.main_category,
	count(*)
from evanston_data ed 
where (ed.description ilike '%garbage%' or ed.description ilike '%trash%')
	  and ed.main_category not like 'waste management' 
group by ed.main_category 
order by count(*) desc;

/*
533 requests containing the words 'trash' or 'garbage' were not categorized as 'waste management'. 
The main category classification system requires improvement.
other			358
animals			105
urban greenery	26
rare			19
law&order		15
utilities		10 
Total			533
*/

/* 
Now that we have examined the table's contents, assessed data quality and created new variables, 
we can turn our attention into the time dimention of tickets resolution.
Notice that for 2018 we have data for only first 6 months.
*/

-- First let's create new column with ticket resolution time (as TRT_KPI)

alter table evanston_data 
add column trt_kpi interval;

update evanston_data 
set trt_kpi = date_completed - date_created;

-- Next let's calculate basic statistics of resolution time and check how it depends on ticket category, priority and source category?

select
	min(ed.trt_kpi),
	max(ed.trt_kpi),
	avg(ed.trt_kpi),
	percentile_cont(0.5) within group (order by ed.trt_kpi) as median_trt_kpi
from evanston_data ed; 

/*
Descriptive statistics for trt_kpi:
min. time - 00:00:07
max. time - 944 days 20:09:03
avg. time - 7 days 12:32:51.88
median time - 1 day 19:29:10
The mean is significantly greater than the median, indicating a right-skewed distribution for this variable. 
Therefore, I will use the median to compare ticket completion times 
I'll calculate trimmed mean (average of the middle 90% of cases) as well
 */

with percentiles as (
    select 
        percentile_cont(0.05) within group (order by ed.trt_kpi) as p5,
        percentile_cont(0.95) within group (order by ed.trt_kpi) as p95
    from evanston_data ed
)
select AVG(trt_kpi) AS avg_trt_kpi
from evanston_data ed, percentiles
where ed.trt_kpi between percentiles.p5 and percentiles.p95;

-- Average ticket resolution time of the middle 90% cases equals: 3 days 13:01:25.02


select
	ed.main_category,
	min(ed.trt_kpi),
	max(ed.trt_kpi),
	percentile_cont(0.5) within group (order by ed.trt_kpi) as median_trt_kpi
from evanston_data ed
group by ed.main_category  
order by median_trt_kpi desc; 

/*
Descriptive statistics for ticket resolution time group by main category (min., max., median):
waste management	00:01:09	285 days 20:42:10	3 days 20:55:45
rare				00:01:04	111 days 05:54:36	2 days 22:34:09.5
urban greenery		00:01:01	381 days 17:08:10	2 days 18:04:12.5
other				00:00:32	800 days 06:16:59	2 days 05:33:53.5
animals				00:00:26	411 days 04:40:06	2 days 01:15:31
transportation		00:00:07	888 days 03:18:12	23:45:00.5
law&order			00:01:09	32 days 22:16:23	21:30:01.5
utilities			00:00:38	944 days 20:09:03	18:31:11.5
 */

select
	ed.priority,
	min(ed.trt_kpi),
	max(ed.trt_kpi),
	percentile_cont(0.5) within group (order by ed.trt_kpi) as median_trt_kpi
from evanston_data ed
group by ed.priority
order by median_trt_kpi desc; 

/*
Descriptive statistics for ticket resolution time group by priority(min., max., median):
LOW		00:03:10	285 days 20:42:10	3 days 02:40:06
MEDIUM	00:00:42	402 days 22:20:27	2 days 20:10:28
NONE	00:00:07	944 days 20:09:03	1 day 13:42:38
HIGH	00:16:21	734 days 23:18:20	20:28:38
 */


select
	ed.source_cat,
	min(ed.trt_kpi),
	max(ed.trt_kpi),
	percentile_cont(0.5) within group (order by ed.trt_kpi) as median_trt_kpi
from evanston_data ed
group by ed.source_cat 
order by median_trt_kpi desc;

/*
Descriptive statistics for ticket resolution time group by source category(min., max., median):
Android	00:02:09	271 days 04:09:20	2 days 20:24:05.
Iframe	00:00:42	402 days 22:20:27	2 days 16:05:21
iOS		00:03:34	264 days 21:38:24	2 days 12:19:36
other	00:41:24	96 days 21:22:13	2 days 02:13:55
gov.publicstuff.com	00:00:07	944 days 20:09:03	1 day 15:59:05.5
 */

-- Based on above results we know which categories of tickets take most time to accomplish.

/* 
Next I'll try to identify any trends or seasonality (daily, weekly or monthly) 
in ticket volumes and average resolution time.
 */

with percentiles as (
    select 
        percentile_cont(0.01) within group (order by ed.trt_kpi) as p1,
        percentile_cont(0.99) within group (order by ed.trt_kpi) as p99
    from evanston_data ed
)
select 
	date_part('year', ed.date_created),
	percentile_cont(0.50) within group (order by trt_kpi) as median_trt_kpi,
	avg(ed.trt_kpi) as avg_trt_kpi,
	count(*) as num_of_tickets
from evanston_data ed, percentiles
where ed.trt_kpi between percentiles.p1 and percentiles.p99
group by date_part('year', ed.date_created)
order by date_part('year', ed.date_created);

/*
I cut off outliers (min./max. 1 % of trt_kpi) and the results are:
year	median			98% mean				num_of_tickets
2016	2 days 00:32:21	5 days 31:30:02.858766	13290
2017	1 day 06:33:01	4 days 29:12:26.5871	15907
2018	1 day 19:01:11	5 days 23:11:36.927855	6487 
 */

select
	to_char(ed.date_created, 'Month'),
	percentile_cont(0.50) within group (order by ed.trt_kpi) as median_trt_kpi,
	count(*) as num_of_tickets
from evanston_data ed 
group by to_char(ed.date_created, 'Month') 
order by median_trt_kpi desc;

/*
Median trt_kpi and # of tickets group by month of a year:
month	   	median (descending) num_of_tickets
April    	1 day 23:35:42		3439
March    	1 day 23:35:20		3091
June     	1 day 21:59:59		4737
July     	1 day 20:57:36		3060
November 	1 day 19:46:33		2282
May      	1 day 18:51:21		4078
January  	1 day 18:05:48		2838
September	1 day 17:01:25		2753
October  	1 day 15:46:19		2394
December 	1 day 12:04:33		1999
August   	1 day 11:20:43		3098
February 	1 day 08:29:52		2630
 */

select
	date_part('year', ed.date_created) as year, 
	date_part('month', ed.date_created) as month,
	percentile_cont(0.50) within group (order by ed.trt_kpi) as median_trt_kpi,
	count(*) as num_of_tickets
from evanston_data ed 
group by cube(date_part('month', ed.date_created), date_part('year', ed.date_created)) 
order by date_part('year', ed.date_created), date_part('month', ed.date_created);

/*
I grouped median trt_kpi and number of tickets by year and month (cross tabulation).
But to spot eventual trends, it would be better to create line plot based on this agregated data points.
year 	month	median				num_of_tickets
2016.0	1.0		2 days 02:42:26		728
2016.0	2.0		1 day 21:15:17		892
2016.0	3.0		3 days 06:54:29		1102
2016.0	4.0		2 days 23:29:52		1119
2016.0	5.0		2 days 00:53:52		1223
2016.0	6.0		2 days 03:10:34		1319
2016.0	7.0		2 days 02:52:38		1287
2016.0	8.0		1 day 14:41:15		1443
2016.0	9.0		1 day 21:55:10		1420
2016.0	10.0	1 day 22:50:45		1110
2016.0	11.0	1 day 23:06:21		1062
2016.0	12.0	1 day 08:14:03		911
2016.0			2 days 00:45:23		13616
2017.0	1.0		1 day 06:37:35		1082
2017.0	2.0		1 day 06:50:24		883
2017.0	3.0		1 day 04:25:27		1069
2017.0	4.0		1 day 07:20:09		1266
2017.0	5.0		1 day 04:56:33		1450
2017.0	6.0		1 day 15:28:23		2083
2017.0	7.0		1 day 15:34:17		1773
2017.0	8.0		1 day 07:43:42		1655
2017.0	9.0		1 day 04:29:38		1333
2017.0	10.0	1 day 05:00:32		1284
2017.0	11.0	1 day 06:39:12		1220
2017.0	12.0	1 day 12:37:32		1088
2017.0			1 day 06:38:25		16186
2018.0	1.0		1 day 04:56:59		1028
2018.0	2.0		1 day 02:44:54		855
2018.0	3.0		1 day 21:13:05		920
2018.0	4.0		1 day 21:56:52		1054
2018.0	5.0		1 day 17:51:29		1405
2018.0	6.0		1 day 23:34:03		1335
2018.0			1 day 18:13:42		6597
 */

select
	to_char(ed.date_created, 'day') as day_of_week,
	percentile_cont(0.50) within group (order by ed.trt_kpi) as median_trt_kpi,
	count(*) as num_of_tickets
from evanston_data ed 
group by to_char(ed.date_created, 'day') 
order by median_trt_kpi desc;
 
/*
Median trt_kpi and number of tickets group by day of the week:
DOW	   		median (descending)	num_of_tickets
friday   	3 days 02:53:49		6107
saturday 	2 days 07:48:46		2022
sunday   	2 days 01:36:16		635
monday   	1 day 04:05:28		7305
tuesday  	1 day 03:11:46		6995
thursday 	1 day 02:25:10		6536
wednesday	1 day 02:20:56		6799
 */

select
	to_char(ed.date_created, 'HH24') as day_of_week,
	percentile_cont(0.50) within group (order by ed.trt_kpi) as median_trt_kpi,
	count(*) as num_of_tickets
from evanston_data ed 
group by to_char(ed.date_created, 'HH24') 
order by to_char(ed.date_created, 'HH24');

/*
Median trt_kpi and number of tickets group by hour of creation:
HH24	median
00		2 days 10:38:29		169
01		1 day 15:44:37		88
02		2 days 11:04:17		47
03		2 days 10:47:11		29
04		2 days 04:03:55		19
05		1 day 03:17:09		9
06		1 day 10:16:05		25
07		1 day 04:48:28		144
08		1 day 03:24:10		787
09		1 day 04:45:06		2015
10		1 day 05:45:20		3164
11		1 day 21:20:55		3959
12		1 day 20:01:54		3943
13		1 day 18:19:23		3724
14		1 day 19:15:30		3360
15		1 day 22:51:18		3206
16		1 day 21:59:59		3117
17		1 day 23:13:33		2913
18		1 day 22:27:46		2353
19		1 day 19:12:46		1467
20		1 day 17:15:38		992
21		2 days 10:20:28		369
22		1 day 28:03:30		268
23		1 day 18:20:42		232
 */

/* Last part of this project will be analysis of help requests (resolution time and volume) by city area. 
I'll try to answer the following questions:
- what is the number of tickets originating from different areas of the city and which of them have the highest and lowest ticket volumes, 
- what are the dominant types and priorities of tickets in different city areas 
- which areas have the longest and shortest average ticket resolution times. 
- what is the dominant sources of tickets used by residents in each area of the city.
*/

-- First I'll check the number of distinct city zip codes

select
	distinct ed.zip,
	count(ed.zip)
from evanston_data ed 
group by distinct ed.zip
order by count(ed.zip) desc;

-- There are 122 distinct zip codes. But most of them occurs very rarly in the table (less then 100 times).
-- So zip's with less then 10 cases will be grouped into 'other' category.

alter table evanston_data 
add column zip_new varchar(20);

with zip_counts as (
	select 
		zip,
		count(*) as zip_count
	from evanston_data 
	group by zip
)
update evanston_data as ed
set zip_new = 
    case 
        when zip_counts.zip_count < 100 then 'other'
        else ed.zip
    end
from zip_counts
where ed.zip = zip_counts.zip;

select
	ed.zip_new,
	count(*) as num_of_tickets
from evanston_data ed 
group by ed.zip_new
order by num_of_tickets desc;

/*
Number of tickets for recoded zip areas:
zip		Num_of_tickets
60201	19050
60202	11162
NA		5505
other	427
60208	255
 */

select
	ed.zip_new, 
	max(ed.priority) as top_priority,
	max(ed.main_category) as top_category
from evanston_data ed
where ed.priority not ilike 'NONE'
group by ed.zip_new;

/*
Top priority (without NONE category) and top category for recoded zip areas:
zip		top_priority	top_category
60201	MEDIUM			waste management
NA		MEDIUM			waste management
other	MEDIUM			utilities
60208	MEDIUM			waste management
60202	MEDIUM			waste management 
 */

select
	ed.zip_new,
	percentile_cont(0.5) within group (order by ed.trt_kpi) as median_trt_kpi 
from evanston_data ed 
group by ed.zip_new
order by median_trt_kpi desc;

/*
Median trt_kpi (tisket resolution time) for receded zip areas:
zip		median_trt_kpi (descending)
60202		2 days 01:14:07
60208		1 day 23:05:24
NA			1 day 17:38:29
60201		1 day 13:33:03
other		1 day 02:30:30
 */

select
	ed.zip_new,
	max(ed.source_cat) as top_source
from evanston_data ed 
group by ed.zip_new
order by top_source desc;

/*
Top source for recoded zip areas:
zip		top_source
60201	other
NA		other
60202	other
other	iOS
60208	iOS
 */














