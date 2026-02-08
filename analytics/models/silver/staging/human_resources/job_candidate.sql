{{ config(
    materialized='view',
    alias='view__job_candidate'
) }}

WITH raw_cleaned AS (
    SELECT 
        job_candidate_id,
        business_entity_id,
        regexp_replace(safe_convert_bytes_to_string(resume), r"^b'|'$", "") as resume_xml,
        modified_date,
        _extract_date_,
        date
    FROM {{ source('silver_staging__human_resources', 'job_candidate') }}
),

extracted_data AS (
    SELECT
        *,
        -- Name fields (Flattened)
        coalesce(regexp_extract(resume_xml, r"(?s)<ns:Name\.Prefix>(.*?)</ns:Name\.Prefix>"), '') as salutation,
        coalesce(regexp_extract(resume_xml, r"(?s)<ns:Name\.First>(.*?)</ns:Name\.First>"), '') as first_name,
        coalesce(regexp_extract(resume_xml, r"(?s)<ns:Name\.Middle>(.*?)</ns:Name\.Middle>"), '') as middle_name,
        coalesce(regexp_extract(resume_xml, r"(?s)<ns:Name\.Last>(.*?)</ns:Name\.Last>"), '') as last_name,
        
        -- Skills Summary
        regexp_replace(regexp_extract(resume_xml, r"(?s)<ns:Skills>(.*?)</ns:Skills>"), r"[\n\r\t]+", " ") as skills_summary,
        
        -- Parsed complex fields using UDFs
        `{{ target.project }}.udfs.parse_employment`(resume_xml) as emp_raw,
        `{{ target.project }}.udfs.parse_education`(resume_xml) as edu_raw,
        `{{ target.project }}.udfs.parse_address`(resume_xml) as addr_raw,
        `{{ target.project }}.udfs.parse_personal_telephone`(resume_xml) as personal_phones_raw,
        
        regexp_extract(resume_xml, r"(?s)<ns:EMail>(.*?)</ns:EMail>") as email,
        regexp_extract(resume_xml, r"(?s)<ns:WebSite>(.*?)</ns:WebSite>") as website
    FROM raw_cleaned
)

SELECT
    -- Remove raw and intermediate columns to avoid duplication
    * EXCEPT(resume_xml, emp_raw, edu_raw, addr_raw, personal_phones_raw),
    
    -- CAST DATE for Employment
    ARRAY(
        SELECT AS STRUCT * REPLACE(
            safe_cast(substring(start_date, 1, 10) as DATE) as start_date, 
            safe_cast(substring(end_date, 1, 10) as DATE) as end_date
        ) FROM UNNEST(emp_raw)
    ) as employment_history,
    
    -- CAST DATE for Education
    ARRAY(
        SELECT AS STRUCT * REPLACE(
            safe_cast(substring(start_date, 1, 10) as DATE) as start_date, 
            safe_cast(substring(end_date, 1, 10) as DATE) as end_date
        ) FROM UNNEST(edu_raw)
    ) as education_history,

    -- Rename clean columns for Address and Personal Phones
    addr_raw as addresses,
    personal_phones_raw as personal_phones
FROM extracted_data