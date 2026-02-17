SELECT title FROM movies;
SELECT director FROM movies;
SELECT title, director FROM movies;
SELECT title, year FROM movies;
SELECT * FROM movies;
/*----------------------------------------------------------------------------*/
SELECT title FROM movies WHERE id = 6;
SELECT title FROM movies WHERE year BETWEEN 2000 AND 2010;
SELECT title FROM movies WHERE year NOT BETWEEN 2000 AND 2010;
SELECT title, year FROM movies ORDER BY year LIMIT 5;
/*----------------------------------------------------------------------------*/
SELECT title FROM movies WHERE title LIKE '%Toy Story%';
SELECT title FROM movies WHERE director LIKE '%John Lasseter%';
SELECT title, director FROM movies WHERE director NOT LIKE '%John Lasseter%';
SELECT title, director FROM movies WHERE title LIKE '%WALL-%';
/*----------------------------------------------------------------------------*/
SELECT DISTINCT director FROM movies ORDER BY director;
SELECT DISTINCT title FROM movies ORDER BY year DESC LIMIT 4;
SELECT title FROM movies ORDER BY title LIMIT 5;
SELECT title FROM movies ORDER BY title LIMIT 5 OFFSET 5;
/*----------------------------------------------------------------------------*/
SELECT * FROM north_american_cities WHERE country LIKE 'CANADA';
SELECT * FROM north_american_cities WHERE country LIKE 'United States' Order by latitude DESC;
SELECT city, longitude FROM north_american_cities WHERE longitude < -87.629798 ORDER BY longitude ASC;
SELECT * FROM north_american_cities WHERE Country LIKE 'Mexico' ORDER BY Population DESC LIMIT 2;
SELECT * FROM north_american_cities WHERE Country LIKE 'United States' ORDER BY Population DESC LIMIT 2 OFFSET 2;