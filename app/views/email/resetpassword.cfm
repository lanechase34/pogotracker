<cfoutput>
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
                                            This link will expire in <strong>#int(args.lifespan)# minutes</strong> at <strong>#dateTimeFormat(args.expires, "mmm dd, yyyy h:nn tt")# UTC</strong>.
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 30px 0 0; color: ##718096; font-size: 14px;">
                                If you didn't request a password reset, please disregard this email.
                            </p>
                        </td>
                    </tr>
</cfoutput>
