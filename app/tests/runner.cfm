<cfscript>
    getPageContext()
        .getRequest()
        .getSession()
        .invalidate();
    sessionInvalidate();

    /**
     * Start every run with an empty test outbox - the whole run is this one request
     * Only the files directly inside testEmailPath are deleted, never the folder itself
     */
    function clearTestEmails() {
        var controller = request.coldBoxVirtualApp.getController();
        var testEmailPath = controller.getSetting("testEmailPath");
        if(!directoryExists(testEmailPath)) {
            return;
        }

        directoryList(
            path     = testEmailPath,
            recurse  = false,
            listInfo = "path",
            type     = "file"
        ).each((path) => {
            try {
                fileDelete(arguments.path);
            }
            catch(any e) {
                // Still held by a mail write - leave it
            }
        });
    }
    clearTestEmails();
</cfscript>

<cfsetting showDebugOutput="false">
<!--- Executes all tests in the 'specs' folder with simple reporter by default --->
<cfparam name="url.reporter" 			default="simple">
<cfparam name="url.directory" 			default="tests.specs">
<cfparam name="url.recurse" 			default="true" type="boolean">
<cfparam name="url.bundles" 			default="">
<cfparam name="url.labels" 				default="">
<cfparam name="url.excludes" 			default="">
<cfparam name="url.reportpath" 			default="#expandPath( "/tests/results" )#">
<cfparam name="url.propertiesFilename" 	default="TEST.properties">
<cfparam name="url.propertiesSummary" 	default="false" type="boolean">
<cfparam name="url.editor" 				default="vscode">
<cfparam name="url.bundlesPattern" 		default="*Spec*.cfc|*Test*.cfc|*Spec*.bx|*Test*.bx">

<!--- Include the TestBox HTML Runner --->
<cfinclude template="/testbox/system/runners/HTMLRunner.cfm" >
