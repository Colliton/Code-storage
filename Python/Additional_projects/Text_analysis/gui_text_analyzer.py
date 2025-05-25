"""
GUI-Based Text Statistics and Word Frequency Analyzer

This script provides a graphical user interface (GUI) to:
- Load a .txt file
- Analyze its word statistics
- Display:
  - Total word count
  - Unique word count
  - Top 3 most frequent words
  - 3 least frequent words

Dependencies:
- tkinter (built-in)
- collections.Counter
- string

"""

import tkinter as tk
from tkinter import filedialog, messagebox
from collections import Counter
import string

# Clean and prepare text
def clean_text(text):
    text = text.lower()
    return text.translate(str.maketrans('', '', string.punctuation))

# Calculate stats
def analyze_text(text):
    words = text.split()
    total = len(words)
    unique = len(set(words))
    freqs = Counter(words)
    most_common = freqs.most_common(3)
    least_common = freqs.most_common()[-3:]
    return total, unique, most_common, least_common

# Format results
def format_results(total, unique, most_common, least_common):
    def format_list(lst):
        return "\n".join(f"- {word}: {count}" for word, count in lst)

    return (
        f"Total words: {total}\n"
        f"Unique words: {unique}\n\n"
        f"Most frequent words:\n{format_list(most_common)}\n\n"
        f"Least frequent words:\n{format_list(least_common)}"
    )

# Load file and display results
def load_file():
    filepath = filedialog.askopenfilename(
        filetypes=[("Text Files", "*.txt")],
        title="Choose a .txt file"
    )
    if not filepath:
        return

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            text = clean_text(f.read())
    except Exception as e:
        messagebox.showerror("Error", f"Could not read file:\n{e}")
        return

    total, unique, most_common, least_common = analyze_text(text)
    result = format_results(total, unique, most_common, least_common)
    output_box.delete(1.0, tk.END)
    output_box.insert(tk.END, result)

# --- GUI Setup ---
root = tk.Tk()
root.title("Text Analyzer")
root.geometry("500x500")

btn_load = tk.Button(root, text="Load Text File", command=load_file)
btn_load.pack(pady=10)

output_box = tk.Text(root, wrap="word", height=25, width=60)
output_box.pack(padx=10, pady=10)

root.mainloop()
