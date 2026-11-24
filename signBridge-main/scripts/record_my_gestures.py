"""
SignBridge - Rapid ISL Gesture Studio (OpenCV)
==============================================
Fast, responsive two-handed Indian Sign Language (ISL) video recorder with
live camera access, custom word editing, instant 2-second capture via 'Q' key,
and automatic progression to the next sign.

Key Shortcuts:
  [Q] or [Space] : Start 2-second gesture recording
  [M] or [E]     : Modify / rename current gesture word
  [A]            : Add a new custom word to the queue
  [N]            : Skip to next word
  [P]            : Return to previous word
  [R]            : Re-record current word
  [ESC]          : Save manifest & exit
"""

import os
import sys
import time
import json
import shutil
import argparse
import concurrent.futures
from pathlib import Path

# Ensure UTF-8 output on Windows
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

try:
    import cv2
    import numpy as np
except ImportError:
    print("Error: opencv-python and numpy are required. Install with: pip install opencv-python numpy")
    sys.exit(1)

BASE_DIR = Path(__file__).resolve().parent.parent
DATASET_ROOT = BASE_DIR / "datasets" / "user_custom_isl"
REGISTRY_FILE = BASE_DIR / "backend" / "app" / "services" / "user_isl_registry.json"

# Thread pool for non-blocking asynchronous video file writing & registry updates
save_executor = concurrent.futures.ThreadPoolExecutor(max_workers=2)

# ISL Instructions for Alphabet
ISL_ALPHABET_GUIDE = {
    'A': "Dominant index touches tip of non-dominant thumb.",
    'B': "Dominant index & thumb touch non-dominant index & thumb.",
    'C': "Dominant hand forms curved 'C' shape in front of chest.",
    'D': "Non-dominant index vertical; dominant index/thumb form 'C' touching it.",
    'E': "Dominant index touches tip of non-dominant index finger.",
    'F': "Dominant 2 fingers (index, middle) crossed over non-dominant 2 fingers.",
    'G': "Both hands in fists, dominant fist resting on top of non-dominant fist.",
    'H': "Non-dominant palm flat; dominant flat palm slides across it.",
    'I': "Dominant index touches tip of non-dominant middle finger.",
    'J': "Dominant index touches middle fingertip and traces 'J' downwards.",
    'K': "Non-dominant index vertical; dominant hooked index rests at joint.",
    'L': "Dominant index & thumb form an 'L' shape.",
    'M': "Dominant 3 fingers (index, middle, ring) rest on non-dominant palm.",
    'N': "Dominant 2 fingers (index, middle) rest on non-dominant palm.",
    'O': "Dominant index touches tip of non-dominant ring finger.",
    'P': "Non-dominant index vertical; dominant circle touches upper tip.",
    'Q': "Non-dominant index/thumb circle; dominant index hooks into base.",
    'R': "Dominant hooked index finger hooks over non-dominant flat palm.",
    'S': "BOTH PINKY FINGERS HOOK TOGETHER, palms facing each other.",
    'T': "Non-dominant index vertical; dominant index rests across top (forming 'T').",
    'U': "Dominant index touches tip of non-dominant little finger.",
    'V': "Dominant index & middle form 'V' resting on non-dominant palm.",
    'W': "Both hands open, fingers spread, forming 'W' peaks together.",
    'X': "Both index fingers crossed over each other like an 'X'.",
    'Y': "Dominant index rests in cleft between non-dominant thumb & index.",
    'Z': "Dominant index finger traces 'Z' in the air or on palm."
}

# ISL Instructions for Numbers
ISL_NUMBERS_GUIDE = {
    '0': "Fingers curled into 'O' shape, tips touching thumb.",
    '1': "Index finger extended straight up, palm facing outward.",
    '2': "Index and middle fingers extended in 'V' shape.",
    '3': "Index, middle, and ring fingers extended up.",
    '4': "Four fingers extended up, thumb folded across palm.",
    '5': "Open hand with all five fingers spread.",
    '6': "Non-dominant open 5 fingers; dominant index points to it.",
    '7': "Non-dominant 5 fingers; dominant 2 fingers.",
    '8': "Non-dominant 5 fingers; dominant 3 fingers.",
    '9': "Non-dominant 5 fingers; dominant 4 fingers."
}

