﻿SET SEARCH_PATH TO SH;

-- Task 1 --

WITH SDATA AS (
	SELECT
        C2.COUNTRY_REGION AS COUNTRY_REGION,
        T.CALENDAR_YEAR,
        CHAN.CHANNEL_DESC,
        SUM(S.AMOUNT_SOLD) AS AMOUNT_SOLD,
        TO_CHAR(
            ((SUM(S.AMOUNT_SOLD) / SUM(SUM(S.AMOUNT_SOLD)) OVER (PARTITION BY T.CALENDAR_YEAR, C2.COUNTRY_REGION)) * 100)::NUMERIC, '999.99' || '%'
        ) AS "% BY CHANNELS"    
    FROM
        SALES S
    INNER JOIN
        TIMES T ON S.TIME_ID = T.TIME_ID
    INNER JOIN
        PRODUCTS P ON S.PROD_ID = P.PROD_ID
    LEFT JOIN
        CUSTOMERS C ON S.CUST_ID = C.CUST_ID
    LEFT JOIN
        COUNTRIES C2 ON C.COUNTRY_ID = C2.COUNTRY_ID
    LEFT JOIN
        CHANNELS CHAN ON S.CHANNEL_ID = CHAN.CHANNEL_ID
    WHERE
        T.CALENDAR_YEAR BETWEEN 1999 AND 2001
        AND UPPER(C2.COUNTRY_REGION) IN ('EUROPE', 'AMERICAS', 'ASIA')
    GROUP BY
        C2.COUNTRY_REGION,
        T.CALENDAR_YEAR,
        CHAN.CHANNEL_DESC
)

SELECT
	COUNTRY_REGION,
	CALENDAR_YEAR,
	CHANNEL_DESC,
	AMOUNT_SOLD,
	"% BY CHANNELS",
--	CASE WHEN LAG("% BY CHANNELS") OVER (PARTITION BY COUNTRY_REGION, CHANNEL_DESC ORDER BY CALENDAR_YEAR) IS NULL THEN 'N/A' 
--		ELSE LAG("% BY CHANNELS") OVER (PARTITION BY COUNTRY_REGION, CHANNEL_DESC ORDER BY CALENDAR_YEAR)
--		END AS "% PREVIOUS PERIOD"
--	FIRST_VALUE ("% BY CHANNELS") OVER (ORDER BY CALENDAR_YEAR ROWS BETWEEN 1 PRECEDING AND CURRENT ROW ) AS "% PREVIOUS PERIOD",
	LAG("% BY CHANNELS") OVER (PARTITION BY COUNTRY_REGION, CHANNEL_DESC ORDER BY CALENDAR_YEAR) AS "% PREVIOUS PERIOD",
    COALESCE((CAST(REPLACE("% BY CHANNELS", '%', '') AS NUMERIC) - CAST(REPLACE(LAG("% BY CHANNELS") OVER (PARTITION BY COUNTRY_REGION, CHANNEL_DESC ORDER BY CALENDAR_YEAR), '%', '') AS NUMERIC)) || '%', 'N/A') AS "% DIFF"
FROM SDATA
GROUP BY
    COUNTRY_REGION,
    CALENDAR_YEAR,
    CHANNEL_DESC,
    AMOUNT_SOLD,
    "% BY CHANNELS"
ORDER BY
    COUNTRY_REGION,
    CALENDAR_YEAR,
    CHANNEL_DESC;


-- Task 2 --

WITH WEEKLYSALES AS (
    SELECT
        T.CALENDAR_WEEK_NUMBER,
        T.DAY_NUMBER_IN_MONTH,
        T.DAY_NAME,
        SUM(S.AMOUNT_SOLD) AS DAILY_SALES,
        T.TIME_ID
    FROM
        SALES S
    INNER JOIN
        TIMES T ON S.TIME_ID = T.TIME_ID
    WHERE
        T.CALENDAR_YEAR = 1999
        AND T.CALENDAR_WEEK_NUMBER BETWEEN 49 AND 51
    GROUP BY
        T.CALENDAR_WEEK_NUMBER,
        T.TIME_ID,
        T.DAY_NUMBER_IN_MONTH,
        T.DAY_NAME
)

SELECT
    WS.CALENDAR_WEEK_NUMBER,
    WS.TIME_ID,
    WS.DAY_NAME,
    SUM(WS.DAILY_SALES) AS DAILY_SALES,
    SUM(WS.DAILY_SALES) OVER (ORDER BY WS.CALENDAR_WEEK_NUMBER, WS.DAY_NUMBER_IN_MONTH) AS CUM_SUM,
    ROUND(AVG(WS.DAILY_SALES) OVER (
        PARTITION BY WS.CALENDAR_WEEK_NUMBER
        ORDER BY WS.DAY_NUMBER_IN_MONTH
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ), 2) AS CENTERED_3_DAY_AVG
FROM
    WEEKLYSALES WS
GROUP BY
    WS.CALENDAR_WEEK_NUMBER,
    WS.TIME_ID,
    WS.DAY_NUMBER_IN_MONTH,
    WS.DAY_NAME,
    WS.DAILY_SALES
ORDER BY
    WS.CALENDAR_WEEK_NUMBER,
    WS.TIME_ID;