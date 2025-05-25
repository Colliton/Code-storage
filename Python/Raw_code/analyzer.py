"""
Text Statistics and Word Frequency Analysis

This script analyzes a Polish-language text file to calculate basic text statistics and word frequency data.

Features:
- Cleans text by removing punctuation and converting to lowercase
- Calculates total number of words
- Calculates number of unique words
- Identifies the 3 most and 3 least frequent words

Data:
- Input file: 'input_text.txt' (UTF-8 encoded)
- The input file should contain free-form text, ideally a full paragraph or more

Output:
- Printed statistics:
  - Total word count
  - Unique word count
  - Top 3 most frequent words
  - 3 least frequent words

Dependencies:
- collections.Counter
- string

To run:
- Ensure 'input_text.txt' is present in the same directory
- Run: python analyzer.py

"""
from collections import Counter
import string

# Read text from file
def read_content_of_file(filename):
    with open(filename, "r", encoding="UTF-8") as file:
        return file.read()

# Clean text: lowercase and remove punctuation
def clean_text(text):
    text = text.lower()
    return text.translate(str.maketrans('', '', string.punctuation))

# Count total words
def number_of_words(text):
    return len(text.split())

# Count unique words
def number_of_unique_words(text):
    return len(set(text.split()))

# Word frequency counter
def get_word_frequencies(text):
    return Counter(text.split())

# Most frequent words
def most_common_words(text, n=3):
    return get_word_frequencies(text).most_common(n)

# Least frequent words
def least_common_words(text, n=3):
    return get_word_frequencies(text).most_common()[-n:]

# Format word-frequency pairs into printable lines
def format_word_frequencies(word_freqs):
    return "\n".join(f"- {word}: {count}" for word, count in word_freqs)

# Main execution
if __name__ == "__main__":
    text = read_content_of_file("input_text.txt")
    cleaned_text = clean_text(text)

    print("Text Statistics:")
    print("Total words:", number_of_words(cleaned_text))
    print("Unique words:", number_of_unique_words(cleaned_text), "\n")

    print("Most frequent words:\n", format_word_frequencies(most_common_words(cleaned_text)), "\n")
    print("Least frequent words:\n", format_word_frequencies(least_common_words(cleaned_text)))