# ISL Instructions for Core Railway Vocabulary
ISL_WORDS_GUIDE = {
    'ATTENTION': "Both open hands at ear level, moving forward and inward.",
    'TRAIN': "Both hands with index/middle extended, dominant gliding along tracks.",
    'PLATFORM': "Flat non-dominant palm down; dominant hand indicates level/number.",
    'CHILD': "Flat open hand facing down, bouncing gently at low child height.",
    'FOUND': "Open hand moving forward, fingers closing swiftly as if grasping.",
    'SAFE': "Both hands crossed in fists over chest, moving out to open palms.",
    'POLICE': "Index & thumb form 'C' shape near collar/shoulder badge.",
    'PARENTS': "Touch chin (Mother) then touch forehead (Father).",
    'OFFICE': "Hands form 'O' or 'B' shapes outlining room walls.",
    'ARRIVE': "Dominant hand moves into flat non-dominant palm.",
    'DEPART': "Dominant hand glides smoothly away from non-dominant palm.",
    'DELAY': "Index finger taps wrist watch, followed by pause gesture.",
    'TICKET': "Curved fingers stamp flat non-dominant palm like a ticket punch.",
    'HELP': "Closed dominant fist on open non-dominant palm, moving upwards."
}


def get_category_for_word(word: str):
    """Determines category folder and asset subfolder for a given sign word."""
    w = word.strip().upper()
    if len(w) == 1 and w.isalpha():
        return "alphabet", "alphabet"
    elif w.isdigit():
        return "numbers", "numbers"
    elif w.startswith("ANN_") or w.startswith("ANNOUNCEMENT"):
        return "announcements", "announcements"
    else:
        return "words", "railway_words"


def get_description_for_word(word: str) -> str:
    """Returns guide instructions for the sign."""
    w = word.strip().upper()
    if w in ISL_ALPHABET_GUIDE:
        return ISL_ALPHABET_GUIDE[w]
    if w in ISL_NUMBERS_GUIDE:
        return ISL_NUMBERS_GUIDE[w]
    if w in ISL_WORDS_GUIDE:
        return ISL_WORDS_GUIDE[w]
    return f"Two-handed ISL gesture for '{w}'. Form clear, distinct handshapes."


