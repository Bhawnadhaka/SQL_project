
drop database swiggydata;
	create database swiggydata;
	use swiggydata;
    drop table swiggy_table;
    CREATE TABLE swiggy_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hotel_name VARCHAR(255),
    rating VARCHAR(255),
    time_minutes VARCHAR(255),
    food_type VARCHAR(255),
    location VARCHAR(255),
    offer_above VARCHAR(255),
    offer_percentage VARCHAR(255)
);

SHOW VARIABLES LIKE 'secure_file_priv';
SHOW VARIABLES LIKE 'local_infile';
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/swiggy_cleaned.csv'
INTO TABLE swiggy_table
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(hotel_name, rating, time_minutes, food_type, location, offer_above, offer_percentage);
select * from swiggy_table;
select
    sum(case when hotel_name='' then 1 else 0 end) as hotel_name,
    sum(case when rating ='' then 1 else 0 end) as rating,
    sum(case when time_minutes='' then 1 else 0 end) as time_minutes,
    sum(case when food_type='' then 1 else 0 end) as food_type ,
    sum(case when location='' then 1 else 0 end) as location,
    sum(case when offer_above='' then 1 else 0 end) as offer_above,
    sum(case when offer_percentage='' then 1 else 0 end) as offer_percentage
 from swiggy_table;

select column_name from information_schema.columns where table_name = 'swiggy_table';

-- sum(case when hotel_name='' then 1 else 0 end) as hotel_name



DELIMITER $$

CREATE PROCEDURE count_blank_rows()
BEGIN
    SELECT GROUP_CONCAT(
        CONCAT('SUM(CASE WHEN `', column_name, '` = ''some_value'' THEN 1 ELSE 0 END) AS `', column_name, '`')
        SEPARATOR ', '
    ) INTO @sql
    FROM information_schema.columns 
    WHERE table_name = 'swiggy_table' AND table_schema = DATABASE();

    SET @sql = CONCAT('SELECT ', @sql, ' FROM swiggy_table');
    SELECT @sql; 

    PREPARE smt FROM @sql;
    EXECUTE smt;
    DEALLOCATE PREPARE smt;
END$$

DELIMITER ;
call count_blank_rows();

select *from swiggy_table;

-- shifting value of rating to time minute 
create table clean as
select * from swiggy_table where rating like '%mins%';
select * from clean;

DELIMITER $$

CREATE DEFINER=`root`@`localhost` FUNCTION `f_name`(a VARCHAR(100)) RETURNS VARCHAR(100) CHARSET utf8mb4
DETERMINISTIC
BEGIN
    DECLARE l INT;
    DECLARE s VARCHAR(100);
    
    SET l = LOCATE(' ', a);
    SET s = IF(l > 0, LEFT(a, l - 1), a);
    
    RETURN s;
END $$

DELIMITER ;




drop table clean;
CREATE TABLE cleaned AS 
SELECT *, f_name(rating) AS ratings FROM clean;
set sql_safe_update=0;

SHOW VARIABLES LIKE 'sql_safe_updates';

update swiggy_table as s
inner join cleaned as c 
on s.hotel_name= c.hotel_name
set s.time_minutes=c.ratings; 
select *from swiggy_table;

 drop table cleaned;
 drop table clean;
 
 
 
 DELIMITER $$

CREATE FUNCTION l_name(a VARCHAR(100)) 
RETURNS VARCHAR(100) 
DETERMINISTIC
BEGIN
    DECLARE pos INT;
    DECLARE result VARCHAR(100);

    -- Find the position of the first space
    SET pos = LOCATE(' ', a);

    -- If no space is found, return an empty string; otherwise, return the last name
    SET result = IF(pos = 0, '', SUBSTRING(a, pos + 1, LENGTH(a)));

    RETURN result;
END $$

DELIMITER ;

 create table clean as 
 select * from swiggy_table where time_minutes like'%-%';
 select * from clean;
 create table cleaned as 
 select *,f_name(time_minutes)as f1, l_name(time_minutes) as f2 from clean;
 select * from cleaned;


update swiggy_table as s
inner join cleaned as c 
on s.hotel_name= c.hotel_name
set s.time_minutes=((c.f1+c.f2)/2);

select * from swiggy_table;

-------- time minute column is cleaned-----


----- lets clean rating column-----

select location, avg(rating) as average 
from swiggy_table
where rating not like '%mins%'
group by location;

select* from  swiggy_table as t
join (
      select location, round(avg(rating),2) as avg_rating
      from swiggy_table
      where rating not like '%mins%'
      group by location
) as avg_table on t.location=avg_table.location;

update swiggy_table as t
join (
      select location, round(avg(rating),2) as avg_rating
      from swiggy_table
      where rating not like '%mins%'
      group by location
) as avg_table on t.location=avg_table.location
set t.rating=avg_table.avg_rating
where t.rating like'%mins%';

select* from swiggy_table where rating like '%mins%';

set @average=(select round(avg(rating),2) from swiggy_table where rating not like'%mins%');
select@average; 

update swiggy_table
set rating =@average
where rating like '%mins%';  
select * from swiggy_table;

-- our rating columns is also cleaned---

select distinct(location) from swiggy_table where location like '%kandivali%';

update swiggy_table
set location='Kandivali East'
where location like '%East%';

update swiggy_table
set location='Kandivali West'
where location like '%West%';

update swiggy_table
set location='Kandivali East'
where location like '%E%';

update swiggy_table
set location='Kandivali Wast'
where location like '%W%';
    

-- location column is also cleaned---

select * from swiggy_table; 

-- cleaning offer_percentage column--

update swiggy_table  
set offer_percentage=0
where offer_above ='not_available';


-- percentage column also cleaned-- 

-- cleaning food type which is denormalized-- 

select substring_index( substring_index( 'American, Mexican, Fast Food, Snacks, Beverages',',',4),',',-1);

select char_length('American, Mexican, Fast Food, Snacks, Beverages');
SELECT CHAR_LENGTH(REPLACE('American, Mexican, Fast Food, Snacks, Beverages', ',', ''));

select distinct food from
(
select *, substring_index(substring_index(food_type,',',numbers.n),',',-1) as'food'
from swiggy_table 
  join
  (
    select 1+a.N+ b.N*10  as n from 
    (
       (
       select 0 as N  union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 
	   union all select 7 union all select 8 union all select 9) as a
       cross join 
      (
      select 0 as N  union all select 1 union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 
      union all select 7 union all select 8 union all select 9) as b 
    )
  ) as numbers
  on  char_length(food_type)-char(replace(food_type ,',', ' ')) >= numbers.n-1
)a;

select * from swiggy_table;
 
 


