"""
LLM Text Analysis Service

Flask application providing:
  - Sentiment analysis (positive / negative / neutral)
  - Extractive text summarization
  - Prometheus metrics (/metrics endpoint)
"""

import time
import os
from flask import Flask, render_template, request, jsonify
from textblob import TextBlob
from prometheus_client import (
    Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
)


app = Flask(__name__)

# Prometheus metrics (low-cardinality labels so metrics stay small)
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



def analyze_sentiment(text: str) -> dict:
    """Return sentiment label + confidence score using TextBlob."""
    # TextBlob wraps a simple NLP pipeline (tokenization + polarity/subjectivity)
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity          # -1.0 … +1.0
    subjectivity = blob.sentiment.subjectivity   #  0.0 … +1.0

    # Thresholds make the output easy to explain in class
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

    # Build a word frequency table (lowercased, skip very short words)
    word_freq: dict[str, int] = {}
    for word in blob.words.lower():
        if len(word) > 3:
            word_freq[word] = word_freq.get(word, 0) + 1

    # Score each sentence by adding up its word frequencies
    scored = []
    for idx, sent in enumerate(sentences):
        score = sum(word_freq.get(w.lower(), 0) for w in sent.words)
        scored.append((score, idx, str(sent)))

    # Pick the top sentences, then restore original order for readability
    scored.sort(key=lambda x: x[0], reverse=True)
    top = sorted(scored[:num_sentences], key=lambda x: x[1])
    return " ".join(s for _, _, s in top)



@app.route("/")
def index():
    """Render the main web UI."""
    # Track request volume for the landing page
    REQUEST_COUNT.labels(endpoint="/", method="GET").inc()
    return render_template("index.html")


@app.route("/analyze", methods=["POST"])
def analyze():
    """API endpoint: analyse text and return JSON."""
    # Measure request latency for Prometheus
    start = time.time()
    data = request.get_json(force=True)
    text = data.get("text", "")

    # Basic validation so the UI gets a helpful error
    if not text.strip():
        return jsonify({"error": "Please provide some text."}), 400

    result = {
        "sentiment": analyze_sentiment(text),
        "summary": summarize_text(text),
        "original_length": len(text),
        "summary_length": len(summarize_text(text)),
    }

    # Update request counters and timing histogram
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
    # Prometheus expects the correct content type for metrics text format
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}



if __name__ == "__main__":
    # Local dev entrypoint (production uses Gunicorn in the Dockerfile)
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
