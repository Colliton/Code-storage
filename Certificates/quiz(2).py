"""
Quiz Tester – Google Professional Data Engineer
================================================
Funkcje:
  • Poprzednie / Następne / Skocz do numeru
  • Zaznaczanie odpowiedzi (single / multiple)
  • Sprawdzenie odpowiedzi z podświetleniem
  • Notatki do każdego pytania (auto-zapis)
  • Oznaczanie pytań jako „błędne"
  • Tryb „tylko błędne pytania"
  • Pasek postępu i statystyki sesji
  • Pełen zapis stanu (progress.json)
"""

import json
import random
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, simpledialog, ttk

# ─── ŚCIEŻKI ─────────────────────────────────────────────────────────────────
BASE_DIR       = Path(__file__).parent
QUESTIONS_FILE = BASE_DIR / "questions.json"
PROGRESS_FILE  = BASE_DIR / "progress.json"
WRONG_FILE     = BASE_DIR / "wrong_questions.json"
SESSION_FILE   = BASE_DIR / "quiz_session.json"

SCRAPED_DEFAULTS = [
    BASE_DIR / "examtopics_ace_saved_links_full.json",
    BASE_DIR / "examtopics_pde_last20.json",
    BASE_DIR / "examtopics_pde_saved_links_full.json",
    BASE_DIR / "examtopics_adp_1_103_full.json",
]

# ─── KOLORY ──────────────────────────────────────────────────────────────────
THEMES = {
    "light": {
        "BG": "#fffacc", "BG2": "#ffffff", "BG3": "#edafb8",
        "ACCENT": "#70a0af", "PROGRESS_START": "#4f91a4",
        "PROGRESS_END": "#c75c81",
        "GREEN": "#2e7d32", "RED": "#c62828",
        "YELLOW": "#7a6174", "TEXT": "#111111", "TEXT_DIM": "#7a6174",
        "WHITE": "#ffffff", "ANSWER_GREEN_BG": "#ddf2e1",
        "ANSWER_RED_BG": "#fde2e7", "ACTIVE": "#d8c6d2",
        "POKEMON_BG": "#ffffff",
    },
    "dark": {
        "BG": "#1f2228", "BG2": "#2d3138", "BG3": "#464b55",
        "ACCENT": "#ffd21c", "PROGRESS_START": "#ffd21c",
        "PROGRESS_END": "#a6e3a1",
        "GREEN": "#a6e3a1", "RED": "#f38ba8",
        "YELLOW": "#ffe36e", "TEXT": "#f7f8fa", "TEXT_DIM": "#b9c0ca",
        "WHITE": "#ffffff", "ANSWER_GREEN_BG": "#28513d",
        "ANSWER_RED_BG": "#5a3041", "ACTIVE": "#626873",
        "POKEMON_BG": "#2d3138",
    },
}

BG = BG2 = BG3 = ACCENT = PROGRESS_START = PROGRESS_END = ""
GREEN = RED = YELLOW = TEXT = TEXT_DIM = WHITE = ""
ANSWER_GREEN_BG = ANSWER_RED_BG = ACTIVE = POKEMON_BG = ""


def _set_palette(name: str):
    globals().update(THEMES[name])


_set_palette("light")

# Rozmiar czcionki – zmieniany dynamicznie
BASE_SIZE = 11

def _fonts(size: int):
    return {
        "main":  ("Trebuchet MS", size),
        "bold":  ("Trebuchet MS", size, "bold"),
        "large": ("Trebuchet MS", size + 3, "bold"),
        "small": ("Trebuchet MS", max(8, size - 2)),
        "mono":  ("Consolas", size - 1),
    }

FONT_MAIN   = ("Trebuchet MS", BASE_SIZE)
FONT_BOLD   = ("Trebuchet MS", BASE_SIZE, "bold")
FONT_LARGE  = ("Trebuchet MS", BASE_SIZE + 3, "bold")
FONT_SMALL  = ("Trebuchet MS", max(8, BASE_SIZE - 2))
FONT_MONO   = ("Consolas", BASE_SIZE - 1)


def _detect_questions_file() -> Path:
    if QUESTIONS_FILE.exists():
        return QUESTIONS_FILE
    for candidate in SCRAPED_DEFAULTS:
        if candidate.exists():
            return candidate
    json_files = sorted(BASE_DIR.glob("examtopics_*.json"))
    if json_files:
        return json_files[0]
    return QUESTIONS_FILE


def _letters_from_raw(raw_answer: str | None) -> list[str]:
    if not raw_answer:
        return []
    cleaned = str(raw_answer).upper()
    letters = []
    for char in cleaned:
        if "A" <= char <= "H" and char not in letters:
            letters.append(char)
    return letters


def _normalize_selected_answers(values: list[str] | None) -> list[str]:
    if not values:
        return []
    result: list[str] = []
    for value in values:
        letter = str(value).strip().upper()
        if "A" <= letter <= "H" and letter not in result:
            result.append(letter)
    return result


def _discussion_entry_text(item: dict | str) -> str:
    text = item.strip() if isinstance(item, str) else str(item.get("text", "")).strip()
    if not text:
        return ""
    if isinstance(item, str):
        return text
    selected_answers = _normalize_selected_answers(item.get("selected_answers"))
    selected_label = ",".join(selected_answers) if selected_answers else "-"
    return f"[SA: {selected_label}] {text}"


def _normalize_discussion_item(item: dict | str) -> dict | None:
    text = item.strip() if isinstance(item, str) else str(item.get("text", "")).strip()
    if not text:
        return None
    if isinstance(item, str):
        return {
            "author": None,
            "date": None,
            "upvotes": None,
            "selected_answers": [],
            "text": text,
        }
    return {
        "author": str(item.get("author") or "").strip() or None,
        "date": str(item.get("date") or "").strip() or None,
        "upvotes": str(item.get("upvotes") or "").strip() or None,
        "selected_answers": _normalize_selected_answers(item.get("selected_answers")),
        "text": text,
    }


def _format_discussion_entries(entries: list[dict]) -> str:
    lines: list[str] = []
    for idx, entry in enumerate(entries, start=1):
        meta_parts: list[str] = []
        if entry.get("author"):
            meta_parts.append(entry["author"])
        if entry.get("date"):
            meta_parts.append(entry["date"])
        if entry.get("upvotes"):
            meta_parts.append(f"👍 {entry['upvotes']}")
        selected_answers = entry.get("selected_answers") or []
        selected_label = ",".join(selected_answers) if selected_answers else "-"
        header = f"[{idx}] " + (" | ".join(meta_parts) if meta_parts else "")
        header = header.rstrip() + f" | SA: {selected_label}"
        lines.append(header)
        lines.append(entry.get("text", ""))
        lines.append("")
    return "\n".join(lines).strip()


