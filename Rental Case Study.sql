-- What are the top two categories of movies for each user ?
-- Creating temporary table that maps  from rental table to category table
DROP TABLE IF EXISTS complete_joint_dataset;
CREATE TEMP TABLE complete_joint_dataset AS
SELECT
  rental.customer_id,
  inventory.film_id,
  film.title,
  category.name AS category_name,
  rental.rental_date
FROM dvd_rentals.rental
INNER JOIN dvd_rentals.inventory
  ON rental.inventory_id = inventory.inventory_id
INNER JOIN dvd_rentals.film
  ON inventory.film_id = film.film_id
INNER JOIN dvd_rentals.film_category
  ON film.film_id = film_category.film_id
INNER JOIN dvd_rentals.category
  ON film_category.category_id = category.category_id;
-- Creating Table with category count and last rental information by customer and category 
DROP TABLE IF EXISTS category_count;
CREATE TEMP TABLE category_count AS
SELECT
  customer_id,
  category_name,
  COUNT(category_name) AS category_counts,
  MAX(rental_date) AS last_rented
FROM complete_joint_dataset
GROUP BY 
  customer_id, category_name;
-- Creating a table for total rentals by customer_id
DROP TABLE IF EXISTS total_count;
CREATE TEMP TABLE total_count AS
SELECT
  customer_id,
  SUM(category_counts) AS num_rentals
FROM category_count
GROUP BY customer_id;
-- Creating category rank table using dense_rank window function
DROP TABLE IF EXISTS rank_table;
CREATE TEMP TABLE rank_table AS
SELECT 
  customer_id,
  category_name,
  DENSE_RANK() OVER(
  PARTITION BY 
    customer_id
  ORDER BY
    category_counts DESC,
    last_rented DESC,
    category_name
  ) AS category_rank
  FROM category_count;
-- Selecting the top two ranked categories from each customer
SELECT 
  * 
FROM 
  rank_table
WHERE 
  category_rank <= 2;
