component extends="cbmailservices.models.protocols.FileProtocol" {

    /**
     * Write the mail to its own file - a uuid in the name keeps parallel sends from overwriting each other
     */
    struct function send(required cbmailservices.models.Mail payload) {
        var rtnStruct = {"error": true, "messages": []};
        var filePath  = getProperty("filePath") & "/mail.#dateFormat(now(), "MM-dd-yyyy")#.#timeFormat(now(), "HH-mm-ss-L")#.#createUUID()#.html";

        try {
            fileWrite(
                filePath,
                getMailContent(arguments.payload),
                "UTF-8"
            );
            rtnStruct.error = false;
        }
        catch(any e) {
            rtnStruct.messages.append("Error sending mail. #e.message# : #e.detail# : #e.stackTrace#");
        }

        return rtnStruct;
    }

}
