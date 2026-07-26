import random
from datetime import UTC, datetime, timedelta
from typing import Literal

from models import SampleRecord

SAMPLE_SOURCES = ("BLOOD", "TISSUE", "SALIVA")
ANALYTES = ("DNA", "RNA")
OPERATOR_IDS = ("OP-001", "OP-002", "OP-003", "OP-004", "OP-005")
ASSAY_BY_ANALYTE = {
    "DNA": ("DNA_HS", "DNA_BR"),
    "RNA": ("RNA_HS", "RNA_BR"),
}

SOURCE_PROFILE = {
    "BLOOD": {
        "cell_count": (700_000, 2_000_000),
        "viability": (82.0, 99.5),
        "rin": (6.8, 10.0),
        "generated_temp": (2.0, 8.0),
        "accepted_storage_temp": (1.0, 10.0),
        "volume_ul": (40.0, 250.0),
        "max_processing_hours": 18.0,
        "analyte_weights": {"DNA": 0.6, "RNA": 0.4},
    },
    "TISSUE": {
        "cell_count": (300_000, 1_200_000),
        "viability": (60.0, 92.0),
        "rin": (4.2, 8.4),
        "generated_temp": (-90.0, -55.0),
        "accepted_storage_temp": (-90.0, -40.0),
        "volume_ul": (20.0, 120.0),
        "max_processing_hours": 6.0,
        "analyte_weights": {"DNA": 0.5, "RNA": 0.5},
    },
    "SALIVA": {
        "cell_count": (100_000, 600_000),
        "viability": (55.0, 90.0),
        "rin": (4.5, 8.8),
        "generated_temp": (2.0, 8.0),
        "accepted_storage_temp": (1.0, 10.0),
        "volume_ul": (25.0, 200.0),
        "max_processing_hours": 12.0,
        "analyte_weights": {"DNA": 0.75, "RNA": 0.25},
    },
}

ASSAY_PROFILE = {
    "DNA_HS": {
        "analyte": "DNA",
        "conc_range": (1.0, 100.0),
        "pass_concentration_min": 2.0,
        "pass_total_yield_min": 300.0,
    },
    "DNA_BR": {
        "analyte": "DNA",
        "conc_range": (20.0, 1000.0),
        "pass_concentration_min": 20.0,
        "pass_total_yield_min": 1000.0,
    },
    "RNA_HS": {
        "analyte": "RNA",
        "conc_range": (1.0, 100.0),
        "pass_concentration_min": 5.0,
        "pass_total_yield_min": 250.0,
        "pass_rin_min": 7.0,
    },
    "RNA_BR": {
        "analyte": "RNA",
        "conc_range": (20.0, 700.0),
        "pass_concentration_min": 20.0,
        "pass_total_yield_min": 900.0,
        "pass_rin_min": 7.0,
    },
}


class BatchGenerator:
    def __init__(self, rng: random.Random, now_utc: datetime) -> None:
        self._rng = rng
        self._now_utc = now_utc

    def generate_batch_id(self) -> str:
        return f"BATCH-{self._now_utc:%Y%m%dT%H%M%S}-{self._rng.randint(0, 9999):04d}"


class QCGenerator:
    def assess(
        self,
        *,
        sample_source: str,
        analyte: str,
        assay_type: str,
        processing_delay_hours: float,
        viability_percent: float,
        rin_score: float | None,
        storage_temperature: float,
        qubit_concentration_ng_ul: float | None,
        sample_volume_ul: float,
    ) -> tuple[Literal["PASS", "FAIL"], str | None]:
        failure_reasons: list[str] = []

        max_delay = SOURCE_PROFILE[sample_source]["max_processing_hours"]
        if processing_delay_hours > max_delay:
            failure_reasons.append("delayed_processing")

        if viability_percent < 70.0:
            failure_reasons.append("low_viability")

        assay = ASSAY_PROFILE[assay_type]
        if assay["analyte"] != analyte:
            failure_reasons.append("assay_analyte_mismatch")

        if qubit_concentration_ng_ul is None:
            failure_reasons.append("concentration not measured")
            total_yield_ng = None
        else:
            total_yield_ng = qubit_concentration_ng_ul * sample_volume_ul

        if (
            qubit_concentration_ng_ul is not None
            and qubit_concentration_ng_ul < assay["pass_concentration_min"]
        ):
            failure_reasons.append("low_concentration")

        if (
            total_yield_ng is not None
            and total_yield_ng < assay["pass_total_yield_min"]
        ):
            failure_reasons.append("low_yield")

        if analyte == "RNA":
            rin_min = assay["pass_rin_min"]
            if rin_score is None:
                failure_reasons.append("rin_not_measured")
            elif rin_score < rin_min:
                failure_reasons.append("low_rin")

        accepted_temp_min, accepted_temp_max = SOURCE_PROFILE[sample_source][
            "accepted_storage_temp"
        ]
        if not (accepted_temp_min <= storage_temperature <= accepted_temp_max):
            failure_reasons.append("storage_temperature_out_of_range")

        if failure_reasons:
            unique_reasons = sorted(set(failure_reasons))
            return "FAIL", "|".join(unique_reasons)

        return "PASS", None


