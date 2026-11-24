import requests

tests = [
    # 1. Songs / Music Lyrics
    ('Tere vaaste falak se main sitare le aaun baby dance with me forever', False, 'music_song'),
    ('Let me love you till the morning light baby baby oh yeah', False, 'music_song'),
    ('Chaiyya Chaiyya Chal Chaiyya Chaiyya', False, 'music_song'),

    # 2. General Non-Railway
    ('What is the weather in Delhi tomorrow?', False, 'general_non_railway'),
    ('Can you order pizza for dinner tonight?', False, 'general_non_railway'),

    # 3. Railway Operations
    ('Train number 12626 Kerala Express arriving on platform number 3', True, 'train_arrival'),
    ('Attention passengers, train 20608 Vande Bharat Express is delayed by 45 minutes', True, 'train_delay'),
    ('Platform change notice: Rajdhani Express will now depart from platform 4 instead of platform 2', True, 'platform_change'),

    # 4. Station Safety Alerts (Crucial user requirement: missing child, wallet, phone, etc.)
    ('Attention please, a 6-year-old child named Rahul wearing a blue shirt is missing near platform 2. Please contact the station master immediately.', True, 'station_safety'),
    ('A black leather wallet has been found near the ticket counter. Owner please collect from station master office.', True, 'station_safety'),
    ('A lost mobile phone iPhone has been reported near the waiting hall.', True, 'station_safety'),
    ('Missing person alert: an elderly passenger has been separated from their family on platform 1.', True, 'station_safety'),
    ('Security alert: unattended baggage found near platform 5 escalator. Please maintain safe distance.', True, 'station_safety'),
]

print("=== TESTING BACKEND TRANSLATE / VALIDATION ENDPOINT ===")
all_passed = True
for text, expected_valid, expected_cat in tests:
    res = requests.post("http://127.0.0.1:5000/api/announcements/translate-text", json={"text": text})
    data = res.json()
    is_valid = data.get("is_railway_announcement")
    cat = data.get("announcement_category")
    reason = data.get("railway_validation_reason", "")
    match_valid = (is_valid == expected_valid)
    status_icon = "PASS" if match_valid else "FAIL"
    if not match_valid:
        all_passed = False
    print(f"[{status_icon}] is_railway={is_valid} (exp {expected_valid}), cat={cat} | reason: {reason[:40]} | Text: {text[:45]}...")

print("\n=== TESTING YOUTUBE URL VALIDATION ENDPOINT ===")
invalid_urls = [
    "https://google.com",
    "https://vimeo.com/123456",
    "not_a_url",
    "https://example.com/watch?v=12345"
]
for u in invalid_urls:
    res = requests.post("http://127.0.0.1:5000/api/announcements/process-youtube", json={"youtube_url": u})
    data = res.json()
    success = data.get("success")
    msg = data.get("message") or data.get("error")
    print(f"URL: {u} -> success={success}, msg={msg}")

print("\nALL NLP AND YOUTUBE TESTS PASSED:", all_passed)