def _normalize_question(row: dict, fallback_index: int) -> dict:
    if "id" in row and "question" in row and "correct" in row:
        normalized = dict(row)
        if "type" not in normalized:
            normalized["type"] = "multiple" if len(normalized.get("correct", [])) > 1 else "single"
        normalized["correct"] = [str(x).upper() for x in normalized.get("correct", [])]
        normalized.setdefault("question_added_date", row.get("question_added_date"))
        existing_answer = normalized.get("answer")
        if not isinstance(existing_answer, dict):
            selected = normalized.get("correct", [])
            raw = ",".join(selected) if len(selected) > 1 else (selected[0] if selected else None)
            normalized["answer"] = {
                "most_voted": selected[0] if selected else None,
                "selected_answers": selected,
                "raw": raw,
                "percentages": {},
            }
        else:
            existing_answer.setdefault("percentages", {})
        if not isinstance(normalized.get("discussion"), list):
            normalized["discussion"] = []
        else:
            normalized["discussion"] = [
                d for d in (_normalize_discussion_item(item) for item in normalized.get("discussion", [])) if d
            ]
        return normalized

    qnum = row.get("question_number", fallback_index + 1)
    answer = row.get("answer") or {}
    selected = [str(x).upper() for x in answer.get("selected_answers", []) if x]
    most_voted = _letters_from_raw(answer.get("most_voted"))
    raw = _letters_from_raw(answer.get("raw"))

    correct = selected or raw or most_voted
    correct = [x for x in correct if "A" <= x <= "H"]

    discussion_items = row.get("discussion") or []
    discussion = [d for d in (_normalize_discussion_item(item) for item in discussion_items) if d]
    explanation_parts = [_discussion_entry_text(item) for item in discussion_items]
    explanation_parts = [part for part in explanation_parts if part]
    explanation = "\n\n".join(explanation_parts[:3]).strip()

    return {
        "id": str(qnum),
        "query": row.get("query"),
        "question_title": row.get("question_title"),
        "question": row.get("question_text") or row.get("question_title") or f"Question {qnum}",
        "options": row.get("options") or [],
        "correct": correct,
        "type": "multiple" if len(correct) > 1 else "single",
        "answer": {
            "most_voted": answer.get("most_voted"),
            "selected_answers": selected,
            "raw": answer.get("raw"),
            "percentages": answer.get("percentages") if isinstance(answer.get("percentages"), dict) else {},
        },
        "discussion": discussion,
        "explanation": explanation,
        "question_added_date": row.get("question_added_date"),
        "question_source": row.get("question_source"),
        "official_sample_index": row.get("official_sample_index"),
        "official_sample_total": row.get("official_sample_total"),
    }


def _load_questions() -> list[dict]:
    source_file = _detect_questions_file()
    if not source_file.exists():
        raise FileNotFoundError(
            "Nie znaleziono pliku z pytaniami. Oczekiwano np. questions.json lub examtopics_*.json"
        )

    data = json.loads(source_file.read_text("utf-8"))
    rows: list[dict]
    if isinstance(data, dict) and isinstance(data.get("questions"), list):
        rows = data["questions"]
    elif isinstance(data, list):
        rows = data
    else:
        raise ValueError(
            f"Nieobsługiwany format pliku {source_file.name}. Oczekiwano listy pytań lub obiektu z polem 'questions'."
        )

    normalized = [_normalize_question(row, i) for i, row in enumerate(rows)]
    normalized = [q for q in normalized if q.get("options")]
    if not normalized:
        raise ValueError(
            f"Nie udało się wczytać żadnych poprawnych pytań z pliku {source_file.name}."
        )
    return normalized


