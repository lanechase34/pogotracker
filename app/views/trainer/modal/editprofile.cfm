<cfoutput>
<div class="modal fade" 
    id="editProfileModal" 
    data-bs-backdrop="static" 
    data-bs-keyboard="false" 
    tabindex="-1" 
    aria-labelledby="editProfileLabel" 
    aria-hidden="true"
>
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5" id="editProfile">Edit</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div id="editProfileAlertDiv"></div>
                <form name="editProfileForm" id="editProfileForm" class="needs-validation row g-3" novalidate autocomplete="off">
                    <input type="hidden" id="trainerid" name="trainerid" value="#EncodeForHTML(args.trainer.getId())#">
                    <div class="col-md-6">
                        <label for="inputUsername" class="form-label">Username</label>
                        <input name="username" type="username" class="form-control" id="inputUsername" value="#EncodeForHTML(args.trainer.getUsername())#" minlength="1" maxlength="30" required>
                        <div class="invalid-feedback">
                            Please provide a valid username.
                        </div> 
                    </div>
                    <div class="col-md-6">
                        <label for="inputPassword" class="form-label">Password</label>
                        <input name="password" type="password" class="form-control" id="inputPassword" value="" minlength="12" maxlength="50">
                    </div>
                    <div class="col-12">
                        <label for="inputEmail" class="form-label">Email</label>
                        <input name="email" type="email" class="form-control" id="inputEmail" value="#EncodeForHTML(args.trainer.getEmail())#" minlength="1" maxlength="100" required>
                        <div class="invalid-feedback">
                            Please provide a valid email.
                        </div>  
                    </div>
                    <div class="col-12">
                        <label for="inputIcon" class="form-label">Icon</label>
                        <select id="iconList" class="form-select" name="icon" required>
                            <cfloop index="i" item="currItem" array="#args.iconMap#">
                                <option value="#encodeForHTML(lcase(currItem))#" <cfif "#lcase(currItem)#" EQ args.trainer.getIcon()>selected</cfif>>
                                    #encodeForHTML(currItem)#
                                </option>
                            </cfloop>
                        </select>
                    </div>
                    <cfif args?.admin ?: false>
                        <div class="col-12">
                            <label for="inputFriendcode" class="form-label">Friendcode</label>
                            <input name="friendcode" type="string" class="form-control" id="inputFriendcode" value="#EncodeForHTML(args.trainer.getFriendCode())#" minlength="12" maxlength="12" required>
                            <div class="invalid-feedback">
                                Please provide a valid friendcode. No hyphens.
                            </div>  
                        </div>
                        <div class="col-12">
                            <label for="inputSecurityLevel" class="form-label">Security Level</label>
                            <select id="securityLevelList" class="form-select" name="securitylevel" required>
                                <cfloop item="currItem" index="currKey" collection="#args.securityLevels#">
                                    <option value="#encodeForHTML(currKey)#" <cfif currKey EQ args.trainer.getSecurityLevel()>selected</cfif>>
                                        #encodeForHTML(currItem)#
                                    </option>
                                </cfloop>
                            </select>
                        </div>
                        <div class="col-12">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="inputVerified" name="verified" <cfif args.trainer.getVerified()>checked</cfif>>
                                <label class="form-check-label" for="inputVerified">Verified</label>
                            </div>
                        </div>
                    </cfif>
                    <div class="col-12">
                        <label for="inputDefaultView" class="form-label">
                            Default View
                        </label>
                        <select id="inputDefaultView" name="defaultview" class="form-select" required>
                            <cfloop item="currValue" index="currKey" collection="#args.viewMap#">
                                <option value="#encodeForHTMLAttribute(currKey)#" <cfif currKey EQ session.settings.defaultView>selected</cfif>>
                                    #encodeForHTML(currValue)#
                                </option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="col-12">
                        <label for="inputDefaultRegion" class="form-label">
                            Default Region
                        </label>
                        <select id="inputDefaultRegion" name="defaultregion" class="form-select" required>
                            <cfloop index="i" item="curr" array="#args.generations#">
                                <option value="#encodeForHTMLAttribute(curr.getRegion())#" <cfif curr.getRegion() EQ session.settings.defaultRegion>selected</cfif>>
                                    #encodeForHTML(curr.getRegion())#
                                </option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="col-12">
                        <label for="inputDefaultPage" class="form-label">
                            Default Page
                        </label>
                        <select id="inputDefaultPage" name="defaultpage" class="form-select" required data-bs-display="static">
                            <cfloop item="currValue" index="currKey" collection="#args.pageMap#">
                                <option value="#encodeForHTMLAttribute(currKey)#" <cfif currKey EQ session.settings.defaultPage>selected</cfif>>
                                    #encodeForHTML(currValue)#
                                </option>
                            </cfloop>
                        </select>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <div class="btn-group" role="group">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="submit" id="submitEditProfileForm" class="btn btn-primary">
                        <i class="bi bi-check2-square me-1"></i>
                        Submit
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>  
</cfoutput> 