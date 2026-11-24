"""
Karnataka & Indian Railways Announcement Dataset
================================================
Curated authentic announcements across major Karnataka and Dakshina Kannada railway stations
(Mangaluru Central, Mangaluru Junction, Surathkal, Mulki, Bantwal, Kabaka Puttur, Subrahmanya Road, Ullal,
KSR Bengaluru, Mysuru, Hubballi, Kalaburagi) with full multilingual translations
(Kannada, English, Hindi, Tamil, Telugu), Named Entity Recognition (NER),
and Indian Sign Language (ISL) gesture mappings.
"""

from typing import List, Dict, Any, Optional
from app.services.railway_db_service import railway_db

# Query active confirmed stations from authoritative database
try:
    KARNATAKA_STATIONS = railway_db.get_selectable_stations(district=None)
except Exception:
    # Fallback to confirmed active stations
    KARNATAKA_STATIONS = [
        {"code": "MAQ", "name": "Mangaluru Central", "city": "Mangaluru", "division": "Southern Railway (SR)", "district": "Dakshina Kannada"},
        {"code": "MAJN", "name": "Mangaluru Junction", "city": "Mangaluru", "division": "Southern Railway (SR)", "district": "Dakshina Kannada"},
        {"code": "SL", "name": "Surathkal", "city": "Surathkal", "division": "Konkan Railway (KR)", "district": "Dakshina Kannada"},
        {"code": "MULK", "name": "Mulki", "city": "Mulki", "division": "Konkan Railway (KR)", "district": "Dakshina Kannada"},
        {"code": "BNTL", "name": "Bantwal", "city": "Bantwal", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "KBPR", "name": "Kabaka Puttur", "city": "Puttur", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "SBHR", "name": "Subrahmanya Road", "city": "Subrahmanya", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "ULL", "name": "Ullal", "city": "Ullal", "division": "Southern Railway (SR)", "district": "Dakshina Kannada"},
        {"code": "YDM", "name": "Yedamangala", "city": "Kadaba", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "BAJE", "name": "Bajakare Halt", "city": "Bajakare", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "KDBA", "name": "Kodimbala Halt", "city": "Kodimbala", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "KNYR", "name": "Kaniuru Halt", "city": "Kaniyoor", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "NRF", "name": "Neralakatte Halt", "city": "Neralakatte", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "NRJ", "name": "Narimogaru", "city": "Narimogaru", "division": "South Western Railway (SWR)", "district": "Dakshina Kannada"},
        {"code": "SBC", "name": "KSR Bengaluru City", "city": "Bengaluru", "division": "South Western Railway (SWR)", "district": "Bengaluru Urban"},
        {"code": "MYS", "name": "Mysuru Junction", "city": "Mysuru", "division": "South Western Railway (SWR)", "district": "Mysuru"},
        {"code": "UBL", "name": "SSS Hubballi Junction", "city": "Hubballi", "division": "South Western Railway (SWR)", "district": "Dharwad"},
    ]

