--Create table and import data from csv

CREATE TABLE IF NOT EXISTS public.distribusi_barang (
	No INTEGER,
	Product_Name VARCHAR(100),
	Qty INTEGER,
	Unit VARCHAR(10),
	Store_Destination VARCHAR(50),
	Store_Address VARCHAR(50),
	Operator VARCHAR(50),
	Shipping_Vehicle VARCHAR (50),
	No_Polisi VARCHAR (50),
	Shipping_Driver VARCHAR(50),
	Shipping_codriver VARCHAR(50),
	Sending_Time TIMESTAMP WITHOUT TIME ZONE,
	Delivered_Time TIMESTAMP WITHOUT TIME ZONE,
	Received_By VARCHAR(50)
);

SELECT *
FROM distribusi_barang;

copy distribusi_barang from 'E:\Daftar Kerja\Magang\Rakamin\Database Administrator - Kalbe\distribusi_barang.csv' (format csv, null "NULL", DELIMITER ';', HEADER);

CREATE TABLE IF NOT EXISTS public.data_produk (
	No INTEGER,
	Name VARCHAR(100)
);

copy data_produk from 
'E:\Daftar Kerja\Magang\Rakamin\Database Administrator - Kalbe\data_produk.csv' 
(format csv, null "NULL", DELIMITER ';', HEADER);

SELECT *
FROM data_produk;

--Create schema app and table normalization of distribution product

CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    qty INTEGER NOT NULL,
    unit VARCHAR(10) NOT NULL,
    store_id INTEGER NOT NULL,
    operator_id INTEGER NOT NULL
);

CREATE TABLE app.store (
    store_id SERIAL PRIMARY KEY,
    store_destination VARCHAR(100) NOT NULL,
    store_address VARCHAR(100) NOT NULL
);

CREATE TABLE app.operator (
    operator_id SERIAL PRIMARY KEY,
    operator_name VARCHAR(50) NOT NULL
);

CREATE TABLE app.vehicle (
    vehicle_id SERIAL PRIMARY KEY,
    shipping_vehicle VARCHAR(50) NOT NULL,
	no_polisi VARCHAR(50) NOT NULL,
    shipping_driver VARCHAR(50) NOT NULL,
    shipping_codriver VARCHAR(50) NOT NULL,
    operator_id INTEGER NOT NULL
);

CREATE TABLE app.delivery (
    delivery_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    store_id INTEGER NOT NULL,
    vehicle_id INTEGER NOT NULL,
    sending_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    delivered_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    received_by VARCHAR(50) NOT NULL
);

--Alter table add foreign key

ALTER TABLE app.product
ADD CONSTRAINT FK_product_storeid
FOREIGN KEY (store_id)
REFERENCES app.store(store_id);

ALTER TABLE app.product
ADD CONSTRAINT FK_product_operatorid
FOREIGN KEY (operator_id)
REFERENCES app.operator(operator_id);

ALTER TABLE app.vehicle
ADD CONSTRAINT FK_vehicle_operatorid
FOREIGN KEY (operator_id)
REFERENCES app.operator(operator_id);


ALTER TABLE app.delivery
ADD CONSTRAINT FK_delivery_product
FOREIGN KEY (product_id)
REFERENCES app.product(product_id);

ALTER TABLE app.delivery
ADD CONSTRAINT FK_delivery_storeid
FOREIGN KEY (store_id)
REFERENCES app.store(store_id);

ALTER TABLE app.delivery
ADD CONSTRAINT FK_delivery_vehicleid
FOREIGN KEY (vehicle_id)
REFERENCES app.vehicle(vehicle_id);


-- Retrieved data from public.distribusi_barang to normalization table (app.product, app.store, etc)

SELECT *
FROM public.distribusi_barang;

INSERT INTO app.store (store_destination, store_address)
SELECT DISTINCT store_destination, store_address
FROM public.distribusi_barang
ORDER BY store_destination;

SELECT *
FROM app.store;


INSERT INTO app.operator (operator_name)
SELECT DISTINCT operator_name
FROM public.distribusi_barang
ORDER BY operator_name;

SELECT *
FROM app.operator;


INSERT INTO app.product (product_name, qty, unit, store_id, operator_id)
SELECT DISTINCT db.product_name, db.qty, db.unit, s.store_id, o.operator_id
FROM public.distribusi_barang db
INNER JOIN app.store s
	ON db.store_destination = s.store_destination
INNER JOIN app.operator o
	ON db.operator_name = o.operator_name
ORDER BY s.store_id, o.operator_id;

SELECT *
FROM app.product;


INSERT INTO app.vehicle (shipping_vehicle, no_polisi, shipping_driver, shipping_codriver, operator_id)
SELECT DISTINCT db.shipping_vehicle, db.no_polisi, db.shipping_driver, db.shipping_codriver, o.operator_id
FROM public.distribusi_barang db
INNER JOIN app.operator o
	ON db.operator_name = o.operator_name
ORDER BY db.shipping_vehicle, operator_id;

SELECT *
FROM app.vehicle;


INSERT INTO app.delivery (product_id, store_id, vehicle_id, sending_time, delivered_time, received_by)
SELECT p.product_id, s.store_id, v.vehicle_id, db.sending_time, db.delivered_time, db.received_by
FROM public.distribusi_barang db
INNER JOIN app.product p
	ON db.product_name = p.product_name
INNER JOIN app.store s
	ON db.store_destination = s.store_destination
