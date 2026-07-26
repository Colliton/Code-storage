import json

import pytest
from generator import generate_samples
from writer import infer_format_from_path, render_payload


def test_infer_format_from_path_enforces_ndjson():
    assert infer_format_from_path("samples/20260726_samples.ndjson") == "ndjson"
    assert infer_format_from_path("samples/20260726_samples.jsonl") == "ndjson"


def test_infer_format_from_path_rejects_unknown_extensions():
    with pytest.raises(ValueError):
        infer_format_from_path("samples/data.csv")

    with pytest.raises(ValueError):
        infer_format_from_path("samples/data.json")


def test_render_payload_ndjson_contains_one_json_per_line():
    samples = generate_samples(sample_count=1, seed=3)
    payload, content_type = render_payload(samples=samples, output_format="ndjson")

    assert content_type == "application/x-ndjson"
    lines = payload.strip().splitlines()
    assert len(lines) == 1
    recourd = json.loads(lines[0])
    assert "sample_id" in recourd
    assert "batch_id" in recourd
    assert recourd["sample_id"].startswith(recourd["batch_id"] + "-SMP-")


def test_render_payload_rejects_unsupported_format():
    samples = generate_samples(sample_count=1, seed=3)
    with pytest.raises(ValueError):
        render_payload(samples=samples, output_format="csv")
