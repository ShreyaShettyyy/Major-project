"""
Indian Sign Language (ISL) Synthesis & Fingerspelling Engine
Handles conversion of parsed multilingual announcements into ISL gesture sequences,
including two-handed manual alphabet fingerspelling for proper nouns (e.g., person names like "Shreya"),
railway domain sign tokens, and custom user-recorded video dataset mappings.
"""

from typing import List, Dict, Any, Optional
import os
import json

# Two-handed Indian Sign Language (ISL) Alphabet Dataset
# Each letter has description of dominant/non-dominant hand roles and visual glyph
ISL_ALPHABET_DATA: Dict[str, Dict[str, Any]] = {
    "A": {
        "letter": "A",
        "name": "ISL Sign A",
        "hands": "Two-handed",
        "description": "Dominant index finger touches the tip of the non-dominant thumb.",
        "handshape": "Index to Thumb Tip",
        "svg_path": "M10 20 L25 5 L40 20 M15 15 L35 15",
        "duration_ms": 700
    },
    "B": {
        "letter": "B",
        "name": "ISL Sign B",
        "hands": "Two-handed",
        "description": "Both hands form open 'O' or curved loops touching at index and thumbs (forming letter B).",
        "handshape": "Double Loop Touch",
        "svg_path": "M12 5 L28 5 C34 5 34 14 28 14 C35 14 35 25 28 25 L12 25 Z",
        "duration_ms": 750
    },
    "C": {
        "letter": "C",
        "name": "ISL Sign C",
        "hands": "Single-handed",
        "description": "Curved open hand forming a clear 'C' arc facing forward.",
        "handshape": "Curved C-Arc",
        "svg_path": "M35 10 C20 10 15 16 15 25 C15 34 20 40 35 40",
        "duration_ms": 650
    },
    "D": {
        "letter": "D",
        "name": "ISL Sign D",
        "hands": "Two-handed",
        "description": "Non-dominant index points vertically; dominant hand curves to meet tip and base forming 'D'.",
        "handshape": "Stem & Arc Touch",
        "svg_path": "M15 5 L15 35 M15 5 C32 5 32 35 15 35",
        "duration_ms": 750
    },
    "E": {
        "letter": "E",
        "name": "ISL Sign E",
        "hands": "Two-handed",
        "description": "Dominant index finger touches the tip of the non-dominant index finger.",
        "handshape": "Index to Index Tip",
        "svg_path": "M12 5 L35 5 M12 20 L28 20 M12 35 L35 35 M12 5 L12 35",
        "duration_ms": 700
    },
    "F": {
        "letter": "F",
        "name": "ISL Sign F",
        "hands": "Two-handed",
        "description": "Dominant two fingers cross over non-dominant two fingers forming a cross hatch.",
        "handshape": "Two-Finger Cross",
        "svg_path": "M12 5 L35 5 M12 20 L28 20 M12 5 L12 35",
        "duration_ms": 750
    },
    "G": {
        "letter": "G",
        "name": "ISL Sign G",
        "hands": "Two-handed",
        "description": "Both fists held horizontally, dominant fist taps on top of non-dominant fist.",
        "handshape": "Fist on Fist",
        "svg_path": "M35 10 C20 10 15 16 15 25 C15 34 20 40 35 40 L35 25 L25 25",
        "duration_ms": 750
    },
    "H": {
        "letter": "H",
        "name": "ISL Sign H",
        "hands": "Two-handed",
        "description": "Non-dominant palm open flat; dominant hand slides flat palm across the non-dominant palm.",
        "handshape": "Palm Slide Across",
        "svg_path": "M15 5 L15 35 M35 5 L35 35 M15 20 L35 20",
        "duration_ms": 750
    },
    "I": {
        "letter": "I",
        "name": "ISL Sign I",
        "hands": "Two-handed",
        "description": "Dominant index finger touches the tip of non-dominant middle finger.",
        "handshape": "Index to Middle Tip",
        "svg_path": "M25 5 L25 35 M15 5 L35 5 M15 35 L35 35",
        "duration_ms": 700
    },
    "J": {
        "letter": "J",
        "name": "ISL Sign J",
        "hands": "Two-handed",
        "description": "Dominant index draws a 'J' curve on the open palm of non-dominant hand.",
        "handshape": "Palm J-Stroke",
        "svg_path": "M30 5 L30 25 C30 35 18 35 15 28",
        "duration_ms": 800
    },
    "K": {
        "letter": "K",
        "name": "ISL Sign K",
        "hands": "Two-handed",
        "description": "Non-dominant index points up; dominant hooked index touches side at joint forming 'K'.",
        "handshape": "Hooked Finger Contact",
        "svg_path": "M15 5 L15 35 M35 5 L15 20 L35 35",
        "duration_ms": 750
    },
    "L": {
        "letter": "L",
        "name": "ISL Sign L",
        "hands": "Two-handed",
        "description": "Dominant index finger places flat on non-dominant palm forming an 'L' right angle.",
        "handshape": "Right-Angle Palm Contact",
        "svg_path": "M15 5 L15 35 L35 35",
        "duration_ms": 700
    },
    "M": {
        "letter": "M",
        "name": "ISL Sign M",
        "hands": "Two-handed",
        "description": "Dominant three fingers (index, middle, ring) rest on non-dominant palm.",
        "handshape": "Three Fingers on Palm",
        "svg_path": "M10 35 L10 10 L25 25 L40 10 L40 35",
        "duration_ms": 750
    },
    "N": {
        "letter": "N",
        "name": "ISL Sign N",
        "hands": "Two-handed",
        "description": "Dominant two fingers (index, middle) rest flat on non-dominant palm.",
        "handshape": "Two Fingers on Palm",
        "svg_path": "M12 35 L12 10 L35 35 L35 10",
        "duration_ms": 750
    },
    "O": {
        "letter": "O",
        "name": "ISL Sign O",
        "hands": "Two-handed",
        "description": "Dominant index finger touches tip of non-dominant ring finger (vowel sequence).",
        "handshape": "Index to Ring Tip",
        "svg_path": "M25 5 C15 5 10 14 10 25 C10 36 15 45 25 45 C35 45 40 36 40 25 C40 14 35 5 25 5 Z",
        "duration_ms": 700
    },
    "P": {
        "letter": "P",
        "name": "ISL Sign P",
        "hands": "Two-handed",
        "description": "Non-dominant index points vertically; dominant index & thumb circle touch the upper stem.",
        "handshape": "Stem & Upper Loop",
        "svg_path": "M15 5 L15 35 M15 5 C30 5 30 20 15 20",
        "duration_ms": 750
    },
    "Q": {
        "letter": "Q",
        "name": "ISL Sign Q",
        "hands": "Two-handed",
        "description": "Dominant hand forms 'O' loop placed on non-dominant palm with index tail pointing down.",
        "handshape": "Loop with Tail",
        "svg_path": "M25 5 C15 5 10 14 10 23 C10 32 15 41 25 41 C35 41 40 32 40 23 C40 14 35 5 25 5 Z M28 28 L40 40",
        "duration_ms": 800
    },
    "R": {
        "letter": "R",
        "name": "ISL Sign R",
        "hands": "Two-handed",
        "description": "Dominant hooked index finger hooks over non-dominant flat open palm.",
        "handshape": "Hooked Finger over Palm",
        "svg_path": "M15 5 L15 35 M15 5 C30 5 30 18 15 18 M20 18 L35 35",
        "duration_ms": 750
    },
    "S": {
        "letter": "S",
        "name": "ISL Sign S",
        "hands": "Two-handed",
        "description": "Both pinky fingers hook together, palms facing each other (ISL sign for S).",
        "handshape": "Interlocking Little Fingers",
        "svg_path": "M32 10 C20 5 12 14 15 22 C18 30 35 25 35 33 C35 42 22 45 15 38",
        "duration_ms": 750
    },
    "T": {
        "letter": "T",
        "name": "ISL Sign T",
        "hands": "Two-handed",
        "description": "Dominant index touches base edge of non-dominant upright palm forming 'T'.",
        "handshape": "T-Cross Contact",
        "svg_path": "M10 5 L40 5 M25 5 L25 35",
        "duration_ms": 700
    },
    "U": {
        "letter": "U",
        "name": "ISL Sign U",
        "hands": "Two-handed",
        "description": "Dominant index finger touches tip of non-dominant little finger (completing AEIOU vowels).",
        "handshape": "Index to Little Finger Tip",
        "svg_path": "M15 5 L15 25 C15 35 35 35 35 25 L35 5",
        "duration_ms": 700
    },
    "V": {
        "letter": "V",
        "name": "ISL Sign V",
        "hands": "Two-handed",
        "description": "Dominant V-shape (index & middle spread) rests onto non-dominant palm.",
        "handshape": "V on Palm",
        "svg_path": "M15 5 L25 35 L35 5",
        "duration_ms": 700
    },
    "W": {
        "letter": "W",
        "name": "ISL Sign W",
        "hands": "Two-handed",
        "description": "Both hands spread with fingers interlaced forming a 3-peak 'W'.",
        "handshape": "Interlaced W Peaks",
        "svg_path": "M10 5 L18 35 L25 15 L32 35 L40 5",
        "duration_ms": 750
    },
    "X": {
        "letter": "X",
        "name": "ISL Sign X",
        "hands": "Two-handed",
        "description": "Both index fingers cross each other in the center forming an 'X'.",
        "handshape": "Crossing Index Fingers",
        "svg_path": "M12 5 L38 35 M38 5 L12 35",
        "duration_ms": 700
    },
    "Y": {
        "letter": "Y",
        "name": "ISL Sign Y",
        "hands": "Two-handed",
        "description": "Dominant thumb and index spread in 'V', positioned between thumb and index of non-dominant hand.",
        "handshape": "V between Thumb & Index",
        "svg_path": "M12 5 L25 20 L38 5 M25 20 L25 35",
        "duration_ms": 750
    },
    "Z": {
        "letter": "Z",
        "name": "ISL Sign Z",
        "hands": "Two-handed",
        "description": "Dominant bent hand rests with fingertips against non-dominant palm forming Z-profile.",
        "handshape": "Z Profile Stroke",
        "svg_path": "M12 5 L38 5 L12 35 L38 35",
        "duration_ms": 800
    }
}

