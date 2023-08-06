CREATE TABLE cache__products_average_price (
	id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
	product_id INT,
	price DECIMAL(15, 2),

	UNIQUE(product_id)
);

INSERT INTO cache__products_average_price
	(product_id, price)
SELECT product_id, price
FROM products_average_price;

CREATE TABLE cache__products_last_purchased (
	id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
	product_id INT,
	amount DECIMAL(15, 2),
	best_before_date DATE,
	purchased_date DATE,
	price DECIMAL(15, 2),
	location_id INT,
	shopping_location_id INT,

	UNIQUE(product_id)
);

INSERT INTO cache__products_last_purchased
	(product_id, amount, best_before_date, purchased_date, price, location_id, shopping_location_id)
SELECT product_id, amount, best_before_date, purchased_date, price, location_id, shopping_location_id
FROM products_last_purchased;

CREATE TRIGGER stock_log_INS AFTER INSERT ON stock_log
BEGIN
	-- Update products_average_price cache
	INSERT OR REPLACE INTO cache__products_average_price
		(product_id, price)
	SELECT product_id, price
	FROM products_average_price
	WHERE product_id = NEW.product_id;

	-- Update products_last_purchased cache
	INSERT OR REPLACE INTO cache__products_last_purchased
		(product_id, amount, best_before_date, purchased_date, price, location_id, shopping_location_id)
	SELECT product_id, amount, best_before_date, purchased_date, price, location_id, shopping_location_id
	FROM products_last_purchased
	WHERE product_id = NEW.product_id;
END;

CREATE TRIGGER stock_log_UPD AFTER UPDATE ON stock_log
BEGIN
	-- Update products_average_price cache
	INSERT OR REPLACE INTO cache__products_average_price
		(product_id, price)
	SELECT product_id, price
	FROM products_average_price
	WHERE product_id = NEW.product_id;

	-- Update products_last_purchased cache
	INSERT OR REPLACE INTO cache__products_last_purchased
		(product_id, amount, best_before_date, purchased_date, price, location_id, shopping_location_id)
	SELECT product_id, amount, best_before_date, purchased_date, price, location_id, shopping_location_id
	FROM products_last_purchased
	WHERE product_id = NEW.product_id;
END;

CREATE TRIGGER stock_log_DEL AFTER DELETE ON stock_log
BEGIN
	-- Update products_average_price cache
	DELETE FROM cache__products_average_price
	WHERE product_id = OLD.id;

	-- Update products_last_purchased cache
	DELETE FROM cache__products_last_purchased
	WHERE product_id = OLD.id;
END;

DROP VIEW uihelper_stock_current_overview;
CREATE VIEW uihelper_stock_current_overview
AS
SELECT
	p.id,
	sc.amount_opened AS amount_opened,
	p.tare_weight AS tare_weight,
	p.enable_tare_weight_handling AS enable_tare_weight_handling,
	sc.amount AS amount,
	sc.value as value,
	sc.product_id AS product_id,
	sc.best_before_date AS best_before_date,
	EXISTS(SELECT id FROM stock_missing_products WHERE id = sc.product_id) AS product_missing,
	p.name AS product_name,
	pg.name AS product_group_name,
	EXISTS(SELECT * FROM shopping_list WHERE shopping_list.product_id = sc.product_id) AS on_shopping_list,
	qu_stock.name AS qu_stock_name,
	qu_stock.name_plural AS qu_stock_name_plural,
	qu_purchase.name AS qu_purchase_name,
	qu_purchase.name_plural AS qu_purchase_name_plural,
	qu_consume.name AS qu_consume_name,
	qu_consume.name_plural AS qu_consume_name_plural,
	qu_price.name AS qu_price_name,
	qu_price.name_plural AS qu_price_name_plural,
	sc.is_aggregated_amount,
	sc.amount_opened_aggregated,
	sc.amount_aggregated,
	p.calories AS product_calories,
	sc.amount * p.calories AS calories,
	sc.amount_aggregated * p.calories AS calories_aggregated,
	p.quick_consume_amount,
	p.quick_consume_amount / p.qu_factor_consume_to_stock AS quick_consume_amount_qu_consume,
	p.quick_open_amount,
	p.quick_open_amount / p.qu_factor_consume_to_stock AS quick_open_amount_qu_consume,
	p.due_type,
	plp.purchased_date AS last_purchased,
	plp.price AS last_price,
	pap.price as average_price,
	p.min_stock_amount,
	pbcs.barcodes AS product_barcodes,
	p.description AS product_description,
	l.name AS product_default_location_name,
	p_parent.id AS parent_product_id,
	p_parent.name AS parent_product_name,
	p.picture_file_name AS product_picture_file_name,
	p.no_own_stock AS product_no_own_stock,
	p.qu_factor_purchase_to_stock AS product_qu_factor_purchase_to_stock,
	p.qu_factor_price_to_stock AS product_qu_factor_price_to_stock
