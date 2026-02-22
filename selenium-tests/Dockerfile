# ── Selenium Test Runner Dockerfile ───────────────────────────────────────────
FROM python:3.11-slim

RUN apt-get update && \
    apt-get install -y wget gnupg2 unzip curl fonts-liberation \
        libnss3 libatk-bridge2.0-0 libgtk-3-0 libx11-xcb1 \
        libxcomposite1 libxdamage1 libxrandr2 libgbm1 libasound2 \
        libpangocairo-1.0-0 libatspi2.0-0 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tests
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# The test script waits for the app to be ready before running
CMD ["pytest", "test_ui.py", "-v", "--tb=short"]
