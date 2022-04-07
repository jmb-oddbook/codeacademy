USE Day9;

-- Download and import the file
-- Create table for data
CREATE TABLE downloads (
	download_date DATE,
    time TIME,
    size INT NOT NULL,
    r_version VARCHAR(255) NOT NULL,
    r_arch VARCHAR(255) NOT NULL,
    r_os VARCHAR(255) NOT NULL,
    package VARCHAR(100) NOT NULL,
    version VARCHAR(100) NOT NULL,
    country VARCHAR(60) NOT NULL,
    ip_id INT NOT NULL
);


/*LOAD DATA INFILE '/var/lib/mysql-files/cran_logs_2015_01_01.csv' 
INTO TABLE downloads 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' STARTING BY ''
IGNORE 1 ROWS; -- do not import the heading*/

LOAD DATA INFILE "/var/lib/mysql-files/cran_logs_2015_01_01.csv"
INTO TABLE downloads
COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES STARTING BY '"'
IGNORE 1 LINES
(@download_date,@time,size,r_version,r_arch,r_os,package,version,country,@ip_id)
SET download_date=replace(@download_date,"\"",""),
ip_id=replace(@ip_id,"\"",""),
time=@time
;

SELECT * FROM downloads;

-- 9.1 Give the package name and how many times they're downloaded. Order by the 2nd column descently.
SELECT package, COUNT(package) AS countp FROM downloads GROUP BY package ORDER BY 2 DESC;
SELECT package, COUNT(package) AS countp FROM downloads GROUP BY package ORDER BY countp DESC;

-- 9.2 Give the package ranking (based on how many times it was downloaded) during 9AM to 11AM
SELECT package, COUNT(package) AS pkgcount FROM downloads WHERE time BETWEEN "09:00:00" AND "10:59:59" GROUP BY package ORDER BY pkgcount DESC;

-- 9.3 How many recordings are from China ("CN") or Japan("JP") or Singapore ("SG")?
SELECT country, COUNT(package) AS pkgcount FROM downloads WHERE country IN ('CN', 'JP', 'SG') GROUP BY country;

-- 9.4 Print the countries whose downloads are more than the downloads from China ("CN")
SELECT country, COUNT(package) AS pkgcount FROM downloads GROUP BY country HAVING pkgcount > (
	SELECT COUNT(package) FROM downloads WHERE country = 'CN'
);
/* The following will give 1111-Invalid use of group function error
SELECT country, COUNT(package) AS pkgcount FROM downloads WHERE pkgcount > (
	SELECT COUNT(package) FROM downloads WHERE country = 'CN'
);*/

-- 9.5 Print the average length of the package name of all the UNIQUE packages
SELECT AVG(LENGTH(package)) AS AvgLenPacketName FROM (SELECT DISTINCT package FROM downloads) D;
-- 'D' required b/c every derived table must have own alias

-- !!! 9.6 Get the package whose download count ranks 2nd (print package name and its download count).
SELECT package, COUNT(package) AS pkgcount FROM downloads GROUP BY package ORDER BY pkgcount DESC LIMIT 1 OFFSET 1;

-- 9.7 Print the name of the package whose download count is bigger than 1000.
SELECT package FROM downloads GROUP BY package HAVING COUNT(package) > 1000;

-- 9.8 The field "r_os" is the operating system of the users. Here we would like to know what main system we have (ignore version number), the relevant counts, and the proportion (in percentage).

-- returns the different os
SELECT regexp_replace(r_os, '[.0-9]', '') AS opsys FROM downloads GROUP BY opsys;

-- returns os, count, and proportion but does NOT ignore version number
SELECT r_os, COUNT(r_os) AS numos, ROUND((COUNT(r_os) * 100.0 / (SELECT COUNT(r_os) FROM downloads)),2) AS percent
FROM downloads GROUP BY r_os ORDER BY numos DESC;

-- want to return the different os without version number, count, and percentage
WITH opsys AS (
	SELECT regexp_replace(r_os, '[.0-9]', '') AS r_os FROM downloads GROUP BY r_os
)
SELECT r_os, COUNT(r_os) FROM opsys GROUP BY r_os; -- will only return 1 for each os

-- select and count the os where the name of the os contains an element returned by the regexp and group by that element
SELECT r_os, COUNT(r_os) AS numos, ROUND((COUNT(r_os) * 100.0 / (SELECT COUNT(r_os) FROM downloads)),2) AS percent
FROM downloads 
WHERE r_os LIKE (
	SELECT regexp_replace(r_os, '[.0-9]', '') AS opsys FROM downloads GROUP BY opsys
) GROUP BY r_os ORDER BY numos DESC;