# Digits in ISL
ISL_DIGITS_DATA: Dict[str, Dict[str, Any]] = {
    "0": {"symbol": "0", "name": "Zero", "description": "Closed circular 'O' with thumb and fingers.", "handshape": "Fist Loop"},
    "1": {"symbol": "1", "name": "One", "description": "Single dominant index finger pointing upward.", "handshape": "Upward Index"},
    "2": {"symbol": "2", "name": "Two", "description": "Index and middle fingers extended upward in V-shape.", "handshape": "Two Fingers Up"},
    "3": {"symbol": "3", "name": "Three", "description": "Thumb, index, and middle fingers extended.", "handshape": "Three Fingers"},
    "4": {"symbol": "4", "name": "Four", "description": "Four fingers extended upward, thumb folded.", "handshape": "Four Fingers"},
    "5": {"symbol": "5", "name": "Five", "description": "All five fingers open and extended wide.", "handshape": "Open Palm"},
    "6": {"symbol": "6", "name": "Six", "description": "Thumb contacts little finger, 3 middle fingers up.", "handshape": "Thumb-Pinky Touch"},
    "7": {"symbol": "7", "name": "Seven", "description": "Thumb contacts ring finger, others up.", "handshape": "Thumb-Ring Touch"},
    "8": {"symbol": "8", "name": "Eight", "description": "Thumb contacts middle finger, others up.", "handshape": "Thumb-Middle Touch"},
    "9": {"symbol": "9", "name": "Nine", "description": "Thumb contacts index finger, 3 outer fingers up.", "handshape": "Thumb-Index Touch"},
}

