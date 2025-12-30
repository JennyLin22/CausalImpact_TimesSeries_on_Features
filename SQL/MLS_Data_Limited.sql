WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) as census_tract,

        -- Education
        SUM(a."B15002e1") AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
             THEN (SUM(a."B15002e15" + a."B15002e32") / SUM(a."B15002e1")) * 100
             ELSE NULL END AS pct_bachelors_degree,

        -- Race/Ethnicity
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
             THEN (SUM(c."B03002e3") / SUM(c."B03002e1")) * 100
             ELSE NULL END AS pct_white,

        -- Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,

        -- Household Income
        AVG(income."B19013e1") AS median_household_income,

        -- Housing characteristics
        AVG(housing_value."B25077e1") AS median_home_value,
        AVG(rent."B25064e1") AS median_gross_rent,
        SUM(tenure."B25003e2") AS owner_occupied_units,
        SUM(tenure."B25003e3") AS renter_occupied_units,
        CASE WHEN SUM(tenure."B25003e1") > 0
             THEN (SUM(tenure."B25003e2") / SUM(tenure."B25003e1")) * 100
             ELSE NULL END AS pct_owner_occupied,
        SUM(occupancy."B25002e2") AS occupied_units,
        SUM(occupancy."B25002e3") AS vacant_units,

        -- Demographics
        AVG(age."B01002e1") AS median_age,

        -- Employment
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN SUM(employment."B23025e3" + employment."B23025e5") > 0
             THEN (SUM(employment."B23025e5") / SUM(employment."B23025e3" + employment."B23025e5")) * 100
             ELSE NULL END AS unemployment_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" AS a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" AS c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" AS d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" AS income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS housing_value
        ON a.CENSUS_BLOCK_GROUP = housing_value.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS rent
        ON a.CENSUS_BLOCK_GROUP = rent.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS tenure
        ON a.CENSUS_BLOCK_GROUP = tenure.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS occupancy
        ON a.CENSUS_BLOCK_GROUP = occupancy.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" AS age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" AS employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP

    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) = '37'  -- NC state FIPS code
    GROUP BY LEFT(a.CENSUS_BLOCK_GROUP, 11)
)

SELECT
    p.PROPERTYID as property_id,
    p.CURRENTSALESPRICE as sale_price,
    p.CURRENTSALERECORDINGDATE as sale_date,
    p.YEARBUILT as year_built,
    p.EFFECTIVEYEARBUILT as effective_year_built,
    p.SITUSLATITUDE as latitude,
    p.SITUSLONGITUDE as longitude,
    p.SITUSSTATE as state,
    p.SITUSCITY as city,
    p.SITUSZIP5 as zip,
    p.SITUSCENSUSTRACT as census_tract,
    p.SUMLIVINGAREASQFT as living_sqft,
    p.LOTSIZESQFT as lot_sqft,
    p.BEDROOMS as bedrooms,
    p.BATHFULL as full_baths,
    p.BATHSPARTIALNBR as half_baths,
    p.GARAGEPARKINGNBR as garage_spaces,
    p.FIREPLACECODE as fireplace_code,

    -- Census Demographics (Education)
    c.total_population_25plus,
    c.male_bachelors_degree,
    c.female_bachelors_degree,
    c.pct_bachelors_degree,

    -- Census Demographics (Population)
    c.total_population,
    c.non_hispanic_white_population,
    c.pct_white,

    -- Census Demographics (Income)
    c.median_earnings_total,
    c.median_earnings_male,
    c.median_earnings_female,
    c.median_household_income,

    -- Census Demographics (Housing)
    c.median_home_value,
    c.median_gross_rent,
    c.owner_occupied_units,
    c.renter_occupied_units,
    c.pct_owner_occupied,
    c.occupied_units,
    c.vacant_units,

    -- Census Demographics (Age & Employment)
    c.median_age,
    c.civilian_employed,
    c.civilian_unemployed,
    c.unemployment_rate,

    -- Election Data
    v.county_name,
    v.county_fips,
    v.votes_gop,
    v.votes_dem,
    v.total_votes,
    v.per_gop,
    v.per_dem,
    v.per_point_diff,
    v.dem_margin,
    v.rep_margin

FROM
    roc_public_record_data."DATATREE"."ASSESSOR" p

LEFT JOIN
    census_data c
    ON p.SITUSCENSUSTRACT = c.census_tract

LEFT JOIN
    "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
    ON LEFT(p.FIPS, 5) = CAST(v.county_fips AS VARCHAR)

WHERE
    p.SITUSSTATE = 'nc'
    AND p.CURRENTSALESPRICE IS NOT NULL
    AND p.SUMLIVINGAREASQFT IS NOT NULL
    AND p.LOTSIZESQFT IS NOT NULL
    AND p.SITUSLATITUDE IS NOT NULL
    AND p.SITUSLONGITUDE IS NOT NULL;

----------
WITH census_data AS (
    SELECT
        a.CENSUS_BLOCK_GROUP,
        a.GEOMETRY as census_geometry,  -- Keep geometry for spatial join
        LEFT(a.CENSUS_BLOCK_GROUP, 11) as census_tract,

        -- Education
        a."B15002e1" AS total_population_25plus,
        a."B15002e15" AS male_bachelors_degree,
        a."B15002e32" AS female_bachelors_degree,
        CASE WHEN a."B15002e1" > 0
             THEN ((a."B15002e15" + a."B15002e32") / a."B15002e1") * 100
             ELSE NULL END AS pct_bachelors_degree,

        -- Race/Ethnicity
        c."B03002e1" AS total_population,
        c."B03002e3" AS non_hispanic_white_population,
        CASE WHEN c."B03002e1" > 0
             THEN (c."B03002e3" / c."B03002e1") * 100
             ELSE NULL END AS pct_white,

        -- Earnings
        d."B20002e1" AS median_earnings_total,
        d."B20002e2" AS median_earnings_male,
        d."B20002e3" AS median_earnings_female,

        -- Household Income
        income."B19013e1" AS median_household_income,

        -- Housing characteristics
        housing_value."B25077e1" AS median_home_value,
        rent."B25064e1" AS median_gross_rent,
        tenure."B25003e2" AS owner_occupied_units,
        tenure."B25003e3" AS renter_occupied_units,
        CASE WHEN tenure."B25003e1" > 0
             THEN (tenure."B25003e2" / tenure."B25003e1") * 100
             ELSE NULL END AS pct_owner_occupied,
        occupancy."B25002e2" AS occupied_units,
        occupancy."B25002e3" AS vacant_units,

        -- Demographics
        age."B01002e1" AS median_age,

        -- Employment
        employment."B23025e3" AS civilian_employed,
        employment."B23025e5" AS civilian_unemployed,
        CASE WHEN (employment."B23025e3" + employment."B23025e5") > 0
             THEN (employment."B23025e5" / (employment."B23025e3" + employment."B23025e5")) * 100
             ELSE NULL END AS unemployment_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" AS a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" AS c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" AS d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" AS income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS housing_value
        ON a.CENSUS_BLOCK_GROUP = housing_value.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS rent
        ON a.CENSUS_BLOCK_GROUP = rent.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS tenure
        ON a.CENSUS_BLOCK_GROUP = tenure.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS occupancy
        ON a.CENSUS_BLOCK_GROUP = occupancy.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" AS age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" AS employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP

    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) = '37'  -- NC state FIPS code
)

SELECT
    p.PROPERTYID as property_id,
    p.CURRENTSALESPRICE as sale_price,
    p.CURRENTSALERECORDINGDATE as sale_date,
    p.YEARBUILT as year_built,
    p.EFFECTIVEYEARBUILT as effective_year_built,
    p.SITUSLATITUDE as latitude,
    p.SITUSLONGITUDE as longitude,
    p.SITUSSTATE as state,
    p.SITUSCITY as city,
    p.SITUSZIP5 as zip,
    p.SITUSCENSUSTRACT as census_tract_original,
    c.CENSUS_BLOCK_GROUP as census_block_group_matched,
    c.census_tract as census_tract_matched,
    p.SUMLIVINGAREASQFT as living_sqft,
    p.LOTSIZESQFT as lot_sqft,
    p.BEDROOMS as bedrooms,
    p.BATHFULL as full_baths,
    p.BATHSPARTIALNBR as half_baths,
    p.GARAGEPARKINGNBR as garage_spaces,
    p.FIREPLACECODE as fireplace_code,

    -- Census Demographics (Education)
    c.total_population_25plus,
    c.male_bachelors_degree,
    c.female_bachelors_degree,
    c.pct_bachelors_degree,

    -- Census Demographics (Population)
    c.total_population,
    c.non_hispanic_white_population,
    c.pct_white,

    -- Census Demographics (Income)
    c.median_earnings_total,
    c.median_earnings_male,
    c.median_earnings_female,
    c.median_household_income,

    -- Census Demographics (Housing)
    c.median_home_value,
    c.median_gross_rent,
    c.owner_occupied_units,
    c.renter_occupied_units,
    c.pct_owner_occupied,
    c.occupied_units,
    c.vacant_units,

    -- Census Demographics (Age & Employment)
    c.median_age,
    c.civilian_employed,
    c.civilian_unemployed,
    c.unemployment_rate,

    -- Election Data
    v.county_name,
    v.county_fips,
    v.votes_gop,
    v.votes_dem,
    v.total_votes,
    v.per_gop,
    v.per_dem,
    v.per_point_diff,
    v.dem_margin,
    v.rep_margin

FROM
    roc_public_record_data."DATATREE"."ASSESSOR" p

-- SPATIAL JOIN: Match property to census block group by lat/long
LEFT JOIN
    census_data c
    ON ST_CONTAINS(c.census_geometry, TO_GEOMETRY(ST_POINT(p.SITUSLONGITUDE, p.SITUSLATITUDE)))

LEFT JOIN
    "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
    ON LEFT(p.FIPS, 5) = CAST(v.county_fips AS VARCHAR)

WHERE
    p.SITUSSTATE = 'nc'
    AND p.CURRENTSALESPRICE IS NOT NULL
    AND p.SUMLIVINGAREASQFT IS NOT NULL
    AND p.LOTSIZESQFT IS NOT NULL
    AND p.SITUSLATITUDE IS NOT NULL
    AND p.SITUSLONGITUDE IS NOT NULL;

------

-- Check the structure and sample data from NEIGHBORHOODS_LEV_2
SELECT TOP 5 *
FROM ATTOM_HOUSE_IQ_SHARE.DELIVERY.NEIGHBORHOODS_LEV_2
WHERE STATE = 'NC';

-- Check the structure and sample data from COMMUNITY_INFO_NEIGHBORHOODS_LEV_2
SELECT TOP 5 *
FROM ATTOM_HOUSE_IQ_SHARE.DELIVERY.COMMUNITY_INFO_NEIGHBORHOODS_LEV_2;

-- Also check the column names specifically
DESCRIBE TABLE ATTOM_HOUSE_IQ_SHARE.DELIVERY.NEIGHBORHOODS_LEV_2;
DESCRIBE TABLE ATTOM_HOUSE_IQ_SHARE.DELIVERY.COMMUNITY_INFO_NEIGHBORHOODS_LEV_2;

-- Check the format of census tracts in your property data
-- Check the format of census tracts in your property data
SELECT
    p.SITUSCENSUSTRACT,
    LENGTH(p.SITUSCENSUSTRACT) as tract_length,
    LEFT(p.SITUSCENSUSTRACT, 11) as first_11_chars,
    '37001950100' as expected_format_example
FROM roc_public_record_data."DATATREE"."ASSESSOR" p
WHERE p.SITUSSTATE = 'nc'
  AND p.SITUSCENSUSTRACT IS NOT NULL
LIMIT 20;

-------

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) as census_tract,

        -- Education
        SUM(a."B15002e1") AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
             THEN (SUM(a."B15002e15" + a."B15002e32") / SUM(a."B15002e1")) * 100
             ELSE NULL END AS pct_bachelors_degree,

        -- Race/Ethnicity
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
             THEN (SUM(c."B03002e3") / SUM(c."B03002e1")) * 100
             ELSE NULL END AS pct_white,

        -- Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,

        -- Household Income
        AVG(income."B19013e1") AS median_household_income,

        -- Housing characteristics
        AVG(housing_value."B25077e1") AS median_home_value,
        AVG(rent."B25064e1") AS median_gross_rent,
        SUM(tenure."B25003e2") AS owner_occupied_units,
        SUM(tenure."B25003e3") AS renter_occupied_units,
        CASE WHEN SUM(tenure."B25003e1") > 0
             THEN (SUM(tenure."B25003e2") / SUM(tenure."B25003e1")) * 100
             ELSE NULL END AS pct_owner_occupied,
        SUM(occupancy."B25002e2") AS occupied_units,
        SUM(occupancy."B25002e3") AS vacant_units,

        -- Demographics
        AVG(age."B01002e1") AS median_age,

        -- Employment
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN SUM(employment."B23025e3" + employment."B23025e5") > 0
             THEN (SUM(employment."B23025e5") / SUM(employment."B23025e3" + employment."B23025e5")) * 100
             ELSE NULL END AS unemployment_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" AS a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" AS c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" AS d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" AS income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS housing_value
        ON a.CENSUS_BLOCK_GROUP = housing_value.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS rent
        ON a.CENSUS_BLOCK_GROUP = rent.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS tenure
        ON a.CENSUS_BLOCK_GROUP = tenure.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS occupancy
        ON a.CENSUS_BLOCK_GROUP = occupancy.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" AS age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" AS employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP

    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) = '37'  -- NC state FIPS code
    GROUP BY LEFT(a.CENSUS_BLOCK_GROUP, 11)
)

SELECT
    p.PROPERTYID as property_id,
    p.CURRENTSALESPRICE as sale_price,
    p.CURRENTSALERECORDINGDATE as sale_date,
    p.YEARBUILT as year_built,
    p.EFFECTIVEYEARBUILT as effective_year_built,
    p.SITUSLATITUDE as latitude,
    p.SITUSLONGITUDE as longitude,
    p.SITUSSTATE as state,
    p.SITUSCITY as city,
    p.SITUSZIP5 as zip,
    p.SITUSCENSUSTRACT as census_tract_original,
    c.census_tract as census_tract_matched,
    p.SUMLIVINGAREASQFT as living_sqft,
    p.LOTSIZESQFT as lot_sqft,
    p.BEDROOMS as bedrooms,
    p.BATHFULL as full_baths,
    p.BATHSPARTIALNBR as half_baths,
    p.GARAGEPARKINGNBR as garage_spaces,
    p.FIREPLACECODE as fireplace_code,

    -- Census Demographics (Education)
    c.total_population_25plus,
    c.male_bachelors_degree,
    c.female_bachelors_degree,
    c.pct_bachelors_degree,

    -- Census Demographics (Population)
    c.total_population,
    c.non_hispanic_white_population,
    c.pct_white,

    -- Census Demographics (Income)
    c.median_earnings_total,
    c.median_earnings_male,
    c.median_earnings_female,
    c.median_household_income,

    -- Census Demographics (Housing)
    c.median_home_value,
    c.median_gross_rent,
    c.owner_occupied_units,
    c.renter_occupied_units,
    c.pct_owner_occupied,
    c.occupied_units,
    c.vacant_units,

    -- Census Demographics (Age & Employment)
    c.median_age,
    c.civilian_employed,
    c.civilian_unemployed,
    c.unemployment_rate,

    -- Election Data
    v.county_name,
    v.county_fips,
    v.votes_gop,
    v.votes_dem,
    v.total_votes,
    v.per_gop,
    v.per_dem,
    v.per_point_diff,
    v.dem_margin,
    v.rep_margin

FROM
    roc_public_record_data."DATATREE"."ASSESSOR" p

LEFT JOIN
    census_data c
    ON LEFT(p.FIPS, 5) || p.SITUSCENSUSTRACT = c.census_tract  -- FIX: Concatenate state+county+tract

LEFT JOIN
    "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
    ON LEFT(p.FIPS, 5) = CAST(v.county_fips AS VARCHAR)

WHERE
    p.SITUSSTATE = 'nc'
    AND p.CURRENTSALESPRICE IS NOT NULL
    AND p.SUMLIVINGAREASQFT IS NOT NULL
    AND p.LOTSIZESQFT IS NOT NULL
    AND p.SITUSLATITUDE IS NOT NULL
    AND p.SITUSLONGITUDE IS NOT NULL;

-----------
WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) as census_tract,

        -- Education
        SUM(a."B15002e1") AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
             THEN (SUM(a."B15002e15" + a."B15002e32") / SUM(a."B15002e1")) * 100
             ELSE NULL END AS pct_bachelors_degree,

        -- Race/Ethnicity
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
             THEN (SUM(c."B03002e3") / SUM(c."B03002e1")) * 100
             ELSE NULL END AS pct_white,

        -- Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,

        -- Household Income
        AVG(income."B19013e1") AS median_household_income,

        -- Housing characteristics
        AVG(housing_value."B25077e1") AS median_home_value,
        AVG(rent."B25064e1") AS median_gross_rent,
        SUM(tenure."B25003e2") AS owner_occupied_units,
        SUM(tenure."B25003e3") AS renter_occupied_units,
        CASE WHEN SUM(tenure."B25003e1") > 0
             THEN (SUM(tenure."B25003e2") / SUM(tenure."B25003e1")) * 100
             ELSE NULL END AS pct_owner_occupied,
        SUM(occupancy."B25002e2") AS occupied_units,
        SUM(occupancy."B25002e3") AS vacant_units,

        -- Demographics
        AVG(age."B01002e1") AS median_age,

        -- Employment
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN SUM(employment."B23025e3" + employment."B23025e5") > 0
             THEN (SUM(employment."B23025e5") / SUM(employment."B23025e3" + employment."B23025e5")) * 100
             ELSE NULL END AS unemployment_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" AS a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" AS c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" AS d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" AS income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS housing_value
        ON a.CENSUS_BLOCK_GROUP = housing_value.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS rent
        ON a.CENSUS_BLOCK_GROUP = rent.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS tenure
        ON a.CENSUS_BLOCK_GROUP = tenure.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS occupancy
        ON a.CENSUS_BLOCK_GROUP = occupancy.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" AS age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" AS employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP

    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) IN ('37', '36', '39')  -- NC, NY, OH state FIPS codes
    GROUP BY LEFT(a.CENSUS_BLOCK_GROUP, 11)
)

SELECT
    p.PROPERTYID as property_id,
    p.CURRENTSALESPRICE as sale_price,
    p.CURRENTSALERECORDINGDATE as sale_date,
    p.YEARBUILT as year_built,
    p.EFFECTIVEYEARBUILT as effective_year_built,
    p.SITUSLATITUDE as latitude,
    p.SITUSLONGITUDE as longitude,
    p.SITUSSTATE as state,
    p.SITUSCITY as city,
    p.SITUSZIP5 as zip,
    p.SITUSCENSUSTRACT as census_tract_original,
    c.census_tract as census_tract_matched,
    p.SUMLIVINGAREASQFT as living_sqft,
    p.LOTSIZESQFT as lot_sqft,
    p.BEDROOMS as bedrooms,
    p.BATHFULL as full_baths,
    p.BATHSPARTIALNBR as half_baths,
    p.GARAGEPARKINGNBR as garage_spaces,
    p.FIREPLACECODE as fireplace_code,

    -- Census Demographics (Education)
    c.total_population_25plus,
    c.male_bachelors_degree,
    c.female_bachelors_degree,
    c.pct_bachelors_degree,

    -- Census Demographics (Population)
    c.total_population,
    c.non_hispanic_white_population,
    c.pct_white,

    -- Census Demographics (Income)
    c.median_earnings_total,
    c.median_earnings_male,
    c.median_earnings_female,
    c.median_household_income,

    -- Census Demographics (Housing)
    c.median_home_value,
    c.median_gross_rent,
    c.owner_occupied_units,
    c.renter_occupied_units,
    c.pct_owner_occupied,
    c.occupied_units,
    c.vacant_units,

    -- Census Demographics (Age & Employment)
    c.median_age,
    c.civilian_employed,
    c.civilian_unemployed,
    c.unemployment_rate,

    -- Election Data
    v.county_name,
    v.county_fips,
    v.votes_gop,
    v.votes_dem,
    v.total_votes,
    v.per_gop,
    v.per_dem,
    v.per_point_diff,
    v.dem_margin,
    v.rep_margin

