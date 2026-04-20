# YouTube Video Script: Discourse 3.5 on AWS Marketplace

**Video Title:** Deploy Discourse 3.5 on AWS in 30 Minutes | New Features & Full Walkthrough

**Duration:** ~8-10 minutes

---

## INTRO (0:00 - 0:45)

**[Screen: Discourse logo + "3.5" + AWS logo]**

Hey everyone! Discourse just released version 3.5, and we've updated our AWS Marketplace pattern to include all the new features.

In this video, I'll show you what's new in Discourse 3.5, and then walk you through deploying it on AWS using our CloudFormation template.

If you're not familiar with Discourse, it's the open-source forum software that powers communities for companies like GitHub, Netlify, and thousands of others.

Let's dive in.

---

## WHAT'S NEW IN 3.5 (0:45 - 3:00)

**[Screen: Discourse demo site showing new features]**

Discourse 3.5 has some really nice updates. Let me show you the highlights.

### Horizon Theme

**[Screen: Show Horizon theme]**

First up is Horizon, the new default theme. It's clean, modern, and looks great out of the box. This is now built into Discourse core, so you get it automatically.

### New Composer

**[Screen: Demo the new composer]**

The composer has been completely redesigned. Instead of the split-screen markdown view, you now get a single unified window. You can still toggle back to the classic view if you prefer, but I think most people will like this better.

On mobile, it goes full-screen, which makes posting from your phone much nicer.

### Bundled Plugins

**[Screen: Show plugins page in admin]**

This is a big one. Several popular plugins are now bundled directly into Discourse:

- Assign - for assigning topics to team members
- Solved - for marking topics as resolved
- Data Explorer - for running SQL queries
- Reactions - for emoji reactions on posts

If you were installing these manually before, you can simplify your setup now.

### Dark Mode Improvements

**[Screen: Toggle dark/light mode]**

Dark and light modes are much easier to configure now. Each theme can have its own settings, and switching between them is seamless.

---

## AWS ARCHITECTURE OVERVIEW (3:00 - 4:30)

**[Screen: Architecture diagram]**

Before we deploy, let me quickly explain what you're getting with our AWS Marketplace pattern.

**[Point to each component as you mention it]**

- **VPC** with public and private subnets across two availability zones
- **Application Load Balancer** handling SSL termination
- **Auto Scaling Group** running the Discourse application on EC2
- **Aurora PostgreSQL** for the database - fully managed, multi-AZ
- **ElastiCache Redis** for caching and background jobs
- **Elastic File System** for shared storage between instances
- **SES** for sending emails - with DKIM configured automatically
- **S3** for user uploads and assets

Everything is configured for production use. High availability, encryption at rest, the works.

---

## DEPLOYMENT WALKTHROUGH (4:30 - 7:30)

**[Screen: AWS Console]**

Alright, let's deploy this.

### Step 1: Find the Listing

**[Screen: AWS Marketplace search]**

Go to AWS Marketplace and search for "Ordinary Experts Discourse". Click on our listing and hit Subscribe.

### Step 2: Launch the Stack

**[Screen: CloudFormation console]**

Once subscribed, click "Continue to Configuration", select your region, and then "Continue to Launch".

Choose "Launch CloudFormation" and click Launch.

### Step 3: Configure Parameters

**[Screen: CloudFormation parameters]**

Now we fill in the parameters.

**Application Config:**
- **Admin Emails** - This is important. Enter the email addresses that should have admin access. When you register with one of these emails, you'll automatically become an admin.
- **Plugin Commands List** - If you need additional plugins beyond the bundled ones, add git clone commands here, separated by commas.

**DNS:**
- Enter your Route 53 hosted zone name
- Enter the hostname you want, like "community.yourdomain.com"

**SSL:**
- Paste in your ACM certificate ARN. Make sure it covers your hostname.

**VPC:**
- You can create a new VPC or use an existing one. For this demo, I'll let it create a new one.

**[Screen: Click Create Stack]**

Click Create Stack and wait. This takes about 20-25 minutes.

### Step 4: Complete Setup

**[Screen: Stack outputs, then Discourse setup wizard]**

Once the stack is complete, grab the URL from the Outputs tab.

Open it in your browser, and you'll see the Discourse homepage. Click Register, use one of the admin emails you specified, and check your inbox for the confirmation email.

After confirming, you're in as an admin. Run through the setup wizard to configure your site name, colors, and other basics.

And that's it! You've got a production-ready Discourse forum running on AWS.

---

## TIPS & NEXT STEPS (7:30 - 8:30)

**[Screen: Admin dashboard]**

A few tips before I let you go:

**Backups:** Aurora handles database backups automatically, but you should also enable Discourse's built-in backup system for a complete site backup including uploads.

**Scaling:** If you need more capacity, you can modify the Auto Scaling Group settings in EC2. The architecture supports multiple instances behind the load balancer.

**Custom Domain Email:** The SES integration is set up automatically, but you'll want to verify your sending domain and request production access if you're sending to external users.

**Plugins:** Remember, Assign, Solved, Data Explorer, and Reactions are now built-in. Check the Plugins page in admin to enable them.

---

## OUTRO (8:30 - 9:00)

**[Screen: Ordinary Experts logo + links]**

That's Discourse 3.5 on AWS!

If you have questions, drop them in the comments or check out our GitHub repo - link in the description.

We also have similar patterns for Mastodon and Jitsi Meet if you're looking to self-host other open-source applications on AWS.

Thanks for watching, and good luck building your community!

**[End card with subscribe button, links to other videos]**

---

## VIDEO DESCRIPTION

```
Deploy Discourse 3.5 on AWS using our production-ready CloudFormation template. This video covers the new features in Discourse 3.5 and walks through the complete deployment process.

New in Discourse 3.5:
- Horizon theme (new default)
- Redesigned composer
- Bundled plugins (Assign, Solved, Data Explorer, Reactions)
- Improved dark mode
- Admin search tool
- Automatic translations

AWS Marketplace Listing: https://aws.amazon.com/marketplace/pp/prodview-nhgzw6qrtwsgo
Documentation: https://github.com/ordinaryexperts/aws-marketplace-oe-patterns-discourse
Discourse Official: https://discourse.org

Timestamps:
0:00 - Intro
0:45 - What's New in Discourse 3.5
3:00 - AWS Architecture Overview
4:30 - Deployment Walkthrough
7:30 - Tips & Next Steps
8:30 - Outro

#Discourse #AWS #CloudFormation #OpenSource #SelfHosted
```

---

## THUMBNAIL IDEAS

1. Discourse logo + "3.5" badge + AWS logo + "Deploy in 30 min"
2. Split screen: Discourse interface on left, AWS architecture diagram on right
3. "NEW" burst graphic + Discourse 3.5 screenshot + your face (if doing talking head)
