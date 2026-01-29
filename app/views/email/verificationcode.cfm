<cfoutput>
    <!DOCTYPE html>
    <html lang="en">
        <head>
            <meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0;">
            Hi,

            <p>
                You have successfully registered for POGO Tracker using the email address <b>#args.email#.</b>
            </p>

            <p>
                Use the following one-time password (OTP) to verify your email address. This OTP is valid for 15 minutes till 
                <b>#dateTimeFormat(args.expires, "mmm dd, yyyy H:nn")# (GMT -05:00)</b>
            </p>

            <h4 id="verificationCode">
                #args.verificationCode#
            </h4>
        </body>
    </html>
</cfoutput>