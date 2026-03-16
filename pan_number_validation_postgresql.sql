-- ==========================================================
-- PROJECT: PAN Number Validation (PostgreSQL)
-- ==========================================================

-- DROP VIEW IF EXISTS vw_valid_invalid_pans;
-- DROP TABLE IF EXISTS pan_numbers_dataset_cleaned;
-- DROP TABLE IF EXISTS stg_pan_numbers_dataset;

-- ==========================================================
-- (1) Create staging table for raw PAN data
-- ==========================================================
-- CREATE TABLE stg_pan_numbers_dataset (
--     pan_number TEXT
-- );

-- ==========================================================
-- (2) Data quality checks
-- ==========================================================
-- Missing PANs
SELECT * FROM stg_pan_numbers_dataset WHERE pan_number IS NULL;

-- Duplicates
SELECT pan_number, COUNT(*) 
FROM stg_pan_numbers_dataset 
WHERE pan_number IS NOT NULL
GROUP BY pan_number
HAVING COUNT(*) > 1;

-- Leading/trailing spaces
SELECT * 
FROM stg_pan_numbers_dataset
WHERE pan_number <> TRIM(pan_number);

-- Lowercase PANs
SELECT *
FROM stg_pan_numbers_dataset
WHERE pan_number <> UPPER(pan_number);

-- ==========================================================
-- (3) Create cleaned PAN table
-- ==========================================================
DROP TABLE IF EXISTS pan_numbers_dataset_cleaned; 
CREATE TABLE pan_numbers_dataset_cleaned AS
SELECT DISTINCT UPPER(TRIM(pan_number)) AS pan_number
FROM stg_pan_numbers_dataset 
WHERE pan_number IS NOT NULL
  AND TRIM(pan_number) <> '';

-- ==========================================================
-- (4) Create helper functions
-- ==========================================================

-- Function A: Check for adjacent repetition (e.g., AA, 11)
CREATE OR REPLACE FUNCTION fn_check_adjacent_repetition(p_str TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    FOR i IN 1 .. (LENGTH(p_str) - 1)
    LOOP
        IF SUBSTRING(p_str, i, 1) = SUBSTRING(p_str, i+1, 1) THEN
            RETURN TRUE;
        END IF;
    END LOOP;
    RETURN FALSE;
END;
$$;

-- Function B: Check for sequential pattern (e.g., ABCDE or 12345)
CREATE OR REPLACE FUNCTION fn_check_sequence(p_str TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    FOR i IN 1 .. (LENGTH(p_str) - 1)
    LOOP
        IF ASCII(SUBSTRING(p_str, i+1, 1)) - ASCII(SUBSTRING(p_str, i, 1)) <> 1 THEN
            RETURN FALSE;
        END IF;
    END LOOP;
    RETURN TRUE;
END;
$$;

-- ==========================================================
-- (5) Create view to classify valid vs invalid PANs
-- ==========================================================
CREATE OR REPLACE VIEW vw_valid_invalid_pans AS
WITH cte_cleaned_pan AS (
    SELECT DISTINCT UPPER(TRIM(pan_number)) AS pan_number
    FROM stg_pan_numbers_dataset 
    WHERE pan_number IS NOT NULL
      AND TRIM(pan_number) <> ''
),
cte_valid_pan AS (
    SELECT *
    FROM cte_cleaned_pan
    WHERE fn_check_adjacent_repetition(pan_number) = FALSE
      AND fn_check_sequence(SUBSTRING(pan_number,1,5)) = FALSE
      AND fn_check_sequence(SUBSTRING(pan_number,6,4)) = FALSE
      AND pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'
)
SELECT 
    cln.pan_number,
    CASE 
        WHEN vld.pan_number IS NULL THEN 'Invalid PAN'
        ELSE 'Valid PAN'
    END AS status
FROM cte_cleaned_pan cln
LEFT JOIN cte_valid_pan vld 
    ON vld.pan_number = cln.pan_number;

-- ==========================================================
-- (6) Summary Report
-- ==========================================================
WITH cte AS (
    SELECT 
        (SELECT COUNT(*) FROM stg_pan_numbers_dataset) AS total_processed_records,

        (SELECT COUNT(*)                               
         FROM stg_pan_numbers_dataset
         WHERE pan_number IS NULL
            OR TRIM(pan_number) = '') AS total_missing_pans,

        COUNT(*) FILTER (WHERE vw.status = 'Valid PAN')   AS total_valid_pans,
        COUNT(*) FILTER (WHERE vw.status = 'Invalid PAN') AS total_invalid_pans
    FROM vw_valid_invalid_pans vw
)
SELECT 
    total_processed_records, 
    total_valid_pans, 
    total_invalid_pans,
    total_missing_pans                                 
FROM cte;