def save_clip_worker(word: str, frames: list, fps: float, size: tuple):
    """Background worker that writes the MP4 video and updates dataset & backend registries."""
    try:
        category_name, subfolder = get_category_for_word(word)
        dest_dir = DATASET_ROOT / subfolder / word
        dest_dir.mkdir(parents=True, exist_ok=True)

        existing = list(dest_dir.glob("*.mp4"))
        clip_number = len(existing) + 1
        output_filename = dest_dir / f"{word}_{clip_number:02d}.mp4"

        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(str(output_filename), fourcc, fps, size)
        for f in frames:
            out.write(f)
        out.release()

        # Copy to backend assets for instant playback in frontend & synthesis
        backend_assets = BASE_DIR / "backend" / "assets" / "isl_dataset" / category_name
        backend_assets.mkdir(parents=True, exist_ok=True)
        asset_file = backend_assets / f"{word}.mp4"
        shutil.copyfile(output_filename, asset_file)

        # Generate animated GIF for Flutter / Web UI live playback
        try:
            from PIL import Image
            gif_file = backend_assets / f"{word}.gif"
            pil_frames = [
                Image.fromarray(cv2.cvtColor(cv2.resize(f, (320, 240)), cv2.COLOR_BGR2RGB))
                for f in frames[::2]
            ]
            if pil_frames:
                pil_frames[0].save(str(gif_file), save_all=True, append_images=pil_frames[1:], duration=66, loop=0)
        except Exception:
            pass

        # Update user_isl_registry.json
        registry = {
            "alphabet": {},
            "numbers": {},
            "railway_words": {},
            "announcements": {},
            "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "total_signs": 0,
            "total_clips": 0
        }
        if REGISTRY_FILE.exists():
            try:
                with open(REGISTRY_FILE, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
                    if isinstance(loaded, dict):
                        registry.update(loaded)
            except Exception:
                pass

        key_map = {
            "words": "railway_words",
            "railway_words": "railway_words",
            "alphabet": "alphabet",
            "numbers": "numbers",
            "announcements": "announcements"
        }
        target_key = key_map.get(subfolder, key_map.get(category_name, "railway_words"))
        registry.setdefault(target_key, {})[word] = {
            "primary_clip": f"/assets/isl_dataset/{category_name}/{asset_file.name}",
            "filename": asset_file.name,
            "is_custom": True,
            "dataset_path": str(output_filename)
        }

        total = sum(len(registry.get(k, {})) for k in ["alphabet", "numbers", "railway_words", "announcements"])
        registry["total_signs"] = total
        registry["total_clips"] = total
        registry["generated_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ")

        with open(REGISTRY_FILE, "w", encoding="utf-8") as f:
            json.dump(registry, f, indent=2, ensure_ascii=False)

        print(f"\n[OK] Saved gesture clip: {output_filename.name} -> {asset_file}")
    except Exception as e:
        print(f"\n[Error saving video clip for {word}]: {e}")


def update_manifest():
    """Builds an index of all recorded clips in the dataset."""
    manifest = {
        "version": "2.0",
        "last_updated": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "counts": {"alphabet": 0, "numbers": 0, "railway_words": 0},
        "items": []
    }

    categories = [
        ("alphabet", DATASET_ROOT / "alphabet", ISL_ALPHABET_GUIDE),
        ("numbers", DATASET_ROOT / "numbers", ISL_NUMBERS_GUIDE),
        ("railway_words", DATASET_ROOT / "railway_words", ISL_WORDS_GUIDE)
    ]

    for cat_name, cat_dir, guide_dict in categories:
        if not cat_dir.exists():
            continue
        for sub_dir in sorted(cat_dir.iterdir()):
            if sub_dir.is_dir():
                label = sub_dir.name
                clips = [f.name for f in sub_dir.glob("*.mp4")]
                if clips:
                    manifest["counts"][cat_name] += len(clips)
                manifest["items"].append({
                    "category": cat_name,
                    "label": label,
                    "description": guide_dict.get(label, ""),
                    "clip_count": len(clips),
                    "clips": clips
                })

    DATASET_ROOT.mkdir(parents=True, exist_ok=True)
    manifest_path = DATASET_ROOT / "dataset_manifest.json"
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"\nManifest refreshed: {manifest_path}")


