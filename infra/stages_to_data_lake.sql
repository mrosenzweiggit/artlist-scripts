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