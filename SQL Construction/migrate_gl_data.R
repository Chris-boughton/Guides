library(DBI)
library(RPostgres)
library(glue)

# Connect to DW
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("Postgres_db"),
  host = Sys.getenv("Postgres_host"),
  port = Sys.getenv("Postgres_port"),
  user = Sys.getenv("Postgres_user"),
  password = Sys.getenv("Postgres_password")
)

# Function to record log of data migration
write_log <- function(
    source_table,
    organisation,
    gl_year,
    source_rows,
    target_rows,
    source_balance,
    target_balance,
    success,
    error_message = NULL
) {
  dbExecute(con,
            "INSERT INTO general.gl_data_migration_log (
                source_table,
                organisation,
                gl_year,
                source_rows,
                target_rows,
                source_balance,
                target_balance,
                success,
                error_message
                )
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)",
            params = list(source_table,
                          organisation,
                          gl_year,
                          source_rows,
                          target_rows,
                          source_balance,
                          target_balance,
                          success,
                          error_message)
            )
}

# Account NI Migration
accountni_query <- "SELECT org.department_name AS organisation,
                           CASE
                              WHEN EXTRACT(MONTH FROM a.effective_date) >= 4
                              THEN CONCAT(EXTRACT(YEAR FROM a.effective_date), '-04-01')
                              ELSE CONCAT(EXTRACT(YEAR FROM a.effective_date)-1, '-04-01')
                            END AS gl_year,
                            
                            CASE
                              WHEN org.department_name = 'DFC'
                                AND a.code::numeric >= 80000
                                AND a.code::numeric <= 83000
                              THEN CONCAT(a.code,
                                          ' ',
                                          RIGHT(COALESCE(a.analysis_one_code, ''), 4),
                                          ' ',
                                          org.department_sub_category
                                          )
                                          
                              WHEN a.code::numeric >= 80000
                                AND a.code::numeric <= 83000
                              THEN CONCAT(a.code,
                                          ' ',
                                          RIGHT(COALESCE(a.analysis_one_code, ''), 4)
                                          )
                                          
                              WHEN org.department_name = 'DFC'
                              THEN CONCAT(a.code,
                                          ' ',
                                          org.department_sub_category
                                          )
                              ELSE a.code
                          END AS code,
                          
                          COALESCE(a.debit,0) - COALESCE(a.credit,0) AS balance,
                          a.posted_date,
                          'f' AS i_f_tag,
                          (to_jsonb(a) - ARRAY['id', 'code', 'debit', 'credit', 'posted_date', 'org_number', 'department_sub_category']) AS additional_data
                          
                    FROM accountni.account_ni_data a
                    LEFT JOIN accountni.organisations org
                      ON a.org_number = org.department_number"

# FECs
fec_query <- "SELECT organisation,
                     gl_year,
                     code,
                     balance,
                     COALESCE(posted_date, effective_date) AS posted_date,
                     'f' AS i_f_tag,
                     (to_jsonb(f) - ARRAY['id', 'organisation', 'gl_year', 'code', 'balance', 'posted_date']) AS additional_data
              FROM fec.fec_data f"

# Councils
councils_query <- "SELECT organisation,
                          gl_year,
                          code,
                          balance,
                          posted_date,
                          'f' AS i_f_tag,
                          (to_jsonb(c) - ARRAY['id', 'organisation', 'gl_year', 'code', 'balance', 'posted_date']) AS additional_data
                   FROM councils.councils_data c"

# Sage
sage_query <- "SELECT organisation,
                      gl_year,
                      CASE
                        WHEN organisation = 'Loughs'
                        THEN CONCAT(code,' ',sub_department)
                        ELSE code
                      END AS code,
                      balance,
                      posted_date,
                      'f' AS i_f_tag,
                      (to_jsonb(s) - ARRAY['id', 'organisation', 'gl_year', 'code', 'balance', 'posted_date', 'sub_department']) AS additional_data
                FROM sage.sage_data s"

