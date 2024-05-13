-- Table: fact_candy_sales

-- DROP TABLE fact_candy_sales;

CREATE TABLE fact_candy_sales
(
  order_key bigint NOT NULL,
  product_key integer,
  order_date integer,
  customer_key integer,
  units integer,
  sale_amount integer,
  CONSTRAINT pk_fact_candy_sales PRIMARY KEY (order_key),
  CONSTRAINT fk_customer FOREIGN KEY (customer_key)
      REFERENCES dim_candy_customers (customer_key) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_product FOREIGN KEY (product_key)
      REFERENCES dim_candy_products (product_key) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fact_candy_sales
  OWNER TO postgres;

-- Index: fki_customer

-- DROP INDEX fki_customer;

CREATE INDEX fki_customer
  ON fact_candy_sales
  USING btree
  (customer_key);

-- Index: fki_product

-- DROP INDEX fki_product;

CREATE INDEX fki_product
  ON fact_candy_sales
  USING btree
  (product_key);

-- Index: idx_order_date

-- DROP INDEX idx_order_date;

CREATE INDEX idx_order_date
  ON fact_candy_sales
  USING btree
  (order_date);


  
-- Table: fact_transactions

-- DROP TABLE fact_transactions;

CREATE TABLE fact_transactions
(
  transaction_key bigint NOT NULL,
  transaction_type_key integer,
  party_account_key integer,
  location_key integer,
  transaction_date integer,
  transaction_amount double precision,
  CONSTRAINT pk_fact_transactions PRIMARY KEY (transaction_key)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE fact_transactions
  OWNER TO postgres;

-- Index: fki_location

-- DROP INDEX fki_location;

CREATE INDEX fki_location
  ON fact_transactions
  USING btree
  (location_key);

-- Index: fki_party_account

-- DROP INDEX fki_party_account;

CREATE INDEX fki_party_account
  ON fact_transactions
  USING btree
  (party_account_key);

-- Index: fki_transaction_type

-- DROP INDEX fki_transaction_type;

CREATE INDEX fki_transaction_type
  ON fact_transactions
  USING btree
  (transaction_type_key);

-- Index: idx_transaction_date

-- DROP INDEX idx_transaction_date;

CREATE INDEX idx_transaction_date
  ON fact_transactions
  USING btree
  (transaction_date);