class SampleGenerator:
    def __init__(
        self, rng: random.Random, now_utc: datetime, qc_generator: QCGenerator
    ) -> None:
        self._rng = rng
        self._now_utc = now_utc
        self._qc_generator = qc_generator

    def _sample_characteristics(self, sample_source: str) -> dict:
        rng = self._rng
        profile = SOURCE_PROFILE[sample_source]
        return {
            "cell_count": rng.randint(*profile["cell_count"]),
            "viability": round(rng.uniform(*profile["viability"]), 1),
            "rin": round(rng.uniform(*profile["rin"]), 1),
            "temperature": self._generate_storage_temperature(
                sample_source=sample_source
            ),
            "volume_ul": round(rng.uniform(*profile["volume_ul"]), 1),
            "max_processing_hours": profile["max_processing_hours"],
        }

    def _generate_storage_temperature(self, *, sample_source: str) -> float:
        profile = SOURCE_PROFILE[sample_source]
        generated_min, generated_max = profile["generated_temp"]
        accepted_min, accepted_max = profile["accepted_storage_temp"]

        if self._rng.random() < 0.05:
            delta = self._rng.uniform(1.0, 12.0)
            if self._rng.random() < 0.5:
                return round(accepted_min - delta, 1)
            return round(accepted_max + delta, 1)

        return round(self._rng.uniform(generated_min, generated_max), 1)

    def generate_sample(self, *, index: int, batch_id: str) -> SampleRecord:
        rng = self._rng
        sample_source = rng.choices(SAMPLE_SOURCES, weights=(0.45, 0.35, 0.2), k=1)[0]
        source_analyte_weights = SOURCE_PROFILE[sample_source]["analyte_weights"]
        analyte = rng.choices(
            ANALYTES,
            weights=(source_analyte_weights["DNA"], source_analyte_weights["RNA"]),
            k=1,
        )[0]
        profile = self._sample_characteristics(sample_source=sample_source)

        collection_time = self._now_utc - timedelta(hours=rng.uniform(2.0, 36.0))
        processing_delay_hours = rng.uniform(0.5, profile["max_processing_hours"] * 1.6)
        processing_time = min(
            collection_time + timedelta(hours=processing_delay_hours), self._now_utc
        )
        actual_processing_delay_hours = (
            processing_time - collection_time
        ).total_seconds() / 3600.0

        qubit_assay = rng.choice(ASSAY_BY_ANALYTE[analyte])
        assay_profile = ASSAY_PROFILE[qubit_assay]
        measured = rng.random() > 0.03
        concentration = (
            round(
                rng.uniform(
                    assay_profile["conc_range"][0], assay_profile["conc_range"][1]
                ),
                1,
            )
            if measured
            else None
        )
        sample_volume_ul = profile["volume_ul"]
        total_yield_ng = (
            None
            if concentration is None
            else round(concentration * sample_volume_ul, 1)
        )

        rin_score = profile["rin"] if analyte == "RNA" else None
        if rng.random() < 0.04 and analyte == "RNA":
            rin_score = None

        qc_status, qc_failure_reason = self._qc_generator.assess(
            sample_source=sample_source,
            analyte=analyte,
            assay_type=qubit_assay,
            processing_delay_hours=actual_processing_delay_hours,
            viability_percent=profile["viability"],
            rin_score=rin_score,
            storage_temperature=profile["temperature"],
            qubit_concentration_ng_ul=concentration,
            sample_volume_ul=sample_volume_ul,
        )

        return SampleRecord(
            sample_id=f"{batch_id}-SMP-{index:04d}",
            batch_id=batch_id,
            sample_source=sample_source,
            analyte=analyte,
            collection_timestamp=collection_time,
            processing_timestamp=processing_time,
            operator_id=rng.choice(OPERATOR_IDS),
            cell_count=profile["cell_count"],
            viability_percent=profile["viability"],
            qubit_assay_type=qubit_assay,
            qubit_concentration_ng_ul=concentration,
            sample_volume_ul=sample_volume_ul,
            total_yield_ng=total_yield_ng,
            rin_score=rin_score,
            storage_temperature=profile["temperature"],
            qc_status=qc_status,
            qc_failure_reason=qc_failure_reason,
        )


def generate_samples(
    sample_count: int, seed: int | None = None, now_utc: datetime | None = None
) -> list[SampleRecord]:
    rng = random.Random(seed)
    current_time = now_utc or datetime.now(UTC)

    batch_generator = BatchGenerator(rng=rng, now_utc=current_time)
    qc_generator = QCGenerator()
    sample_generator = SampleGenerator(
        rng=rng, now_utc=current_time, qc_generator=qc_generator
    )

    batch_id = batch_generator.generate_batch_id()
    return [
        sample_generator.generate_sample(index=i, batch_id=batch_id)
        for i in range(1, sample_count + 1)
    ]
