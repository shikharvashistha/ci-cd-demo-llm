# Selenium test runner
FROM python:3.11-slim

# System libraries needed to run Chrome in a container
RUN apt-get update && \
    apt-get install -y wget gnupg2 unzip curl fonts-liberation \
        libnss3 libatk-bridge2.0-0 libgtk-3-0 libx11-xcb1 \
        libxcomposite1 libxdamage1 libxrandr2 libgbm1 libasound2 \
        libpangocairo-1.0-0 libatspi2.0-0 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tests
COPY requirements.txt .
# Install Python test dependencies
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run the Selenium tests when the container starts
CMD ["pytest", "test_ui.py", "-v", "--tb=short"]