FROM
    roc_public_record_data."DATATREE"."ASSESSOR" p

LEFT JOIN
    census_data c
    ON LEFT(p.FIPS, 5) || p.SITUSCENSUSTRACT = c.census_tract

LEFT JOIN
    "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
    ON LEFT(p.FIPS, 5) = CAST(v.county_fips AS VARCHAR)

WHERE
    (
        -- NC around Raleigh (Wake County and nearby counties in Triangle area)
        (p.SITUSSTATE = 'nc' AND LEFT(p.FIPS, 5) IN ('37183', '37063', '37101', '37069', '37135'))  -- Wake, Durham, Johnston, Franklin, Orange
        OR
        -- New York excluding NYC (Bronx, Kings, New York, Queens, Richmond)
        (p.SITUSSTATE = 'ny' AND LEFT(p.FIPS, 5) NOT IN ('36005', '36047', '36061', '36081', '36085'))
        OR
        -- All of Ohio
        (p.SITUSSTATE = 'oh')
    )
    AND p.CURRENTSALESPRICE IS NOT NULL
    AND p.SUMLIVINGAREASQFT IS NOT NULL
    AND p.LOTSIZESQFT IS NOT NULL
    AND p.SITUSLATITUDE IS NOT NULL
    AND p.SITUSLONGITUDE IS NOT NULL;


-----------

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) as census_tract,

        -- Education
        SUM(a."B15002e1") AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
             THEN (SUM(a."B15002e15" + a."B15002e32") / SUM(a."B15002e1")) * 100
             ELSE NULL END AS pct_bachelors_degree,

        -- Race/Ethnicity
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
             THEN (SUM(c."B03002e3") / SUM(c."B03002e1")) * 100
             ELSE NULL END AS pct_white,

        -- Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,

        -- Household Income
        AVG(income."B19013e1") AS median_household_income,

        -- Housing characteristics
        AVG(housing_value."B25077e1") AS median_home_value,
        AVG(rent."B25064e1") AS median_gross_rent,
        SUM(tenure."B25003e2") AS owner_occupied_units,
        SUM(tenure."B25003e3") AS renter_occupied_units,
        CASE WHEN SUM(tenure."B25003e1") > 0
             THEN (SUM(tenure."B25003e2") / SUM(tenure."B25003e1")) * 100
             ELSE NULL END AS pct_owner_occupied,
        SUM(occupancy."B25002e2") AS occupied_units,
        SUM(occupancy."B25002e3") AS vacant_units,

        -- Demographics
        AVG(age."B01002e1") AS median_age,

        -- Employment
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN SUM(employment."B23025e3" + employment."B23025e5") > 0
             THEN (SUM(employment."B23025e5") / SUM(employment."B23025e3" + employment."B23025e5")) * 100
             ELSE NULL END AS unemployment_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" AS a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" AS c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" AS d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" AS income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS housing_value
        ON a.CENSUS_BLOCK_GROUP = housing_value.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS rent
        ON a.CENSUS_BLOCK_GROUP = rent.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS tenure
        ON a.CENSUS_BLOCK_GROUP = tenure.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" AS occupancy
        ON a.CENSUS_BLOCK_GROUP = occupancy.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" AS age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" AS employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP

    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) IN ('37', '36', '39')  -- NC, NY, OH state FIPS codes
    GROUP BY LEFT(a.CENSUS_BLOCK_GROUP, 11)
)

SELECT
    p.PROPERTYID as property_id,
    p.CURRENTSALESPRICE as sale_price,
    p.CURRENTSALERECORDINGDATE as sale_date,
    p.YEARBUILT as year_built,
    p.EFFECTIVEYEARBUILT as effective_year_built,
    p.SITUSLATITUDE as latitude,
    p.SITUSLONGITUDE as longitude,
    p.SITUSSTATE as state,
    p.SITUSCITY as city,
    p.SITUSZIP5 as zip,
    p.SITUSCENSUSTRACT as census_tract_original,
    c.census_tract as census_tract_matched,
    p.SUMLIVINGAREASQFT as living_sqft,
    p.LOTSIZESQFT as lot_sqft,
    p.BEDROOMS as bedrooms,
    p.BATHFULL as full_baths,
    p.BATHSPARTIALNBR as half_baths,
    p.GARAGEPARKINGNBR as garage_spaces,
    p.FIREPLACECODE as fireplace_code,

    -- Census Demographics (Education)
    c.total_population_25plus,
    c.male_bachelors_degree,
    c.female_bachelors_degree,
    c.pct_bachelors_degree,

    -- Census Demographics (Population)
    c.total_population,
    c.non_hispanic_white_population,
    c.pct_white,

    -- Census Demographics (Income)
    c.median_earnings_total,
    c.median_earnings_male,
    c.median_earnings_female,
    c.median_household_income,

    -- Census Demographics (Housing)
    c.median_home_value,
    c.median_gross_rent,
    c.owner_occupied_units,
    c.renter_occupied_units,
    c.pct_owner_occupied,
    c.occupied_units,
    c.vacant_units,

    -- Census Demographics (Age & Employment)
    c.median_age,
    c.civilian_employed,
    c.civilian_unemployed,
    c.unemployment_rate,

    -- Election Data
    v.county_name,
    v.county_fips,
    v.votes_gop,
    v.votes_dem,
    v.total_votes,
    v.per_gop,
    v.per_dem,
    v.per_point_diff,
    v.dem_margin,
    v.rep_margin

FROM
    roc_public_record_data."DATATREE"."ASSESSOR" p

LEFT JOIN
    census_data c
    ON LEFT(p.FIPS, 5) || p.SITUSCENSUSTRACT = c.census_tract

LEFT JOIN
    "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
    ON LEFT(p.FIPS, 5) = CAST(v.county_fips AS VARCHAR)

WHERE
    (
        -- NC around Raleigh (Wake County and nearby counties in Triangle area)
        (p.SITUSSTATE = 'nc' AND LEFT(p.FIPS, 5) IN ('37183', '37063', '37101', '37069', '37135'))  -- Wake, Durham, Johnston, Franklin, Orange
        OR
        -- New York excluding NYC (Bronx, Kings, New York, Queens, Richmond)
        (p.SITUSSTATE = 'ny' AND LEFT(p.FIPS, 5) NOT IN ('36005', '36047', '36061', '36081', '36085'))
        OR
        -- All of Ohio
        (p.SITUSSTATE = 'oh')
    )
    AND p.CURRENTSALESPRICE IS NOT NULL
    AND p.SUMLIVINGAREASQFT IS NOT NULL
    AND p.LOTSIZESQFT IS NOT NULL
    AND p.SITUSLATITUDE IS NOT NULL
    AND p.SITUSLONGITUDE IS NOT NULL;



----------

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) AS census_tract,

        -- Education
        SUM(a."B15002e1")  AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
          THEN 100.0 * (SUM(a."B15002e15") + SUM(a."B15002e32")) / SUM(a."B15002e1")
        END AS pct_bachelors_degree,

        -- Population & Demographics
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
          THEN 100.0 * SUM(c."B03002e3") / SUM(c."B03002e1")
        END AS pct_white,

        -- Income & Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,
        AVG(income."B19013e1") AS median_household_income,

        -- Housing
        AVG(b25."B25077e1") AS median_home_value,
        AVG(b25."B25064e1") AS median_gross_rent,
        SUM(b25."B25003e2") AS owner_occupied_units,
        SUM(b25."B25003e3") AS renter_occupied_units,
        SUM(b25."B25002e2") AS occupied_units,
        SUM(b25."B25002e3") AS vacant_units,
        CASE WHEN SUM(b25."B25003e1") > 0
          THEN 100.0 * SUM(b25."B25003e2") / SUM(b25."B25003e1")
        END AS pct_owner_occupied,

        -- Derived: Vacancy Rate
        CASE WHEN (SUM(b25."B25002e2") + SUM(b25."B25002e3")) > 0
          THEN 100.0 * SUM(b25."B25002e3") / (SUM(b25."B25002e2") + SUM(b25."B25002e3"))
        END AS vacancy_rate,

        -- Age & Employment
        AVG(age."B01002e1") AS median_age,
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN (SUM(employment."B23025e3") + SUM(employment."B23025e5")) > 0
          THEN 100.0 * SUM(employment."B23025e5")
               / (SUM(employment."B23025e3") + SUM(employment."B23025e5"))
        END AS unemployment_rate,

        -- Poverty (currently NULL but structure in place)
        CAST(NULL AS NUMBER) AS population_below_poverty,
        CAST(NULL AS FLOAT)  AS poverty_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" b25
        ON a.CENSUS_BLOCK_GROUP = b25.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B17" poverty
        ON a.CENSUS_BLOCK_GROUP = poverty.CENSUS_BLOCK_GROUP
    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) IN ('37', '36', '39')  -- NC, NY, OH
    GROUP BY 1
),
base AS (
    SELECT
        -- Property Identifiers
        p.PROPERTYID as property_id,
        p.CURRENTSALESPRICE as sale_price,
        p.CURRENTSALERECORDINGDATE as sale_date,

        -- Location
        p.SITUSLATITUDE as latitude,
        p.SITUSLONGITUDE as longitude,
        p.SITUSSTATE as state,
        p.SITUSCITY as city,
        p.SITUSZIP5 as zip,
        p.SITUSCENSUSTRACT as census_tract,

        -- Property Age (USE EFFECTIVE YEAR BUILT!)
        p.YEARBUILT as year_built,
        p.EFFECTIVEYEARBUILT as effective_year_built,
        COALESCE(p.EFFECTIVEYEARBUILT, p.YEARBUILT) as year_built_final,

        -- Property Size
        p.SUMLIVINGAREASQFT as living_sqft,
        p.LOTSIZESQFT as lot_sqft,
        p.LOTSIZEACRES as lot_acres,
        p.BEDROOMS as bedrooms,
        p.BATHFULL as full_baths,
        p.BATHSPARTIALNBR as half_baths,
        p.TOTALROOMS as total_rooms,

        -- Property Features
        p.GARAGEPARKINGNBR as garage_spaces,
        p.FIREPLACECODE as fireplace_code,
        CASE WHEN p.FIREPLACECODE IS NOT NULL THEN 1 ELSE 0 END as has_fireplace,

        -- ========================================================================
        -- CRITICAL LUXURY FEATURES FOR ULTRA-HIGH PROPERTIES
        -- ========================================================================

        -- Building Quality & Condition (HIGHEST PRIORITY FOR ULTRA-HIGH)
        p.BUILDINGQUALITYCODE as building_quality,
        p.BUILDINGCONDITIONCODE as building_condition,
        p.STYLECODE as architectural_style,

        -- Luxury Amenities
        p.POOLCODE as pool_code,
        CASE WHEN p.POOLCODE IS NOT NULL AND p.POOLCODE > 0 THEN 1 ELSE 0 END as has_pool,
        p.STORIESNBRCODE as stories,

        -- Climate Control
        p.AIRCONDITIONINGCODE as ac_code,
        CASE WHEN p.AIRCONDITIONINGCODE IS NOT NULL AND p.AIRCONDITIONINGCODE > 0 THEN 1 ELSE 0 END as has_ac,

        -- Basement
        p.BASEMENTCODE as basement_code,
        p.BASEMENTFINISHEDSQFT as basement_finished_sqft,
        CASE WHEN p.BASEMENTCODE IS NOT NULL THEN 1 ELSE 0 END as has_basement,

        -- Water Features
        p.WATERCODE as water_code,
        CASE WHEN p.WATERCODE IS NOT NULL AND p.WATERCODE > 0 THEN 1 ELSE 0 END as has_water_feature,

        -- ========================================================================
        -- Assessment & Market Values (predictive but lagged)
        -- ========================================================================
        p.ASSDTOTALVALUE as assessed_total_value,
        p.ASSDLANDVALUE as assessed_land_value,
        p.ASSDIMPROVEMENTVALUE as assessed_improvement_value,
        p.MARKETVALUELAND as market_value_land,
        p.MARKETVALUEIMPROVEMENT as market_value_improvements,

        -- Site Characteristics
        p.TOPOGRAPHYCODE as topography_code,
        p.SITEINFLUENCECODE as site_influence_code,

        -- Building Materials
        p.EXTERIORWALLSCODE as exterior_walls_code,
        p.ROOFCOVERCODE as roof_cover_code,

        -- Ownership
        p.OWNEROCCUPIED as is_owner_occupied,

        -- Transaction History
        p.PREVSALESPRICE as previous_sale_price,
        p.PREVSALERECORDINGDATE as previous_sale_date,

        -- Community
        p.SUBDIVISIONNAME as subdivision,
        p.ZONING as zoning,

        -- ========================================================================

        -- Census Demographics (Education)
        c.total_population_25plus,
        c.male_bachelors_degree,
        c.female_bachelors_degree,
        c.pct_bachelors_degree,

        -- Census Demographics (Population)
        c.total_population,
        c.non_hispanic_white_population,
        c.pct_white,

        -- Census Demographics (Income)
        c.median_earnings_total,
        c.median_earnings_male,
        c.median_earnings_female,
        c.median_household_income,

        -- Census Demographics (Housing)
        c.median_home_value,
        c.median_gross_rent,
        c.owner_occupied_units,
        c.renter_occupied_units,
        c.pct_owner_occupied,
        c.occupied_units,
        c.vacant_units,
        c.vacancy_rate,

        -- Census Demographics (Age & Employment)
        c.median_age,
        c.civilian_employed,
        c.civilian_unemployed,
        c.unemployment_rate,

        -- Derived: Wealth Concentration Metrics
        c.median_household_income * c.total_population / 1000000.0 as wealth_concentration_index,
        c.pct_bachelors_degree * c.median_household_income / 100000.0 as education_income_index,

        -- Election Data
        v.county_name,
        v.county_fips,
        v.votes_gop,
        v.votes_dem,
        v.total_votes,
        v.per_gop,
        v.per_dem,
        v.per_point_diff,
        v.dem_margin,
        v.rep_margin,

        -- Derived: Political Lean Strength (absolute difference)
        ABS(v.per_gop - v.per_dem) as political_lean_strength,

        -- State FIPS for partitioning
        LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 2) AS state_fips

    FROM roc_public_record_data."DATATREE"."ASSESSOR" p
    LEFT JOIN census_data c
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) || p.SITUSCENSUSTRACT = c.census_tract  -- FIXED JOIN
    LEFT JOIN "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) = LPAD(TRIM(CAST(v.county_fips AS VARCHAR)), 5, '0')
    WHERE
        -- Location restrictions: NC around Raleigh, NY excluding NYC, All of OH
        (
            -- NC around Raleigh (Wake County and nearby Triangle counties)
            (p.SITUSSTATE = 'nc' AND LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) IN ('37183', '37063', '37101', '37069', '37135'))
            -- Wake, Durham, Johnston, Franklin, Orange
            OR
            -- New York excluding NYC (exclude Bronx, Kings, New York, Queens, Richmond)
            (p.SITUSSTATE = 'ny' AND LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) NOT IN ('36005', '36047', '36061', '36081', '36085'))
            OR
            -- All of Ohio
            (p.SITUSSTATE = 'oh')
        )

        -- Data quality filters
        AND p.CURRENTSALESPRICE IS NOT NULL
        AND p.SUMLIVINGAREASQFT IS NOT NULL
        AND p.LOTSIZESQFT IS NOT NULL
        AND p.SITUSLATITUDE IS NOT NULL
        AND p.SITUSLONGITUDE IS NOT NULL

        -- Exclude obvious data errors
        AND p.CURRENTSALESPRICE BETWEEN 10000 AND 100000000
        AND p.SUMLIVINGAREASQFT > 0
        AND p.LOTSIZESQFT > 0
        AND p.BEDROOMS > 0
),
random_sample AS (
    SELECT *
    FROM base
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY state_fips
        ORDER BY RANDOM()
    ) <= 1000
),
high_value_properties AS (
    SELECT *
    FROM base
    WHERE sale_price > 800000
)
-- Combine random sample with all high-value properties, removing duplicates
SELECT *
FROM random_sample
UNION
SELECT *
FROM high_value_properties
ORDER BY sale_price DESC;





-- Augmented query: Random sample of 1000 per state + ALL properties > $800K
WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) AS census_tract,
        SUM(a."B15002e1")  AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
          THEN 100.0 * (SUM(a."B15002e15") + SUM(a."B15002e32")) / SUM(a."B15002e1")
        END AS pct_bachelors_degree,
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
          THEN 100.0 * SUM(c."B03002e3") / SUM(c."B03002e1")
        END AS pct_white,
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,
        AVG(income."B19013e1") AS median_household_income,
        AVG(b25."B25077e1") AS median_home_value,
        AVG(b25."B25064e1") AS median_gross_rent,
        SUM(b25."B25003e2") AS owner_occupied_units,
        SUM(b25."B25003e3") AS renter_occupied_units,
        CASE WHEN SUM(b25."B25003e1") > 0
          THEN 100.0 * SUM(b25."B25003e2") / SUM(b25."B25003e1")
        END AS pct_owner_occupied,
        SUM(b25."B25002e2") AS occupied_units,
        SUM(b25."B25002e3") AS vacant_units,
        AVG(age."B01002e1") AS median_age,
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN (SUM(employment."B23025e3") + SUM(employment."B23025e5")) > 0
          THEN 100.0 * SUM(employment."B23025e5")
               / (SUM(employment."B23025e3") + SUM(employment."B23025e5"))
        END AS unemployment_rate,
        CAST(NULL AS NUMBER) AS population_below_poverty,
        CAST(NULL AS FLOAT)  AS poverty_rate
    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" b25
        ON a.CENSUS_BLOCK_GROUP = b25.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B17" poverty
        ON a.CENSUS_BLOCK_GROUP = poverty.CENSUS_BLOCK_GROUP
    GROUP BY 1
),
base AS (
    SELECT
        p.PROPERTYID as property_id,
        p.CURRENTSALESPRICE as sale_price,
        p.CURRENTSALERECORDINGDATE as sale_date,
        p.YEARBUILT as year_built,
        p.EFFECTIVEYEARBUILT as effective_year_built,
        p.SITUSLATITUDE as latitude,
        p.SITUSLONGITUDE as longitude,
        p.SITUSSTATE as state,
        p.SITUSCITY as city,
        p.SITUSZIP5 as zip,
        p.SITUSCENSUSTRACT as census_tract,
        p.SUMLIVINGAREASQFT as living_sqft,
        p.LOTSIZESQFT as lot_sqft,
        p.BEDROOMS as bedrooms,
        p.BATHFULL as full_baths,
        p.BATHSPARTIALNBR as half_baths,
        p.GARAGEPARKINGNBR as garage_spaces,
        p.FIREPLACECODE as fireplace_code,

        -- Census Demographics (Education)
        c.total_population_25plus,
        c.male_bachelors_degree,
        c.female_bachelors_degree,
        c.pct_bachelors_degree,

        -- Census Demographics (Population)
        c.total_population,
        c.non_hispanic_white_population,
        c.pct_white,

        -- Census Demographics (Income)
        c.median_earnings_total,
        c.median_earnings_male,
        c.median_earnings_female,
        c.median_household_income,

        -- Census Demographics (Housing)
        c.median_home_value,
        c.median_gross_rent,
        c.owner_occupied_units,
        c.renter_occupied_units,
        c.pct_owner_occupied,
        c.occupied_units,
        c.vacant_units,

        -- Census Demographics (Age & Employment)
        c.median_age,
        c.civilian_employed,
        c.civilian_unemployed,
        c.unemployment_rate,

        -- Election Data
        v.county_name,
        v.county_fips,
        v.votes_gop,
        v.votes_dem,
        v.total_votes,
        v.per_gop,
        v.per_dem,
        v.per_point_diff,
        v.dem_margin,
        v.rep_margin,

        -- State FIPS for partitioning
        LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 2) AS state_fips

    FROM roc_public_record_data."DATATREE"."ASSESSOR" p
    LEFT JOIN census_data c
        ON p.SITUSCENSUSTRACT = c.census_tract
    LEFT JOIN "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) = LPAD(TRIM(CAST(v.county_fips AS VARCHAR)), 5, '0')
    WHERE
        p.SITUSSTATE IN ('CA','TX','NY','FL','IL','PA','OH','GA','WA','NJ')
        AND p.CURRENTSALESPRICE IS NOT NULL
        AND p.SUMLIVINGAREASQFT IS NOT NULL
        AND p.LOTSIZESQFT IS NOT NULL
        AND p.SITUSLATITUDE IS NOT NULL
        AND p.SITUSLONGITUDE IS NOT NULL
),
random_sample AS (
    SELECT *
    FROM base
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY state_fips
        ORDER BY RANDOM()
    ) <= 1000
),
high_value_properties AS (
    SELECT *
    FROM base
    WHERE sale_price > 800000
)
SELECT *
FROM random_sample
UNION
SELECT *
FROM high_value_properties;

