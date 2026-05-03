# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an AWS Marketplace pattern that deploys a production-ready Discourse instance using CloudFormation/CDK. The project consists of:

1. **Custom AMI** built with Packer (Ubuntu 24.04 with Discourse pre-installed)
2. **CDK Infrastructure** (Python) that synthesizes to CloudFormation templates
3. **Product Listing Framework (PLF)** configuration for AWS Marketplace publishing

The infrastructure includes: VPC, EC2 Auto Scaling Group, Aurora PostgreSQL, ElastiCache Redis, EFS, S3, SES, ALB, Route53, ACM, and supporting services (IAM, Secrets Manager, SSM).

## Upgrade Workflow

For upgrading the upstream Discourse version, follow the process in [aws-marketplace-utilities/UPGRADE.md](https://github.com/ordinaryexperts/aws-marketplace-utilities/blob/develop/UPGRADE.md).

### Discourse-specific upgrade notes

Discourse runs inside `discourse/base` Docker containers managed by the upstream `discourse_docker` tooling. The `discourse/base` image version must be specified in **two** places inside `packer/ubuntu_2404_appinstall.sh`:

1. `git checkout <sha>` — pins the `discourse_docker` repo to a specific commit. The `launcher` script at that commit has a hardcoded `image="discourse/base:<version>"` default that dictates which image the runtime `./launcher bootstrap app` pulls. Find the right commit by browsing [discourse_docker launcher history](https://github.com/discourse/discourse_docker/commits/main/launcher) — recent ones have messages like "Bump default base image to 2.0.XXXXXXXX-XXXX".
2. `docker pull discourse/base:<version>` — pre-pulls the **same** image version into the AMI so `./launcher bootstrap app` doesn't re-download at instance boot.

**Both values must reference the same `discourse/base` tag.** Otherwise the AMI pre-pulls image A but the runtime launcher pulls image B from Docker Hub, doubling disk usage and running a different version.

> **Do not try to override via `base_image:` in `cdk/discourse/user_data.sh`'s generated `app.yml`** — adding `base_image:` at the top of app.yml interacted oddly with the YAML merge done by `launcher`. The git-checkout-pin + pre-pull approach works reliably.

### Plugin list obsolescence

The `PluginCommandsList` parameter in the `Makefile` `deploy` target historically included `git clone https://github.com/discourse/discourse-math.git` and `git clone https://github.com/discourse/discourse-cakeday.git`. **Both plugins were merged into Discourse core** (around mid-2025) and `./launcher bootstrap app` now refuses to build if those plugins are present:

```
HINT: The plugin 'discourse-math' is now bundled with Discourse and should not be included in your container configuration.
```

During upgrades, review the `PluginCommandsList` default against discourse's current bundled-plugins list. Remove any that have been absorbed into core, or bootstrap fails with exit code 128.

### `web.ssl.template.yml` ALB health check patch

The HTTPS server block in `web.ssl.template.yml` has a nginx rewrite that 301's any request whose `Host` header doesn't match `DISCOURSE_HOSTNAME`:

```nginx
if ($http_host != ${DISCOURSE_HOSTNAME}) {
  rewrite (.*) https://${DISCOURSE_HOSTNAME}$1 permanent;
}
```

The ALB target group health check sends requests with `Host: <target-ip>`, which doesn't match, so `/srv/status` returns 301 instead of 200 and the target group marks the instance unhealthy.

The packer script patches this with a pattern-based `sed` that inserts a nested exception for `/srv/status`:

```bash
sed -i '/rewrite.*permanent/i\        if (\$request_uri = "/srv/status") { return 200; }' \
  /var/discourse/templates/web.ssl.template.yml
```

**Why pattern-based (not line-number-based):** The old `sed -i '39,41c...'` approach broke when upstream refactored the template in May 2025 (PR #959, "nginx config outlets"). A pattern match on `rewrite.*permanent` survives line renumbering.

### Pin `version:` in app.yml to a real Discourse tag

The generated `app.yml` (via `cdk/discourse/user_data.sh`) sets `params.version: vXXXX.YY.Z` to pin Discourse to a specific release. Upgrades need two checks:

1. **Tag must exist.** Discourse uses `vYEAR.MAJOR.MINOR` (e.g. `v2026.3.0`). The `-latest` suffix (e.g. `v2026.4.0-latest`) indicates a beta; don't pin to `-latest` tags. `gh api repos/discourse/discourse/tags?per_page=10` lists recent ones.
2. **Tag must be compatible with the `discourse/base` image era.** Very old Discourse versions (e.g. `v3.4.2`) fail bootstrap against modern base images (yarn/pnpm mismatch, schema drift). Keep `version:` on a tag from around the same era as the `discourse/base` image tag.

Root volume must be at least **40GB** in `packer/ami.json` (`volume_size`). The Discourse bootstrap combines the pre-pulled base image, a bootstrap-built app image, and log/cache data; 20GB is not enough and causes `./launcher bootstrap app` to fail with `less than 5GB of free space`.

The `Makefile` `deploy` target should NOT hardcode `VpcId` / `VpcPrivateSubnet*Id` / `VpcPublicSubnet*Id` unless those IDs correspond to a real VPC in `oe-patterns-dev`. Leaving them out lets the CDK stack create a fresh VPC on each deploy.

## Development Environment

All development is done inside Docker containers via docker-compose to ensure consistency:

- `devenv` service: Main development environment with CDK, AWS CLI, Python, and all required tools
- `ami` service: Packer environment for building custom AMIs

**Never run CDK, Packer, or other build commands directly on the host.** Always use `make` targets which wrap docker-compose.

### Using AWS Profiles

The docker-compose setup passes through AWS environment variables:

```bash
AWS_PROFILE=oe-patterns-dev make ami-ec2-build
AWS_PROFILE=oe-patterns-dev make deploy
```

## Common Commands

### Setup
First, download the common make targets:
```bash
make update-common
```
This downloads `common.mk` from the aws-marketplace-utilities repository, which contains most make targets.

### Build and Setup
- `make build` - Build the devenv Docker image
- `make rebuild` - Rebuild devenv without cache
- `make bash` - Start an interactive bash session in devenv container

### CDK Operations
- `make synth` - Synthesize CloudFormation template
- `make synth-to-file` - Synthesize template and save to `dist/template.yaml`
- `make diff` - Show differences between deployed stack and current code
- `make deploy` - Deploy the stack to AWS (dev environment with hardcoded parameters)
- `make destroy` - Destroy the deployed stack
- `make cdk-bootstrap` - Bootstrap CDK in the AWS account

### Testing
- `make test-main` - Run main integration test with taskcat (deploys actual stack)
- `make test-all` - Run all integration tests

### AMI Building
- `make ami-ec2-build` - Build AMI with Packer
- `make ami-ec2-copy AMI_ID=<id>` - Copy AMI to other regions
- `make ami-docker-bash` - Interactive bash session in AMI container

### Product Listing Framework (PLF)
- `make gen-plf AMI_ID=<id> TEMPLATE_VERSION=<version>` - Generate PLF configuration
- `make plf AMI_ID=<id> TEMPLATE_VERSION=<version>` - Update product listing

### Publishing
- `make publish TEMPLATE_VERSION=<version>` - Publish CloudFormation template to S3
- `make publish-diagram TEMPLATE_VERSION=<version>` - Publish architecture diagram

### Cleanup
- `make clean` - Clean up test resources
- `make clean-snapshots-tcat` - Clean up taskcat snapshots
- `make clean-logs-tcat` - Clean up taskcat logs
- `make clean-buckets-tcat` - Clean up taskcat S3 buckets

## Architecture

### CDK Stack Structure

The main CDK stack (`cdk/discourse/discourse_stack.py`) uses reusable constructs from `oe-patterns-cdk-common`. Components:

1. **Vpc** - Creates VPC or uses existing one via parameters
2. **Dns** - Route53 hosted zone integration
3. **AssetsBucket** - S3 bucket with public access for user uploads
4. **Ses** - SES domain identity with Easy DKIM for email
5. **DbSecret** - Secrets Manager for database credentials (username: `discourse`)
6. **ElasticacheRedis** - Redis cluster for caching
7. **AuroraPostgresql** - Aurora PostgreSQL cluster
8. **Efs** - Elastic File System for `/var/discourse/shared`
9. **Asg** - Auto Scaling Group with custom AMI (t3.xlarge, non-Graviton)
10. **Alb** - Application Load Balancer with ACM certificate

### AMI Configuration

The AMI is built via Packer (`packer/ami.json`) using `packer/ubuntu_2404_appinstall.sh`. The AMI ID is hardcoded in `cdk/discourse/discourse_stack.py` and must be updated when building new AMIs.

### User Data

EC2 instances run `cdk/discourse/user_data.sh` on boot, which:
- Retrieves secrets from Secrets Manager
- Mounts EFS for shared storage
- Creates self-signed SSL certificate for internal use
- Configures Discourse with environment variables
- Runs plugin installation commands
- Starts Discourse services

### Key Parameters

- `AdminEmails` - Comma-separated list of admin emails (required for initial setup)
- `PluginCommandsList` - Comma-separated git clone commands for plugins
- `DnsHostname` / `DnsRoute53HostedZoneName` - DNS configuration
- `AlbCertificateArn` - ACM certificate for HTTPS
- `AlbIngressCidr` - IP ranges allowed to access the site
- `AsgReprovisionString` - Forces ASG instance replacement when changed

### Health Check

ALB health check path: `/srv/status`

## Important Patterns

### Version Management
Template version is determined by:
1. `TEMPLATE_VERSION` environment variable (if set)
2. `git describe` output (in git repos)
3. Falls back to "CICD" in CI environments

### Secrets Management
Database and SES credentials are:
1. Generated via `DbSecret` and `Ses` constructs in Secrets Manager
2. Retrieved by EC2 instances via IAM role permissions

## Testing

Integration tests use [taskcat](https://github.com/aws-ia/taskcat), which deploys the stack to AWS and validates success. Test configuration is in `test/main-test/.taskcat.yml`.

Tests run on:
- Every push to `develop` branch
- Pull requests to `develop`
- Weekly schedule (Monday mornings)

## Git Workflow

- Main branch: `develop` (not `main` or `master`)
- Use git-flow style releases: feature branches → develop → release/X.Y.Z → tags

## Dependencies

### Python CDK Dependencies
Defined in `cdk/requirements.txt`:
- `aws-cdk-lib==2.120.0`
- `constructs>=10.0.0,<11.0.0`
- `oe-patterns-cdk-common@4.2.4` (from GitHub)

### Docker Base Image
`ordinaryexperts/aws-marketplace-patterns-devenv:2.5.4`

## Files to Update When Releasing

1. `cdk/discourse/discourse_stack.py` - Update `AMI_ID` constant
2. `plf_config.yaml` - Product listing metadata
3. `CHANGELOG.md` - Document changes
4. Git tag with version number

## Important Notes

- **Do not add Make commands to common.mk** - that file is managed in the aws-marketplace-utilities repo
- The `deploy` target in Makefile has hardcoded parameters for the dev environment
- Discourse runs inside Docker containers on the EC2 instance
- Admin setup: Register with an email from `AdminEmails` parameter, then confirm via email
