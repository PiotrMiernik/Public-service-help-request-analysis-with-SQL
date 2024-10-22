SELECT 
	ed.source,
	count(ed.priority) 
FROM evanston_data ed 
group by source;