def draw_hud(display, word, category_name, description, idx, total, state,
             elapsed=0.0, duration=2.0, status_msg="", edit_buffer=""):
    """Draws a responsive, high-contrast HUD matching the SignBridge Ash Wine theme."""
    h, w = display.shape[:2]

    # 1. Top Header Banner (Ash Wine: BGR 47, 41, 50 -> #32292F)
    banner_height = 85
    cv2.rectangle(display, (0, 0), (w, banner_height), (47, 41, 50), -1)
    cv2.line(display, (0, banner_height), (w, banner_height), (100, 80, 110), 2)

    # Word Title & Category
    title_text = f"[{idx + 1}/{total}] SIGN: {word}"
    cv2.putText(display, title_text, (20, 36), cv2.FONT_HERSHEY_DUPLEX, 1.0, (255, 255, 255), 2)

    # Guidance / Hint
    guide_snippet = description[:75] + ("..." if len(description) > 75 else "")
    cv2.putText(display, guide_snippet, (20, 68), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (210, 190, 225), 1)

    # 2. Right-side Status Badge
    if state == "RECORDING":
        rem = max(0.0, duration - elapsed)
        # Pulsing Red badge
        cv2.rectangle(display, (w - 230, 12), (w - 15, 72), (20, 20, 190), -1)
        cv2.rectangle(display, (w - 230, 12), (w - 15, 72), (60, 60, 255), 2)
        cv2.circle(display, (w - 205, 42), 10, (0, 0, 255), -1)
        cv2.putText(display, "REC", (w - 185, 47), cv2.FONT_HERSHEY_DUPLEX, 0.75, (255, 255, 255), 2)
        cv2.putText(display, f"{rem:0.1f}s", (w - 110, 47), cv2.FONT_HERSHEY_DUPLEX, 0.85, (0, 255, 255), 2)

        # Bottom Recording Progress Bar (Bright Red filling horizontally)
        prog = min(1.0, elapsed / duration)
        bar_w = int(w * prog)
        cv2.rectangle(display, (0, h - 45), (w, h - 35), (30, 20, 25), -1)
        cv2.rectangle(display, (0, h - 45), (bar_w, h - 35), (0, 0, 240), -1)
    else:
        # Standby badge (Bright Cyan/Gold)
        cv2.rectangle(display, (w - 300, 14), (w - 15, 70), (35, 30, 38), -1)
        cv2.rectangle(display, (w - 300, 14), (w - 15, 70), (220, 180, 50), 2)
        cv2.putText(display, "READY TO RECORD", (w - 280, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (220, 180, 50), 2)
        cv2.putText(display, "Press 'Q' to Start", (w - 280, 62), cv2.FONT_HERSHEY_DUPLEX, 0.65, (0, 255, 200), 2)

    # 3. Bottom Guidance Strip
    bottom_height = 35
    cv2.rectangle(display, (0, h - bottom_height), (w, h), (26, 22, 28), -1)
    cv2.line(display, (0, h - bottom_height), (w, h - bottom_height), (70, 60, 75), 1)

    controls = "[Q] 2s Record  |  [R] Redo Take  |  [P] Prev  |  [N] Next  |  [M] Edit  |  [A] Add  |  [ESC] Exit"
    cv2.putText(display, controls, (18, h - 12), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (220, 220, 220), 1)

    # 4. Status Notification Message Overlay
    if status_msg and state != "RECORDING":
        msg_w = min(w - 60, len(status_msg) * 11 + 40)
        mx1 = (w - msg_w) // 2
        my1 = banner_height + 15
        cv2.rectangle(display, (mx1, my1), (mx1 + msg_w, my1 + 36), (20, 80, 30), -1)
        cv2.rectangle(display, (mx1, my1), (mx1 + msg_w, my1 + 36), (70, 220, 110), 2)
        cv2.putText(display, status_msg, (mx1 + 15, my1 + 24), cv2.FONT_HERSHEY_DUPLEX, 0.58, (255, 255, 255), 1)

    # 5. In-Window Word Edit / Add Modal
    if state in ("EDIT_WORD", "ADD_WORD"):
        # Translucent dark backdrop
        overlay = display.copy()
        cv2.rectangle(overlay, (0, 0), (w, h), (15, 12, 18), -1)
        cv2.addWeighted(overlay, 0.70, display, 0.30, 0, display)

        box_w, box_h = min(720, w - 40), 190
        bx1 = (w - box_w) // 2
        by1 = (h - box_h) // 2
        bx2 = bx1 + box_w
        by2 = by1 + box_h

        cv2.rectangle(display, (bx1, by1), (bx2, by2), (47, 41, 50), -1)
        cv2.rectangle(display, (bx1, by1), (bx2, by2), (230, 180, 60), 2)

        modal_title = "MODIFY GESTURE WORD" if state == "EDIT_WORD" else "ADD NEW WORD TO QUEUE"
        cv2.putText(display, modal_title, (bx1 + 25, by1 + 40), cv2.FONT_HERSHEY_DUPLEX, 0.85, (255, 255, 255), 2)

        # Input field box
        field_y1 = by1 + 65
        field_y2 = field_y1 + 50
        cv2.rectangle(display, (bx1 + 20, field_y1), (bx2 - 20, field_y2), (20, 16, 22), -1)
        cv2.rectangle(display, (bx1 + 20, field_y1), (bx2 - 20, field_y2), (180, 160, 200), 1)

        cursor = "|" if int(time.time() * 2) % 2 == 0 else ""
        disp_text = (edit_buffer + cursor) if edit_buffer else ("<Type word here>" + cursor)
        t_col = (255, 255, 255) if edit_buffer else (140, 140, 140)
        cv2.putText(display, disp_text, (bx1 + 35, field_y1 + 35), cv2.FONT_HERSHEY_DUPLEX, 0.95, t_col, 2)

        sub = "Type letters/numbers. Press ENTER to confirm, ESC to cancel."
        cv2.putText(display, sub, (bx1 + 25, by2 - 18), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (190, 190, 190), 1)

    # 6. Completion Modal
    elif state == "COMPLETED":
        overlay = display.copy()
        cv2.rectangle(overlay, (0, 0), (w, h), (15, 12, 18), -1)
        cv2.addWeighted(overlay, 0.65, display, 0.35, 0, display)

        box_w, box_h = min(720, w - 40), 200
        bx1 = (w - box_w) // 2
        by1 = (h - box_h) // 2
        bx2 = bx1 + box_w
        by2 = by1 + box_h

        cv2.rectangle(display, (bx1, by1), (bx2, by2), (47, 41, 50), -1)
        cv2.rectangle(display, (bx1, by1), (bx2, by2), (50, 200, 100), 2)

        cv2.putText(display, "ALL GESTURES RECORDED!", (bx1 + 30, by1 + 50), cv2.FONT_HERSHEY_DUPLEX, 1.0, (80, 255, 120), 2)
        cv2.putText(display, f"Successfully processed {total} sign(s).", (bx1 + 30, by1 + 95), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (240, 240, 240), 1)
        cv2.putText(display, "Press 'A' to add another word, 'R' to review, or 'ESC' to exit.", (bx1 + 30, by1 + 145), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (200, 200, 200), 1)


def run_recording_session(words_list: list, camera_index=0, duration=2.0):
    """
    Runs the continuous live OpenCV camera feed.
    Press 'Q' to record the current gesture for 2.0s, save it, and automatically advance to the next sign!
    """
    DATASET_ROOT.mkdir(parents=True, exist_ok=True)

    print(f"\n=======================================================")
    print(f"  Starting SignBridge Rapid ISL Gesture Recorder")
    print(f"  Target Words: {words_list}")
    print(f"  Record Duration: {duration}s per gesture")
    print(f"  Camera Index: {camera_index}")
    print(f"=======================================================")
    print("Controls:")
    print("  [Q] or [Space] : START 2-second recording")
    print("  [M] or [E]     : Edit/modify current word in OpenCV window")
    print("  [A]            : Add new word to queue")
    print("  [N]            : Skip to next word")
    print("  [P]            : Back to previous word")
    print("  [R]            : Re-record current word")
    print("  [ESC]          : Finish & Exit\n")

    # Open Camera with DirectShow on Windows, or default fallback
    cap = None
    if sys.platform == 'win32':
        cap = cv2.VideoCapture(camera_index, cv2.CAP_DSHOW)
        if not cap.isOpened():
            cap = cv2.VideoCapture(camera_index)
        if not cap.isOpened() and camera_index == 0:
            cap = cv2.VideoCapture(1, cv2.CAP_DSHOW)
    else:
        cap = cv2.VideoCapture(camera_index)
        if not cap.isOpened() and camera_index == 0:
            cap = cv2.VideoCapture(1)

    if not cap.isOpened():
        print(f"Error: Could not access camera (index {camera_index}). Please verify webcam connection.")
        return False

    # Configure optimal camera properties for low-latency preview
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) or 1280
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 720
    fps = 30.0

    window_name = "SignBridge - Rapid ISL Gesture Recorder"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, 1024, 600)
    try:
        cv2.setWindowProperty(window_name, cv2.WND_PROP_TOPMOST, 1)
    except Exception:
        pass

    words = list(words_list)
    current_index = 0
    state = "IDLE"  # IDLE, RECORDING, EDIT_WORD, ADD_WORD, COMPLETED
    record_start = 0.0
    recorded_frames = []
    edit_buffer = ""
    last_recorded_index = None
    status_msg = f"Ready! Position your hands, then press 'Q' to record."
    status_msg_time = time.time()

    while True:
        ret, frame = cap.read()
        if not ret:
            # Fallback frame if camera drops momentarily
            frame = np.zeros((height, width, 3), dtype=np.uint8)

        # Mirror horizontally for natural, mirror-like interaction
        frame = cv2.flip(frame, 1)
        display = frame.copy()
        current_time = time.time()

        # Clear expired status banner after 3 seconds
        if status_msg and (current_time - status_msg_time > 3.0):
            status_msg = ""

        # Check bounds
        if current_index >= len(words):
            if state != "ADD_WORD":
                state = "COMPLETED"
            current_word = words[-1] if words else "DONE"
        else:
            current_word = words[current_index]

        category_name, _ = get_category_for_word(current_word)
        description = get_description_for_word(current_word)

        # Manage recording state
        elapsed_record = 0.0
        if state == "RECORDING":
            elapsed_record = current_time - record_start
            recorded_frames.append(frame.copy())

            if elapsed_record >= duration:
                # 2.0s recording period finished!
                frames_to_save = list(recorded_frames)
                word_to_save = current_word
                save_executor.submit(save_clip_worker, word_to_save, frames_to_save, fps, (width, height))

                last_recorded_index = current_index

                # Automatically move to the next word
                current_index += 1
                if current_index >= len(words):
                    state = "COMPLETED"
                    status_msg = f"✓ Saved '{word_to_save}'! Press [R] to redo, or [ESC] to exit."
                else:
                    state = "IDLE"
                    next_word_name = words[current_index]
                    status_msg = f"✓ Saved '{word_to_save}'! Press [R] to Redo take | [Q] for next: '{next_word_name}'"
                status_msg_time = time.time()

        # Draw HUD overlays
        draw_hud(
            display,
            word=current_word,
            category_name=category_name,
            description=description,
            idx=min(current_index, len(words) - 1),
            total=len(words),
            state=state,
            elapsed=elapsed_record,
            duration=duration,
            status_msg=status_msg,
            edit_buffer=edit_buffer
        )

        cv2.imshow(window_name, display)
        key = cv2.waitKey(1) & 0xFF

        # ---------------- Keyboard Event Dispatcher ----------------
        if key == 255:
            continue  # No key pressed

        # Global Exit: ESC key (27)
        if key == 27:
            if state in ("EDIT_WORD", "ADD_WORD"):
                state = "IDLE"
            else:
                print("Exit requested by user.")
                break

        # State: EDIT_WORD or ADD_WORD text input
        if state in ("EDIT_WORD", "ADD_WORD"):
            if key in (13, 10):  # ENTER key
                clean_text = edit_buffer.strip().upper()
                if clean_text:
                    if state == "EDIT_WORD":
                        words[current_index] = clean_text
                        status_msg = f"Word updated to '{clean_text}'."
                    elif state == "ADD_WORD":
                        words.append(clean_text)
                        current_index = len(words) - 1
                        status_msg = f"Added '{clean_text}' to queue."
                    status_msg_time = time.time()
                state = "IDLE"
            elif key in (8, 127):  # BACKSPACE
                edit_buffer = edit_buffer[:-1]
            elif 32 <= key <= 126:  # Alphanumeric & symbols
                ch = chr(key).upper()
                if ch.isalnum() or ch in ("_", "-"):
                    edit_buffer += ch

        # State: COMPLETED
        elif state == "COMPLETED":
            if key in (ord('a'), ord('A')):
                state = "ADD_WORD"
                edit_buffer = ""
            elif key in (ord('r'), ord('R'), 8, 127):
                current_index = max(0, len(words) - 1)
                state = "IDLE"
                status_msg = f"↺ Ready to REDO '{words[current_index]}'. Press 'Q'."
                status_msg_time = time.time()
            elif key in (ord('z'), ord('Z')):
                current_index = 0
                state = "IDLE"
                status_msg = f"↺ Restarted queue from first word: '{words[0]}'. Press 'Q'."
                status_msg_time = time.time()

        # State: IDLE
        elif state == "IDLE":
            # [Q] or [Space]: START 2-second recording!
            if key in (ord('q'), ord('Q'), 32):
                state = "RECORDING"
                record_start = time.time()
                recorded_frames = [frame.copy()]
                print(f"\n--> Recording '{current_word}' for {duration} seconds...")

            # [R] or Backspace: REDO / Retake gesture!
            elif key in (ord('r'), ord('R'), 8, 127):
                if last_recorded_index is not None and current_index == last_recorded_index + 1:
                    current_index = last_recorded_index
                    status_msg = f"↺ Stepped back to REDO '{words[current_index]}'. Press 'Q' to re-record."
                else:
                    status_msg = f"↺ Ready to REDO '{words[current_index]}'. Press 'Q' to re-record."
                last_recorded_index = None
                status_msg_time = time.time()

            # [P]: Previous word (to redo any past sign)
            elif key in (ord('p'), ord('P')):
                if current_index > 0:
                    current_index -= 1
                    status_msg = f"Moved to previous: '{words[current_index]}'. Press 'Q' to re-record."
                    status_msg_time = time.time()

            # [Z]: Restart queue from first word
            elif key in (ord('z'), ord('Z')):
                current_index = 0
                status_msg = f"↺ Restarted queue from first sign: '{words[0]}'. Press 'Q'."
                status_msg_time = time.time()

            # [M] or [E]: Modify / Edit current word
            elif key in (ord('m'), ord('M'), ord('e'), ord('E')):
                state = "EDIT_WORD"
                edit_buffer = current_word

            # [A]: Add new word to queue
            elif key in (ord('a'), ord('A')):
                state = "ADD_WORD"
                edit_buffer = ""

            # [N]: Next word
            elif key in (ord('n'), ord('N')):
                if current_index < len(words) - 1:
                    current_index += 1
                    status_msg = f"Moved to '{words[current_index]}'."
                    status_msg_time = time.time()

    # Clean up OpenCV and camera resources
    cap.release()
    cv2.destroyAllWindows()

    print("\nFinalizing video dataset...")
    save_executor.shutdown(wait=True)
    update_manifest()

    # Automatically run dataset indexing & registry scan
    try:
        from train_user_dataset import scan_and_register
        scan_and_register()
    except Exception:
        try:
            from scripts.train_user_dataset import scan_and_register
            scan_and_register()
        except Exception:
            pass

    print("\nDone! All recorded gestures are indexed and ready for live playback & recognition.")
    return True


