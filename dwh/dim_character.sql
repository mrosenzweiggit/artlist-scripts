
MERGE INTO ARTLIST_DB.DWH.DIM_CHARACTER AS target
USING (
    WITH cte_characters AS (
        SELECT
            value AS character_json
        FROM ARTLIST_DB.DATA_LAKE.RAW_CHARACTERS,
             LATERAL FLATTEN(input => RAW_JSON:results)
        WHERE TRUE
            -- AND character_json:id::INT IN (1)
            AND fetched_at >= '1900-01-01'
    )
    SELECT
        character_json:created::TIMESTAMP       AS api_created,
        character_json:id::INT                  AS character_id,
        character_json:name::STRING             AS name,
        character_json:status::STRING           AS status,
        character_json:species::STRING          AS species,
        character_json:type::STRING             AS type,
        character_json:gender::STRING           AS gender,
        character_json:image::STRING            AS image,
        character_json:url::STRING              AS url,
        character_json:origin.name::STRING      AS origin_name,
        character_json:origin.url::STRING       AS origin_url,
        character_json:location.name::STRING    AS location_name,
        character_json:location.url::STRING     AS location_url,
        CURRENT_TIMESTAMP                       AS sfk_updated
    FROM cte_characters
) AS source
ON target.character_id = source.character_id

-- si ya existe → actualiza
WHEN MATCHED THEN UPDATE SET
    target.api_created = source.api_created,
    target.name              = source.name,
    target.status            = source.status,
    target.species           = source.species,
    target.type              = source.type,
    target.gender            = source.gender,
    target.image             = source.image,
    target.url               = source.url,
    target.origin_name       = source.origin_name,
    target.origin_url        = source.origin_url,
    target.location_name     = source.location_name,
    target.location_url      = source.location_url,
    target.sfk_updated       = source.sfk_updated

-- si no existe → inserta
WHEN NOT MATCHED THEN INSERT (
    character_id,
    name,
    status,
    species,
    type,
    gender,
    image,
    url,
    origin_name,
    origin_url,
    location_name,
    location_url,
    api_created,
    sfk_updated
) VALUES (
    source.character_id,
    source.name,
    source.status,
    source.species,
    source.type,
    source.gender,
    source.image,
    source.url,
    source.origin_name,
    source.origin_url,
    source.location_name,
    source.location_url,
    source.api_created,
    source.sfk_updated
);

select
      ft.character_id
    , dc.name
    , dc.status
from artlist_db.dwh.fact_episode_characters ft
join artlist_db.dwh.dim_character dc on (ft.character_sk = dc.character_sk)
join artlist_db.dwh.dim_episode de on (ft.episode_sk = de.episode_sk)
where true
    and de.episode_name = 'Rickdependence Spray'
;

