# Migrate Journal Summary Data #

# Establishing a connection to the data warehouse for pushing of data
data_warehouse <- dbConnect(                 # Connecting to the warehouse
  RPostgres::Postgres(),                     # Establishing a Postgres connection
  dbname = Sys.getenv("Postgres_db"),        # Pulling the name of the database
  host = Sys.getenv("Postgres_host"),        # Pulling the host of the data warehouse
  port = Sys.getenv("Postgres_port"),        # Pulling the port of the data warehouse
  user = Sys.getenv("Postgres_user"),        # Pulling the user of the data warehouse
  password = Sys.getenv("Postgres_password") # Pulling the password of the data warehouse
  )

# Query to pull existing ANI data
ANI <- DBI::dbGetQuery(
  data_warehouse,
  "SELECT organisation,

          CASE
            WHEN EXTRACT(MONTH FROM effective_date) >= 4
            THEN CONCAT(EXTRACT(YEAR FROM effective_date), '-04-01')
            ELSE CONCAT(EXTRACT(YEAR FROM effective_date)-1, '-04-01')
          END AS summary_year,

          journal_reference,

          debit AS balance,
          
          CASE LEFT(period_name, 3)
              WHEN 'APR' THEN 1
              WHEN 'MAY' THEN 2
              WHEN 'JUN' THEN 3
              WHEN 'JUL' THEN 4
              WHEN 'AUG' THEN 5
              WHEN 'SEP' THEN 6
              WHEN 'OCT' THEN 7
              WHEN 'NOV' THEN 8
              WHEN 'DEC' THEN 9
              WHEN 'JAN' THEN 10
              WHEN 'FEB' THEN 11
              WHEN 'MAR' THEN 12
              WHEN 'ADJ' THEN 13
          END AS period,

          'f' AS i_f_tag,

          LEAST(created_date, posted_date, last_updated_date)::TIME AS early_time,
          
          GREATEST(created_date, posted_date, last_updated_date)::TIME AS late_time,

          CASE
              WHEN weekend_day = 1 THEN TRUE
              WHEN weekend_day = 0 THEN FALSE
          END AS weekend_day,

          (to_jsonb(a) - ARRAY['id', 'organisation', 'summary_year', 'journal_reference', 'debit', 'credit', 'period_name', 'weekend_day', 'department_sub_category']) AS additional_data

   FROM accountni.account_ni_journal_summary a")

# Query to pull existing Non ANI data
NonANI <- DBI::dbGetQuery(
  data_warehouse,
  "SELECT organisation,

          summary_year,

          journal_reference,

          balance,

          CASE
              WHEN period_name = 'Start Adj' THEN 0
              WHEN period_name = 'End Adj'   THEN 13
              WHEN LEFT(period_name, 3) = 'Apr' THEN 1
              WHEN LEFT(period_name, 3) = 'May' THEN 2
              WHEN LEFT(period_name, 3) = 'Jun' THEN 3
              WHEN LEFT(period_name, 3) = 'Jul' THEN 4
              WHEN LEFT(period_name, 3) = 'Aug' THEN 5
              WHEN LEFT(period_name, 3) = 'Sep' THEN 6
              WHEN LEFT(period_name, 3) = 'Oct' THEN 7
              WHEN LEFT(period_name, 3) = 'Nov' THEN 8
              WHEN LEFT(period_name, 3) = 'Dec' THEN 9
              WHEN LEFT(period_name, 3) = 'Jan' THEN 10
              WHEN LEFT(period_name, 3) = 'Feb' THEN 11
              WHEN LEFT(period_name, 3) = 'Mar' THEN 12
              ELSE
                  CASE EXTRACT(MONTH FROM COALESCE(posted_date, effective_date))
                      WHEN 4  THEN 1
                      WHEN 5  THEN 2
                      WHEN 6  THEN 3
                      WHEN 7  THEN 4
                      WHEN 8  THEN 5
                      WHEN 9  THEN 6
                      WHEN 10 THEN 7
                      WHEN 11 THEN 8
                      WHEN 12 THEN 9
                      WHEN 1  THEN 10
                      WHEN 2  THEN 11
                      WHEN 3  THEN 12
                      ELSE 12
                  END
          END AS period,

          'f' AS i_f_tag,

          LEAST(created_time, posted_time) AS early_time,
          
          GREATEST(created_time, posted_time) AS late_time,
          
          CASE
              WHEN weekend_day IS NOT NULL
                  THEN (weekend_day = 1)
              
              WHEN COALESCE(posted_date, effective_date) IS NOT NULL
                  THEN EXTRACT(DOW FROM COALESCE(posted_date, effective_date)) IN (0, 6)
              ELSE NULL
          END AS weekend_day,

          (to_jsonb(a) - ARRAY['id', 'organisation', 'journal_reference', 'balance', 'period_name', 'weekend_day']) AS additional_data

   FROM nonaccountni.journal_summaries a")

# To upload the data to the data warehouse, we will use a chunking system that loops through the global environment to pull all data frames and then chunk upload them. The rationale
# for this method is that it allows a fairly straightforward process that is consistent 
upload_data <- ls()                           # List all objects in the environment
for (environment_data in upload_data) {       # Loop through each object in the environment
  if (is.data.frame(get(environment_data))) { # Check if the data found in the environment is a data frame
    upload_df <- get(environment_data)        # Extract the data frame from the environment
    if (nrow(upload_df) > 0) {                # Check if the dataframe contains data to upload
      chunk_size <- 10000                     # Defining the chunk size for upload
      total_rows <- nrow(upload_df)           # Finding the length of data frame using nrow()
      for (start_row in seq(1, total_rows, by = chunk_size)) { # For each row in the sequence of 1 to the end of the data frame, split up by chunks
        end_row <- min(start_row + chunk_size - 1, total_rows) # Calculate the end row which is the lowest number as either the previous + new chunk - 1 or the end of the dataframe
        chunk <- upload_df[start_row:end_row, ]                # Creating the chunk based on the row extraction
        tryCatch({                                             # Upload each chunk of the data frame to the warehouse with an error handler (aka.tryCatch()) to identify issues on upload
          dbWriteTable(                                        # Writing a database table
            data_warehouse,                                    # Connecting to the data warehouse through connection specified above
            name = SQL("general.journal_summaries"),           # Writing some SQL code to specify the schema/database the data should be uploaded to
            value = chunk,                                     # The data to be uploaded is the data created in the chunk above
            append = TRUE,                                     # The data is appended onto the table
            row.names = FALSE)                                 # There are no row names
          message(sprintf("Uploaded rows %d to %d of %s", start_row, end_row, environment_data)) # A message to inform what rows of what dataframe were uploaded successfully
          },
          error = function(failed_upload) {                                                                                          # If an error during upload
            message(sprintf("Error uploading rows %d to %d of %s: %s", start_row, end_row, environment_data, failed_upload$message)) # Then an error identifying what rows is produced
            }
          )
        }
      } else {
        message(sprintf("Skipping %s as it is empty.", environment_data))          # Where empty data frames may exist, then these are skipped and justified
        }
    } else {
      message(sprintf("Skipping %s as it is not a data frame.", environment_data)) # Where objects in the environment are not data frames, these are skipped and justified
    }
  }

# Disconnecting from the data warehouse
dbDisconnect(data_warehouse)