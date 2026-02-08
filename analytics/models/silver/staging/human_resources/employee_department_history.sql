{{ config(
    materialized='view',
    alias='view__employee_department_history'
)}}

select 
  business_entity_id,
  department_id,
  shift_id,
  start_date,
  coalesce(end_date, DATE '9999-12-31') as end_date,
  modified_date,
  _extract_date_,
  date
from {{ source('silver_staging__human_resources', 'employee_department_history') }}