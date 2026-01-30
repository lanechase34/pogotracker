## Github Actions

- Testing workflow `test.yml`
- Deploy workflow `deploy.yml`

## Manual Deploy

1. Start commandbox

    `sudo box`

2. Go to apache web hosting root on ubuntu

    `cd /var/www/wwwroot/pogotracker`

3. Stop POGOTracker Site

    `server stop`

4. Pull latest changes

    `sudo git pull`

5. Enter username and github access token

    If codebase has changes on server try the following

    ```
    git restore .
    git reset --hard
    ```

6. Check and remove any dev only dirs/files

    ```
    ls -l
    sudo rm -r tests
    sudo rm package.json package-lock.json
    ```

7. Start the site

    `server start`

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

8.  Clone site into wwwroot

    `sudo git clone ${url}`

9.  Make and modify env as needed

    ```
    sudo touch .env
    sudo nano .env
    ```

10. Grant read/write to server.json

    `sudo chmod u+w server.json`

11. Start commandbox and init dependencies

    ```
    sudo box
    update --system
    install --production
    migrate fresh # only run once - this initializes the database
    migrate up
    dotenv check
    server start
    ```
