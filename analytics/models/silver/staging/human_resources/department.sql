{{ config(
    materialized='view',
    alias='view__department'
)}}

select 
  department_id,
  trim(name) as name,
  trim(group_name) as group_name,
  modified_date,
  _extract_date_,
  date
from {{ source('silver_staging__human_resources', 'department') }}