"""
Unit tests for Authoritative Railway Database Service & Endpoints
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.services.railway_db_service import railway_db

client = TestClient(app)

def test_candidate_stations_evaluation():
    all_stations = railway_db.get_all_stations()
    station_map = {s["code"]: s for s in all_stations}

    candidate_codes = [
        "MAQ", "MAJN", "SL", "MULK", "BNTL", "KBPR", "SBHR", "ULL",
        "YDM", "YDK", "SVGL", "TKOT", "TOK", "KNKD", "BAJE", "FRG",
        "KDBA", "KNYR", "NRF", "NRJ", "NTVT", "PNMB", "HMB", "KLKH", "PADL"
    ]

    # Verify all 25 candidate codes exist in the inventory
    for code in candidate_codes:
        assert code in station_map, f"Candidate code {code} missing from railway database inventory"

    # Verify exactly 14 confirmed active commercial passenger stations in Dakshina Kannada
    dk_selectable = railway_db.get_selectable_stations(district="Dakshina Kannada")
    dk_codes = {s["code"] for s in dk_selectable}
    expected_active_dk = {
        "MAQ", "MAJN", "SL", "MULK", "BNTL", "KBPR", "SBHR",
        "ULL", "YDM", "BAJE", "KDBA", "KNYR", "NRF", "NRJ"
    }
    assert dk_codes == expected_active_dk

    # Verify non-selectable candidates are kept in review state with proper reasons
    review_records = {r["identifier"]: r for r in railway_db.get_review_records()}

    assert "YDK" in review_records
    assert "Hassan" in review_records["YDK"]["reason"]
    assert station_map["YDK"]["is_selectable"] == 0

    assert "SVGL" in review_records
    assert station_map["SVGL"]["is_selectable"] == 0

    assert "TKOT" in review_records
    assert station_map["TKOT"]["is_selectable"] == 0

    assert "TOK" in review_records
    assert station_map["TOK"]["is_selectable"] == 0

    assert "KNKD" in review_records
    assert "MAJN" in review_records["KNKD"]["reason"]
    assert station_map["KNKD"]["is_selectable"] == 0

    assert "NTVT" in review_records
    assert station_map["NTVT"]["is_selectable"] == 0

    assert "PNMB" in review_records
    assert station_map["PNMB"]["is_selectable"] == 0

def test_train_master_records_and_halts():
    candidate_train_numbers = [
        "20631", "20632", "16649", "16610", "22637", "12619", "12620",
        "12601", "12602", "22609", "22610", "16595", "16596", "16511",
        "16512", "16585", "16586", "16575", "16576", "16515", "16516",
        "16539", "16540", "17378", "56625", "56626", "56627", "56628",
        "10107", "10108"
    ]

    all_trains = railway_db.get_all_trains()
    train_map = {t["train_number"]: t for t in all_trains}

    for t_no in candidate_train_numbers:
        assert t_no in train_map, f"Train {t_no} missing from verified train master"
        tr = train_map[t_no]
        assert tr["origin_code"] and tr["origin_name"]
        assert tr["destination_code"] and tr["destination_name"]
        assert tr["running_days"]
        assert tr["direction"]
        assert len(tr["dakshina_kannada_stops"]) > 0

    # Test Panchaganga Express (16595) stops in Dakshina Kannada
    p_16595 = train_map["16595"]
    p_stops = {s["station_code"] for s in p_16595["dakshina_kannada_stops"]}
    assert {"SBHR", "KBPR", "BNTL", "SL", "MULK"}.issubset(p_stops)

    # Test Subrahmanya Passenger (56625) full halt sequence
    pass_56625 = train_map["56625"]
    p56_stops = [s["station_code"] for s in pass_56625["dakshina_kannada_stops"]]
    assert p56_stops[0] == "MAQ"
    assert p56_stops[-1] == "SBHR"
    assert "NRF" in p56_stops
    assert "YDM" in p56_stops

def test_journey_matching():
    # Mangaluru Central to Subrahmanya Road
    matches_sbhr = railway_db.match_passenger_journey("MAQ", "Subrahmanya")
    assert len(matches_sbhr) >= 4
    train_nos = {m["train_number"] for m in matches_sbhr}
    assert "56625" in train_nos
    assert "56627" in train_nos
    assert "17378" in train_nos

    # Surathkal to Mumbai
    matches_mumbai = railway_db.match_passenger_journey("SL", "Mumbai")
    assert any(m["train_number"] == "12620" for m in matches_mumbai)

def test_fastapi_endpoints():
    # 1. Selectable stations
    r1 = client.get("/api/railway/stations?district=Dakshina%20Kannada")
    assert r1.status_code == 200
    d1 = r1.json()
    assert d1["success"] is True
    assert d1["count"] == 14

    # 2. All stations inventory
    r2 = client.get("/api/railway/stations/all")
    assert r2.status_code == 200
    d2 = r2.json()
    assert d2["count"] >= 25

    # 3. Verified trains
    r3 = client.get("/api/railway/trains")
    assert r3.status_code == 200
    d3 = r3.json()
    assert d3["count"] >= 30

    # 4. Trains by station
    r4 = client.get("/api/railway/trains?station=SBHR")
    assert r4.status_code == 200
    d4 = r4.json()
    assert d4["count"] >= 15

    # 5. Journey match
    r5 = client.get("/api/railway/journey-match?from_station=MAQ&destination=Subrahmanya")
    assert r5.status_code == 200
    d5 = r5.json()
    assert d5["match_count"] >= 4

    # 6. Review state
    r6 = client.get("/api/railway/review-state")
    assert r6.status_code == 200
    d6 = r6.json()
    assert d6["count"] >= 11

    # 7. Verification report
    r7 = client.get("/api/railway/verification-report")
    assert r7.status_code == 200
    d7 = r7.json()
    assert d7["success"] is True
    assert len(d7["sources_referenced"]) >= 5

