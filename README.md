# Rick and Morty Data Pipeline

## Development Process
1. Explore the API endpoints in Postman and review the documentation.  
2. Develop a Python script to extract data from the API.  
3. Validate that the Python extraction works correctly.  
4. Implement ingestion into a schema named `DATA_LAKE`.  
5. Create scripts to populate the DWH tables from the raw data in `DATA_LAKE`.
6. Validate the model

---

## API Handling
- Ideally, confirm which column can be used for incremental extraction, preferably a numeric or date column.  
- During Snowflake ingestion, an SSL certificate issue prevented direct API connection.  
- To work around this:
  1. Saved a JSON file per page for each endpoint locally at `./downloads/raw_data/`.  
  2. Uploaded the JSON files into two Snowflake stages: `STAGE_CHARACTERS` and `STAGE_EPISODES` under the `DATA_LAKE` schema.  
  3. Loaded the JSON files from the stages into two raw tables:  
     - `ARTLIST_DB.DATA_LAKE.RAW_CHARACTERS`  
     - `ARTLIST_DB.DATA_LAKE.RAW_EPISODES`  
Both tables contain `PAGE`, `FETCHED_AT`, and `RAW_JSON` columns.  

---

## Data Modeling
Three tables were created in the DWH:  
1. `DIM_CHARACTER`: One row per character from the API.  
2. `DIM_EPISODE`: One row per episode from the API.  
3. `FACT_EPISODE_CHARACTERS`: A bridge / fact-less table connecting episodes and characters.  

**Assumptions and Notes:**  
- Character IDs are unique and distinguish characters, even if names or attributes are identical.  
- If two different IDs refer to the same character, data cleansing would be required to resolve duplicates.  

**Example Analyses:**  
- Which characters appeared in a specific episode?  
- How many episodes did a character appear in?  
- First and last episodes a character appeared in.  

**Surrogate Keys:**  
- Each dimension uses a surrogate key (SK) as the primary key (e.g., `character_sk`, `episode_sk`).  
- SKs decouple the DWH from business keys and protect against changes, duplicates, or composite keys.  
- Fact tables include both the SK and business key (`character_id`, `episode_id`) for traceability.  
- If a character referenced in an episode does not exist in `DIM_CHARACTER`, the SK is set to -1. A dummy record ensures referential integrity.  
- Including the business key in the fact table ensures traceability and helps identify potential data issues from the source.  

---

## Orchestration
- Use a tool like Airflow to execute ETL jobs according to business needs (hourly, daily, weekly).  
- Load dimension tables first, then fact tables.  

---

## Incremental Strategy
- Each table includes `fetched_at` or `sfk_updated` columns to track record insertion.  
- An `ETL_MANAGEMENT` table stores the last load timestamp per table, enabling incremental delta extraction.  

---

## General Comments
- All scripts use the `MERGE` statement to populate tables.  
- If using DBT, YAML configuration handles incremental loads automatically.  
- Without DBT, generic stored procedures were created to:  
  - Create staging tables  
  - Create DWH tables  
  - Retrieve dimension keys  
  - Perform upsert, append, or delete-insert operations  

---

## Files / Structure
- **Python scripts:** Extract and save API data locally.  
- **Snowflake stages:** `STAGE_CHARACTERS` and `STAGE_EPISODES`.  
- **Raw tables:** `RAW_CHARACTERS` and `RAW_EPISODES`.  
- **DWH tables:** `DIM_CHARACTER`, `DIM_EPISODE`, `FACT_EPISODE_CHARACTERS`.  

---

## Steps to Run the Pipeline
1. Execute the `ddls.sql` script to create the database, schemas, and tables.  
2. Run the `main` script to extract data from the API.  
3. Copy the extracted JSON files from `Downloads/raw_data` to their respective Snowflake stages.  
4. Execute the `stages_to_data_lake` script to load the JSON files into the raw tables.  
5. Run the scripts in the following order: `dim_character`, `dim_episode`, and `fact_episode_characters`.  