WITH base AS (
  SELECT
    PROPERTYID,
    SITUSSTATE,
    SITUSCITY,
    SITUSZIP5,
    RECORDINGDATE,
    SALEAMT
  FROM roc_public_record_data."DATATREE"."RETRANSACTION"
  WHERE (UPPER(SITUSSTATE) = 'NY' OR UPPER(SITUSSTATE) = 'NEW YORK')
    AND SITUSZIP5 IN (
      -- Original 25 ZIPs
      '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
      '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
      '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950',

      -- Additional 25 ZIPs
      '10562', '10601', '10583', '10701', '10533',
      '12203', '12110', '12189', '12208', '12302',
      '14617', '14618', '14626', '14534', '14450',
      '13210', '13224', '13088', '13215',
      '14221', '14226', '14072', '14127',
      '11733', '11758', '11772'
    )
    AND RECORDINGDATE >= '2005-01-01'
    AND RECORDINGDATE <= '2025-12-31'
    AND PROPERTYID IS NOT NULL
    AND SALEAMT IS NOT NULL
),
properties_with_multiple_sales AS (
  SELECT PROPERTYID
  FROM base
  GROUP BY PROPERTYID
  HAVING COUNT(DISTINCT SALEAMT) > 4
),
property_features AS (
  SELECT DISTINCT
    PROPERTYID,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR = (
    SELECT MAX(MARKETYEAR)
    FROM roc_public_record_data."DATATREE"."ASSESSOR" a2
    WHERE a2.PROPERTYID = ASSESSOR.PROPERTYID
  )
),
unique_properties AS (
  SELECT DISTINCT
    p.PROPERTYID,
    pf.BEDROOMS,
    pf.BATHFULL,
    pf.BATHSPARTIALNBR
  FROM properties_with_multiple_sales p
  LEFT JOIN property_features pf ON p.PROPERTYID = pf.PROPERTYID
)

-- Count by Bedrooms
SELECT
  'Bedrooms' AS category,
  COALESCE(BEDROOMS, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BEDROOMS

UNION ALL

-- Count by Full Bathrooms
SELECT
  'Full Bathrooms' AS category,
  COALESCE(BATHFULL, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BATHFULL

UNION ALL

-- Count by Partial Bathrooms
SELECT
  'Partial Bathrooms' AS category,
  COALESCE(BATHSPARTIALNBR, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BATHSPARTIALNBR

-- ORDER BY goes at the very end, after all UNIONs
ORDER BY category, level;

-------

WITH base AS (
  SELECT
    PROPERTYID,
    SITUSSTATE,
    SITUSCITY,
    SITUSZIP5,
    RECORDINGDATE,
    SALEAMT
  FROM roc_public_record_data."DATATREE"."RETRANSACTION"
  WHERE (
      -- All of New York excluding NYC
      (UPPER(SITUSSTATE) IN ('NY', 'NEW YORK')
       AND SITUSZIP5 NOT LIKE '100%'  -- Manhattan
       AND SITUSZIP5 NOT LIKE '101%'  -- Manhattan
       AND SITUSZIP5 NOT LIKE '102%'  -- Manhattan
       AND SITUSZIP5 NOT LIKE '103%'  -- Staten Island, Bronx
       AND SITUSZIP5 NOT LIKE '104%'  -- Bronx
       AND SITUSZIP5 NOT LIKE '112%'  -- Brooklyn
       AND SITUSZIP5 NOT LIKE '113%'  -- Queens
       AND SITUSZIP5 NOT LIKE '114%'  -- Queens
       AND SITUSZIP5 NOT LIKE '116%'  -- Queens
      )
      OR
      -- All of Ohio
      UPPER(SITUSSTATE) IN ('OH', 'OHIO')
    )
    AND RECORDINGDATE >= '2005-01-01'
    AND RECORDINGDATE <= '2025-12-31'
    AND PROPERTYID IS NOT NULL
    AND SALEAMT IS NOT NULL
),
properties_with_multiple_sales AS (
  SELECT PROPERTYID
  FROM base
  GROUP BY PROPERTYID
  HAVING COUNT(DISTINCT SALEAMT) > 4
),
property_features AS (
  SELECT DISTINCT
    PROPERTYID,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR = (
    SELECT MAX(MARKETYEAR)
    FROM roc_public_record_data."DATATREE"."ASSESSOR" a2
    WHERE a2.PROPERTYID = ASSESSOR.PROPERTYID
  )
),
unique_properties AS (
  SELECT DISTINCT
    p.PROPERTYID,
    pf.BEDROOMS,
    pf.BATHFULL,
    pf.BATHSPARTIALNBR
  FROM properties_with_multiple_sales p
  LEFT JOIN property_features pf ON p.PROPERTYID = pf.PROPERTYID
)

SELECT
  'Bedrooms' AS category,
  COALESCE(BEDROOMS, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BEDROOMS

UNION ALL

SELECT
  'Full Bathrooms' AS category,
  COALESCE(BATHFULL, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BATHFULL

UNION ALL

SELECT
  'Partial Bathrooms' AS category,
  COALESCE(BATHSPARTIALNBR, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BATHSPARTIALNBR

ORDER BY category, level;