def record_clip(category_folder: Path, label: str, description: str, camera_index=0, record_seconds=2.0, copy_to_assets=True, category_name="words"):
    """Single-clip capture API method for backward compatibility."""
    return run_recording_session([label], camera_index=camera_index, duration=record_seconds)


def main():
    DATASET_ROOT.mkdir(parents=True, exist_ok=True)

    parser = argparse.ArgumentParser(description="SignBridge Rapid ISL Gesture Studio")
    parser.add_argument("--words", "-w", type=str, default="", help="Comma-separated words to record (e.g. 'TRAIN, PLATFORM, HELP')")
    parser.add_argument("--token", "-t", type=str, default="", help="Specific single token or word to record")
    parser.add_argument("--duration", type=float, default=2.0, help="Recording duration in seconds (default: 2.0s)")
    parser.add_argument("--camera-index", type=int, default=0, help="Camera device index")
    parser.add_argument("--json", action="store_true", help="Output JSON result to stdout")
    args = parser.parse_args()

    # 1. Direct CLI words provided
    if args.words.strip():
        word_list = [w.strip().upper() for w in args.words.split(",") if w.strip()]
        run_recording_session(word_list, camera_index=args.camera_index, duration=args.duration)
        return

    # 2. Single token provided
    if args.token.strip():
        token = args.token.strip().upper()
        run_recording_session([token], camera_index=args.camera_index, duration=args.duration)
        return

    # 3. Interactive prompt
    print("\n=======================================================")
    print("   SignBridge: Rapid ISL Gesture Studio (OpenCV)")
    print("   Anchor Color: Ash Wine (#32292F)")
    print("=======================================================")
    print("Enter custom words/signs to record (comma-separated, e.g. 'TRAIN, PLATFORM, TICKET')")
    user_words = input("Or press ENTER for preset menu: ").strip()

    if user_words:
        word_list = [w.strip().upper() for w in user_words.split(",") if w.strip()]
        run_recording_session(word_list, camera_index=args.camera_index, duration=args.duration)
        return

    # Preset selection
    print("\nPreset Options:")
    print(" 1. Railway Words (ATTENTION, TRAIN, PLATFORM, CHILD, FOUND, SAFE, POLICE, PARENTS, OFFICE, ARRIVE, DEPART, DELAY, TICKET, HELP)")
    print(" 2. Alphabet (A to Z) - 26 letters")
    print(" 3. Numbers (0 to 9) - 10 digits")
    print(" 4. Single Custom Word")
    print(" 0. Exit")

    choice = input("\nEnter choice [1-4, default=1]: ").strip()

    if choice == '2':
        words = sorted(list(ISL_ALPHABET_GUIDE.keys()))
    elif choice == '3':
        words = sorted(list(ISL_NUMBERS_GUIDE.keys()))
    elif choice == '4':
        single = input("Enter word or letter to record: ").strip().upper()
        words = [single] if single else ["TRAIN"]
    elif choice == '0':
        print("Exiting.")
        return
    else:
        words = list(ISL_WORDS_GUIDE.keys())

    run_recording_session(words, camera_index=args.camera_index, duration=args.duration)


if __name__ == "__main__":
    main()
