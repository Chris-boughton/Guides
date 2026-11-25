-- Had to create a new tablespace as the organisation of memory on Linux server was wonky (300GB free on /home but only 91GB given to psql)
CREATE TABLESPACE gl_data_space
LOCATION '/home/postgres_tablespace';
-- Making the new table
CREATE TABLE general.gl_data (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    organisation VARCHAR(40) NOT NULL,
    gl_year DATE NOT NULL,
    code VARCHAR(40) NOT NULL,
    balance NUMERIC NOT NULL,
    posted_date TIMESTAMP NOT NULL,
    i_f_tag VARCHAR(1) NOT NULL,
    additional_data JSONB
)
PARTITION BY LIST (gl_year)
TABLESPACE gl_data_space;
-- Creating partition years from previous data until 2036 including putting these into the same tablespace for memory
CREATE TABLE general.gl_data_2021_04
PARTITION OF general.gl_data
FOR VALUES IN ('2021-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2022_04
PARTITION OF general.gl_data
FOR VALUES IN ('2022-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2023_04
PARTITION OF general.gl_data
FOR VALUES IN ('2023-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2023_08
PARTITION OF general.gl_data
FOR VALUES IN ('2023-08-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2024_01
PARTITION OF general.gl_data
FOR VALUES IN ('2024-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2024_04
PARTITION OF general.gl_data
FOR VALUES IN ('2024-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2024_08
PARTITION OF general.gl_data
FOR VALUES IN ('2024-08-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2025_01
PARTITION OF general.gl_data
FOR VALUES IN ('2025-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2025_04
PARTITION OF general.gl_data
FOR VALUES IN ('2025-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2025_09
PARTITION OF general.gl_data
FOR VALUES IN ('2025-09-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2026_01
PARTITION OF general.gl_data
FOR VALUES IN ('2026-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2026_04
PARTITION OF general.gl_data
FOR VALUES IN ('2026-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2027_01
PARTITION OF general.gl_data
FOR VALUES IN ('2027-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2027_04
PARTITION OF general.gl_data
FOR VALUES IN ('2027-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2028_01
PARTITION OF general.gl_data
FOR VALUES IN ('2028-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2028_04
PARTITION OF general.gl_data
FOR VALUES IN ('2028-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2029_01
PARTITION OF general.gl_data
FOR VALUES IN ('2029-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2029_04
PARTITION OF general.gl_data
FOR VALUES IN ('2029-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2030_01
PARTITION OF general.gl_data
FOR VALUES IN ('2030-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2030_04
PARTITION OF general.gl_data
FOR VALUES IN ('2030-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2031_01
PARTITION OF general.gl_data
FOR VALUES IN ('2031-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2031_04
PARTITION OF general.gl_data
FOR VALUES IN ('2031-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2032_01
PARTITION OF general.gl_data
FOR VALUES IN ('2032-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2032_04
PARTITION OF general.gl_data
FOR VALUES IN ('2032-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2033_01
PARTITION OF general.gl_data
FOR VALUES IN ('2033-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2033_04
PARTITION OF general.gl_data
FOR VALUES IN ('2033-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2034_01
PARTITION OF general.gl_data
FOR VALUES IN ('2034-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2034_04
PARTITION OF general.gl_data
FOR VALUES IN ('2034-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2035_01
PARTITION OF general.gl_data
FOR VALUES IN ('2035-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2035_04
PARTITION OF general.gl_data
FOR VALUES IN ('2035-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2036_01
PARTITION OF general.gl_data
FOR VALUES IN ('2036-01-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_2036_04
PARTITION OF general.gl_data
FOR VALUES IN ('2036-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.gl_data_default
PARTITION OF general.gl_data
DEFAULT
TABLESPACE gl_data_space;

-- Adding comments to the different columns to be transparent about what they are/do
comment on column general.gl_data.id is 'The unique id associated with the row. This will be used to harvest further information about specific rows for outputs.';
comment on column general.gl_data.organisation is 'This is the organisation that the row relates to.';
comment on column general.gl_data.gl_year is 'This is the year that the row of this gl relates to.';
comment on column general.gl_data.code is 'The account code for the row of the GL.';
comment on column general.gl_data.balance is 'The balance associated with that particular row of the GL.';
comment on column general.gl_data.posted_date is 'The date that this particular row was posted in the GL.';
comment on column general.gl_data.additional_data is 'All additional columns that are non-essential to the fundamental processes are stored in JSON format. This will allow new columns to be created at any given moment without requiring the table to be altered or structural changes to the warehouse. This includes columns that may be important for later tests or workflows, such as description, period_name and creator, as they are important for later stages but not fundamental to a departments performance in the app. This should ultimately mean that our table is flexible enough for the wide-array of data that we receive. Some added benefits of thsi method are that data in JSON can be indexed if required and are easy to edit/extract/manipulate in our application.';
-- Create covering index to help speed up the data loading process within applications
CREATE INDEX idx_general_gl_org_year_tag ON general.gl_data(organisation, gl_year, i_f_tag) INCLUDE (id, code, balance) TABLESPACE gl_data_space;
-- Ensuring access to the secrets user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA general TO Postgres_admin;