# Railway Domain ISL Gesture Dictionary
RAILWAY_ISL_DICTIONARY: Dict[str, Dict[str, Any]] = {
    "ATTENTION": {
        "code": "ATTENTION",
        "gloss": "ATTENTION",
        "label": "Attention / Listen",
        "kannada_label": "ಗಮನಿಸಿ",
        "hindi_label": "ध्यान दें",
        "description": "Both hands open near ears, wave gently forward to draw visual focus.",
        "icon": "notifications_active",
        "tags": ["announcement", "start"]
    },
    "TRAIN": {
        "code": "TRAIN",
        "gloss": "TRAIN",
        "label": "Train",
        "kannada_label": "ರೈಲು / ಗಾಡಿ",
        "hindi_label": "ट्रेन / रेलगाड़ी",
        "description": "Two fingers of dominant hand slide rhythmically over two fingers of non-dominant hand (rail tracks motion).",
        "icon": "train",
        "tags": ["transport", "vehicle"]
    },
    "PLATFORM": {
        "code": "PLATFORM",
        "gloss": "PLATFORM",
        "label": "Platform",
        "kannada_label": "ಪ್ಲಾಟ್‌ಫಾರ್ಮ್",
        "hindi_label": "प्लेटफार्म",
        "description": "Flat non-dominant palm held horizontally; dominant index traces the edge of the boarding platform.",
        "icon": "crop_portrait",
        "tags": ["station", "location"]
    },
    "ARRIVE": {
        "code": "ARRIVE",
        "gloss": "ARRIVE",
        "label": "Arriving / Coming",
        "kannada_label": "ಬರಲಿದೆ",
        "hindi_label": "आ रही है",
        "description": "Dominant hand moves smoothly from distance toward the body into resting palm.",
        "icon": "flight_land",
        "tags": ["action", "status"]
    },
    "DEPART": {
        "code": "DEPART",
        "gloss": "DEPART",
        "label": "Departing / Leaving",
        "kannada_label": "ಹೊರಡಲಿದೆ",
        "hindi_label": "रवाना होगी",
        "description": "Dominant hand sweeps forward away from the body indicating moving out.",
        "icon": "flight_takeoff",
        "tags": ["action", "status"]
    },
    "DELAY": {
        "code": "DELAY",
        "gloss": "DELAY",
        "label": "Delayed / Late",
        "kannada_label": "ವಿಳಂಬ",
        "hindi_label": "देरी",
        "description": "Dominant index finger taps wrist watch location twice, then pauses with palm lowered.",
        "icon": "schedule",
        "tags": ["status", "time"]
    },
    "CHILD": {
        "code": "CHILD",
        "gloss": "CHILD",
        "label": "Child / Kid",
        "kannada_label": "ಮಗು / ಬಾಲಕಿ",
        "hindi_label": "बच्चा / बच्ची",
        "description": "Hand held palm-down, patted at hip-height indicating small child stature.",
        "icon": "child_care",
        "tags": ["person", "emergency"]
    },
    "FOUND": {
        "code": "FOUND",
        "gloss": "FOUND",
        "label": "Found / With Us",
        "kannada_label": "ಕಂಡುಬಂದಿದೆ",
        "hindi_label": "मिली है",
        "description": "Hands open gather together gently towards chest expressing safekeeping.",
        "icon": "visibility",
        "tags": ["status", "emergency"]
    },
    "SAFE": {
        "code": "SAFE",
        "gloss": "SAFE",
        "label": "Safe / Protected",
        "kannada_label": "ಸುರಕ್ಷಿತ",
        "hindi_label": "सुरक्षित",
        "description": "Crossed wrists open outward confidently showing freedom from danger.",
        "icon": "verified_user",
        "tags": ["status", "security"]
    },
    "POLICE": {
        "code": "POLICE",
        "gloss": "POLICE",
        "label": "Railway Protection Force (RPF) / Police",
        "kannada_label": "ರೈಲ್ವೆ ಪೊಲೀಸ್",
        "hindi_label": "रेलवे पुलिस",
        "description": "Fingers salute lightly at forehead, indicating uniformed security personnel.",
        "icon": "local_police",
        "tags": ["authority", "security"]
    },
    "PARENTS": {
        "code": "PARENTS",
        "gloss": "PARENTS",
        "label": "Parents / Guardians",
        "kannada_label": "ಪೋಷಕರು",
        "hindi_label": "माता-पिता",
        "description": "Touch chin (mother sign) then forehead (father sign) combined smoothly.",
        "icon": "family_restroom",
        "tags": ["person", "family"]
    },
    "PLEASE": {
        "code": "PLEASE",
        "gloss": "PLEASE",
        "label": "Please",
        "kannada_label": "ದಯವಿಟ್ಟು",
        "hindi_label": "कृपया",
        "description": "Open flat dominant palm circles gently clockwise over the center of the chest.",
        "icon": "volunteer_activism",
        "tags": ["polite", "announcement"]
    },
    "MISSING": {
        "code": "MISSING",
        "gloss": "MISSING",
        "label": "Missing / Lost Person",
        "kannada_label": "ನಾಪತ್ತೆ / ಕಾಣೆಯಾದ",
        "hindi_label": "लापता / खोया हुआ",
        "description": "Both hands held open facing outward from chest, fingers curling inward while scanning sideways expressing absence.",
        "icon": "search_off",
        "tags": ["emergency", "lost_person"]
    },
    "HELP": {
        "code": "HELP",
        "gloss": "HELP",
        "label": "Help / Assistance",
        "kannada_label": "ಸಹಾಯ",
        "hindi_label": "सहायता / मदद",
        "description": "Closed dominant fist with thumb up rests upon flat open non-dominant palm, lifting upward together.",
        "icon": "help_outline",
        "tags": ["emergency", "service"]
    },
    "TRACK": {
        "code": "TRACK",
        "gloss": "TRACK",
        "label": "Railway Track / Line",
        "kannada_label": "ರೈಲು ಹಳಿ",
        "hindi_label": "रेलवे पटरी",
        "description": "Index and middle fingers of both hands extended parallel, moving forward in sync showing railway lines.",
        "icon": "timeline",
        "tags": ["infrastructure", "railway"]
    },
    "STATION": {
        "code": "STATION",
        "gloss": "STATION",
        "label": "Railway Station",
        "kannada_label": "ರೈಲ್ವೆ ನಿಲ್ದಾಣ",
        "hindi_label": "रेलवे स्टेशन",
        "description": "Train locomotive hand sign arriving into flat horizontal station platform hand.",
        "icon": "store",
        "tags": ["infrastructure", "station"]
    },
    "COACH": {
        "code": "COACH",
        "gloss": "COACH",
        "label": "Coach / Compartment / Bogie",
        "kannada_label": "ಬೋಗಿ",
        "hindi_label": "डिब्बा / कोच",
        "description": "Both open hands frame a rectangular compartment box, then fingers interlock indicating coupled coaches.",
        "icon": "view_carousel",
        "tags": ["train", "location"]
    },
    "CANCELLED": {
        "code": "CANCELLED",
        "gloss": "CANCELLED",
        "label": "Cancelled",
        "kannada_label": "ರದ್ದುಗೊಂಡಿದೆ",
        "hindi_label": "रद्द",
        "description": "Both index fingers form a sharp 'X' cross in front of chest indicating cancellation.",
        "icon": "cancel",
        "tags": ["status", "alert"]
    },
    "RESCHEDULED": {
        "code": "RESCHEDULED",
        "gloss": "RESCHEDULED",
        "label": "Rescheduled / Time Changed",
        "kannada_label": "ಮರುನಿಗದಿ",
        "hindi_label": "पुनर्निर्धारित",
        "description": "Index finger taps wrist watch, followed by circular hand gesture indicating new adjusted time.",
        "icon": "update",
        "tags": ["status", "time"]
    },
    "ANNOUNCEMENT": {
        "code": "ANNOUNCEMENT",
        "gloss": "ANNOUNCEMENT",
        "label": "Announcement / Notice",
        "kannada_label": "ಘೋಷಣೆ",
        "hindi_label": "घोषणा",
        "description": "Both open hands funnel out from the mouth expanding outward representing loudspeaker announcement.",
        "icon": "campaign",
        "tags": ["announcement", "start"]
    },
    "MYSURU": {
        "code": "MYSURU",
        "gloss": "MYSURU",
        "label": "Mysuru Junction",
        "kannada_label": "ಮೈಸೂರು ಜಂಕ್ಷನ್",
        "hindi_label": "मैसूरु जंक्शन",
        "description": "Two curved hands trace royal palace arch outline followed by fingerspelling M-Y-S.",
        "icon": "account_balance",
        "tags": ["station", "karnataka"]
    },
    "HUBBALLI": {
        "code": "HUBBALLI",
        "gloss": "HUBBALLI",
        "label": "SSS Hubballi Junction",
        "kannada_label": "ಎಸ್ಎಸ್ಎಸ್ ಹುಬ್ಬಳ್ಳಿ ಜಂಕ್ಷನ್",
        "hindi_label": "हुबली जंक्शन",
        "description": "Elongated continuous horizontal arm sweep marking the world's longest platform followed by U-B-L.",
        "icon": "train",
        "tags": ["station", "karnataka"]
    },
    "MANGALURU": {
        "code": "MANGALURU",
        "gloss": "MANGALURU",
        "label": "Mangaluru Central",
        "kannada_label": "ಮಂಗಳೂರು ಸೆಂಟ್ರಲ್",
        "hindi_label": "मंगलौर सेंट्रल",
        "description": "Both flat hands ripple outward denoting coastal waves followed by M-A-Q.",
        "icon": "waves",
        "tags": ["station", "dakshina_kannada"]
    },
    "MANGALURU_JUNCTION": {
        "code": "MANGALURU_JUNCTION",
        "gloss": "MANGALURU_JUNCTION",
        "label": "Mangaluru Junction (Kankanady)",
        "kannada_label": "ಮಂಗಳೂರು ಜಂಕ್ಷನ್ (ಕಂಕನಾಡಿ)",
        "hindi_label": "मंगलौर जंक्शन (कंकनाडी)",
        "description": "Rail intersection sign with crossed index fingers followed by coastal wave motion M-A-J-N.",
        "icon": "alt_route",
        "tags": ["station", "dakshina_kannada"]
    },
    "SURATHKAL": {
        "code": "SURATHKAL",
        "gloss": "SURATHKAL",
        "label": "Surathkal Station (NITK)",
        "kannada_label": "ಸುರತ್ಕಲ್",
        "hindi_label": "सुरथकल",
        "description": "Lighthouse beam hand rotation sign followed by fingerspelling S-L.",
        "icon": "wb_incandescent",
        "tags": ["station", "dakshina_kannada"]
    },
    "MULKI": {
        "code": "MULKI",
        "gloss": "MULKI",
        "label": "Mulki Station",
        "kannada_label": "ಮೂಲ್ಕಿ",
        "hindi_label": "मुल्की",
        "description": "River confluence gesture followed by M-U-L-K.",
        "icon": "water",
        "tags": ["station", "dakshina_kannada"]
    },
    "BANTWAL": {
        "code": "BANTWAL",
        "gloss": "BANTWAL",
        "label": "Bantwal / B.C. Road Station",
        "kannada_label": "ಬಂಟ್ವಾಳ / ಬಿ.ಸಿ. ರೋಡ್",
        "hindi_label": "बंटवाल / बी.सी. रोड",
        "description": "Netravati river bridge arch sign followed by B-N-T-L.",
        "icon": "arch",
        "tags": ["station", "dakshina_kannada"]
    },
    "PUTTUR": {
        "code": "PUTTUR",
        "gloss": "PUTTUR",
        "label": "Kabaka Puttur Station",
        "kannada_label": "ಕಬಕ ಪುತ್ತೂರು",
        "hindi_label": "कबाका पुत्तूर",
        "description": "Betel-nut palm tree upward climbing gesture followed by K-B-P-R.",
        "icon": "forest",
        "tags": ["station", "dakshina_kannada"]
    },
    "SUBRAHMANYA": {
        "code": "SUBRAHMANYA",
        "gloss": "SUBRAHMANYA",
        "label": "Subrahmanya Road (Kukke)",
        "kannada_label": "ಸುಬ್ರಹ್ಮಣ್ಯ ರೋಡ್ (ಕುಕ್ಕೆ)",
        "hindi_label": "सुब्रह्मण्य रोड (कुक्के)",
        "description": "Sacred serpent hood sign (Kukke Subrahmanya Kshetra) followed by S-B-H-R.",
        "icon": "temple_hindu",
        "tags": ["station", "dakshina_kannada"]
    },
    "ULLAL": {
        "code": "ULLAL",
        "gloss": "ULLAL",
        "label": "Ullal Station",
        "kannada_label": "ಉಳ್ಳಾಲ",
        "hindi_label": "उल्लाल",
        "description": "Queen Abbakka valiant shield sign at chest followed by coastal wave gesture U-L-L.",
        "icon": "shield",
        "tags": ["station", "dakshina_kannada"]
    },
    "PANAMBUR": {
        "code": "PANAMBUR",
        "gloss": "PANAMBUR",
        "label": "Panambur Port (NMPT)",
        "kannada_label": "ಪಣಂಬೂರು ಬಂದರು",
        "hindi_label": "पणम्बूर बंदरगाह",
        "description": "Large cargo ship steering motion followed by ocean waves sign.",
        "icon": "directions_boat",
        "tags": ["landmark", "dakshina_kannada"]
    },
    "DHARMASTHALA": {
        "code": "DHARMASTHALA",
        "gloss": "DHARMASTHALA",
        "label": "Dharmasthala Kshetra",
        "kannada_label": "ಧರ್ಮಸ್ಥಳ ಕ್ಷೇತ್ರ",
        "hindi_label": "धर्मस्थल क्षेत्र",
        "description": "Both palms folded in respectful Namaste at forehead level denoting Lord Manjunatha.",
        "icon": "temple_buddhist",
        "tags": ["pilgrimage", "dakshina_kannada"]
    },
    "MOODBIDRI": {
        "code": "MOODBIDRI",
        "gloss": "MOODBIDRI",
        "label": "Moodbidri (Jain Kashi)",
        "kannada_label": "ಮೂಡುಬಿದಿರೆ",
        "hindi_label": "मूडबिद्री",
        "description": "Thousand pillars temple gesture with both hands forming parallel columns.",
        "icon": "account_balance",
        "tags": ["landmark", "dakshina_kannada"]
    },
    "BELTHANGADY": {
        "code": "BELTHANGADY",
        "gloss": "BELTHANGADY",
        "label": "Belthangady",
        "kannada_label": "ಬೆಳ್ತಂಗಡಿ",
        "hindi_label": "बेल्तंगडी",
        "description": "Western Ghats green hill slopes gesture followed by B-T-H.",
        "icon": "terrain",
        "tags": ["town", "dakshina_kannada"]
    },
    "SULLIA": {
        "code": "SULLIA",
        "gloss": "SULLIA",
        "label": "Sullia Town",
        "kannada_label": "ಸುಳ್ಯ",
        "hindi_label": "सुल्या",
        "description": "Rubber plantation tapping motion followed by hill range sign.",
        "icon": "nature",
        "tags": ["town", "dakshina_kannada"]
    },
    "NETRAVATI": {
        "code": "NETRAVATI",
        "gloss": "NETRAVATI",
        "label": "Netravati River",
        "kannada_label": "ನೇತ್ರಾವತಿ ನದಿ",
        "hindi_label": "नेत्रावती नदी",
        "description": "Flowing river water undulating waves across chest.",
        "icon": "waves",
        "tags": ["river", "dakshina_kannada"]
    },
    "DAKSHINA_KANNADA": {
        "code": "DAKSHINA_KANNADA",
        "gloss": "DAKSHINA_KANNADA",
        "label": "Dakshina Kannada District",
        "kannada_label": "ದಕ್ಷಿಣ ಕನ್ನಡ ಜಿಲ್ಲೆ",
        "hindi_label": "दक्षिण कन्नड़ जिला",
        "description": "Two hands form coastline boundary arch extending from Netravati to Arabian Sea.",
        "icon": "map",
        "tags": ["district", "dakshina_kannada"]
    },
    "PANCHAGANGA_EXPRESS": {
        "code": "PANCHAGANGA_EXPRESS",
        "gloss": "PANCHAGANGA_EXPRESS",
        "label": "Panchaganga Express",
        "kannada_label": "ಪಂಚಗಂಗಾ ಎಕ್ಸ್‌ಪ್ರೆಸ್",
        "hindi_label": "पंचगंगा एक्सप्रेस",
        "description": "Five open fingers spread forward symbolizing five sacred rivers followed by locomotive express sign.",
        "icon": "directions_railway",
        "tags": ["train", "dakshina_kannada"]
    },
    "MATSYAGANDHA_EXPRESS": {
        "code": "MATSYAGANDHA_EXPRESS",
        "gloss": "MATSYAGANDHA_EXPRESS",
        "label": "Matsyagandha Express",
        "kannada_label": "ಮತ್ಸ್ಯಗಂಧ ಎಕ್ಸ್‌ಪ್ರೆಸ್",
        "hindi_label": "मत्स्यगंधा एक्सप्रेस",
        "description": "Fish swimming motion with hands together followed by Konkan coastal train sign.",
        "icon": "set_meal",
        "tags": ["train", "dakshina_kannada"]
    },
    "BELAGAVI": {
        "code": "BELAGAVI",
        "gloss": "BELAGAVI",
        "label": "Belagavi Station",
        "kannada_label": "ಬೆಳಗಾವಿ",
        "hindi_label": "बेलगाम",
        "description": "Historic fort rampart sign at shoulder height followed by B-G-M.",
        "icon": "fort",
        "tags": ["station", "karnataka"]
    },
    "KALABURAGI": {
        "code": "KALABURAGI",
        "gloss": "KALABURAGI",
        "label": "Kalaburagi Junction",
        "kannada_label": "ಕಲಬುರಗಿ ಜಂಕ್ಷನ್",
        "hindi_label": "कलबुर्गी जंक्शन",
        "description": "Circle fort sign denoting north Karnataka junction terminal K-L-B-G.",
        "icon": "domain",
        "tags": ["station", "karnataka"]
    },
    "BALLARI": {
        "code": "BALLARI",
        "gloss": "BALLARI",
        "label": "Ballari Junction",
        "kannada_label": "ಬಳ್ಳಾರಿ",
        "hindi_label": "बेल्लारी",
        "description": "Solid fist indicating granite rock fort followed by B-A-Y.",
        "icon": "landscape",
        "tags": ["station", "karnataka"]
    },
    "UDUPI": {
        "code": "UDUPI",
        "gloss": "UDUPI",
        "label": "Udupi Station",
        "kannada_label": "ಉಡುಪಿ",
        "hindi_label": "उडुपी",
        "description": "Temple chime bell sign followed by coastal rail gesture.",
        "icon": "temple_hindu",
        "tags": ["station", "karnataka"]
    },
    "HASSAN": {
        "code": "HASSAN",
        "gloss": "HASSAN",
        "label": "Hassan Junction",
        "kannada_label": "ಹಾಸನ",
        "hindi_label": "हासन",
        "description": "Hoysala temple stone carving hand gesture followed by H-A-S.",
        "icon": "handyman",
        "tags": ["station", "karnataka"]
    },
    "DAVANAGERE": {
        "code": "DAVANAGERE",
        "gloss": "DAVANAGERE",
        "label": "Davanagere Station",
        "kannada_label": "ದಾವಣಗೆರೆ",
        "hindi_label": "दावणगेरे",
        "description": "Textile weaving hand motion followed by D-V-G.",
        "icon": "texture",
        "tags": ["station", "karnataka"]
    },
    "SHIVAMOGGA": {
        "code": "SHIVAMOGGA",
        "gloss": "SHIVAMOGGA",
        "label": "Shivamogga Town",
        "kannada_label": "ಶಿವಮೊಗ್ಗ",
        "hindi_label": "शिवमोग्गा",
        "description": "Cascading waterfall motion (Jog Falls) followed by S-M-E-T.",
        "icon": "water_drop",
        "tags": ["station", "karnataka"]
    },
    "HYDERABAD": {
        "code": "HYDERABAD",
        "gloss": "HYDERABAD",
        "label": "Hyderabad / Secunderabad",
        "kannada_label": "ಹೈದರಾಬಾದ್",
        "hindi_label": "हैदराबाद",
        "description": "Four fingers pointed upright denoting Charminar monument followed by H-Y-B.",
        "icon": "account_balance",
        "tags": ["station", "destination"]
    },
    "GOA": {
        "code": "GOA",
        "gloss": "GOA",
        "label": "Goa (Madgaon Junction)",
        "kannada_label": "ಗೋವಾ (ಮಡಗಾಂವ್)",
        "hindi_label": "गोवा (मडगांव)",
        "description": "Gentle sea breeze wave hand gesture followed by M-A-O.",
        "icon": "beach_access",
        "tags": ["station", "destination"]
    },
    "KARNATAKA": {
        "code": "KARNATAKA",
        "gloss": "KARNATAKA",
        "label": "State of Karnataka",
        "kannada_label": "ಕರ್ನಾಟಕ",
        "hindi_label": "कर्नाटक",
        "description": "Two hands open in front, moving out and blooming representing the Land of Sandalwood & Kannada culture.",
        "icon": "flag",
        "tags": ["state", "region"]
    },
    "MAHARASHTRA": {
        "code": "MAHARASHTRA",
        "gloss": "MAHARASHTRA",
        "label": "State of Maharashtra",
        "kannada_label": "ಮಹಾರಾಷ್ಟ್ರ",
        "hindi_label": "महाराष्ट्र",
        "description": "Salute followed by proud chest tap representing the Maratha region.",
        "icon": "flag",
        "tags": ["state", "region"]
    },
    "TAMIL_NADU": {
        "code": "TAMIL_NADU",
        "gloss": "TAMIL_NADU",
        "label": "State of Tamil Nadu",
        "kannada_label": "ತಮಿಳುನಾಡು",
        "hindi_label": "तमिलनाडु",
        "description": "Temple gopuram steeple sign formed with both fingertips touching above head.",
        "icon": "temple_hindu",
        "tags": ["state", "region"]
    },
    "COME": {
        "code": "COME",
        "gloss": "COME",
        "label": "Please Come / Contact",
        "kannada_label": "ತಕ್ಷಣ ಬನ್ನಿ",
        "hindi_label": "तुरंत आएं",
        "description": "Both palms facing upward, curving inward twice beckoning attendance.",
        "icon": "login",
        "tags": ["action", "request"]
    },
    "OFFICE": {
        "code": "OFFICE",
        "gloss": "OFFICE",
        "label": "Station Master Office",
        "kannada_label": "ಸ್ಟೇಷನ್ ಮಾಸ್ಟರ್ ಕಚೇರಿ",
        "hindi_label": "स्टेशन मास्टर कार्यालय",
        "description": "Two flat hands outline rectangular building walls and door.",
        "icon": "business",
        "tags": ["location", "station"]
    },
    "CAUTION": {
        "code": "CAUTION",
        "gloss": "CAUTION",
        "label": "Caution / Danger",
        "kannada_label": "ಎಚ್ಚರಿಕೆ",
        "hindi_label": "सावधानी",
        "description": "Hands held open forward at chest, pulsing with alert warning motion.",
        "icon": "warning",
        "tags": ["security", "alert"]
    },
    "BAG": {
        "code": "BAG",
        "gloss": "BAG",
        "label": "Luggage / Unattended Bag",
        "kannada_label": "ಬ್ಯಾಗ್ / ಲಗೇಜ್",
        "hindi_label": "सामान / बैग",
        "description": "Mimed gripping of heavy suitcase handle with downward tension.",
        "icon": "luggage",
        "tags": ["security", "prohibition"]
    },
    "PASSENGERS": {
        "code": "PASSENGERS",
        "gloss": "PASSENGERS",
        "label": "Passengers / Public",
        "kannada_label": "ಪ್ರಯಾಣಿಕರು",
        "hindi_label": "यात्रीगण",
        "description": "Both open hands sweep gently horizontally across chest indicating assembled travelers.",
        "icon": "groups",
        "tags": ["audience", "railway"]
    },
    "NUMBER": {
        "code": "NUMBER",
        "gloss": "NUMBER",
        "label": "Train Number",
        "kannada_label": "ಸಂಖ್ಯೆ",
        "hindi_label": "नंबर / संख्या",
        "description": "Fingertips pinched together tapping rhythmically indicating train identifier code.",
        "icon": "tag",
        "tags": ["identifier", "railway"]
    },
    "KARNATAKA_EXPRESS": {
        "code": "KARNATAKA_EXPRESS",
        "gloss": "KARNATAKA_EXPRESS",
        "label": "Karnataka Express",
        "kannada_label": "ಕರ್ನಾಟಕ ಎಕ್ಸ್‌ಪ್ರೆಸ್",
        "hindi_label": "कर्नाटक एक्सप्रेस",
        "description": "ISL sign for State of Karnataka followed by high-speed double-handed forward express thrust.",
        "icon": "directions_railway",
        "tags": ["train", "express"]
    },
    "SWARNA_JAYANTI_EXPRESS": {
        "code": "SWARNA_JAYANTI_EXPRESS",
        "gloss": "SWARNA_JAYANTI_EXPRESS",
        "label": "Swarna Jayanti Express",
        "kannada_label": "ಸ್ವರ್ಣ ಜಯಂತಿ ಎಕ್ಸ್‌ಪ್ರೆಸ್",
        "hindi_label": "स्वर्ण जयंती एक्सप्रेस",
        "description": "Golden radiance flourish with fingers expanding into high-speed locomotive express sign.",
        "icon": "military_tech",
        "tags": ["train", "express"]
    },
    "CHENNAI_EXPRESS": {
        "code": "CHENNAI_EXPRESS",
        "gloss": "CHENNAI_EXPRESS",
        "label": "Chennai Express",
        "kannada_label": "ಚೆನ್ನೈ ಎಕ್ಸ್‌ಪ್ರೆಸ್",
        "hindi_label": "चेन्नई एक्सप्रेस",
        "description": "Curved C-hand shape leading into rhythmic express train locomotive motion.",
        "icon": "directions_railway",
        "tags": ["train", "express"]
    },
    "RANI_CHENNAMMA": {
        "code": "RANI_CHENNAMMA",
        "gloss": "RANI_CHENNAMMA",
        "label": "Rani Chennamma Express",
        "kannada_label": "ರಾಣಿ ಚೆನ್ನಮ್ಮ ಎಕ್ಸ್‌ಪ್ರೆಸ್",
        "hindi_label": "रानी चेन्नम्मा एक्सप्रेस",
        "description": "Crown emblem sign at forehead followed by forward moving train sign.",
        "icon": "directions_railway",
        "tags": ["train", "express"]
    },
    "VANDE_BHARAT": {
        "code": "VANDE_BHARAT",
        "gloss": "VANDE_BHARAT",
        "label": "Vande Bharat Express",
        "kannada_label": "ವಂದೇ ಭಾರತ್ ಎಕ್ಸ್‌ಪ್ರೆಸ್",
        "hindi_label": "वंदे भारत एक्सप्रेस",
        "description": "Aerodynamic pointed nose-cone handshape gliding rapidly forward.",
        "icon": "speed",
        "tags": ["train", "express"]
    },
    "KSR_BENGALURU": {
        "code": "KSR_BENGALURU",
        "gloss": "KSR_BENGALURU",
        "label": "KSR Bengaluru Station",
        "kannada_label": "ಕೆಎಸ್ಆರ್ ಬೆಂಗಳೂರು",
        "hindi_label": "केएसआर बेंगलुरु",
        "description": "Two-handed blossom sign (Garden City) followed by fingerspelled junction initials B-L-R.",
        "icon": "location_city",
        "tags": ["station", "origin"]
    },
    "NEW_DELHI": {
        "code": "NEW_DELHI",
        "gloss": "NEW_DELHI",
        "label": "New Delhi Station",
        "kannada_label": "ನವದೆಹಲಿ",
        "hindi_label": "नई दिल्ली",
        "description": "Dominant hand forms arch monument shape at chest level followed by D-L-I.",
        "icon": "location_city",
        "tags": ["station", "destination"]
    },
    "SOLAPUR": {
        "code": "SOLAPUR",
        "gloss": "SOLAPUR",
        "label": "Solapur Junction",
        "kannada_label": "ಸೋಲಾಪುರ",
        "hindi_label": "सोलापूर",
        "description": "Both flat hands circle outward at mid-height denoting central junction terminal S-U-R.",
        "icon": "place",
        "tags": ["station", "intermediate"]
    },
    "CHENNAI": {
        "code": "CHENNAI",
        "gloss": "CHENNAI",
        "label": "MGR Chennai Central",
        "kannada_label": "ಚೆನ್ನೈ ಸೆಂಟ್ರಲ್",
        "hindi_label": "चेन्नई सेंट्रल",
        "description": "Curved C-hand sweeping forward toward coastal railway terminus.",
        "icon": "place",
        "tags": ["station", "destination"]
    },
    "MUMBAI": {
        "code": "MUMBAI",
        "gloss": "MUMBAI",
        "label": "Mumbai CSMT",
        "kannada_label": "ಮುಂಬೈ ಸಿಎಸ್ಎಂಟಿ",
        "hindi_label": "मुंबई सीएसएमटी",
        "description": "Double gentle wave sign indicating coastal metropolis M-U-M.",
        "icon": "place",
        "tags": ["station", "origin"]
    },
    "FROM": {
        "code": "FROM",
        "gloss": "FROM",
        "label": "From (Origin)",
        "kannada_label": "ಇಂದ",
        "hindi_label": "से",
        "description": "Dominant index finger starts at point and pulls inward toward signer.",
        "icon": "arrow_forward",
        "tags": ["relation", "direction"]
    },
    "TO": {
        "code": "TO",
        "gloss": "TO",
        "label": "To (Destination)",
        "kannada_label": "ಗೆ",
        "hindi_label": "तक / को",
        "description": "Dominant index arches smoothly outward forward toward destination.",
        "icon": "arrow_forward",
        "tags": ["relation", "direction"]
    },
    "VIA": {
        "code": "VIA",
        "gloss": "VIA",
        "label": "Via / Through",
        "kannada_label": "ಮಾರ್ಗವಾಗಿ",
        "hindi_label": "होकर",
        "description": "Dominant hand weaves between non-dominant fingers indicating intermediate route stop.",
        "icon": "alt_route",
        "tags": ["relation", "route"]
    },
    "SHORTLY": {
        "code": "SHORTLY",
        "gloss": "SHORTLY",
        "label": "Shortly / In Few Minutes",
        "kannada_label": "ಕೆಲವೇ ಕ್ಷಣಗಳಲ್ಲಿ",
        "hindi_label": "कुछ ही समय में",
        "description": "Thumb and index finger held closely together pulsing forward indicating imminent arrival.",
        "icon": "timer",
        "tags": ["time", "status"]
    },
    "0": {"code": "0", "gloss": "0", "label": "Digit 0", "kannada_label": "0", "hindi_label": "0", "description": "Curved fingers touching thumb forming an 'O' ring shape.", "icon": "tag", "tags": ["digit"]},
    "1": {"code": "1", "gloss": "1", "label": "Digit 1", "kannada_label": "1", "hindi_label": "1", "description": "Dominant index finger extended upright.", "icon": "tag", "tags": ["digit"]},
    "2": {"code": "2", "gloss": "2", "label": "Digit 2", "kannada_label": "2", "hindi_label": "2", "description": "Dominant index and middle fingers extended in a V-shape.", "icon": "tag", "tags": ["digit"]},
    "3": {"code": "3", "gloss": "3", "label": "Digit 3", "kannada_label": "3", "hindi_label": "3", "description": "Thumb, index, and middle fingers extended.", "icon": "tag", "tags": ["digit"]},
    "4": {"code": "4", "gloss": "4", "label": "Digit 4", "kannada_label": "4", "hindi_label": "4", "description": "Four fingers extended upward with thumb folded across palm.", "icon": "tag", "tags": ["digit"]},
    "5": {"code": "5", "gloss": "5", "label": "Digit 5", "kannada_label": "5", "hindi_label": "5", "description": "Open hand with all five fingers spread wide.", "icon": "tag", "tags": ["digit"]},
    "6": {"code": "6", "gloss": "6", "label": "Digit 6", "kannada_label": "6", "hindi_label": "6", "description": "Non-dominant open palm (5) with dominant index finger (1) touching center palm.", "icon": "tag", "tags": ["digit"]},
    "7": {"code": "7", "gloss": "7", "label": "Digit 7", "kannada_label": "7", "hindi_label": "7", "description": "Non-dominant open palm (5) with dominant index & middle (2) touching palm.", "icon": "tag", "tags": ["digit"]},
    "8": {"code": "8", "gloss": "8", "label": "Digit 8", "kannada_label": "8", "hindi_label": "8", "description": "Non-dominant open palm (5) with dominant 3 fingers touching palm.", "icon": "tag", "tags": ["digit"]},
    "9": {"code": "9", "gloss": "9", "label": "Digit 9", "kannada_label": "9", "hindi_label": "9", "description": "Non-dominant open palm (5) with dominant 4 fingers touching palm.", "icon": "tag", "tags": ["digit"]},
    # General / Music / Song & Universal ISL Vocabulary
    "LOVE": {"code": "LOVE", "gloss": "LOVE", "label": "Love / Affection", "kannada_label": "ಪ್ರೀತಿ", "hindi_label": "प्यार / प्रेम", "description": "Both arms crossed firmly over the chest touching shoulders.", "icon": "favorite", "tags": ["emotion", "song"]},
    "YOU": {"code": "YOU", "gloss": "YOU", "label": "You", "kannada_label": "ನೀವು", "hindi_label": "आप / तुम", "description": "Dominant index finger points directly forward at the person.", "icon": "person", "tags": ["pronoun", "song"]},
    "ME": {"code": "ME", "gloss": "ME", "label": "Me / I", "kannada_label": "ನಾನು", "hindi_label": "मैं / मुझे", "description": "Dominant index finger points directly inward to the signer's chest.", "icon": "person_outline", "tags": ["pronoun", "song"]},
    "HEART": {"code": "HEART", "gloss": "HEART", "label": "Heart / Soul", "kannada_label": "ಹೃದಯ", "hindi_label": "दिल / हृदय", "description": "Both hands form a heart outline over the left chest pulsing gently.", "icon": "favorite_border", "tags": ["emotion", "song"]},
    "MUSIC": {"code": "MUSIC", "gloss": "MUSIC", "label": "Music / Melody", "kannada_label": "ಸಂಗೀತ", "hindi_label": "संगीत / धुन", "description": "Right hand waves rhythmically across left forearm like conducting melody.", "icon": "music_note", "tags": ["music", "song"]},
    "SONG": {"code": "SONG", "gloss": "SONG", "label": "Song / Lyrics", "kannada_label": "ಹಾಡು", "hindi_label": "गीत / गाना", "description": "Open hand gestures outward from the mouth in melodic undulating waves.", "icon": "mic", "tags": ["music", "song"]},
    "SING": {"code": "SING", "gloss": "SING", "label": "Singing", "kannada_label": "ಹಾಡುವುದು", "hindi_label": "गाना", "description": "Index and middle fingers sweep forward from mouth like musical notes.", "icon": "record_voice_over", "tags": ["music", "song"]},
    "DANCE": {"code": "DANCE", "gloss": "DANCE", "label": "Dance / Rhythm", "kannada_label": "ನೃತ್ಯ", "hindi_label": "नृत्य / नाचना", "description": "Dominant index and middle fingers dance rhythmically over open flat non-dominant palm.", "icon": "celebration", "tags": ["action", "song"]},
    "HAPPY": {"code": "HAPPY", "gloss": "HAPPY", "label": "Happy / Joy", "kannada_label": "ಸಂತೋಷ", "hindi_label": "खुश / प्रसन्न", "description": "Both open palms brush upward against chest twice with upbeat smiling expression.", "icon": "sentiment_very_satisfied", "tags": ["emotion", "song"]},
    "BEAUTIFUL": {"code": "BEAUTIFUL", "gloss": "BEAUTIFUL", "label": "Beautiful / Lovely", "kannada_label": "ಸುಂದರ", "hindi_label": "सुंदर", "description": "Open hand circles gracefully around face gathering fingertips smoothly at chin.", "icon": "auto_awesome", "tags": ["description", "song"]},
    "FRIEND": {"code": "FRIEND", "gloss": "FRIEND", "label": "Friend", "kannada_label": "ಸ್ನೇಹಿತ", "hindi_label": "दोस्त / मित्र", "description": "Both index fingers hook together once and then reverse interlocking.", "icon": "people", "tags": ["relationship", "song"]},
    "TIME": {"code": "TIME", "gloss": "TIME", "label": "Time / Moment", "kannada_label": "ಸಮಯ", "hindi_label": "समय / वक्त", "description": "Dominant index finger taps the wrist watch position on non-dominant arm.", "icon": "schedule", "tags": ["time", "song"]},
    "NIGHT": {"code": "NIGHT", "gloss": "NIGHT", "label": "Night", "kannada_label": "ರಾತ್ರಿ", "hindi_label": "रात", "description": "Dominant curved hand moves downward over horizontal non-dominant arm like sunset.", "icon": "bedtime", "tags": ["time", "song"]},
    "DAY": {"code": "DAY", "gloss": "DAY", "label": "Day / Daylight", "kannada_label": "ದಿನ", "hindi_label": "दिन", "description": "Dominant arm moves upward in an arc symbolizing the sun rising.", "icon": "wb_sunny", "tags": ["time", "song"]},
    "DREAM": {"code": "DREAM", "gloss": "DREAM", "label": "Dream", "kannada_label": "ಕನಸು", "hindi_label": "सपना / ख्वाब", "description": "Index finger touches forehead temple then ripples outward into floating curls.", "icon": "nights_stay", "tags": ["concept", "song"]},
    "EYES": {"code": "EYES", "gloss": "EYES", "label": "Eyes / Look", "kannada_label": "ಕಣ್ಣುಗಳು", "hindi_label": "आंखें / देखना", "description": "V-fingers point to the eyes and then sweep forward toward the view.", "icon": "visibility", "tags": ["body", "song"]},
    "TOGETHER": {"code": "TOGETHER", "gloss": "TOGETHER", "label": "Together / With You", "kannada_label": "ಜೊತೆಯಲ್ಲಿ", "hindi_label": "साथ में / एक साथ", "description": "Both hands form loose fists brought together in front of chest orbiting in unison.", "icon": "group_work", "tags": ["relationship", "song"]},
    "HELLO": {"code": "HELLO", "gloss": "HELLO", "label": "Hello / Welcome", "kannada_label": "ನಮಸ್ಕಾರ", "hindi_label": "नमस्ते", "description": "Open hand raises smoothly to forehead and waves outward warmly.", "icon": "waving_hand", "tags": ["greeting"]},
    "THANKYOU": {"code": "THANKYOU", "gloss": "THANKYOU", "label": "Thank You", "kannada_label": "ಧನ್ಯವಾದಗಳು", "hindi_label": "धन्यवाद / शुक्रिया", "description": "Flat fingertips touch chin and move outward toward the listener.", "icon": "volunteer_activism", "tags": ["greeting"]}
}

