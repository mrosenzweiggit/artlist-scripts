
MERGE INTO ARTLIST_DB.DWH.DIM_EPISODE AS target
USING (
    WITH cte_episodes AS (
        SELECT
            value AS episode_json
        FROM ARTLIST_DB.DATA_LAKE.RAW_EPISODES,
             LATERAL FLATTEN(input => RAW_JSON:results)
        WHERE TRUE
            -- AND episode_json:id::INT in (41)
            AND fetched_at >= '1900-01-01'
    )
    SELECT
        episode_json:id::INT         AS episode_id,
        episode_json:name::STRING    AS episode_name,
        COALESCE(
            TRY_TO_DATE(episode_json:air_date::STRING, 'MMMM DD, YYYY'),
            DATE '1900-01-01'
        ) AS episode_air_date,
        episode_json:episode::STRING AS episode_code,
        episode_json:url::STRING     AS episode_url,
        -- c.value::STRING              AS character_url,
        episode_json:created::TIMESTAMP     AS api_created,
        CURRENT_TIMESTAMP            AS sfk_updated
    FROM cte_episodes,
    -- LATERAL FLATTEN(input => episode_json:characters) c
) AS src
ON target.episode_id = src.episode_id
WHEN MATCHED THEN
    UPDATE SET
        episode_name     = src.episode_name,
        episode_air_date = src.episode_air_date,
        episode_code     = src.episode_code,
        episode_url      = src.episode_url,
        api_created      = src.api_created,
        sfk_updated      = src.sfk_updated
WHEN NOT MATCHED THEN
    INSERT (
        episode_id,
        episode_name,
        episode_air_date,
        episode_code,
        episode_url,
        -- character_url,
        api_created,
        sfk_updated
    )
    VALUES (
        src.episode_id,
        src.episode_name,
        src.episode_air_date,
        src.episode_code,
        src.episode_url,
        -- src.character_url,
        api_created,
        src.sfk_updated
    );


    select *
    from artlist_db.dwh.dim_episode;