component singleton accessors="true" {

    property name="mailService" inject="MailService@cbmailservices";

    property name="contactEmail" inject="coldbox:setting:contactEmail";
    property name="mailServer" inject="coldbox:setting:mailServer" getter="false" setter="false";

    /**
     * Verify successful connection to the mail server - same functionality as admin page
     */
    public boolean function verifyConnection() {
        try {
            admin action = "verifyMailServer"
            type         = "server"
            password     = "#variables.mailServer.adminPassword#"
            hostname     = "#variables.mailServer.hostname#"
            port         = "#variables.mailServer.port#"
            mailusername = "#variables.mailServer.username#"
            mailpassword = "#variables.mailServer.password#";

            return true;
        }
        catch(any e) {
        }
        return false;
    }

    /**
     * Send a user contact email - contains feedback and email from user
     *
     * @email   User's email
     * @subject Email subject
     * @message Email content
     */
    public void function sendContact(
        required string email,
        required string subject,
        required string message
    ) {
        mailService
            .newMail(to: getContactEmail(), subject: "User Submitted Feedback")
            .setView(
                view: "email/contact",
                args: {
                    email  : arguments.email,
                    subject: arguments.subject,
                    message: arguments.message
                }
            )
            .queue();
    }

    /**
     * Send a bug error dump
     *
     * @error          The error struct
     * @requestContext The rc struct
     */
    public void function sendBug(required struct error, required struct requestContext) {
        mailService
            .newMail(to: getContactEmail(), subject: "BUG Found")
            .setView(
                view: "email/bug",
                args: {
                    error         : arguments.error,
                    sessionData   : redactSensitive(session),
                    requestContext: redactSensitive(arguments.requestContext),
                    // Cookie values are credentials (session, persist) - only send the names
                    cookieData    : cookie.keyList()
                }
            )
            .queue();
    }

    /**
     * Copy of a scope with credentials/tokens replaced so they never leave the server
     * Walks nested structs and arrays (json bodies land in the rc nested) - objects are left out, only their type is kept
     *
     * @data  struct, array or simple value to redact
     * @depth how deep we are - stops runaway recursion on self referencing data
     */
    private any function redactSensitive(required any data, numeric depth = 0) {
        var sensitive = "password|passwd|csrf|token|secret|resetcode|persistcookie|verificationcode|sessionid|jsessionid|cfid|cftoken|recaptcha|^code$";

        if(arguments.depth > 10) {
            return "[TRUNCATED]";
        }

        if(isArray(arguments.data)) {
            var depth = arguments.depth;
            return arguments.data.map((item) => redactSensitive(item ?: "", depth + 1));
        }

        if(isStruct(arguments.data) && !isObject(arguments.data)) {
            var result = {};
            for(var key in arguments.data) {
                result[key] = reFindNoCase(sensitive, key) ? "[REDACTED]" : redactSensitive(
                    arguments.data[key] ?: "",
                    arguments.depth + 1
                );
            }
            return result;
        }

        if(isObject(arguments.data)) {
            return "[#getMetadata(arguments.data).name ?: "object"#]";
        }

        return arguments.data;
    }

    /**
     * Send a password reset code to a user
     *
     * @email     User's email
     * @resetLink Link containing reset code
     * @expires   When link expires
     * @lifespan  The lifespan of link in minutes
     */
    public void function sendResetCode(
        required string email,
        required string resetLink,
        required date expires,
        required numeric lifespan
    ) {
        mailService
            .newMail(to: arguments.email, subject: "Reset POGO Tracker Password")
            .setView(
                view: "email/resetpassword",
                args: {
                    resetLink: arguments.resetLink,
                    expires  : arguments.expires,
                    lifespan : arguments.lifespan
                }
            )
            .send();
    }

    /**
     * Send a verification code to a user
     *
     * @email            User's email
     * @verificationCode The verification code
     * @expires          When code expires
     * @lifespan         The lifespan of code in minutes
     */
    public void function sendVerificationCode(
        required string email,
        required string verificationCode,
        required date expires,
        required numeric lifespan
    ) {
        mailService
            .newMail(to: arguments.email, subject: "POGO Tracker Verification Code")
            .setView(
                view: "email/verificationcode",
                args: {
                    email           : arguments.email,
                    verificationCode: arguments.verificationCode,
                    expires         : arguments.expires,
                    lifespan        : arguments.lifespan
                }
            )
            .send();
    }

    /**
     * Send a test email
     */
    public void function sendTestEmail() {
        mailService
            .newMail(to: getContactEmail(), subject: "Sending a test email!")
            .setBody("
                Sending an email from the testing server! #now()# #createUUID()#
            ")
            .send();
    }

}
