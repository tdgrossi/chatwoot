# Chatwoot Deployment Guide — Max's Fork
## Dokploy + Cloudflare Tunnel on Ubuntu (Local Machine)

**Target:** Deploy Chatwoot at your domain via Cloudflare Tunnel, running on a spare Ubuntu laptop managed by Dokploy.

---

## Prerequisites

- Spare laptop running Ubuntu 22.04 or 24.04 LTS (minimum 4 GB RAM, 40 GB disk)
- A domain managed on Cloudflare
- A Cloudflare account (free tier is sufficient)
- Internet connection on the laptop (outbound traffic only — no port forwarding needed)
- A Meta/Facebook Developer account (for WhatsApp Cloud API)
- An SMTP provider for email (e.g., Gmail App Password, Brevo, Resend, or Mailgun)

---

## Security Considerations

> **IMPORTANT:** Before deploying, be aware of these security aspects:

1. **Change all default passwords** — The database password `CHANGE_THIS_DB_PASSWORD` MUST be changed before deployment
2. **Use strong secrets** — Generate a cryptographically secure `SECRET_KEY_BASE` (64+ hex chars)
3. **Protect your `stack.env` file** — This file contains sensitive credentials; never commit it to version control
4. **Whitelist your Meta app** — During development, only whitelisted phone numbers can message your WhatsApp Business account
5. **Consider Docker secrets** — For production, use Docker Swarm secrets or an external secrets manager instead of plain env files

---

## Part 1 — Prepare the Ubuntu Machine

### Step 1.1 — Update the System

Open a terminal on the laptop and run:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git ufw
```

### Step 1.2 — Configure the Firewall

Dokploy and Chatwoot only need outbound access. Lock down inbound traffic:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh        # Keep SSH access if you want remote terminal access
sudo ufw enable
```

> **Note:** You do NOT need to open ports 80 or 443. All inbound HTTP/HTTPS traffic will flow through Cloudflare Tunnel, which only makes outbound connections.

---

## Part 2 — Install Dokploy

### Step 2.1 — Run the Installer

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

This script will:
- Install Docker and Docker Compose if not present
- Initialize Docker Swarm
- Pull Dokploy images and start the Dokploy panel
- Create the Traefik reverse proxy and an internal overlay network (`dokploy-network`)

Wait 15–30 seconds after it finishes.

### Step 2.2 — Access the Dokploy Dashboard

Open a browser **on the same machine** and navigate to:

```
http://localhost:3000
```

You will see the first-run setup screen. Create your Dokploy admin account (email + password). Save these credentials — you'll need them.

> If you're accessing from another machine on your local network, use the laptop's LAN IP instead of `localhost`, e.g. `http://192.168.1.X:3000`.

---

## Part 3 — Set Up Cloudflare Tunnel

This is what lets Chatwoot be publicly reachable at your domain without opening any ports on your router.

### Step 3.1 — Create the Tunnel in Cloudflare

