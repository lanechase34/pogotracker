<cfoutput>
<div class="row align-items-center mt-4 mt-lg-0 flex-grow-1">
    <div class="col-sm-12 col-md-10 offset-md-1 col-lg-8 offset-lg-2 col-xxl-6 offset-xxl-3">
        <article class="card border-0 overflow-hidden shadow">
            #view(view="/views/login/fragment/hero", args={heading: "Create Account", subtitle: "Start tracking your Pokémon GO journey"})#

            <div class="card-body p-3">
                #view("/views/fragment/alert")#
                <form
                    name="registrationForm"
                    class="row g-3 needs-validation verifyRecaptcha"
                    id="registrationForm"
                    novalidate
                    action="/login/register"
                    method="post"
                    autocomplete="off"
                    data-action="register"
                >
                    <div class="col-md-6">
                        <label for="inputUsername" class="form-label">Username</label>
                        <input name="username" type="text" class="form-control" id="inputUsername" value="" minlength="1" maxlength="30" required>
                        <div class="invalid-feedback">
                            Please provide a valid username.
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label for="inputPassword" class="form-label">Password</label>
                        <input name="password" type="password" class="form-control" id="inputPassword" value="" minlength="10" maxlength="50" required>
                        <div class="invalid-feedback">
                            Please provide a valid password with minimum length 10.
                        </div>
                    </div>
                    <div class="col-12">
                        <label for="inputEmail" class="form-label">Email</label>
                        <input name="email" type="email" class="form-control" id="inputEmail" value="" minlength="1" maxlength="100" required>
                        <div class="invalid-feedback">
                            Please provide a valid email.
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label for="friendcode" class="form-label">Friend Code</label>
                        <input name="friendcode" type="text" class="form-control" id="friendcode" value="" minlength="12" maxlength="12" required>
                        <div class="invalid-feedback">
                            Please provide a valid friend code.
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label for="iconList" class="form-label">Icon</label>
                        <select id="iconList" class="form-select" name="icon" required>
                            <option selected disabled value="">Select an icon</option>
                            <cfloop index="i" item="currItem" array="#prc.iconMap#">
                                <option value="#encodeForHTML(lcase(currItem))#">
                                    #encodeForHTML(currItem)#
                                </option>
                            </cfloop>
                        </select>
                        <div class="invalid-feedback">
                            Please select an icon.
                        </div>
                    </div>
                    <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
                    <div class="col-12">
                        <div class="d-grid">
                            <button class="btn btn-dark" id="submitForm" type="submit">Create Account</button>
                        </div>
                    </div>
                    <div class="col-12">
                        <p class="text-center small mb-0">
                            Already have an account? <a href="/login" class="link-underline link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">Sign in</a>
                        </p>
                    </div>
                </form>
            </div>
        </article>
    </div>
</div>
</cfoutput>