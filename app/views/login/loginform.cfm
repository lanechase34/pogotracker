<cfoutput>
<div class="row align-items-center mt-5 mt-lg-0 vh-lg-100">
    <div class="col-sm-12 col-md-8 offset-md-2 col-xl-6 offset-xl-3 col-xxl-4 offset-xxl-4">
        <div class="row mb-3 text-center border-bottom mx-1">
            <div class="d-flex align-items-center justify-content-center mb-2">
                <img src="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#" alt="POGO Tracker Logo" class="logo me-1">
                <h1 class="fs-3 m-0">POGO Tracker</h1>
            </div>
        </div>
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
            <div class="mt-3 mb-3 row">
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                    <div class="form-floating">
                        <input name="email" type="text" class="form-control" id="inputEmail" placeholder="Email" value="" minlength="1" maxlength="100" required>
                        <label for="inputEmail">Email</label>
                    </div>
                    <div class="invalid-feedback">
                        Please provide a valid email.
                    </div> 
                </div>
            </div>
            <div class="mb-3 row">
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-key"></i></span>
                    <div class="form-floating">
                        <input name="password" type="password" class="form-control" id="inputPassword" placeholder="Password" value="" minlength="12" maxlength="50" required>
                        <label for="inputPassword">Password</label>
                    </div>
                    <div class="invalid-feedback">
                        Please provide a valid password.
                    </div>
                </div>
            </div>
            <div class="mb-3 row">
                <div class="col-6">
                    <a href="/forgot" class="link-underline link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">Forgot password?</a>
                </div>
                <div class="col-6 d-flex justify-content-end">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" id="inputPersist" name="persist">
                        <label class="form-check-label" for="inputPersist">Remember Me</label>
                    </div>
                </div>
            </div>
            <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
            <div class="mb-3 row">
                <div class="col-12 text-end">
                    <button class="btn btn-dark col-12 col-lg-6" id="submitForm" type="submit">Log In</button>
                </div>
            </div>
            <cfif getSetting('signups')>
                <div class="mb-3 row">
                    <div class="col-12 col-lg-6 offset-lg-6 text-center">
                        Don't have an account? <a href="/register" class="link-underline link-offset-2 link-underline-opacity-0 link-underline-opacity-100-hover">Sign up now.</a>
                    </div>
                </div>
            </cfif>
            <cfif getSetting('environment') EQ 'development' OR getSetting('environment') EQ 'test'>
                <button id="populateFields" type="button" class="btn btn-dark">Dev Login</button>
                <button id="populateFields2" type="button" class="btn btn-dark">User Login</button>
                <script>
                    const $email = document.getElementById('inputEmail');
                    const $pass = document.getElementById('inputPassword');

                    document.getElementById('populateFields').addEventListener('click', () => {
                        $email.value = 'lanechase34@outlook.com';
                        $pass.value = 'asedasdfasdfasdfasdf';
                    });

                    document.getElementById('populateFields2').addEventListener('click', () => {
                        $email.value = 'chaz14x@gmail.com';
                        $pass.value = 'asedasdfasdfasdfasdf';
                    });
                </script>
            </cfif>
        </div>
    </div>
</div>

</cfoutput>