<cfoutput>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0;">
        <span>#dateTimeFormat( now(), "mm/dd/yyyy hh:nn tt" )#</span>
        <cfdump var="#args.error#" top="3"/>
        <cfdump var="#args.sessionData#" top="2"/>
        <cfdump var="#args.requestContext#" top="3"/>
        <cfdump var="#args.cookieData#" top="3"/>
    </body>
</html>
</cfoutput>