CREATE TABLE IF NOT EXISTS general.general_ob_tb (
	id							BIGINT GENERATED ALWAYS AS IDENTITY,
	organisation				TEXT NOT NULL,
	code						VARCHAR(35) NOT NULL,
	account_code_description	TEXT,
	analysis_one_description	TEXT,
	year						DATE NOT NULL,
	balance						NUMERIC NOT NULL,
	ob_tb_tag					VARCHAR(2) NOT NULL CHECK(ob_tb_tag IN ('ob', 'tb')),
	i_f_tag						VARCHAR(1) NOT NULL CHECK(ob_tb_tag IN ('i', 'f')),
	CONSTRAINT ob_tb_p_key PRIMARY KEY (organisation, code, year, ob_tb_tag, i_f_tag)
);

comment on column general.general_ob_tb.id is 'The id associated with the row, which is an automatically generated integer in sequence.';
comment on column general.general_ob_tb.organisation is 'The department name for the TB/OB inserted.';
comment on column general.general_ob_tb.code is 'The account code for the TB/OB inserted. This is the full concatenated code that matches the mapping template and GL. Some organisations may have complex codes that are broken up when required in the applications, but retained as one whole code in the warehouse.';
comment on column general.general_ob_tb.account_code_description is 'The account code description for the TB/OB inserted.';
comment on column general.general_ob_tb.analysis_one_description is 'The analysis one description for the TB/OB inserted.';
comment on column general.general_ob_tb.year is 'The year that the associated OB/TB is for. This is always a DATE of format %Y-%m-%d e.g. 2026-10-26';
comment on column general.general_ob_tb.balance is 'The monetary balance for the TB/OB inserted.';
comment on column general.general_ob_tb.ob_tb_tag is 'The tag to indicate whether the line represents an OB (ob) or TB (tb) line.';
comment on column general.general_ob_tb.i_f_tag is 'The tag to indicate whether the line represents an interim (i) or final (f) line.';

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA general TO Postgres_admin;

CREATE INDEX idx_ob_tb_organisation_year_ob_tb_i_f ON general.general_ob_tb(organisation, year, ob_tb_tag, i_f_tag);
