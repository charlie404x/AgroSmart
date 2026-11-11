from tests.conftest import VALID_REQUEST, register


def test_health_and_root(client):
    assert client.get("/health").json() == {"status": "ok"}
    assert client.get("/").status_code == 200


def test_recommend_requires_auth(client):
    assert client.post("/recommend/", json=VALID_REQUEST).status_code == 401


def test_recommend_ok_and_saved_in_history(client, auth_headers):
    res = client.post("/recommend/", json=VALID_REQUEST, headers=auth_headers)
    assert res.status_code == 200
    body = res.json()
    assert body["id"] and body["created_at"].endswith(("Z", "+00:00"))
    assert body["recommended_crops"]
    first = body["recommended_crops"][0]
    for key in ("estimated_income_per_ha", "reasons", "warnings", "tag", "suitability", "ideal_soils"):
        assert key in first
    history = client.get("/history/", headers=auth_headers).json()
    assert history["total"] == 1
    assert history["items"][0]["id"] == body["id"]
    assert history["items"][0]["top_crops"] == [c["name"] for c in body["recommended_crops"][:3]]
    assert history["items"][0]["top_crop_keys"] == [c["crop_key"] for c in body["recommended_crops"][:3]]


def test_recommend_accepts_case_and_accent_variants(client, auth_headers):
    payload = {**VALID_REQUEST, "department": "junin", "soil_type": "andosol", "water_availability": "media"}
    res = client.post("/recommend/", json=payload, headers=auth_headers)
    assert res.status_code == 200
    assert res.json()["department"] == "Junín"


def test_recommend_validation_messages_in_spanish(client, auth_headers):
    cases = [
        ({"department": "Lima"}, "Departamento no válido"),
        ({"soil_type": "Arcilla"}, "Tipo de suelo no válido"),
        ({"water_availability": "Mucha"}, "Disponibilidad hídrica no válida"),
        ({"altitude": -10}, "entre 0 y 5000"),
        ({"altitude": 5001}, "entre 0 y 5000"),
        ({"altitude": "alto"}, "Altitud debe ser un número"),
    ]
    for override, expected in cases:
        res = client.post("/recommend/", json={**VALID_REQUEST, **override}, headers=auth_headers)
        assert res.status_code == 422, override
        assert expected in res.json()["detail"], res.json()


def test_recommend_missing_field(client, auth_headers):
    payload = {k: v for k, v in VALID_REQUEST.items() if k != "soil_type"}
    res = client.post("/recommend/", json=payload, headers=auth_headers)
    assert res.status_code == 422
    assert res.json()["detail"] == "Tipo de suelo es obligatorio."


def test_recommend_empty_result_is_200_with_notice(client, auth_headers):
    payload = {**VALID_REQUEST, "altitude": 4900, "department": "Puno"}
    res = client.post("/recommend/", json=payload, headers=auth_headers)
    assert res.status_code == 200
    assert res.json()["recommended_crops"] == [] and res.json()["notice"]


def test_history_detail_ownership_and_delete(client, auth_headers):
    query_id = client.post("/recommend/", json=VALID_REQUEST, headers=auth_headers).json()["id"]
    detail = client.get(f"/history/{query_id}", headers=auth_headers)
    assert detail.status_code == 200 and detail.json()["id"] == query_id

    other = register(client, email="luis@example.com", name="Luis Mamani").json()["access_token"]
    other_headers = {"Authorization": f"Bearer {other}"}
    assert client.get(f"/history/{query_id}", headers=other_headers).status_code == 404
    assert client.delete(f"/history/{query_id}", headers=other_headers).status_code == 404
    assert client.get("/history/", headers=other_headers).json()["total"] == 0

    assert client.delete(f"/history/{query_id}", headers=auth_headers).status_code == 204
    assert client.get(f"/history/{query_id}", headers=auth_headers).status_code == 404


def test_history_pagination_newest_first(client, auth_headers):
    ids = [
        client.post("/recommend/", json={**VALID_REQUEST, "altitude": 3000 + i}, headers=auth_headers).json()["id"]
        for i in range(3)
    ]
    page = client.get("/history/?limit=2&offset=0", headers=auth_headers).json()
    assert page["total"] == 3 and [i["id"] for i in page["items"]] == ids[::-1][:2]
    assert client.get("/history/?limit=500", headers=auth_headers).status_code == 422


def test_climate_endpoint(client):
    res = client.get("/climate/Cusco")
    assert res.status_code == 200
    body = res.json()
    assert body["data_type"] == "referencial"
    assert body["temperature_range"] == "9–16 °C"
    assert "año" in body["precipitation"]
    assert client.get("/climate/junin").json()["department"] == "Junín"
    missing = client.get("/climate/Lima")
    assert missing.status_code == 404 and "No hay información climática" in missing.json()["detail"]


def test_catalog(client):
    body = client.get("/catalog").json()
    assert len(body["departments"]) == 8 and len(body["soil_types"]) == 6


def test_unknown_route_spanish_404(client):
    res = client.get("/no-existe")
    assert res.status_code == 404 and res.json()["detail"] == "Recurso no encontrado."