from pathlib import Path

# User custom mapped announcement videos storage in memory/json
CUSTOM_DATASET_STORE: Dict[str, Dict[str, Any]] = {}

def load_user_custom_registry() -> Dict[str, Any]:
    """
    Loads custom user ISL recordings from user_isl_registry.json AND automatically
    scans the backend/assets/isl_dataset folders (words, alphabet, numbers, announcements).
    Any .mp4/.webm video placed in these folders is automatically registered!
    """
    registry_file = Path(__file__).resolve().parent / "user_isl_registry.json"
    registry: Dict[str, Any] = {
        "alphabet": {},
        "numbers": {},
        "railway_words": {},
        "announcements": {}
    }
    
    if registry_file.exists():
        try:
            with open(registry_file, 'r', encoding='utf-8') as f:
                loaded = json.load(f)
                if isinstance(loaded, dict):
                    registry.update(loaded)
        except Exception:
            pass

    # Auto-scan backend/assets/isl_dataset
    dataset_dir = Path(__file__).resolve().parent.parent.parent / "assets" / "isl_dataset"
    if dataset_dir.exists():
        valid_exts = {".mp4", ".webm", ".mov", ".mkv"}
        
        # Scan words folder
        words_dir = dataset_dir / "words"
        if words_dir.exists():
            for f in words_dir.iterdir():
                if f.is_file() and f.suffix.lower() in valid_exts:
                    token = f.stem.upper()
                    clip_path = f"/assets/isl_dataset/words/{f.name}"
                    registry.setdefault("railway_words", {})[token] = {
                        "primary_clip": clip_path,
                        "file_path": str(f),
                        "filename": f.name
                    }
                    
        # Scan alphabet folder
        alpha_dir = dataset_dir / "alphabet"
        if alpha_dir.exists():
            for f in alpha_dir.iterdir():
                if f.is_file() and f.suffix.lower() in valid_exts:
                    letter = f.stem.upper()
                    clip_path = f"/assets/isl_dataset/alphabet/{f.name}"
                    registry.setdefault("alphabet", {})[letter] = {
                        "primary_clip": clip_path,
                        "file_path": str(f),
                        "filename": f.name
                    }

        # Scan numbers folder
        num_dir = dataset_dir / "numbers"
        if num_dir.exists():
            for f in num_dir.iterdir():
                if f.is_file() and f.suffix.lower() in valid_exts:
                    digit = f.stem.upper()
                    clip_path = f"/assets/isl_dataset/numbers/{f.name}"
                    registry.setdefault("numbers", {})[digit] = {
                        "primary_clip": clip_path,
                        "file_path": str(f),
                        "filename": f.name
                    }

        # Scan announcements folder
        ann_dir = dataset_dir / "announcements"
        if ann_dir.exists():
            for f in ann_dir.iterdir():
                if f.is_file() and f.suffix.lower() in valid_exts:
                    ann_id = f.stem
                    clip_path = f"/assets/isl_dataset/announcements/{f.name}"
                    registry.setdefault("announcements", {})[ann_id] = {
                        "primary_clip": clip_path,
                        "file_path": str(f),
                        "filename": f.name
                    }
                    CUSTOM_DATASET_STORE[ann_id] = {
                        "announcement_id": ann_id,
                        "video_url": clip_path,
                        "title": f"Custom Recording for {ann_id}",
                        "author": "User",
                        "has_custom_video": True
                    }

    return registry


