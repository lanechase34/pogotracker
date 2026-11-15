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
                <h5 class="modal-title fs-5" id="editProfileLabel">Edit</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div id="editProfileAlertDiv"></div>
                <form name="editProfileForm" id="editProfileForm" class="needs-validation row g-3" novalidate autocomplete="off">
                    <input type="hidden" id="trainerid" name="trainerid" value="#EncodeForHTML(args.trainer.id)#">
                    <div class="col-md-6">
                        <label for="inputUsername" class="form-label">Username</label>
                        <input name="username" type="username" class="form-control" id="inputUsername" value="#EncodeForHTML(args.trainer.username)#" minlength="1" maxlength="30" required>
                        <div class="invalid-feedback">
                            Please provide a valid username.
                        </div> 
                    </div>
                    <div class="col-md-6">
                        <label for="inputPassword" class="form-label">Password</label>
                        <input name="password" type="password" class="form-control" id="inputPassword" value="" minlength="10" maxlength="50" autocomplete="new-password">
                    </div>
                    <cfif args.trainer.id EQ prc.oCurrentUser.getId()>
                        <!--- Hidden until the password or email is changed - see toggleCurrentPassword in modals.js --->
                        <div class="col-12 d-none" id="currentPasswordDiv">
                            <label for="inputCurrentPassword" class="form-label">Current Password</label>
                            <input name="currentPassword" type="password" class="form-control" id="inputCurrentPassword" value="" maxlength="50" autocomplete="current-password" aria-describedby="currentPasswordHelp" disabled>
                            <div id="currentPasswordHelp" class="form-text">Required to change your email or password. A new email has to be verified with a code sent to it.</div>
                            <div class="invalid-feedback">
                                Please provide your current password.
                            </div>
                        </div>
                    </cfif>
                    <div class="col-12">
                        <label for="inputEmail" class="form-label">Email</label>
                        <input name="email" type="email" class="form-control" id="inputEmail" value="#EncodeForHTML(args.trainer.email)#" minlength="1" maxlength="100" required>
                        <div class="invalid-feedback">
                            Please provide a valid email.
                        </div>  
                    </div>
                    <div class="col-12">
                        <label for="inputIcon" class="form-label">Icon</label>
                        <select id="iconList" class="form-select" name="icon" required>
                            <cfloop index="i" item="currItem" array="#args.iconMap#">
                                <cfset iconValue = lcase(replace(currItem, " ", "", "all"))>
                                <option value="#encodeForHTML(iconValue)#" <cfif iconValue EQ args.trainer.icon>selected</cfif>>
                                    #encodeForHTML(currItem)#
                                </option>
                            </cfloop>
                        </select>
                    </div>
                    <cfif args?.admin ?: false>
                        <div class="col-12">
                            <label for="inputFriendcode" class="form-label">Friendcode</label>
                            <input name="friendcode" type="string" class="form-control" id="inputFriendcode" value="#EncodeForHTML(args.trainer.friendcode)#" minlength="12" maxlength="12" required>
                            <div class="invalid-feedback">
                                Please provide a valid friendcode. No hyphens.
                            </div>  
                        </div>
                        <div class="col-12">
                            <label for="securityLevelList" class="form-label">Security Level</label>
                            <cfif args.securityLevels.keyExists(args.trainer.securitylevel)>
                                <select id="securityLevelList" class="form-select" name="securitylevel" required>
                                    <cfloop item="currItem" index="currKey" collection="#args.securityLevels#">
                                        <option value="#encodeForHTML(currKey)#" <cfif currKey EQ args.trainer.securitylevel>selected</cfif>>
                                            #encodeForHTML(currItem)#
                                        </option>
                                    </cfloop>
                                </select>
                            <cfelse>
                                <!--- Developer - not assignable, so not editable here --->
                                <input id="securityLevelList" type="text" class="form-control" value="#encodeForHTMLAttribute(getSetting("securityLevels")[args.trainer.securitylevel] ?: args.trainer.securitylevel)#" disabled>
                            </cfif>
                        </div>
                        <div class="col-12">
                            <!--- The hidden off comes first - a checked box replaces it, so unchecking unverifies --->
                            <input type="hidden" name="verified" value="off">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="inputVerified" name="verified" <cfif args.trainer.verified>checked</cfif>>
                                <label class="form-check-label" for="inputVerified">Verified</label>
                            </div>
                        </div>
                        <div class="col-12">
                            <!--- The hidden off comes first - a checked box replaces it, so unchecking lifts the ban --->
                            <input type="hidden" name="commentBanned" value="off">
                            <div class="form-check">
                                <input class="form-check-input" type="checkbox" id="inputCommentBanned" name="commentBanned" <cfif args.trainer.commentbanned ?: false>checked</cfif>>
                                <label class="form-check-label" for="inputCommentBanned">Banned from commenting</label>
                            </div>
                        </div>
                    </cfif>
                    <div class="col-12">
                        <label for="inputDefaultView" class="form-label">
                            Default View
                        </label>
                        <select id="inputDefaultView" name="defaultview" class="form-select" required>
                            <cfloop item="currValue" index="currKey" collection="#args.viewMap#">
                                <option value="#encodeForHTMLAttribute(currKey)#" <cfif currKey EQ args.settings.defaultView>selected</cfif>>
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
                                <option value="#encodeForHTMLAttribute(curr.region)#" <cfif curr.region EQ args.settings.defaultRegion>selected</cfif>>
                                    #encodeForHTML(curr.region)#
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
                                <option value="#encodeForHTMLAttribute(currKey)#" <cfif currKey EQ args.settings.defaultPage>selected</cfif>>
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
                    <button type="submit" id="submitEditProfileForm" class="btn btn-dark">
                        <i class="bi bi-check2-square me-1"></i>
                        Submit
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>  
</cfoutput> 