INNER JOIN app.vehicle v
	ON db.shipping_vehicle = v.shipping_vehicle
ORDER BY p.product_id,s.store_id,v.vehicle_id;

SELECT *
FROM app.delivery;



--Create an users for backend programmers to INSERT, SELECT, UPDATE, DELETE

CREATE USER backend_programmer WITH ENCRYPTED PASSWORD 'kalbe123';
GRANT CONNECT ON DATABASE app TO backend_programmer;
GRANT USAGE ON SCHEMA app TO backend_programmer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO backend_programmer;



--Create an indexes to optimize query

CREATE INDEX idx_product_product_id ON app.product (product_id);
CREATE INDEX idx_product_product_name ON app.product (product_name);
CREATE INDEX idx_product_store_id ON app.product (store_id);
CREATE INDEX idx_product_operator_id ON app.product (operator_id);

CREATE INDEX idx_store_store_id ON app.store (store_id);
CREATE INDEX idx_store_store_destination ON app.store (store_destination);

CREATE INDEX idx_operator_operator_id ON app.operator (operator_id);
CREATE INDEX idx_operator_operator_name ON app.operator (operator_name);

CREATE INDEX idx_vehicle_vehicle_id ON app.vehicle (vehicle_id);
CREATE INDEX idx_vehicle_shipping_vehicle ON app.vehicle (shipping_vehicle);
CREATE INDEX idx_vehicle_operator_id ON app.vehicle (operator_id);

CREATE INDEX idx_delivery_delivery_id ON app.delivery (delivery_id);
CREATE INDEX idx_delivery_product_id ON app.delivery (product_id);
CREATE INDEX idx_delivery_store_id ON app.delivery (store_id);
CREATE INDEX idx_delivery_vehicle_id ON app.delivery (vehicle_id);
CREATE INDEX idx_delivery_received_by ON app.delivery (received_by);


--Showing the 2 drivers with the most deliveries of May 2023

SELECT shipping_driver, COUNT(*) AS total_shipment
FROM public.distribusi_barang
WHERE EXTRACT(MONTH FROM delivered_time) = 5 AND EXTRACT(YEAR FROM delivered_time) = 2023
GROUP BY shipping_driver
ORDER BY total_shipment DESC
LIMIT 2;


--Showing the 10 most frequently shipped items in May 2023

SELECT product_name, SUM(qty) AS total_qty
FROM public.distribusi_barang
WHERE EXTRACT(MONTH FROM delivered_time) = 5 AND EXTRACT(YEAR FROM delivered_time) = 2023
GROUP BY product_name
ORDER BY total_qty DESC
LIMIT 10;


--Shows all incomplete submissions

SELECT *
FROM public.distribusi_barang
WHERE delivered_time IS NULL;


--Create a Shipment ID with the format yymmddxxx (example: 230519001, 230519002)

SELECT TO_CHAR(sending_time, 'YYMMDD') || LPAD(ROW_NUMBER() OVER 
	(ORDER BY sending_time)::TEXT, 3, '0') AS shipment_id
FROM public.distribusi_barang;

SELECT *
FROM public.distribusi_barang;
--Create a new shipment wtih stored procedures

CREATE OR REPLACE PROCEDURE sp_create_shipment(
    IN product_name VARCHAR(100),
    IN qty INTEGER,
    IN unit VARCHAR(10),
    IN store_destination VARCHAR(100),
    IN store_address VARCHAR(100),
    IN operator_name VARCHAR(50),
    IN shipping_vehicle VARCHAR(50),
    IN no_polisi VARCHAR(50),
    IN shipping_driver VARCHAR(50),
    IN shipping_codriver VARCHAR(50),
    IN sending_time TIMESTAMP WITHOUT TIME ZONE,
	IN delivered_time TIMESTAMP WITHOUT TIME ZONE,
    IN received_by VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.distribusi_barang ("product_name", "qty", "unit", "store_destination", 
		"store_address", "operator_name", "shipping_vehicle", "no_polisi", "shipping_driver", 
		"shipping_codriver", "sending_time", "delivered_time", "received_by")
    VALUES (product_name, qty, unit, store_destination, store_address, operator_name, 
		shipping_vehicle, no_polisi, shipping_driver, shipping_codriver, sending_time, 
		delivered_time, received_by);
END;
$$;


--Create sp for add products to the shipment

CREATE OR REPLACE PROCEDURE sp_add_product_to_shipment(
    IN shipment_id bigint,
    IN product_name character varying,
    IN qty integer,
    IN unit character varying
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO app.distribusi_barang ("shipment_id", "product_name", "qty", "unit")
    VALUES (shipment_id, product_name, qty, unit);
END;
$$;


-- Created a function for job backup
CREATE OR REPLACE FUNCTION calculate_total_shipments_by_product(product_name character varying)
RETURNS integer
AS $$
DECLARE
    total_shipments integer;
BEGIN
    SELECT COUNT(*) INTO total_shipments
    FROM shipment
    WHERE product_name = calculate_total_shipments_by_product.product_name
        AND sending_time >= '2023-05-01' AND sending_time < '2023-06-01';

    RETURN total_shipments;
END;
$$
LANGUAGE plpgsql;


--Code step
COPY (select * FROM calculate_total_shipments_by_product('%%')) 
TO E'E:\Daftar Kerja\Magang\Rakamin\Database Administrator - Kalbe\backup.csv';