# Preset authentic Karnataka & Dakshina Kannada Railway announcements
ANNOUNCEMENT_PRESETS: List[Dict[str, Any]] = [
    # 1. Train 20631 Vande Bharat Express at Mangaluru Central
    {
        "id": "ann_vande_bharat_20631_maq",
        "station_code": "MAQ",
        "station_name": "Mangaluru Central",
        "category": "departure",
        "category_label": "Vande Bharat Departure Announcement",
        "title": "Train 20631 Vande Bharat Express Ready for Departure",
        "primary_language": "English",
        "audio_sample_url": "https://www.youtube.com/watch?v=vande_bharat_maq",
        "youtube_demo": "https://www.youtube.com/watch?v=vande_bharat_maq",
        "transcription": "May I have your attention please. Train number 20631 Vande Bharat Express from Mangaluru Central to Thiruvananthapuram Central is ready for departure on platform number 1. Passengers please take note.",
        "translations": {
            "en": "May I have your attention please. Train number 20631 Vande Bharat Express from Mangaluru Central to Thiruvananthapuram Central is ready for departure on platform number 1. Passengers please take note.",
            "kn": "ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಮಂಗಳೂರು ಸೆಂಟ್ರಲ್‌ನಿಂದ ತಿರುವನಂತಪುರಂ ಸೆಂಟ್ರಲ್‌ಗೆ ತೆರಳುವ ಗಾಡಿ ಸಂಖ್ಯೆ 20631 ವಂದೇ ಭಾರತ್ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 1 ರಿಂದ ಹೊರಡಲು ಸಿದ್ಧವಾಗಿದೆ. ಪ್ರಯಾಣಿಕರು ಗಮನಿಸಬೇಕಾಗಿ ವಿನಂತಿ.",
            "hi": "यात्रियों का ध्यान आकर्षित किया जाता है। मंगलुरु सेंट्रल से तिरुवनंतपुरम सेंट्रल जाने वाली गाड़ी संख्या 20631 वंदे भारत एक्सप्रेस प्लेटफार्म नंबर 1 से प्रस्थान के लिए तैयार है।",
            "ta": "பயணிகள் கவனத்திற்கு. மங்களூரு சென்ட்ரலிலிருந்து திருவனந்தபுரம் சென்ட்ரல் செல்லும் வண்டி எண் 20631 வந்தே பாரத் எக்ஸ்பிரஸ் நடைமேடை எண் 1-லிருந்து புறப்பட தயாராக உள்ளது.",
            "te": "ప్రయాణీకుల దృష్టికి. మంగళూరు సెంట్రల్ నుండి తిరువనంతపురం సెంట్రల్ వెళ్లే రైలు నంబర్ 20631 వందే భారత్ ఎక్స్‌ప్రెస్ ప్లాట్‌ఫారమ్ నంబర్ 1 నుండి బయలుదేరడానికి సిద్ధంగా ఉంది."
        },
        "named_entities": [
            {"text": "20631", "entity_type": "TRAIN_NUMBER", "label": "Train 20631", "fingerspell": ["2", "0", "6", "3", "1"]},
            {"text": "Vande Bharat Express", "entity_type": "TRAIN_NAME", "label": "Vande Bharat Express", "fingerspell": ["V", "A", "N", "D", "E"]},
            {"text": "Mangaluru Central", "entity_type": "STATION", "label": "Origin", "fingerspell": ["M", "A", "Q"]},
            {"text": "Thiruvananthapuram Central", "entity_type": "DESTINATION", "label": "Destination", "fingerspell": ["T", "V", "C"]},
            {"text": "1", "entity_type": "PLATFORM", "label": "Platform 1", "fingerspell": ["1"]}
        ],
        "isl_tokens": [
            "ATTENTION", "PASSENGERS", "TRAIN", "NUMBER", "2", "0", "6", "3", "1",
            "VANDE_BHARAT", "FROM", "MANGALURU", "TO", "THIRUVANANTHAPURAM", "READY", "DEPART", "PLATFORM", "1"
        ],
        "has_custom_video": False,
        "custom_video_url": None
    },
    # 2. Train 16595 Panchaganga Express at Subrahmanya Road
    {
        "id": "ann_panchaganga_16595_sbhr",
        "station_code": "SBHR",
        "station_name": "Subrahmanya Road",
        "category": "arrival",
        "category_label": "Panchaganga Express Arrival",
        "title": "Train 16595 Panchaganga Express at Subrahmanya Road",
        "primary_language": "Kannada",
        "audio_sample_url": "https://www.youtube.com/watch?v=panchaganga_sbhr",
        "youtube_demo": "https://www.youtube.com/watch?v=panchaganga_sbhr",
        "transcription": "ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಕೆಎಸ್ಆರ್ ಬೆಂಗಳೂರಿನಿಂದ ಕಾರವಾರಕ್ಕೆ ತೆರಳುವ ಗಾಡಿ ಸಂಖ್ಯೆ 16595 ಪಂಚಗಂಗಾ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಕೆಲವೇ ಕ್ಷಣಗಳಲ್ಲಿ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 1 ಕ್ಕೆ ಬರಲಿದೆ.",
        "translations": {
            "en": "May I have your attention please. Train number 16595 Panchaganga Express from KSR Bengaluru to Karwar via Subrahmanya Road is arriving shortly on platform number 1.",
            "kn": "ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಕೆಎಸ್ಆರ್ ಬೆಂಗಳೂರಿನಿಂದ ಕಾರವಾರಕ್ಕೆ ತೆರಳುವ ಗಾಡಿ ಸಂಖ್ಯೆ 16595 ಪಂಚಗಂಗಾ ಎಕ್ಸ್‌ಪ್ರೆಸ್ ಕೆಲವೇ ಕ್ಷಣಗಳಲ್ಲಿ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 1 ಕ್ಕೆ ಬರಲಿದೆ.",
            "hi": "यात्रियों कृपया ध्यान दें। केएसआर बेंगलुरु से कारवार जाने वाली गाड़ी संख्या 16595 पंचगंगा एक्सप्रेस कुछ ही समय में प्लेटफार्म नंबर 1 पर आ रही है।",
            "ta": "பயணிகள் கவனத்திற்கு. கேஎஸ்ஆர் பெங்களூரிலிருந்து கார்வார் செல்லும் வண்டி எண் 16595 பஞ்சகங்கா எக்ஸ்பிரஸ் விரைவில் நடைமேடை 1-க்கு வந்து சேரும்.",
            "te": "ప్రయాణీకుల దృష్టికి. కేఎస్ఆర్ బెంగళూరు నుండి కార్వార్ వెళ్లే రైలు నంబర్ 16595 పంచగంగ ఎక్స్‌ప్రెస్ కొద్దిసేపట్లో ప్లాట్‌ఫారమ్ నంబర్ 1 కు చేరుకుంటుంది."
        },
        "named_entities": [
            {"text": "16595", "entity_type": "TRAIN_NUMBER", "label": "Train 16595", "fingerspell": ["1", "6", "5", "9", "5"]},
            {"text": "Panchaganga Express", "entity_type": "TRAIN_NAME", "label": "Panchaganga Express", "fingerspell": ["P", "A", "N", "C", "H", "A"]},
            {"text": "KSR Bengaluru", "entity_type": "STATION", "label": "Origin", "fingerspell": ["S", "B", "C"]},
            {"text": "Karwar", "entity_type": "DESTINATION", "label": "Destination", "fingerspell": ["K", "A", "W", "R"]},
            {"text": "1", "entity_type": "PLATFORM", "label": "Platform 1", "fingerspell": ["1"]}
        ],
        "isl_tokens": [
            "ATTENTION", "PASSENGERS", "TRAIN", "NUMBER", "1", "6", "5", "9", "5",
            "PANCHAGANGA_EXPRESS", "FROM", "BENGALURU", "TO", "KARWAR", "SHORTLY", "ARRIVE", "PLATFORM", "1"
        ],
        "has_custom_video": False,
        "custom_video_url": None
    },
    # 3. Train 56625 Passenger at Bantwal (BNTL)
    {
        "id": "ann_passenger_56625_bntl",
        "station_code": "BNTL",
        "station_name": "Bantwal",
        "category": "arrival",
        "category_label": "Local Commuter Passenger Arrival",
        "title": "Train 56625 Passenger from Mangaluru Central to Subrahmanya Road",
        "primary_language": "Kannada",
        "audio_sample_url": "https://www.youtube.com/watch?v=passenger_56625",
        "youtube_demo": "https://www.youtube.com/watch?v=passenger_56625",
        "transcription": "ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಮಂಗಳೂರು ಸೆಂಟ್ರಲ್‌ನಿಂದ ಸುಬ್ರಹ್ಮಣ್ಯ ರೋಡ್‌ಗೆ ತೆರಳುವ ಗಾಡಿ ಸಂಖ್ಯೆ 56625 ಪ್ಯಾಸೆಂಜರ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 2 ಕ್ಕೆ ಆಗಮಿಸುತ್ತಿದೆ.",
        "translations": {
            "en": "May I have your attention please. Train number 56625 Passenger from Mangaluru Central to Subrahmanya Road is arriving on platform number 2. Passengers please take note.",
            "kn": "ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ಮಂಗಳೂರು ಸೆಂಟ್ರಲ್‌ನಿಂದ ಸುಬ್ರಹ್ಮಣ್ಯ ರೋಡ್‌ಗೆ ತೆರಳುವ ಗಾಡಿ ಸಂಖ್ಯೆ 56625 ಪ್ಯಾಸೆಂಜರ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಸಂಖ್ಯೆ 2 ಕ್ಕೆ ಆಗಮಿಸುತ್ತಿದೆ.",
            "hi": "यात्रियों का ध्यान आकर्षित किया जाता है। मंगलुरु सेंट्रल से सुब्रह्मण्य रोड जाने वाली गाड़ी संख्या 56625 पैसेंजर प्लेटफार्म नंबर 2 पर आ रही है।",
            "ta": "பயணிகள் கவனத்திற்கு. மங்களூரு சென்ட்ரலிலிருந்து சுப்ரமண்யா ரோடு செல்லும் வண்டி எண் 56625 பாசஞ்சர் நடைமேடை எண் 2-க்கு வருகிறது.",
            "te": "ప్రయాణీకుల దృష్టికి. మంగళూరు సెంట్రల్ నుండి సుబ్రహ్మణ్య రోడ్ వెళ్లే రైలు నంబర్ 56625 ప్యాసింజర్ ప్లాట్‌ఫారమ్ నంబర్ 2 కి చేరుకుంటుంది."
        },
        "named_entities": [
            {"text": "56625", "entity_type": "TRAIN_NUMBER", "label": "Train 56625", "fingerspell": ["5", "6", "6", "2", "5"]},
            {"text": "Passenger", "entity_type": "TRAIN_NAME", "label": "Passenger", "fingerspell": ["P", "A", "S", "S"]},
            {"text": "Mangaluru Central", "entity_type": "STATION", "label": "Origin", "fingerspell": ["M", "A", "Q"]},
            {"text": "Subrahmanya Road", "entity_type": "DESTINATION", "label": "Destination", "fingerspell": ["S", "B", "H", "R"]},
            {"text": "2", "entity_type": "PLATFORM", "label": "Platform 2", "fingerspell": ["2"]}
        ],
        "isl_tokens": [
            "ATTENTION", "PASSENGERS", "TRAIN", "NUMBER", "5", "6", "6", "2", "5",
            "PASSENGER", "FROM", "MANGALURU", "TO", "SUBRAHMANYA", "ARRIVE", "PLATFORM", "2"
        ],
        "has_custom_video": False,
        "custom_video_url": None
    },
    # 4. Emergency & Station Safety Notice at Mangaluru Central (High Priority to Everyone)
    {
        "id": "ann_emergency_security_maq",
        "station_code": "MAQ",
        "station_name": "Mangaluru Central",
        "category": "station_safety",
        "category_label": "Public Safety & Security Notice",
        "title": "Unattended Baggage Alert & Railway Helpline 139",
        "primary_language": "English",
        "audio_sample_url": "https://www.youtube.com/watch?v=security_baggage_alert",
        "youtube_demo": "https://www.youtube.com/watch?v=security_baggage_alert",
        "transcription": "Security alert. If you notice any suspicious, unclaimed, or unattended baggage on railway premises, please do not touch it. Immediately alert the on-duty Railway Protection Force or call railway helpline 139.",
        "translations": {
            "en": "Security alert. If you notice any suspicious, unclaimed, or unattended baggage on railway premises, please do not touch it. Immediately alert the on-duty Railway Protection Force or call railway helpline 139.",
            "kn": "ಸುರಕ್ಷತಾ ಎಚ್ಚರಿಕೆ. ರೈಲ್ವೆ ಆವರಣದಲ್ಲಿ ಯಾವುದೇ ಅನುಮಾನಾಸ್ಪದ, ಮಾಲೀಕರಿಲ್ಲದ ಬ್ಯಾಗ್ ಅಥವಾ ವಸ್ತು ಕಂಡುಬಂದಲ್ಲಿ, ದಯವಿಟ್ಟು ಮುಟ್ಟಬೇಡಿ. ತಕ್ಷಣ ಕರ್ತವ್ಯದಲ್ಲಿರುವ ರೈಲ್ವೆ ರಕ್ಷಣಾ ಪಡೆಗೆ ತಿಳಿಸಿ ಅಥವಾ 139 ಗೆ ಕರೆ ಮಾಡಿ.",
            "hi": "सुरक्षा चेतावनी। यदि आपको रेलवे परिसर में कोई भी लावारिस या संदिग्ध वस्तु दिखाई दे, तो उसे न छुएं। तुरंत रेलवे सुरक्षा बल को सूचित करें या हेल्पलाइन 139 पर संपर्क करें।",
            "ta": "பாதுகாப்பு எச்சரிக்கை. ரயில்வே வளாகத்தில் உரிமை கோரப்படாத சந்தேகத்திற்கிடமான பைகள் காணப்பட்டால் தொட வேண்டாம். உடனே 139 அல்லது ஆர்பிஎஃப்-ஐ தொடர்பு கொள்ளவும்.",
            "te": "భద్రతా హెచ్చరిక. రైల్వే ప్రాంగణంలో అనుమానాస్పద లేదా అనాథ లగేజీ కనిపిస్తే ముట్టుకోవద్దు. వెంటనే ఆర్పీఎఫ్ లేదా 139 కి సమాచారం అందించండి."
        },
        "named_entities": [
            {"text": "139", "entity_type": "PHONE_NUMBER", "label": "Helpline 139", "fingerspell": ["1", "3", "9"]},
            {"text": "RPF", "entity_type": "ORGANIZATION", "label": "Security Force", "fingerspell": ["R", "P", "F"]}
        ],
        "isl_tokens": [
            "CAUTION", "BAG", "DONT_TOUCH", "POLICE", "139"
        ],
        "has_custom_video": False,
        "custom_video_url": None
    },
    # 5. Missing Child Emergency Notice at Surathkal (High Priority to Everyone)
    {
        "id": "ann_missing_child_sl",
        "station_code": "SL",
        "station_name": "Surathkal",
        "category": "station_safety",
        "category_label": "Urgent Station Safety Announcement",
        "title": "Missing Child Alert at Surathkal Station",
        "primary_language": "English",
        "audio_sample_url": "https://www.youtube.com/watch?v=missing_child_alert",
        "youtube_demo": "https://www.youtube.com/watch?v=missing_child_alert",
        "transcription": "Attention please, urgent passenger announcement. A 6-year-old child wearing a blue shirt is separated from parents near platform 1. If seen, please bring the child to the station master office immediately.",
        "translations": {
            "en": "Attention please, urgent passenger announcement. A 6-year-old child wearing a blue shirt is separated from parents near platform 1. If seen, please bring the child to the station master office immediately.",
            "kn": "ತುರ್ತು ಪ್ರಯಾಣಿಕರ ಗಮನಕ್ಕೆ. ನೀಲಿ ಶರ್ಟ್ ಧರಿಸಿರುವ 6 ವರ್ಷದ ಮಗು ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ 1 ರ ಬಳಿ ಪೋಷಕರಿಂದ ಕಳೆದುಹೋಗಿದೆ. ಕಂಡುಬಂದಲ್ಲಿ ತಕ್ಷಣವೇ ಸ್ಟೇಷನ್ ಮಾಸ್ಟರ್ ಕಚೇರಿಗೆ ಕರೆತರಲು ವಿನಂತಿ.",
            "hi": "कृपया ध्यान दें, आवश्यक सूचना। नीली कमीज पहने 6 वर्ष का एक बच्चा प्लेटफार्म 1 के पास अपने माता-पिता से बिछड़ गया है। कृपया बच्चे को स्टेशन मास्टर कार्यालय लाएं।",
            "ta": "கவனத்திற்கு, அவசர அறிவிப்பு. நடைமேடை 1 அருகில் நீல நிற சட்டை அணிந்த 6 வயது குழந்தை காணாமல் போயுள்ளது. கண்டால் உடனே ஸ்டேஷன் மாஸ்டர் அலுவலகத்திற்கு அழைத்து வரவும்.",
            "te": "దృష్టికి, అత్యవసర ప్రకటన. ప్లాట్‌ఫారమ్ 1 వద్ద నీలిరంగు చొక్కా ధరించిన 6 సంవత్సరాల చిన్నారి తల్లిదండ్రుల నుండి తప్పిపోయింది. స్టేషన్ మాస్టర్ ఆఫీసుకు తీసుకురాగలరు."
        },
        "named_entities": [
            {"text": "child", "entity_type": "PERSON", "label": "Child", "fingerspell": ["C", "H", "I", "L", "D"]},
            {"text": "1", "entity_type": "PLATFORM", "label": "Platform 1", "fingerspell": ["1"]}
        ],
        "isl_tokens": [
            "ATTENTION", "URGENT", "CHILD", "LOST", "PLATFORM", "1", "HELP", "OFFICE"
        ],
        "has_custom_video": False,
        "custom_video_url": None
    }
]

def get_announcements_by_station(station_code: str) -> List[Dict[str, Any]]:
    clean = station_code.upper().strip()
    return [a for a in ANNOUNCEMENT_PRESETS if a.get("station_code") == clean]

def get_announcement_by_id(ann_id: str) -> Optional[Dict[str, Any]]:
    for a in ANNOUNCEMENT_PRESETS:
        if a["id"] == ann_id:
            return a
    return None