---

-- DIAGNOSTIC: Check what's actually in the data
SELECT
    COUNT(*) as total_records,
    COUNT(DISTINCT p.SITUSSTATE) as distinct_states,
    COUNT(CASE WHEN p.CURRENTSALESPRICE IS NOT NULL THEN 1 END) as has_sale_price,
    COUNT(CASE WHEN p.SUMLIVINGAREASQFT IS NOT NULL THEN 1 END) as has_living_sqft,
    COUNT(CASE WHEN p.LOTSIZESQFT IS NOT NULL THEN 1 END) as has_lot_sqft,
    MIN(p.CURRENTSALESPRICE) as min_price,
    MAX(p.CURRENTSALESPRICE) as max_price
FROM roc_public_record_data."DATATREE"."ASSESSOR" p
WHERE p.SITUSSTATE IN ('ca','tx','ny','fl','il','pa','oh','ga','wa','nj');

-- Check state format
SELECT DISTINCT p.SITUSSTATE, COUNT(*) as count
FROM roc_public_record_data."DATATREE"."ASSESSOR" p
GROUP BY p.SITUSSTATE
ORDER BY count DESC
LIMIT 20;

------

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) AS census_tract,

        -- Education
        SUM(a."B15002e1")  AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
          THEN 100.0 * (SUM(a."B15002e15") + SUM(a."B15002e32")) / SUM(a."B15002e1")
        END AS pct_bachelors_degree,

        -- Population & Demographics
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
          THEN 100.0 * SUM(c."B03002e3") / SUM(c."B03002e1")
        END AS pct_white,

        -- Income & Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,
        AVG(income."B19013e1") AS median_household_income,

        -- Housing
        AVG(b25."B25077e1") AS median_home_value,
        AVG(b25."B25064e1") AS median_gross_rent,
        SUM(b25."B25003e2") AS owner_occupied_units,
        SUM(b25."B25003e3") AS renter_occupied_units,
        SUM(b25."B25002e2") AS occupied_units,
        SUM(b25."B25002e3") AS vacant_units,
        CASE WHEN SUM(b25."B25003e1") > 0
          THEN 100.0 * SUM(b25."B25003e2") / SUM(b25."B25003e1")
        END AS pct_owner_occupied,

        -- Derived: Vacancy Rate
        CASE WHEN (SUM(b25."B25002e2") + SUM(b25."B25002e3")) > 0
          THEN 100.0 * SUM(b25."B25002e3") / (SUM(b25."B25002e2") + SUM(b25."B25002e3"))
        END AS vacancy_rate,

        -- Age & Employment
        AVG(age."B01002e1") AS median_age,
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN (SUM(employment."B23025e3") + SUM(employment."B23025e5")) > 0
          THEN 100.0 * SUM(employment."B23025e5")
               / (SUM(employment."B23025e3") + SUM(employment."B23025e5"))
        END AS unemployment_rate,

        -- Poverty (currently NULL but structure in place)
        CAST(NULL AS NUMBER) AS population_below_poverty,
        CAST(NULL AS FLOAT)  AS poverty_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" b25
        ON a.CENSUS_BLOCK_GROUP = b25.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B17" poverty
        ON a.CENSUS_BLOCK_GROUP = poverty.CENSUS_BLOCK_GROUP
    GROUP BY 1
),
base AS (
    SELECT
        -- Property Identifiers
        p.PROPERTYID as property_id,
        p.CURRENTSALESPRICE as sale_price,
        p.CURRENTSALERECORDINGDATE as sale_date,

        -- Location
        p.SITUSLATITUDE as latitude,
        p.SITUSLONGITUDE as longitude,
        p.SITUSSTATE as state,
        p.SITUSCITY as city,
        p.SITUSZIP5 as zip,
        p.SITUSCENSUSTRACT as census_tract,

        -- Property Age (USE EFFECTIVE YEAR BUILT!)
        p.YEARBUILT as year_built,
        p.EFFECTIVEYEARBUILT as effective_year_built,
        COALESCE(p.EFFECTIVEYEARBUILT, p.YEARBUILT) as year_built_final,

        -- Property Size
        p.SUMLIVINGAREASQFT as living_sqft,
        p.LOTSIZESQFT as lot_sqft,
        p.BEDROOMS as bedrooms,
        p.BATHFULL as full_baths,
        p.BATHSPARTIALNBR as half_baths,

        -- Property Features
        p.GARAGEPARKINGNBR as garage_spaces,
        p.FIREPLACECODE as fireplace_code,
        CASE WHEN p.FIREPLACECODE IS NOT NULL THEN 1 ELSE 0 END as has_fireplace,

        --Luxury Features (add these if they exist in your ASSESSOR table)
        --Uncomment and test these columns:
        -- p.POOLIND as has_pool,
        -- p.VIEWCODE as view_type,
        -- p.WATERFRONTIND as is_waterfront,
        -- p.BUILDINGQUALITYCODE as building_quality,
        -- p.BUILDINGCONDITIONCODE as building_condition,
        -- p.ARCHITECTURALSTYLECODE as arch_style,
        -- p.STORIESUNKNOWNNBR as stories,
        -- p.TOTALROOMS as total_rooms,
        -- p.GATEDCOMMUNITYIND as gated_community,

        -- Census Demographics (Education)
        c.total_population_25plus,
        c.male_bachelors_degree,
        c.female_bachelors_degree,
        c.pct_bachelors_degree,

        -- Census Demographics (Population)
        c.total_population,
        c.non_hispanic_white_population,
        c.pct_white,

        -- Census Demographics (Income)
        c.median_earnings_total,
        c.median_earnings_male,
        c.median_earnings_female,
        c.median_household_income,

        -- Census Demographics (Housing)
        c.median_home_value,
        c.median_gross_rent,
        c.owner_occupied_units,
        c.renter_occupied_units,
        c.pct_owner_occupied,
        c.occupied_units,
        c.vacant_units,
        c.vacancy_rate,

        -- Census Demographics (Age & Employment)
        c.median_age,
        c.civilian_employed,
        c.civilian_unemployed,
        c.unemployment_rate,

        -- Derived: Wealth Concentration Metrics
        c.median_household_income * c.total_population / 1000000.0 as wealth_concentration_index,
        c.pct_bachelors_degree * c.median_household_income / 100000.0 as education_income_index,

        -- Election Data
        v.county_name,
        v.county_fips,
        v.votes_gop,
        v.votes_dem,
        v.total_votes,
        v.per_gop,
        v.per_dem,
        v.per_point_diff,
        v.dem_margin,
        v.rep_margin,

        -- Derived: Political Lean Strength (absolute difference)
        ABS(v.per_gop - v.per_dem) as political_lean_strength,

        -- State FIPS for partitioning
        LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 2) AS state_fips

    FROM roc_public_record_data."DATATREE"."ASSESSOR" p
    LEFT JOIN census_data c
        ON p.SITUSCENSUSTRACT = c.census_tract
    LEFT JOIN "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) = LPAD(TRIM(CAST(v.county_fips AS VARCHAR)), 5, '0')
    WHERE
        -- Top 10 states by population/property value
        p.SITUSSTATE IN ('ca','tx','ny','fl','il','pa','oh','ga','wa','nj')

        -- Data quality filters
        AND p.CURRENTSALESPRICE IS NOT NULL
        AND p.SUMLIVINGAREASQFT IS NOT NULL
        AND p.LOTSIZESQFT IS NOT NULL
        AND p.SITUSLATITUDE IS NOT NULL
        AND p.SITUSLONGITUDE IS NOT NULL

        -- Exclude obvious data errors
        AND p.CURRENTSALESPRICE BETWEEN 10000 AND 100000000
        AND p.SUMLIVINGAREASQFT > 0
        AND p.LOTSIZESQFT > 0
        AND p.BEDROOMS > 0
),
random_sample AS (
    SELECT *
    FROM base
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY state_fips
        ORDER BY RANDOM()
    ) <= 1000
),
high_value_properties AS (
    SELECT *
    FROM base
    WHERE sale_price > 800000
)
-- Combine random sample with all high-value properties, removing duplicates
SELECT *
FROM random_sample
UNION
SELECT *
FROM high_value_properties
ORDER BY sale_price DESC;

----------
-- AVM Outlier Properties Specific ---

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) AS census_tract,

        -- Education
        SUM(a."B15002e1")  AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
          THEN 100.0 * (SUM(a."B15002e15") + SUM(a."B15002e32")) / SUM(a."B15002e1")
        END AS pct_bachelors_degree,

        -- Population & Demographics
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
          THEN 100.0 * SUM(c."B03002e3") / SUM(c."B03002e1")
        END AS pct_white,

        -- Income & Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,
        AVG(income."B19013e1") AS median_household_income,

        -- Housing
        AVG(b25."B25077e1") AS median_home_value,
        AVG(b25."B25064e1") AS median_gross_rent,
        SUM(b25."B25003e2") AS owner_occupied_units,
        SUM(b25."B25003e3") AS renter_occupied_units,
        SUM(b25."B25002e2") AS occupied_units,
        SUM(b25."B25002e3") AS vacant_units,
        CASE WHEN SUM(b25."B25003e1") > 0
          THEN 100.0 * SUM(b25."B25003e2") / SUM(b25."B25003e1")
        END AS pct_owner_occupied,

        -- Derived: Vacancy Rate
        CASE WHEN (SUM(b25."B25002e2") + SUM(b25."B25002e3")) > 0
          THEN 100.0 * SUM(b25."B25002e3") / (SUM(b25."B25002e2") + SUM(b25."B25002e3"))
        END AS vacancy_rate,

        -- Age & Employment
        AVG(age."B01002e1") AS median_age,
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN (SUM(employment."B23025e3") + SUM(employment."B23025e5")) > 0
          THEN 100.0 * SUM(employment."B23025e5")
               / (SUM(employment."B23025e3") + SUM(employment."B23025e5"))
        END AS unemployment_rate,

        -- Poverty (currently NULL but structure in place)
        CAST(NULL AS NUMBER) AS population_below_poverty,
        CAST(NULL AS FLOAT)  AS poverty_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" b25
        ON a.CENSUS_BLOCK_GROUP = b25.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B17" poverty
        ON a.CENSUS_BLOCK_GROUP = poverty.CENSUS_BLOCK_GROUP
    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) IN ('37', '36', '39')  -- NC, NY, OH
    GROUP BY 1
),
base AS (
    SELECT
        -- Property Identifiers
        p.PROPERTYID as property_id,
        p.CURRENTSALESPRICE as sale_price,
        p.CURRENTSALERECORDINGDATE as sale_date,

        -- Location
        p.SITUSLATITUDE as latitude,
        p.SITUSLONGITUDE as longitude,
        p.SITUSSTATE as state,
        p.SITUSCITY as city,
        p.SITUSZIP5 as zip,
        p.SITUSCENSUSTRACT as census_tract,

        -- Property Age (USE EFFECTIVE YEAR BUILT!)
        p.YEARBUILT as year_built,
        p.EFFECTIVEYEARBUILT as effective_year_built,
        COALESCE(p.EFFECTIVEYEARBUILT, p.YEARBUILT) as year_built_final,

        -- Property Size
        p.SUMLIVINGAREASQFT as living_sqft,
        p.LOTSIZESQFT as lot_sqft,
        p.LOTSIZEACRES as lot_acres,
        p.BEDROOMS as bedrooms,
        p.BATHFULL as full_baths,
        p.BATHSPARTIALNBR as half_baths,
        p.TOTALROOMS as total_rooms,

        -- Property Features
        p.GARAGEPARKINGNBR as garage_spaces,
        p.FIREPLACECODE as fireplace_code,
        CASE WHEN p.FIREPLACECODE IS NOT NULL THEN 1 ELSE 0 END as has_fireplace,

        -- ========================================================================
        -- CRITICAL LUXURY FEATURES FOR ULTRA-HIGH PROPERTIES
        -- ========================================================================

        -- Building Quality & Condition (HIGHEST PRIORITY FOR ULTRA-HIGH)
        p.BUILDINGQUALITYCODE as building_quality,
        p.BUILDINGCONDITIONCODE as building_condition,
        p.STYLECODE as architectural_style,

        -- Luxury Amenities
        p.POOLCODE as pool_code,
        CASE WHEN p.POOLCODE IS NOT NULL AND p.POOLCODE > 0 THEN 1 ELSE 0 END as has_pool,
        p.STORIESNBRCODE as stories,

        -- Climate Control
        p.AIRCONDITIONINGCODE as ac_code,
        CASE WHEN p.AIRCONDITIONINGCODE IS NOT NULL AND p.AIRCONDITIONINGCODE > 0 THEN 1 ELSE 0 END as has_ac,

        -- Basement
        p.BASEMENTCODE as basement_code,
        p.BASEMENTFINISHEDSQFT as basement_finished_sqft,
        CASE WHEN p.BASEMENTCODE IS NOT NULL THEN 1 ELSE 0 END as has_basement,

        -- Water Features
        p.WATERCODE as water_code,
        CASE WHEN p.WATERCODE IS NOT NULL AND p.WATERCODE > 0 THEN 1 ELSE 0 END as has_water_feature,

        -- ========================================================================
        -- Assessment & Market Values (predictive but lagged)
        -- ========================================================================
        p.ASSDTOTALVALUE as assessed_total_value,
        p.ASSDLANDVALUE as assessed_land_value,
        p.ASSDIMPROVEMENTVALUE as assessed_improvement_value,
        p.MARKETVALUELAND as market_value_land,
        p.MARKETVALUEIMPROVEMENT as market_value_improvements,

        -- Site Characteristics
        p.TOPOGRAPHYCODE as topography_code,
        p.SITEINFLUENCECODE as site_influence_code,

        -- Building Materials
        p.EXTERIORWALLSCODE as exterior_walls_code,
        p.ROOFCOVERCODE as roof_cover_code,

        -- Ownership
        p.OWNEROCCUPIED as is_owner_occupied,

        -- Transaction History
        p.PREVSALESPRICE as previous_sale_price,
        p.PREVSALERECORDINGDATE as previous_sale_date,

        -- Community
        p.SUBDIVISIONNAME as subdivision,
        p.ZONING as zoning,

        -- ========================================================================

        -- Census Demographics (Education)
        c.total_population_25plus,
        c.male_bachelors_degree,
        c.female_bachelors_degree,
        c.pct_bachelors_degree,

        -- Census Demographics (Population)
        c.total_population,
        c.non_hispanic_white_population,
        c.pct_white,

        -- Census Demographics (Income)
        c.median_earnings_total,
        c.median_earnings_male,
        c.median_earnings_female,
        c.median_household_income,

        -- Census Demographics (Housing)
        c.median_home_value,
        c.median_gross_rent,
        c.owner_occupied_units,
        c.renter_occupied_units,
        c.pct_owner_occupied,
        c.occupied_units,
        c.vacant_units,
        c.vacancy_rate,

        -- Census Demographics (Age & Employment)
        c.median_age,
        c.civilian_employed,
        c.civilian_unemployed,
        c.unemployment_rate,

        -- Derived: Wealth Concentration Metrics
        c.median_household_income * c.total_population / 1000000.0 as wealth_concentration_index,
        c.pct_bachelors_degree * c.median_household_income / 100000.0 as education_income_index,

        -- Election Data
        v.county_name,
        v.county_fips,
        v.votes_gop,
        v.votes_dem,
        v.total_votes,
        v.per_gop,
        v.per_dem,
        v.per_point_diff,
        v.dem_margin,
        v.rep_margin,

        -- Derived: Political Lean Strength (absolute difference)
        ABS(v.per_gop - v.per_dem) as political_lean_strength,

        -- State FIPS for partitioning
        LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 2) AS state_fips

    FROM roc_public_record_data."DATATREE"."ASSESSOR" p
    LEFT JOIN census_data c
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) || p.SITUSCENSUSTRACT = c.census_tract  -- FIXED JOIN
    LEFT JOIN "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) = LPAD(TRIM(CAST(v.county_fips AS VARCHAR)), 5, '0')
    WHERE
        -- Location restrictions: NC around Raleigh, NY excluding NYC, All of OH
        (
            -- NC around Raleigh (Wake County and nearby Triangle counties)
            (p.SITUSSTATE = 'nc' AND LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) IN ('37183', '37063', '37101', '37069', '37135'))
            -- Wake, Durham, Johnston, Franklin, Orange
            OR
            -- New York excluding NYC (exclude Bronx, Kings, New York, Queens, Richmond)
            (p.SITUSSTATE = 'ny' AND LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) NOT IN ('36005', '36047', '36061', '36081', '36085'))
            OR
            -- All of Ohio
            (p.SITUSSTATE = 'oh')
        )

        -- Data quality filters
        AND p.CURRENTSALESPRICE IS NOT NULL
        AND p.SUMLIVINGAREASQFT IS NOT NULL
        AND p.LOTSIZESQFT IS NOT NULL
        AND p.SITUSLATITUDE IS NOT NULL
        AND p.SITUSLONGITUDE IS NOT NULL

        -- Exclude obvious data errors
        AND p.CURRENTSALESPRICE BETWEEN 10000 AND 100000000
        AND p.SUMLIVINGAREASQFT > 0
        AND p.LOTSIZESQFT > 0
        AND p.BEDROOMS > 0

        AND p.PROPERTYID IN (93817184, 89085494)

        -- Then apply data quality filters
        AND p.CURRENTSALESPRICE IS NOT NULL
        AND p.SUMLIVINGAREASQFT IS NOT NULL
),
random_sample AS (
    SELECT *
    FROM base
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY state_fips
        ORDER BY RANDOM()
    ) <= 1000
),
high_value_properties AS (
    SELECT *
    FROM base
    WHERE sale_price > 800000
)
-- Combine random sample with all high-value properties, removing duplicates
SELECT *
FROM random_sample
UNION
SELECT *
FROM high_value_properties
ORDER BY sale_price DESC;

