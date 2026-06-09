SELECT colour FROM my_brick_collection
UNION
SELECT colour FROM your_brick_collection
ORDER BY colour;

SELECT shape FROM my_brick_collection
INTERSECT
SELECT shape FROM your_brick_collection
ORDER BY shape;
/*----------------------------------------------------------------------------*/
SELECT shape FROM my_brick_collection
MINUS
SELECT shape FROM your_brick_collection;

SELECT colour FROM my_brick_collection
UNION ALL
SELECT colour FROM your_brick_collection
ORDER BY colour;