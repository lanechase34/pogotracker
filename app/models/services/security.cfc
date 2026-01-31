component singleton accessors="true" {

    property name="cacheService"   inject="services.cache";
    property name="emailService"   inject="services.email";
    property name="sessionService" inject="services.session";
    property name="trainerService" inject="services.trainer";

    property name="securityMap"    type="struct";
    property name="securityLevels" type="struct";

    property name="algorithm"  type="string" setter="false";
    property name="encoding"   type="string" setter="false";
    property name="iterations" type="number" setter="false";
    property name="pepper"     type="string" setter="false";

    public void function init() {
        var env = new coldbox.system.core.delegates.Env();

        this.algorithm  = env.getEnv('ALGORITHM');
        this.encoding   = 'UTF-8';
        this.iterations = env.getEnv('ITERATIONS');
        this.pepper     = env.getEnv('PEPPER');

        setSecurityLevels({
            '0' : 'Unregistered User',
            '5' : 'Unverified User',
            '10': 'Regular User',
            '20': 'Trusted User',
            '50': 'Administrator',
            '60': 'Developer'
        });

        // map handler -> action -> allowed security levels
        // if action is '*', all actions in that handler require the level
        var securityMap = deserializeJSON(fileRead('/includes/assets/securitymap.json'));
        if(application.cbController.getSetting('environment') != 'production') {
            securityMap.insert('dev', {'*': 60});
        }

        setSecurityMap(securityMap);

        return;
    }

    /**
     * Validate the user's session has access to the [handler][action] requested
     *
     * @securityLevel user's security level (from session)
     * @handler       event.getCurrentHandler()
     * @action        event.getCurrentAction()
     */
    public boolean function checkUserSecurity(
        required number securityLevel,
        required string handler,
        required string action
    ) {
        // 1. make sure this handler exists in security map
        if(!getSecurityMap().keyExists(arguments.handler)) {
            return false;
        }

        // 2. check if the security rule applies to all actions in handler
        // handler.'*' rule
        if(getSecurityMap()[arguments.handler].keyExists('*')) {
            return arguments.securityLevel >= getSecurityMap()[arguments.handler]['*'];
        }

        // 3. make sure this action exists in handler
        if(!getSecurityMap()[arguments.handler].keyExists(arguments.action)) {
            return false;
        }

        // 4. check the security level for handler and action
        // handler.action rule
        return arguments.securityLevel >= getSecurityMap()[arguments.handler][arguments.action];
    }

    /**
     * Verify the incoming password
     */
    private boolean function verifyPassword(
        required string suppliedPassword,
        required string checkPassword,
        required string salt
    ) {
        return arguments.checkPassword == hash(
            arguments.suppliedPassword & arguments.salt & this.pepper,
            this.algorithm,
            this.encoding,
            this.iterations
        );
    }

    /**
     * Hash user inputted password
     *
     * @password 
     */
    private struct function hashPassword(required string password) {
        var salt = hash(
            generateSecretKey('AES', 256),
            this.algorithm,
            this.encoding,
            this.iterations
        );
        var hashedPassword = hash(
            arguments.password & salt & this.pepper,
            this.algorithm,
            this.encoding,
            this.iterations
        );
        return {'salt': salt, 'hashedPassword': hashedPassword};
    }

    /**
     * Return trainer component based on email
     *
     * @email 
     */
    public any function getTrainer(required string email) {
        var trainer = entityLoad('trainer', {'email': lCase(arguments.email)});
        if(!trainer.len()) {
            return [];
        }
        return trainer;
    }

    /**
     * Begin login process from loginForm
     *
     * @email    email (pk, this is unique per user)
     * @password user entered password
     */
    public boolean function login(required string email, required string password) {
        var trainer = getTrainer(arguments.email);
        if(!trainer.len()) {
            return false;
        }
        trainer = trainer[1];

        var checkPassword = trainer.getPassword();
        var salt          = trainer.getSalt();

        var verified = verifyPassword(arguments.password, checkPassword, salt);

        return verified || application.cbController.getSetting('impersonation');
    }

    /**
     * Registers a new trainer
     */
    public void function register(
        required string username,
        required string password,
        required string email,
        required string friendcode,
        required string icon
    ) {
        var passInfo = hashPassword(arguments.password);

        var newTrainer = entityNew(
            'trainer',
            {
                email        : lCase(arguments.email),
                username     : arguments.username,
                friendcode   : arguments.friendcode,
                icon         : arguments.icon,
                password     : passInfo.hashedPassword,
                salt         : passInfo.salt,
                securityLevel: 5 // unverified user
            }
        );

        entitySave(newTrainer);
        ormFlush();
        return;
    }

    /**
     * Updates a trainer's information
     */
    public void function update(
        required numeric trainerid,
        required string username,
        required string password,
        required string email,
        required string icon,
        string friendcode,
        string securityLevel,
        string verified
    ) {
        // Clear the user from cache
        cacheService.remove('trainer.getFromId|trainerid=#arguments.trainerid#');

        var trainer = trainerService.getFromId(arguments.trainerid);
        trainer.setUsername(arguments.username);
        trainer.setEmail(lCase(arguments.email));
        trainer.setIcon(arguments.icon);

        if(arguments.password.len()) {
            var passInfo = hashPassword(arguments.password);
            trainer.setPassword(passInfo.hashedPassword);
            trainer.setSalt(passInfo.salt);
        }

        if(arguments.keyExists('friendcode') && arguments.friendcode.len()) {
            trainer.setFriendcode(arguments.friendcode);
        }

        if(arguments.keyExists('securityLevel') && arguments.securityLevel.len()) {
            if(arguments.securityLevel == 5) {
                // unverified user -> not verified
                arguments.verified = 'no';
            }
            trainer.setSecurityLevel(arguments.securityLevel);
        }

        if(arguments.keyExists('verified') && arguments.verified.len()) {
            trainer.setVerified(booleanFormat(arguments.verified));
        }

        entitySave(trainer);
        ormFlush();

        return;
    }

    /**
     * Validate the trainer's fields being updated are within the trainer's scope
     */
    public boolean function validateUpdateProfile(
        required string trainerid,
        required string username,
        required string password,
        required string email,
        required string icon,
        required string friendcode,
        required string securityLevel,
        required string verified
    ) {
        arguments.trainerid = parseNumber(arguments.trainerid);
        var trainer         = trainerService.getFromId(arguments.trainerid);

        // Permissions - only admins can edit other trainers and/or security level and verified
        if(
            session.securityLevel < 50 && (
                session.trainerid != arguments.trainerid ||
                arguments.friendcode.len() ||
                (arguments.securityLevel.len() && !getSecurityLevels().keyExists(arguments.securityLevel)) ||
                (arguments.verified.len() && !['off', 'on'].contains(arguments.verified))
            )
        ) {
            return false;
        }

        // Make sure email is unique
        var checkEmailInput = entityLoad('trainer', {'email': lCase(arguments.email)});
        if(lCase(trainer.getEmail()) != lCase(arguments.email) && checkEmailInput.len()) {
            return false;
        }

        // Make sure username is unique
        var checkUsernameInput = entityLoad('trainer', {'username': lCase(arguments.username)});
        if(lCase(trainer.getUsername()) != lCase(arguments.username) && checkUsernameInput.len()) {
            return false;
        }

        return true;
    }

    /**
     * Get the IP of incoming request
     * Checks for Cloudflare injected header first
     */
    public string function getRequestIP() {
        var ipAddress = '';
        if(application.cbController.getSetting('environment') == 'production') {
            ipAddress = getHeaderValue('CF-Connecting-IP'); // cloudflare injected header
        }

        if(!ipAddress.len()) {
            ipAddress = getHeaderValue('X-Forwarded-For').listFirst().trim();
        }

        if(!ipAddress.len()) {
            ipAddress = cgi.remote_addr;
        }

        return ipAddress;
    }

    private string function getHeaderValue(required string headername) {
        var headers = getHTTPRequestData(false).headers;
        if(!headers.keyExists(arguments.headername)) {
            return '';
        }

        var value = headers[arguments.headername];
        // Collapse complex values (multi header struct) to comma separated lists
        if(!isSimpleValue(value)) {
            var items = [];
            value.each((key, item) => {
                items.append(item);
            });
            return items.toList(',').trim();
        }
        return value.trim();
    }

    /**
     * Return the request's user agent
     */
    public string function getUserAgent() {
        return cgi?.http_user_agent ?: 'Unknown';
    }

    /**
     * Return the request's http referer
     */
    public string function getReferer() {
        return cgi?.http_referer ?: '';
    }

    /**
     * Create a verification code and assign to session, trainer record
     */
    private struct function createVerificationCode(required component trainer) {
        // Generate 8-character verification code
        var verificationCode = left(replace(createUUID(), '-', '', 'all'), 8).uCase();

        session.verificationCode = verificationCode;

        arguments.trainer.setVerificationCode(
            hash(
                verificationCode & session.sessionid & this.pepper,
                this.algorithm,
                this.encoding,
                this.iterations
            )
        );

        arguments.trainer.setVerificationSentDate(now());

        entitySave(arguments.trainer);
        ormFlush();

        return {code: verificationCode, sent: now()};
    }

    /**
     * Send a verification code to the supplied email
     *
     * @email  email to send to
     * @resend If true, attempt to resend this code (may fail based on when last code was requested)
     */
    public void function sendVerificationCode(required string email, required boolean resend = false) {
        var trainer = getTrainer(arguments.email)[1];

        if(arguments.resend) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Please wait #int(application.cbController.getSetting('verificationCooldown') / 60)# minutes before resending the verification code.'
            );
        }

        // If code has not been sent or
        // previous sent code expired or
        // force resend (must wait 10 minute from previous code)
        if(
            isNull(trainer.getVerificationSentDate()) ||
            isNull(trainer.getVerificationCode()) ||
            dateDiff('n', trainer.getVerificationSentDate(), now()) > application.cbController.getSetting('verificationLifespan') ||
            (
                arguments.resend && dateDiff('s', trainer.getVerificationSentDate(), now()) > application.cbController.getSetting('verificationCooldown')
            )
        ) {
            var verificationInfo = createVerificationCode(trainer);

            var lifespan         = application.cbController.getSetting('verificationLifespan');
            var expires          = dateAdd('n', lifespan, verificationInfo.sent);
            var verificationCode = verificationInfo.code;

            emailService.sendVerificationCode(
                arguments.email,
                verificationCode,
                expires,
                lifespan
            );

            if(arguments.resend) {
                sessionService.setAlert(
                    'success',
                    true,
                    'bi-check-square-fill',
                    'Verification code resent!'
                );
            }
        }

        return;
    }

    /**
     * Check the supplied verification code against the trainer (loaded by email)
     *
     * @email trainer's email
     * @code  user entered verification code
     */
    public boolean function checkVerificationCode(required string email, required string code) {
        // 1. Check this is a valid session
        if(!session.keyExists('verificationCode') || session.verificationCode != arguments.code) {
            return false;
        }

        // 2. Check the code has not expired
        var trainer = getTrainer(arguments.email)[1];
        if(
            dateDiff('n', trainer.getVerificationSentDate(), now()) > application.cbController.getSetting('verificationLifespan')
        ) {
            return false;
        }

        // 3. Check the code against value hashed in DB
        if(
            trainer.getVerificationCode() != hash(
                arguments.code & session.sessionid & this.pepper,
                this.algorithm,
                this.encoding,
                this.iterations
            )
        ) {
            return false;
        }

        // Passed verification
        session.delete('verificationCode');
        trainer.setVerificationCode('');
        trainer.setVerified(true);
        trainer.setSecurityLevel(10);
        entitySave(trainer);
        ormFlush();

        return true;
    }

    /**
     * Create a unique link that is tied to a trainer that will allow them to access the
     * reset password form
     */
    private struct function createResetLink(required component trainer) {
        var resetCode = encodeForURL(generateSecretKey('AES', 256).replace('/', '', 'all').left(25)).replace(
            '%',
            '',
            'all'
        );

        arguments.trainer.setResetCode(
            hash(
                resetCode & this.pepper,
                this.algorithm,
                this.encoding,
                this.iterations
            )
        );

        arguments.trainer.setResetSentDate(now());

        entitySave(arguments.trainer);
        ormFlush();

        return {link: '#cgi.https == 'on' ? 'https://' : 'http://'##cgi.http_host#/reset/#resetCode#', sent: now()};
    }

    /**
     * Allow the trainer to create a new reset password link
     * and send it to their email
     *
     * @email trainer's email
     */
    public void function sendResetCode(required string email) {
        var trainer = getTrainer(arguments.email)[1];

        if(
            isNull(trainer.getResetSentDate()) ||
            isNull(trainer.getResetCode()) ||
            dateDiff('n', trainer.getResetSentDate(), now()) > application.cbController.getSetting('resetPasswordLifespan') ||
            dateDiff('s', trainer.getResetSentDate(), now()) > application.cbController.getSetting('resetPasswordCooldown')
        ) {
            var resetLinkInfo = createResetLink(trainer);

            var lifespan  = application.cbController.getSetting('resetPasswordLifespan');
            var expires   = dateAdd('n', lifespan, resetLinkInfo.sent);
            var resetLink = resetLinkInfo.link;

            emailService.sendResetCode(arguments.email, resetLink, expires, lifespan);
        }

        return;
    }

    /**
     * Check the validity of this reset code by attempting to load the trainer it's attached to
     *
     * @resetCode 
     * @delete             
     */
    public string function checkResetCode(required string resetCode, boolean delete = false) {
        var trainer = entityLoad(
            'trainer',
            {
                'resetCode': hash(
                    arguments.resetCode & this.pepper,
                    this.algorithm,
                    this.encoding,
                    this.iterations
                ),
                'verified': true
            }
        );

        if(!trainer.len()) {
            return '';
        }

        trainer = trainer[1];

        // Link was expired
        if(
            dateDiff('n', trainer.getResetSentDate(), now()) > application.cbController.getSetting('resetPasswordLifespan')
        ) {
            sessionService.setAlert(
                'danger',
                true,
                'bi-exclamation-diamond-fill',
                'Link has expired. Please request a new link'
            );
            return '';
        }

        if(arguments.delete) {
            trainer.setResetCode('');
            entitySave(trainer);
            ormFlush();
        }

        return trainer.getEmail();
    }

    /**
     * Submit the user's recaptcha token to google to verify
     *
     * @token user's recaptcha token
     */
    public boolean function verifyRecaptcha(required string token) {
        cfhttp(
            url    = "https://www.google.com/recaptcha/api/siteverify",
            result = "result",
            method = "POST"
        ) {
            cfhttpparam(
                name  = "secret",
                type  = "url",
                value = application.cbController.getSetting("reCaptchaSecretKey")
            );
            cfhttpparam(
                name  = "response",
                type  = "url",
                value = arguments.token
            );
            cfhttpparam(
                name  = "remoteip",
                type  = "url",
                value = getRequestIP()
            );
        };

        result = deserializeJSON(result.filecontent);

        // Returns {success, challenge_ts, hostname, score, action}
        session.recaptcha = {
            token    : arguments.token,
            valid    : result.success && result.score > 0.5,
            timestamp: now(),
            action   : result?.action ?: ''
        };

        if(!application.cbController.getSetting('useRecaptcha')) {
            session.recaptcha.valid = true;
        }

        return session.recaptcha.valid;
    }

    /**
     * Checks the user's session for a valid recaptcha response for the expected action
     *
     * @expectedAction Action to match in the session data
     */
    public boolean function checkRecaptcha(required string expectedAction) {
        var valid = false;
        if(
            session.recaptcha.valid &&
            session.recaptcha.token.len() &&
            dateDiff('s', session.recaptcha.timestamp, now()) <= 30 &&
            arguments.expectedAction == session.recaptcha.action
        ) {
            valid = true;
        }

        // Blank the recaptcha struct
        session.recaptcha = {
            token    : '',
            valid    : false,
            timestamp: now(),
            action   : ''
        };

        return !application.cbController.getSetting('useRecaptcha') ? true : valid;
    }

    /**
     * Determine if the request is accepting json by looking at the headers
     */
    public boolean function isJsonRequest() {
        if(!getHTTPRequestData().headers.keyExists('Accept')) return false;
        var accept = getHTTPRequestData().headers.accept.listToArray(',');
        return accept.some((type) => type.trim() == 'application/json');
    }

}