----

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) AS census_tract,

        -- Education
        SUM(a."B15002e1")  AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
          THEN 100.0 * (SUM(a."B15002e15") + SUM(a."B15002e32")) / SUM(a."B15002e1")
        END AS pct_bachelors_degree,

        -- Population & Demographics
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
          THEN 100.0 * SUM(c."B03002e3") / SUM(c."B03002e1")
        END AS pct_white,

        -- Income & Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,
        AVG(income."B19013e1") AS median_household_income,

        -- Housing
        AVG(b25."B25077e1") AS median_home_value,
        AVG(b25."B25064e1") AS median_gross_rent,
        SUM(b25."B25003e2") AS owner_occupied_units,
        SUM(b25."B25003e3") AS renter_occupied_units,
        SUM(b25."B25002e2") AS occupied_units,
        SUM(b25."B25002e3") AS vacant_units,
        CASE WHEN SUM(b25."B25003e1") > 0
          THEN 100.0 * SUM(b25."B25003e2") / SUM(b25."B25003e1")
        END AS pct_owner_occupied,

        -- Derived: Vacancy Rate
        CASE WHEN (SUM(b25."B25002e2") + SUM(b25."B25002e3")) > 0
          THEN 100.0 * SUM(b25."B25002e3") / (SUM(b25."B25002e2") + SUM(b25."B25002e3"))
        END AS vacancy_rate,

        -- Age & Employment
        AVG(age."B01002e1") AS median_age,
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN (SUM(employment."B23025e3") + SUM(employment."B23025e5")) > 0
          THEN 100.0 * SUM(employment."B23025e5")
               / (SUM(employment."B23025e3") + SUM(employment."B23025e5"))
        END AS unemployment_rate,

        -- Poverty (currently NULL but structure in place)
        CAST(NULL AS NUMBER) AS population_below_poverty,
        CAST(NULL AS FLOAT)  AS poverty_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" b25
        ON a.CENSUS_BLOCK_GROUP = b25.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B17" poverty
        ON a.CENSUS_BLOCK_GROUP = poverty.CENSUS_BLOCK_GROUP
    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) IN ('37', '36', '39')  -- NC, NY, OH
    GROUP BY 1
),
-- ============================================================================
-- PROPERTY ID LIST - UPDATE THIS WITH YOUR PROPERTY IDS
-- ============================================================================
property_id_list AS (
    SELECT property_id FROM (
        VALUES
            (93817184),
            (12345678),
            (87654321)
            -- Add more property IDs here, one per line
            -- (property_id_here),
    ) AS t(property_id)
),
-- ============================================================================
base AS (
    SELECT
        -- Property Identifiers
        p.PROPERTYID as property_id,
        p.CURRENTSALESPRICE as sale_price,
        p.CURRENTSALERECORDINGDATE as sale_date,

        -- Location
        p.SITUSLATITUDE as latitude,
        p.SITUSLONGITUDE as longitude,
        p.SITUSSTATE as state,
        p.SITUSCITY as city,
        p.SITUSZIP5 as zip,
        p.SITUSCENSUSTRACT as census_tract,

        -- Property Age (USE EFFECTIVE YEAR BUILT!)
        p.YEARBUILT as year_built,
        p.EFFECTIVEYEARBUILT as effective_year_built,
        COALESCE(p.EFFECTIVEYEARBUILT, p.YEARBUILT) as year_built_final,

        -- Property Size
        p.SUMLIVINGAREASQFT as living_sqft,
        p.LOTSIZESQFT as lot_sqft,
        p.LOTSIZEACRES as lot_acres,
        p.BEDROOMS as bedrooms,
        p.BATHFULL as full_baths,
        p.BATHSPARTIALNBR as half_baths,
        p.TOTALROOMS as total_rooms,

        -- Property Features
        p.GARAGEPARKINGNBR as garage_spaces,
        p.FIREPLACECODE as fireplace_code,
        CASE WHEN p.FIREPLACECODE IS NOT NULL THEN 1 ELSE 0 END as has_fireplace,

        -- ========================================================================
        -- CRITICAL LUXURY FEATURES FOR ULTRA-HIGH PROPERTIES
        -- ========================================================================

        -- Building Quality & Condition (HIGHEST PRIORITY FOR ULTRA-HIGH)
        p.BUILDINGQUALITYCODE as building_quality,
        p.BUILDINGCONDITIONCODE as building_condition,
        p.STYLECODE as architectural_style,

        -- Luxury Amenities
        p.POOLCODE as pool_code,
        CASE WHEN p.POOLCODE IS NOT NULL AND p.POOLCODE > 0 THEN 1 ELSE 0 END as has_pool,
        p.STORIESNBRCODE as stories,

        -- Climate Control
        p.AIRCONDITIONINGCODE as ac_code,
        CASE WHEN p.AIRCONDITIONINGCODE IS NOT NULL AND p.AIRCONDITIONINGCODE > 0 THEN 1 ELSE 0 END as has_ac,

        -- Basement
        p.BASEMENTCODE as basement_code,
        p.BASEMENTFINISHEDSQFT as basement_finished_sqft,
        CASE WHEN p.BASEMENTCODE IS NOT NULL THEN 1 ELSE 0 END as has_basement,

        -- Water Features
        p.WATERCODE as water_code,
        CASE WHEN p.WATERCODE IS NOT NULL AND p.WATERCODE > 0 THEN 1 ELSE 0 END as has_water_feature,

        -- ========================================================================
        -- Assessment & Market Values (predictive but lagged)
        -- ========================================================================
        p.ASSDTOTALVALUE as assessed_total_value,
        p.ASSDLANDVALUE as assessed_land_value,
        p.ASSDIMPROVEMENTVALUE as assessed_improvement_value,
        p.MARKETVALUELAND as market_value_land,
        p.MARKETVALUEIMPROVEMENT as market_value_improvements,

        -- Site Characteristics
        p.TOPOGRAPHYCODE as topography_code,
        p.SITEINFLUENCECODE as site_influence_code,

        -- Building Materials
        p.EXTERIORWALLSCODE as exterior_walls_code,
        p.ROOFCOVERCODE as roof_cover_code,

        -- Ownership
        p.OWNEROCCUPIED as is_owner_occupied,

        -- Transaction History
        p.PREVSALESPRICE as previous_sale_price,
        p.PREVSALERECORDINGDATE as previous_sale_date,

        -- Community
        p.SUBDIVISIONNAME as subdivision,
        p.ZONING as zoning,

        -- ========================================================================

        -- Census Demographics (Education)
        c.total_population_25plus,
        c.male_bachelors_degree,
        c.female_bachelors_degree,
        c.pct_bachelors_degree,

        -- Census Demographics (Population)
        c.total_population,
        c.non_hispanic_white_population,
        c.pct_white,

        -- Census Demographics (Income)
        c.median_earnings_total,
        c.median_earnings_male,
        c.median_earnings_female,
        c.median_household_income,

        -- Census Demographics (Housing)
        c.median_home_value,
        c.median_gross_rent,
        c.owner_occupied_units,
        c.renter_occupied_units,
        c.pct_owner_occupied,
        c.occupied_units,
        c.vacant_units,
        c.vacancy_rate,

        -- Census Demographics (Age & Employment)
        c.median_age,
        c.civilian_employed,
        c.civilian_unemployed,
        c.unemployment_rate,

        -- Derived: Wealth Concentration Metrics
        c.median_household_income * c.total_population / 1000000.0 as wealth_concentration_index,
        c.pct_bachelors_degree * c.median_household_income / 100000.0 as education_income_index,

        -- Election Data
        v.county_name,
        v.county_fips,
        v.votes_gop,
        v.votes_dem,
        v.total_votes,
        v.per_gop,
        v.per_dem,
        v.per_point_diff,
        v.dem_margin,
        v.rep_margin,

        -- Derived: Political Lean Strength (absolute difference)
        ABS(v.per_gop - v.per_dem) as political_lean_strength,

        -- State FIPS for partitioning
        LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 2) AS state_fips

    FROM roc_public_record_data."DATATREE"."ASSESSOR" p
    -- INNER JOIN to only get properties in the list
    INNER JOIN property_id_list pil
        ON p.PROPERTYID = pil.property_id
    LEFT JOIN census_data c
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) || p.SITUSCENSUSTRACT = c.census_tract
    LEFT JOIN "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) = LPAD(TRIM(CAST(v.county_fips AS VARCHAR)), 5, '0')
)
SELECT *
FROM base
ORDER BY sale_price DESC;

------

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) AS census_tract,

        -- Education
        SUM(a."B15002e1")  AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
          THEN 100.0 * (SUM(a."B15002e15") + SUM(a."B15002e32")) / SUM(a."B15002e1")
        END AS pct_bachelors_degree,

        -- Population & Demographics
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
          THEN 100.0 * SUM(c."B03002e3") / SUM(c."B03002e1")
        END AS pct_white,

        -- Income & Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,
        AVG(income."B19013e1") AS median_household_income,

        -- Housing
        AVG(b25."B25077e1") AS median_home_value,
        AVG(b25."B25064e1") AS median_gross_rent,
        SUM(b25."B25003e2") AS owner_occupied_units,
        SUM(b25."B25003e3") AS renter_occupied_units,
        SUM(b25."B25002e2") AS occupied_units,
        SUM(b25."B25002e3") AS vacant_units,
        CASE WHEN SUM(b25."B25003e1") > 0
          THEN 100.0 * SUM(b25."B25003e2") / SUM(b25."B25003e1")
        END AS pct_owner_occupied,

        -- Derived: Vacancy Rate
        CASE WHEN (SUM(b25."B25002e2") + SUM(b25."B25002e3")) > 0
          THEN 100.0 * SUM(b25."B25002e3") / (SUM(b25."B25002e2") + SUM(b25."B25002e3"))
        END AS vacancy_rate,

        -- Age & Employment
        AVG(age."B01002e1") AS median_age,
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN (SUM(employment."B23025e3") + SUM(employment."B23025e5")) > 0
          THEN 100.0 * SUM(employment."B23025e5")
               / (SUM(employment."B23025e3") + SUM(employment."B23025e5"))
        END AS unemployment_rate,

        -- Poverty (currently NULL but structure in place)
        CAST(NULL AS NUMBER) AS population_below_poverty,
        CAST(NULL AS FLOAT)  AS poverty_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" b25
        ON a.CENSUS_BLOCK_GROUP = b25.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B17" poverty
        ON a.CENSUS_BLOCK_GROUP = poverty.CENSUS_BLOCK_GROUP
    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) IN ('37', '36', '39')  -- NC, NY, OH
    GROUP BY 1
),
-- ============================================================================
-- PROPERTY ID LIST - SOURCED FROM OUTLIERS TABLE
-- ============================================================================
property_id_list AS (
    SELECT PROPERTYID as property_id
    FROM "SCRATCH"."PUBLIC"."OUTLIERS_AVM_ZILLOW_COMPARISONS"
),
-- ============================================================================
base AS (
    SELECT
        -- Property Identifiers
        p.PROPERTYID as property_id,
        p.CURRENTSALESPRICE as sale_price,
        p.CURRENTSALERECORDINGDATE as sale_date,

        -- Location
        p.SITUSLATITUDE as latitude,
        p.SITUSLONGITUDE as longitude,
        p.SITUSSTATE as state,
        p.SITUSCITY as city,
        p.SITUSZIP5 as zip,
        p.SITUSCENSUSTRACT as census_tract,

        -- Property Age (USE EFFECTIVE YEAR BUILT!)
        p.YEARBUILT as year_built,
        p.EFFECTIVEYEARBUILT as effective_year_built,
        COALESCE(p.EFFECTIVEYEARBUILT, p.YEARBUILT) as year_built_final,

        -- Property Size
        p.SUMLIVINGAREASQFT as living_sqft,
        p.LOTSIZESQFT as lot_sqft,
        p.LOTSIZEACRES as lot_acres,
        p.BEDROOMS as bedrooms,
        p.BATHFULL as full_baths,
        p.BATHSPARTIALNBR as half_baths,
        p.TOTALROOMS as total_rooms,

        -- Property Features
        p.GARAGEPARKINGNBR as garage_spaces,
        p.FIREPLACECODE as fireplace_code,
        CASE WHEN p.FIREPLACECODE IS NOT NULL THEN 1 ELSE 0 END as has_fireplace,

        -- ========================================================================
        -- CRITICAL LUXURY FEATURES FOR ULTRA-HIGH PROPERTIES
        -- ========================================================================

        -- Building Quality & Condition (HIGHEST PRIORITY FOR ULTRA-HIGH)
        p.BUILDINGQUALITYCODE as building_quality,
        p.BUILDINGCONDITIONCODE as building_condition,
        p.STYLECODE as architectural_style,

        -- Luxury Amenities
        p.POOLCODE as pool_code,
        CASE WHEN p.POOLCODE IS NOT NULL AND p.POOLCODE > 0 THEN 1 ELSE 0 END as has_pool,
        p.STORIESNBRCODE as stories,

        -- Climate Control
        p.AIRCONDITIONINGCODE as ac_code,
        CASE WHEN p.AIRCONDITIONINGCODE IS NOT NULL AND p.AIRCONDITIONINGCODE > 0 THEN 1 ELSE 0 END as has_ac,

        -- Basement
        p.BASEMENTCODE as basement_code,
        p.BASEMENTFINISHEDSQFT as basement_finished_sqft,
        CASE WHEN p.BASEMENTCODE IS NOT NULL THEN 1 ELSE 0 END as has_basement,

        -- Water Features
        p.WATERCODE as water_code,
        CASE WHEN p.WATERCODE IS NOT NULL AND p.WATERCODE > 0 THEN 1 ELSE 0 END as has_water_feature,

        -- ========================================================================
        -- Assessment & Market Values (predictive but lagged)
        -- ========================================================================
        p.ASSDTOTALVALUE as assessed_total_value,
        p.ASSDLANDVALUE as assessed_land_value,
        p.ASSDIMPROVEMENTVALUE as assessed_improvement_value,
        p.MARKETVALUELAND as market_value_land,
        p.MARKETVALUEIMPROVEMENT as market_value_improvements,

        -- Site Characteristics
        p.TOPOGRAPHYCODE as topography_code,
        p.SITEINFLUENCECODE as site_influence_code,

        -- Building Materials
        p.EXTERIORWALLSCODE as exterior_walls_code,
        p.ROOFCOVERCODE as roof_cover_code,

        -- Ownership
        p.OWNEROCCUPIED as is_owner_occupied,

        -- Transaction History
        p.PREVSALESPRICE as previous_sale_price,
        p.PREVSALERECORDINGDATE as previous_sale_date,

        -- Community
        p.SUBDIVISIONNAME as subdivision,
        p.ZONING as zoning,

        -- ========================================================================

        -- Census Demographics (Education)
        c.total_population_25plus,
        c.male_bachelors_degree,
        c.female_bachelors_degree,
        c.pct_bachelors_degree,

        -- Census Demographics (Population)
        c.total_population,
        c.non_hispanic_white_population,
        c.pct_white,

        -- Census Demographics (Income)
        c.median_earnings_total,
        c.median_earnings_male,
        c.median_earnings_female,
        c.median_household_income,

        -- Census Demographics (Housing)
        c.median_home_value,
        c.median_gross_rent,
        c.owner_occupied_units,
        c.renter_occupied_units,
        c.pct_owner_occupied,
        c.occupied_units,
        c.vacant_units,
        c.vacancy_rate,

        -- Census Demographics (Age & Employment)
        c.median_age,
        c.civilian_employed,
        c.civilian_unemployed,
        c.unemployment_rate,

        -- Derived: Wealth Concentration Metrics
        c.median_household_income * c.total_population / 1000000.0 as wealth_concentration_index,
        c.pct_bachelors_degree * c.median_household_income / 100000.0 as education_income_index,

        -- Election Data
        v.county_name,
        v.county_fips,
        v.votes_gop,
        v.votes_dem,
        v.total_votes,
        v.per_gop,
        v.per_dem,
        v.per_point_diff,
        v.dem_margin,
        v.rep_margin,

        -- Derived: Political Lean Strength (absolute difference)
        ABS(v.per_gop - v.per_dem) as political_lean_strength,

        -- State FIPS for partitioning
        LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 2) AS state_fips

    FROM roc_public_record_data."DATATREE"."ASSESSOR" p
    -- INNER JOIN to only get properties in the list
    INNER JOIN property_id_list pil
        ON p.PROPERTYID = pil.property_id
    LEFT JOIN census_data c
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) || p.SITUSCENSUSTRACT = c.census_tract
    LEFT JOIN "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) = LPAD(TRIM(CAST(v.county_fips AS VARCHAR)), 5, '0')
)
SELECT *
FROM base
ORDER BY sale_price DESC;

----

