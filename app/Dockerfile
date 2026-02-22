# ── LLM App Dockerfile ───────────────────────────────────────────────────────
# Multi-stage build: keeps the final image small
# Stage 1 ─ install dependencies
FROM python:3.11-slim AS builder
WORKDIR /install
COPY requirements.txt .
RUN pip install --prefix=/install/deps --no-cache-dir -r requirements.txt

# Stage 2 ─ runtime
FROM python:3.11-slim
LABEL maintainer="ci-cd-demo"

WORKDIR /app
COPY --from=builder /install/deps /usr/local
COPY . .

# Download TextBlob / NLTK corpora (punkt_tab is needed by newer NLTK)
RUN python -m textblob.download_corpora && \
    python -c "import nltk; nltk.download('punkt_tab')"

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "app:app"]
