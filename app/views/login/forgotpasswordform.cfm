<cfoutput>
<div class="row align-items-center mt-4 mt-lg-0 flex-grow-1">
    <div class="col-sm-12 col-md-8 offset-md-2 col-lg-6 offset-lg-3 col-xxl-4 offset-xxl-4">
        <article class="card border-0 overflow-hidden shadow">
            #view(view="/views/login/fragment/hero", args={heading: "Reset Password", subtitle: "Enter your email and we'll send a reset link"})#

            <div class="card-body p-3">
                #view("/views/fragment/alert")#
                <form
                    name="forgotPasswordForm"
                    class="needs-validation verifyRecaptcha"
                    id="forgotPasswordForm"
                    novalidate
                    action="/login/forgotPassword"
                    method="post"
                    data-action="forgotpassword"
                >
                    <div class="mb-3">
                        <div class="input-group has-validation">
                            <span class="input-group-text"><i class="bi bi-envelope" aria-hidden="true"></i></span>
                            <div class="form-floating">
                                <input name="email" type="email" class="form-control" id="inputEmail" placeholder="Email address" value="" minlength="1" maxlength="100" autocomplete="email" data-invalidfeedback="validationEmailFeedback" required>
                                <label for="inputEmail">Email</label>
                            </div>
                            <div id="validationEmailFeedback" class="invalid-feedback">
                                Please provide a valid email.
                            </div>
                        </div>
                    </div>
                    <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
                    <div class="d-grid mb-3">
                        <button class="btn btn-dark" id="submitForm" type="submit">Send Reset Link</button>
                    </div>
                    <p class="text-center small mb-0">
                        <a href="/login" class="link-underline link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">Back to sign in</a>
                    </p>
                </form>
            </div>
        </article>
    </div>
</div>
</cfoutput>