<cfoutput>
<div class="row align-items-center mt-5 mt-lg-0 vh-lg-100">
    <div class="col-sm-12 col-md-8 offset-md-2 col-lg-6 offset-lg-3 col-xxl-4 offset-xxl-4">
        <div class="row mb-3 text-center border-bottom">
            <div class="d-flex align-items-center justify-content-center mb-2">
                <img src="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#" alt="POGO Tracker Logo" class="logo me-1">
                <h1 class="fs-3 m-0">POGO Tracker</h1>
            </div>
        </div>
        <p>
            Please enter a new password
        </p>
        #view("/views/fragment/alert")#
        <form name="resetPasswordForm" class="needs-validation" id="resetPasswordForm" novalidate action="/login/resetPassword" method="post">
            <div class="mt-3 mb-3 row">
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                    <div class="form-floating">
                        <input name="email" type="text" class="form-control" id="inputEmail" placeholder="Email" value="#prc.email#" minlength="1" maxlength="100" readonly disabled required>
                        <label for="email">Email</label>
                    </div>
                </div>
            </div>
            <div class="mb-3 row">
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-key"></i></span>
                    <div class="form-floating">
                        <input name="password" type="password" class="form-control" id="inputPassword" placeholder="Password" value="" minlength="12" maxlength="50" required>
                        <label for="password">Password</label>
                    </div>
                    <div class="invalid-feedback">
                        Please provide a valid password.
                    </div>
                </div>
            </div>
            <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
            <input type="hidden" name="resetCode" value="#rc.resetCode#"/>
            <div class="mb-3 row">
                <div class="col-12 text-end">
                    <button class="btn btn-dark col-12 col-lg-6" id="submitForm" type="submit">Reset Password</button>
                </div>
            </div>
        </form>
    </div>
</div>
</cfoutput>