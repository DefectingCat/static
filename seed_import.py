#!/usr/bin/env python3
"""Import seed SQL files into PostgreSQL database."""

import os
import sys
import glob
import subprocess

def main():
    db_url = os.environ.get('DATABASE_URL')
    if not db_url:
        print("Error: DATABASE_URL environment variable not set")
        print("Usage: DATABASE_URL=postgres://user:pass@host:port/db python3 seed_import.py")
        sys.exit(1)

    seeds_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'seeds')
    files = sorted(glob.glob(os.path.join(seeds_dir, '*.sql')))

    if not files:
        print(f"No SQL files found in {seeds_dir}")
        sys.exit(1)

    print(f"Found {len(files)} seed files")
    print(f"Target: {db_url}")

    success = 0
    skipped = 0
    failed = 0

    for f in files:
        name = os.path.basename(f)
        result = subprocess.run(
            ['psql', db_url, '-f', f],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"  FAIL  {name}: {result.stderr.strip()}")
            failed += 1
        elif 'INSERT 0 0' in result.stdout:
            skipped += 1
        else:
            print(f"  OK    {name}")
            success += 1

    print(f"\nDone: {success} inserted, {skipped} skipped (duplicate), {failed} failed")

if __name__ == '__main__':
    main()
