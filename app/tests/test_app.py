"""Unit tests for the LLM Text Analysis Service."""

import pytest
import json
import sys
import os

# Add parent directory to path so we can import app
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app import app, analyze_sentiment, summarize_text


@pytest.fixture
def client():
    """Create a Flask test client."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


class TestSentiment:
    def test_positive(self):
        result = analyze_sentiment("I love this product! It is amazing and wonderful.")
        assert result["label"] == "positive"
        assert result["polarity"] > 0

    def test_negative(self):
        result = analyze_sentiment("This is terrible. I hate it. Worst experience ever.")
        assert result["label"] == "negative"
        assert result["polarity"] < 0

    def test_neutral(self):
        result = analyze_sentiment("The meeting is at 3 PM in room 204.")
        assert result["label"] == "neutral"

    def test_returns_required_keys(self):
        result = analyze_sentiment("Hello world")
        assert "label" in result
        assert "polarity" in result
        assert "subjectivity" in result


class TestSummarization:
    def test_short_text_unchanged(self):
        text = "Short sentence."
        assert summarize_text(text) == text

    def test_long_text_shortened(self):
        text = (
            "Machine learning is a branch of artificial intelligence. "
            "It allows computers to learn from data. "
            "Deep learning is a subset of machine learning. "
            "Neural networks are the backbone of deep learning. "
            "Training a model requires large datasets. "
            "The model improves over many iterations. "
            "Evaluation metrics help measure performance. "
        )
        summary = summarize_text(text, num_sentences=3)
        # Summary should be shorter than original
        assert len(summary) < len(text)


class TestAPI:
    def test_index_returns_200(self, client):
        resp = client.get("/")
        assert resp.status_code == 200

    def test_health_check(self, client):
        resp = client.get("/health")
        data = json.loads(resp.data)
        assert data["status"] == "healthy"

    def test_analyze_success(self, client):
        resp = client.post(
            "/analyze",
            data=json.dumps({"text": "I love CI/CD pipelines!"}),
            content_type="application/json",
        )
        assert resp.status_code == 200
        data = json.loads(resp.data)
        assert "sentiment" in data
        assert "summary" in data

    def test_analyze_empty_text(self, client):
        resp = client.post(
            "/analyze",
            data=json.dumps({"text": ""}),
            content_type="application/json",
        )
        assert resp.status_code == 400

    def test_metrics_endpoint(self, client):
        resp = client.get("/metrics")
        assert resp.status_code == 200
        assert b"llm_requests_total" in resp.data
