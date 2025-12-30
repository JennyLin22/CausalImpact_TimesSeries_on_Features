WITH treated_properties AS (
  -- Identify properties that had renovations
  SELECT DISTINCT CC_PROPERTY_ID
  FROM ROC_MLS_DATA.ATTOM.MLS
  WHERE RECORD_DATE_TIME >= '2018-01-01'
    AND BEDROOMS IS NOT NULL
    AND FULL_BATHS IS NOT NULL
  GROUP BY CC_PROPERTY_ID
  HAVING MAX(BEDROOMS) > MIN(BEDROOMS) OR MAX(FULL_BATHS) > MIN(FULL_BATHS)
),

ny_properties AS (
  SELECT
    PROPERTYID,
    SITUSSTATE,
    SITUSCITY,
    SITUSZIP5,
    ROW_NUMBER() OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR DESC) AS rn
  FROM ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR
  WHERE UPPER(SITUSSTATE) IN ('NY', 'NEW YORK')
    AND SITUSZIP5 NOT LIKE '100%'
    AND SITUSZIP5 NOT LIKE '101%'
    AND SITUSZIP5 NOT LIKE '102%'
    AND SITUSZIP5 NOT LIKE '103%'
    AND SITUSZIP5 NOT LIKE '104%'
    AND SITUSZIP5 NOT LIKE '112%'
    AND SITUSZIP5 NOT LIKE '113%'
    AND SITUSZIP5 NOT LIKE '114%'
    AND SITUSZIP5 NOT LIKE '116%'
),

control_candidates AS (
  SELECT
    mls.CC_PROPERTY_ID,
    ny.SITUSCITY,
    ny.SITUSZIP5,
    MIN(mls.RECORD_DATE_TIME) AS first_date,
    MAX(mls.RECORD_DATE_TIME) AS last_date,

    -- Verify features are stable
    MIN(mls.BEDROOMS) AS min_beds,
    MAX(mls.BEDROOMS) AS max_beds,
    MIN(mls.FULL_BATHS) AS min_baths,
    MAX(mls.FULL_BATHS) AS max_baths,

    -- Average characteristics for matching
    AVG(mls.BEDROOMS) AS avg_bedrooms,
    AVG(mls.FULL_BATHS) AS avg_full_baths,
    AVG(mls.GLA_SQFT) AS avg_gla_sqft,

    COUNT(DISTINCT mls.RECORD_DATE_TIME) AS num_snapshots

  FROM ROC_MLS_DATA.ATTOM.MLS mls
  INNER JOIN ny_properties ny
    ON mls.CC_PROPERTY_ID = ny.PROPERTYID
    AND ny.rn = 1

  WHERE mls.RECORD_DATE_TIME >= '2018-01-01'
    AND mls.CC_PROPERTY_ID NOT IN (SELECT CC_PROPERTY_ID FROM treated_properties)
    AND mls.BEDROOMS IS NOT NULL
    AND mls.FULL_BATHS IS NOT NULL
    AND mls.GLA_SQFT IS NOT NULL

  GROUP BY mls.CC_PROPERTY_ID, ny.SITUSCITY, ny.SITUSZIP5

  -- Only keep stable properties (no feature changes)
  HAVING MIN(mls.BEDROOMS) = MAX(mls.BEDROOMS)
    AND MIN(mls.FULL_BATHS) = MAX(mls.FULL_BATHS)
    AND ABS(MIN(mls.GLA_SQFT) - MAX(mls.GLA_SQFT)) < 100
    AND COUNT(DISTINCT mls.RECORD_DATE_TIME) >= 5
)

-- Get all records for control properties with price and DOM data
SELECT
  mls.CC_PROPERTY_ID,
  mls.RECORD_DATE_TIME,
  mls.BEDROOMS,
  mls.FULL_BATHS,
  mls.HALF_BATHS,
  mls.GLA_SQFT,
  mls.ROOMS,
  mls.GARAGE_SPACES,

  -- PRICE COLUMNS - adjust names to match your schema
  mls.LIST_PRICE,           -- Use whatever column exists
  mls.CLOSE_PRICE,          -- Alternative: SOLD_PRICE, SALE_PRICE
  mls.ORIGINAL_LIST_PRICE,  -- If available

  -- TIME-TO-SELL COLUMNS - adjust names to match your schema
  mls.DAYS_ON_MARKET,       -- Alternative: DOM, CDOM
  mls.CUMULATIVE_DAYS_ON_MARKET,  -- If available
  mls.STATUS,               -- Alternative: MLS_STATUS, LISTING_STATUS

  -- DATE COLUMNS for calculating DOM if needed
  mls.LIST_DATE,
  mls.CLOSE_DATE,
  mls.PENDING_DATE,

  -- Location
  cc.SITUSCITY,
  cc.SITUSZIP5,

  -- For matching
  cc.avg_bedrooms,
  cc.avg_full_baths,
  cc.avg_gla_sqft,
  cc.num_snapshots,

  'CONTROL' AS PROPERTY_TYPE

FROM ROC_MLS_DATA.ATTOM.MLS mls
INNER JOIN control_candidates cc
  ON mls.CC_PROPERTY_ID = cc.CC_PROPERTY_ID

WHERE mls.RECORD_DATE_TIME BETWEEN cc.first_date AND cc.last_date

ORDER BY mls.CC_PROPERTY_ID, mls.RECORD_DATE_TIME
LIMIT 10000;