# Comprehensive Semantic & Synonym Lexicon for User ISL Gestures
# Maps concepts, inflections, synonyms, and multilingual translations (English, Hindi, Kannada)
USER_GESTURE_SYNONYMS: Dict[str, List[str]] = {
    # 1. Trains & Locomotive Types
    "TRAIN": ["train", "trains", "railway", "rail", "railways", "express", "locomotive", "railcar", "गाड़ी", "ट्रेन", "रेल", "रेलगाड़ी", "ರೈಲು", "ರೈಲುಗಳು"],
    "VANDEBHARAT": ["vande bharat", "vandebharat", "vande bharat express", "vande-bharat", "20607", "20608", "20631", "20632", "वंदे भारत", "वंदे भारत एक्सप्रेस", "ವಂದೇ ಭಾರತ್", "ವಂದೇ ಭಾರತ್ ಎಕ್ಸ್‌ಪ್ರೆಸ್"],
    "RAJDHANI": ["rajdhani", "rajdhani express", "राजधानी", "राजधानी एक्सप्रेस", "ರಾಜಧಾನಿ"],

    # 2. Station, Tracks & Infrastructure
    "RAILWAY STATION": ["railway station", "station", "railway stn", "stn", "junction", "jn", "terminal", "railway stop", "railway terminal", "स्टेशन", "रेलवे स्टेशन", "ನಿಲ್ದಾಣ", "ರೈಲ್ವೆ ನಿಲ್ದಾಣ", "ಜಂಕ್ಷನ್"],
    "PLATFORM": ["platform", "platforms", "pf", "plat", "platform no", "platform number", "प्लेटफार्म", "ಪ್ಲಾಟ್‌ಫಾರ್ಮ್"],
    "TRACK": ["track", "tracks", "rail track", "rail line", "line", "rails", "पटरी", "हळी", "ಹಳಿ", "ಹಳಿಗಳು"],

    # 3. Carriage, Seats & Tickets
    "COACH": ["coach", "coaches", "bogie", "bogey", "bogies", "compartment", "compartments", "carriage", "rail car", "डिब्बा", "डब्बा", "ಕೋಚ್", "ಬೋಗಿ"],
    "BOGIE": ["bogie", "bogey", "bogies", "bogeys", "coach", "compartment", "carriage", "बोगी"],
    "COMPARTMENT": ["compartment", "compartments", "cabin", "coach", "bogie"],
    "SEAT": ["seat", "seats", "berth", "berths", "chair", "sitting", "sheet", "सीट", "बर्थ", "ಆಸನ", "ಬರ್ತ್"],
    "TICKET": ["ticket", "tickets", "pass", "passes", "fare", "boarding pass", "tte", "टिकट", "ಟಿಕೆಟ್"],
    "BOOKING": ["booking", "booked", "reservation", "reserve", "book", "ಬುಕಿಂಗ್", "आरक्षण", "बुकिंग"],
    "PASSENGER": ["passenger", "passengers", "commuter", "commuters", "traveler", "travelers", "people", "public", "yatri", "यात्री", "यात्रीगण", "ಪ್ರಯಾಣಿಕರು", "ಪ್ರಯಾಣಿಕರ"],
    "TRAVEL": ["travel", "traveling", "travels", "journey", "journeying", "trip", "trips", "tour", "yatra", "यात्रा", "ಪ್ರಯಾಣ"],

    # 4. Movement, Arrival & Departure
    "ARRIVE": ["arrive", "arrives", "arriving", "arrival", "incoming", "reached", "reaches", "reaching", "approach", "approaches", "shortly", "आ रही", "पहुंच रही", "आगमन", "ಆಗಮನ", "ಬರಲಿದೆ", "ತಲುಪಲಿದೆ"],
    "ARRIVAL": ["arrival", "arriving", "arrive", "reach", "incoming", "आगमन"],
    "ARRIVING": ["arriving", "arrive", "coming", "approaching"],
    "APPROACHING": ["approaching", "approach", "nears", "nearing", "coming in", "drawing near", "आ रही"],
    "COMING": ["coming", "comes", "incoming", "arriving"],
    "DEPART": ["depart", "departs", "departing", "departure", "leave", "leaves", "leaving", "left", "start", "starts", "starting", "moving out", "exits", "रवाना", "छूट रही", "ಹೊರಡಲಿದೆ", "ನಿರ್ಗಮನ"],
    "DEPARTURE": ["departure", "depart", "leaving", "ನಿರ್ಗಮನ"],
    "LEAVING": ["leaving", "leave", "depart", "departing"],
    "GOING": ["going", "goes", "heading", "departing", "bound for"],
    "STARTING": ["starting", "start", "starts", "started", "commence", "commencing", "originating", "ಪ್ರಾರಂಭ", "ಆರಂಭ"],

    # 5. Speed, Halting & Delays
    "HALTING": ["halt", "halts", "halting", "halted", "stop", "stops", "stopping", "stopped", "standstill", "pause", "stoppage", "ರೈಲು ನಿಲುಗಡೆ", "ನಿಲುಗಡೆ", "ರೈಲು ನಿಲ್ಲಲಿದೆ", "रुकना", "ठहराव", "रुकने"],
    "STOP": ["stop", "stops", "stopping", "stopped", "halt", "pause"],
    "STOPPING": ["stopping", "stopped", "stop", "halting"],
    "DELAY": ["delay", "delays", "delayed", "late", "lateness", "running late", "behind schedule", "behind time", "rescheduled", "postponed", "देरी", "विलंब", "ವಿಳಂಬ", "ತಡವಾಗಿ"],
    "LATE": ["late", "delayed", "running late", "tardy"],
    "EARLY": ["early", "ahead of time", "ahead of schedule", "before time", "समय से पहले", "ಮುಂಚಿತವಾಗಿ"],
    "FAST": ["fast", "speed", "speedy", "speeding", "quick", "quickly", "rapid", "rapidly", "swift", "express", "तेज", "ವೇಗವಾಗಿ"],
    "SLOW": ["slow", "slowly", "crawl", "crawling", "moderate", "धीमे", "धीरे", "ನಿಧಾನವಾಗಿ"],

    # 6. Safety, Emergency & Attention
    "CAUTION": ["caution", "cautious", "warning", "warn", "warns", "beware", "alert", "careful", "danger", "hazard", "सावधान", "सावधानी", "चेतावनी", "ಎಚ್ಚರಿಕೆ"],
    "ATTENTION": ["attention", "attention please", "listen", "notice", "announcement", "कृपया ध्यान दें", "ध्यान दें", "ಗಮನಕ್ಕೆ", "ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ"],
    "PLEASE": ["please", "kindly", "request", "requested", "kripaya", "कृपया", "ದಯವಿಟ್ಟು"],
    "EMERGENCY": ["emergency", "urgent", "urgency", "crisis", "sos", "hazard", "danger", "आपातकालीन", "ತುರ್ತು"],
    "SAFE": ["safe", "safety", "secure", "security", "protected", "protection", "surakshit", "सुरक्षित", "सुरक्षा", "ಸುರಕ್ಷಿತ", "ಸುರಕ್ಷತೆ"],
    "POLICE": ["police", "cop", "cops", "rpf", "grp", "railway police", "constable", "officer", "inspector", "guard", "पुलिस", "ಪೊಲೀಸ್", "ರೈಲ್ವೆ ಪೊಲೀಸ್"],
    "CHILD": ["child", "children", "kid", "kids", "boy", "girl", "infant", "baby", "toddler", "minor", "बच्चा", "बच्चे", "ಮಗು", "ಮಕ್ಕಳು"],
    "FOUND": ["found", "find", "located", "recovered", "traced", "identified", "मिला", "ಪತ್ತೆಯಾಗಿದೆ", "ಸಿಕ್ಕಿದೆ"],
    "PARENTS": ["parents", "parent", "mother", "father", "mom", "dad", "family", "guardians", "माता-पिता", "ಪೋಷಕರು", "ತಂದೆ ತಾಯಿ"],
    "OFFICE": ["office", "room", "station master office", "enquiry", "counter", "desk", "booth", "help desk", "कार्यालय", "ಕಚೇರಿ"],
    "ROUND": ["round", "circle", "circular", "roundabout", "gol", "सर्कल", "ಗೋಲಾಕಾರ", "ಸುತ್ತು"],

    # 7. Colors
    "BLACK": ["black", "dark", "काला", "ಕಪ್ಪು"],
    "BLUE": ["blue", "navy", "नीला", "ನೀಲಿ"],
    "BROWN": ["brown", "भूरा", "ಕಂದು"],
    "GREEN": ["green", "हरा", "ಹಸಿರು"],
    "INDIGO": ["indigo", "जामुनी", "ಇಂಡಿಗೋ"],
    "PINK": ["pink", "rose", "गुलाबी", "ಗುಲಾಬಿ"],
    "VIOLET": ["violet", "purple", "बैंगनी", "ನೇರಳೆ"],

    # 8. Greetings
    "GOODMORNING": ["good morning", "goodmorning", "morning", "suprabhat", "सुप्रभात", "ಶುಭೋದಯ"],
    "GOODAFTERNOON": ["good afternoon", "goodafternoon", "afternoon", "shubh dopahar", "शुभ दोपहर", "ಶುಭ ಮಧ್ಯಾಹ್ನ"],
    "GOODEVENING": ["good evening", "goodevening", "evening", "shubh sandhya", "शुभ संध्या", "ಶುಭ ಸಂಜೆ"]
}

