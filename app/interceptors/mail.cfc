component extends="coldbox.system.Interceptor" {

    function configure() {
    }

    function preMailSend(event, data, buffer, rc, prc) {
        // Change the subject and mailer if we are on development/test
        if(getSetting('environment') != 'production') {
            data.mail.setMailer('devFiles');
            data.mail.setSubject('[TESTING]  #data.mail.getSubject()#');
        }
    }

    function postMailSend(event, data, buffer, rc, prc) {
        if(data.result.error) {
        }
    }

}
