# Unreleased

# 1.3.0

* Upgrade Discourse to v2026.4.0 (was v2026.3.0)
* Upgrade discourse_docker pin to commit `e295aff` (same `discourse/base:2.0.20260209-1300` image; picks up "Clear stuck web upgrade flags after a full rebuild" fix)
* Upgrade OE devenv to 2.8.4 (fixes missing `pytest`/`playwright` in `:2.8.3` container)
* Bump versioned AMI parameter to `AsgAmiIdv130`
* Add integration test suite (`test/integration/`) — health, infrastructure, and UI smoke tests via pytest + Playwright

# 1.2.0

* Upgrade Discourse to v2026.3.0
* Upgrade Ubuntu to 24.04
* Upgrade to OE CDK library 4.5.0
  * Upgrade Aurora PostgreSQL to 15.13 (was 15.4) *causes downtime during upgrade*
  * Upgrade ElastiCache Redis to 7.0 (was 6.2)
* Upgrade CDK to 2.225.0
* Upgrade OE devenv to 2.8.3
* Introduce versioned AMI parameter (AsgAmiIdv120)
* Switch to AWS Marketplace Catalog API workflow (replaces PLF)
* Remove bundled discourse-math and discourse-cakeday plugins (now in Discourse core)

# 1.1.0

* Upgrade Discourse to v3.4.2
* Add TaskCat tests
* Upgrade to OE CDK library 4.2.4

# 1.0.1

* Adding link to Marketplace product

# 1.0.0

* Initial development
* Updated README.md
* Plugin support
* Pin to v3.2.2
