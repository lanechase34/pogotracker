<cfparam name="args.title" default="POGO Tracker">
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>#encodeForHTML(args.title)#</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: ##f4f4f4; line-height: 1.6;">
    <table role="presentation" style="width: 100%; border-collapse: collapse; background-color: ##f4f4f4;">
        <tr>
            <td align="center" style="padding: 40px 20px;">
                <!-- Main Container -->
                <table role="presentation" style="max-width: 600px; margin: 0 auto; background-color: ##ffffff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    
                    <!-- Header with Logo -->
                    <tr>
                        <td style="padding: 32px 40px; background-color: ##1a1a1a; border-radius: 8px 8px 0 0;">
                            <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
                                <tr>
                                    <td align="center">
                                        <table role="presentation" cellpadding="0" cellspacing="0" border="0">
                                            <tr>
                                                <td style="vertical-align: middle; padding-right: 8px; line-height: 0;">
                                                    <img src="https://pogotracker.app/includes/images/favicon.svg" alt="POGO Tracker Logo" style="max-width: 120px; height: auto; display: block; margin: 0 auto;">
                                                </td>
                                                <td style="vertical-align: middle; line-height: 0;">
                                                    <h1 style="margin: 0; padding: 0; color: ##ffffff; font-size: 28px; font-weight: 600; letter-spacing: -0.5px; line-height: 1.2;">
                                                        POGO Tracker
                                                    </h1>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    #view()#
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
</cfoutput>