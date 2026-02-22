"""Selenium UI tests for the LLM Text Analysis Service."""

import time
import pytest
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


APP_URL = "http://llm-app:5000"
SELENIUM_HUB = "http://selenium-chrome:4444/wd/hub"
WAIT_TIMEOUT = 20  # seconds



@pytest.fixture(scope="module")
def wait_for_app():
    """Block until the Flask app is reachable."""
    for _ in range(30):
        try:
            r = requests.get(f"{APP_URL}/health", timeout=2)
            if r.status_code == 200:
                return
        except requests.ConnectionError:
            pass
        time.sleep(2)
    pytest.fail("LLM app did not become healthy in time")


@pytest.fixture(scope="module")
def driver(wait_for_app):
    """Create a remote Chrome WebDriver connected to Selenium Grid."""
    opts = Options()
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--headless")

    # Wait for Selenium Grid to be ready
    for _ in range(15):
        try:
            d = webdriver.Remote(command_executor=SELENIUM_HUB, options=opts)
            d.implicitly_wait(10)
            yield d
            d.quit()
            return
        except Exception:
            time.sleep(2)

    pytest.fail("Could not connect to Selenium Grid")



class TestPageLoad:
    def test_title(self, driver):
        driver.get(APP_URL)
        assert "LLM Text Analysis" in driver.title

    def test_header_visible(self, driver):
        driver.get(APP_URL)
        h1 = driver.find_element(By.TAG_NAME, "h1")
        assert "LLM Text Analysis" in h1.text

    def test_pipeline_badges_visible(self, driver):
        driver.get(APP_URL)
        badges = driver.find_elements(By.CSS_SELECTOR, ".pipeline-strip span")
        labels = [b.text for b in badges]
        for tool in ["GitHub", "Jenkins", "Selenium", "Puppet", "Prometheus"]:
            assert tool in labels, f"'{tool}' badge not found on page"


class TestAnalyzeWorkflow:
    POSITIVE_TEXT = "I absolutely love this CI/CD pipeline demo! It is fantastic and works perfectly."
    NEGATIVE_TEXT = "This is broken, terrible, awful. Nothing works and everything fails."

    def _submit_text(self, driver, text):
        driver.get(APP_URL)
        textarea = driver.find_element(By.ID, "inputText")
        textarea.clear()
        textarea.send_keys(text)
        btn = driver.find_element(By.ID, "analyzeBtn")
        btn.click()
        # Wait for results to appear
        WebDriverWait(driver, WAIT_TIMEOUT).until(
            EC.visibility_of_element_located((By.ID, "results"))
        )

    def test_positive_sentiment(self, driver):
        self._submit_text(driver, self.POSITIVE_TEXT)
        badge = driver.find_element(By.ID, "sentimentBadge")
        assert "POSITIVE" in badge.text.upper()
        assert "positive" in badge.get_attribute("class")

    def test_negative_sentiment(self, driver):
        self._submit_text(driver, self.NEGATIVE_TEXT)
        badge = driver.find_element(By.ID, "sentimentBadge")
        assert "NEGATIVE" in badge.text.upper()

    def test_summary_populated(self, driver):
        long_text = (
            "Machine learning is a subset of artificial intelligence. "
            "It allows computers to learn from data without being explicitly programmed. "
            "Deep learning uses neural networks with many layers. "
            "These models can recognize patterns in large datasets. "
            "Natural language processing is a key application of deep learning. "
            "It powers chatbots, translation services, and text analysis tools. "
            "The deployment of ML models requires robust infrastructure."
        )
        self._submit_text(driver, long_text)
        summary = driver.find_element(By.ID, "summaryText").text
        assert len(summary) > 0
        assert len(summary) <= len(long_text)


class TestEndpoints:
    def test_health(self):
        r = requests.get(f"{APP_URL}/health")
        assert r.status_code == 200
        assert r.json()["status"] == "healthy"

    def test_metrics(self):
        r = requests.get(f"{APP_URL}/metrics")
        assert r.status_code == 200
        assert "llm_requests_total" in r.text