# ─── LOGIKA APLIKACJI ─────────────────────────────────────────────────────────
class QuizApp:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("🌸 GCP Quiz Tester 🌸")
        self.root.configure(bg=BG)
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        window_width = min(1600, max(1000, int(screen_width * 0.88)))
        window_height = min(1050, max(700, int(screen_height * 0.86)))
        left = max(0, (screen_width - window_width) // 2)
        top = max(0, (screen_height - window_height) // 2)
        self.root.geometry(f"{window_width}x{window_height}+{left}+{top}")
        self.root.minsize(800, 600)

        self.all_questions: list[dict] = _load_questions()
        self.progress: dict = self._load_progress()
        self.saved_session: dict = self._load_session()
        self.completed_question_ids: set[str] = set()
        self._progress_ratio = 0.0

        # Rozmiar czcionki
        self.font_size = max(BASE_SIZE, min(18, round(window_width / 110)))

        # Tryb: "all" lub "wrong"
        self.mode = "all"
        self.shuffle = False
        self.queue: list[int] = []   # indeksy do all_questions
        self.pos   = 0               # pozycja w queue

        # Stan bieżącego pytania
        self.answer_vars: list[tk.IntVar] = []
        self.checked = False
        self.more_panel = None
        self.more_hide_job = None
        self.explanation_visible = True
        self.theme_name = "light"

        self._build_ui()
        self._restore_session()

    # ── PERSIST ──────────────────────────────────────────────────────────────
    def _load_progress(self) -> dict:
        if PROGRESS_FILE.exists():
            try:
                return json.loads(PROGRESS_FILE.read_text("utf-8"))
            except Exception:
                pass
        return {}

    def _save_progress(self):
        PROGRESS_FILE.write_text(
            json.dumps(self.progress, ensure_ascii=False, indent=2), "utf-8"
        )
        self._export_wrong()

    def _load_session(self) -> dict:
        if not SESSION_FILE.exists():
            return {}
        try:
            session = json.loads(SESSION_FILE.read_text("utf-8"))
        except json.JSONDecodeError as error:
            messagebox.showwarning(
                "Nie udało się odczytać sesji",
                f"Plik zapisu sesji jest nieprawidłowy:\n{error}",
                parent=self.root,
            )
            return {}
        if not isinstance(session, dict):
            messagebox.showwarning(
                "Nie udało się odczytać sesji",
                "Plik zapisu sesji ma nieprawidłowy format. Rozpoczynam nową sesję.",
                parent=self.root,
            )
            return {}
        return session

    def _save_session(self):
        if not self.queue:
            return
        current_question_id = (
            self._current_q()["id"] if 0 <= self.pos < len(self.queue) else None
        )
        session = {
            "version": 1,
            "mode": self.mode,
            "shuffle": self.shuffle,
            "queue": [self.all_questions[index]["id"] for index in self.queue],
            "current_question_id": current_question_id,
            "completed_question_ids": [
                q["id"] for q in self.all_questions
                if q["id"] in self.completed_question_ids
            ],
        }
        temporary_file = SESSION_FILE.with_name(f"{SESSION_FILE.name}.tmp")
        temporary_file.write_text(
            json.dumps(session, ensure_ascii=False, indent=2), "utf-8"
        )
        temporary_file.replace(SESSION_FILE)

    def _restore_session(self):
        valid_ids = {q["id"] for q in self.all_questions}
        saved_completed = self.saved_session.get("completed_question_ids", [])
        if isinstance(saved_completed, list):
            self.completed_question_ids = {
                str(qid) for qid in saved_completed if str(qid) in valid_ids
            }
        elif "completed_question_ids" in self.saved_session:
            messagebox.showwarning(
                "Niepełny zapis sesji",
                "Nie udało się odczytać listy zrobionych pytań. "
                "Postęp sesji rozpocznie się od zera.",
                parent=self.root,
            )

        mode = self.saved_session.get("mode")
        saved_queue = self.saved_session.get("queue")
        if (
            not isinstance(mode, str)
            or mode not in {"all", "wrong"}
            or not isinstance(saved_queue, list)
        ):
            if self.saved_session:
                messagebox.showwarning(
                    "Niepełny zapis sesji",
                    "Nie udało się odtworzyć kolejki pytań. "
                    "Sesja rozpocznie się od początku.",
                    parent=self.root,
                )
            self._start_mode("all")
            return

        question_indices = {q["id"]: i for i, q in enumerate(self.all_questions)}
        shuffle = self.saved_session.get("shuffle")
        if not isinstance(shuffle, bool):
            saved_indices = [
                question_indices[str(saved_id)]
                for saved_id in saved_queue
                if str(saved_id) in question_indices
            ]
            descents = sum(
                1 for previous, current in zip(saved_indices, saved_indices[1:])
                if current < previous
            )
            shuffle = descents > max(1, len(saved_indices) // 100)

        queue: list[int] = []
        seen_ids: set[str] = set()
        for saved_id in saved_queue:
            qid = str(saved_id)
            index = question_indices.get(qid)
            if index is None or qid in seen_ids:
                continue
            if mode == "wrong" and not self._get_state(qid).get("wrong"):
                continue
            queue.append(index)
            seen_ids.add(qid)

        if mode == "all":
            if shuffle:
                queue.extend(
                    i for i, q in enumerate(self.all_questions)
                    if q["id"] not in seen_ids
                )
                sample_queue = [
                    i for i in queue
                    if self._is_official_sample(self.all_questions[i])
                ]
                queue = [
                    i for i in queue
                    if not self._is_official_sample(self.all_questions[i])
                ]
                queue.extend(sample_queue)
            else:
                queue = list(range(len(self.all_questions)))
        else:
            queue.extend(
                i for i, q in enumerate(self.all_questions)
                if q["id"] not in seen_ids and self._get_state(q["id"]).get("wrong")
            )

        if not queue:
            self._start_mode("all")
            return

        self.mode = mode
        self.shuffle = shuffle if mode == "all" else False
        self.queue = queue
        current_id = str(self.saved_session.get("current_question_id", ""))
        self.pos = next(
            (i for i, index in enumerate(queue)
             if self.all_questions[index]["id"] == current_id),
            0,
        )
        self._load_question()

    def _render_flags(self, q: dict, st: dict):
        has_wrong = st.get("wrong", False)
        has_completed = q["id"] in self.completed_question_ids
        has_note  = bool(st.get("note", "").strip())
        added_date = q.get("question_added_date")
        has_answer_key = bool(q.get("correct"))

        parts: list[str] = []
        if has_wrong:
            parts.append("❌ błędne")
        if has_completed:
            parts.append("✅ zrobione")
        if has_note:
            parts.append("📝 notatka")
        if not has_answer_key:
            parts.append("⚠️ brak klucza")
        if added_date:
            parts.append(f"📅 dodane: {added_date}")

        self.lbl_flags.config(
            text="  ".join(parts),
            fg=RED if has_wrong else GREEN if has_completed else TEXT_DIM,
        )

    def _build_explanation_text(self, q: dict) -> str:
        sections: list[str] = []

        answer = q.get("answer") if isinstance(q.get("answer"), dict) else {}
        most_voted = answer.get("most_voted") if answer else None
        raw = answer.get("raw") if answer else None
        percentages = answer.get("percentages") if answer else {}

        answer_lines: list[str] = []
        if most_voted:
            answer_lines.append(f"Most voted: {most_voted}")
        if raw and raw != most_voted:
            answer_lines.append(f"Raw: {raw}")
        if isinstance(percentages, dict) and percentages:
            ordered = sorted(percentages.items(), key=lambda item: item[0])
            answer_lines.append("Rozkład: " + ", ".join(f"{letter} {percent}%" for letter, percent in ordered))
        if answer_lines:
            sections.append("Odpowiedź społeczności\n" + "\n".join(answer_lines))

        discussion = q.get("discussion") if isinstance(q.get("discussion"), list) else []
        if discussion:
            sections.append("Dyskusja\n" + _format_discussion_entries(discussion))
        else:
            explanation = (q.get("explanation") or "").strip()
            if explanation:
                sections.append("Wyjaśnienie\n" + explanation)

        return "\n\n".join(part for part in sections if part).strip()

    def _get_state(self, qid: str) -> dict:
        return self.progress.setdefault(qid, {"wrong": False, "note": ""})

    # ── TRYB ─────────────────────────────────────────────────────────────────
    def _start_mode(self, mode: str, shuffle: bool = False):
        self.mode = mode
        self.shuffle = shuffle if mode == "all" else False
        if mode == "wrong":
            self.queue = [
                i for i, q in enumerate(self.all_questions)
                if self._get_state(q["id"]).get("wrong")
            ]
            if not self.queue:
                messagebox.showinfo("Brak błędnych pytań",
                                    "Nie masz jeszcze żadnych oznaczonych błędnych pytań.")
                return
        else:
            self.queue = list(range(len(self.all_questions)))

        if shuffle:
            sample_queue = [
                index for index in self.queue
                if self._is_official_sample(self.all_questions[index])
            ]
            self.queue = [
                index for index in self.queue
                if not self._is_official_sample(self.all_questions[index])
            ]
            random.shuffle(self.queue)
            self.queue.extend(sample_queue)

        self.pos = 0
        self._load_question()

    # ── NAWIGACJA ────────────────────────────────────────────────────────────
    def _current_idx(self) -> int:
        return self.queue[self.pos]

    def _draw_progress_bar(self, _event=None):
        if _event is None:
            width = self.progress_bar.winfo_width()
            height = self.progress_bar.winfo_height()
        else:
            width = _event.width
            height = _event.height
        if width <= 1 or height <= 1:
            return

        self.progress_bar.delete("all")
        self.progress_bar.create_rectangle(
            0, 0, width, height, fill=BG3, outline=""
        )
        fill_width = int(width * self._progress_ratio)
        if fill_width <= 0:
            return

        start = tuple(int(PROGRESS_START[i:i + 2], 16) for i in (1, 3, 5))
        end = tuple(int(PROGRESS_END[i:i + 2], 16) for i in (1, 3, 5))
        steps = min(fill_width, 256)
        for step in range(steps):
            ratio = step / max(steps - 1, 1)
            color = "#" + "".join(
                f"{round(first + (last - first) * ratio):02x}"
                for first, last in zip(start, end)
            )
            x0 = step * fill_width / steps
            x1 = (step + 1) * fill_width / steps
            self.progress_bar.create_rectangle(
                x0, 0, x1, height, fill=color, outline=""
            )

    def _update_progress_bar(self):
        real_total = self._real_question_count()
        completed = sum(
            1 for index in self.queue
            if self._is_main_question(self.all_questions[index])
            and self.all_questions[index]["id"] in self.completed_question_ids
        )
        self._progress_ratio = completed / real_total if real_total else 0.0
        self._draw_progress_bar()

    def _current_q(self) -> dict:
        return self.all_questions[self._current_idx()]

    @staticmethod
    def _is_checkpoint(q: dict) -> bool:
        return q.get("query") == "motivational-insert"

    @staticmethod
    def _is_official_sample(q: dict) -> bool:
        return q.get("question_source") == "Google Official Sample"

    def _is_main_question(self, q: dict) -> bool:
        return not self._is_checkpoint(q) and not self._is_official_sample(q)

    def _real_question_count(self) -> int:
        return sum(
            1 for index in self.queue
            if self._is_main_question(self.all_questions[index])
        )

    def _real_question_position(self) -> int:
        return sum(
            1 for index in self.queue[: self.pos + 1]
            if self._is_main_question(self.all_questions[index])
        )

    def _queue_position_for_question_number(self, question_number: int) -> int | None:
        if question_number < 1:
            return None
        real_question_number = 0
        for position, index in enumerate(self.queue):
            if not self._is_main_question(self.all_questions[index]):
                continue
            real_question_number += 1
            if real_question_number == question_number:
                return position
        return None

    def _go_to_pos(self, pos: int):
        if 0 <= pos < len(self.queue):
            self.pos = pos
            self._load_question()

    def _prev(self):
        self._go_to_pos(self.pos - 1)

    def _next(self):
        self._go_to_pos(self.pos + 1)

    def _jump(self):
        real_total = self._real_question_count()
        if not real_total:
            return
        val = simpledialog.askinteger(
            "Przejdź do pytania",
            f"Podaj numer pytania w bieżącej kolejności (1 – {real_total}):",
            minvalue=1, maxvalue=real_total,
            parent=self.root,
        )
        if val is not None:
            queue_position = self._queue_position_for_question_number(val)
            if queue_position is not None:
                self._go_to_pos(queue_position)

    # ── WCZYTANIE PYTANIA ────────────────────────────────────────────────────
    def _load_question(self):
        self.checked = False
        q    = self._current_q()
        qid  = q["id"]
        st   = self._get_state(qid)
        opts = q.get("options", [])
        fonts = _fonts(self.font_size)

        # Nagłówek / postęp
        total = len(self.queue)
        real_total = self._real_question_count()
        real_position = self._real_question_position()
        mode_prefix = "❌ TRYB: BŁĘDNE  " if self.mode == "wrong" else ""
        if self._is_checkpoint(q):
            title = str(q.get("question_title") or "Checkpoint")
            if "META" in title.upper():
                progress_text = f"{mode_prefix}Koniec • {real_total} pytań"
            else:
                progress_text = f"{mode_prefix}Checkpoint • po {real_position} pytaniach"
        elif self._is_official_sample(q):
            sample_position = q.get("official_sample_index", 1)
            sample_total = q.get("official_sample_total", 20)
            progress_text = (
                f"{mode_prefix}OFFICIAL GOOGLE SAMPLE • "
                f"{sample_position} / {sample_total}"
            )
        else:
            progress_text = f"{mode_prefix}Pytanie {real_position} / {real_total}"
        self.lbl_progress.config(text=progress_text)

        # Wskaźniki wykonania/błędne/notatka/data
        self._render_flags(q, st)

        # Treść pytania
        self.txt_question.config(state="normal")
        self.txt_question.delete("1.0", "end")
        self.txt_question.insert("1.0", q["question"])
        self.txt_question.config(state="disabled")
        self._update_question_image(q)

        # Opcje
        for w in self.options_frame.winfo_children():
            w.destroy()
        self.answer_vars = []

        multi = q.get("type", "single") == "multiple"
        for i, opt in enumerate(opts):
            var = tk.IntVar(value=0)
            self.answer_vars.append(var)
            letter = "ABCDEFGH"[i]
            cb = tk.Checkbutton(
                self.options_frame,
                text=f"  {letter})  {opt}",
                variable=var,
                anchor="w",
                justify="left",
                wraplength=max(600, self.root.winfo_width() - 140),
                bg=BG2, fg=TEXT,
                selectcolor=BG3,
                activebackground=BG2,
                activeforeground=WHITE,
                font=fonts["main"],
                cursor="hand2",
                pady=max(4, self.font_size // 2),
            )
            cb.pack(fill="x", padx=8, pady=2)

        # Wyjaśnienie – ukryj
        self.txt_expl.config(state="normal")
        self.txt_expl.delete("1.0", "end")
        self.txt_expl.insert("1.0", "Wyjaśnienie pojawi się po kliknięciu: ✔ Sprawdź")
        self.txt_expl.config(state="disabled")

        # Notatka
        self.txt_note.config(state="normal")
        self.txt_note.delete("1.0", "end")
        self.txt_note.insert("1.0", st.get("note", ""))

        # Pasek postępu
        self._update_progress_bar()

        # Przyciski nav
        self.btn_prev.config(state="normal" if self.pos > 0 else "disabled")
        self.btn_next.config(state="normal" if self.pos < total - 1 else "disabled")

        # Statystyki
        self._update_stats()
        self._apply_font_size()
        self._save_session()

    # ── SPRAWDZANIE ──────────────────────────────────────────────────────────
    def _check(self):
        if self.checked:
            return
        self.checked = True
        q       = self._current_q()
        correct = set(q.get("correct", []))
        letters = "ABCDEFGH"
        has_answer_key = bool(correct)

        selected = {
            letters[i]
            for i, v in enumerate(self.answer_vars)
            if v.get()
        }

        is_correct = selected == correct if has_answer_key else None

        # Pokoloruj opcje
        if has_answer_key:
            for i, cb in enumerate(self.options_frame.winfo_children()):
                letter = letters[i]
                if letter in correct and letter in selected:
                    cb.config(bg=ANSWER_GREEN_BG, fg=GREEN)
                elif letter in correct:
                    cb.config(bg=ANSWER_GREEN_BG, fg=GREEN)
                elif letter in selected:
                    cb.config(bg=ANSWER_RED_BG, fg=RED)

        # Pokaż wyjaśnienie
        expl = self._build_explanation_text(q)
        if not has_answer_key:
            expl = (
                "Brak klucza odpowiedzi dla tego pytania — wynik nie jest oceniany.\n\n"
                + (expl or "")
            ).strip()
        self.txt_expl.config(state="normal")
        self.txt_expl.delete("1.0", "end")
        self.txt_expl.insert("1.0", expl or "Brak wyjaśnienia dla tego pytania.")
        self.txt_expl.config(state="disabled")

        if not self._is_checkpoint(q):
            self.completed_question_ids.add(q["id"])
            if has_answer_key and not is_correct:
                self._get_state(q["id"])["wrong"] = True
            self._render_flags(q, self._get_state(q["id"]))
            self._update_stats()
            self._update_progress_bar()
            self._save_session()
            if has_answer_key and not is_correct:
                self._save_progress()

    # ── OZNACZANIE BŁĘDÓW ────────────────────────────────────────────────────
    def _toggle_wrong(self):
        q  = self._current_q()
        st = self._get_state(q["id"])
        st["wrong"] = not st.get("wrong", False)
        self._save_progress()
        self._export_wrong()
        self._load_question()

    def _reset_wrong_questions(self):
        wrong_count = sum(
            1 for q in self.all_questions if self._get_state(q["id"]).get("wrong")
        )
        if not wrong_count:
            messagebox.showinfo("Błędne pytania", "Licznik błędnych pytań już wynosi 0.", parent=self.root)
            return
        confirmed = messagebox.askyesno(
            "Wyzeruj błędne pytania",
            f"Wyzerować licznik błędnych odpowiedzi ({wrong_count})?\n\n"
            "Notatki zostaną zachowane.",
            parent=self.root,
        )
        if not confirmed:
            return
        for q in self.all_questions:
            self._get_state(q["id"])["wrong"] = False
        self._save_progress()
        self._export_wrong()
        if self.mode == "wrong":
            self._start_mode("all")
        else:
            self._load_question()

    def _export_wrong(self):
        wrong = [
            self.all_questions[i]
            for i, q in enumerate(self.all_questions)
            if self._get_state(q["id"]).get("wrong")
        ]
        WRONG_FILE.write_text(
            json.dumps(wrong, ensure_ascii=False, indent=2), "utf-8"
        )

    # ── NOTATKI ──────────────────────────────────────────────────────────────
    def _save_note(self):
        q  = self._current_q()
        st = self._get_state(q["id"])
        st["note"] = self.txt_note.get("1.0", "end").strip()
        self._save_progress()
        self._load_question()

    def _show_note_popup(self):
        q    = self._current_q()
        note = self._get_state(q["id"]).get("note", "").strip()
        if not note:
            messagebox.showinfo("Notatka", "Brak notatki dla tego pytania.", parent=self.root)
        else:
            win = tk.Toplevel(self.root)
            win.title(f"Notatka – pytanie {self.pos + 1}")
            win.configure(bg=BG)
            win.geometry("600x300")
            txt = tk.Text(win, bg=BG2, fg=TEXT, font=FONT_MAIN,
                          wrap="word", relief="flat", padx=10, pady=10)
            txt.pack(fill="both", expand=True, padx=10, pady=10)
            txt.insert("1.0", note)
            txt.config(state="disabled")

    def _copy_question(self):
        q = self._current_q()
        lines = [
            "Wyjaśnij poniższe pytanie egzaminacyjne Google Cloud: która odpowiedź "
            "jest poprawna i dlaczego, oraz dlaczego pozostałe są błędne?",
            "",
            q["question"],
            "",
        ]
        for i, opt in enumerate(q.get("options", [])):
            text = str(opt).strip()
            if not (len(text) >= 2 and text[0] in "ABCDEFGH" and text[1] in ".)"):
                text = f"{'ABCDEFGH'[i]}. {text}"
            lines.append(text)
        self.root.clipboard_clear()
        self.root.clipboard_append("\n".join(lines))

        self.btn_copy.config(text="✓ Skopiowano")
        self.root.after(1200, lambda: self.btn_copy.config(text="📋 Kopiuj"))

    def _toggle_note_panel(self):
        if self.note_frame.winfo_ismapped():
            self._save_note()
            self.note_frame.grid_remove()
            return
        q = self._current_q()
        st = self._get_state(q["id"])
        self.txt_note.config(state="normal")
        self.txt_note.delete("1.0", "end")
        self.txt_note.insert("1.0", st.get("note", ""))
        self.note_frame.grid()

    def _close_more_panel(self):
        if self.more_hide_job:
            self.root.after_cancel(self.more_hide_job)
            self.more_hide_job = None
        if self.more_panel is not None and self.more_panel.winfo_exists():
            self.more_panel.destroy()
        self.more_panel = None

    def _schedule_close_more_panel(self):
        if self.more_hide_job:
            self.root.after_cancel(self.more_hide_job)
        self.more_hide_job = self.root.after(180, self._close_more_panel)

    def _cancel_close_more_panel(self, _event=None):
        if self.more_hide_job:
            self.root.after_cancel(self.more_hide_job)
            self.more_hide_job = None

    def _open_more_panel(self):
        if self.more_panel is not None and self.more_panel.winfo_exists():
            self._close_more_panel()
            return

        panel = tk.Toplevel(self.root)
        panel.overrideredirect(True)
        panel.configure(bg=BG3)
        panel.attributes("-topmost", True)

        frame = tk.Frame(panel, bg=BG2, bd=1, relief="solid")
        frame.pack(fill="both", expand=True)

        def add_item(text, cmd):
            b = tk.Button(
                frame,
                text=text,
                command=lambda: (cmd(), self._close_more_panel()),
                anchor="w",
                bg=BG2,
                fg=TEXT,
                font=_fonts(self.font_size)["main"],
                relief="flat",
                cursor="hand2",
                padx=10,
                pady=6,
                activebackground=BG3,
                activeforeground=WHITE,
            )
            b.pack(fill="x", padx=2, pady=1)

        add_item("Skocz do #", self._jump)
        add_item("Przełącz błędne", self._toggle_wrong)
        add_item("Wyzeruj błędne", self._reset_wrong_questions)

        sep1 = tk.Frame(frame, bg=BG3, height=1)
        sep1.pack(fill="x", padx=4, pady=4)

        add_item("Losowo", lambda: self._start_mode("all", shuffle=True))
        add_item("Wszystkie", lambda: self._start_mode("all"))
        add_item("Tylko błędne", lambda: self._start_mode("wrong"))

        sep2 = tk.Frame(frame, bg=BG3, height=1)
        sep2.pack(fill="x", padx=4, pady=4)

        add_item("Pokaż notatkę (popup)", self._show_note_popup)

        self.root.update_idletasks()
        panel.update_idletasks()

        panel_w = max(250, panel.winfo_reqwidth())
        panel_h = panel.winfo_reqheight()

        btn_x = self.more_button.winfo_rootx()
        btn_y = self.more_button.winfo_rooty()

        screen_x = self.root.winfo_vrootx()
        screen_y = self.root.winfo_vrooty()
        screen_w = self.root.winfo_vrootwidth()
        screen_h = self.root.winfo_vrootheight()

        x = btn_x
        max_x = screen_x + screen_w - panel_w - 4
        x = max(screen_x + 4, min(x, max_x))

        # Zawsze rozwijaj do góry, nad przyciskiem
        y = max(screen_y + 4, btn_y - panel_h - 2)

        panel.geometry(f"{panel_w}x{panel_h}+{x}+{y}")

        panel.bind("<Enter>", self._cancel_close_more_panel)
        panel.bind("<Leave>", lambda e: self._schedule_close_more_panel())
        frame.bind("<Enter>", self._cancel_close_more_panel)
        frame.bind("<Leave>", lambda e: self._schedule_close_more_panel())

        self.more_button.bind("<Enter>", self._cancel_close_more_panel)
        self.more_button.bind("<Leave>", lambda e: self._schedule_close_more_panel())

        self.more_panel = panel

    # ── ROZMIAR CZCIONKI ─────────────────────────────────────────────────────
    def _change_font_size(self, delta: int):
        self.font_size = max(8, min(36, self.font_size + delta))
        self._apply_font_size()

    def _toggle_theme(self):
        self.theme_name = "dark" if self.theme_name == "light" else "light"
        _set_palette(self.theme_name)
        self._apply_theme()

    def _update_pokemon_image(self):
        preferred_file = BASE_DIR / (
            "pokemon_dark.png" if self.theme_name == "dark" else "pokemon.png"
        )
        fallback_file = BASE_DIR / "pokemon.png"
        image_file = preferred_file if preferred_file.exists() else fallback_file
        if image_file.exists():
            scale = 8 if self.theme_name == "dark" else 4
            self.pokemon_image = tk.PhotoImage(file=image_file).subsample(scale, scale)
            self.pokemon_label.config(image=self.pokemon_image, bg=POKEMON_BG)
            self.pokemon_label.grid_configure(
                pady=(0, 12) if self.theme_name == "dark" else (6, 6)
            )

    def _update_question_image(self, q: dict):
        image_file = BASE_DIR / "question_98.png"
        if str(q.get("id")) == "98" and image_file.exists():
            self.question_image = tk.PhotoImage(file=image_file).subsample(3, 3)
            self.question_image_label.config(image=self.question_image)
            self.question_image_label.grid()
        else:
            self.question_image_label.config(image="")
            self.question_image_label.grid_remove()

    def _apply_theme(self):
        self.root.configure(bg=BG)

        def recolor(widget):
            widget_class = widget.winfo_class()
            try:
                if widget_class in {"Frame", "TFrame", "Labelframe"}:
                    widget.config(bg=BG)
                elif widget_class in {"Label", "TLabel"}:
                    widget.config(bg=BG, fg=TEXT)
                elif widget_class in {"Button", "TButton"}:
                    widget.config(
                        bg=BG3, fg=TEXT,
                        activebackground=ACTIVE, activeforeground=TEXT,
                    )
                elif widget_class == "Checkbutton":
                    widget.config(
                        bg=BG2, fg=TEXT, selectcolor=BG3,
                        activebackground=BG2, activeforeground=TEXT,
                    )
                elif widget_class == "Text":
                    widget.config(bg=BG2, fg=TEXT, insertbackground=TEXT)
            except tk.TclError:
                pass
            for child in widget.winfo_children():
                recolor(child)

        recolor(self.root)
        self.txt_question.config(bg=BG2, fg=TEXT)
        self.txt_expl.config(bg=BG2, fg=YELLOW)
        self.txt_note.config(bg=BG2, fg=TEXT)
        self.q_frame.config(bg=BG2, highlightbackground=BG3)
        self.opt_outer.config(bg=BG2)
        self.options_frame.config(bg=BG2)
        self.question_image_label.config(bg=BG2)
        self.pokemon_label.config(bg=POKEMON_BG)
        self.expl_frame.config(bg=BG, fg=YELLOW)
        self.note_frame.config(bg=BG, fg=TEXT_DIM)
        self.lbl_progress.config(bg=BG, fg=ACCENT)
        self.lbl_flags.config(bg=BG, fg=RED)
        self.lbl_stats.config(bg=BG, fg=TEXT_DIM)
        self.lbl_font_size.config(bg=BG, fg=TEXT_DIM)
        self.progress_bar.config(bg=BG3)
        self.btn_theme.config(text="☀" if self.theme_name == "dark" else "☾")
        self._update_pokemon_image()
        self._load_question()

    def _apply_font_size(self):
        s = self.font_size
        f = _fonts(s)
        # Stałe widżety
        self.txt_question.config(font=f["bold"])
        self.txt_question.config(padx=max(12, s), pady=max(10, s - 1))
        self.txt_expl.config(font=f["mono"])
        self.txt_note.config(font=f["mono"])
        self.lbl_progress.config(font=f["large"])
        self.lbl_flags.config(font=f["main"])
        self.lbl_stats.config(font=f["small"])
        self.lbl_font_size.config(text=f"A {s}pt", font=f["small"])
        # Dynamiczne checkboxy
        for cb in self.options_frame.winfo_children():
            cb.config(
                font=f["main"],
                pady=max(4, s // 2),
                wraplength=max(600, self.root.winfo_width() - 140),
            )
        # Przyciski dolnego paska
        for w in self._all_buttons:
            try:
                w.config(font=f["main"])
            except Exception:
                pass

    def _on_root_resize(self, event):
        if event.widget is self.root:
            self._apply_font_size()

    # ── STATYSTYKI ───────────────────────────────────────────────────────────
    def _update_stats(self):
        main_questions = [q for q in self.all_questions if self._is_main_question(q)]
        total = len(main_questions)
        completed = sum(
            1 for q in main_questions
            if q["id"] in self.completed_question_ids
        )
        wrong  = sum(1 for q in main_questions if self._get_state(q["id"]).get("wrong"))
        notes  = sum(1 for q in main_questions if self._get_state(q["id"]).get("note","").strip())
        self.lbl_stats.config(
            text=f"Zrobione: {completed}/{total}  |  Błędnych: {wrong}  |  Notatek: {notes}"
        )

    # ── UI ───────────────────────────────────────────────────────────────────
    def _build_ui(self):
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)

        # ── GŁÓWNA RAMKA ─────────────────────────────────────────────────────
        main = tk.Frame(self.root, bg=BG)
        main.pack(fill="both", expand=True, padx=12, pady=10)
        main.columnconfigure(0, weight=1)
        main.rowconfigure(2, weight=1)

        # ── TOP BAR ──────────────────────────────────────────────────────────
        top = tk.Frame(main, bg=BG)
        top.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        top.columnconfigure(1, weight=1)
        top.columnconfigure(2, weight=1)

        self.lbl_progress = tk.Label(top, text="", bg=BG, fg=ACCENT,
                                     font=FONT_LARGE)
        self.lbl_progress.grid(row=0, column=0, sticky="w")

        self.lbl_flags = tk.Label(top, text="", bg=BG, fg=RED, font=FONT_MAIN)
        self.lbl_flags.grid(row=0, column=1, sticky="w", padx=20)

        self.lbl_stats = tk.Label(top, text="", bg=BG, fg=TEXT_DIM, font=FONT_SMALL)
        self.lbl_stats.grid(row=0, column=2, sticky="e", padx=(0, 8))

        # Kontrolki rozmiaru czcionki
        font_ctrl = tk.Frame(top, bg=BG)
        font_ctrl.grid(row=0, column=3, sticky="e")
        tk.Button(font_ctrl, text="A−", command=lambda: self._change_font_size(-1),
                  bg=BG3, fg=TEXT, font=FONT_SMALL, relief="flat", cursor="hand2",
                  activebackground=ACTIVE, activeforeground=TEXT,
                  padx=4, pady=2).pack(side="left")
        self.lbl_font_size = tk.Label(font_ctrl, text=f"A {BASE_SIZE}pt",
                                      bg=BG, fg=TEXT_DIM, font=FONT_SMALL, width=6)
        self.lbl_font_size.pack(side="left")
        tk.Button(font_ctrl, text="A+", command=lambda: self._change_font_size(+1),
                  bg=BG3, fg=TEXT, font=FONT_SMALL, relief="flat", cursor="hand2",
                  activebackground=ACTIVE, activeforeground=TEXT,
                  padx=4, pady=2).pack(side="left")
        self.btn_theme = tk.Button(
            font_ctrl, text="☾", command=self._toggle_theme,
            bg=BG3, fg=TEXT, font=FONT_SMALL, relief="flat", cursor="hand2",
            activebackground=ACTIVE, activeforeground=TEXT,
            padx=4, pady=2,
        )
        self.btn_theme.pack(side="left", padx=(4, 0))

        # ── PASEK POSTĘPU ────────────────────────────────────────────────────
        self.progress_bar = tk.Canvas(
            main, height=14, bg=BG3, highlightthickness=0, bd=0
        )
        self.progress_bar.grid(row=1, column=0, sticky="ew", pady=(0, 8))
        self.progress_bar.bind("<Configure>", self._draw_progress_bar)

        # ── ŚRODEK: pytanie + opcje + wyjaśnienie ────────────────────────────
        mid = tk.Frame(main, bg=BG)
        mid.grid(row=2, column=0, sticky="nsew")
        mid.columnconfigure(0, weight=1)
        mid.rowconfigure(0, weight=1)

        # Główny podział pionowy: [pytanie] / [odpowiedzi + wyjaśnienie]
        main_qa_pane = ttk.Panedwindow(mid, orient="vertical")
        main_qa_pane.grid(row=0, column=0, sticky="nsew", pady=(0, 6))

        # Pytanie
        q_frame = tk.Frame(main_qa_pane, bg=BG2, bd=0, highlightthickness=1,
                           highlightbackground=BG3)
        self.q_frame = q_frame
        q_frame.columnconfigure(0, weight=1)
        q_frame.columnconfigure(1, weight=0)
        q_frame.rowconfigure(0, weight=1)

        self.txt_question = tk.Text(
            q_frame, bg=BG2, fg=TEXT, font=FONT_BOLD,
            wrap="word", relief="flat", padx=12, pady=10,
            state="disabled", height=5, cursor="arrow",
        )
        self.txt_question.grid(row=0, column=0, sticky="nsew")

        self.question_image_label = tk.Label(q_frame, bg=BG2)
        self.question_image_label.grid(
            row=1, column=0, sticky="w", padx=12, pady=(0, 8)
        )
        self.question_image_label.grid_remove()

        self.pokemon_label = tk.Label(q_frame, bg=POKEMON_BG)
        self.pokemon_label.grid(row=0, column=1, sticky="e", padx=(0, 12), pady=6)
        self._update_pokemon_image()

        # Dolna sekcja: odpowiedzi + wyjaśnienie
        qa_container = tk.Frame(main_qa_pane, bg=BG)
        qa_container.columnconfigure(0, weight=1)
        qa_container.rowconfigure(0, weight=1)

        # Opcje + wyjaśnienie (rozciągalne przez przeciąganie)
        qa_pane = ttk.Panedwindow(qa_container, orient="vertical")
        self.qa_pane = qa_pane
        qa_pane.grid(row=0, column=0, sticky="nsew")

        opt_outer = tk.Frame(qa_pane, bg=BG2)
        self.opt_outer = opt_outer
        opt_outer.columnconfigure(0, weight=1)
        opt_outer.rowconfigure(0, weight=1)
        self.options_frame = tk.Frame(opt_outer, bg=BG2)
        self.options_frame.grid(row=0, column=0, sticky="nsew")

        # Wyjaśnienie
        self.expl_frame = tk.LabelFrame(
            qa_pane, text=" 📖 Wyjaśnienie (przeciągnij separator, aby zmienić rozmiar) ",
            bg=BG, fg=YELLOW, font=FONT_SMALL, bd=1, relief="groove",
        )
        self.txt_expl = tk.Text(
            self.expl_frame, bg=BG2, fg=YELLOW, font=FONT_MONO,
            wrap="word", relief="flat", padx=10, pady=8,
            state="disabled", height=10,
        )
        self.txt_expl.pack(fill="both", expand=True)

        qa_pane.add(opt_outer, weight=1)
        qa_pane.add(self.expl_frame, weight=2)

        # Teraz pytanie też ma własny chwyt do zmiany wysokości
        main_qa_pane.add(q_frame, weight=1)
        main_qa_pane.add(qa_container, weight=4)

        # ── NOTATKA ──────────────────────────────────────────────────────────
        self.note_frame = tk.LabelFrame(
            main, text=" 📝 Notatka (auto-zapis przy przejściu) ",
            bg=BG, fg=TEXT_DIM, font=FONT_SMALL, bd=1, relief="groove",
        )
        self.note_frame.grid(row=3, column=0, sticky="ew", pady=(6, 0))
        self.note_frame.columnconfigure(0, weight=1)

        self.txt_note = tk.Text(
            self.note_frame, bg=BG2, fg=TEXT, font=FONT_MONO,
            wrap="word", relief="flat", padx=8, pady=6, height=3,
        )
        self.txt_note.grid(row=0, column=0, sticky="ew")

        btn_note_save = tk.Button(
            self.note_frame, text="Zapisz notatkę", command=self._save_note,
            bg=BG3, fg=TEXT, font=FONT_SMALL, relief="flat", cursor="hand2",
        )
        btn_note_save.grid(row=0, column=1, padx=6)
        self.note_frame.grid_remove()

        # ── DOLNY PASEK PRZYCISKÓW ────────────────────────────────────────────
        bot = tk.Frame(main, bg=BG)
        bot.grid(row=4, column=0, sticky="ew", pady=(10, 0))
        bot.columnconfigure(0, weight=1)

        self._all_buttons: list[tk.Widget] = []

        def btn(parent, text, cmd, color=BG3, fg=TEXT):
            b = tk.Button(parent, text=text, command=cmd,
                          bg=color, fg=fg, font=FONT_MAIN,
                          relief="flat", cursor="hand2",
                          padx=8, pady=5,
                          activebackground="#d8c6d2", activeforeground=TEXT)
            self._all_buttons.append(b)
            return b

        controls = tk.Frame(bot, bg=BG)
        controls.grid(row=0, column=0, sticky="w")

        self.btn_prev = btn(controls, "◀ Poprzednie", self._prev)
        self.btn_prev.pack(side="left", padx=3)

        self.btn_next = btn(controls, "Następne ▶", self._next)
        self.btn_next.pack(side="left", padx=3)

        btn(controls, "✔ Sprawdź", self._check, color="#ddf2e1", fg=GREEN).pack(side="left", padx=3)
        btn(controls, "📝 Notatka", self._toggle_note_panel).pack(side="left", padx=3)

        self.btn_copy = btn(controls, "📋 Kopiuj", self._copy_question)
        self.btn_copy.pack(side="left", padx=3)

        self.more_button = tk.Button(
            controls,
            text="⋯ Więcej",
            command=self._open_more_panel,
            bg=BG3,
            fg=TEXT,
            font=FONT_MAIN,
            relief="flat",
            cursor="hand2",
            padx=8,
            pady=5,
            activebackground="#d8c6d2",
            activeforeground=TEXT,
        )
        self.more_button.pack(side="left", padx=3)
        self._all_buttons.append(self.more_button)

        self.root.bind("<Configure>", self._on_root_resize)

    # ── KLAWIATURA ───────────────────────────────────────────────────────────
    def _bind_keys(self):
        self.root.bind("<Right>",       lambda e: self._next())
        self.root.bind("<Left>",        lambda e: self._prev())
        self.root.bind("<Return>",      lambda e: self._check())
        self.root.bind("<Control-s>",   lambda e: self._save_note())
        self.root.bind("<F1>",          lambda e: self._show_note_popup())
        self.root.bind("<Control-equal>",  lambda e: self._change_font_size(+1))
        self.root.bind("<Control-plus>",   lambda e: self._change_font_size(+1))
        self.root.bind("<Control-minus>",  lambda e: self._change_font_size(-1))

        # 1-8 zaznacza opcje
        for i in range(8):
            self.root.bind(str(i + 1),
                lambda e, idx=i: self.answer_vars[idx].set(
                    1 - self.answer_vars[idx].get()
                ) if idx < len(self.answer_vars) else None
            )

    def run(self):
        self._bind_keys()

        # Zapis notatki przy przejściu
        def _on_close():
            self._save_note()
            self._save_progress()
            self._export_wrong()
            self._save_session()
            self.root.destroy()

        self.root.protocol("WM_DELETE_WINDOW", _on_close)
        self.root.mainloop()


# ─── MAIN ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    root = tk.Tk()
    app  = QuizApp(root)
    app.run()
