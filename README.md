#  PAN Number Validation Pipeline - Data Cleaning & Validation

A complete data cleaning and validation pipeline for Indian **Permanent Account Numbers (PAN)**, implemented in **both Python and SQL (PostgreSQL)**. The project processes a raw dataset of 10,000 PAN entries, applies multi-stage cleaning, validates each entry against official PAN format rules, and produces a categorised output.

---

##  Table of Contents

- [Project Overview](#project-overview)
- [PAN Format Rules](#pan-format-rules)
- [Final Results](#final-results)
- [Python Implementation](#python-implementation)
  - [Bugs Fixed](#bugs-fixed)
  - [How to Run](#how-to-run-python)
- [SQL Implementation (PostgreSQL)](#sql-implementation-postgresql)
  - [Bug Fixed](#bug-fixed-sql)
  - [How to Run](#how-to-run-sql)
- [Python vs SQL - Side by Side](#python-vs-sql--side-by-side)
- [Project Structure](#project-structure)
- [Technologies Used](#technologies-used)

---

##  Project Overview

**Goal:** Clean and validate a dataset of PAN numbers. Categorise each as **Valid** or **Invalid** and produce a summary report.

**Cleaning steps applied:**
| Step | Action |
|------|--------|
| Missing values | Identified and counted separately - not treated as Invalid |
| Duplicates | Removed (keep first occurrence) |
| Whitespace | Leading/trailing spaces stripped |
| Case | Normalised to uppercase before deduplication |

**Validation rules applied:**
| Rule | Description |
|------|-------------|
| Format | Must match `AAAAA9999A` exactly — 5 letters, 4 digits, 1 letter |
| Alpha adjacent | No two consecutive letters can be the same (e.g. `AABCD`  |
| Alpha sequence | First 5 letters cannot form a consecutive run (e.g. `ABCDE` ) |
| Digit adjacent | No two consecutive digits can be the same (e.g. `1123` ) |
| Digit sequence | Middle 4 digits cannot form a consecutive run (e.g. `1234` ) |

---

##  PAN Format Rules

A valid Indian PAN follows the format: **`AAAAA9999A`**

```
 A  A  A  A  A  9  9  9  9  A
[1][2][3][4][5][6][7][8][9][10]
 ←── 5 letters ──→←─ 4 digits ─→← 1 letter →
```

**Valid example:** `AHGVE1276F`

---

##  Final Results

| Metric | Value |
|--------|-------|
| Total records (raw) | 10,000 |
|  Valid PANs | **3,186** |
|  Invalid PANs | **5,839** |
|  Missing PANs | **967** |
| Records after cleaning | 9,025 |

---

##  Python Implementation

**File:** `pan_validation.py`  
**Output:** `pan_validation_result.xlsx` (2 sheets: `PAN Validations`, `Summary`)


### How to Run (Python)

pip install pandas openpyxl
python pan_validation.py

The script reads pan_number_validation_dataset.xlsx from the same directory
and writes pan_validation_result.xlsx to the same directory.

To save the output to a specific folder, update the path in the script:

output_path = r'C:\Your\Target\Folder\pan_validation_result.xlsx'

with pd.ExcelWriter(output_path) as writer:
    df.to_excel(writer, sheet_name='PAN Validations', index=False)
    df_summary.to_excel(writer, sheet_name='Summary', index=False)

---

##  SQL Implementation (PostgreSQL)

**File:** `pan_validation_postgresql.sql`  
**Tested on:** PostgreSQL via pgAdmin

The SQL script replicates the full Python pipeline using:
- A **staging table** for raw data
- Two **helper functions** for adjacent repetition and sequential checks
- A **view** for PAN classification
- A **summary CTE** for the final report

### Helper Functions

| Function | Purpose |
|----------|---------|
| `fn_check_adjacent_repetition(text)` | Returns `TRUE` if any two adjacent chars are identical |
| `fn_check_sequence(text)` | Returns `TRUE` if all chars form one consecutive ascending sequence |

> `fn_check_adjacent_repetition` is called on the full 10-char PAN. This is safe because letter/digit boundaries (positions 5→6 and 9→10) can never be equal, making it equivalent to checking alpha and digit parts separately.
>
> `fn_check_sequence` is called separately on `SUBSTRING(pan, 1, 5)` (alpha) and `SUBSTRING(pan, 6, 4)` (digits), matching Python exactly.


### How to Run (SQL)

1. Open **pgAdmin** and connect to your PostgreSQL server
2. Create the staging table and load data:
```sql
CREATE TABLE stg_pan_numbers_dataset (pan_number TEXT);

COPY stg_pan_numbers_dataset(pan_number)
FROM 'C:\path\to\pan_number_validation_dataset.csv'
DELIMITER ',' CSV HEADER;
```
3. Run `pan_validation_postgresql.sql` top to bottom
4. Query the results:
```sql
-- Full record-level results
SELECT * FROM vw_valid_invalid_pans;

-- Summary
-- (run the summary CTE block at the bottom of the SQL file)
```

---

##  Python vs SQL - Side by Side

| Step | Python | SQL |
|------|--------|-----|
| Load data | `pd.read_excel()` | `COPY` into staging table |
| Count missing | `isna().sum()` before `astype(str)` | `COUNT(*) WHERE IS NULL OR TRIM = ''` |
| Strip whitespace | `str.strip()` | `TRIM()` |
| Uppercase | `str.upper()` | `UPPER()` |
| Deduplicate | `drop_duplicates()` | `SELECT DISTINCT` |
| Format check | `re.match(r'^[A-Z]{5}[0-9]{4}[A-Z]$')` | `pan_number ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'` |
| Adjacent check | `has_adjacent_repetition()` on alpha + digit parts | `fn_check_adjacent_repetition()` on full PAN |
| Sequential check | `is_sequential()` on alpha + digit parts | `fn_check_sequence()` on `SUBSTRING` parts |
| Output | Excel file (2 sheets) | View + summary query |

### Results Comparison

| Metric | Python | SQL |
|--------|--------|-----|
| Total records | 10,000 | 10,000 |
| Valid PANs | **3,186** | **3,186**  |
| Invalid PANs | **5,839** | **5,839**  |
| Missing PANs | **967** | **967**  |

---

## Project Structure

```
pan-validation/
│
├── pan_number_validation_dataset.xlsx         # Raw input dataset (10,000 rows)
├── pan_number_validation- problem_statement   # Project problem statement and requirements
│
├── pan_validation.py                          # Python script (fixed)
├── pan_number_validation_result.xlsx          # Python output (PAN Validations + Summary)
│
├── pan_validation_postgresql.sql              # PostgreSQL script (fixed)
│
└── README.md                                  # This file
```

> Both implementations live in the **same repository** — they solve the same problem using the same rules, so keeping them together makes comparison and maintenance straightforward.

---

##  Technologies Used

| Tool       | Purpose                              |
|------------|--------------------------------------|
| Python 3.x | Core scripting                       |
| pandas     | Data loading, cleaning, manipulation |
| re (regex) | PAN format pattern matching          |
| PostgreSQL | SQL-based validation pipeline        |

---

