"""Builds translations/strings.csv from tools/translations_table.py.

Run from the project folder:  python3 tools/build_translations.py
Godot turns the CSV into .translation files when it imports the project.
"""
import csv
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from translations_table import T  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "translations" / "strings.csv"
LOCALES = ["es", "fr", "de", "tr", "ru", "zh_CN", "zh_TW"]

OUT.parent.mkdir(exist_ok=True)
with OUT.open("w", encoding="utf-8", newline="") as f:
    w = csv.writer(f)
    w.writerow(["keys", "en"] + LOCALES)
    for key, row in T.items():
        if len(row) != len(LOCALES):
            sys.exit("Wrong number of translations for %r" % key)
        w.writerow([key, key] + list(row))
print("Wrote %d keys to %s" % (len(T), OUT))
