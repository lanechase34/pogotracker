<cfoutput>
<div class="row align-items-center mt-4 mt-lg-0 flex-grow-1">
    <div class="col-sm-12 col-md-8 offset-md-2 col-lg-6 offset-lg-3 col-xxl-4 offset-xxl-4">
        <article class="card border-0 overflow-hidden shadow">
            #view(view="/views/login/fragment/hero", args={heading: "Verify Your Account", subtitle: "Enter the code sent to your email"})#

            <div class="card-body p-3">
                <p class="text-muted small mb-3">
                    Check your inbox for the verification code. You may need to check your Spam or Junk folder
                    and trust senders from <strong>@pogotracker.app</strong>.
                    Having trouble? <a href="##" id="submitResend" role="button">Resend code</a>.
                </p>
                <form
                    name="resendVerificationForm"
                    id="resendVerificationForm"
                    novalidate
                    action="/verify"
                    method="post"
                >
                    <input type="hidden" name="resend" value="true">
                </form>
                #view("/views/fragment/alert")#
                <form
                    name="verificationForm"
                    class="needs-validation"
                    id="verificationForm"
                    novalidate
                    action="/login/verify"
                    method="post"
                >
                    <div class="mb-3">
                        <div class="form-floating">
                            <input name="code" type="text" class="form-control" id="inputCode" placeholder="Verification code" value="" minlength="8" maxlength="8" autocomplete="one-time-code" required>
                            <label for="inputCode">Verification code</label>
                        </div>
                        <div class="invalid-feedback">
                            Please enter the verification code sent to your email.
                        </div>
                    </div>
                    <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
                    <div class="d-grid mb-3">
                        <button class="btn btn-dark" id="submitForm" type="submit">Verify Account</button>
                    </div>
                </form>
            </div>
        </article>
    </div>
</div>
</cfoutput>