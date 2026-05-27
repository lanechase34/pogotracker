<cfoutput>
<div class="row align-items-center mt-4 mt-lg-0 flex-grow-1">
    <div class="col-sm-12 col-md-8 offset-md-2 col-xl-6 offset-xl-3 col-xxl-4 offset-xxl-4">
        <article class="card border-0 overflow-hidden shadow">
            #view(view="/views/login/fragment/hero", args={heading: "Sign In", subtitle: "Welcome back — sign in to continue"})#

            <div class="card-body p-3">
                #view("/views/fragment/alert")#
                <form
                    name="loginForm"
                    class="needs-validation verifyRecaptcha"
                    id="loginForm"
                    novalidate
                    action="/login/doLogin"
                    method="post"
                    data-action="dologin"
                >
                    <div class="mb-3">
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-envelope" aria-hidden="true"></i></span>
                            <div class="form-floating">
                                <input name="email" type="email" class="form-control" id="inputEmail" placeholder="Email address" value="" minlength="1" maxlength="100" autocomplete="email" required>
                                <label for="inputEmail">Email</label>
                            </div>
                            <div class="invalid-feedback">
                                Please provide a valid email.
                            </div>
                        </div>
                    </div>
                    <div class="mb-3">
                        <div class="input-group">
                            <span class="input-group-text"><i class="bi bi-key" aria-hidden="true"></i></span>
                            <div class="form-floating">
                                <input name="password" type="password" class="form-control" id="inputPassword" placeholder="Password" value="" minlength="12" maxlength="50" autocomplete="current-password" required>
                                <label for="inputPassword">Password</label>
                            </div>
                            <div class="invalid-feedback">
                                Please provide a valid password.
                            </div>
                        </div>
                    </div>
                    <div class="mb-3 d-flex align-items-center justify-content-between">
                        <a href="/forgot" class="small link-underline link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">Forgot password?</a>
                        <div class="form-check mb-0">
                            <input class="form-check-input" type="checkbox" id="inputPersist" name="persist">
                            <label class="form-check-label small" for="inputPersist">Remember me</label>
                        </div>
                    </div>
                    <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
                    <div class="d-grid mb-3">
                        <button class="btn btn-dark" id="submitForm" type="submit">Sign In</button>
                    </div>
            
                    <cfif getSetting('signups')>
                        <p class="text-center small mb-0">
                            Don't have an account? <a href="/register" class="link-underline link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">Sign up now</a>
                        </p>
                    </cfif>
                    
                    <cfif getSetting('environment') EQ 'development' OR getSetting('environment') EQ 'test'>
                        <div class="mt-3 d-flex gap-2">
                            <button id="populateFields" type="button" class="btn btn-sm btn-outline-secondary">Dev Login</button>
                            <button id="populateFields2" type="button" class="btn btn-sm btn-outline-secondary">User Login</button>
                        </div>
                        <script>
                            const $email = document.getElementById('inputEmail');
                            const $pass = document.getElementById('inputPassword');

                            document.getElementById('populateFields').addEventListener('click', () => {
                                $email.value = 'test_0@gmail.com';
                                $pass.value = 'asedasdfasdfasdfasdf';
                            });

                            document.getElementById('populateFields2').addEventListener('click', () => {
                                $email.value = 'test_1@gmail.com';
                                $pass.value = 'asedasdfasdfasdfasdf';
                            });
                        </script>
                    </cfif>
                </form>
            </div>
        </article>
    </div>
</div>
</cfoutput>