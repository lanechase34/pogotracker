<cfoutput>
    <!DOCTYPE html>
    <html lang="en">
        <head>
            <meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                table, th, td {
                    border: 1px solid;
                }
            </style>
        </head>
        <body style="margin: 0; padding: 0;">
            New user submitted feedback at #dateTimeFormat(now(), "short")#

            <p>
                <table>
                    <tbody>
                        <tr>
                            <th scope="row">User</th>
                            <td>#encodeForHTML(args.email)#</td>
                        </tr>
                        <tr>
                            <th scope="row">Subject</th>
                            <td>#encodeForHTML(args.subject)#</td>
                        </tr>
                        <tr>
                            <th scope="row">Message</th>
                            <td>#encodeForHTML(args.message)#</td>
                        </tr>
                    </tbody>
                </table>
            </p>
        </body>
    </html>
</cfoutput>