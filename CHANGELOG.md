# Unreleased

* Fix a deploy-order race condition where the ASG launch template could bake in an empty `DISCOURSE_REDIS_HOST` (and, less reliably, `DISCOURSE_DB_HOST`): both were resolved via raw `${RedisCluster.RedisEndpoint.Address}` / `${DbCluster.Endpoint.Address}` text in `user_data.sh`, which CDK's dependency graph can't see into, so CloudFormation could create the launch template before those resources finished. Discourse then tried to reach Redis on `127.0.0.1:6379`, `bundle exec rake db:migrate` failed during `./launcher bootstrap app`, and the app never came up (ALB returned 502 on every endpoint). Fixed by passing `DbHost`/`RedisHost` through `user_data_variables` as genuine CDK attribute references, which CloudFormation's `Fn::Sub` variable map reliably depends on.
* Fix `test/integration/config.yaml`'s `expected_version` (was hardcoded to the old pinned Discourse version, so `test_about_api` would fail after any version bump)
* Fix `docker-compose.yml` missing `TEST_BASE_URL`/`TEST_STACK_NAME` in the `environment:` passthrough list, so the override mechanism documented in `test/integration/README.md` silently did nothing
* Upgrade Discourse to v2026.6.0 (was v2026.4.0)
* Upgrade discourse_docker pin to commit `472e9ce` (`discourse/base:2.0.20260706-0040`, up from `2.0.20260209-1300`; new base image includes both PG15 and PG18 clients)
* Upgrade OE devenv to 2.8.4 -> 2.8.6 (bundled Node.js runtime 20 -> 22 LTS, fixes JSII EOL warnings)
* Upgrade aws-marketplace-utilities script pin (packer preinstall + common.mk) to 1.10.3 (was 1.9.1) - picks up an EFS-utils AMI build reliability fix (previously `build-deb.sh` could silently fail to produce mount.efs without erroring the build)
* Upgrade oe-patterns-cdk-common to 4.5.1 (was 4.5.0) - additive-only Secret construct params, no behavior change for this stack
* Bump versioned AMI parameter to `AsgAmiIdv140`

# 1.3.0

* Upgrade Discourse to v2026.4.0 (was v2026.3.0)
* Upgrade discourse_docker pin to commit `e295aff` (same `discourse/base:2.0.20260209-1300` image; picks up "Clear stuck web upgrade flags after a full rebuild" fix)
* Upgrade OE devenv to 2.8.4 (fixes missing `pytest`/`playwright` in `:2.8.3` container)
* Bump versioned AMI parameter to `AsgAmiIdv130`
* Add integration test suite (`test/integration/`) - health, infrastructure, and UI smoke tests via pytest + Playwright

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
