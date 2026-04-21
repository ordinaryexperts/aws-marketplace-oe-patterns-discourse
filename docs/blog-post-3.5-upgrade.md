# Discourse 3.5 Now Available on AWS Marketplace

We're excited to announce that our Discourse AWS Marketplace pattern has been updated to version 3.5.2, bringing a host of new features and improvements to your self-hosted community forums.

## What's New in Discourse 3.5

### Horizon: A Fresh New Look

Discourse 3.5 introduces Horizon, a sleek modern theme that's now the default. Horizon delivers a clean, contemporary design that looks great out of the box. It's built into Discourse core, so there's nothing extra to install or configure.

### Redesigned Composer

The new visual composer combines everything into a single window, making it easier to create and respond to topics. You can toggle between the updated interface and the classic markdown view whenever you like. On mobile, the composer goes full-screen for a distraction-free writing experience.

### Improved Color Management

Dark and light modes are now much easier to configure. Each theme can have its own dark/light settings, and users can easily switch between their preferred color options.

### Bundled Plugins

Several popular plugins are now bundled directly into Discourse core:

- **Assign** - Assign topics to team members
- **Solved** - Mark topics as solved (great for support forums)
- **Data Explorer** - Run SQL queries against your forum data
- **Reactions** - Add emoji reactions to posts

If you were previously installing these via the Plugin Commands List parameter, you may be able to simplify your configuration.

### Admin Improvements

A new comprehensive admin search tool makes it easy to find settings, pages, plugins, and components. Site logos and fonts are easier to set up, and the overall organization of admin settings has been improved.

### Automatic Translations

Discourse 3.5 includes AI-powered automatic translation capabilities, making it easier to run multilingual communities.

## Upgrading Your Existing Installation

If you're running an earlier version of our Discourse pattern, upgrading is straightforward:

1. **Launch a new stack** with the updated CloudFormation template
2. **Migrate your data** from your existing Aurora PostgreSQL database
3. **Update your DNS** to point to the new load balancer

For detailed migration instructions, see our documentation.

## New Deployments

Deploying Discourse 3.5 on AWS is as easy as ever:

1. Find our listing on AWS Marketplace
2. Subscribe and launch the CloudFormation stack
3. Configure your domain, SSL certificate, and admin email
4. Complete the setup wizard in your browser

Your production-ready Discourse forum will be running in about 30 minutes, complete with:

- Aurora PostgreSQL for reliable, scalable database storage
- ElastiCache Redis for high-performance caching
- Elastic File System for shared storage across instances
- Application Load Balancer with SSL termination
- SES integration for reliable email delivery
- Auto Scaling for handling traffic spikes

## Getting Started

Ready to deploy Discourse 3.5 on AWS?

- [View on AWS Marketplace](https://aws.amazon.com/marketplace/pp/prodview-nhgzw6qrtwsgo)
- [Documentation](https://github.com/ordinaryexperts/aws-marketplace-oe-patterns-discourse)
- [Support](mailto:support@ordinaryexperts.com)

---

*Ordinary Experts specializes in AWS Marketplace solutions for open-source applications. Our patterns provide production-ready infrastructure so you can focus on building your community.*