WITH census_data AS (
    SELECT
        LEFT(a.CENSUS_BLOCK_GROUP, 11) AS census_tract,

        -- Education
        SUM(a."B15002e1")  AS total_population_25plus,
        SUM(a."B15002e15") AS male_bachelors_degree,
        SUM(a."B15002e32") AS female_bachelors_degree,
        CASE WHEN SUM(a."B15002e1") > 0
          THEN 100.0 * (SUM(a."B15002e15") + SUM(a."B15002e32")) / SUM(a."B15002e1")
        END AS pct_bachelors_degree,

        -- Population & Demographics
        SUM(c."B03002e1") AS total_population,
        SUM(c."B03002e3") AS non_hispanic_white_population,
        CASE WHEN SUM(c."B03002e1") > 0
          THEN 100.0 * SUM(c."B03002e3") / SUM(c."B03002e1")
        END AS pct_white,

        -- Income & Earnings
        AVG(d."B20002e1") AS median_earnings_total,
        AVG(d."B20002e2") AS median_earnings_male,
        AVG(d."B20002e3") AS median_earnings_female,
        AVG(income."B19013e1") AS median_household_income,

        -- Housing
        AVG(b25."B25077e1") AS median_home_value,
        AVG(b25."B25064e1") AS median_gross_rent,
        SUM(b25."B25003e2") AS owner_occupied_units,
        SUM(b25."B25003e3") AS renter_occupied_units,
        SUM(b25."B25002e2") AS occupied_units,
        SUM(b25."B25002e3") AS vacant_units,
        CASE WHEN SUM(b25."B25003e1") > 0
          THEN 100.0 * SUM(b25."B25003e2") / SUM(b25."B25003e1")
        END AS pct_owner_occupied,

        -- Derived: Vacancy Rate
        CASE WHEN (SUM(b25."B25002e2") + SUM(b25."B25002e3")) > 0
          THEN 100.0 * SUM(b25."B25002e3") / (SUM(b25."B25002e2") + SUM(b25."B25002e3"))
        END AS vacancy_rate,

        -- Age & Employment
        AVG(age."B01002e1") AS median_age,
        SUM(employment."B23025e3") AS civilian_employed,
        SUM(employment."B23025e5") AS civilian_unemployed,
        CASE WHEN (SUM(employment."B23025e3") + SUM(employment."B23025e5")) > 0
          THEN 100.0 * SUM(employment."B23025e5")
               / (SUM(employment."B23025e3") + SUM(employment."B23025e5"))
        END AS unemployment_rate,

        -- Poverty (currently NULL but structure in place)
        CAST(NULL AS NUMBER) AS population_below_poverty,
        CAST(NULL AS FLOAT)  AS poverty_rate

    FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B15" a
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B03" c
        ON a.CENSUS_BLOCK_GROUP = c.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B20" d
        ON a.CENSUS_BLOCK_GROUP = d.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B19" income
        ON a.CENSUS_BLOCK_GROUP = income.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B25" b25
        ON a.CENSUS_BLOCK_GROUP = b25.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B01" age
        ON a.CENSUS_BLOCK_GROUP = age.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B23" employment
        ON a.CENSUS_BLOCK_GROUP = employment.CENSUS_BLOCK_GROUP
    LEFT JOIN US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.PUBLIC."2019_CBG_B17" poverty
        ON a.CENSUS_BLOCK_GROUP = poverty.CENSUS_BLOCK_GROUP
    WHERE LEFT(a.CENSUS_BLOCK_GROUP, 2) IN ('37', '36', '39')  -- NC, NY, OH
    GROUP BY 1
),
base AS (
    SELECT
        -- Property Identifiers
        p.PROPERTYID as property_id,
        p.CURRENTSALESPRICE as sale_price,
        p.CURRENTSALERECORDINGDATE as sale_date,

        -- Location
        p.SITUSLATITUDE as latitude,
        p.SITUSLONGITUDE as longitude,
        p.SITUSSTATE as state,
        p.SITUSCITY as city,
        p.SITUSZIP5 as zip,
        p.SITUSCENSUSTRACT as census_tract,

        -- Property Age (USE EFFECTIVE YEAR BUILT!)
        p.YEARBUILT as year_built,
        p.EFFECTIVEYEARBUILT as effective_year_built,
        COALESCE(p.EFFECTIVEYEARBUILT, p.YEARBUILT) as year_built_final,

        -- Property Size
        p.SUMLIVINGAREASQFT as living_sqft,
        p.LOTSIZESQFT as lot_sqft,
        p.LOTSIZEACRES as lot_acres,
        p.BEDROOMS as bedrooms,
        p.BATHFULL as full_baths,
        p.BATHSPARTIALNBR as half_baths,
        p.TOTALROOMS as total_rooms,

        -- Property Features
        p.GARAGEPARKINGNBR as garage_spaces,
        p.FIREPLACECODE as fireplace_code,
        CASE WHEN p.FIREPLACECODE IS NOT NULL THEN 1 ELSE 0 END as has_fireplace,

        -- ========================================================================
        -- CRITICAL LUXURY FEATURES FOR ULTRA-HIGH PROPERTIES
        -- ========================================================================

        -- Building Quality & Condition (HIGHEST PRIORITY FOR ULTRA-HIGH)
        p.BUILDINGQUALITYCODE as building_quality,
        p.BUILDINGCONDITIONCODE as building_condition,
        p.STYLECODE as architectural_style,

        -- Luxury Amenities
        p.POOLCODE as pool_code,
        CASE WHEN p.POOLCODE IS NOT NULL AND p.POOLCODE > 0 THEN 1 ELSE 0 END as has_pool,
        p.STORIESNBRCODE as stories,

        -- Climate Control
        p.AIRCONDITIONINGCODE as ac_code,
        CASE WHEN p.AIRCONDITIONINGCODE IS NOT NULL AND p.AIRCONDITIONINGCODE > 0 THEN 1 ELSE 0 END as has_ac,

        -- Basement
        p.BASEMENTCODE as basement_code,
        p.BASEMENTFINISHEDSQFT as basement_finished_sqft,
        CASE WHEN p.BASEMENTCODE IS NOT NULL THEN 1 ELSE 0 END as has_basement,

        -- Water Features
        p.WATERCODE as water_code,
        CASE WHEN p.WATERCODE IS NOT NULL AND p.WATERCODE > 0 THEN 1 ELSE 0 END as has_water_feature,

        -- ========================================================================
        -- Assessment & Market Values (predictive but lagged)
        -- ========================================================================
        p.ASSDTOTALVALUE as assessed_total_value,
        p.ASSDLANDVALUE as assessed_land_value,
        p.ASSDIMPROVEMENTVALUE as assessed_improvement_value,
        p.MARKETVALUELAND as market_value_land,
        p.MARKETVALUEIMPROVEMENT as market_value_improvements,

        -- Site Characteristics
        p.TOPOGRAPHYCODE as topography_code,
        p.SITEINFLUENCECODE as site_influence_code,

        -- Building Materials
        p.EXTERIORWALLSCODE as exterior_walls_code,
        p.ROOFCOVERCODE as roof_cover_code,

        -- Ownership
        p.OWNEROCCUPIED as is_owner_occupied,

        -- Transaction History
        p.PREVSALESPRICE as previous_sale_price,
        p.PREVSALERECORDINGDATE as previous_sale_date,

        -- Community
        p.SUBDIVISIONNAME as subdivision,
        p.ZONING as zoning,

        -- ========================================================================

        -- Census Demographics (Education)
        c.total_population_25plus,
        c.male_bachelors_degree,
        c.female_bachelors_degree,
        c.pct_bachelors_degree,

        -- Census Demographics (Population)
        c.total_population,
        c.non_hispanic_white_population,
        c.pct_white,

        -- Census Demographics (Income)
        c.median_earnings_total,
        c.median_earnings_male,
        c.median_earnings_female,
        c.median_household_income,

        -- Census Demographics (Housing)
        c.median_home_value,
        c.median_gross_rent,
        c.owner_occupied_units,
        c.renter_occupied_units,
        c.pct_owner_occupied,
        c.occupied_units,
        c.vacant_units,
        c.vacancy_rate,

        -- Census Demographics (Age & Employment)
        c.median_age,
        c.civilian_employed,
        c.civilian_unemployed,
        c.unemployment_rate,

        -- Derived: Wealth Concentration Metrics
        c.median_household_income * c.total_population / 1000000.0 as wealth_concentration_index,
        c.pct_bachelors_degree * c.median_household_income / 100000.0 as education_income_index,

        -- Election Data
        v.county_name,
        v.county_fips,
        v.votes_gop,
        v.votes_dem,
        v.total_votes,
        v.per_gop,
        v.per_dem,
        v.per_point_diff,
        v.dem_margin,
        v.rep_margin,

        -- Derived: Political Lean Strength (absolute difference)
        ABS(v.per_gop - v.per_dem) as political_lean_strength,

        -- State FIPS for partitioning
        LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 2) AS state_fips

    FROM roc_public_record_data."DATATREE"."ASSESSOR" p
    LEFT JOIN census_data c
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) || p.SITUSCENSUSTRACT = c.census_tract  -- FIXED JOIN
    LEFT JOIN "SCRATCH"."DATASCIENCE"."VOTING_PATTERNS_2020" v
        ON LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) = LPAD(TRIM(CAST(v.county_fips AS VARCHAR)), 5, '0')
    WHERE
        -- Location restrictions: NC around Raleigh, NY excluding NYC, All of OH
        (
            -- NC around Raleigh (Wake County and nearby Triangle counties)
            (p.SITUSSTATE = 'nc' AND LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) IN ('37183', '37063', '37101', '37069', '37135'))
            -- Wake, Durham, Johnston, Franklin, Orange
            OR
            -- New York excluding NYC (exclude Bronx, Kings, New York, Queens, Richmond)
            (p.SITUSSTATE = 'ny' AND LEFT(LPAD(TRIM(CAST(p.FIPS AS VARCHAR)), 5, '0'), 5) NOT IN ('36005', '36047', '36061', '36081', '36085'))
            OR
            -- All of Ohio
            (p.SITUSSTATE = 'oh')
        )

        -- Data quality filters
        AND p.CURRENTSALESPRICE IS NOT NULL
        AND p.SUMLIVINGAREASQFT IS NOT NULL
        AND p.LOTSIZESQFT IS NOT NULL
        AND p.SITUSLATITUDE IS NOT NULL
        AND p.SITUSLONGITUDE IS NOT NULL

        -- Exclude obvious data errors
        AND p.CURRENTSALESPRICE BETWEEN 10000 AND 100000000
        AND p.SUMLIVINGAREASQFT > 0
        AND p.LOTSIZESQFT > 0
        AND p.BEDROOMS > 0

        AND p.PROPERTYID IN (93817184, 89085494, 89350368, 89656411, 89663626, 92214221, 92245128,
90002154,
89899559,
93159811,
90027503,
92351615)

        -- Then apply data quality filters
        AND p.CURRENTSALESPRICE IS NOT NULL
        AND p.SUMLIVINGAREASQFT IS NOT NULL
),
random_sample AS (
    SELECT *
    FROM base
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY state_fips
        ORDER BY RANDOM()
    ) <= 1000
),
high_value_properties AS (
    SELECT *
    FROM base
    WHERE sale_price > 800000
)
-- Combine random sample with all high-value properties, removing duplicates
SELECT *
FROM random_sample
UNION
SELECT *
FROM high_value_properties
ORDER BY sale_price DESC;

------


with base as (select
SITUSCITY,
SITUSZIP5,
SITUSFULLSTREETADDRESS,
SITUSSTATE,
*
FROM roc_public_record_data."DATATREE"."ASSESSOR" p
WHERE propertyid
IN (92317183,
92317183,
91112664,
94183213,
94771755,
94182336,
94856780,
93373042,
94889281,
94326851,
96558265,
97757985,
98755237,
101539748,
102592297)
order by propertyid)
select
propertyid,
count(currentsaleprice)
from base
group by propertyid;


-----

with base as (select
SITUSCITY,
SITUSZIP5,
SITUSFULLSTREETADDRESS,
SITUSSTATE,
*
FROM roc_public_record_data."DATATREE"."ASSESSOR" p)
order by propertyid)
select
propertyid,
count(distinct marketyear)
from
base
group by
propertyid
having
count(distinct marketyear)>1;

----------

WITH base AS (
  SELECT
    SITUSCITY,
    SITUSZIP5,
    SITUSFULLSTREETADDRESS,
    SITUSSTATE,
    *
  FROM roc_public_record_data."DATATREE"."ASSESSOR" p
)
SELECT
  propertyid,
  COUNT(DISTINCT marketyear) AS year_count
FROM
  base
GROUP BY
  propertyid
HAVING
  COUNT(DISTINCT marketyear) > 1
ORDER BY
  COUNT(DISTINCT marketyear) DESC;

------

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    IS_IDENTITY,
    COMMENT
FROM roc_public_record_data.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'DATATREE'
  AND TABLE_NAME = 'ASSESSOR'
ORDER BY ORDINAL_POSITION;

----

SELECT
  PROPERTYID,
  COUNT(DISTINCT MARKETYEAR) AS year_count,
  MIN(MARKETYEAR) AS first_year,
  MAX(MARKETYEAR) AS last_year
FROM roc_public_record_data."DATATREE"."ASSESSOR"
WHERE MARKETYEAR IS NOT NULL
GROUP BY PROPERTYID
HAVING COUNT(DISTINCT MARKETYEAR) > 1
ORDER BY year_count DESC
LIMIT 100;
--------

WITH base AS (
  SELECT
    PROPERTYID,
    MARKETYEAR,
    SITUSCITY,
    SITUSZIP5,
    SITUSFULLSTREETADDRESS,
    SITUSSTATE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR IS NOT NULL
)
SELECT
  PROPERTYID,
  COUNT(DISTINCT MARKETYEAR) AS year_count,
  MIN(MARKETYEAR) AS first_year,
  MAX(MARKETYEAR) AS last_year
FROM base
GROUP BY PROPERTYID
HAVING COUNT(DISTINCT MARKETYEAR) > 1
ORDER BY year_count DESC
LIMIT 100;

-------------

WITH base AS (
  SELECT
    PROPERTYID,
    MARKETYEAR,
    SITUSCITY,
    SITUSZIP5,
    SITUSFULLSTREETADDRESS,
    SITUSSTATE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR IS NOT NULL
)
SELECT
  PROPERTYID,
  COUNT(DISTINCT MARKETYEAR) AS year_count,
  MIN(MARKETYEAR) AS first_year,
  MAX(MARKETYEAR) AS last_year
FROM base
GROUP BY PROPERTYID
HAVING COUNT(DISTINCT MARKETYEAR) > 1
ORDER BY year_count DESC
LIMIT 100;

---------

SELECT
    PROPERTYID,
    MARKETYEAR,
    SITUSCITY,
    SITUSZIP5,
    SITUSFULLSTREETADDRESS,
    SITUSSTATE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR IS NOT NULL;

---------

SELECT
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE,
    ROW_COUNT,
    BYTES
FROM
    INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_CATALOG = 'ROC_PUBLIC_RECORD_DATA'
    AND TABLE_SCHEMA = 'DATATREE'
ORDER BY
    TABLE_NAME;
----

USE DATABASE ROC_PUBLIC_RECORD_DATA;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    ORDINAL_POSITION
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_CATALOG = 'ROC_PUBLIC_RECORD_DATA'
    AND TABLE_SCHEMA = 'DATATREE'
    AND UPPER(COLUMN_NAME) LIKE '%PROPERTY%ID%'
ORDER BY
    TABLE_NAME, ORDINAL_POSITION;

-----

SELECT
    YEAR(SALEDATE) AS sale_year,
    COUNT(*) AS number_of_sales,
    COUNT(DISTINCT PROPERTYID) AS unique_properties_sold
FROM ROC_PUBLIC_RECORD_DATA."DATATREE"."RETRANSACTION"
WHERE SALEDATE IS NOT NULL
GROUP BY YEAR(SALEDATE)
ORDER BY sale_year DESC;

------

SELECT
    sales_count,
    COUNT(*) AS number_of_properties,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_properties
FROM (
    SELECT
        PROPERTYID,
        COUNT(*) AS sales_count
    FROM ROC_PUBLIC_RECORD_DATA."DATATREE"."RETRANSACTION"
    WHERE SALEDATE IS NOT NULL
    GROUP BY PROPERTYID
)
GROUP BY sales_count
ORDER BY sales_count;

------------

WITH base AS (
  SELECT
    PROPERTYID,
    MARKETYEAR,
    SITUSCITY,
    SITUSZIP5,
    SITUSFULLSTREETADDRESS,
    SITUSSTATE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR IS NOT NULL
)
SELECT
  PROPERTYID,
  COUNT(DISTINCT MARKETYEAR) AS year_count,
  MIN(MARKETYEAR) AS first_year,
  MAX(MARKETYEAR) AS last_year
FROM base
GROUP BY PROPERTYID
HAVING COUNT(DISTINCT MARKETYEAR) > 1
ORDER BY year_count DESC
LIMIT 100;

-------

WITH base AS (
  SELECT
    PROPERTYID,
    MARKETYEAR,
    SITUSCITY,
    SITUSZIP5,
    SITUSFULLSTREETADDRESS,
    SITUSSTATE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR IS NOT NULL
)
SELECT
  PROPERTYID,
  COUNT(DISTINCT MARKETYEAR) AS year_count,
  MIN(MARKETYEAR) AS first_year,
  MAX(MARKETYEAR) AS last_year
FROM base
GROUP BY PROPERTYID
HAVING COUNT(DISTINCT MARKETYEAR) > 1
ORDER BY year_count DESC
LIMIT 100;

----

SELECT
  PROPERTYID,
  COUNT(*) AS transaction_count,
  MIN(RECORDINGDATE) AS first_sale,
  MAX(RECORDINGDATE) AS last_sale,
  MAX(SALEAMT) - MIN(SALEAMT) AS price_change
FROM roc_public_record_data."DATATREE"."RETRANSACTION"
WHERE RECORDINGDATE IS NOT NULL
GROUP BY PROPERTYID
HAVING COUNT(*) > 1
ORDER BY transaction_count DESC
LIMIT 100;

--------------

SELECT DISTINCT
  PROPERTYID,
  SITUSSTATE,
  SITUSCITY,
  RECORDINGDATE,
  SALEAMT
  -- SITUSFULLSTREETADDRESS
FROM roc_public_record_data."DATATREE"."RETRANSACTION"
WHERE (UPPER(SITUSSTATE) = 'NY' OR UPPER(SITUSSTATE) = 'NEW YORK')
  AND RECORDINGDATE >= '2005-01-01'
  AND RECORDINGDATE <= '2025-12-31'
  AND PROPERTYID IS NOT NULL
ORDER BY PROPERTYID;

-----------

SELECT
    *
FROM roc_public_record_data."DATATREE"."ASSESSOR" limit 1

----------

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CASE WHEN IS_NULLABLE = 'YES' THEN 'NULL' ELSE 'NOT NULL' END AS nullable
FROM ROC_PUBLIC_RECORD_DATA.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_CATALOG = 'ROC_PUBLIC_RECORD_DATA'
    AND TABLE_SCHEMA = 'DATATREE'
    AND TABLE_NAME = 'ASSESSOR'
ORDER BY ORDINAL_POSITION;

-------------

WITH base_properties AS (
  SELECT DISTINCT PROPERTYID
  FROM roc_public_record_data."DATATREE"."RETRANSACTION"
  WHERE (UPPER(SITUSSTATE) = 'NY' OR UPPER(SITUSSTATE) = 'NEW YORK')
    AND SITUSZIP5 IN (
      '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
      '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
      '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
    )
    AND RECORDINGDATE >= '2005-01-01'
    AND PROPERTYID IS NOT NULL
),
property_history AS (
  SELECT
    a.PROPERTYID,
    a.MARKETYEAR,
    a.BEDROOMS,
    a.BATHFULL,
    a.BATHSPARTIALNBR,
    a.SITUSCITY,
    a.SITUSZIP5,
    a.SITUSFULLSTREETADDRESS,
    -- Get previous year values
    LAG(a.BEDROOMS) OVER (PARTITION BY a.PROPERTYID ORDER BY a.MARKETYEAR) AS prev_bedrooms,
    LAG(a.BATHFULL) OVER (PARTITION BY a.PROPERTYID ORDER BY a.MARKETYEAR) AS prev_bathfull,
    LAG(a.BATHSPARTIALNBR) OVER (PARTITION BY a.PROPERTYID ORDER BY a.MARKETYEAR) AS prev_halfbath
  FROM roc_public_record_data."DATATREE"."ASSESSOR" a
  INNER JOIN base_properties bp ON a.PROPERTYID = bp.PROPERTYID
  WHERE a.MARKETYEAR IS NOT NULL
    AND a.MARKETYEAR >= '2005'
),
changes_detected AS (
  SELECT
    PROPERTYID,
    MARKETYEAR AS change_year,
    SITUSCITY,
    SITUSZIP5,
    SITUSFULLSTREETADDRESS,
    -- Detect bedroom additions
    CASE
      WHEN BEDROOMS > prev_bedrooms THEN BEDROOMS - prev_bedrooms
      ELSE 0
    END AS bedrooms_added,
    -- Detect full bath additions
    CASE
      WHEN BATHFULL > prev_bathfull THEN BATHFULL - prev_bathfull
      ELSE 0
    END AS fullbath_added,
    -- Detect half bath additions
    CASE
      WHEN BATHSPARTIALNBR > prev_halfbath THEN BATHSPARTIALNBR - prev_halfbath
      ELSE 0
    END AS halfbath_added,
    -- Current and previous values for reference
    prev_bedrooms,
    BEDROOMS AS current_bedrooms,
    prev_bathfull,
    BATHFULL AS current_bathfull,
    prev_halfbath,
    BATHSPARTIALNBR AS current_halfbath
  FROM property_history
  WHERE prev_bedrooms IS NOT NULL -- Exclude first year (no comparison)
)
SELECT
  PROPERTYID,
  change_year AS effective_year,
  TO_DATE(change_year || '-01-01') AS effective_date_estimate,
  SITUSCITY AS city,
  SITUSZIP5 AS zip,
  SITUSFULLSTREETADDRESS AS address,
  -- Create change description
  CASE
    WHEN bedrooms_added > 0 AND fullbath_added > 0 AND halfbath_added > 0
      THEN 'Added ' || bedrooms_added || ' bedroom(s), ' || fullbath_added || ' full bath(s), ' || halfbath_added || ' half bath(s)'
    WHEN bedrooms_added > 0 AND fullbath_added > 0
      THEN 'Added ' || bedrooms_added || ' bedroom(s), ' || fullbath_added || ' full bath(s)'
    WHEN bedrooms_added > 0 AND halfbath_added > 0
      THEN 'Added ' || bedrooms_added || ' bedroom(s), ' || halfbath_added || ' half bath(s)'
    WHEN fullbath_added > 0 AND halfbath_added > 0
      THEN 'Added ' || fullbath_added || ' full bath(s), ' || halfbath_added || ' half bath(s)'
    WHEN bedrooms_added > 0
      THEN 'Added ' || bedrooms_added || ' bedroom(s)'
    WHEN fullbath_added > 0
      THEN 'Added ' || fullbath_added || ' full bath(s)'
    WHEN halfbath_added > 0
      THEN 'Added ' || halfbath_added || ' half bath(s)'
  END AS change_enacted,
  -- Before and after for verification
  prev_bedrooms || 'BR → ' || current_bedrooms || 'BR' AS bedroom_change,
  prev_bathfull || 'FB → ' || current_bathfull || 'FB' AS fullbath_change,
  prev_halfbath || 'HB → ' || current_halfbath || 'HB' AS halfbath_change
FROM changes_detected
WHERE bedrooms_added > 0
   OR fullbath_added > 0
   OR halfbath_added > 0
