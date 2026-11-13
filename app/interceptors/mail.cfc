component extends="coldbox.system.Interceptor" {

    property name="async"        inject="asyncManager@coldbox";
    property name="auditService" inject="provider:services.audit";
    property name="bugService"   inject="provider:services.bug";

    /**
     * Interceptor point before mail is sent
     */
    function preMailSend(event, data, buffer, rc, prc) {
        // Change the subject and mailer if we are on development/test
        if(getSetting("environment") != "production") {
            data.mail.setMailer("devFiles");
            data.mail.setSubject("[TESTING]  #data.mail.getSubject()#");
        }
    }

    /**
     * Interceptor point after mail is sent
     */
    function postMailSend(event, data, buffer, rc, prc) {
        var failed = data.result.error;

        if(failed) {
            // Log bug
            var bugDetail = {
                ip       : "-1",
                event    : "cbMailQueue",
                message  : "Failed to send email",
                stack    : data.result,
                trainerid: -1
            };

            async.newFuture(() => {
                bugService.logBug(argumentCollection = bugDetail);
            });
        }

        try {
            // Audit and log on failure
            var context     = data.mail.getAdditionalInfoItem("audit", {});
            var auditDetail = {
                ip     : context.ip ?: "-1",
                event  : context.event ?: "email",
                referer: context.referer ?: "",
                agent  : context.agent ?: "",
                detail : left(
                    "#failed ? "Failed to email" : "Emailed"# #data.mail.getTo()#: #data.mail.getSubject()#",
                    250
                ),
                trainerid: val(context.trainerid ?: -1)
            };

            async
                .newFuture(() => {
                    auditService.audit(argumentCollection = auditDetail);
                })
                .onException((e) => {
                    log.error("Failed to audit email: #e.message#", e);
                });
        }
        catch(any e) {
            log.error("Failed to audit email: #e.message#", e);
        }
    }

}
