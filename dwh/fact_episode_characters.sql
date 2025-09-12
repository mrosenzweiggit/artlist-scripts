set var_start_time = (select date_from from ARTLIST_DB.MNG.ETL_MANAGEMENT where table_name = 'FACT_CHARACTER_EPISODES');
set var_end_time = (select date_to from ARTLIST_DB.MNG.ETL_MANAGEMENT where table_name = 'FACT_CHARACTER_EPISODES');

MERGE INTO artlist_db.dwh.fact_episode_characters AS tgt
USING (
    WITH cte_episodes AS (
        SELECT
            value AS episode_json,
            TRY_TO_DATE(episode_json:air_date::STRING, 'MMMM DD, YYYY') AS episode_air_date
        FROM artlist_db.data_lake.raw_episodes,
        LATERAL FLATTEN(input => raw_json:results)
        WHERE TRUE
            AND fetched_at between $var_start_time and $var_end_time
    )

    , cte_characters_eposides AS (
        SELECT
            e.episode_json:id::INT              AS episode_id,
            c.value::STRING                     AS character_url,
            e.episode_air_date                  AS episode_air_date,
            SPLIT_PART(character_url, '/', -1)  AS character_id
        FROM cte_episodes e,
        LATERAL FLATTEN(input => e.episode_json:characters) c
    )

    , cte_with_flags AS (
        SELECT
            ifnull(de.episode_sk,-1)    AS episode_sk,
            ce.episode_id               AS episode_id,
            ifnull(dc.character_sk,-1)  AS character_sk,
            dc.character_id             AS character_id,
            ce.character_url            AS character_url,
            ce.episode_air_date         AS episode_air_date,
            CURRENT_TIMESTAMP           AS sfk_updated,
            CASE WHEN ce.episode_air_date = MIN(ce.episode_air_date) OVER (PARTITION BY ce.character_id) THEN 1 ELSE 0 END AS first_appearance_flag,
            CASE WHEN ce.episode_air_date = MAX(ce.episode_air_date) OVER (PARTITION BY ce.character_id) THEN 1 ELSE 0 END AS last_appearance_flag
        FROM cte_characters_eposides ce
        LEFT JOIN artlist_db.dwh.dim_character dc on (dc.character_id = ce.character_id)
        LEFT JOIN artlist_db.dwh.dim_episode de   on (de.episode_id = ce.episode_id)
    )

    SELECT
        episode_sk,
        episode_id,
        character_sk,
        character_id,
        character_url,
        episode_air_date,
        sfk_updated,
        first_appearance_flag,
        last_appearance_flag
    FROM cte_with_flags
) AS src ON tgt.episode_sk = src.episode_sk
        AND tgt.character_sk = src.character_sk
WHEN MATCHED THEN
    UPDATE SET
        tgt.first_appearance_flag   = src.first_appearance_flag,
        tgt.last_appearance_flag    = src.last_appearance_flag,
        tgt.sfk_updated             = src.sfk_updated
WHEN NOT MATCHED THEN
    INSERT (
        episode_sk,
        episode_id,
        character_sk,
        character_id,
        first_appearance_flag,
        last_appearance_flag,
        sfk_updated
    )
    VALUES (
        src.episode_sk,
        src.episode_id,
        src.character_sk,
        src.character_id,
        src.first_appearance_flag,
        src.last_appearance_flag,
        src.sfk_updated
    );


select count(distinct character_sk), count(distinct episode_sk) from artlist_db.dwh.fact_episode_characters;