ORDER BY PROPERTYID, change_year;

----------





---------

SELECT
  SITUSZIP5,
  SITUSCITY,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM roc_public_record_data."DATATREE"."ASSESSOR"
WHERE SITUSZIP5 IN (
  '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
  '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
  '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
)
  AND MARKETYEAR >= '2005'
  AND MARKETYEAR <= '2025'
  AND PROPERTYID IS NOT NULL
GROUP BY SITUSZIP5, SITUSCITY
ORDER BY property_count DESC;



-------

with base as (SELECT DISTINCT
  PROPERTYID,
  SITUSSTATE,
  SITUSCITY,
  SITUSZIP5,
  RECORDINGDATE,
  SALEAMT
  -- SITUSFULLSTREETADDRESS
FROM roc_public_record_data."DATATREE"."RETRANSACTION"
WHERE (UPPER(SITUSSTATE) = 'NY' OR UPPER(SITUSSTATE) = 'NEW YORK')
  AND SITUSZIP5 IN (
    '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
    '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
    '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
  )
  AND RECORDINGDATE >= '2005-01-01'
  AND RECORDINGDATE <= '2025-12-31'
  AND PROPERTYID IS NOT NULL
ORDER BY PROPERTYID)
select
propertyid,
count(distinct saleamt)
from
base
group by
propertyid
having
count(distinct saleamt) > 4
order by count(distinct saleamt) desc;

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
  WHERE (UPPER(SITUSSTATE) = 'NY' OR UPPER(SITUSSTATE) = 'NEW YORK')
    AND SITUSZIP5 IN (
      '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
      '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
      '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
    )
    AND RECORDINGDATE >= '2005-01-01'
    AND RECORDINGDATE <= '2025-12-31'
    AND PROPERTYID IS NOT NULL
)
SELECT
  PROPERTYID,
  COUNT(DISTINCT SALEAMT) AS distinct_sale_count,
  COUNT(*) AS total_transactions,
  MIN(YEAR(RECORDINGDATE)) AS first_year,
  MAX(YEAR(RECORDINGDATE)) AS last_year,
  LISTAGG(DISTINCT YEAR(RECORDINGDATE), ', ') WITHIN GROUP (ORDER BY YEAR(RECORDINGDATE)) AS years_with_data,
  ANY_VALUE(SITUSCITY) AS city,
  ANY_VALUE(SITUSZIP5) AS zip
FROM base
GROUP BY PROPERTYID
HAVING COUNT(DISTINCT SALEAMT) > 4
ORDER BY COUNT(DISTINCT SALEAMT) DESC;

--------------


------------

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
      '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
      '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
      '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
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
sales_data AS (
  SELECT
    b.PROPERTYID,
    YEAR(b.RECORDINGDATE) AS sale_year,
    b.SALEAMT AS sale_amount,
    b.RECORDINGDATE AS sale_date,
    b.SITUSCITY AS city,
    b.SITUSZIP5 AS zip
  FROM base b
  INNER JOIN properties_with_multiple_sales p ON b.PROPERTYID = p.PROPERTYID
),
property_features AS (
  SELECT DISTINCT
    PROPERTYID,
    -- Size
    SUMLIVINGAREASQFT,
    LOTSIZESQFT,
    SUMBUILDINGSQFT,
    SUMBASEMENTSQFT,
    SUMGARAGESQFT,
    -- Structure
    YEARBUILT,
    EFFECTIVEYEARBUILT,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR,
    TOTALROOMS,
    -- Features
    FIREPLACECODE,
    POOLCODE,
    GARAGEPARKINGNBR,
    AIRCONDITIONINGCODE,
    STORIESNBRCODE,
    -- Quality
    BUILDINGQUALITYCODE,
    BUILDINGCONDITIONCODE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR = (
    SELECT MAX(MARKETYEAR)
    FROM roc_public_record_data."DATATREE"."ASSESSOR" a2
    WHERE a2.PROPERTYID = ASSESSOR.PROPERTYID
  )
)
SELECT
  sd.PROPERTYID,
  sd.sale_year,
  sd.sale_amount,
  sd.sale_date,
  sd.city,
  sd.zip,
  -- Property Features
  pf.SUMLIVINGAREASQFT,
  pf.LOTSIZESQFT,
  pf.SUMBUILDINGSQFT,
  pf.SUMBASEMENTSQFT,
  pf.SUMGARAGESQFT,
  pf.YEARBUILT,
  pf.EFFECTIVEYEARBUILT,
  pf.BEDROOMS,
  pf.BATHFULL,
  pf.BATHSPARTIALNBR,
  pf.TOTALROOMS,
  pf.FIREPLACECODE,
  pf.POOLCODE,
  pf.GARAGEPARKINGNBR,
  pf.AIRCONDITIONINGCODE,
  pf.STORIESNBRCODE,
  pf.BUILDINGQUALITYCODE,
  pf.BUILDINGCONDITIONCODE
FROM sales_data sd
LEFT JOIN property_features pf ON sd.PROPERTYID = pf.PROPERTYID
ORDER BY sd.PROPERTYID, sd.RECORDINGDATE;

----

WITH property_history AS (
  SELECT
    a.PROPERTYID,
    a.MARKETYEAR,
    a.BEDROOMS,
    a.BATHFULL,
    a.BATHSPARTIALNBR,
    a.SITUSCITY,
    a.SITUSZIP5,
    LAG(a.BEDROOMS) OVER (PARTITION BY a.PROPERTYID ORDER BY a.MARKETYEAR) AS prev_bedrooms,
    LAG(a.BATHFULL) OVER (PARTITION BY a.PROPERTYID ORDER BY a.MARKETYEAR) AS prev_bathfull,
    LAG(a.BATHSPARTIALNBR) OVER (PARTITION BY a.PROPERTYID ORDER BY a.MARKETYEAR) AS prev_halfbath
  FROM roc_public_record_data."DATATREE"."ASSESSOR" a
  WHERE a.SITUSZIP5 IN (
    '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
    '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
    '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
  )
    AND (UPPER(a.SITUSSTATE) = 'NY' OR UPPER(a.SITUSSTATE) = 'NEW YORK')
    AND a.MARKETYEAR IS NOT NULL
    AND a.MARKETYEAR >= '2005'
)
SELECT
  PROPERTYID,
  MARKETYEAR AS effective_year,
  SITUSCITY AS city,
  SITUSZIP5 AS zip,
  CONCAT_WS(', ',
    CASE WHEN BEDROOMS > COALESCE(prev_bedrooms, 0)
      THEN 'Added ' || (BEDROOMS - COALESCE(prev_bedrooms, 0)) || ' bedroom(s)' END,
    CASE WHEN BATHFULL > COALESCE(prev_bathfull, 0)
      THEN 'Added ' || (BATHFULL - COALESCE(prev_bathfull, 0)) || ' full bath(s)' END,
    CASE WHEN BATHSPARTIALNBR > COALESCE(prev_halfbath, 0)
      THEN 'Added ' || (BATHSPARTIALNBR - COALESCE(prev_halfbath, 0)) || ' half bath(s)' END
  ) AS change_enacted,
  prev_bedrooms,
  BEDROOMS AS current_bedrooms,
  prev_bathfull,
  BATHFULL AS current_bathfull,
  prev_halfbath,
  BATHSPARTIALNBR AS current_halfbath
FROM property_history
WHERE (BEDROOMS > COALESCE(prev_bedrooms, 0)
   OR BATHFULL > COALESCE(prev_bathfull, 0)
   OR BATHSPARTIALNBR > COALESCE(prev_halfbath, 0))
  AND prev_bedrooms IS NOT NULL
ORDER BY PROPERTYID, MARKETYEAR
LIMIT 100;

----- Check if ASSESSOR has data for these ZIPs at all
SELECT
  SITUSZIP5,
  COUNT(DISTINCT PROPERTYID) AS property_count,
  COUNT(DISTINCT MARKETYEAR) AS year_count,
  MIN(MARKETYEAR) AS earliest_year,
  MAX(MARKETYEAR) AS latest_year,
  COUNT(*) AS total_rows
FROM roc_public_record_data."DATATREE"."ASSESSOR"
WHERE SITUSZIP5 IN (
  '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
  '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
  '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
)
GROUP BY SITUSZIP5
ORDER BY property_count DESC;

-----

-- Check if ASSESSOR has data for these ZIPs at all
SELECT
  SITUSZIP5,
  COUNT(DISTINCT PROPERTYID) AS property_count,
  COUNT(DISTINCT MARKETYEAR) AS year_count,
  MIN(MARKETYEAR) AS earliest_year,
  MAX(MARKETYEAR) AS latest_year,
  COUNT(*) AS total_rows
FROM roc_public_record_data."DATATREE"."ASSESSOR"
WHERE SITUSZIP5 IN (
  '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
  '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
  '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
)
GROUP BY SITUSZIP5
ORDER BY property_count DESC;

------







-- Sample properties with bedroom/bath data
SELECT
  PROPERTYID,
  MARKETYEAR,
  BEDROOMS,
  BATHFULL,
  BATHSPARTIALNBR,
  SITUSZIP5,
  SITUSCITY
FROM roc_public_record_data."DATATREE"."ASSESSOR"
WHERE SITUSZIP5 IN (
  '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
  '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
  '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
)
  AND BEDROOMS IS NOT NULL
  AND MARKETYEAR IS NOT NULL
ORDER BY PROPERTYID, MARKETYEAR
LIMIT 50;

----
-- Check how many properties have multiple assessment years
SELECT
  COUNT(CASE WHEN year_count > 1 THEN 1 END) AS properties_with_multiple_years,
  COUNT(*) AS total_properties,
  MAX(year_count) AS max_years_per_property
FROM (
  SELECT
    PROPERTYID,
    COUNT(DISTINCT MARKETYEAR) AS year_count
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE SITUSZIP5 IN (
    '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
    '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
    '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
  )
    AND MARKETYEAR IS NOT NULL
  GROUP BY PROPERTYID
);


-- Show properties with multiple years AND their bedroom/bath values
SELECT
  PROPERTYID,
  MARKETYEAR,
  BEDROOMS,
  BATHFULL,
  BATHSPARTIALNBR,
  SITUSZIP5
FROM roc_public_record_data."DATATREE"."ASSESSOR"
WHERE PROPERTYID IN (
  SELECT PROPERTYID
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE SITUSZIP5 IN (
    '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
    '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
    '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
  )
  GROUP BY PROPERTYID
  HAVING COUNT(DISTINCT MARKETYEAR) > 1
  LIMIT 5
)
ORDER BY PROPERTYID, MARKETYEAR;
----

-- Get all column names from RETRANSACTION
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_SCHEMA = 'DATATREE'
  -- AND TABLE_NAME = 'RETRANSACTION'
ORDER BY ORDINAL_POSITION;

---

-- Get all schemas and their tables
SELECT
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN (
  SELECT SCHEMA_NAME
  FROM INFORMATION_SCHEMA.SCHEMATA
  WHERE SCHEMA_NAME NOT IN ('INFORMATION_SCHEMA', 'PERFORMANCE_SCHEMA')
)
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

----
-- Check for MLS-related tables
SELECT
  TABLE_NAME,
  ROW_COUNT
FROM roc_public_record_data.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DATATREE'
  AND (TABLE_NAME LIKE '%MLS%'
       OR TABLE_NAME LIKE '%LISTING%'
       OR TABLE_NAME LIKE '%SALE%'
       OR TABLE_NAME LIKE '%FORECLOSURE%')
ORDER BY TABLE_NAME;

-----

-- Show all tables in DATATREE schema
SELECT TABLE_NAME
FROM roc_public_record_data.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DATATREE'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


----

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
      '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
      '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
      '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
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
sales_data AS (
  SELECT
    b.PROPERTYID,
    YEAR(b.RECORDINGDATE) AS sale_year,
    b.SALEAMT AS sale_amount,
    b.RECORDINGDATE AS sale_date,
    b.SITUSCITY AS city,
    b.SITUSZIP5 AS zip
  FROM base b
  INNER JOIN properties_with_multiple_sales p ON b.PROPERTYID = p.PROPERTYID
),
property_features AS (
  SELECT DISTINCT
    PROPERTYID,
    -- Size
    SUMLIVINGAREASQFT,
    LOTSIZESQFT,
    SUMBUILDINGSQFT,
    SUMBASEMENTSQFT,
    SUMGARAGESQFT,
    -- Structure
    YEARBUILT,
    EFFECTIVEYEARBUILT,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR,
    TOTALROOMS,
    -- Features
    FIREPLACECODE,
    POOLCODE,
    GARAGEPARKINGNBR,
    AIRCONDITIONINGCODE,
    STORIESNBRCODE,
    -- Quality
    BUILDINGQUALITYCODE,
    BUILDINGCONDITIONCODE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR = (
    SELECT MAX(MARKETYEAR)
    FROM roc_public_record_data."DATATREE"."ASSESSOR" a2
    WHERE a2.PROPERTYID = ASSESSOR.PROPERTYID
  )
)
SELECT
  sd.PROPERTYID,
  sd.sale_year,
  sd.sale_amount,
  sd.sale_date,
  sd.city,
  sd.zip,
  -- Property Features
  pf.SUMLIVINGAREASQFT,
  pf.LOTSIZESQFT,
  pf.SUMBUILDINGSQFT,
  pf.SUMBASEMENTSQFT,
  pf.SUMGARAGESQFT,
  pf.YEARBUILT,
  pf.EFFECTIVEYEARBUILT,
  pf.BEDROOMS,
  pf.BATHFULL,
  pf.BATHSPARTIALNBR,
  pf.TOTALROOMS,
  pf.FIREPLACECODE,
  pf.POOLCODE,
  pf.GARAGEPARKINGNBR,
  pf.AIRCONDITIONINGCODE,
  pf.STORIESNBRCODE,
  pf.BUILDINGQUALITYCODE,
  pf.BUILDINGCONDITIONCODE
FROM sales_data sd
LEFT JOIN property_features pf ON sd.PROPERTYID = pf.PROPERTYID
ORDER BY sd.PROPERTYID, sd.sale_date;

-----

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

      -- Additional 25 ZIPs for geographic diversity
      -- Westchester/Lower Hudson Valley
      '10562', '10601', '10583', '10701', '10533',
      -- Capital Region (Albany area)
      '12203', '12110', '12189', '12208', '12302',
      -- Rochester area
      '14617', '14618', '14626', '14534', '14450',
      -- Syracuse area
      '13210', '13224', '13088', '13215',
      -- Buffalo suburbs
      '14221', '14226', '14072', '14127',
      -- Long Island
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
sales_data AS (
  SELECT
    b.PROPERTYID,
    YEAR(b.RECORDINGDATE) AS sale_year,
    b.SALEAMT AS sale_amount,
    b.RECORDINGDATE AS sale_date,
    b.SITUSCITY AS city,
    b.SITUSZIP5 AS zip
  FROM base b
  INNER JOIN properties_with_multiple_sales p ON b.PROPERTYID = p.PROPERTYID
),
property_features AS (
  SELECT DISTINCT
    PROPERTYID,
    -- Size
    SUMLIVINGAREASQFT,
    LOTSIZESQFT,
    SUMBUILDINGSQFT,
    SUMBASEMENTSQFT,
    SUMGARAGESQFT,
    -- Structure
    YEARBUILT,
    EFFECTIVEYEARBUILT,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR,
    TOTALROOMS,
    -- Features
    FIREPLACECODE,
    POOLCODE,
    GARAGEPARKINGNBR,
    AIRCONDITIONINGCODE,
    STORIESNBRCODE,
    -- Quality
    BUILDINGQUALITYCODE,
    BUILDINGCONDITIONCODE
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE MARKETYEAR = (
    SELECT MAX(MARKETYEAR)
    FROM roc_public_record_data."DATATREE"."ASSESSOR" a2
    WHERE a2.PROPERTYID = ASSESSOR.PROPERTYID
  )
)
SELECT
  sd.PROPERTYID,
  sd.sale_year,
  sd.sale_amount,
  sd.sale_date,
  sd.city,
  sd.zip,
  -- Property Features
  pf.SUMLIVINGAREASQFT,
  pf.LOTSIZESQFT,
  pf.SUMBUILDINGSQFT,
  pf.SUMBASEMENTSQFT,
  pf.SUMGARAGESQFT,
  pf.YEARBUILT,
  pf.EFFECTIVEYEARBUILT,
  pf.BEDROOMS,
  pf.BATHFULL,
  pf.BATHSPARTIALNBR,
  pf.TOTALROOMS,
  pf.FIREPLACECODE,
  pf.POOLCODE,
  pf.GARAGEPARKINGNBR,
  pf.AIRCONDITIONINGCODE,
  pf.STORIESNBRCODE,
  pf.BUILDINGQUALITYCODE,
  pf.BUILDINGCONDITIONCODE
FROM sales_data sd
LEFT JOIN property_features pf ON sd.PROPERTYID = pf.PROPERTYID
ORDER BY sd.PROPERTYID, sd.sale_date;

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
ORDER BY BEDROOMS

UNION ALL

