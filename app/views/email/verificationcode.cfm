<cfoutput>
                    <tr>
                        <td style="padding: 48px 40px;">
                            <h2 style="text-align: center; margin: 0 0 24px; color: ##212121; font-size: 24px; font-weight: 600; letter-spacing: -0.5px;">
                                Verify Your Email Address
                            </h2>
                            
                            <p style="color: ##333333; font-size: 16px; margin: 0 0 20px;">
                                Thank you for registering with <strong>POGO Tracker</strong>! Please verify your email address using the code below to complete your account setup.
                            </p>
                            
                            <!-- OTP Box -->
                            <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
                                <tr>
                                    <td align="center" style="padding: 0 0 32px;">
                                        <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="background-color: ##f5f5f5; border: 2px solid ##e0e0e0; border-radius: 8px;">
                                            <tr>
                                                <td style="padding: 24px 48px;">
                                                    <p id="verificationCode" style="margin: 0; color: ##212121; font-size: 36px; font-weight: 700; letter-spacing: 8px; font-family: 'Courier New', Courier, monospace; text-align: center;">
                                                        #args.verificationCode#
                                                    </p>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                            
                            <!-- Expiration Notice -->
                            <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
                                <tr>
                                    <td style="padding: 20px; background-color: ##fff5f5; border-left: 4px solid ##fc8181; border-radius: 4px;">
                                        <p style="margin: 0; color: ##742a2a; font-size: 14px;">
                                            This code will expire in <strong>#int(args.lifespan)# minutes</strong> at <strong>#dateTimeFormat(args.expires, "mmm dd, yyyy h:nn tt")# UTC</strong>.
                                        </p>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 30px 0 0; color: ##718096; font-size: 14px;">
                                If you didn't create an account with POGO Tracker, please disregard this email.
                            </p>
                        </td>
                    </tr>
</cfoutput>
