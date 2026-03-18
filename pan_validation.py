# =============================================================
# Project: PAN Number Validation (Data Cleaning & Validation)
# =============================================================

# -------------------------------------------------------------
# (1) Import Required Libraries
# -------------------------------------------------------------
import pandas as pd
import re

# -------------------------------------------------------------
# (2) Load Dataset
# -------------------------------------------------------------
df = pd.read_excel(r'pan_number_validation_dataset.xlsx')
total_records = len(df)
# print("Initial Total Records:", total_records)

# -------------------------------------------------------------
# (3) Data Cleaning
# -------------------------------------------------------------
# Count missing PANs (NaN after replacement)
nan_cnt = df['Pan_Numbers'].isna().sum()

# (a) Convert all values to string to avoid type errors
df['Pan_Numbers'] = df['Pan_Numbers'].astype(str)

# (b) Remove leading and trailing spaces
df['Pan_Numbers'] = df['Pan_Numbers'].str.strip()

# (c) Replace empty strings (like "") or space-only cells with proper NaN
df['Pan_Numbers'] = df['Pan_Numbers'].replace({'':pd.NA, 'nan': pd.NA})

# (d) Final missing count = original NaN + newly found empty/nan-string rows
missing_cnt = nan_cnt + (df['Pan_Numbers'].isna().sum() - nan_cnt)  # 965 + 2 = 967

# (e) Drop rows with missing PAN values
df = df.dropna(subset=['Pan_Numbers'])

# (f) Convert all PAN numbers to uppercase for uniform validation
df['Pan_Numbers'] = df['Pan_Numbers'].str.upper()

# (g) Remove duplicates (keep first occurrence)
df = df.drop_duplicates(subset=['Pan_Numbers'])

# -------------------------------------------------------------
# (4) PAN Format Validation
# -------------------------------------------------------------

def has_adjacent_repetition(s):
    """Check if any adjacent characters are the same."""
    return any(s[i] == s[i+1] for i in range(len(s)-1))

def is_sequential(s):
    """Check if all characters form a consecutive sequence (like: ABCDE, BCDEF)."""
    return all(ord(s[i+1]) - ord(s[i]) == 1 for i in range(len(s)-1))

def is_valid_pan(pan):
    """Validate PAN structure and pattern rules."""
    # (a) Basic length and regex
    if len(pan) != 10 or not re.match(r'^[A-Z]{5}[0-9]{4}[A-Z]$',pan):
        return False

    # Split into alphabetic & numeric parts
    alphabets = pan[:5]
    digits = pan[5:9]
    last_char = pan[9]

    # (b) Alphabet rules
    if has_adjacent_repetition(alphabets):  # no AA, BB etc.
        return False
    
    if is_sequential(alphabets):            # no ABCDE, BCDEF etc.
        return False
    
    # (C) Numeric rules
    if has_adjacent_repetition(digits):     # no 1123 etc.
        return False
    
    if is_sequential(digits):               # no 1234, 2345 etc.
        return False
    
    # (d) Last char already covered by regex (must be letter)
    return True

# -------------------------------------------------------------
# (4): Apply validation
# -------------------------------------------------------------
df['Status'] = df['Pan_Numbers'].apply(lambda x: 'Valid' if is_valid_pan(x) else 'Invalid')

# -------------------------------------------------------------
# (5): Create Summary DataFrame
# -------------------------------------------------------------
summary = {
    'Total records': total_records,
    'Total valid PANs': (df['Status'] == 'Valid').sum(),
    'Total invalid PANs': (df['Status'] == 'Invalid').sum(),
    'Total missing PANs': missing_cnt
}
df_summary = pd.DataFrame([summary])

# -------------------------------------------------------------
# (6): Export results
# -------------------------------------------------------------
with pd.ExcelWriter(r'pan_number_validation_result.xlsx') as writer:
    df.to_excel(writer, sheet_name = 'PAN Validations', index=False)
    df_summary.to_excel(writer, sheet_name='Summary', index=False)

