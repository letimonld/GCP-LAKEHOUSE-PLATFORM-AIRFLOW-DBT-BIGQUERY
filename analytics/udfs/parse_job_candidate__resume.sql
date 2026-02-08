CREATE OR REPLACE FUNCTION `from-warehouse-to-lakehouse.udfs.parse_employment`(xml_str STRING)
RETURNS ARRAY<STRUCT<
    start_date STRING, end_date STRING, org_name STRING, job_title STRING, 
    responsibility STRING, function_category STRING, industry_category STRING,
    country STRING, state STRING, city STRING
>>
LANGUAGE js AS """
  if (!xml_str) return [];
  const regex = /<ns:Employment>(.*?)<\\/ns:Employment>/gs;
  let match, result = [];
  while ((match = regex.exec(xml_str)) !== null) {
    const b = match[1];
    const get = (t) => { 
        const m = b.match(new RegExp(`<ns:${t}>(.*?)<\\\\/ns:${t}>`)); 
        return m ? m[1].trim() : null; 
    };
    result.push({
      start_date: get('Emp.StartDate'), end_date: get('Emp.EndDate'),
      org_name: get('Emp.OrgName'), job_title: get('Emp.JobTitle'),
      responsibility: get('Emp.Responsibility'), 
      function_category: get('Emp.FunctionCategory'),
      industry_category: get('Emp.IndustryCategory'),
      country: get('Loc.CountryRegion'), state: get('Loc.State'), city: get('Loc.City')
    });
  }
  return result;
""";

CREATE OR REPLACE FUNCTION `from-warehouse-to-lakehouse.udfs.parse_education`(xml_str STRING)
RETURNS ARRAY<STRUCT<
    level STRING, start_date STRING, end_date STRING, degree STRING, 
    major STRING, minor STRING, gpa STRING, gpa_scale STRING, school STRING, 
    country STRING, state STRING, city STRING
>>
LANGUAGE js AS """
  if (!xml_str) return [];
  const regex = /<ns:Education>(.*?)<\\/ns:Education>/gs;
  let match, result = [];
  while ((match = regex.exec(xml_str)) !== null) {
    const b = match[1];
    const get = (t) => { 
        const m = b.match(new RegExp(`<ns:${t}>(.*?)<\\\\/ns:${t}>`)); 
        return m ? m[1].trim() : null; 
    };
    result.push({
      level: get('Edu.Level'), start_date: get('Edu.StartDate'), end_date: get('Edu.EndDate'),
      degree: get('Edu.Degree'), major: get('Edu.Major'), minor: get('Edu.Minor'),
      gpa: get('Edu.GPA'), gpa_scale: get('Edu.GPAScale'), school: get('Edu.School'),
      country: get('Loc.CountryRegion'), state: get('Loc.State'), city: get('Loc.City')
    });
  }
  return result;
""";

CREATE OR REPLACE FUNCTION `from-warehouse-to-lakehouse.udfs.parse_address`(xml_str STRING)
RETURNS ARRAY<STRUCT<
    addr_type STRING, street STRING, postal_code STRING, 
    country STRING, state STRING, city STRING,
    phones ARRAY<STRUCT<tel_type STRING, intl_code STRING, area_code STRING, tel_number STRING>>
>>
LANGUAGE js AS """
  if (!xml_str) return [];
  const addrRegex = /<ns:Address>(.*?)<\\/ns:Address>/gs;
  let match, result = [];
  while ((match = addrRegex.exec(xml_str)) !== null) {
    const b = match[1];
    const get = (t) => { 
        const m = b.match(new RegExp(`<ns:${t}>(.*?)<\\\\/ns:${t}>`)); 
        return m ? m[1].trim() : null; 
    };

    // Parse mảng Telephone lồng bên trong Address
    let phones = [];
    const telRegex = /<ns:Telephone>(.*?)<\\/ns:Telephone>/gs;
    let telMatch;
    while ((telMatch = telRegex.exec(b)) !== null) {
        const t = telMatch[1];
        const getT = (tag) => {
            const m = t.match(new RegExp(`<ns:${tag}>(.*?)<\\\\/ns:${tag}>`));
            return m ? m[1].trim() : null;
        };
        phones.push({
            tel_type: getT('Tel.Type'),
            intl_code: getT('Tel.IntlCode'),
            area_code: getT('Tel.AreaCode'),
            tel_number: getT('Tel.Number')
        });
    }

    result.push({
      addr_type: get('Addr.Type'), street: get('Addr.Street'), postal_code: get('Addr.PostalCode'),
      country: get('Loc.CountryRegion'), state: get('Loc.State'), city: get('Loc.City'),
      phones: phones
    });
  }
  return result;
""";