FROM (
	SELECT *
	FROM stock_current
	WHERE best_before_date IS NOT NULL
	UNION
	SELECT m.id, 0, 0, 0, null, 0, 0, 0, p.due_type
	FROM stock_missing_products m
	JOIN products p
		ON m.id = p.id
	WHERE m.id NOT IN (SELECT product_id FROM stock_current)
	) sc
JOIN products_view p
    ON sc.product_id = p.id
JOIN locations l
	ON p.location_id = l.id
JOIN quantity_units qu_stock
	ON p.qu_id_stock = qu_stock.id
JOIN quantity_units qu_purchase
	ON p.qu_id_purchase = qu_purchase.id
JOIN quantity_units qu_consume
	ON p.qu_id_consume = qu_consume.id
JOIN quantity_units qu_price
	ON p.qu_id_price = qu_price.id
LEFT JOIN product_groups pg
	ON p.product_group_id = pg.id
LEFT JOIN cache__products_last_purchased plp
	ON sc.product_id = plp.product_id
LEFT JOIN cache__products_average_price pap
	ON sc.product_id = pap.product_id
LEFT JOIN product_barcodes_comma_separated pbcs
	ON sc.product_id = pbcs.product_id
LEFT JOIN products p_parent
	ON p.parent_product_id = p_parent.id
WHERE p.hide_on_stock_overview = 0;

DROP VIEW uihelper_shopping_list;
CREATE VIEW uihelper_shopping_list
AS
SELECT
	sl.*,
	p.name AS product_name,
	plp.price AS last_price_unit,
	plp.price * sl.amount AS last_price_total,
	st.name AS default_shopping_location_name,
	qu.name AS qu_name,
	qu.name_plural AS qu_name_plural,
	pg.id AS product_group_id,
	pg.name AS product_group_name,
	pbcs.barcodes AS product_barcodes
FROM shopping_list sl
LEFT JOIN products p
	ON sl.product_id = p.id
LEFT JOIN cache__products_last_purchased plp
	ON sl.product_id = plp.product_id
LEFT JOIN shopping_locations st
	ON p.shopping_location_id = st.id
LEFT JOIN quantity_units qu
	ON sl.qu_id = qu.id
LEFT JOIN product_groups pg
	ON p.product_group_id = pg.id
LEFT JOIN product_barcodes_comma_separated pbcs
	ON sl.product_id = pbcs.product_id;

DROP VIEW products_current_price;
CREATE VIEW products_current_price
AS

/*
	Current price per product,
	based on the stock entry to use next,
	or on the last price if the product is currently not in stock
*/

SELECT
	-1 AS id, -- Dummy,
	p.id AS product_id,
	IFNULL(snu.price, plp.price) AS price
FROM products p
LEFT JOIN (
	SELECT
		product_id,
		MAX(priority),
		price -- Bare column, ref https://www.sqlite.org/lang_select.html#bare_columns_in_an_aggregate_query
	FROM stock_next_use
	GROUP BY product_id
	ORDER BY priority DESC, open DESC, best_before_date ASC, purchased_date ASC
	) snu
	ON p.id = snu.product_id
LEFT JOIN cache__products_last_purchased plp
	ON p.id = plp.product_id;