# Migration function
migrate_source <- function(source_name, base_query) {
  # Print out the name of the department that we are migrating - for transparency as to what is being completed at any given moment
  print(source_name)
  
  # Creating a dataframe of the balances and rows that exist for each combo of year and org - so we know what is to be migrated and their size/balance
  combinations <- dbGetQuery(con,
                             glue("SELECT organisation,
                                          gl_year,
                                          COUNT(*) AS source_rows,
                                          COALESCE(SUM(balance),0) AS source_balance
                                   FROM ({base_query}) x
                                   GROUP BY 1,2
                                   ORDER BY 1,2"))
  
  # For each combo
  for(i in seq_len(nrow(combinations))) {
    # We take the stats associated with it
    org <- combinations$organisation[i]
    year <- combinations$gl_year[i]
    source_rows <- combinations$source_rows[i]
    source_balance <- combinations$source_balance[i]
    # Document that we are starting the specific org and year
    print(
      sprintf(
        "Processing %s | %s",
        org,
        year
      )
    )
    # Insert into the new gl data frame using the appropriate query that we made above (which manipulates the data into the format needed)
    tryCatch({
      dbBegin(con)
      insert_sql <- glue("INSERT INTO general.gl_data (organisation, gl_year, code, balance, posted_date, i_f_tag, additional_data)
                          SELECT organisation,
                                 gl_year,
                                 code,
                                 balance,
                                 posted_date,
                                 i_f_tag,
                                 additional_data
                          FROM ({base_query}) a
                          WHERE a.organisation = $1
                            AND a.gl_year = $2")
      dbExecute(con,
                insert_sql,
                params = list(org, year)
                )
      
      validation <- dbGetQuery(con,
                              "SELECT COUNT(*) AS target_rows,
                                      COALESCE(SUM(balance),0) AS target_balance
                               FROM general.gl_data
                               WHERE organisation = $1
                                 AND gl_year = $2
                                 AND i_f_tag = 'f'",
                              params = list(org, year))
      target_rows <- validation$target_rows[[1]]
      target_balance <- validation$target_balance[[1]]
      
      # Force everything to numerical values
      source_rows <- as.numeric(source_rows)[1]
      target_rows <- as.numeric(target_rows)[1]
      source_balance <- as.numeric(source_balance)[1]
      target_balance <- as.numeric(target_balance)[1]
      
      # Check it was successful
      success_check <- identical(source_rows, target_rows) && abs(source_balance - target_balance) < 0.0001
      success_check <- as.logical(success_check)[1]
      
      # Write teh log to document what was complete and the success of it
      write_log(
        source_name,
        as.character(org),
        as.character(year),
        source_rows,
        target_rows,
        source_balance,
        target_balance,
        success_check,
        NA_character_
      )
      
      # Push the query
      dbCommit(con)
      
      # Success message
      print(
        sprintf(
          "SUCCESS | Rows %.0f -> %.0f | Balance %.2f -> %.2f",
          source_rows,
          target_rows,
          source_balance,
          target_balance
        )
      ) # If this causes an error
    }, error = function(e) {
      # Attempt to abort all changes made since we started dbBegin(), which will be all insertion/data for that loop value
      try(
        dbRollback(con),
        silent = TRUE
      )
      
      # Wrtie the log indicating it was unsuccessful and produce the error message
      write_log(
        source_name,
        as.character(org),
        as.character(year),
        as.numeric(source_rows)[1],
        NA_real_,
        as.numeric(source_balance)[1],
        NA_real_,
        FALSE,
        as.character(conditionMessage(e))[1]
      )
      # Write to the console that it failed for that org and year with the error it experienced
      print(
        sprintf(
          "FAILED | %s | %s | %s",
          org,
          year,
          conditionMessage(e)
        )
      )
    })
  }
}

# Running the functions
# Account NI migration
migrate_source(
  "accountni.account_ni_data",
  accountni_query
)

# FEC migration
migrate_source(
  "fec.fec_data",
  fec_query
)

# Sage migration
migrate_source(
  "sage.sage_data",
  sage_query
)

# Council migration
migrate_source(
  "councils.councils_data",
  councils_query
)

# Other data migration
tryCatch({
  dbBegin(con)
  # Identifying the amount of rows and balance to be migrated
  source_stats <- dbGetQuery(con,
                             "SELECT COUNT(*) AS row_count,
                                     COALESCE(SUM(balance), 0) AS total_balance
                              FROM other.other_gl")
  source_rows <- as.numeric(source_stats$row_count[[1]])
  source_balance <- as.numeric(source_stats$total_balance[[1]])
  
  # Identifying state of table that this data will go into before any other_data is migrated
  before_other <- dbGetQuery(con,
                             "SELECT COUNT(*) AS row_count,
                                     COALESCE(SUM(balance), 0) AS total_balance
                              FROM general.gl_data")
  before_rows <- as.numeric(before_other$row_count[[1]])
  before_balance <- as.numeric(before_other$total_balance[[1]])
  
  # Writing to the console the number of rows and total balance that is to be migrated
  print(
    sprintf(
      "Source rows: %.0f | Source balance: %.2f",
      source_rows,
      source_balance
    )
  )
  
  # Inserting the rows from the other_gl table into the new table
  inserted_rows <- dbExecute(con,
                             "INSERT INTO general.gl_data (organisation, gl_year, code, balance, posted_date, i_f_tag, additional_data)
                              SELECT organisation,
                                     gl_year,
                                     code,
                                     balance,
                                     posted_date,
                                     i_f_tag,
                                     additional_data
                              FROM other.other_gl")

  # Checking the metrics of the table after the migration has occurred
  after_other <- dbGetQuery(con,
                            "SELECT COUNT(*) AS row_count,
                                    COALESCE(SUM(balance), 0) AS total_balance
                             FROM general.gl_data")
  after_rows <- as.numeric(after_other$row_count[[1]])
  after_balance <- as.numeric(after_other$total_balance[[1]])
  
  # Calculating the number of rows and total balance added
  rows_added <- after_rows - before_rows
  balance_added <- after_balance - before_balance
  
  # Checking all went smoothly and no issues/discrepancies in value etc.
  success_check <- identical(as.numeric(rows_added), as.numeric(source_rows)) && abs(balance_added - source_balance) < 0.0001
  
  # Writing the log out to state what occurred
  write_log(
    source_table = "other.other_gl",
    organisation = "ALL",
    gl_year = "ALL",
    source_rows = source_rows,
    target_rows = rows_added,
    source_balance = source_balance,
    target_balance = balance_added,
    success = success_check,
    error_message = NA_character_
  )
  dbCommit(con)
  
  # Documenting the success in the console for transparency all went grand
  print(
    sprintf(
      "SUCCESS | Rows Added: %.0f | Expected Rows: %.0f | Balance Added: %.2f | Expected Balance: %.2f",
      rows_added,
      source_rows,
      balance_added,
      source_balance
      )
    ) # If an error occurs
  }, error = function(e) {
    
  # Then prevent the work/changes since dbBegin() started and return to prior state
  try(dbRollback(con), silent = TRUE)
  # Write the log explaining what went wrong as an error message
  write_log(
    source_table = "other.other_gl",
    organisation = "ALL",
    gl_year = "ALL",
    source_rows = NA_real_,
    target_rows = NA_real_,
    source_balance = NA_real_,
    target_balance = NA_real_,
    success = FALSE,
    error_message = conditionMessage(e)
  )
  # Document to console that it failed with the reason it did
  print(
    sprintf("FAILED %s",
            conditionMessage(e)
            )
    )
})
dbDisconnect(con)
