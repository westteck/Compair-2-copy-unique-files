import os
import sys
import hashlib
import csv
from pathlib import Path

# Function to calculate file's MD5
def md5(file_path):
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

# Function to compare and optionally copy files
def compare_and_copy(src1, src2, dest, mode, duplicates_csv, copied_csv):
    src1_files = {p: md5(p) for p in Path(src1).rglob('*') if p.is_file()}
    src2_files = {p: md5(p) for p in Path(src2).rglob('*') if p.is_file()}
    
    with open(duplicates_csv, 'w', newline='') as dup_csv, open(copied_csv, 'w', newline='') as cop_csv:
        dup_writer = csv.writer(dup_csv)
        cop_writer = csv.writer(cop_csv)
        dup_writer.writerow(["File Path", "Source Directory"])
        cop_writer.writerow(["Original File Path", "Copied To"])
        
        for path, hash_value in src1_files.items():
            relative_path = path.relative_to(src1)
            other_path = src2 / relative_path
            
            if other_path.exists() and src2_files[other_path] == hash_value:
                dup_writer.writerow([str(path), str(src1)])
            else:
                if mode == "-run":
                    dest_path = dest / relative_path
                    dest_path.parent.mkdir(parents=True, exist_ok=True)
                    os.replace(path, dest_path)
                    print(f"Copied: {path} -> {dest_path}")
                else:
                    print(f"Would copy: {path} -> {dest / relative_path}")
                cop_writer.writerow([str(path), str(dest / relative_path)])

# Check command-line arguments
if len(sys.argv) != 2 or sys.argv[1] not in ("-test", "-run"):
    print("Usage: script.py [-test|-run]")
    sys.exit(1)

mode = sys.argv[1]

# Update these paths
SOURCE_DIR1 = Path("/path/to/source1")
SOURCE_DIR2 = Path("/path/to/source2")
DESTINATION_DIR = Path("/path/to/destination")
DUPLICATES_CSV = "/path/to/duplicates.csv"
COPIED_FILES_CSV = "/path/to/copied_files.csv"

if mode == "-run":
    DESTINATION_DIR.mkdir(parents=True, exist_ok=True)

compare_and_copy(SOURCE_DIR1, SOURCE_DIR2, DESTINATION_DIR, mode, DUPLICATES_CSV, COPIED_FILES_CSV)
