-- First let's check what's in the database and check data quality.
-- Duplicates and missing data were checked before.

select count(*)
from evanston_data ed;

-- There is 36431 rows (requests) in the dataset

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
Another column with main categories should be created. The categories in this new variable ought to align with the key urban concerns of residents, including: 
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

-- help requests were completed between January 4, 2016 and September 20, 2018

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
Now that we have examined the table's contents, assessed data quality, and created new variables, 
we can turn our attention to the tickets and their timely resolution.
 */






	

