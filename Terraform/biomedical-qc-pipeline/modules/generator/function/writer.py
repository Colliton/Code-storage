import json

from google.cloud import storage
from models import SampleRecord


def infer_format_from_path(object_path: str) -> str:
    normalized_path = object_path.lower()

    if normalized_path.endswith((".ndjson", ".jsonl")):
        return "ndjson"

    raise ValueError(f"Could not infer format from path: {object_path}")


def render_payload(samples: list[SampleRecord], output_format: str) -> tuple[str, str]:
    if output_format != "ndjson":
        raise ValueError(f"Unsupported output format: {output_format}")
    lines = [
        json.dumps(sample.to_dict(), ensure_ascii=False, separators=(",", ":"))
        for sample in samples
    ]

    return "\n".join(lines) + "\n", "application/x-ndjson"


def upload_payload(
    bucket_name: str,
    object_path: str,
    payload: str,
    content_type: str,
    storage_client: storage.Client | None = None,
) -> None:
    client = storage_client or storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(object_path)
    blob.upload_from_string(payload, content_type=content_type)
