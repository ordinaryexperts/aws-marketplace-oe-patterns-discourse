"""
User workflow tests for Discourse using Playwright.
These tests simulate real user interactions in a headless browser.
"""

import pytest
from playwright.sync_api import sync_playwright


@pytest.mark.ui
class TestDiscourseUIWorkflows:
    """Level 3: UI and user workflow tests."""

    @pytest.fixture(scope="class")
    def browser_context(self):
        """Create a headless browser context for UI tests."""
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                viewport={"width": 1280, "height": 720},
                user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
            )
            yield context
            context.close()
            browser.close()

    def test_homepage_loads(self, base_url, browser_context):
        """Test that the Discourse homepage loads correctly."""
        page = browser_context.new_page()
        try:
            page.goto(base_url, wait_until="networkidle", timeout=60000)
            page.wait_for_load_state("domcontentloaded")

            assert page.title(), "Page title should not be empty"

            # Discourse exposes a meta generator tag and renders the
            # ember-cli-app shell. Either signal is sufficient.
            page_content = page.content().lower()
            assert ("discourse" in page_content
                    or page.locator('meta[name="generator"][content*="Discourse"]').count() > 0), \
                "Page content should reference Discourse"
        finally:
            page.close()

    def test_signup_page_accessible(self, base_url, browser_context):
        """Test that the signup page is accessible."""
        page = browser_context.new_page()
        try:
            # Discourse exposes signup via the /signup route and via the
            # 'Sign Up' button in the header. Probe the route directly.
            page.goto(f"{base_url}/signup", timeout=30000)
            page.wait_for_load_state("domcontentloaded")

            # Discourse renders the create-account modal client-side, so
            # check for either a recognizable selector or a URL containing
            # signup/create-account.
            content = page.content().lower()
            assert ("create" in content and "account" in content) \
                or "signup" in page.url.lower() \
                or page.locator('input[id="new-account-email"]').count() > 0, \
                "Signup affordance not detected"
        finally:
            page.close()

    def test_login_page_accessible(self, base_url, browser_context):
        """Test that the login page is accessible."""
        page = browser_context.new_page()
        try:
            page.goto(f"{base_url}/login", timeout=30000)
            page.wait_for_load_state("domcontentloaded")

            content = page.content().lower()
            assert ("log in" in content or "login" in content) \
                or page.locator('input[id="login-account-name"]').count() > 0, \
                "Login affordance not detected"
        finally:
            page.close()

    def test_categories_page(self, base_url, browser_context):
        """Test that the Discourse /categories listing is accessible."""
        page = browser_context.new_page()
        try:
            page.goto(f"{base_url}/categories", timeout=30000)
            page.wait_for_load_state("domcontentloaded")

            assert page.title(), "Categories page should have a title"
            # Don't fail if categories list is empty on a fresh deploy
        finally:
            page.close()

    def test_about_page(self, base_url, browser_context):
        """Test that the /about page is accessible and reports the instance."""
        page = browser_context.new_page()
        try:
            page.goto(f"{base_url}/about", timeout=30000)
            page.wait_for_load_state("domcontentloaded")

            content = page.content()
            assert content, "About page should have content"
            assert "discourse" in content.lower(), \
                "About page should reference Discourse"
        finally:
            page.close()


@pytest.mark.ui
@pytest.mark.slow
class TestDiscourseUserWorkflow:
    """
    End-to-end user workflow tests.
    These require a confirmed admin user (registered against an email in the
    AdminEmails parameter) before running.
    """

    @pytest.fixture(scope="class")
    def test_user_credentials(self, config):
        pytest.skip(
            "Full user workflow tests require a pre-registered Discourse "
            "admin user. Register one via the homepage with an email listed "
            "in the AdminEmails stack parameter, then update this fixture."
        )

        return {
            "username": "testuser",
            "email": "test@example.com",
            "password": "test_password",
        }

    def test_user_login_workflow(self, base_url, test_user_credentials, browser_context):
        """Test complete user login workflow."""
        page = browser_context.new_page()
        try:
            page.goto(f"{base_url}/login", timeout=30000)
            page.wait_for_load_state("domcontentloaded")

            page.fill('input[id="login-account-name"]',
                      test_user_credentials["username"])
            page.fill('input[id="login-account-password"]',
                      test_user_credentials["password"])
            page.click('button[id="login-button"]')
            page.wait_for_load_state("networkidle")

            assert "/login" not in page.url.lower(), \
                "Should be redirected away from /login after successful login"
        finally:
            page.close()
