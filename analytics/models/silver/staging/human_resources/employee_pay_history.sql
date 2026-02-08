{{config(
    materialized='view',
    alias='view__employee_pay_history'
)}}

select
    business_entity_id,
    cast(rate_change_date as DATE) as rate_change_date,
    rate,
    pay_frequency,
    modified_date,
    _extract_date_
    date    
from {{ source('silver_staging__human_resources', 'employee_pay_history') }}