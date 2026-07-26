import os
from dataclasses import replace
from datetime import UTC, datetime

from config import build_partitioned_object_path, derive_base_prefix, load_settings
from flask import Request
from generator import generate_samples
from writer import infer_format_from_path, render_payload, upload_payload


def generate(_request: Request) -> tuple[dict, int]:
    settings = load_settings()
    samples = generate_samples(
        sample_count=settings.sample_count, seed=settings.sample_seed
    )

    base_prefix = derive_base_prefix(settings.object_path)
    partitioned_object_path = build_partitioned_object_path(
        base_prefix=base_prefix,
        sample_count=settings.sample_count,
        seed=settings.sample_seed,
    )
    ingestion_timestamp = datetime.now(UTC)
    samples = [
        replace(
            sample,
            source_file=partitioned_object_path,
            ingestion_timestamp=ingestion_timestamp,
        )
        for sample in samples
    ]

    output_format = infer_format_from_path(partitioned_object_path)
    payload, content_type = render_payload(samples=samples, output_format=output_format)

    upload_payload(
        bucket_name=settings.bucket_name,
        object_path=partitioned_object_path,
        payload=payload,
        content_type=content_type,
    )

    preview = [sample.to_dict() for sample in samples[:3]]
    return {
        "message": "Synthetic laboratory samples generated and uploaded successfully.",
        "bucket": settings.bucket_name,
        "object": partitioned_object_path,
        "format": output_format,
        "rows": len(samples),
        "preview": preview,
        "preview_rows": len(preview),
    }, 200


if __name__ == "__main__":
    os.environ.setdefault("BUCKET_NAME", "unused-local")
    os.environ.setdefault("OBJECT_PATH", "samples")
    os.environ.setdefault("SAMPLE_COUNT", "5")

    local_settings = load_settings()
    local_samples = generate_samples(
        sample_count=local_settings.sample_count, seed=local_settings.sample_seed
    )
    local_prefix = derive_base_prefix(local_settings.object_path)
    local_object = build_partitioned_object_path(
        base_prefix=local_prefix,
        sample_count=local_settings.sample_count,
        seed=local_settings.sample_seed,
    )
    local_ingestion_timestamp = datetime.now(UTC)
    local_samples = [
        replace(
            sample,
            source_file=local_object,
            ingestion_timestamp=local_ingestion_timestamp,
        )
        for sample in local_samples
    ]

    local_payload, _ = render_payload(
        samples=local_samples, output_format=infer_format_from_path(local_object)
    )
    local_output_path = os.getenv("LOCAL_OUTPUT_PATH", "synthetic_samples.ndjson")
    with open(local_output_path, "w", encoding="utf-8") as local_file:
        local_file.write(local_payload)

    print(f"Wrote {len(local_samples)} samples to {local_output_path}")
