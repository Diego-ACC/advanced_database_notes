SELECT movies.title, Boxoffice.Domestic_sales, Boxoffice.International_sales FROM movies INNER JOIN Boxoffice ON movies.id = Boxoffice.movie_id;
SELECT movies.title, Boxoffice.International_sales, Boxoffice.Domestic_sales FROM movies INNER JOIN Boxoffice ON movies.id = Boxoffice.movie_id WHERE Boxoffice.International_sales > Boxoffice.Domestic_sales;
SELECT movies.title FROM movies INNER JOIN Boxoffice ON movies.id = Boxoffice.movie_id WHERE Boxoffice.movie_id ORDER BY rating DESC;
/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT DISTINCT building FROM employees;
SELECT Building_name, Capacity FROM Buildings;
SELECT DISTINCT building_name, role FROM buildings LEFT JOIN employees ON building_name = building;
/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT pages.page_id FROM pages LEFT JOIN page_likes ON pages.page_id = page_likes.page_id WHERE page_likes.page_id IS NULL;