# Pre-build normalized fast lookup index
SYNONYM_TO_TOKEN: Dict[str, str] = {}
for _tok, _syns in USER_GESTURE_SYNONYMS.items():
    SYNONYM_TO_TOKEN[_tok.lower()] = _tok
    SYNONYM_TO_TOKEN[_tok.lower().replace("_", " ")] = _tok
    SYNONYM_TO_TOKEN[_tok.lower().replace("_", "")] = _tok
    for _s in _syns:
        SYNONYM_TO_TOKEN[_s.lower().strip()] = _tok


def find_matching_user_gesture(word_or_phrase: str, user_words: Dict[str, Any] = None) -> Optional[str]:
    """
    Given a word or phrase (e.g. 'stopping', 'berth', 'bogie', 'वंदे भारत', 'ಸುರಕ್ಷಿತ'),
    returns the matching canonical token name if a custom gesture or synonym exists.
    """
    if not word_or_phrase:
        return None
    raw = str(word_or_phrase).strip().lower()
    import re
    clean = re.sub(r'[^a-z0-9\sऀ-ॿಀ-೿]', '', raw).strip()

    # 1. Exact canonical check
    upper_tok = clean.upper().replace(" ", "_")
    if user_words and upper_tok in user_words:
        return upper_tok
    upper_space = clean.upper()
    if user_words and upper_space in user_words:
        return upper_space

    # 2. Direct synonym match
    if clean in SYNONYM_TO_TOKEN:
        return SYNONYM_TO_TOKEN[clean]

    # 3. Suffix / Lemmatization rules
    for suffix in ['ing', 'ed', 'es', 's']:
        if clean.endswith(suffix) and len(clean) > len(suffix) + 2:
            stem = clean[:-len(suffix)]
            if stem in SYNONYM_TO_TOKEN:
                return SYNONYM_TO_TOKEN[stem]

    return None


