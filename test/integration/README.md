# Discourse Integration Tests

Integration tests for the Discourse AWS Marketplace pattern. They validate infrastructure deployment, application health, and basic UI workflows against a deployed stack.

## Test layers

### Level 1 — Health (`test_health.py::TestDiscourseHealth`)
- HTTPS accessibility
- `/srv/status` ALB health endpoint (200 OK with empty body — patched in `packer/ubuntu_2404_appinstall.sh`)
- `/about.json` returns the expected Discourse version
- Response time
- SSL certificate validity (ACM cert via ALB)
- Security headers (`X-Content-Type-Options: nosniff`)

### Level 2 — Infrastructure (`test_health.py::TestDiscourseInfrastructure`)
- CloudFormation stack is in `CREATE_COMPLETE` / `UPDATE_COMPLETE`
- Stack exposes required outputs (`DnsSiteUrlOutput`, `VpcIdOutput`)
- EC2 instance is running and using a valid AMI

### Level 3 — UI workflows (`test_workflows.py`)
- Homepage loads and references Discourse
- `/signup` page is reachable
- `/login` page is reachable
- `/categories` page renders
- `/about` page renders

The slow `TestDiscourseUserWorkflow` class is skipped by default — it expects a pre-registered admin user. Wire one up by registering against an email in the `AdminEmails` stack parameter and updating the `test_user_credentials` fixture.

## Running

From the repo root, against your `make deploy`-ed dev stack:

```bash
# Level 1 + 2 (health + infrastructure)
AWS_PROFILE=oe-patterns-dev make test-integration

# UI tests (requires the playwright chromium browser to be installed)
AWS_PROFILE=oe-patterns-dev make test-integration-ui

# Everything
AWS_PROFILE=oe-patterns-dev make test-integration-all
```

Override the deployed URL or stack name via environment variables:

```bash
TEST_BASE_URL="https://discourse-otheruser.dev.patterns.ordinaryexperts.com" \
TEST_STACK_NAME="oe-patterns-discourse-otheruser" \
  make test-integration
```

`make test-integration` runs inside the devenv docker image, so `playwright` and `pytest` come from `requirements.txt` here — no host-level install needed.
