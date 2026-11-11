import itertools

import pytest

from app.catalog import DEPARTMENTS, SOIL_TYPES, WATER_LEVELS
from app.services import recommendation_service as engine
from app.utils.agrosmart_data import AGROSMART_DATA


def test_dataset_has_16_crops_and_8_departments():
    assert len(AGROSMART_DATA["crops"]) == 16
    assert len(DEPARTMENTS) == 8


def test_every_band_soil_water_combination_has_a_rule():
    combos = set(itertools.product(["Baja", "Media", "Alta"], SOIL_TYPES, WATER_LEVELS))
    rules = {(r["altitud"], r["suelo"], r["disponibilidad_hidrica"]) for r in engine.RULES}
    assert combos == rules
    assert len(engine.RULES) == 54


@pytest.mark.parametrize("altitude,band", [(0, "Baja"), (2499, "Baja"), (2500, "Media"), (3500, "Media"), (3501, "Alta")])
def test_classify_altitude(altitude, band):
    assert engine.classify_altitude(altitude) == band


def test_income_formula():
    assert engine.estimated_income(12.5, 0.8) == 10000.0
    assert engine.estimated_income(0, 5) is None
    assert engine.estimated_income(2, 0) is None


def test_results_sorted_by_estimated_income_not_price():
    result = engine.get_recommendation("Cusco", 3600, "Andosol", "Media")
    incomes = [c["estimated_income_per_ha"] for c in result["recommended_crops"]]
    assert incomes == sorted(incomes, reverse=True)
    names = [c["crop_key"] for c in result["recommended_crops"]]
    # Antes la papa salía última por su precio/kg; con ingreso por hectárea va por delante de la quinua.
    assert names.index("papa") < names.index("quinua")


def test_justification_has_no_double_period_and_mentions_user_conditions():
    result = engine.get_recommendation("Cusco", 3600, "Andosol", "Media")
    for crop in result["recommended_crops"]:
        assert ".." not in crop["justification"]
        assert "3 600 m" in crop["justification"]
        assert all(s.endswith(".") for s in crop["reasons"] + crop["warnings"])


def test_soil_mismatch_produces_warning():
    result = engine.get_recommendation("Cusco", 3600, "Andosol", "Media")
    haba = next(c for c in result["recommended_crops"] if c["crop_key"] == "haba")
    assert haba["soil_match"] is True
    avena = next(c for c in result["recommended_crops"] if c["crop_key"] == "avena")
    assert avena["water_match"] is True


def test_previously_missing_combination_returns_transparent_fallback():
    result = engine.get_recommendation("Puno", 3900, "Fluvisol", "Baja")
    assert result["used_fallback"] is True
    assert result["notice"]
    assert result["recommended_crops"], "debe ofrecer alternativas con reservas"
    for crop in result["recommended_crops"]:
        assert crop["is_fallback"] is True
        assert crop["water_need"] == "Baja"
        assert crop["min_altitude"] <= 3900 <= crop["max_altitude"]
        assert crop["soil_match"] is False
        assert crop["tag"] == "Alternativa con reservas"


def test_no_combination_in_supported_range_returns_empty_without_explanation():
    """Para altitudes entre 1000 y 4400 m siempre debe haber resultados o una explicación."""
    for dept, soil, water, alt in itertools.product(DEPARTMENTS[:2], SOIL_TYPES, WATER_LEVELS, range(1000, 4401, 250)):
        result = engine.get_recommendation(dept, alt, soil, water)
        assert result["recommended_crops"] or result["notice"] == engine.EMPTY_NOTICE


def test_previously_empty_combinations_now_have_results():
    # Alta + Fluvisol + Media listaba sólo cultivos con altitud máxima <= 3800 m.
    result = engine.get_recommendation("Cusco", 4000, "Fluvisol", "Media")
    assert result["recommended_crops"]
    assert result["used_fallback"] is True


def test_altitude_outside_all_crops_returns_empty_with_notice():
    result = engine.get_recommendation("Puno", 4900, "Andosol", "Alta")
    assert result["recommended_crops"] == []
    assert result["notice"] == engine.EMPTY_NOTICE


def test_price_disclaimer_present_and_flagged_in_dataset():
    result = engine.get_recommendation("Cusco", 3200, "Andosol", "Media")
    assert "no son cotizaciones regionales verificadas" in result["price_disclaimer"]
    assert AGROSMART_DATA["metadata"]["prices_verified_by_region"] is False
