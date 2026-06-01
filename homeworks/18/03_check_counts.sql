USE world;

SELECT 'city' AS t_name, COUNT(*) AS cnt
FROM city
UNION ALL
SELECT 'city (RUS)', COUNT(*)
FROM city
WHERE countrycode = 'RUS'
UNION ALL
SELECT 'country', COUNT(*)
FROM country
UNION ALL
SELECT 'countrylanguage', COUNT(*)
FROM countrylanguage;
