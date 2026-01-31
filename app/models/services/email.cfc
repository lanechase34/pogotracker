component singleton accessors="true" {

    property name="mailService" inject="MailService@cbmailservices";

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

    public void function sendContact(
        required string email,
        required string subject,
        required string message
    ) {
        mailService
            .newMail(to: application.cbController.getSetting('contactEmail'), subject: 'User Submitted Feedback')
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

    public void function sendBug(required struct error, required struct requestContext) {
        mailService
            .newMail(to: application.cbController.getSetting('contactEmail'), subject: 'BUG Found')
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

    public void function sendTestEmail() {
        mailService
            .newMail(to: application.cbController.getSetting('contactEmail'), subject: 'Sending a test email!')
            .setBody('
                Sending an email from the testing server! #now()# #createUUID()#
            ')
            .send();
    }

}