-- Count by Full Bathrooms
SELECT
  'Full Bathrooms' AS category,
  COALESCE(BATHFULL, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BATHFULL
ORDER BY BATHFULL

UNION ALL

-- Count by Partial Bathrooms
SELECT
  'Partial Bathrooms' AS category,
  COALESCE(BATHSPARTIALNBR, 0) AS level,
  COUNT(DISTINCT PROPERTYID) AS property_count
FROM unique_properties
GROUP BY BATHSPARTIALNBR
ORDER BY BATHSPARTIALNBR;

------------------

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

------------

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
       AND SITUSZIP5 NOT LIKE '100%'
       AND SITUSZIP5 NOT LIKE '101%'
       AND SITUSZIP5 NOT LIKE '102%'
       AND SITUSZIP5 NOT LIKE '103%'
       AND SITUSZIP5 NOT LIKE '104%'
       AND SITUSZIP5 NOT LIKE '112%'
       AND SITUSZIP5 NOT LIKE '113%'
       AND SITUSZIP5 NOT LIKE '114%'
       AND SITUSZIP5 NOT LIKE '116%'
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
properties_with_features AS (
  SELECT
    p.PROPERTYID,
    COALESCE(pf.BEDROOMS, 0) AS BEDROOMS,
    COALESCE(pf.BATHFULL, 0) AS BATHFULL,
    COALESCE(pf.BATHSPARTIALNBR, 0) AS BATHSPARTIALNBR,
    -- Create a bathroom configuration grouping for stratification
    CONCAT(COALESCE(pf.BATHFULL, 0), '_', COALESCE(pf.BATHSPARTIALNBR, 0)) AS bath_config
  FROM properties_with_multiple_sales p
  LEFT JOIN property_features pf ON p.PROPERTYID = pf.PROPERTYID
  WHERE pf.BEDROOMS IN (2, 3)  -- Filter for 2BR and 3BR only
),
-- Sample 2BR properties, stratified by bathroom configuration
two_bedroom_sample AS (
  SELECT
    PROPERTYID,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR,
    bath_config,
    ROW_NUMBER() OVER (PARTITION BY bath_config ORDER BY RANDOM()) AS rn,
    COUNT(*) OVER (PARTITION BY bath_config) AS config_count
  FROM properties_with_features
  WHERE BEDROOMS = 2
),
two_bedroom_selected AS (
  SELECT
    PROPERTYID,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR,
    bath_config
  FROM two_bedroom_sample
  WHERE rn <= GREATEST(1, FLOOR(10000.0 * config_count / (SELECT COUNT(*) FROM properties_with_features WHERE BEDROOMS = 2)))
  LIMIT 10000
),
-- Sample 3BR properties, stratified by bathroom configuration
three_bedroom_sample AS (
  SELECT
    PROPERTYID,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR,
    bath_config,
    ROW_NUMBER() OVER (PARTITION BY bath_config ORDER BY RANDOM()) AS rn,
    COUNT(*) OVER (PARTITION BY bath_config) AS config_count
  FROM properties_with_features
  WHERE BEDROOMS = 3
),
three_bedroom_selected AS (
  SELECT
    PROPERTYID,
    BEDROOMS,
    BATHFULL,
    BATHSPARTIALNBR,
    bath_config
  FROM three_bedroom_sample
  WHERE rn <= GREATEST(1, FLOOR(10000.0 * config_count / (SELECT COUNT(*) FROM properties_with_features WHERE BEDROOMS = 3)))
  LIMIT 10000
)
-- Combine both samples
SELECT
  PROPERTYID,
  BEDROOMS,
  BATHFULL,
  BATHSPARTIALNBR,
  bath_config
FROM two_bedroom_selected
UNION ALL
SELECT
  PROPERTYID,
  BEDROOMS,
  BATHFULL,
  BATHSPARTIALNBR,
  bath_config
FROM three_bedroom_selected
ORDER BY BEDROOMS, bath_config, RANDOM();














----

select
*
from
(SELECT COLUMN_NAME, DATA_TYPE
FROM roc_public_record_data.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'DATATREE'
  AND TABLE_NAME = 'FORECLOSURE'
ORDER BY ORDINAL_POSITION)
UNION
(SELECT COLUMN_NAME, DATA_TYPE
FROM roc_public_record_data.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'DATATREE'
  AND TABLE_NAME = 'ASSIGNMENT'
ORDER BY ORDINAL_POSITION);



SHOW DATABASES;

--------------

-- See tables in ROC_MLS_DATA
SELECT
  TABLE_SCHEMA,
  TABLE_NAME,
  COLUMN_NAME
FROM ROC_MLS_DATA.INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

---

-- Find properties with listings in multiple years
WITH property_history AS (
  SELECT
    CC_PROPERTY_ID,
    YEAR(A_DATE) AS listing_year,
    COUNT(*) AS listings_that_year,
    MIN(A_DATE) AS first_listing,
    MAX(A_DATE) AS last_listing
  FROM ROC_MLS_DATA.ATTOM.MLS
  WHERE STATE IN ('NY', 'New York')
    AND ZIP IN (
      '12814', '12409', '10987', '12824', '12526', '12457', '10524', '10516',
      '12808', '13152', '12572', '12498', '12461', '10917', '14202', '14031',
      '10916', '12525', '12997', '12540', '12866', '12577', '12075', '12148', '10950'
    )
    AND A_DATE IS NOT NULL
  GROUP BY CC_PROPERTY_ID, YEAR(A_DATE)
)
SELECT
  CC_PROPERTY_ID,
  COUNT(DISTINCT listing_year) AS years_with_listings,
  MIN(listing_year) AS first_year,
  MAX(listing_year) AS last_year,
  SUM(listings_that_year) AS total_listings
FROM property_history
GROUP BY CC_PROPERTY_ID
HAVING COUNT(DISTINCT listing_year) > 1
ORDER BY years_with_listings DESC, total_listings DESC
LIMIT 20;






select * from roc_public_record_data."DATATREE"."RETRANSACTION" limit 1;






------------



select * from ROC_PUBLIC_RECORD_DATA."DATATREE"."RETRANSACTION" limit 1;



-----





-- Check for bedroom upgrades
WITH property_changes AS (
  SELECT
    PROPERTYID,
    MARKETYEAR,
    BEDROOMS,
    LAG(BEDROOMS) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_bedrooms,
    LAG(MARKETYEAR) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_year,
    BATHFULL,
    LAG(BATHFULL) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_bathfull,
    SUMLIVINGAREASQFT,
    LAG(SUMLIVINGAREASQFT) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_sqft
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE PROPERTYID IN (
    -- Focus on properties from your filtered set
    SELECT DISTINCT PROPERTYID
    FROM roc_public_record_data."DATATREE"."RETRANSACTION"
    WHERE (
        (UPPER(SITUSSTATE) IN ('NY', 'NEW YORK')
         AND SITUSZIP5 NOT LIKE '100%' AND SITUSZIP5 NOT LIKE '101%'
         AND SITUSZIP5 NOT LIKE '102%' AND SITUSZIP5 NOT LIKE '103%'
         AND SITUSZIP5 NOT LIKE '104%' AND SITUSZIP5 NOT LIKE '112%'
         AND SITUSZIP5 NOT LIKE '113%' AND SITUSZIP5 NOT LIKE '114%'
         AND SITUSZIP5 NOT LIKE '116%')
        OR UPPER(SITUSSTATE) IN ('OH', 'OHIO')
      )
      AND RECORDINGDATE >= '2005-01-01'
      AND PROPERTYID IS NOT NULL
  )
)
SELECT
  'Bedroom Upgrade' AS upgrade_type,
  PROPERTYID,
  prev_year AS from_year,
  MARKETYEAR AS to_year,
  prev_bedrooms AS from_value,
  BEDROOMS AS to_value,
  (BEDROOMS - prev_bedrooms) AS change
FROM property_changes
WHERE BEDROOMS > prev_bedrooms
  AND prev_bedrooms IS NOT NULL

UNION ALL

SELECT
  'Bathroom Upgrade' AS upgrade_type,
  PROPERTYID,
  prev_year AS from_year,
  MARKETYEAR AS to_year,
  prev_bathfull AS from_value,
  BATHFULL AS to_value,
  (BATHFULL - prev_bathfull) AS change
FROM property_changes
WHERE BATHFULL > prev_bathfull
  AND prev_bathfull IS NOT NULL

UNION ALL

SELECT
  'Square Footage Increase' AS upgrade_type,
  PROPERTYID,
  prev_year AS from_year,
  MARKETYEAR AS to_year,
  prev_sqft AS from_value,
  SUMLIVINGAREASQFT AS to_value,
  (SUMLIVINGAREASQFT - prev_sqft) AS change
FROM property_changes
WHERE SUMLIVINGAREASQFT > prev_sqft
  AND prev_sqft IS NOT NULL
  AND (SUMLIVINGAREASQFT - prev_sqft) > 100  -- At least 100 sqft increase

ORDER BY upgrade_type, PROPERTYID, from_year;

-- summary count of upgrades --

WITH property_changes AS (
  SELECT
    PROPERTYID,
    MARKETYEAR,
    BEDROOMS,
    LAG(BEDROOMS) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_bedrooms,
    BATHFULL,
    LAG(BATHFULL) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_bathfull,
    BATHSPARTIALNBR,
    LAG(BATHSPARTIALNBR) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_partial_bath,
    SUMLIVINGAREASQFT,
    LAG(SUMLIVINGAREASQFT) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_sqft,
    TOTALROOMS,
    LAG(TOTALROOMS) OVER (PARTITION BY PROPERTYID ORDER BY MARKETYEAR) AS prev_total_rooms
  FROM roc_public_record_data."DATATREE"."ASSESSOR"
  WHERE PROPERTYID IN (
    SELECT DISTINCT PROPERTYID
    FROM roc_public_record_data."DATATREE"."RETRANSACTION"
    WHERE (
        (UPPER(SITUSSTATE) IN ('NY', 'NEW YORK')
         AND SITUSZIP5 NOT LIKE '100%' AND SITUSZIP5 NOT LIKE '101%'
         AND SITUSZIP5 NOT LIKE '102%' AND SITUSZIP5 NOT LIKE '103%'
         AND SITUSZIP5 NOT LIKE '104%' AND SITUSZIP5 NOT LIKE '112%'
         AND SITUSZIP5 NOT LIKE '113%' AND SITUSZIP5 NOT LIKE '114%'
         AND SITUSZIP5 NOT LIKE '116%')
        OR UPPER(SITUSSTATE) IN ('OH', 'OHIO')
      )
      AND RECORDINGDATE >= '2005-01-01'
      AND PROPERTYID IS NOT NULL
  )
)
SELECT
  'Bedroom' AS feature,
  COUNT(DISTINCT PROPERTYID) AS properties_upgraded,
  COUNT(*) AS total_upgrades,
  AVG(BEDROOMS - prev_bedrooms) AS avg_increase
FROM property_changes
WHERE BEDROOMS > prev_bedrooms AND prev_bedrooms IS NOT NULL

UNION ALL

SELECT
  'Full Bathroom' AS feature,
  COUNT(DISTINCT PROPERTYID) AS properties_upgraded,
  COUNT(*) AS total_upgrades,
  AVG(BATHFULL - prev_bathfull) AS avg_increase
FROM property_changes
WHERE BATHFULL > prev_bathfull AND prev_bathfull IS NOT NULL

UNION ALL

SELECT
  'Partial Bathroom' AS feature,
  COUNT(DISTINCT PROPERTYID) AS properties_upgraded,
  COUNT(*) AS total_upgrades,
  AVG(BATHSPARTIALNBR - prev_partial_bath) AS avg_increase
FROM property_changes
WHERE BATHSPARTIALNBR > prev_partial_bath AND prev_partial_bath IS NOT NULL

UNION ALL

SELECT
  'Total Rooms' AS feature,
  COUNT(DISTINCT PROPERTYID) AS properties_upgraded,
  COUNT(*) AS total_upgrades,
  AVG(TOTALROOMS - prev_total_rooms) AS avg_increase
FROM property_changes
WHERE TOTALROOMS > prev_total_rooms AND prev_total_rooms IS NOT NULL

UNION ALL

SELECT
  'Square Footage' AS feature,
  COUNT(DISTINCT PROPERTYID) AS properties_upgraded,
  COUNT(*) AS total_upgrades,
  AVG(SUMLIVINGAREASQFT - prev_sqft) AS avg_increase
FROM property_changes
WHERE SUMLIVINGAREASQFT > prev_sqft
  AND prev_sqft IS NOT NULL
  AND (SUMLIVINGAREASQFT - prev_sqft) > 100

ORDER BY properties_upgraded DESC;

---------


-- Simple check of ASSESSOR table structure
SELECT
  COUNT(DISTINCT PROPERTYID) AS unique_properties,
  COUNT(DISTINCT MARKETYEAR) AS unique_years,
  COUNT(*) AS total_records,
  COUNT(*) / COUNT(DISTINCT PROPERTYID) AS avg_records_per_property,
  MIN(MARKETYEAR) AS earliest_year,
  MAX(MARKETYEAR) AS latest_year
FROM roc_public_record_data."DATATREE"."ASSESSOR"
WHERE PROPERTYID IN (
  SELECT DISTINCT PROPERTYID
  FROM roc_public_record_data."DATATREE"."RETRANSACTION"
  WHERE (
      (UPPER(SITUSSTATE) IN ('NY', 'NEW YORK')
       AND SITUSZIP5 NOT LIKE '100%' AND SITUSZIP5 NOT LIKE '101%'
       AND SITUSZIP5 NOT LIKE '102%' AND SITUSZIP5 NOT LIKE '103%'
       AND SITUSZIP5 NOT LIKE '104%' AND SITUSZIP5 NOT LIKE '112%'
       AND SITUSZIP5 NOT LIKE '113%' AND SITUSZIP5 NOT LIKE '114%'
       AND SITUSZIP5 NOT LIKE '116%')
      OR UPPER(SITUSSTATE) IN ('OH', 'OHIO')
    )
    AND RECORDINGDATE >= '2005-01-01'
    AND PROPERTYID IS NOT NULL
  LIMIT 10000
);

-------

-- Get all schemas across all databases
SELECT
  CATALOG_NAME AS database_name,
  SCHEMA_NAME,
  CREATED,
  COMMENT
FROM INFORMATION_SCHEMA.SCHEMATA
ORDER BY CATALOG_NAME, SCHEMA_NAME;

--------

-- Search for property-related tables with time series potential across all databases
SELECT
  TABLE_CATALOG AS database_name,
  TABLE_SCHEMA AS schema_name,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM REAL_PROPERTY_INSIGHTS_DEMOSAMPLE.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM ANALYTICS.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM ATTOM_HOUSE_IQ_SHARE.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM DBT_DEV.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM EXT_ROC_GEO.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM FSQ_OPEN_SOURCE_PLACES.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM HIQ_DEV.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM ROC_ANALYTICS.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM ROC_MLS_DATA.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM ROC_PUBLIC_RECORD_DATA.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM ROC_RELATIONALAI.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM SCRATCH.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM "USER$JLIN".INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM US_OPEN_CENSUS_DATA__NEIGHBORHOOD_INSIGHTS__FREE_DATASET.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROW_COUNT,
  COMMENT
FROM US_REAL_ESTATE.INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

ORDER BY database_name, schema_name, TABLE_NAME;

-----

-- Find tables with both property identifiers AND date/year columns
WITH all_columns AS (
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM REAL_PROPERTY_INSIGHTS_DEMOSAMPLE.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ANALYTICS.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ATTOM_HOUSE_IQ_SHARE.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM DBT_DEV.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM EXT_ROC_GEO.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM HIQ_DEV.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_ANALYTICS.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_MLS_DATA.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_PUBLIC_RECORD_DATA.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_RELATIONALAI.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM SCRATCH.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM "USER$JLIN".INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM US_REAL_ESTATE.INFORMATION_SCHEMA.COLUMNS
)
SELECT
  TABLE_CATALOG AS database_name,
  TABLE_SCHEMA AS schema_name,
  TABLE_NAME,
  LISTAGG(DISTINCT
    CASE
      WHEN LOWER(COLUMN_NAME) LIKE '%property%id%'
        OR LOWER(COLUMN_NAME) LIKE '%parcel%id%'
        OR LOWER(COLUMN_NAME) = 'propertyid'
        OR LOWER(COLUMN_NAME) = 'parcelid'
      THEN COLUMN_NAME
    END, ', ') WITHIN GROUP (ORDER BY COLUMN_NAME) AS property_id_columns,
  LISTAGG(DISTINCT
    CASE
      WHEN LOWER(COLUMN_NAME) LIKE '%date%'
        OR LOWER(COLUMN_NAME) LIKE '%year%'
        OR LOWER(COLUMN_NAME) LIKE '%time%'
        OR DATA_TYPE IN ('DATE', 'TIMESTAMP_NTZ', 'TIMESTAMP_LTZ')
      THEN COLUMN_NAME
    END, ', ') WITHIN GROUP (ORDER BY COLUMN_NAME) AS date_year_columns,
  LISTAGG(DISTINCT
    CASE
      WHEN LOWER(COLUMN_NAME) LIKE '%bedroom%'
        OR LOWER(COLUMN_NAME) LIKE '%bath%'
        OR LOWER(COLUMN_NAME) LIKE '%sqft%'
        OR LOWER(COLUMN_NAME) LIKE '%area%'
        OR LOWER(COLUMN_NAME) LIKE '%garage%'
        OR LOWER(COLUMN_NAME) LIKE '%pool%'
        OR LOWER(COLUMN_NAME) LIKE '%story%'
        OR LOWER(COLUMN_NAME) LIKE '%room%'
      THEN COLUMN_NAME
    END, ', ') WITHIN GROUP (ORDER BY COLUMN_NAME) AS feature_columns
FROM all_columns
GROUP BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
HAVING property_id_columns IS NOT NULL
  AND date_year_columns IS NOT NULL
  AND feature_columns IS NOT NULL
ORDER BY database_name, schema_name, TABLE_NAME;

------------

-- Find tables with both property identifiers AND date/year columns
WITH all_columns AS (
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM REAL_PROPERTY_INSIGHTS_DEMOSAMPLE.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ANALYTICS.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ATTOM_HOUSE_IQ_SHARE.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM DBT_DEV.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM EXT_ROC_GEO.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM HIQ_DEV.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_ANALYTICS.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_MLS_DATA.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_PUBLIC_RECORD_DATA.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM ROC_RELATIONALAI.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM SCRATCH.INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM "USER$JLIN".INFORMATION_SCHEMA.COLUMNS
  UNION ALL
  SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE
  FROM US_REAL_ESTATE.INFORMATION_SCHEMA.COLUMNS
),
categorized_columns AS (
  SELECT
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CASE
      WHEN LOWER(COLUMN_NAME) LIKE '%property%id%'
        OR LOWER(COLUMN_NAME) LIKE '%parcel%id%'
        OR LOWER(COLUMN_NAME) = 'propertyid'
        OR LOWER(COLUMN_NAME) = 'parcelid'
      THEN 1 ELSE 0
    END AS is_property_id,
    CASE
      WHEN LOWER(COLUMN_NAME) LIKE '%date%'
        OR LOWER(COLUMN_NAME) LIKE '%year%'
        OR LOWER(COLUMN_NAME) LIKE '%time%'
        OR DATA_TYPE IN ('DATE', 'TIMESTAMP_NTZ', 'TIMESTAMP_LTZ')
      THEN 1 ELSE 0
    END AS is_date_year,
    CASE
      WHEN LOWER(COLUMN_NAME) LIKE '%bedroom%'
        OR LOWER(COLUMN_NAME) LIKE '%bath%'
        OR LOWER(COLUMN_NAME) LIKE '%sqft%'
        OR LOWER(COLUMN_NAME) LIKE '%area%'
        OR LOWER(COLUMN_NAME) LIKE '%garage%'
        OR LOWER(COLUMN_NAME) LIKE '%pool%'
        OR LOWER(COLUMN_NAME) LIKE '%story%'
        OR LOWER(COLUMN_NAME) LIKE '%room%'
      THEN 1 ELSE 0
    END AS is_feature
  FROM all_columns
)
SELECT
  TABLE_CATALOG AS database_name,
  TABLE_SCHEMA AS schema_name,
  TABLE_NAME,
  LISTAGG(DISTINCT CASE WHEN is_property_id = 1 THEN COLUMN_NAME END, ', ') AS property_id_columns,
  LISTAGG(DISTINCT CASE WHEN is_date_year = 1 THEN COLUMN_NAME END, ', ') AS date_year_columns,
  LISTAGG(DISTINCT CASE WHEN is_feature = 1 THEN COLUMN_NAME END, ', ') AS feature_columns
FROM categorized_columns
GROUP BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
HAVING property_id_columns IS NOT NULL
  AND date_year_columns IS NOT NULL
  AND feature_columns IS NOT NULL
ORDER BY database_name, schema_name, TABLE_NAME;

-----

-- Check this table first!
SELECT
  PROPERTY_ID,
  PURCHASE_DATE,
  APPRAISAL_DATE,
  PRE_REHAB_BEDROOMS_COUNT,
  POST_REHAB_BEDROOMS_COUNT,
  PRE_REHAB_BATHROOMS_COUNT,
  POST_REHAB_BATHROOMS_COUNT
FROM ROC_ANALYTICS.ANALYTICS.ROC_LOANS_PROPERTIES
WHERE PRE_REHAB_BEDROOMS_COUNT IS NOT NULL
  AND POST_REHAB_BEDROOMS_COUNT IS NOT NULL
LIMIT 100;


------


-- Check if same properties have multiple listing dates
SELECT
  CC_PROPERTY_ID,
  COUNT(DISTINCT RECORD_DATE_TIME) AS num_records,
  MIN(RECORD_DATE_TIME) AS first_listing,
  MAX(RECORD_DATE_TIME) AS last_listing
FROM ROC_MLS_DATA.ATTOM.MLS
GROUP BY CC_PROPERTY_ID
HAVING num_records > 1
ORDER BY num_records DESC
LIMIT 100;

----------

SELECT
  PROPERTY_ID,
  PURCHASE_DATE,
  APPRAISAL_DATE,
  PRE_REHAB_BEDROOMS_COUNT,
  POST_REHAB_BEDROOMS_COUNT,
  PRE_REHAB_BATHROOMS_COUNT,
  POST_REHAB_BATHROOMS_COUNT
FROM ROC_ANALYTICS.ANALYTICS.ROC_LOANS_PROPERTIES
WHERE PRE_REHAB_BEDROOMS_COUNT IS NOT NULL
  AND POST_REHAB_BEDROOMS_COUNT IS NOT NULL
LIMIT 100;

------

-- How many renovated properties in NY and OH?
SELECT
  a.SITUSSTATE,
  COUNT(DISTINCT rlp.PROPERTY_ID) AS properties_with_renovations,
  SUM(CASE WHEN rlp.POST_REHAB_BEDROOMS_COUNT > rlp.PRE_REHAB_BEDROOMS_COUNT THEN 1 ELSE 0 END) AS bedroom_upgrades,
  SUM(CASE WHEN rlp.POST_REHAB_BATHROOMS_COUNT > rlp.PRE_REHAB_BATHROOMS_COUNT THEN 1 ELSE 0 END) AS bathroom_upgrades,
  MIN(rlp.PURCHASE_DATE) AS earliest_purchase,
  MAX(rlp.PURCHASE_DATE) AS latest_purchase

FROM ROC_ANALYTICS.ANALYTICS.ROC_LOANS_PROPERTIES rlp
LEFT JOIN ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a
  ON rlp.PROPERTY_ID = a.PROPERTYID
  AND a.MARKETYEAR = (
    SELECT MAX(MARKETYEAR)
    FROM ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a2
    WHERE a2.PROPERTYID = a.PROPERTYID
  )

WHERE
  rlp.PRE_REHAB_BEDROOMS_COUNT IS NOT NULL
  AND rlp.POST_REHAB_BEDROOMS_COUNT IS NOT NULL
  AND a.SITUSZIP5 IS NOT NULL
  AND (
      (UPPER(a.SITUSSTATE) IN ('NY', 'NEW YORK')
       AND a.SITUSZIP5 NOT LIKE '100%' AND a.SITUSZIP5 NOT LIKE '101%'
       AND a.SITUSZIP5 NOT LIKE '102%' AND a.SITUSZIP5 NOT LIKE '103%'
       AND a.SITUSZIP5 NOT LIKE '104%' AND a.SITUSZIP5 NOT LIKE '112%'
       AND a.SITUSZIP5 NOT LIKE '113%' AND a.SITUSZIP5 NOT LIKE '114%'
       AND a.SITUSZIP5 NOT LIKE '116%')
      OR UPPER(a.SITUSSTATE) IN ('OH', 'OHIO')
    )

GROUP BY a.SITUSSTATE
ORDER BY properties_with_renovations DESC;

----

-- Basic check: does this table have data?
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT PROPERTY_ID) AS unique_properties,
  COUNT(CASE WHEN PRE_REHAB_BEDROOMS_COUNT IS NOT NULL THEN 1 END) AS has_pre_bedrooms,
  COUNT(CASE WHEN POST_REHAB_BEDROOMS_COUNT IS NOT NULL THEN 1 END) AS has_post_bedrooms,
  MIN(PURCHASE_DATE) AS earliest_date,
  MAX(PURCHASE_DATE) AS latest_date
