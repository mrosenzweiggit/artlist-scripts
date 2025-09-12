
--**************************************
-- Create database and schemas
--**************************************
CREATE OR REPLACE DATABASE artlist_db;
USE DATABASE artlist_db;
CREATE OR REPLACE SCHEMA data_lake;
CREATE OR REPLACE SCHEMA dwh;
CREATE OR REPLACE SCHEMA mng;

-- Create stages
CREATE STAGE ARTLIST_DB.DATA_LAKE.STAGE_CHARACTERS
	DIRECTORY = ( ENABLE = true );
CREATE STAGE ARTLIST_DB.DATA_LAKE.STAGE_EPISODES
	DIRECTORY = ( ENABLE = true );


--**************************************
--       Create data lake tables
--**************************************
-- create data lake table to store 'characters' JSON pages
create or replace TABLE ARTLIST_DB.DATA_LAKE.RAW_CHARACTERS (
	PAGE NUMBER(38,0) NOT NULL,
	FETCHED_AT TIMESTAMP_LTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	RAW_JSON VARIANT
);

-- create data lake table to store 'episdes' JSON
create or replace TABLE ARTLIST_DB.DATA_LAKE.RAW_EPISODES (
	PAGE NUMBER(38,0) NOT NULL,
	FETCHED_AT TIMESTAMP_LTZ(9) DEFAULT CURRENT_TIMESTAMP(),
	RAW_JSON VARIANT
);

--**************************************
-- Move data from stages to datalake
--**************************************
COPY INTO ARTLIST_DB.DATA_LAKE.RAW_EPISODES (page,fetched_at, raw_json)
FROM (
    SELECT TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME, '\\d+')) AS page,CURRENT_TIMESTAMP AS FETCHED_AT, PARSE_JSON($1) AS raw_json
    FROM @stage_episodes
)
FILE_FORMAT = (TYPE = 'JSON')
ON_ERROR = 'CONTINUE';


COPY INTO ARTLIST_DB.DATA_LAKE.RAW_CHARACTERS (page, fetched_at, raw_json)
FROM (
    SELECT TO_NUMBER(REGEXP_SUBSTR(METADATA$FILENAME, '\\d+')) AS page,CURRENT_TIMESTAMP AS FETCHED_AT, PARSE_JSON($1) AS raw_json
    FROM @STAGE_CHARACTERS
)
FILE_FORMAT = (TYPE = 'JSON')
ON_ERROR = 'CONTINUE';


--**************************************
--        Create DWH tables
--**************************************
CREATE OR REPLACE TABLE ARTLIST_DB.DWH.DIM_CHARACTER (
    character_sk INT AUTOINCREMENT START 1 INCREMENT 1,
    character_id INT,
    name STRING NOT NULL,
    status STRING,
    species STRING,
    type STRING,
    gender STRING,
    image STRING,
    url STRING,
    origin_name STRING,
    origin_url STRING,
    location_name STRING,
    location_url STRING,
    api_created TIMESTAMP_NTZ,
    sfk_updated TIMESTAMP_NTZ
);


CREATE OR REPLACE TABLE ARTLIST_DB.DWH.DIM_EPISODE (
    episode_sk INT AUTOINCREMENT START 1 INCREMENT 1,
    episode_id INT,
    episode_name STRING,
    episode_air_date STRING,
    episode_code STRING,
    episode_url STRING,
    api_created TIMESTAMP_NTZ,
    sfk_updated TIMESTAMP_NTZ
);

-- Tabla puente para relación muchos a muchos personajes-episodios
CREATE OR REPLACE TABLE artlist_db.dwh.fact_episode_characters (
    episode_sk             INT NOT NULL,
    episode_id             INT NOT NULL,
    character_sk           INT NOT NULL,
    character_id           INT NOT NULL,
    first_appearance_flag  BOOLEAN DEFAULT FALSE,
    last_appearance_flag   BOOLEAN DEFAULT FALSE,
    sfk_updated            TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);