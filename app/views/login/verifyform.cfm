<cfoutput>
<div class="row align-items-center mt-5 mt-lg-0 vh-lg-100">
    <div class="col-sm-12 col-md-8 offset-md-2 col-lg-6 offset-lg-3 col-xxl-4 offset-xxl-4">
        <div class="row mb-3 text-center border-bottom">
            <div class="d-flex align-items-center justify-content-center mb-2">
                <img src="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#" alt="POGO Tracker Logo" class="logo me-1">
                <h1 class="fs-3 m-0">POGO Tracker</h1>
            </div>
        </div>
        <div class="card p-3">
            <p>
                Check your email for a verification code and enter below. You may need to check your 'Spam' and 'Junk' folders and trust senders from '<b>@pogotracker.app</b>'
            </p>
            <p>
                If you are having trouble, click <a href="##" id="submitResend" role="button">here</a> to resend the verification code.
            </p>
        </div>
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
            <div class="mt-3 mb-3 row">
                <label for="code" class="col-sm-4 col-form-label">Verification Code</label>
                <div class="col-sm-8">
                    <input name="code" type="text" class="form-control" id="inputCode" value="" minlength="8" maxlength="8" required>
                    <div class="invalid-feedback">
                        Please enter the verification code sent to your email.
                    </div> 
                </div>
            </div>
            <input type="hidden" name="#getSetting('csrfTokenField')#" value="#csrfGenerateToken(forceNew=true)#">
            <div class="col-12 text-end ">
                <button class="btn btn-dark col-12 col-lg-6" id="submitForm" type="submit">Verify</button>
            </div>
        </form>
    </div>
</div>
</cfoutput>