1. Log into [dash.cloudflare.com](https://dash.cloudflare.com).
2. In the left sidebar, click **Zero Trust**.
3. Go to **Networks → Tunnels**.
4. Click **Create a tunnel**, choose **Cloudflared**, and give it a name (e.g., `chatwoot-tunnel`).
5. On the next screen, Cloudflare will show you an install command with a token embedded. **Copy the tunnel token** — it looks like a long random string. You'll need it shortly.
6. Click **Next** — don't worry about the connector installation step shown here; you'll run `cloudflared` as a Docker container inside Dokploy.

### Step 3.2 — Configure the Public Hostname

Still in the Cloudflare Tunnel setup:

1. Click **Add a public hostname**.
2. Fill in:
   - **Subdomain:** `chat` (or your desired subdomain)
   - **Domain:** `your-domain.com`
   - **Service type:** `HTTP`
   - **URL:** `traefik:80`

   > This routes your domain → through the tunnel → to Traefik inside Docker, which then routes to Chatwoot.

3. Save and finish creating the tunnel. Cloudflare will automatically create a CNAME DNS record pointing to the tunnel.

### Step 3.3 — Configure Cloudflare SSL Mode

1. In Cloudflare dashboard, go to your domain.
2. Click **SSL/TLS → Overview**.
3. Set the encryption mode to **Full** (not Flexible, not Full Strict).
   - "Full" encrypts between visitor and Cloudflare, and also between Cloudflare and your origin — but doesn't require a CA-signed cert on your server, which is fine since Traefik will handle HTTP internally.

### Step 3.4 — Deploy Cloudflared in Dokploy

1. In the Dokploy dashboard, click **Projects → Create Project**. Name it `infrastructure`.
2. Inside the project, click **Create Service → Docker Compose**.
3. Paste the following compose file, replacing `YOUR_TUNNEL_TOKEN_HERE` with the token you copied in Step 3.1:

```yaml
version: "3.8"
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    network_mode: host
    environment:
      - TUNNEL_TOKEN=YOUR_TUNNEL_TOKEN_HERE
    command:
      - tunnel
      - --no-autoupdate
      - run
```

4. Click **Deploy**.
5. After a minute, check the **Logs** tab. You should see lines like `Connection established` and `Registered tunnel connection`. The tunnel is now live.

---

## Part 4 — Deploy Chatwoot

### Step 4.1 — Generate a Secret Key

Run this on the Ubuntu terminal to generate a strong secret:

```bash
openssl rand -hex 64
```

Copy the output — this will be your `SECRET_KEY_BASE`. **Store it securely** — you'll need it for every deployment and it cannot be recovered if lost.

### Step 4.2 — Create the Chatwoot Project in Dokploy

1. In Dokploy, click **Projects → Create Project**. Name it `chatwoot`.
2. Inside the project, click **Create Service → Docker Compose**.
3. Paste the following compose file:

```yaml
version: "3.8"

services:
  rails:
    image: chatwoot/chatwoot:latest
    env_file: stack.env
    volumes:
      - chatwoot_storage:/app/storage
    depends_on:
      - postgres
      - redis
    networks:
      - dokploy-network
      - internal
    expose:
      - "3000"
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    entrypoint: docker/entrypoints/rails.sh
    command: ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
    restart: unless-stopped
    # Resource limits (adjust based on your hardware)
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G

  sidekiq:
    image: chatwoot/chatwoot:latest
    env_file: stack.env
    volumes:
      - chatwoot_storage:/app/storage
    depends_on:
      - postgres
      - redis
    networks:
      - internal
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    command: ["bundle", "exec", "sidekiq", "-C", "config/sidekiq.yml"]
    restart: unless-stopped
    # Resource limits
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    volumes:
      - chatwoot_postgres:/var/lib/postgresql/data
    networks:
      - internal
    environment:
      - POSTGRES_USER=chatwoot
      - POSTGRES_PASSWORD=CHANGE_THIS_DB_PASSWORD  # ⚠️ MUST CHANGE THIS
      - POSTGRES_DB=chatwoot_production
    # Resource limits
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

  redis:
    image: redis:alpine
    restart: unless-stopped
    networks:
      - internal
    volumes:
      - chatwoot_redis:/data

volumes:
  chatwoot_storage:
  chatwoot_postgres:
  chatwoot_redis:

networks:
  dokploy-network:
    external: true
  internal:
    driver: overlay
    internal: true
```

> **Security notes:**
> - Only the `rails` service is connected to `dokploy-network` (and thus reachable by Traefik)
> - Postgres and Redis are on the `internal` network only — they are not exposed externally
> - Resource limits are set to prevent any single service from consuming all available memory

### Step 4.3 — Configure Environment Variables

In the Dokploy service, go to the **Environment** tab and add the following. Replace placeholder values with your actual configuration:

```env
# Core (REQUIRED)
SECRET_KEY_BASE=PASTE_YOUR_GENERATED_SECRET_HERE
FRONTEND_URL=https://your-domain.com
FORCE_SSL=true

# Database (REQUIRED - must match compose file)
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USERNAME=chatwoot
POSTGRES_PASSWORD=CHANGE_THIS_DB_PASSWORD  # ⚠️ MUST MATCH COMPOSE FILE
POSTGRES_DB=chatwoot_production

# Redis (REQUIRED)
REDIS_URL=redis://redis:6379

# Email (SMTP) — see Part 5 for provider-specific values
# (REQUIRED for password resets, notifications)
MAILER_SENDER_EMAIL=noreply@your-domain.com
SMTP_ADDRESS=smtp.your-provider.com
SMTP_PORT=587
SMTP_USERNAME=your-smtp-user
SMTP_PASSWORD=your-smtp-password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# Security (RECOMMENDED)
# Disable public signup - only admins can create accounts
ENABLE_ACCOUNT_SIGNUP=false

# Storage (local by default — files saved in the volume)
ACTIVE_STORAGE_SERVICE=local

# Logging
RAILS_LOG_TO_STDOUT=true
```

> **Important:**
> - `POSTGRES_PASSWORD` must match exactly what you set in the compose file for the postgres service
> - Consider using Docker secrets for production: `echo "your-secret" | docker secret create chatwoot_db_password -`
> - The `stack.env` file should be stored securely and backed up — it contains all your secrets

### Step 4.4 — Initialize the Database

Dokploy doesn't run one-off commands automatically. You need to run the database setup command **before** fully starting Chatwoot.

In Dokploy, the easiest way is:

1. **Deploy** the service first (it will fail or loop on `rails` since the DB isn't initialized — that's okay).
2. Go to **Containers** in Dokploy and find the running `rails` container.
3. Click **Terminal** (or use the shell icon) to open a shell into it.
4. Run:

```bash
bundle exec rails db:chatwoot_prepare
```

5. Wait for it to complete (it sets up the DB schema without seeding demo data).
6. Go back to Dokploy and **restart** the `rails` service.

Alternatively, you can do this from the Ubuntu terminal:

```bash
# Find the container name
docker ps | grep rails

# Run the prepare command (replace container_name with actual name)
docker exec -it <container_name> bundle exec rails db:chatwoot_prepare
```

### Step 4.5 — Configure the Domain in Dokploy

1. In Dokploy, open the `rails` service.
2. Go to the **Domains** tab.
3. Click **Add Domain** and fill in:
   - **Host:** `your-domain.com`
   - **Port:** `3000`
   - **HTTPS:** Leave disabled (Cloudflare handles HTTPS termination — enabling it here with Traefik can cause redirect loops)
4. Save.

Traefik will now route requests arriving at your domain to your Chatwoot `rails` container on port 3000.

### Step 4.6 — Verify the Deployment

Open your browser and navigate to:

```
https://your-domain.com
```

You should see the Chatwoot onboarding screen asking you to create your first account. **Do this now** — the first account created becomes the default administrator account.

---

## Part 5 — Set Up the Super Admin Dashboard

The Super Admin dashboard is separate from your regular Chatwoot account and is used to manage accounts, billing settings, and instance-level configuration.

### Step 5.1 — Create the Super Admin User

The first account created via the onboarding page is a regular admin, not a Super Admin. You need to create the Super Admin account via the Rails console.

On the Ubuntu terminal:

```bash
# Find the rails container name
docker ps | grep rails

# Enter the container
docker exec -it <rails_container_name> /bin/sh

# Open the Rails console
RAILS_ENV=production bundle exec rails c
```

Once inside the Rails console, run:

```ruby
# Create a Super Admin account
s = SuperAdmin.create!(
  email: "superadmin@your-domain.com",
  password: "YourStrongPassword123!",
  name: "Super Admin"
)

# Confirm the account (bypasses email confirmation)
s.confirmed_at = Time.now
s.confirmation_token = nil
s.save!

exit
```

### Step 5.2 — Access the Super Admin Dashboard

Navigate to:

```
https://your-domain.com/super_admin
```

Log in with the email and password you just set. From here you can:
- Manage all accounts on the instance
- Monitor Sidekiq background jobs
- View and configure feature flags
- Manage billing/subscription settings

> ⚠️ **Security note:** The Super Admin account bypasses normal email confirmation. Use a strong, unique password and consider enabling 2FA if available.

---

## Part 6 — Configure Email (SMTP)

Chatwoot uses email for agent notifications, password resets, and outbound email conversations.

### Option A — Gmail App Password (Simplest)

1. Enable 2-Factor Authentication on your Google account.
2. Go to **Google Account → Security → App Passwords**.
3. Create an app password (select "Mail" and "Other device").
4. Use these SMTP settings in your environment variables:

```env
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=youraddress@gmail.com
SMTP_PASSWORD=your-16-char-app-password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
MAILER_SENDER_EMAIL=youraddress@gmail.com
```

> Gmail limits you to ~500 emails/day on free accounts — fine for small teams.

### Option B — Brevo (Free Tier, 300 emails/day)

1. Sign up at [brevo.com](https://brevo.com).
2. Go to **SMTP & API → SMTP**.
3. Use:

```env
SMTP_ADDRESS=smtp-relay.brevo.com
SMTP_PORT=587
SMTP_USERNAME=your-brevo-login-email
SMTP_PASSWORD=your-brevo-smtp-key
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
MAILER_SENDER_EMAIL=noreply@your-domain.com
```

### Option C — Resend (Developer-Friendly, Generous Free Tier)

1. Sign up at [resend.com](https://resend.com) and verify your domain.
2. Create an API key.
3. Use:

```env
SMTP_ADDRESS=smtp.resend.com
SMTP_PORT=587
SMTP_USERNAME=resend
SMTP_PASSWORD=your-resend-api-key
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
MAILER_SENDER_EMAIL=noreply@your-domain.com
```

### Verifying Email Works

After setting SMTP vars and redeploying, go to the Chatwoot **Super Admin dashboard → Notifications** (or test by sending a password reset email from the login page).

---

## Part 7 — Set Up WhatsApp

Chatwoot supports WhatsApp via the **WhatsApp Cloud API** (free, hosted by Meta). You'll need a Meta Developer account and a WhatsApp Business phone number.

### Step 7.1 — Create a Meta App

1. Go to [developers.facebook.com](https://developers.facebook.com) and log in.
2. Click **My Apps → Create App**.
3. Choose **Business** type.
4. Give it a name (e.g., `Chatwoot Your Name`) and your email.
5. On the app dashboard, click **Add Product** and select **WhatsApp**.

### Step 7.2 — Set Up a WhatsApp Business Account

1. In the left sidebar under your app, go to **WhatsApp → Quick Start**.
2. Follow the prompts to create or link a **WhatsApp Business Account (WABA)** and add a **phone number**.
   - For testing, Meta provides a free test phone number. For production, you'll add your real business number.
3. Note down:
   - **Phone Number ID** (shown in the API Setup section)
   - **WhatsApp Business Account ID**

### Step 7.3 — Generate a Permanent Access Token

Temporary tokens expire after a few hours. You need a permanent system user token for production:

1. Go to [business.facebook.com](https://business.facebook.com).
2. Go to **Settings → System Users**.
3. Click **Add** and create a system user with **Admin** role.
4. Click **Add Assets** → select your WhatsApp app → grant **Full Control**.
5. Click **Generate New Token**:
   - Select your app
   - Set expiration to **Never**
   - Under permissions, select: `whatsapp_business_messaging`, `whatsapp_business_management`
6. Copy the generated token securely. **Store it safely** — it provides full access to your WhatsApp Business account.

### Step 7.4 — Set Up the Webhook in Chatwoot

1. Log into your Chatwoot dashboard at `https://your-domain.com`.
2. Go to **Settings → Inboxes → Add Inbox**.
3. Select **WhatsApp**.
4. Choose **WhatsApp Cloud API (Manual setup)**.
5. Fill in:
   - **Phone Number:** your WhatsApp business number (e.g., `+5543...`)
   - **Phone Number ID:** from Meta
   - **Business Account ID:** from Meta
   - **API Key:** the permanent token from Step 7.3
6. Click **Create Inbox**.

Chatwoot will show you a **Webhook URL** and a **Verify Token**. Note both.

### Step 7.5 — Configure the Webhook in Meta

1. Go back to the Meta Developer Console → your app → **WhatsApp → Configuration**.
2. Under **Webhook**, click **Edit**:
   - **Callback URL:** `https://your-domain.com/webhooks/whatsapp/<your-phone-number-id>`
   - **Verify Token:** paste the token shown in Chatwoot
3. Click **Verify and Save**.
4. Under **Webhook Fields**, click **Manage** and make sure `messages` is subscribed.

### Step 7.6 — Test WhatsApp

Send a message from any WhatsApp account to your business number. It should appear as a new conversation in your Chatwoot inbox within seconds.

> **Important:** While your Meta app is in **Development** mode, only numbers explicitly added as test users in the Meta Developer Console can send messages to you. To receive messages from anyone, you need to submit your app for **Business Verification** and go through Meta's review process.

---

## Part 8 — Optional: Configure Email as an Inbox

In addition to using email for transactional notifications (Part 5), you can add an **email inbox** in Chatwoot so that customer emails appear as conversations.

1. Go to **Settings → Inboxes → Add Inbox → Email**.
2. Enter your email inbox name and the email address you want customers to use (e.g., `support@your-domain.com`).
3. Chatwoot will give you a **forwarding address** (looks like `abc123@chatwoot.io` for cloud, or your domain for self-hosted).
4. In your email provider (Gmail, Zoho, etc.), set up **forwarding** or a **routing rule** to forward incoming mail to that address.
5. For **sending replies**, the SMTP configuration from Part 6 is used automatically.

---

## Part 9 — Maintenance & Updates

### Updating Chatwoot

In Dokploy, go to the Chatwoot service and click **Redeploy** — it will pull the latest `chatwoot/chatwoot:latest` image. After redeploying, run the database migrations:

```bash
docker exec -it <rails_container_name> bundle exec rails db:chatwoot_prepare
```

### Updating Dokploy

```bash
docker pull dokploy/dokploy:latest
docker restart dokploy
```

### Backing Up Data

Dokploy supports volume backups. Go to **Settings → Backups** in Dokploy and configure a schedule pointing to S3, Cloudflare R2, or a local path. The critical volumes to back up are:
- `chatwoot_postgres` (all conversation data)
- `chatwoot_storage` (uploaded files and attachments)

> **Recommended backup schedule:** Daily backups with 30-day retention, stored off-site (e.g., Cloudflare R2 or S3).

---

## Troubleshooting

**Chatwoot shows "Bad Gateway" or doesn't load**
- Check that the `rails` container is running: `docker ps | grep rails`
- Check rails logs: `docker logs <rails_container_name> --tail 50`
- Verify the domain in Dokploy is set to port `3000` with HTTPS disabled

**Cloudflare Tunnel shows "offline"**
- Check cloudflared logs in Dokploy: the container should show `Connection established`
- Verify the `TUNNEL_TOKEN` environment variable matches the token from the Cloudflare dashboard
- Make sure `network_mode: host` is set on the cloudflared service

**Email not sending**
- Check Sidekiq is running: `docker ps | grep sidekiq`
- From the Rails console: `ActionMailer::Base.mail(to: "test@example.com", subject: "test", body: "test").deliver_now`

**WhatsApp messages not arriving**
- Check that the webhook in Meta is verified (green checkmark)
- Ensure `FRONTEND_URL` in your .env starts with `https://` and matches your exact domain
- Make sure the webhook URL format is exactly: `https://your-domain.com/webhooks/whatsapp/<phone-number-id>`

**Can't access `/super_admin`**
- The SuperAdmin account is completely separate from regular accounts — you must create it via the Rails console as shown in Part 5
- Navigate to `https://your-domain.com/super_admin` (not `/auth/sign_in`)
