component extends="coldbox.system.testing.BaseTestCase" {

    public numeric function countTestEmails() {
        return directoryList(
            path     = application.cbController.getSetting('testEmailPath'),
            recurse  = false,
            listInfo = 'name',
            type     = 'file'
        ).len();
    }

    public numeric function countBugLog() {
        return ormExecuteQuery('select count(id) from bug')[1];
    }

    public numeric function countAuditLog() {
        return ormExecuteQuery('select count(id) from audit')[1];
    }

    public any function readEmail(string email = '') {
        if(arguments.email.len()) {
            var fileContent = fileRead('#application.cbController.getSetting('testEmailPath')#/#arguments.email#');
        }
        // Default to read the most recent email sent
        else {
            var emails = directoryList(
                path    : '#application.cbController.getSetting('testEmailPath')#',
                recurse : false,
                listInfo: 'query',
                sort    : 'DateLastModified desc'
            );

            var fileContent = fileRead('#application.cbController.getSetting('testEmailPath')#/#emails.name[1]#');
        }

        // Email starts at DOCTYPE HTML. Select only this portion
        var mailBody = right(fileContent, fileContent.len() - fileContent.find('<!DOCTYPE html>') + 1);

        var jsoup = getInstance('javaloader:org.jsoup.Jsoup');
        return jsoup.parse(mailBody);
    }

}
