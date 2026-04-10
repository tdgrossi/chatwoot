# Chatwoot Local Deployment Guide

**Target:** Ubuntu laptop + Dockploy (free) + Cloudflare tunnel + chat.escolaativa.com.br
**Date:** 2026-04-10

> **Important:** Dockploy.com is currently unreachable. This guide uses Docker + Cloudflare tunnel as the deployment method. If Dockploy becomes available, you can adapt Step 3 accordingly.

---

## Prerequisites

- Ubuntu 22.04 LTS (or 24.04 LTS) installed on laptop
- Domain: `chat.escolaativa.com.br` managed in Cloudflare
- Internet connection for initial setup
- At least 4GB RAM and 20GB disk space

---

## Step 1: Ubuntu Laptop Setup

### 1.1 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Install Required Packages

```bash
sudo apt install -y curl wget git unzip ca-certificates gnupg lsb-release
```

### 1.3 Install Docker

```bash
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (avoids needing sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### 1.4 Verify Docker

```bash
docker --version
docker compose version
```

---

## Step 2: Clone Chatwoot Repository

On your Ubuntu laptop:

```bash
# Clone Chatwoot (if you want the latest from GitHub)
git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot

# Or if you want to use your existing cloned repo from this machine,
# copy the chatwoot folder to your Ubuntu laptop via USB/network
```

---

## Step 3: Configure Chatwoot Environment

### 3.1 Copy Environment Template

```bash
cp .env.example .env
```

### 3.2 Generate Secret Key Base

```bash
# Option A: If Ruby/Rails is installed
rails secret

# Option B: Generate manually
openssl rand -hex 64
```

### 3.3 Edit `.env` File

Edit these essential variables:

```bash
nano .env  # or your preferred editor
```

**Required changes:**

```env
# Application
RAILS_ENV=production
NODE_ENV=production
FRONTEND_URL=https://chat.escolaativa.com.br

# Secret (generate with `openssl rand -hex 64`)
SECRET_KEY_BASE=<your-generated-key>

# Database
POSTGRES_HOST=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<choose-a-strong-password>
POSTGRES_DB=chatwoot

# Redis
REDIS_PASSWORD=<choose-a-strong-password>

# Docker installation
INSTALLATION_ENV=docker

# Email (configure your SMTP - required for sending emails)
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
SMTP_DOMAIN=chat.escolaativa.com.br

# Storage (optional - for file uploads)
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_REGION=us-east-1
# S3_BUCKET_NAME=chatwoot-uploads

# Disable account creation from dashboard (security)
ENABLE_ACCOUNT_SIGNUP=false
```

### 3.4 Configure PostgreSQL Password in docker-compose.production.yaml

Edit `docker-compose.production.yaml`:

```yaml
postgres:
  # ... existing config ...
  environment:
    - POSTGRES_DB=chatwoot
    - POSTGRES_USER=postgres
    - POSTGRES_PASSWORD=<must-match-.env>
```

### 3.5 Configure Redis Password

Make sure `.env` has:
```env
REDIS_PASSWORD=<choose-a-strong-password>
```

And in `docker-compose.production.yaml`, the redis service already reads from `.env`:
```yaml
redis:
  # ...
  command: ["sh", "-c", "redis-server --requirepass \"$REDIS_PASSWORD\""]
  env_file: .env
```

---

## Step 4: Start Chatwoot with Docker

### 4.1 Start All Services

```bash
docker compose -f docker-compose.production.yaml up -d
```

### 4.2 Check Service Status

```bash
docker compose -f docker-compose.production.yaml ps
```

### 4.3 View Logs

```bash
# Rails logs
docker compose -f docker-compose.production.yaml logs rails

# Sidekiq logs (background jobs)
docker compose -f docker-compose.production.yaml logs sidekiq

# All logs
docker compose -f docker-compose.production.yaml logs -f
```

### 4.4 Verify Services Are Running

```bash
# Check if Rails is responding
curl http://localhost:3000/api/v1/health

# Check if all containers are healthy
docker ps
```

Expected output should show 4 containers: rails, sidekiq, postgres, redis — all running.

---

## Step 5: Set Up Cloudflare Tunnel

Since your laptop is on a local network (not publicly accessible), you need a Cloudflare tunnel to expose it via `chat.escolaativa.com.br`.

### 5.1 Install cloudflared on Ubuntu

```bash
# Download cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

# Install
sudo dpkg -i cloudflared.deb

# Verify
cloudflared --version
```

### 5.2 Create Cloudflare Tunnel

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click **Create a tunnel**
4. Select **Cloudflared** as connector
5. Name the tunnel: `chatwoot-local`
6. Save the tunnel
7. Note the **Tunnel UUID** and **Connector token**

### 5.3 Configure cloudflared

On your Ubuntu laptop, create the config file:

```bash
mkdir -p ~/.cloudflared
nano ~/.cloudflared/config.yml
```

Add this content:

```yaml
tunnel: <YOUR-TUNNEL-UUID>
credentials-file: /root/.cloudflared/<YOUR-TUNNEL-UUID>.json

