<cfoutput>
<div class="row align-items-center flex-grow-1">
    <div class="col-sm-12 col-md-8 offset-md-2 col-lg-6 offset-lg-3 col-xxl-4 offset-xxl-4">
        <article class="card border-0 overflow-hidden shadow">
            #view(view="/views/login/fragment/hero", args={heading: "Reset Password", subtitle: "Please enter a new password"})#

            <div class="card-body p-3">
                #view("/views/fragment/alert")#
                <form name="resetPasswordForm" class="needs-validation" id="resetPasswordForm" novalidate action="/login/resetPassword" method="post">
                    <div class="mb-3">
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-envelope" aria-hidden="true"></i></span>
                            <div class="form-floating">
                                <input name="email" type="text" class="form-control" id="inputEmail" placeholder="Email" value="#prc.email#" minlength="1" maxlength="100" readonly disabled required>
                                <label for="inputEmail">Email</label>
                            </div>
                        </div>
                    </div>
                    <div class="mb-3">
                        <div class="input-group has-validation">
                            <span class="input-group-text"><i class="bi bi-key" aria-hidden="true"></i></span>
                            <div class="form-floating">
                                <input name="password" type="password" class="form-control" id="inputPassword" placeholder="Password" value="" minlength="10" maxlength="50" autocomplete="new-password" required>
                                <label for="inputPassword">Password</label>
                            </div>
                            <div class="invalid-feedback">
                                Please provide a valid password.
                            </div>
                        </div>
                    </div>
                    <input type="hidden" name="csrf" value="#csrfToken()#">
                    <input type="hidden" name="resetCode" value="#rc.resetCode#"/>
                    <div class="d-grid mb-3">
                        <button class="btn btn-dark" id="submitForm" type="submit">Reset Password</button>
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
