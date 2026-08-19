# MyCloud Stack (Seafile + Immich)

A complete, production-ready private cloud stack for self-hosting personal files, documents, photos, and videos.

This stack provisions:
- **Seafile**: Enterprise-grade file synchronization, sharing, and WebDAV server.
- **Seafile MariaDB & Memcached**: High-performance caching and database backend for Seafile.
- **Immich**: High-performance photo and video management (Google Photos alternative) with automated backup, facial recognition, and CLIP search.
- **Immich PostgreSQL (pgvector), Redis, & Machine Learning**: Dedicated vector database, cache, and ML runtime.

---

## 🚀 Quick Start

### 1. Configure Environment
Copy the example environment file:
```bash
cp .env.example .env
```
Open `.env` and configure your credentials, base data directory, and domain/IP settings:
- Generate strong database passwords (`openssl rand -hex 16`).
- Set `DATA_DIR` to your preferred host storage path (e.g., `/srv/data/mycloud`).
- Set `MYCLOUD_IP` (`127.0.0.1` for reverse proxy setups or `0.0.0.0` for direct network binding).

### 2. Initialize Host Storage Directories
```bash
chmod +x setup_volumes.sh
./setup_volumes.sh
```

### 3. Start the Stack
```bash
docker compose up -d
```

### 4. Access Web Interfaces
- **Seafile Web UI**: `http://<YOUR_SERVER_IP>:9085` (or via configured domain)
- **Immich Web UI**: `http://<YOUR_SERVER_IP>:2283` (or via configured domain)

---

## 📧 Email Notifications Setup (SMTP / Gmail)

To enable email notifications (password resets, invitations, alerts), use an SMTP provider or **Google App Password** (16 characters).

### 1. Seafile SMTP Configuration
Seafile stores its runtime configuration inside the data volume. After the container boots for the first time:

1. Edit `seahub_settings.py`:
   ```bash
   nano <DATA_DIR>/seafile/data/seafile/conf/seahub_settings.py
   ```
2. Add your SMTP configuration:
   ```python
   EMAIL_USE_TLS = True
   EMAIL_HOST = 'smtp.gmail.com'
   EMAIL_HOST_USER = 'your_email@gmail.com'
   EMAIL_HOST_PASSWORD = 'your_16_char_app_password'
   EMAIL_PORT = 587
   DEFAULT_FROM_EMAIL = EMAIL_HOST_USER
   SERVER_EMAIL = EMAIL_HOST_USER
   ```
3. Restart Seafile:
   ```bash
   docker compose restart seafile
   ```

### 2. Immich SMTP Configuration
Immich is configured entirely through the Web UI:
1. Log into the Immich Web UI as Administrator.
2. Navigate to **Administration** (gear icon) -> **Settings** -> **Notifications / Mail**.
3. Enter your SMTP Host (`smtp.gmail.com`), Port (`587`), Username, and App Password.
4. Click **Save** and test the connection.

---

## 🔌 Integrations & Features

### 1. WebDAV (SeafDAV)
To access Seafile libraries via WebDAV (compatible with Joplin, Rclone, Keepass, mobile sync apps):
1. Open the Seafile WebDAV configuration:
   ```bash
   nano <DATA_DIR>/seafile/data/seafile/conf/seafdav.conf
   ```
2. Ensure `enabled = true` under the `[WEBDAV]` section:
   ```ini
   [WEBDAV]
   enabled = true
   port = 8080
   fastcgi = false
   share_name = /seafdav
   ```
3. Restart the container:
   ```bash
   docker compose restart seafile
   ```
4. Access WebDAV at: `http://<SERVER_IP>:9085/seafdav` (or `https://<YOUR_DOMAIN>/seafdav`).

### 2. Two-Factor Authentication & App Passwords
If 2FA is enabled in Seafile, regular passwords will not work for WebDAV. Enable WebDAV app passwords:
1. Open `seahub_settings.py`:
   ```bash
   nano <DATA_DIR>/seafile/data/seafile/conf/seahub_settings.py
   ```
2. Append:
   ```python
   ENABLE_WEBDAV_SECRET = True
   WEBDAV_SECRET_MIN_LENGTH = 8
   ```
3. Restart Seafile (`docker compose restart seafile`). Users can now generate dedicated WebDAV passwords from their profile page.

### 3. OnlyOffice Document Editing Integration
To edit documents directly in the Seafile web UI using an OnlyOffice Document Server:
1. Open `seahub_settings.py`:
   ```bash
   nano <DATA_DIR>/seafile/data/seafile/conf/seahub_settings.py
   ```
2. Append:
   ```python
   ENABLE_ONLYOFFICE = True
   ONLYOFFICE_APIJS_URL = 'https://office.yourdomain.com/web-apps/apps/api/documents/api.js'
   ONLYOFFICE_FILE_EXTENSION = ('doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'odt', 'fodt', 'odp', 'fodp', 'ods', 'fods')
   ONLYOFFICE_EDIT_FILE_EXTENSION = ('docx', 'pptx', 'xlsx')
   ONLYOFFICE_JWT_SECRET = 'your_onlyoffice_jwt_secret'
   ```
3. Restart Seafile: `docker compose restart seafile`.

### 4. Create an Admin User via Command Line
If you ever need to reset or create an administrator account:
```bash
docker exec -it seafile /opt/seafile/seafile-server-latest/reset-admin.sh
```

### 5. Recommended Settings (`seahub_settings.py`)
Add these recommended tweaks to `<DATA_DIR>/seafile/data/seafile/conf/seahub_settings.py`:
```python
# Keep file revision history for 30 days (-1 for unlimited)
KEEP_HISTORY_DAYS = 30

# Disable public user registration for private homelab security
ENABLE_SIGNUP = False

# Keep users logged in for 30 days
LOGIN_REMEMBER_DAYS = 30
```

### 6. Automated Garbage Collection
Seafile marks deleted files as tombstoned. To physically free disk space on the host, run the garbage collector:
```bash
docker exec -it seafile /opt/seafile/seafile-server-latest/seaf-gc.sh
```
*(Recommended: Schedule this weekly via host cron job).*

---

## ⚠️ Important Gotchas

- **Cloudflare 100MB Proxy Limit:** If routing through Cloudflare Proxy (orange cloud), free accounts cap file uploads at 100MB. Use Cloudflare in DNS-only mode (gray cloud) or direct domain/Tailscale connections for large file and 4K video uploads.
- **Service URLs behind Reverse Proxy:** If using a reverse proxy (Caddy / Traefik / Nginx), ensure `SERVICE_URL` (`https://seafile.yourdomain.com`) and `FILE_SERVER_ROOT` (`https://seafile.yourdomain.com/seafhttp`) are configured in Seafile Admin Settings -> System Admin -> Settings.
