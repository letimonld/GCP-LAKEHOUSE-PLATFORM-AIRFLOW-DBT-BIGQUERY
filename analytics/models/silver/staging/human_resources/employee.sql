{{
    config(
        materialized='view',
        alias='view__employee'
)
}}

select 
    business_entity_id,
    national_id_number,
    split(login_id, '\\')[safe_offset(1)] as login_user_name,
    organization_node,
    organization_level,
    job_title,
    birth_date,
    case marital_status
        when 'M' then 'Married'
        when 'S' then 'Single'
        else 'Unknown'
    end as marital_status,
    case gender
        when 'M' then 'Male'
        when 'F' then 'Female'
        else 'Unknown'
    end as gender,
    hire_date,
    date_diff(current_date(), hire_date, year) as tenure_years,
    salaried_flag,
    vacation_hours,
    sick_leave_hours,
    current_flag,
    row_guid,
    modified_date,
    _extract_date_,
    date
from {{ source('silver_staging__human_resources', 'employee') }}