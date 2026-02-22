"""
LLM Text Analysis Service
==========================
A simple Flask application that provides:
  1. Sentiment Analysis  (positive / negative / neutral)
  2. Text Summarization  (extractive – picks key sentences)
  3. Prometheus metrics   (/metrics endpoint)

This is the "product" that our CI/CD pipeline builds, tests, and deploys.
"""

import time
import os
from flask import Flask, render_template, request, jsonify
from textblob import TextBlob
from prometheus_client import (
    Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
)

# ── Flask app ────────────────────────────────────────────────────────────────
app = Flask(__name__)

# ── Prometheus metrics ───────────────────────────────────────────────────────
REQUEST_COUNT = Counter(
    "llm_requests_total",
    "Total requests to the LLM service",
    ["endpoint", "method"],
)
REQUEST_LATENCY = Histogram(
    "llm_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint"],
)
SENTIMENT_COUNT = Counter(
    "llm_sentiment_total",
    "Count of sentiment results",
    ["sentiment"],
)

# ── Helper functions ─────────────────────────────────────────────────────────

def analyze_sentiment(text: str) -> dict:
    """Return sentiment label + confidence score using TextBlob."""
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity          # -1.0 … +1.0
    subjectivity = blob.sentiment.subjectivity   #  0.0 … +1.0

    if polarity > 0.1:
        label = "positive"
    elif polarity < -0.1:
        label = "negative"
    else:
        label = "neutral"

    SENTIMENT_COUNT.labels(sentiment=label).inc()

    return {
        "label": label,
        "polarity": round(polarity, 3),
        "subjectivity": round(subjectivity, 3),
    }


def summarize_text(text: str, num_sentences: int = 3) -> str:
    """
    Simple extractive summariser.
    Ranks sentences by average word-importance (word frequency)
    and returns the top `num_sentences`.
    """
    blob = TextBlob(text)
    sentences = blob.sentences
    if len(sentences) <= num_sentences:
        return text

    # word frequency table (lowered, ignoring short words)
    word_freq: dict[str, int] = {}
    for word in blob.words.lower():
        if len(word) > 3:
            word_freq[word] = word_freq.get(word, 0) + 1

    # score each sentence
    scored = []
    for idx, sent in enumerate(sentences):
        score = sum(word_freq.get(w.lower(), 0) for w in sent.words)
        scored.append((score, idx, str(sent)))

    # pick top sentences, keep original order
    scored.sort(key=lambda x: x[0], reverse=True)
    top = sorted(scored[:num_sentences], key=lambda x: x[1])
    return " ".join(s for _, _, s in top)


# ── Routes ───────────────────────────────────────────────────────────────────

@app.route("/")
def index():
    """Render the main web UI."""
    REQUEST_COUNT.labels(endpoint="/", method="GET").inc()
    return render_template("index.html")


@app.route("/analyze", methods=["POST"])
def analyze():
    """API endpoint: analyse text and return JSON."""
    start = time.time()
    data = request.get_json(force=True)
    text = data.get("text", "")

    if not text.strip():
        return jsonify({"error": "Please provide some text."}), 400

    result = {
        "sentiment": analyze_sentiment(text),
        "summary": summarize_text(text),
        "original_length": len(text),
        "summary_length": len(summarize_text(text)),
    }

    REQUEST_COUNT.labels(endpoint="/analyze", method="POST").inc()
    REQUEST_LATENCY.labels(endpoint="/analyze").observe(time.time() - start)
    return jsonify(result)


@app.route("/health")
def health():
    """Health-check endpoint used by Docker, Jenkins, and Prometheus."""
    return jsonify({"status": "healthy"})


@app.route("/metrics")
def metrics():
    """Prometheus scrape endpoint."""
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


# ── Entrypoint ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
