"""
SignBridge Gesture Registration Utility
========================================
Registers or copies a recorded video file into the SignBridge ISL Dataset.
Usage:
    python register_gesture.py --type word --token ATTENTION --file /path/to/attention.mp4
    python register_gesture.py --type letter --token A --file /path/to/a.mp4
    python register_gesture.py --type number --token 1 --file /path/to/1.mp4
    python register_gesture.py --type announcement --token ann_karnataka_exp_arrival --file /path/to/ann.mp4
"""

import argparse
import json
import shutil
from pathlib import Path

DATASET_ROOT = Path(__file__).resolve().parent.parent.parent / "assets" / "isl_dataset"
REGISTRY_FILE = Path(__file__).resolve().parent / "user_isl_registry.json"

def register_file(item_type: str, token: str, file_path: str):
    token = token.strip().upper()
    src = Path(file_path).resolve()
    if not src.exists():
        print(f"Error: Source file '{src}' does not exist.")
        return

    subfolder = {
        "word": "words",
        "letter": "alphabet",
        "number": "numbers",
        "announcement": "announcements"
    }.get(item_type.lower())

    if not subfolder:
        print(f"Error: Invalid type '{item_type}'. Must be one of: word, letter, number, announcement.")
        return

    dest_dir = DATASET_ROOT / subfolder
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_file = dest_dir / f"{token}{src.suffix.lower()}"

    shutil.copy2(src, dest_file)
    print(f"Successfully copied: {src.name} -> {dest_file}")

    # Update user_isl_registry.json
    registry = {
        "alphabet": {},
        "numbers": {},
        "railway_words": {},
        "announcements": {}
    }
    if REGISTRY_FILE.exists():
        try:
            with open(REGISTRY_FILE, "r", encoding="utf-8") as f:
                registry.update(json.load(f))
        except Exception:
            pass

    key_map = {
        "words": "railway_words",
        "alphabet": "alphabet",
        "numbers": "numbers",
        "announcements": "announcements"
    }
    target_key = key_map[subfolder]
    registry.setdefault(target_key, {})[token] = {
        "primary_clip": f"/assets/isl_dataset/{subfolder}/{dest_file.name}",
        "filename": dest_file.name,
        "is_custom": True
    }

    with open(REGISTRY_FILE, "w", encoding="utf-8") as f:
        json.dump(registry, f, indent=2, ensure_ascii=False)

    print(f"Registered '{token}' in {REGISTRY_FILE.name} -> /assets/isl_dataset/{subfolder}/{dest_file.name}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Register ISL video clip")
    parser.add_argument("--type", choices=["word", "letter", "number", "announcement"], required=True, help="Category of the sign")
    parser.add_argument("--token", required=True, help="Word, letter, digit, or announcement ID")
    parser.add_argument("--file", required=True, help="Path to the video file (.mp4, .webm)")
    args = parser.parse_args()

    register_file(args.type, args.token, args.file)