FROM ROC_ANALYTICS.ANALYTICS.ROC_LOANS_PROPERTIES;

-----

-- What states do we have in the joined data?
SELECT
  a.SITUSSTATE,
  COUNT(DISTINCT rlp.PROPERTY_ID) AS property_count
FROM ROC_ANALYTICS.ANALYTICS.ROC_LOANS_PROPERTIES rlp
LEFT JOIN ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a
  ON rlp.PROPERTY_ID = a.PROPERTYID
WHERE rlp.PRE_REHAB_BEDROOMS_COUNT IS NOT NULL
  AND rlp.POST_REHAB_BEDROOMS_COUNT IS NOT NULL
GROUP BY a.SITUSSTATE
ORDER BY property_count DESC;

-------

-- Try joining with LOAN_PROPERTY_ID instead
SELECT
  rlp.PROPERTY_ID AS ROC_PROPERTY_ID,
  rlp.LOAN_PROPERTY_ID,
  a.PROPERTYID AS ASSESSOR_PROPERTY_ID,
  a.SITUSSTATE,
  a.SITUSZIP5,
  rlp.PRE_REHAB_BEDROOMS_COUNT,
  rlp.POST_REHAB_BEDROOMS_COUNT
FROM ROC_ANALYTICS.ANALYTICS.ROC_LOANS_PROPERTIES rlp
LEFT JOIN ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a
  ON rlp.LOAN_PROPERTY_ID = a.PROPERTYID
WHERE rlp.PRE_REHAB_BEDROOMS_COUNT IS NOT NULL
  AND rlp.POST_REHAB_BEDROOMS_COUNT IS NOT NULL
LIMIT 20;

-----

-- Find properties in NY/OH that have changed features over time in MLS data
WITH mls_snapshots AS (
  SELECT
    CC_PROPERTY_ID,
    RECORD_DATE_TIME,
    YEAR_BUILT,
    BEDROOMS,
    FULL_BATHS,
    HALF_BATHS,
    GLA_SQFT,
    GARAGE_SPACES,
    ROOMS,
    ROW_NUMBER() OVER (PARTITION BY CC_PROPERTY_ID ORDER BY RECORD_DATE_TIME) AS snapshot_num
  FROM ROC_MLS_DATA.ATTOM.MLS
  WHERE CC_PROPERTY_ID IN (
    -- Get properties that have multiple snapshots
    SELECT CC_PROPERTY_ID
    FROM ROC_MLS_DATA.ATTOM.MLS
    GROUP BY CC_PROPERTY_ID
    HAVING COUNT(DISTINCT RECORD_DATE_TIME) >= 2
  )
),
first_snapshot AS (
  SELECT * FROM mls_snapshots WHERE snapshot_num = 1
),
last_snapshot AS (
  SELECT *
  FROM mls_snapshots ms
  WHERE snapshot_num = (
    SELECT MAX(snapshot_num)
    FROM mls_snapshots ms2
    WHERE ms2.CC_PROPERTY_ID = ms.CC_PROPERTY_ID
  )
)

SELECT
  f.CC_PROPERTY_ID,
  a.SITUSSTATE,
  a.SITUSCITY,
  a.SITUSZIP5,

  -- First snapshot
  f.RECORD_DATE_TIME AS FIRST_LISTING_DATE,
  f.BEDROOMS AS FIRST_BEDROOMS,
  f.FULL_BATHS AS FIRST_FULL_BATHS,
  f.HALF_BATHS AS FIRST_HALF_BATHS,
  f.GLA_SQFT AS FIRST_SQFT,

  -- Last snapshot
  l.RECORD_DATE_TIME AS LAST_LISTING_DATE,
  l.BEDROOMS AS LAST_BEDROOMS,
  l.FULL_BATHS AS LAST_FULL_BATHS,
  l.HALF_BATHS AS LAST_HALF_BATHS,
  l.GLA_SQFT AS LAST_SQFT,

  -- Changes
  (l.BEDROOMS - f.BEDROOMS) AS BEDROOM_CHANGE,
  (l.FULL_BATHS - f.FULL_BATHS) AS FULL_BATH_CHANGE,
  (l.HALF_BATHS - f.HALF_BATHS) AS HALF_BATH_CHANGE,
  (l.GLA_SQFT - f.GLA_SQFT) AS SQFT_CHANGE,

  -- Property details
  a.YEARBUILT,
  a.LOTSIZESQFT

FROM first_snapshot f
INNER JOIN last_snapshot l ON f.CC_PROPERTY_ID = l.CC_PROPERTY_ID
LEFT JOIN ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a
  ON f.CC_PROPERTY_ID = a.PROPERTYID
  AND a.MARKETYEAR = (
    SELECT MAX(MARKETYEAR)
    FROM ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a2
    WHERE a2.PROPERTYID = a.PROPERTYID
  )

WHERE
  -- Filter for NY and OH
  (
    (UPPER(a.SITUSSTATE) IN ('NY', 'NEW YORK')
     AND a.SITUSZIP5 NOT LIKE '100%' AND a.SITUSZIP5 NOT LIKE '101%'
     AND a.SITUSZIP5 NOT LIKE '102%' AND a.SITUSZIP5 NOT LIKE '103%'
     AND a.SITUSZIP5 NOT LIKE '104%' AND a.SITUSZIP5 NOT LIKE '112%'
     AND a.SITUSZIP5 NOT LIKE '113%' AND a.SITUSZIP5 NOT LIKE '114%'
     AND a.SITUSZIP5 NOT LIKE '116%')
    OR UPPER(a.SITUSSTATE) IN ('OH', 'OHIO')
  )
  -- Only keep properties where features actually changed
  AND (
    l.BEDROOMS != f.BEDROOMS
    OR l.FULL_BATHS != f.FULL_BATHS
    OR l.HALF_BATHS != f.HALF_BATHS
    OR ABS(l.GLA_SQFT - f.GLA_SQFT) > 100
  )

ORDER BY a.SITUSSTATE, a.SITUSZIP5;

--------

-- OPTIMIZED: Much faster version with limits and better structure
WITH property_counts AS (
  -- First, find properties with multiple snapshots (with limit for speed)
  SELECT CC_PROPERTY_ID, COUNT(DISTINCT RECORD_DATE_TIME) AS snapshot_count
  FROM ROC_MLS_DATA.ATTOM.MLS
  WHERE RECORD_DATE_TIME >= '2015-01-01'  -- Limit date range
    AND BEDROOMS IS NOT NULL
  GROUP BY CC_PROPERTY_ID
  HAVING COUNT(DISTINCT RECORD_DATE_TIME) >= 2
  LIMIT 10000  -- Start with 10k properties
),
snapshots_ranked AS (
  -- Get first and last snapshot in one pass
  SELECT
    mls.CC_PROPERTY_ID,
    mls.RECORD_DATE_TIME,
    mls.BEDROOMS,
    mls.FULL_BATHS,
    mls.HALF_BATHS,
    mls.GLA_SQFT,
    mls.YEAR_BUILT,
    ROW_NUMBER() OVER (PARTITION BY mls.CC_PROPERTY_ID ORDER BY mls.RECORD_DATE_TIME ASC) AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY mls.CC_PROPERTY_ID ORDER BY mls.RECORD_DATE_TIME DESC) AS rn_last
  FROM ROC_MLS_DATA.ATTOM.MLS mls
  INNER JOIN property_counts pc ON mls.CC_PROPERTY_ID = pc.CC_PROPERTY_ID
  WHERE mls.RECORD_DATE_TIME >= '2015-01-01'
),
first_last AS (
  SELECT
    CC_PROPERTY_ID,
    MAX(CASE WHEN rn_first = 1 THEN RECORD_DATE_TIME END) AS first_date,
    MAX(CASE WHEN rn_first = 1 THEN BEDROOMS END) AS first_bedrooms,
    MAX(CASE WHEN rn_first = 1 THEN FULL_BATHS END) AS first_full_baths,
    MAX(CASE WHEN rn_first = 1 THEN HALF_BATHS END) AS first_half_baths,
    MAX(CASE WHEN rn_first = 1 THEN GLA_SQFT END) AS first_sqft,
    MAX(CASE WHEN rn_last = 1 THEN RECORD_DATE_TIME END) AS last_date,
    MAX(CASE WHEN rn_last = 1 THEN BEDROOMS END) AS last_bedrooms,
    MAX(CASE WHEN rn_last = 1 THEN FULL_BATHS END) AS last_full_baths,
    MAX(CASE WHEN rn_last = 1 THEN HALF_BATHS END) AS last_half_baths,
    MAX(CASE WHEN rn_last = 1 THEN GLA_SQFT END) AS last_sqft,
    MAX(CASE WHEN rn_first = 1 THEN YEAR_BUILT END) AS year_built
  FROM snapshots_ranked
  WHERE rn_first = 1 OR rn_last = 1
  GROUP BY CC_PROPERTY_ID
)

SELECT
  fl.CC_PROPERTY_ID,
  a.SITUSSTATE,
  a.SITUSCITY,
  a.SITUSZIP5,

  -- First snapshot
  fl.first_date AS FIRST_LISTING_DATE,
  fl.first_bedrooms AS FIRST_BEDROOMS,
  fl.first_full_baths AS FIRST_FULL_BATHS,
  fl.first_half_baths AS FIRST_HALF_BATHS,
  fl.first_sqft AS FIRST_SQFT,

  -- Last snapshot
  fl.last_date AS LAST_LISTING_DATE,
  fl.last_bedrooms AS LAST_BEDROOMS,
  fl.last_full_baths AS LAST_FULL_BATHS,
  fl.last_half_baths AS LAST_HALF_BATHS,
  fl.last_sqft AS LAST_SQFT,

  -- Changes
  (fl.last_bedrooms - fl.first_bedrooms) AS BEDROOM_CHANGE,
  (fl.last_full_baths - fl.first_full_baths) AS FULL_BATH_CHANGE,
  (fl.last_half_baths - fl.first_half_baths) AS HALF_BATH_CHANGE,
  (fl.last_sqft - fl.first_sqft) AS SQFT_CHANGE,

  -- Time between snapshots
  DATEDIFF(day, fl.first_date, fl.last_date) AS days_between_snapshots,

  -- Property details
  fl.year_built,
  a.LOTSIZESQFT

FROM first_last fl
LEFT JOIN ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a
  ON fl.CC_PROPERTY_ID = a.PROPERTYID
  AND a.MARKETYEAR = 2024  -- Use specific year instead of subquery

WHERE
  -- Filter for NY and OH
  (
    (UPPER(a.SITUSSTATE) IN ('NY', 'NEW YORK')
     AND a.SITUSZIP5 NOT LIKE '100%' AND a.SITUSZIP5 NOT LIKE '101%'
     AND a.SITUSZIP5 NOT LIKE '102%' AND a.SITUSZIP5 NOT LIKE '103%'
     AND a.SITUSZIP5 NOT LIKE '104%' AND a.SITUSZIP5 NOT LIKE '112%'
     AND a.SITUSZIP5 NOT LIKE '113%' AND a.SITUSZIP5 NOT LIKE '114%'
     AND a.SITUSZIP5 NOT LIKE '116%')
    OR UPPER(a.SITUSSTATE) IN ('OH', 'OHIO')
  )
  -- Only keep properties where features actually changed
  AND (
    fl.last_bedrooms != fl.first_bedrooms
    OR fl.last_full_baths != fl.first_full_baths
    OR fl.last_half_baths != fl.first_half_baths
    OR ABS(fl.last_sqft - fl.first_sqft) > 100
  )

ORDER BY a.SITUSSTATE, a.SITUSZIP5
LIMIT 1000;

----

-- OPTIMIZED: Much faster version with limits and better structure
WITH property_counts AS (
  -- First, find properties with multiple snapshots (with limit for speed)
  SELECT CC_PROPERTY_ID, COUNT(DISTINCT RECORD_DATE_TIME) AS snapshot_count
  FROM ROC_MLS_DATA.ATTOM.MLS
  WHERE RECORD_DATE_TIME >= '2015-01-01'  -- Limit date range
    AND BEDROOMS IS NOT NULL
  GROUP BY CC_PROPERTY_ID
  HAVING COUNT(DISTINCT RECORD_DATE_TIME) >= 2
  LIMIT 10000  -- Start with 10k properties
),
snapshots_ranked AS (
  -- Get first and last snapshot in one pass
  SELECT
    mls.CC_PROPERTY_ID,
    mls.RECORD_DATE_TIME,
    mls.BEDROOMS,
    mls.FULL_BATHS,
    mls.HALF_BATHS,
    mls.GLA_SQFT,
    mls.YEAR_BUILT,
    ROW_NUMBER() OVER (PARTITION BY mls.CC_PROPERTY_ID ORDER BY mls.RECORD_DATE_TIME ASC) AS rn_first,
    ROW_NUMBER() OVER (PARTITION BY mls.CC_PROPERTY_ID ORDER BY mls.RECORD_DATE_TIME DESC) AS rn_last
  FROM ROC_MLS_DATA.ATTOM.MLS mls
  INNER JOIN property_counts pc ON mls.CC_PROPERTY_ID = pc.CC_PROPERTY_ID
  WHERE mls.RECORD_DATE_TIME >= '2015-01-01'
),
first_last AS (
  SELECT
    CC_PROPERTY_ID,
    MAX(CASE WHEN rn_first = 1 THEN RECORD_DATE_TIME END) AS first_date,
    MAX(CASE WHEN rn_first = 1 THEN BEDROOMS END) AS first_bedrooms,
    MAX(CASE WHEN rn_first = 1 THEN FULL_BATHS END) AS first_full_baths,
    MAX(CASE WHEN rn_first = 1 THEN HALF_BATHS END) AS first_half_baths,
    MAX(CASE WHEN rn_first = 1 THEN GLA_SQFT END) AS first_sqft,
    MAX(CASE WHEN rn_last = 1 THEN RECORD_DATE_TIME END) AS last_date,
    MAX(CASE WHEN rn_last = 1 THEN BEDROOMS END) AS last_bedrooms,
    MAX(CASE WHEN rn_last = 1 THEN FULL_BATHS END) AS last_full_baths,
    MAX(CASE WHEN rn_last = 1 THEN HALF_BATHS END) AS last_half_baths,
    MAX(CASE WHEN rn_last = 1 THEN GLA_SQFT END) AS last_sqft,
    MAX(CASE WHEN rn_first = 1 THEN YEAR_BUILT END) AS year_built
  FROM snapshots_ranked
  WHERE rn_first = 1 OR rn_last = 1
  GROUP BY CC_PROPERTY_ID
)

SELECT
  fl.CC_PROPERTY_ID,
  a.SITUSSTATE,
  a.SITUSCITY,
  a.SITUSZIP5,

  -- First snapshot
  fl.first_date AS FIRST_LISTING_DATE,
  fl.first_bedrooms AS FIRST_BEDROOMS,
  fl.first_full_baths AS FIRST_FULL_BATHS,
  fl.first_half_baths AS FIRST_HALF_BATHS,
  fl.first_sqft AS FIRST_SQFT,

  -- Last snapshot
  fl.last_date AS LAST_LISTING_DATE,
  fl.last_bedrooms AS LAST_BEDROOMS,
  fl.last_full_baths AS LAST_FULL_BATHS,
  fl.last_half_baths AS LAST_HALF_BATHS,
  fl.last_sqft AS LAST_SQFT,

  -- Changes
  (fl.last_bedrooms - fl.first_bedrooms) AS BEDROOM_CHANGE,
  (fl.last_full_baths - fl.first_full_baths) AS FULL_BATH_CHANGE,
  (fl.last_half_baths - fl.first_half_baths) AS HALF_BATH_CHANGE,
  (fl.last_sqft - fl.first_sqft) AS SQFT_CHANGE,

  -- Time between snapshots
  DATEDIFF(day, fl.first_date, fl.last_date) AS days_between_snapshots,

  -- Property details
  fl.year_built,
  a.LOTSIZESQFT

FROM first_last fl
LEFT JOIN ROC_PUBLIC_RECORD_DATA.DATATREE.ASSESSOR a
  ON fl.CC_PROPERTY_ID = a.PROPERTYID
  AND a.MARKETYEAR = 2024  -- Use specific year instead of subquery

WHERE
  -- Filter for NY and OH
  (
    (UPPER(a.SITUSSTATE) IN ('NY', 'NEW YORK')
     AND a.SITUSZIP5 NOT LIKE '100%' AND a.SITUSZIP5 NOT LIKE '101%'
     AND a.SITUSZIP5 NOT LIKE '102%' AND a.SITUSZIP5 NOT LIKE '103%'
     AND a.SITUSZIP5 NOT LIKE '104%' AND a.SITUSZIP5 NOT LIKE '112%'
     AND a.SITUSZIP5 NOT LIKE '113%' AND a.SITUSZIP5 NOT LIKE '114%'
     AND a.SITUSZIP5 NOT LIKE '116%')
    OR UPPER(a.SITUSSTATE) IN ('OH', 'OHIO')
  )
  -- Only keep properties where features actually changed
  AND (
    fl.last_bedrooms != fl.first_bedrooms
    OR fl.last_full_baths != fl.first_full_baths
    OR fl.last_half_baths != fl.first_half_baths
    OR ABS(fl.last_sqft - fl.first_sqft) > 100
  )

ORDER BY a.SITUSSTATE, a.SITUSZIP5
LIMIT 1000;