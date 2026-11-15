<cfscript>
    /**
     * ColdBox's customErrorTemplate (config/Coldbox.cfc)
     * Included by coldbox.system.Bootstrap.processException after error.onException runs without relocating -
     * ColdBox ignores whatever an exception handler renders and outputs this template instead, so it sends what onException set:
     *  - renderData : json for fetch callers (403 security failures, 500 bugs)
     *  - a view     : the 403 access denied page
     *  - neither    : the error page itself failed (onException doesn't relocate again) - a static page, Whoops outside production
     * Runs inside processException, so event, rc, prc and oException are its local variables
     */
    local.renderData = event.getRenderData();

    if(!local.renderData.isEmpty()) {
        getPageContext().getResponse().setStatus(local.renderData.statusCode ?: 500);
        getPageContext().getResponse().setContentType("application/json; charset=utf-8");
        writeOutput(serializeJSON(local.renderData.data));
    }
    else if(len(event.getCurrentView())) {
        writeOutput(
            application.cbController
                .getRenderer()
                .layout(layout = event.getCurrentLayout(), view = event.getCurrentView())
        );
    }
    else if(application.cbController.getSetting("environment") != "production") {
        include "/coldbox/system/exceptions/Whoops.cfm";
    }
    else {
        writeOutput("<!DOCTYPE html><html lang=""en""><head><meta charset=""UTF-8""><title>Something Went Wrong</title></head>"
            & "<body style=""font-family:sans-serif;text-align:center;padding:4rem 1rem"">"
            & "<h1>Something Went Wrong</h1><p>An unexpected error occurred. Please try again later.</p><p><a href=""/"">Home</a></p>"
            & "</body></html>");
    }
</cfscript>
