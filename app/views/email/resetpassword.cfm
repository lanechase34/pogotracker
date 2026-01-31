<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>Reset Your Password</title>
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
                    <tr>
                        <td style="padding: 48px 40px;">
                            <h2 style="text-align: center; margin: 0 0 24px; color: ##212121; font-size: 24px; font-weight: 600; letter-spacing: -0.5px;">
                                Reset Your Password
                            </h2>
                            
                            <p style="color: ##333333; font-size: 16px; margin: 0 0 20px;">
                                We received a request to reset the password for your <strong>POGO Tracker</strong> account. Click the button below to create a new password.
                            </p>
                            
                            <!-- Reset Button -->
                            <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
                                <tr>
                                    <td align="center" style="padding: 32px 0;">
                                        <a href="#args.resetLink#" id="resetLink" style="display: inline-block; padding: 16px 48px; background-color: ##212121; color: ##ffffff; text-decoration: none; border-radius: 6px; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">
                                            Reset Password
                                        </a>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Link Alternative -->
                            <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
                                <tr>
                                    <td style="padding: 20px; background-color: ##f5f5f5; border-radius: 4px;">
                                        <p style="margin: 0 0 8px; color: ##666666; font-size: 13px;">
                                            Or copy and paste this link into your browser:
                                        </p>
                                        <p style="margin: 0; color: ##212121; font-size: 13px; word-break: break-all; font-family: 'Courier New', Courier, monospace;">
                                            #args.resetLink#
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Expiration Notice -->
                            <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin-top: 24px;">
                                <tr>
                                    <td style="padding: 20px; background-color: ##fff5f5; border-left: 4px solid ##fc8181; border-radius: 4px;">
                                        <p style="margin: 0; color: ##742a2a; font-size: 14px;">
                                            This link will expire in <strong>#int(args.lifespan)#</strong> at <strong>#dateTimeFormat(args.expires, "mmm dd, yyyy h:nn tt")# UTC</strong>.
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 30px 0 0; color: ##718096; font-size: 14px;">
                                If you didn't request a password reset, please disregard this email.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
</cfoutput>
