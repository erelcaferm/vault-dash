"""Lists every piece of text the game shows, for translating.

Run from the project folder:  python3 tools/i18n_keys.py [--check]

Without --check it prints the keys. With --check it compares them against
translations/strings.csv and reports missing keys, missing translations and
translations whose placeholders (%d, %s, {name}) don't match the English.
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts"
CSV_PATH = ROOT / "translations" / "strings.csv"
LOCALES = ["es", "fr", "de", "tr", "ru", "zh_CN", "zh_TW"]

STRING = r'"((?:[^"\\]|\\.)*)"'
# Calls whose first argument is shown to the player as it is.
CALLS = [r"\btr", r"TranslationServer\.translate", r"_label", r"_menu_button", r"_toast",
         r"_celebrate", r"_die", r"_plain_label"]
# Data fields that are shown to the player.
FIELDS = ["name", "desc", "text", "one"]
SKIP = {"%s   %s", "? ? ?   ", "✓", "● %d  -%d%%", "", "%d%%", "II", "● %d/%d", "★ %d/%d", "✕", "-", "+", "%d/%d", "%d / %d", "● %d", "%s\\n%s", "%s\\n%s\\n%s", "+ ", "\\n",
        # Language names are always shown in their own language.
        "English", "Español", "Français", "Deutsch", "Türkçe", "Русский", "简体中文", "繁體中文"}
# Shown, but only reachable through an expression the patterns above miss.
EXTRA = ["Stats", "Hit by a moving block!", "Caught by a spike trap!", "Spike traps need open floor all round", "Moving blocks need room to move", '  by moving blocks', '  by spike traps', 'The Crypt', 'Ice Caves', 'Jungle Temple', 'Crystal Mine', 'Deep Sea', 'Lava Forge', 'Sky Ruins', "Fish", "Bone", "Pebble", "Seeds", "Jelly", "Bolt", "Pepper", "PETS", "VAULT", "Trophies", 'Runs played', 'Time climbing', 'Floors climbed', 'Best floor', 'Coins collected', 'Cracked walls broken', 'Trap floors passed', 'Power-ups grabbed', 'Chests opened', 'Legendaries found', 'Deaths', '  by lava', '  by spikes', '  by fake floors', 'Revives', 'Daily Climbs played', 'Daily gold medals', 'Levels cleared', 'Level stars', 'Missions finished', 'Cosmetics owned', "Bronze medal", "Silver medal", "Gold medal", "Off", "Spiked!", "The floor gave way!", "Place one start", "Place an exit", "Sure?"]


def unescape(s):
    return s.encode().decode("unicode_escape").encode("latin-1").decode("utf-8")


def keys():
    found = []
    for path in sorted(SCRIPTS.glob("*.gd")):
        text = path.read_text(encoding="utf-8")
        for call in CALLS:
            for m in re.finditer(call + r"\(\s*" + STRING, text):
                found.append(m.group(1))
        for field in FIELDS:
            for m in re.finditer(r'"' + field + r'":\s*' + STRING, text):
                found.append(m.group(1))
        # Button helpers that take the parent first, then the text.
        for m in re.finditer(r"\b(?:_bar_button|_button|_small)\(\s*[\w.]+,\s*" + STRING, text):
            found.append(m.group(1))
        for m in re.finditer(r'placeholder_text = ' + STRING, text):
            found.append(m.group(1))
        # The level editor's palette, as ["tile", "Name"] pairs.
        for m in re.finditer(r'\["[^"]", "([A-Z][^"]*)"\]', text):
            found.append(m.group(1))
        for m in re.finditer(r'\.text = ' + STRING, text):
            found.append(m.group(1))
        # Tab and language lists written as ["id", "Shown text"] pairs.
        for m in re.finditer(r'\[\s*"[a-z_]+",\s*"([A-Z][^"]*)"\s*\]', text):
            found.append(m.group(1))
        for m in re.finditer(r"const MONTHS := \[([^\]]*)\]", text):
            found += re.findall(STRING, m.group(1))
        for m in re.finditer(r"func kind_name[\s\S]*?\n\n", text):
            found += re.findall(r'return ' + STRING, m.group(0))
    out = []
    for raw in found + EXTRA:
        k = unescape(raw)
        if raw in SKIP or k in SKIP or k in out:
            continue
        out.append(k)
    return out


def placeholders(s):
    return sorted(re.findall(r"%[ds]|\{[a-z]+\}", s))


def check():
    want = keys()
    with CSV_PATH.open(encoding="utf-8", newline="") as f:
        rows = {r["keys"]: r for r in csv.DictReader(f)}
    problems = 0
    for k in want:
        if k not in rows:
            print("missing key:", repr(k))
            problems += 1
            continue
        for loc in LOCALES:
            t = rows[k].get(loc, "")
            if not t:
                print(f"missing {loc}:", repr(k))
                problems += 1
            elif placeholders(t) != placeholders(k):
                print(f"placeholders differ in {loc}:", repr(k), "->", repr(t))
                problems += 1
    for k in rows:
        if k not in want:
            print("unused key:", repr(k))
    print(f"{len(want)} keys, {problems} problems")
    return problems


if __name__ == "__main__":
    if "--check" in sys.argv:
        sys.exit(1 if check() else 0)
    for k in keys():
        print(repr(k))
