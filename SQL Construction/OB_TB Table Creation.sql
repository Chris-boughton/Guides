-- Creating the table for OBs and TBs
CREATE TABLE IF NOT EXISTS general.ob_tb (
	id							BIGINT	GENERATED ALWAYS AS IDENTITY,
	organisation				TEXT NOT NULL,
	code						VARCHAR(35) NOT NULL,
	account_code_description	TEXT,
	analysis_one_description	TEXT,
	year						DATE NOT NULL,
	balance						NUMERIC NOT NULL,
	ob_tb_tag					VARCHAR(2) NOT NULL CHECK (ob_tb_tag IN ('ob', 'tb')),
	i_f_tag						VARCHAR(1) NOT NULL CHECK (i_f_tag IN ('i', 'f')),
	CONSTRAINT ob_tb_pkey PRIMARY KEY (organisation, code, year, ob_tb_tag, i_f_tag)
)
PARTITION BY RANGE ("year");

-- Creating the partitions
CREATE TABLE general.ob_tb_2021
PARTITION OF general.ob_tb
FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

CREATE TABLE general.ob_tb_2022
PARTITION OF general.ob_tb
FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');

CREATE TABLE general.ob_tb_2023
PARTITION OF general.ob_tb
FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE general.ob_tb_2024
PARTITION OF general.ob_tb
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE general.ob_tb_2025
PARTITION OF general.ob_tb
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE general.ob_tb_2026
PARTITION OF general.ob_tb
FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE general.ob_tb_2027
PARTITION OF general.ob_tb
FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

CREATE TABLE general.ob_tb_2028
PARTITION OF general.ob_tb
FOR VALUES FROM ('2028-01-01') TO ('2029-01-01');

CREATE TABLE general.ob_tb_2029
PARTITION OF general.ob_tb
FOR VALUES FROM ('2029-01-01') TO ('2030-01-01');

CREATE TABLE general.ob_tb_2030
PARTITION OF general.ob_tb
FOR VALUES FROM ('2030-01-01') TO ('2031-01-01');

CREATE TABLE general.ob_tb_2031
PARTITION OF general.ob_tb
FOR VALUES FROM ('2031-01-01') TO ('2032-01-01');

CREATE TABLE general.ob_tb_2032
PARTITION OF general.ob_tb
FOR VALUES FROM ('2032-01-01') TO ('2033-01-01');

CREATE TABLE general.ob_tb_2033
PARTITION OF general.ob_tb
FOR VALUES FROM ('2033-01-01') TO ('2034-01-01');

CREATE TABLE general.ob_tb_2034
PARTITION OF general.ob_tb
FOR VALUES FROM ('2034-01-01') TO ('2035-01-01');

CREATE TABLE general.ob_tb_2035
PARTITION OF general.ob_tb
FOR VALUES FROM ('2035-01-01') TO ('2036-01-01');

CREATE TABLE general.ob_tb_2036
PARTITION OF general.ob_tb
FOR VALUES FROM ('2036-01-01') TO ('2037-01-01');

CREATE TABLE general.ob_tb_default
PARTITION OF general.ob_tb DEFAULT;

-- Comments for the OB TB table
comment on column general.ob_tb.id is 'The id associated with the row, which is an automatically generated integer in sequence.';
comment on column general.ob_tb.organisation is 'The department name for the TB/OB inserted.';
comment on column general.ob_tb.code is 'The account code for the TB/OB inserted. This is the full concatenated code that matches the mapping template and GL. For some departments this will be a complex code that will be broken up when required in the applications, but retained as one whole code in the warehouse.';
comment on column general.ob_tb.account_code_description is 'The account code description for the TB/OB inserted.';
comment on column general.ob_tb.analysis_one_description is 'The analysis one description for the TB/OB inserted.';
comment on column general.ob_tb.year is 'The year that the associated OB/TB is for. This is always a DATE of format %Y-%m-%d e.g. 2026-10-26';
comment on column general.ob_tb.balance is 'The monetary balance for the TB/OB inserted.';
comment on column general.ob_tb.ob_tb_tag is 'The tag to indicate whether the line represents an OB (ob) or TB (tb) line.';
comment on column general.ob_tb.i_f_tag is 'The tag to indicate whether the line represents an interim (i) or final (f) line.';

-- Providing permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA general TO Postgres_admin;

-- Generating index
CREATE INDEX idx_ob_tb_org_year_obtb_tag ON general.ob_tb(organisation, year, ob_tb_tag);
CREATE INDEX idx_ob_tb_org_year_obtb_if_tag ON general.ob_tb(organisation, year, ob_tb_tag, i_f_tag);