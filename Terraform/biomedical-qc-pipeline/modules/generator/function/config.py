import hashlib
import os
from dataclasses import dataclass
from datetime import UTC, datetime


@dataclass(frozen=True)
class Settings:
    bucket_name: str
    object_path: str
    sample_count: int
    sample_seed: int | None


def _read_sample_count() -> int:
    raw_value = os.getenv("SAMPLE_COUNT", "100")
    try:
        sample_count = int(raw_value)
    except ValueError as exc:
        raise ValueError("SAMPLE_COUNT must be an integer") from exc

    if sample_count <= 0:
        raise ValueError("SAMPLE_COUNT must be greater than zero")

    return sample_count


def load_settings() -> Settings:
    bucket_name = os.environ["BUCKET_NAME"]
    object_path = os.environ["OBJECT_PATH"]
    sample_count = _read_sample_count()
    raw_seed = os.getenv("SAMPLE_SEED", "")
    sample_seed = int(raw_seed) if raw_seed else None

    return Settings(
        bucket_name=bucket_name,
        object_path=object_path,
        sample_count=sample_count,
        sample_seed=sample_seed,
    )


def derive_base_prefix(object_path: str) -> str:
    cleaned = object_path.strip("/")
    if not cleaned:
        return "samples"

    if cleaned.endswith((".json", ".jsonl", ".ndjson", ".csv")):
        if "/" in cleaned:
            return cleaned.rsplit("/", 1)[0]
        return ""

    return cleaned


def build_partitioned_object_path(
    base_prefix: str, sample_count: int, seed: int | None = None
) -> str:
    date_prefix = datetime.now(UTC).strftime("%Y%m%d")
    seed_part = "none" if seed is None else str(seed)
    digest = hashlib.sha1(
        f"{date_prefix}:{sample_count}:{seed_part}".encode()
    ).hexdigest()[:8]
    file_name = f"{date_prefix}_samples_{digest}.jsonl"

    if base_prefix:
        return f"{base_prefix.strip('/')}/{file_name}"
    return file_name
