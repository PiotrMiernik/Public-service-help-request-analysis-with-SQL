-- First let's check what's in the database?

select count(*)
from evanston_data ed;

-- There is 36431 rows (tickets) in the dataset

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
New variable looks like tis now: 

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
There is 149 request categories in the dataset. Only 8 of them have more then 1000 requests and 88 of them have less then 100 requests.
Another column with main categories should be created. The categories in this new variable ought to align with the key urban concerns of residents, including: 
education, healthcare, green spaces, animals, waste management, traffic congestion, public safety e.t.c 
*/


/*

*/


/*

*/


/*

*/


/*

*/