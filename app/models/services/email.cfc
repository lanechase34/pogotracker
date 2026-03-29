component singleton accessors="true" {

    property name="contactEmail" inject="coldbox:setting:contactEmail";
    property name="mailService"  inject="MailService@cbmailservices";

    /**
     * Verify successful connection to the mail server - same functionality as admin page
     */
    public boolean function verifyConnection() {
        var env = new coldbox.system.core.delegates.Env();

        try {
            admin action = 'verifyMailServer'
            type         = 'server'
            password     = '#env.getEnv('CFCONFIG_ADMINPASSWORD')#'
            hostname     = '#env.getEnv('EMAIL_SERVER')#'
            port         = '#env.getEnv('EMAIL_PORT')#'
            mailusername = '#env.getEnv('EMAIL_USERNAME')#'
            mailpassword = '#env.getEnv('EMAIL_PASSWORD')#';

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
            .newMail(to: getContactEmail(), subject: 'User Submitted Feedback')
            .setView(
                view: 'email/contact',
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
            .newMail(to: getContactEmail(), subject: 'BUG Found')
            .setView(
                view: 'email/bug',
                args: {
                    error         : arguments.error,
                    sessionData   : session,
                    requestContext: arguments.requestContext,
                    cookieData    : cookie
                }
            )
            .queue();
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
            .newMail(to: arguments.email, subject: 'Reset POGO Tracker Password')
            .setView(
                view: 'email/resetpassword',
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
            .newMail(to: arguments.email, subject: 'POGO Tracker Verification Code')
            .setView(
                view: 'email/verificationcode',
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
            .newMail(to: getContactEmail(), subject: 'Sending a test email!')
            .setBody('
                Sending an email from the testing server! #now()# #createUUID()#
            ')
            .send();
    }

}
