## Github Actions

- Testing workflow `test.yml`
- Deploy workflow `deploy.yml` - run manually from the Actions tab (`workflow_dispatch`, repo owner only)

### Deploy Flow

`deploy.yml` builds on the runner and rsyncs `app/` to `/var/www/wwwroot/pogotracker/`:

1. Rsync `config/` to `/tmp/nginx-deploy/`, copy `nginx.conf`, `site.conf` (`sites-available/pogotracker.app`), and `security_headers.conf` into `/etc/nginx`, then `nginx -t` and reload
2. Build assets in `app/includes` - `npm ci` (its postinstall runs `buildProfanity`, writing `assets/profanity.json`), `npm run minJS`, `npm run minCSS`. `includes/build/` and `profanity.json` are gitignored, so they only exist from this build
3. Rsync `./app/` with `--delete-after`
    - Never sent or deleted: `.env`, `includes/uploads/`, `includes/sitemap.xml`, `coldbox/`, `modules/`
    - Sent, but server only files are kept: `version.html`, `includes/images/`, `includes/assets/`
    - Dev only, removed from the server: frontend sources/tooling (`includes/js/*` except `vendor/`, `includes/css/`, `package*.json`, `includes/scripts/`, ...), `handlers/dev.cfc`, `views/dev/`, `tests/`, `database/seeds/`, `_testemails/`
4. Write the deploy date to `version.html`, then run `sudo box recipe scripts/deploy.boxr` in the site dir

    ```
    server stop
    install --production
    migrate up
    server start
    ```

5. Reload nginx so `open_file_cache` can't serve stale files under the new cacheBuster

### NGINX

- Test current configuration `sudo nginx -t`
- Reload configuration `sudo systemctl reload nginx`

## Server Setup

Stack:

- Ubuntu 24.04
- Nginx Web Server
- UWF
- Cloudflare

1.  Setup

    ```
    sudo apt-get update
    sudo apt upgrade
    sudo apt install gufw
    sudo apt install default-jdk

    sudo apt install nginx
    sudo apt install ufw
    ```

2.  UFW Set up

    Allow ports 80 (http), 443 (https), and 22 (ssh)

    ```
    sudo ufw allow OpenSSH
    sudo ufw allow 'Nginx HTTPS'
    ```

    Block port running on commandbox, this uses `8081`

    ```
    sudo ufw deny 8081
    ```

3.  Nginx Set up

    Listen to both http, https traffic. Redirect all http traffic to https.
    Listen for server name pogotracker.app, on match, reverse proxy to commandbox using port `8081`.
    Cloudflare origin cert and private key are stored in /etc/nginx/ssl/pogotracker

    Set up the following config for pogotracker `/etc/nginx/sites-available/pogotracker.app`

    `config/nginx.conf` for nginx.conf

    `config/site.conf` for sites-available/pogotracker.app

4.  Enable the site in nginx

    ```
    sudo ln -s /etc/nginx/sites-available/pogotracker.app /etc/nginx/sites-enabled/
    ```

5.  Install Imagmagick

    Ubuntu 24.04 install steps. This includes HEIC format support

    ```
    # Remove bundled ImageMagick

    sudo apt remove imagemagick -y

    # Install image dependencies

    sudo apt-get install -y \
    pkg-config \
    build-essential \
    libltdl-dev \
    libheif-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev

    # Clone source

    cd /usr/local/src
    sudo git clone --depth 1 --branch 7.1.0-54 https://github.com/ImageMagick/ImageMagick.git /usr/local/src/ImageMagick
    cd /usr/local/src/ImageMagick

    # Configure

    sudo ./configure \
    --with-modules \
    --with-heic=yes \
    --with-png=yes \
    --with-jpeg=yes \
    --with-webp=yes

    # Build

    sudo make
    sudo make install
    sudo ldconfig /usr/local/lib

    # Check install

    identify --version
    convert -list format

    # Enforce maximum security policy

    cd /usr/local/etc/ImageMagick-7
    sudo rm policy.xml
    sudo wget -O policy.xml https://imagemagick.org/source/policy-websafe.xml

    # Allow png, jpeg, webp, and heic files

    sudo nano policy.xml

    <policy domain="resource" name="time" value="30"/>
    <policy domain="resource" name="width" value="8KP"/>
    <policy domain="resource" name="height" value="8KP"/>
    <policy domain="module" rights="read|write" value="{JPEG,PNG,WEBP,HEIC}"/>

    ```

6.  Install commandbox per commandbox docs

7.  Set up webroot directory

    ```
    cd /var/www/
    sudo mkdir wwwroot
    ```

8.  Create the site dir and send the code with the Manual Deploy steps 1-2 above (the server is not a git checkout)

    `sudo mkdir /var/www/wwwroot/pogotracker`

9.  Make and modify env as needed in `/var/www/wwwroot/pogotracker`

    ```
    sudo touch .env
    sudo nano .env
    ```

10. Grant read/write to server.json

    `sudo chmod u+w server.json`

11. Start commandbox and init dependencies

    > **WARNING:** never run `migrate fresh` on the server. It drops every table and reruns all migrations, wiping all production data. A new database only needs `migrate install` + `migrate up`.

    ```
    sudo box
    update --system
    install --production
    migrate install
    migrate up
    dotenv check
    server start
    ```