ingress:
  - hostname: chat.escolaativa.com.br
    service: http://localhost:3000
    originRequest:
      noTLSVerify: true
  - service: http_status:404
```

### 5.4 Run the Tunnel

```bash
# Authenticate (will open browser)
cloudflared tunnel login

# Run the tunnel
cloudflared tunnel run chatwoot-local
```

### 5.5 Set Up DNS in Cloudflare

1. In Cloudflare Dashboard, go to your domain **escolaativa.com.br**
2. Navigate to **DNS** → **Records**
3. Add a new CNAME record:
   - **Type:** CNAME
   - **Name:** chat
   - **Target:** `<YOUR-TUNNEL-UUID>.cfargotunnel.com`
   - **Proxy status:** Proxied (orange cloud)
   - **TTL:** Auto

### 5.6 Test the Tunnel

Visit `https://chat.escolaativa.com.br` in your browser. You should see the Chatwoot onboarding page.

---

## Step 6: Complete Chatwoot Setup (Superadmin)

### 6.1 Access the Onboarding Wizard

Visit `https://chat.escolaativa.com.br` (or `http://localhost:3000` if accessing locally).

### 6.2 Create Superadmin Account

Fill in the onboarding form:
- **Company Name:** Escola Ativa (or your choice)
- **Your Name:** Your name
- **Work Email:** Your email
- **Password:** Strong password

Click **Install**.

This creates:
- A SuperAdmin user (accesses `/super_admin` dashboard)
- Your first Account (organization)
- Default inbox

### 6.3 Access Superadmin Dashboard

After onboarding:
1. Log in with your superadmin credentials
2. Visit `https://chat.escolaativa.com.br/super_admin`
3. You can manage:
   - Users
   - Accounts
   - Installation configs
   - And more

---

## Step 7: (Optional) Run Cloudflare Tunnel as a Service

To keep the tunnel running after reboot:

```bash
# Install as systemd service
sudo cloudflared service install

# Start the service
sudo systemctl start cloudflared

# Enable on boot
sudo systemctl enable cloudflared

# Check status
sudo systemctl status cloudflared
```

---

## Step 8: Post-Deployment Checklist

### Verify Everything Works

- [ ] Chatwoot loads at `https://chat.escolaativa.com.br`
- [ ] Superadmin dashboard accessible at `/super_admin`
- [ ] Can create users and accounts
- [ ] Email sending works (check SMTP)
- [ ] Cloudflare tunnel stays connected

### Security Recommendations

1. **Enable SSL:** Cloudflare provides free SSL (already enabled via proxy)
2. **Firewall:** Configure UFW to only allow ports 22 (SSH) and block others
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```
3. **Regular backups:** Back up the PostgreSQL data volume
   ```bash
   docker compose -f docker-compose.production.yaml exec postgres pg_dump -U postgres chatwoot > backup.sql
   ```

### Common Commands

```bash
# Restart Chatwoot
docker compose -f docker-compose.production.yaml restart

# Update Chatwoot to latest
git pull
docker compose -f docker-compose.production.yaml pull
docker compose -f docker-compose.production.yaml up -d

# View logs
docker compose -f docker-compose.production.yaml logs -f rails

# Open Rails console
docker compose -f docker-compose.production.yaml exec rails bundle exec rails console

# Run migrations
docker compose -f docker-compose.production.yaml exec rails bundle exec rails db:migrate
```

---

## Troubleshooting

### "Connection refused" on localhost:3000

Check if containers are running:
```bash
docker ps
docker compose -f docker-compose.production.yaml logs rails
```

### Cloudflare tunnel not connecting

```bash
cloudflared tunnel run chatwoot-local --loglevel debug
```

### Superadmin access lost

Create a superadmin via Rails console:
```bash
docker compose -f docker-compose.production.yaml exec rails bundle exec rails console
```

Then:
```ruby
user = User.new(name: 'Admin', email: 'admin@escolaativa.com.br', password: 'Password123!', type: 'SuperAdmin')
user.skip_confirmation!
user.save!
exit
```

---

## About Dockploy

**Note:** Dockploy.com was unreachable at the time of writing this guide. The Docker + Cloudflare tunnel approach above achieves the same result:
- Containerized deployment
- Public URL via Cloudflare
- No port forwarding needed

If Dockploy becomes available, you would:
1. Install Dockploy CLI on Ubuntu
2. Connect Dockploy to your Cloudflare account
3. Deploy the Chatwoot Docker image
4. Configure routing to `chat.escolaativa.com.br`

---

*Last updated: 2026-04-10*
