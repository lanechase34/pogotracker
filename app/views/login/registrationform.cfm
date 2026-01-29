<cfoutput>
<div class="row align-items-center mt-5 mt-lg-0 vh-lg-100">
    <div class="col-sm-12 col-md-8 offset-md-2 col-lg-6 offset-lg-3 col-xxl-4 offset-xxl-4">
        <div class="row mb-3 text-center border-bottom">
            <div class="d-flex align-items-center justify-content-center mb-2">
                <img src="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#" alt="POGO Tracker Logo" class="logo me-1">
                <h1 class="fs-3 m-0">POGO Tracker</h1>
            </div>
        </div>
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
                <input name="username" type="username" class="form-control" id="inputUsername" value="" minlength="1" maxlength="30" required>
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
                <label for="friendcode" class="form-label">Friendcode</label>
                <input name="friendcode" type="text" class="form-control" id="friendcode" value="" minlength="12" maxlength="12" required>
                <div class="invalid-feedback">
                    Please provide a valid friend code.
                </div> 
            </div>
            <div class="col-12">
                <label for="inputIcon" class="form-label">Icon</label>
                <select id="iconList" class="form-select" name="icon" required>
                    <option selected disabled value="">Select an Icon</option>
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
            <div class="col-12 text-end">
                <button class="btn btn-dark col-12 col-lg-6" id="submitForm" type="submit">Register</button>
            </div>
        </form>
    </div>
</div>
</cfoutput>