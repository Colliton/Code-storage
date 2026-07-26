from datetime import UTC, datetime

from generator import generate_samples


def test_generate_samples_is_deterministic_with_seed_and_now():
    fixed_now = datetime(2026, 7, 26, 12, 0, 0, tzinfo=UTC)

    samples_run_1 = generate_samples(sample_count=5, seed=7, now_utc=fixed_now)
    samples_run_2 = generate_samples(sample_count=5, seed=7, now_utc=fixed_now)

    assert [sample.to_dict() for sample in samples_run_1] == [
        sample.to_dict() for sample in samples_run_2
    ]


def test_generated_samples_have_consistent_qc_reason_rules():
    fixed_now = datetime(2026, 7, 26, 12, 0, 0, tzinfo=UTC)
    samples = generate_samples(sample_count=500, seed=21, now_utc=fixed_now)

    for sample in samples:
        if sample.qc_status == "PASS":
            assert sample.qc_failure_reason is None
        else:
            assert sample.qc_failure_reason is not None

        if sample.qubit_concentration_ng_ul is None:
            assert sample.total_yield_ng is None
            assert sample.qc_status == "FAIL"
            assert sample.qc_failure_reason is not None
            assert "concentration not measured" in sample.qc_failure_reason

        if sample.analyte == "RNA" and sample.rin_score is None:
            assert sample.qc_status == "FAIL"
            assert sample.qc_failure_reason is not None
            assert "rin_not_measured" in sample.qc_failure_reason


def test_generated_samples_have_expected_structure():
    fixed_now = datetime(2026, 7, 26, 12, 0, 0, tzinfo=UTC)
    samples = generate_samples(sample_count=5, seed=7, now_utc=fixed_now)
    assert len(samples) == 5

    first = samples[0].to_dict()
    assert set(first.keys()) == {
        "sample_id",
        "batch_id",
        "sample_source",
        "analyte",
        "collection_timestamp",
        "processing_timestamp",
        "operator_id",
        "cell_count",
        "viability_percent",
        "qubit_assay_type",
        "qubit_concentration_ng_ul",
        "sample_volume_ul",
        "total_yield_ng",
        "rin_score",
        "storage_temperature",
        "qc_status",
        "qc_failure_reason",
        "source_file",
        "ingestion_timestamp",
    }
    assert first["sample_id"].startswith(first["batch_id"] + "-SMP-")
    assert datetime.fromisoformat(first["collection_timestamp"])
    assert datetime.fromisoformat(first["processing_timestamp"])


def test_all_samples_share_same_batch():
    fixed_now = datetime(2026, 7, 26, 12, 0, 0, tzinfo=UTC)
    samples = generate_samples(sample_count=50, seed=42, now_utc=fixed_now)

    batch_ids = {sample.batch_id for sample in samples}
    assert len(batch_ids) == 1


def test_sample_ids_are_unique():
    fixed_now = datetime(2026, 7, 26, 12, 0, 0, tzinfo=UTC)
    samples = generate_samples(sample_count=200, seed=99, now_utc=fixed_now)

    sample_ids = [sample.sample_id for sample in samples]
    assert len(sample_ids) == len(set(sample_ids))


def test_processing_timestamp_is_after_collection_time():
    fixed_now = datetime(2026, 7, 26, 12, 0, 0, tzinfo=UTC)
    samples = generate_samples(sample_count=200, seed=123, now_utc=fixed_now)

    for sample in samples:
        assert sample.processing_timestamp >= sample.collection_timestamp
