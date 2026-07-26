from dataclasses import dataclass
from datetime import datetime
from typing import Literal


@dataclass(frozen=True)
class SampleRecord:
    sample_id: str
    batch_id: str
    sample_source: Literal["BLOOD", "TISSUE", "SALIVA"]
    analyte: Literal["DNA", "RNA"]
    operator_id: str
    collection_timestamp: datetime
    processing_timestamp: datetime
    cell_count: int
    viability_percent: float
    qubit_assay_type: Literal["DNA_HS", "DNA_BR", "RNA_HS", "RNA_BR"]
    qubit_concentration_ng_ul: float | None
    sample_volume_ul: float
    total_yield_ng: float | None
    rin_score: float | None
    storage_temperature: float
    qc_status: Literal["PASS", "FAIL"]
    qc_failure_reason: str | None
    source_file: str | None = None
    ingestion_timestamp: datetime | None = None

    def to_dict(self) -> dict:
        return {
            "sample_id": self.sample_id,
            "batch_id": self.batch_id,
            "sample_source": self.sample_source,
            "analyte": self.analyte,
            "operator_id": self.operator_id,
            "collection_timestamp": self.collection_timestamp.isoformat(),
            "processing_timestamp": self.processing_timestamp.isoformat(),
            "cell_count": self.cell_count,
            "viability_percent": self.viability_percent,
            "qubit_assay_type": self.qubit_assay_type,
            "qubit_concentration_ng_ul": self.qubit_concentration_ng_ul,
            "sample_volume_ul": self.sample_volume_ul,
            "total_yield_ng": self.total_yield_ng,
            "rin_score": self.rin_score,
            "storage_temperature": self.storage_temperature,
            "qc_status": self.qc_status,
            "qc_failure_reason": self.qc_failure_reason,
            "source_file": self.source_file,
            "ingestion_timestamp": (
                self.ingestion_timestamp.isoformat()
                if self.ingestion_timestamp is not None
                else None
            ),
        }
