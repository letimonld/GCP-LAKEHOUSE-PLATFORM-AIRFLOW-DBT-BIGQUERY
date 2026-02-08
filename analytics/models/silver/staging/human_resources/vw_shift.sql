{{ config(
    materialized='view',
    alias='view__shift'
) }}

SELECT
    shift_id,
    name,
    SAFE_CAST(start_time AS TIME) AS start_time,
    SAFE_CAST(end_time AS TIME) AS end_time,
    modified_date,
    _extract_date_,
    date
FROM {{ source('silver_staging__human_resources', 'vw_shift') }}