def get_fingerspelling_for_name(name: str) -> List[Dict[str, Any]]:
    """
    Given a proper noun / person's name (like 'Shreya') or unlisted village,
    decomposes it into the Indian Sign Language (ISL) two-handed manual alphabet letters.
    """
    clean_name = "".join(ch for ch in name.upper() if ch.isalnum())
    user_reg = load_user_custom_registry()
    user_alphabet = user_reg.get("alphabet", {})
    user_numbers = user_reg.get("numbers", {})

    result = []
    for ch in clean_name:
        if ch in ISL_ALPHABET_DATA:
            letter_info = dict(ISL_ALPHABET_DATA[ch])
            letter_info["char"] = ch
            if ch in user_alphabet:
                clip_url = user_alphabet[ch].get("primary_clip")
                letter_info["custom_video_url"] = clip_url
                letter_info["custom_gif_url"] = clip_url.replace(".mp4", ".gif") if clip_url else None
                letter_info["is_user_recorded"] = True
            result.append(letter_info)
        elif ch in ISL_DIGITS_DATA:
            digit_info = dict(ISL_DIGITS_DATA[ch])
            digit_info["char"] = ch
            if ch in user_numbers:
                clip_url = user_numbers[ch].get("primary_clip")
                digit_info["custom_video_url"] = clip_url
                digit_info["custom_gif_url"] = clip_url.replace(".mp4", ".gif") if clip_url else None
                digit_info["is_user_recorded"] = True
            result.append(digit_info)
    return result


