-- Making the new table
CREATE TABLE general.journal_summaries (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    organisation VARCHAR(40) NOT NULL,
    summary_year DATE NOT NULL,
    journal_reference TEXT NOT NULL,
    balance NUMERIC NOT NULL,
    period INTEGER NOT NULL CHECK(period BETWEEN 1 AND 13),
    i_f_tag VARCHAR(1) NOT NULL CHECK(i_f_tag IN ('i', 'f')),
	early_time TIME WITHOUT TIME ZONE,
	late_time TIME WITHOUT TIME ZONE,
	weekend_day BOOLEAN,
    additional_data JSONB
)
PARTITION BY LIST (summary_year)
TABLESPACE gl_data_space;
-- Creating partition years from previous data until 2036 including putting these into the same tablespace for memory
CREATE TABLE general.journal_summaries_2024
PARTITION OF general.journal_summaries
FOR VALUES IN ('2024-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2025
PARTITION OF general.journal_summaries
FOR VALUES IN ('2025-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2026
PARTITION OF general.journal_summaries
FOR VALUES IN ('2026-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2027
PARTITION OF general.journal_summaries
FOR VALUES IN ('2027-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2028
PARTITION OF general.journal_summaries
FOR VALUES IN ('2028-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2029
PARTITION OF general.journal_summaries
FOR VALUES IN ('2029-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2030
PARTITION OF general.journal_summaries
FOR VALUES IN ('2030-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2031
PARTITION OF general.journal_summaries
FOR VALUES IN ('2031-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2032
PARTITION OF general.journal_summaries
FOR VALUES IN ('2032-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2033
PARTITION OF general.journal_summaries
FOR VALUES IN ('2033-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2034
PARTITION OF general.journal_summaries
FOR VALUES IN ('2034-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2035
PARTITION OF general.journal_summaries
FOR VALUES IN ('2035-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_2036
PARTITION OF general.journal_summaries
FOR VALUES IN ('2036-04-01')
TABLESPACE gl_data_space;

CREATE TABLE general.journal_summaries_default
PARTITION OF general.journal_summaries
DEFAULT
TABLESPACE gl_data_space;

-- Adding comments to the different columns to be transparent about what they are/do
comment on column general.journal_summaries.id is 'The unique id associated with the row. This will be used to harvest further information about specific rows for outputs.';
comment on column general.journal_summaries.organisation is 'This is the organisation that the row relates to.';
comment on column general.journal_summaries.summary_year is 'This is the year that the row of this journal summary relates to.';
comment on column general.journal_summaries.journal_reference is 'The matching reference between the summary and the GL files.';
comment on column general.journal_summaries.balance is 'The balance associated with that particular row of the summary file.';
comment on column general.journal_summaries.period is 'The period for this row of the journal summary. It must be an interger between 1 and 13.';
comment on column general.journal_summaries.i_f_tag is 'This tags whether the upload was at interim or final.';
comment on column general.journal_summaries.early_time is 'This is the earliest time recorded for any time-containing field in the summary.';
comment on column general.journal_summaries.late_time is 'This is the latest time recorded for any time-containing field in the summary.';
comment on column general.journal_summaries.weekend_day is 'This is a BOOLEAN column to indicate the day is a weekend or weekday. TRUE means weekend.';
comment on column general.journal_summaries.additional_data is 'All additional columns that are non-essential to the fundamental processes are stored in JSON format. This will allow new columns to be created at any given moment without requiring the table to be altered or structural changes to the warehouse. This includes columns that may be important for the generation of journal scores or extra detail from the client but not fundamental to a departments performance in the app. This should ultimately mean that our table is flexible enough for the wide-array of data that we receive. Some added benefits of this method are that data in JSON can be indexed if required and are easy to edit/extract/manipulate in our application.';
-- Create covering index to help speed up the data loading process within applications
CREATE INDEX idx_general_journal_summary_org_year ON general.journal_summaries(organisation, gl_year) TABLESPACE gl_data_space;
-- Ensuring access to the secrets user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA general TO Postgres_admin;