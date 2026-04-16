component extends="coldbox.system.Interceptor" {

    property name="async"      inject="asyncManager@coldbox";
    property name="bugService" inject="provider:services.bug";

    function configure() {
    }

    /**
     * Interceptor point before mail is sent
     */
    function preMailSend(event, data, buffer, rc, prc) {
        // Change the subject and mailer if we are on development/test
        if(getSetting('environment') != 'production') {
            data.mail.setMailer('devFiles');
            data.mail.setSubject('[TESTING]  #data.mail.getSubject()#');
        }
    }

    /**
     * Interceptor point after mail is sent
     */
    function postMailSend(event, data, buffer, rc, prc) {
        if(data.result.error) {
            // Log bug
            prc.bugDetail = {
                ip       : '-1',
                event    : 'cbMailQueue',
                message  : 'Failed to send email',
                stack    : data.result,
                trainerid: -1
            };

            async.newFuture(() => {
                bugService.log(argumentCollection = prc.bugDetail);
            });
        }
    }

}
