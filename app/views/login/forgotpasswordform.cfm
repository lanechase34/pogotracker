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
            Please enter your email address. You will receive a link to create a new password via email.
        </p>
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
            <div class="mt-3 mb-3 row">
                <div class="input-group has-validation">
                    <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                    <div class="form-floating">
                        <input name="email" type="email" class="form-control" id="inputEmail" placeholder="Email" value="" minlength="1" maxlength="100" data-invalidfeedback="validationEmailFeedback" required>
                        <label for="email">Email</label>
                    </div>
                    <div id="validationEmailFeedback" class="invalid-feedback">
                        Please provide a valid email.
                    </div> 
                </div>
            </div>
            <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
            <div class="mb-3 row">
                <div class="col-12 text-end">
                    <button class="btn btn-dark col-12 col-lg-6" id="submitForm" type="submit">Reset Password</button>
                </div>
            </div>
        </form>
    </div>
</div>
</cfoutput>