def synthesize_isl_sequence(tokens: List[Dict[str, Any]], proper_nouns: List[str] = None) -> List[Dict[str, Any]]:
    """
    Constructs a rich sequential playback list of ISL signs and letter fingerspellings.
    - Standard words: 1400ms duration (natural, brisk 24fps pace)
    - Digits & Alphabet Fingerspelling: 950ms duration
    - Any word not in dataset is automatically decomposed into letter-by-letter fingerspelling!
    """
    if proper_nouns is None:
        proper_nouns = []

    proper_nouns_upper = {p.upper() for p in proper_nouns}
    user_reg = load_user_custom_registry()
    user_words = user_reg.get("railway_words", {})
    user_digits = user_reg.get("numbers", {})
    user_alphabet = user_reg.get("alphabet", {})
    sequence = []

    for item in tokens:
        item_type = item.get("type", "word")
        sign_code = str(item.get("sign", "")).strip().upper()
        label = item.get("label", sign_code)

        # 1. Direct Fingerspelling Letter (single letter A-Z)
        if item_type == "fingerspelling_letter" or (len(sign_code) == 1 and sign_code.isalpha()):
            char = sign_code
            word = item.get("word", char)
            alpha_entry = ISL_ALPHABET_DATA.get(char, {"description": f"ISL sign for letter {char}"})
            custom_clip = f"/assets/isl_dataset/alphabet/{char}.mp4"
            custom_gif = f"/assets/isl_dataset/alphabet/{char}.gif"
            sequence.append({
                "type": "standard_sign",
                "sign_code": char,
                "token": char,
                "label": f"Letter {char} ({word})",
                "word": word,
                "letter": char,
                "is_fingerspelling": True,
                "description": f"Two-handed ISL fingerspelling for '{char}' in word '{word}'. {alpha_entry.get('description', '')}",
                "icon": "sign_language",
                "duration_ms": 950,
                "custom_video_url": custom_clip,
                "custom_gif_url": custom_gif,
                "has_custom_video": True
            })
            continue

        # 2. Proper Nouns (e.g. Person Name like Shreya) -> Decompose into letter-by-letter fingerspelling!
        is_proper_name = item.get("is_name", False) or (sign_code in proper_nouns_upper) or (label.upper() in proper_nouns_upper)
        if is_proper_name or item_type == "proper_noun":
            name_text = item.get("name_text", label.replace("Name: ", "")).upper()
            clean_name = re.sub(r'[^A-Z0-9]', '', name_text)
            for char in clean_name:
                if char.isdigit():
                    sequence.append({
                        "type": "standard_sign",
                        "sign_code": char,
                        "token": char,
                        "label": f"Digit {char}",
                        "description": f"ISL Number {char}",
                        "icon": "pin",
                        "duration_ms": 950,
                        "custom_video_url": f"/assets/isl_dataset/numbers/{char}.mp4",
                        "custom_gif_url": f"/assets/isl_dataset/numbers/{char}.gif",
                        "has_custom_video": True
                    })
                else:
                    alpha_entry = ISL_ALPHABET_DATA.get(char, {})
                    sequence.append({
                        "type": "standard_sign",
                        "sign_code": char,
                        "token": char,
                        "label": f"Letter {char} ({name_text})",
                        "word": name_text,
                        "letter": char,
                        "is_fingerspelling": True,
                        "description": f"ISL fingerspelling for '{char}' in proper name '{name_text}'.",
                        "icon": "person",
                        "duration_ms": 950,
                        "custom_video_url": f"/assets/isl_dataset/alphabet/{char}.mp4",
                        "custom_gif_url": f"/assets/isl_dataset/alphabet/{char}.gif",
                        "has_custom_video": True
                    })
            continue

        # 3. Check digits 0-9
        if sign_code in ISL_DIGITS_DATA or (len(sign_code) == 1 and sign_code.isdigit()):
            digit_entry = ISL_DIGITS_DATA.get(sign_code, {"name": sign_code, "description": f"Digit {sign_code}", "handshape": "Digit"})
            custom_clip = f"/assets/isl_dataset/numbers/{sign_code}.mp4"
            custom_gif = f"/assets/isl_dataset/numbers/{sign_code}.gif"
            sequence.append({
                "type": "standard_sign",
                "sign_code": sign_code,
                "token": sign_code,
                "label": f"Digit {sign_code} ({digit_entry.get('name', sign_code)})",
                "kannada_label": f"ಸಂಖ್ಯೆ {sign_code}",
                "hindi_label": f"अंक {sign_code}",
                "description": f"ISL Number {sign_code}: {digit_entry.get('description', '')}",
                "icon": "pin",
                "duration_ms": 950,
                "custom_video_url": custom_clip,
                "custom_gif_url": custom_gif,
                "has_custom_video": True
            })
            continue

        # 4. Check for matching user gesture or synonym (e.g. COACH, SEAT, VANDEBHARAT, HALTING, STOPPING, etc.)
        matched_token = find_matching_user_gesture(sign_code, user_words) or find_matching_user_gesture(label, user_words)

        if matched_token or sign_code in user_words or sign_code in RAILWAY_ISL_DICTIONARY:
            target_sign = matched_token or (sign_code if sign_code in user_words else sign_code)
            dict_entry = RAILWAY_ISL_DICTIONARY.get(target_sign, {})

            custom_clip = f"/assets/isl_dataset/words/{target_sign}.mp4"
            custom_gif = f"/assets/isl_dataset/words/{target_sign}.gif"
            nice_label = dict_entry.get("label", target_sign.replace("_", " ").title())

            sequence.append({
                "type": "standard_sign",
                "sign_code": target_sign,
                "token": target_sign,
                "label": nice_label,
                "kannada_label": dict_entry.get("kannada_label", ""),
                "hindi_label": dict_entry.get("hindi_label", ""),
                "description": dict_entry.get("description", f"Authentic Indian Sign Language (ISL) gesture for '{nice_label}'."),
                "icon": dict_entry.get("icon", "sign_language"),
                "duration_ms": 1400,
                "custom_video_url": custom_clip,
                "custom_gif_url": custom_gif,
                "has_custom_video": True
            })
            continue

        # 5. Word doesn't exist in dataset -> DO FINGERSPELLING letter-by-letter!
        clean_word = re.sub(r'[^A-Z0-9]', '', sign_code)
        if clean_word:
            for char in clean_word:
                if char.isdigit():
                    sequence.append({
                        "type": "standard_sign",
                        "sign_code": char,
                        "token": char,
                        "label": f"Digit {char}",
                        "description": f"ISL Number {char}",
                        "icon": "pin",
                        "duration_ms": 950,
                        "custom_video_url": f"/assets/isl_dataset/numbers/{char}.mp4",
                        "custom_gif_url": f"/assets/isl_dataset/numbers/{char}.gif",
                        "has_custom_video": True
                    })
                else:
                    alpha_entry = ISL_ALPHABET_DATA.get(char, {})
                    sequence.append({
                        "type": "standard_sign",
                        "sign_code": char,
                        "token": char,
                        "label": f"Letter {char} ({clean_word})",
                        "word": clean_word,
                        "letter": char,
                        "is_fingerspelling": True,
                        "description": f"ISL fingerspelling for '{char}' in word '{clean_word}'.",
                        "icon": "sign_language",
                        "duration_ms": 950,
                        "custom_video_url": f"/assets/isl_dataset/alphabet/{char}.mp4",
                        "custom_gif_url": f"/assets/isl_dataset/alphabet/{char}.gif",
                        "has_custom_video": True
                    })

    return sequence

def register_custom_video_for_announcement(announcement_id: str, video_path_or_url: str, title: str, author: str = "User") -> Dict[str, Any]:
    """
    Allows the user to attach a custom-recorded sign language video to any announcement.
    """
    CUSTOM_DATASET_STORE[announcement_id] = {
        "announcement_id": announcement_id,
        "video_url": video_path_or_url,
        "title": title,
        "author": author,
        "has_custom_video": True
    }
    return CUSTOM_DATASET_STORE[announcement_id]
