# LLM App - multi-stage build
FROM python:3.11-slim AS builder
WORKDIR /install
COPY requirements.txt .
# Install Python deps into a temporary location to keep the final image small
RUN pip install --prefix=/install/deps --no-cache-dir -r requirements.txt

# Runtime image (only contains app + deps)
FROM python:3.11-slim
LABEL maintainer="ci-cd-demo"

WORKDIR /app
# Copy Python dependencies from the builder stage
COPY --from=builder /install/deps /usr/local
COPY . .

# Download TextBlob/NLTK corpora at build time
RUN python -m textblob.download_corpora && \
    python -c "import nltk; nltk.download('punkt_tab')"

EXPOSE 5000

# Container healthcheck for Docker and Compose
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

# Gunicorn runs the Flask app in production mode
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "app:app"]
