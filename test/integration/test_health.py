"""
Health and basic connectivity tests for Discourse.
These tests validate infrastructure and basic application health.
"""

import time
import socket
import ssl
from urllib.parse import urlparse

import pytest
import requests


class TestDiscourseHealth:
    """Level 1: Infrastructure and basic health tests."""

    def test_https_accessible(self, base_url):
        """Test that Discourse is accessible over HTTPS."""
        response = requests.get(base_url, timeout=30, allow_redirects=True)
        assert response.status_code == 200, \
            f"Failed to access Discourse at {base_url}"
        assert response.url.startswith("https://"), \
            "Discourse should be accessible via HTTPS"

    def test_health_endpoint(self, base_url):
        """Test the /srv/status endpoint used by the ALB target group health check.

        Patched into web.ssl.template.yml during AMI build (see CLAUDE.md). It
        returns 200 with an empty body even when Host doesn't match
        DISCOURSE_HOSTNAME, so the ALB can mark the target healthy.
        """
        response = requests.get(f"{base_url}/srv/status", timeout=10)
        assert response.status_code == 200, \
            f"/srv/status returned {response.status_code} (expected 200)"

    def test_about_api(self, base_url, config):
        """Test Discourse /about.json endpoint and verify the version."""
        response = requests.get(f"{base_url}/about.json", timeout=10)
        assert response.status_code == 200, \
            f"/about.json returned {response.status_code}"

        data = response.json()
        assert "about" in data, "/about.json response missing 'about' field"
        assert "version" in data["about"], "/about.json missing 'about.version'"

        expected_version = config["application"]["expected_version"]
        actual_version = data["about"]["version"]
        # Discourse appends a build suffix to the version (e.g. "v2026.4.0
        # +abcdef0"). Match the leading version string only.
        assert expected_version in actual_version, \
            f"Version mismatch. Expected: {expected_version}, Got: {actual_version}"

    def test_response_time(self, base_url):
        """Test that Discourse responds within an acceptable time."""
        start = time.time()
        response = requests.get(f"{base_url}/srv/status", timeout=30)
        elapsed = time.time() - start

        assert response.status_code == 200, "Health check failed"
        assert elapsed < 5.0, f"Response time {elapsed:.2f}s exceeds 5 seconds"

    def test_ssl_certificate(self, base_url):
        """Verify the public SSL certificate served by the ALB is valid."""
        parsed = urlparse(base_url)
        hostname = parsed.hostname
        port = parsed.port or 443

        context = ssl.create_default_context()
        try:
            with socket.create_connection((hostname, port), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    cert = ssock.getpeercert()
                    assert cert is not None, "No SSL certificate found"
        except ssl.SSLError as e:
            pytest.fail(f"SSL certificate validation failed: {e}")

    def test_security_headers(self, base_url):
        """Test that important security headers are present.

        Discourse sets X-Content-Type-Options, X-Frame-Options, and
        Strict-Transport-Security by default; the latter is added by the ALB
        when terminating HTTPS.
        """
        response = requests.get(base_url, timeout=10)
        headers = response.headers

        assert "X-Content-Type-Options" in headers, \
            "X-Content-Type-Options header missing"
        assert headers.get("X-Content-Type-Options") == "nosniff", \
            "X-Content-Type-Options should be 'nosniff'"


class TestDiscourseInfrastructure:
    """Level 2: AWS infrastructure tests."""

    def test_cloudformation_stack_exists(self, cloudformation_client, stack_name):
        """Verify CloudFormation stack exists and is in good state."""
        response = cloudformation_client.describe_stacks(StackName=stack_name)

        assert len(response["Stacks"]) == 1, \
            f"Expected 1 stack, found {len(response['Stacks'])}"

        stack = response["Stacks"][0]
        assert stack["StackStatus"] in ["CREATE_COMPLETE", "UPDATE_COMPLETE"], \
            f"Stack is in unexpected state: {stack['StackStatus']}"

    def test_stack_outputs(self, stack_outputs):
        """Verify CloudFormation stack has required outputs."""
        required_outputs = [
            "DnsSiteUrlOutput",
            "VpcIdOutput",
        ]

        for output in required_outputs:
            assert output in stack_outputs, \
                f"Required output '{output}' missing from stack"
            assert stack_outputs[output], \
                f"Output '{output}' is empty"

    def test_ec2_instance_running(self, instance_id, ec2_client):
        """Verify EC2 instance is running."""
        response = ec2_client.describe_instances(InstanceIds=[instance_id])

        assert len(response["Reservations"]) > 0, \
            f"No reservations found for instance {instance_id}"

        instance = response["Reservations"][0]["Instances"][0]
        assert instance["State"]["Name"] == "running", \
            f"Instance is not running: {instance['State']['Name']}"

    def test_instance_has_correct_ami(self, instance_id, ec2_client):
        """Verify instance is using a valid AMI."""
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        instance = response["Reservations"][0]["Instances"][0]

        ami_id = instance["ImageId"]
        assert ami_id.startswith("ami-"), \
            f"Invalid AMI ID format: {ami_id}"
